"""Nia: a rule-based, safety-first matcher for the Her Health chatbot.

Pure Python standard library. No AI model, no paid service, no internet needed.
Order of work for every message:
  1. Safety rules (suicide, bleeding, breathing, baby not moving, abuse, ...) always win.
  2. Small talk (hi / thanks / bye / who are you).
  3. Matching against the knowledge base (synonyms, typo fixing, weighted overlap).
  4. Confident match -> answer. Unsure -> "Did you mean...?". No match -> safe fallback.
"""
import difflib, json, math, re
from pathlib import Path

STOP = set("""a an the is are was were be been am does did can could should would will i me my we you your
it its of to in on at for with and or but if so as by from about into than then there this that these those
what when why how which who please tell some any get got really very just feel feeling feels experience experiencing getting having""".split())

SYN = {
    "expecting": "pregnant", "preggo": "pregnant", "prego": "pregnant", "preg": "pregnant",
    "pregnancy": "pregnant", "pregnancies": "pregnant",
    "menstruation": "period", "menstrual": "period", "periods": "period", "menses": "period",
    "cramps": "cramp", "cramping": "cramp",
    "kicking": "movement", "kick": "movement", "kicks": "movement", "moving": "movement",
    "move": "movement", "moves": "movement", "movements": "movement",
    "womb": "uterus", "tummy": "abdomen", "stomach": "abdomen", "belly": "abdomen", "abdominal": "abdomen",
    "tired": "fatigue", "tiredness": "fatigue", "exhausted": "fatigue", "weakness": "weak",
    "pee": "urinate", "peeing": "urinate", "urinating": "urinate", "urination": "urinate", "wee": "urinate",
    "sex": "intercourse", "sexual": "intercourse",
    "stds": "sti", "std": "sti", "stis": "sti",
    "delivery": "childbirth", "birth": "childbirth", "postnatal": "postpartum", "labour": "childbirth",
    "boobs": "breast", "breasts": "breast", "boob": "breast",
    "anemia": "anaemia", "anemic": "anaemia",
    "vitamins": "vitamin", "supplements": "supplement", "pills": "supplement", "tablets": "supplement",
    "medicine": "medication", "medicines": "medication", "meds": "medication", "drugs": "medication",
    "painkiller": "medication", "painkillers": "medication", "ibuprofen": "medication", "paracetamol": "medication",
    "panado": "medication", "aspirin": "medication", "antibiotics": "medication", "antibiotic": "medication",
    "dose": "dosage", "doses": "dosage", "dosages": "dosage",
    "gynae": "gynaecologist", "gynecologist": "gynaecologist", "gyno": "gynaecologist",
    "contraceptive": "contraception", "contraceptives": "contraception", "condoms": "condom",
    "hurts": "pain", "hurt": "pain", "painful": "pain", "sore": "pain", "ache": "pain", "aching": "pain",
    "heavier": "heavy", "late": "missed", "delayed": "missed", "skipped": "missed", "missing": "missed",
    "itchy": "itching", "itch": "itching", "smells": "smell", "smelly": "smell",
    "vagina": "vaginal", "tracker": "track", "tracking": "track",
    "newborn": "baby", "babies": "baby", "infant": "baby",
}

def _stem(w):
    for suf in ("ing", "ed", "es", "s"):
        if w.endswith(suf) and len(w) - len(suf) >= 4:
            return w[: -len(suf)]
    return w

def normalise(text):
    text = text.lower().replace("’", "'")
    text = re.sub(r"[^a-z0-9' ]+", " ", text)
    out = []
    for tok in text.split():
        tok = tok.strip("'")
        if not tok or tok in STOP:
            continue
        out.append(SYN.get(tok) or SYN.get(_stem(tok)) or _stem(tok))
    return out

def _split_sentences(text):
    return [s.strip() for s in re.split(r"(?<=[.!?])\s+", text) if s.strip()]

HELP_WORDS = re.compile(r"\b(seek|urgent|emergency|immediately|consult|contact|ask your|speak to|assessed|medical attention|go to)\b", re.I)

class Nia:
    def __init__(self, kb_path=None):
        kb_path = kb_path or str(Path(__file__).with_name("knowledge_base.json"))
        kb = json.loads(Path(kb_path).read_text(encoding="utf-8"))
        self.numbers = kb["numbers"]
        self.intents = {}
        for it in kb["intents"]:
            it = dict(it)
            it["answer"] = self._fill(it["answer"])
            self.intents[str(it["id"])] = it
        self.rules = [(r["id"], str(r["answer_id"]), [re.compile(p, re.I) for p in r["patterns"]])
                      for r in kb["safety_rules"]]
        self._build_index()

    def _fill(self, text):
        for k, v in self.numbers.items():
            text = text.replace("{" + k + "}", v)
        return text

    # ---------- indexing ----------
    def _build_index(self):
        self.patterns = []          # (intent_id, token_list, joined)
        for iid, it in self.intents.items():
            if it.get("small_talk"):
                continue
            for k, p in enumerate([it["question"]] + it.get("patterns", [])):
                toks = normalise(p)
                if toks:
                    self.patterns.append((iid, toks, " ".join(toks), k == 0))
        df = {}
        for _, toks, _, _ in self.patterns:
            for t in set(toks):
                df[t] = df.get(t, 0) + 1
        n = len(self.patterns)
        self.idf = {t: math.log((n + 1) / (c + 0.5)) + 0.5 for t, c in df.items()}
        self.vocab = list(self.idf)
        self.small_talk = {}
        for iid, it in self.intents.items():
            if it.get("small_talk"):
                for p in [it["question"]] + it.get("patterns", []):
                    self.small_talk[" ".join(re.sub(r"[^a-z0-9' ]+", " ", p.lower()).split())] = iid
        # related questions: same category, most similar by token overlap
        self.related = {}
        for iid, it in self.intents.items():
            if it.get("small_talk"):
                continue
            base = set(normalise(it["question"]))
            scored = []
            for jid, jt in self.intents.items():
                if jid == iid or jt.get("small_talk") or jt["category"] != it["category"]:
                    continue
                other = set(normalise(jt["question"]))
                if base and other:
                    scored.append((len(base & other) / len(base | other), jid))
            scored.sort(reverse=True)
            self.related[iid] = [j for s, j in scored[:3] if s > 0]

    # ---------- matching ----------
    def _fix_typos(self, tokens):
        fixed = []
        for t in tokens:
            if t in self.idf or len(t) < 5:
                fixed.append(t)
                continue
            # only fix close spellings that start with the same letter and are about the same length
            cands = [v for v in self.vocab if v[0] == t[0] and abs(len(v) - len(t)) <= 2]
            m = difflib.get_close_matches(t, cands, n=1, cutoff=0.85)
            fixed.append(m[0] if m else t)
        return fixed

    def _score(self, q_tokens, q_joined, p_tokens, p_joined):
        q, p = set(q_tokens), set(p_tokens)
        common = q & p
        if not common:
            return 0.0
        inter = sum(self.idf[t] for t in common)
        cov_q = inter / sum(self.idf.get(t, 1.0) for t in q)
        cov_p = inter / sum(self.idf[t] for t in p)
        fuzz = difflib.SequenceMatcher(None, q_joined, p_joined).ratio()
        return 0.6 * cov_q + 0.25 * cov_p + 0.15 * fuzz

    def _rank(self, message):
        q = self._fix_typos(normalise(message))
        if not q:
            return []
        qj = " ".join(q)
        best = {}
        for iid, toks, joined, canonical in self.patterns:
            s = self._score(q, qj, toks, joined) + (0.005 if canonical else 0)
            if s > best.get(iid, 0):
                best[iid] = s
        return sorted(best.items(), key=lambda kv: kv[1], reverse=True)

    # ---------- public ----------
    def reply(self, message):
        message = (message or "").strip()
        if not message:
            return self._fallback()
        low = message.lower().replace("’", "'")
        for rule_id, answer_id, pats in self.rules:                       # 1. safety first
            if any(p.search(low) for p in pats):
                return self._package(answer_id, "safety", 1.0, rule=rule_id)
        clean = " ".join(re.sub(r"[^a-z0-9' ]+", " ", low).split())      # 2. small talk
        if clean in self.small_talk:
            return self._package(self.small_talk[clean], "small_talk", 1.0)
        ranked = self._rank(message)                                      # 3. knowledge base
        if not ranked:
            return self._fallback()
        top_id, top = ranked[0]
        second = ranked[1][1] if len(ranked) > 1 else 0
        if top >= 0.62 and (top - second >= 0.06 or top >= 0.85):
            return self._package(top_id, "answer", top)
        q_tokens = set(self._fix_typos(normalise(message)))
        shared = q_tokens & set(t for iid2, toks, _, _ in self.patterns if iid2 == top_id for t in toks)
        if top >= 0.45 and (len(shared) >= 2 or len(q_tokens) <= 2):
            return {"type": "suggest", "confidence": round(top, 2),
                    "message": "I want to make sure I give you the right information. Did you mean one of these?",
                    "suggestions": [self._chip(i) for i, s in ranked[:3] if s >= 0.30]}
        return self._fallback()

    def _chip(self, iid):
        return {"id": iid, "question": self.intents[iid]["question"]}

    def _fallback(self):
        return {"type": "fallback", "confidence": 0.0,
                "message": "I'm sorry, I don't have enough information to answer that. Please try rephrasing it with simpler words, or speak to a healthcare professional.",
                "suggestions": [self._chip(i) for i in ("1", "21", "36", "65") if i in self.intents]}

    def answer_by_id(self, iid):
        return self._package(str(iid), "answer", 1.0)

    def _package(self, iid, kind, conf, rule=None):
        it = self.intents[iid]
        sentences = _split_sentences(it["answer"])
        help_s = [s for s in sentences[1:] if HELP_WORDS.search(s)]
        details = [s for s in sentences[1:] if s not in help_s]
        health = not it["category"].startswith(("9.", "SMALL")) and kind != "safety"
        out = {
            "type": kind, "intent_id": iid, "category": it["category"], "confidence": round(conf, 2),
            "answer": it["answer"],
            "summary": sentences[0] if sentences else it["answer"],
            "details": " ".join(details),
            "when_to_get_help": " ".join(help_s),
            "emergency": kind == "safety",
            "disclaimer": "General information only, not a diagnosis. Please speak to your healthcare provider about your own situation." if health else "",
            "follow_ups": [self._chip(j) for j in self.related.get(iid, [])] if kind == "answer" else [],
            "needs_review": bool(it.get("needs_review")),
        }
        if rule:
            out["rule"] = rule
        return out

if __name__ == "__main__":
    nia = Nia()
    print("Nia is ready. Type a question (or 'quit').")
    while True:
        try:
            msg = input("\nYou: ")
        except EOFError:
            break
        if msg.strip().lower() in ("quit", "exit"):
            break
        r = nia.reply(msg)
        print(f"Nia [{r['type']}, {r['confidence']}]:", r.get("answer") or r["message"])
        for s in r.get("suggestions", []) + r.get("follow_ups", []):
            print("   >", s["question"])

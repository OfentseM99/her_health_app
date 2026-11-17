"""Build knowledge_base.json from the Her Health Q&A text file + improvements.json.

Usage (from womens_health_backend):  python3 nia/tools/build_kb.py nia/tools/her_health_qa.txt
"""
import json, re, sys
from pathlib import Path

HEADER = re.compile(r"^[━\-=\s]*(\d+)\\?\.\s+([A-Z][A-Z0-9 ,&'/-]+?)\s*[━\-=\s]*$")
QUESTION = re.compile(r"^(\d+)\\?\.\s+(.+\?)\s*$")

def parse_qa(text: str):
    items, category, current = [], None, None
    in_qa = True
    for raw in text.splitlines():
        line = raw.strip().replace("\\.", ".").replace("\\-", "-")
        if not line:
            continue
        h = HEADER.match(raw.strip().replace("\\.", "."))
        if h and "━" in raw:
            num, title = int(h.group(1)), h.group(2).strip()
            # Sections 1-10 hold Q&A. 11 (alternative phrasings) and 12 (dev notes) do not.
            in_qa = num <= 10
            category = f"{num}. {title}" if in_qa else None
            current = None
            continue
        if not in_qa or category is None:
            continue
        q = QUESTION.match(line)
        if q:
            current = {"id": q.group(1), "category": category, "question": q.group(2), "answer": ""}
            items.append(current)
        elif current is not None and not line.startswith("These responses"):
            current["answer"] = (current["answer"] + " " + line).strip()
    return [i for i in items if i["answer"]]

def main(path):
    imp = json.loads(Path(__file__).with_name("improvements.json").read_text())
    items = parse_qa(Path(path).read_text(encoding="utf-8"))
    by_id = {i["id"]: i for i in items}
    for iid, ov in imp["overrides"].items():
        if iid in by_id:
            by_id[iid].update(ov)
            by_id[iid]["improved"] = True
    for iid, pats in imp["extra_patterns"].items():
        if iid in by_id:
            by_id[iid].setdefault("patterns", []).extend(pats)
    items.extend(imp["new_intents"])
    kb = {"numbers": imp["numbers"], "safety_rules": imp["safety_rules"], "intents": items}
    Path(__file__).resolve().parent.parent.joinpath("knowledge_base.json").write_text(json.dumps(kb, indent=2, ensure_ascii=False))
    print(f"Built knowledge_base.json with {len(items)} intents "
          f"({len(items) - len(imp['new_intents'])} from your document, {len(imp['new_intents'])} new).")

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else str(Path(__file__).with_name("her_health_qa.txt")))

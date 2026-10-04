"""
Run ONCE from the womens_health_backend folder:

    python3 harden_config.py

1. Replaces placeholder secrets in .env with long random ones.
2. Adds DEV_MODE=true to .env if missing (keeps the demo banner working).
3. Tightens CORS in main.py from "any website" to localhost only.

Prints only setting NAMES, never secret values. Safe to re-run.
"""
import re
import secrets

PLACEHOLDER = "replace_with_a_long_random_string"

# ---------- .env ----------
env_lines = open(".env").read().splitlines()
changed = []
has_dev_mode = False

for i, line in enumerate(env_lines):
    key, sep, value = line.partition("=")
    key = key.strip()
    if sep and key in ("SECRET_KEY", "JWT_SECRET") and value.strip() == PLACEHOLDER:
        env_lines[i] = f"{key}={secrets.token_urlsafe(48)}"
        changed.append(key)
    if sep and key == "DEV_MODE":
        has_dev_mode = True

if not has_dev_mode:
    env_lines += [
        "",
        "# true = verification/reset codes are shown on screen (demo only).",
        "# Set to false before real patients use the app.",
        "DEV_MODE=true",
    ]
    changed.append("DEV_MODE (added, set to true)")

open(".env", "w").write("\n".join(env_lines) + "\n")
print(".env:", ", ".join(changed) if changed else "nothing needed changing")

# ---------- main.py CORS ----------
main = open("main.py").read()
pattern = re.compile(r"""allow_origins\s*=\s*\[\s*["']\*["']\s*\]""")
matches = pattern.findall(main)

if "allow_origin_regex" in main:
    print("main.py: CORS already restricted -- not changed.")
elif len(matches) == 1:
    main = pattern.sub(
        r'allow_origin_regex=r"https?://(localhost|127\\.0\\.0\\.1)(:\\d+)?"', main
    )
    open("main.py", "w").write(main)
    print("main.py: CORS now allows localhost only (any port).")
else:
    print("main.py: couldn't find allow_origins=[\"*\"] -- NOT changed. CORS lines:")
    for n, line in enumerate(main.splitlines(), 1):
        if "allow_origin" in line:
            print(f"  {n}: {line.strip()}")

for n, line in enumerate(main.splitlines(), 1):
    if "allow_origin" in line:
        print(f"  {n}: {line.strip()}")

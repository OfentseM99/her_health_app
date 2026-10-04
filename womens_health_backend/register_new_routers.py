"""
Run ONCE from the womens_health_backend folder:

    python3 register_new_routers.py

Adds the reminders and articles routers to main.py right after the
messages router, checks it found the right lines, and prints every
router line afterwards so you can see the result. Safe to re-run: if
they're already registered it changes nothing.
"""

PATH = "main.py"
IMPORT_LINE = "from routers.messages import router as messages_router"
INCLUDE_LINE = "app.include_router(messages_router)"

content = open(PATH).read()

if "reminders_router" in content or "articles_router" in content:
    print("Already registered -- main.py was not changed.")
else:
    assert content.count(IMPORT_LINE) == 1, "Couldn't find the messages import line in main.py"
    assert content.count(INCLUDE_LINE) == 1, "Couldn't find the messages include_router line in main.py"

    content = content.replace(
        IMPORT_LINE,
        IMPORT_LINE
        + "\nfrom routers.reminders import router as reminders_router"
        + "\nfrom routers.articles import router as articles_router",
        1,
    )
    content = content.replace(
        INCLUDE_LINE,
        INCLUDE_LINE
        + "\napp.include_router(reminders_router)"
        + "\napp.include_router(articles_router)",
        1,
    )
    open(PATH, "w").write(content)
    print("main.py updated.")

print()
for number, line in enumerate(content.splitlines(), 1):
    if "router" in line:
        print(f"{number}: {line}")

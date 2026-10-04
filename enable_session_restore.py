"""
Run ONCE from the her_health_app folder:

    python3 enable_session_restore.py

Makes the app open on SplashScreen (which restores a saved login)
instead of going straight to WelcomeScreen. Safe to re-run.
"""

PATH = "lib/main.dart"
WELCOME_IMPORT = "import 'screens/welcome_screen.dart';"
OLD_HOME = "home: const WelcomeScreen(),"
NEW_HOME = "home: const SplashScreen(),"

content = open(PATH).read()

if NEW_HOME in content:
    print("Already done -- main.dart was not changed.")
else:
    assert content.count(WELCOME_IMPORT) == 1, "Couldn't find the welcome_screen import in main.dart"
    assert content.count(OLD_HOME) == 1, "Couldn't find 'home: const WelcomeScreen(),' in main.dart"

    if "import 'screens/splash_screen.dart';" not in content:
        content = content.replace(
            WELCOME_IMPORT,
            WELCOME_IMPORT + "\nimport 'screens/splash_screen.dart';",
            1,
        )
    content = content.replace(OLD_HOME, NEW_HOME, 1)
    open(PATH, "w").write(content)
    print("main.dart updated.")

print()
for number, line in enumerate(content.splitlines(), 1):
    if "splash_screen" in line or "home:" in line:
        print(f"{number}: {line.strip()}")

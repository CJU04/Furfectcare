content = open("lib/views/screens/profile_settings_screen.dart").read()

# Fix the extra parenthesis
old = "\n                                    ),\n                      ),"
new = "\n                                  ],\n                                ),"

if old in content:
    content = content.replace(old, new)
    open("lib/views/screens/profile_settings_screen.dart", "w").write(content)
    print("Fixed successfully")
else:
    print("Pattern not found")

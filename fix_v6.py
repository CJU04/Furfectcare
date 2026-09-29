content = open("lib/views/screens/profile_settings_screen.dart").read()

# Fix the extra parenthesis - change ),\n                             ), to ],\n                             ),
old = "\n                ),\n                      ),"
new = "\n                                  ],\n                                ),"

if old in content:
    content = content.replace(old, new)
    open("lib/views/screens/profile_settings_screen.dart", "w").write(content)
    print("Fixed successfully")
else:
    print("Pattern not found")
    # Try to find what we have
    idx = content.find("Positioned(")
    if idx != -1:
        print(repr(content[idx+500:idx+700]))

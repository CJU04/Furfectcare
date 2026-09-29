content = open("lib/views/screens/profile_settings_screen.dart").read()

# Find and replace the incorrect section
old_pattern = "\n                                        ),\n                                      ),\n                                    ),\n                                  ),\n                               ),"
new_pattern = "\n                                        ),\n                                      ),\n                                    ),\n                                  ],\n                                ),"

if old_pattern in content:
    content = content.replace(old_pattern, new_pattern)
    open("lib/views/screens/profile_settings_screen.dart", "w").write(content)
    print("Fixed successfully")
else:
    print("Pattern not found")
    # Try to find what we have
    idx = content.find("Positioned(")
    if idx != -1:
        print(repr(content[idx+550:idx+750]))

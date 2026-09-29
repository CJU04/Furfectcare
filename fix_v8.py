content = open("lib/views/screens/profile_settings_screen.dart").read()

# Find Positioned and replace the incorrect section
idx = content.find("Positioned(")
if idx != -1:
    # Find where the incorrect ), is
    search_start = idx + 500
    # Find the pattern: ),\n                                    ),\n                                    ),
    pat = "\n                                    ),\n                                    ),"
    pos = content.find(pat, search_start)
    if pos != -1:
        # Replace with: ],\n                                ),
        new_pat = "\n                                  ],\n                                ),"
        content = content[:pos] + new_pat + content[pos + len(pat):]
        open("lib/views/screens/profile_settings_screen.dart", "w").write(content)
        print("Fixed successfully")
    else:
        print("Pattern not found after Positioned")
        print(repr(content[search_start:search_start+200]))
else:
    print("Positioned not found")

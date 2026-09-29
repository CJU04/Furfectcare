content = open("lib/views/screens/profile_settings_screen.dart").read()

# Find Positioned and understand the structure
idx = content.find("Positioned(")
if idx != -1:
    # Find the section after CircleAvatar closes
    # Pattern: ),\n                                ),\n                             ),\n                           ),
    # We want: ),\n                                  ],\n                                ),
    
    # Find CircleAvatar closing
    ca_end = content.find(")\n                                      ),", idx)
    if ca_end != -1:
        # After CircleAvatar closes, we have: \n                                ),\n                             ),\n                           ),
        # We want: \n                                  ],\n                                ),
        
        # Find the position after CircleAvatar closing
        pos = ca_end + len(")\n                                      ),")
        
        # The next part should be replaced
        old = "\n                                ),\n                             ),\n                           ),"
        new = "\n                                  ],\n                                ),"
        
        if content[pos:pos+len(old)] == old:
            content = content[:pos] + new + content[pos+len(old):]
            open("lib/views/screens/profile_settings_screen.dart", "w").write(content)
            print("Fixed successfully")
        else:
            print(f"Pattern mismatch. Got: {repr(content[pos:pos+len(old)])}")
    else:
        print("CircleAvatar end not found")
else:
    print("Positioned not found")

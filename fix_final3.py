content = open("lib/views/screens/profile_settings_screen.dart").read()

# Find Positioned and fix the structure
idx = content.find("Positioned(")
if idx != -1:
    # Find CircleAvatar closing
    ca_close = content.find(")\n                                      ),", idx)
    if ca_close != -1:
        # Position after CircleAvatar closes
        pos = ca_close + 2  # Skip )\n
        # Now find the third ), which should become ]
        first = content.find(")", pos)
        second = content.find(")", first + 1)
        third = content.find(")", second + 1)
        
        if third != -1:
            # Check context
            after = content[third:thrid+50]
            if ",\n                             ),\n                           )," in after or ",\n                             ),\n               const SizedBox" in after:
                content = content[:third] + "]" + content[third+1:]
                open("lib/views/screens/profile_settings_screen.dart", "w").write(content)
                print("Fixed successfully at position", third)
            else:
                print(f"Unexpected context: {repr(after[:50])}")
        else:
            print("Third ) not found")
    else:
        print("CircleAvatar closing not found")
        # Find what we have
        print(repr(content[idx+550:idx+750]))
else:
    print("Positioned not found")

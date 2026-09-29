content = open("lib/views/screens/profile_settings_screen.dart").read()

# Find the exact pattern and fix it
# The pattern after Positioned is:
# ... ),\n                                    ),\n                                ),\n                             ),\n               const SizedBox
# We need to change the third ), to ],

idx = content.find("Positioned(")
if idx != -1:
    # Find the third ), after Positioned
    first_close = content.find(")", idx)
    second_close = content.find(")", first_close + 1)
    third_close = content.find(")", second_close + 1)
    
    if third_close != -1:
        # Check if this is followed by ,\n                             ),\n               const SizedBox
        after_third = content[third_close:third_close+100]
        if ",\n                             ),\n               const SizedBox" in after_third:
            # Replace the ) with ]
            content = content[:third_close] + "]" + content[third_close+1:]
            open("lib/views/screens/profile_settings_screen.dart", "w").write(content)
            print("Fixed successfully")
        else:
            print(f"Unexpected content after third ): {repr(after_third[:50])}")
    else:
        print("Third ) not found")
else:
    print("Positioned not found")

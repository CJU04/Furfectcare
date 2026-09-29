content = open("lib/views/screens/profile_settings_screen.dart").read()

# Find Positioned and fix the structure
idx = content.find("Positioned(")
if idx != -1:
    # The pattern we want to fix starts after CircleAvatar closes
    # Find the CircleAvatar closing
    circle_avatar_end = content.find(")\n                      ),", idx)
    if circle_avatar_end != -1:
        # The next ), should be ]
        fix_pos = circle_avatar_end + 2
        content = content[:fix_pos] + "]" + content[fix_pos+1:]
        open("lib/views/screens/profile_settings_screen.dart", "w").write(content)
        print("Fixed successfully")
    else:
        print("CircleAvatar end not found")
else:
    print("Positioned not found")

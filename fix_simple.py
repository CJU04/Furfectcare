content = open("lib/views/screens/profile_settings_screen.dart").read()

# Find Positioned and fix the structure
idx = content.find("Positioned(")
if idx != -1:
    # Find all ), after Positioned
    positions = []
    search_pos = idx
    while True:
        pos = content.find(")", search_pos)
        if pos == -1:
            break
        positions.append(pos)
        search_pos = pos + 1
        if len(positions) >= 6:
            break
    
    print(f"Found ) at positions: {positions}")
    
    # The structure should be:
    # ), - closes Icon
    # ), - closes CircleAvatar  
    # ], - closes children array
    # ), - closes Positioned
    # ), - closes Stack children array or similar
    
    # We need to change the third ) to ]
    if len(positions) >= 4:
        third = positions[2]
        content = content[:third] + "]" + content[third+1:]
        open("lib/views/screens/profile_settings_screen.dart", "w").write(content)
        print(f"Fixed successfully - changed position {third} to ]")
    else:
        print("Not enough closing parentheses found")
else:
    print("Positioned not found")

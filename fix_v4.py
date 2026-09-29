content = open("lib/views/screens/profile_settings_screen.dart").read()

# Find the second CircleAvatar
first_avatar = content.find("CircleAvatar(")
second_avatar = content.find("CircleAvatar(", first_avatar + 1)

if second_avatar != -1:
    # Find the end pattern
    end = content.find("],", second_avatar + 500)
    if end != -1:
        # Include a bit more context to ensure proper structure
        end += 2  # Include the ],
        # Also include the following ),
        next_paren = content.find("),", end)
        if next_paren != -1:
            end = next_paren + 2
        
        new_section = """CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Theme.of(context).colorScheme.secondary,
                                      child: const Icon(
                                        Icons.notifications,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),"""
        content = content[:second_avatar] + new_section + content[end:]
        open("lib/views/screens/profile_settings_screen.dart", "w").write(content)
        print("Fixed successfully")
    else:
        print("End not found")
else:
    print("Second CircleAvatar not found")

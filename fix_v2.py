content = open("lib/views/screens/profile_settings_screen.dart").read()

# Find the corrupted section - look for the second CircleAvatar with radius: 12
first_avatar = content.find("CircleAvatar(")
second_avatar = content.find("CircleAvatar(", first_avatar + 1)

if second_avatar != -1:
    # Find the end - look for ],
    end = content.find("],\n                                 ),", second_avatar)
    if end != -1:
        end += len("],\n                                 ),")
        new_section = """child: CircleAvatar(
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

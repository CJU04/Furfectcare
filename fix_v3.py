content = open("lib/views/screens/profile_settings_screen.dart").read()

# Find the second CircleAvatar
first_avatar = content.find("CircleAvatar(")
second_avatar = content.find("CircleAvatar(", first_avatar + 1)

if second_avatar != -1:
    # Find the end pattern - ),\n                                 ],
    end_marker = "\\n             ),\n                                 ],"
    end = content.find(end_marker, second_avatar)
    if end != -1:
        end += len(end_marker)
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
        # Try to find alternative end
        alt_end = content.find("],", second_avatar + 500)
        print(f"Alternative end at {alt_end}")
        if alt_end != -1:
            print(repr(content[alt_end-50:alt_end+50]))
else:
    print("Second CircleAvatar not found")

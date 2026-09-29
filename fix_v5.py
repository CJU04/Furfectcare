content = open("lib/views/screens/profile_settings_screen.dart").read()

# Find the Positioned block
idx = content.find("Positioned(")
if idx != -1:
    # Find the end - look for ) after the Positioned block
    # The pattern should be: ...          ),\n                                  ],
    end_marker = "\n                                  ],"
    end = content.find(end_marker, idx)
    if end != -1:
        end += len(end_marker)
        new_section = """Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Theme.of(context).colorScheme.secondary,
                                        child: const Icon(
                                          Icons.notifications,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),"""
        content = content[:idx] + new_section + content[end:]
        open("lib/views/screens/profile_settings_screen.dart", "w").write(content)
        print("Fixed successfully")
    else:
        print("End not found")
else:
    print("Positioned not found")

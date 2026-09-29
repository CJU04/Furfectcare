content = open("lib/views/screens/profile_settings_screen.dart").read()

# Replace the corrupted section from Positioned to the end of the ] array
# Start: Positioned(
# End:   ],

start = content.find("Positioned(\n                                   bottom: 0,")
if start != -1:
    # Find the end of the array
    end = content.find("],\n                                 ),", start)
    if end != -1:
        end += len("],\n                                 ),")
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
                                    ),
                                  ],
                                ),"""
        content = content[:start] + new_section + content[end:]
        open("lib/views/screens/profile_settings_screen.dart", "w").write(content)
        print("Fixed successfully")
    else:
        print("End not found")
else:
    print("Start not found")

content = open("lib/views/screens/profile_settings_screen.dart").read()

# Find Positioned and fix the structure
idx = content.find("Positioned(")
if idx != -1:
    # Find the end of the Positioned block - look for ),\n                          ),\n               const SizedBox
    end_marker = "\n                          ),\n               const SizedBox"
    end = content.find(end_marker, idx)
    if end != -1:
        end += len("\n                          ),")
        new_block = """Positioned(
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
        content = content[:idx] + new_block + content[end:]
        open("lib/views/screens/profile_settings_screen.dart", "w").write(content)
        print("Fixed successfully")
    else:
        print("End marker not found")
        # Find what comes after Positioned
        print(repr(content[idx:idx+800]))
else:
    print("Positioned not found")

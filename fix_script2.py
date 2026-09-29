content = open("lib/views/screens/profile_settings_screen.dart").read()

# Find the corrupted CircleAvatar with radius: 12
search_str = "radius: 12,\\n                                        child: const Icon"
idx = content.find(search_str)

if idx != -1:
    # Find the start of the CircleAvatar widget
    start_idx = content.rfind("child: CircleAvatar(", 0, idx)
    
    # Find the end - the ), that closes CircleAvatar
    # Look for the pattern ),\n                                    ),\n                                  ]
    end_search_start = idx + 100
    end_idx = content.find("\n                                    ),", end_search_start)
    if end_idx != -1:
        end_idx2 = content.find("\n                                  ]", end_idx)
        if end_idx2 != -1:
            end_idx = end_idx2 + len("\n                                  ]")
    
    if start_idx != -1 and end_idx != -1:
        new_section = """child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Theme.of(context).colorScheme.secondary,
                                      child: const Icon(
                                        Icons.notifications,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ]"""
        content = content[:start_idx] + new_section + content[end_idx:]
        open("lib/views/screens/profile_settings_screen.dart", "w").write(content)
        print("Fixed successfully")
    else:
        print(f"End not found: start={start_idx}, end={end_idx}")
else:
    print(f"Search string not found: {idx}")

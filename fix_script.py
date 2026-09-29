import re
content = open("lib/views/screens/profile_settings_screen.dart").read()
# Find the corrupted section starting with child: CircleAvatar
start_marker = "child: CircleAvatar("
end_marker = "\n                                    ),\n                                  ]"

start_idx = content.find(start_marker)
end_idx = content.find(end_marker, start_idx)

if start_idx != -1 and end_idx != -1:
    new_section = """child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Theme.of(context).colorScheme.secondary,
                                        child: const Icon(
                                          Icons.notifications,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),"""
    content = content[:start_idx] + new_section + content[end_idx + len(end_marker):]
    open("lib/views/screens/profile_settings_screen.dart", "w").write(content)
    print("Fixed successfully")
else:
    print(f"Markers not found: start={start_idx}, end={end_idx}")

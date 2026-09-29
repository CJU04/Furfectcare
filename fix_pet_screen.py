#!/usr/bin/env python3
"""Fix pet_management_screen.dart"""

with open('lib/views/screens/pet_management_screen.dart', 'r') as f:
    content = f.read()

import re

# Remove the inner class definitions
content = re.sub(
    r'\n  /// Stateful widget.*?class _PetDetailsSheetContent.*?^\}\n\n  Widget _detailRow.*?^\}\n\n',
    '\n',
    content,
    flags=re.DOTALL | re.MULTILINE
)

# Also remove _showPetDetails that references these classes
content = re.sub(
    r'  /// Full-info dialog.*?void _showPetDetails\(Pet pet\) \{.*?showModalBottomSheet\(.*?_PetDetailsSheetContent\(pet: pet\),.*?^\}\n\n',
    '\n',
    content,
    flags=re.DOTALL | re.MULTILINE
)

# Add a simpler _showPetDetails method before dispose
simple_show = '''
  void _showPetDetails(Pet pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _PetDetailsDialog(pet: pet),
    );
  }
'''

content = content.replace(
    '  @override\n  void dispose() {',
    simple_show + '  @override\n  void dispose() {'
)

with open('lib/views/screens/pet_management_screen.dart', 'w') as f:
    f.write(content)

print('Part 1 done')
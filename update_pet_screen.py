#!/usr/bin/env python3
"""Update pet_management_screen.dart"""

import re

file_path = 'c:\\Users\\Tsayter\\Desktop\\PROGRAMMING\\System\\FURFECTCARE VERSIONS\\furfectcare_fixed\\lib\\views\\screens\\pet_management_screen.dart'

with open(file_path, 'r', encoding='utf-8-sig') as f:
    content = f.read()

# Add imports
imports_block = """
import 'package:vetcare_connect/models/medical_document.dart';
import 'package:vetcare_connect/services/medical_document_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vetcare_connect/config/theme/app_theme.dart';
"""

content = re.sub(
    r"(import 'package:vetcare_connect/views/widgets/drawer_widget.dart';)",
    r"\1" + imports_block,
    content
)

# Add methods before dispose()
methods_block = '''
  void _showPetDetails(Pet pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _PetDetailsSheetContent(pet: pet),
    );
  }

'''
content = content.replace('  @override\n  void dispose() {', methods_block + '  @override\n  void dispose() {')

# Make ExpansionTile tappable
content = content.replace(
    "subtitle: Text('${pet.type} - ${pet.breed}, Age: ${pet.age}, ${pet.gender}'),\n                              trailing:",
    "subtitle: Text('${pet.type} - ${pet.breed}, Age: ${pet.age}, ${pet.gender}'),\n                              onTap: () => _showPetDetails(pet),\n                              trailing:"
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Part 1 done')
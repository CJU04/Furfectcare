import 'package:flutter/material.dart';

import '../config/branding.dart';

class AppColors {
  // Keep these aligned with the app's ThemeData (seeded green).
  static const Color primary = Color(0xFF2E7D32); // green.shade700
  static const Color secondary = Color(0xFFA5D6A7); // green.shade300 (approx)
  static const Color accent = Color(0xFF81C784); // green.shade400 (approx)
  static const Color error = Colors.red;
  static const Color success = Color(0xFF388E3C); // green (strong)
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF1F8E9); // light green surface-ish
}

class AppStrings {
  static const String appName = AppBranding.appName;
  static const String welcomeMessage = 'Welcome to ';
  static const String login = 'Login';
  static const String register = 'Register';
  static const String logout = 'Logout';
  static const String dashboard = 'Dashboard';
  static const String pets = 'Pets';
  static const String appointments = 'Appointments';
  static const String medicalHistory = 'Medical History';
  static const String products = 'Products';
  static const String sales = 'Sales';
  static const String inventoryLogs = 'Inventory Logs';
  static const String profileSettings = 'Profile Settings';
  static const String reports = 'Reports';
  static const String settings = 'Settings';
  static const String medicalDocuments = 'Medical Documents';
}

class AppLayout {
  static const double borderRadius = 12.0;
  static const double padding = 16.0;
  static const double margin = 16.0;
}

/// Cross-feature reference values (vault keys, storage folders, etc.)
/// that are reused by providers, services and screens.
class Constants {
  Constants._();

  // Vault keys used by the encrypted prefs client.
  static const String kVaultPasswordsKey = 'encrypted_passwords';

  // Firebase Storage folder names.
  static const String kPetImagesFolder = 'pet_images';
  static const String kProductImagesFolder = 'product_images';
  static const String kProfileImagesFolder = 'profile_images';
  static const String kMedicalDocumentsFolder = 'medical_documents';

// Vendor catalog (kept here to keep sample data centralized).
  static const int lowStockThreshold = 10;

  static const List<Map<String, dynamic>> realisticCatalog = [
    {
      'productCode': 'VET-FD-001',
      'productName': 'Royal Canin Adult Maxi Dry Dog Food (3kg)',
      'category': 'Food',
      'description':
          'Complete balanced nutrition specially formulated for large breed adult dogs with sensitive digestion and joint care.',
      'price': 1450.00,
      'stockQuantity': 25,
      'minimumStock': 5,
      'unit': 'pack',
      'imageUrl': 'https://placehold.co/300x300/4CAF50/FFFFFF?text=Dog+Food',
    },
    {
      'productCode': 'VET-FD-002',
      'productName': 'Whiskas Ocean Fish Adult Dry Cat Food (1.2kg)',
      'category': 'Food',
      'description':
          'Enriched with Omega 3 & 6 and zinc for healthy coat and urinary tract health for adult cats.',
      'price': 420.00,
      'stockQuantity': 30,
      'minimumStock': 8,
      'unit': 'pack',
      'imageUrl': 'https://placehold.co/300x300/FF9800/FFFFFF?text=Cat+Food',
    },
    {
      'productCode': 'VET-FD-003',
      'productName': 'Pedigree Pro High Protein Puppy Dry Food (1.5kg)',
      'category': 'Food',
      'description':
          'Essential DHA and prebiotic fibers for growing puppies from weaning up to 12 months.',
      'price': 580.00,
      'stockQuantity': 20,
      'minimumStock': 5,
      'unit': 'pack',
      'imageUrl': 'https://placehold.co/300x300/8BC34A/FFFFFF?text=Puppy+Food',
    },
    {
      'productCode': 'VET-FD-004',
      'productName': 'Royal Canin Kitten Mother & Babycat Mousse (195g)',
      'category': 'Food',
      'description':
          'Ultra-soft mousse texture for 1st age kittens and nursing mother cats.',
      'price': 185.00,
      'stockQuantity': 40,
      'minimumStock': 10,
      'unit': 'can',
      'imageUrl': 'https://placehold.co/300x300/CDDC39/FFFFFF?text=Kitten+Food',
    },
    {
      'productCode': 'VET-MED-001',
      'productName': 'Frontline Plus Flea & Tick Spot-On for Dogs (10-20kg)',
      'category': 'Medicine',
      'description':
          'Fast-acting topical treatment that eliminates fleas, flea eggs, ticks, and chewing lice for 30 days.',
      'price': 650.00,
      'stockQuantity': 18,
      'minimumStock': 6,
      'unit': 'pipette',
      'imageUrl': 'https://placehold.co/300x300/F44336/FFFFFF?text=Flea+Tick',
    },
    {
      'productCode': 'VET-MED-002',
      'productName': 'Broadline Spot-On All-in-One for Cats (2.5-7.5kg)',
      'category': 'Medicine',
      'description':
          'Broad spectrum antiparasitic for tapeworms, roundworms, heartworm prevention, fleas and ticks.',
      'price': 720.00,
      'stockQuantity': 15,
      'minimumStock': 5,
      'unit': 'pipette',
      'imageUrl':
          'https://placehold.co/300x300/E91E63/FFFFFF?text=Cat+Medicine',
    },
    {
      'productCode': 'VET-MED-003',
      'productName': 'Canex Multi-Spectrum Dewormer Tablets (Dog)',
      'category': 'Medicine',
      'description':
          'Palatable chewable tablet for control of hookworms, roundworms, whipworms, and tapeworms in dogs.',
      'price': 160.00,
      'stockQuantity': 50,
      'minimumStock': 10,
      'unit': 'tablet',
      'imageUrl': 'https://placehold.co/300x300/9C27B0/FFFFFF?text=Dewormer',
    },
    {
      'productCode': 'VET-MED-004',
      'productName': 'Nutri-Plus Gel High Energy Pet Supplement (120.5g)',
      'category': 'Medicine',
      'description':
          'Concentrated source of vitamins, minerals, and calories for convalescent or working pets.',
      'price': 890.00,
      'stockQuantity': 14,
      'minimumStock': 4,
      'unit': 'tube',
      'imageUrl': 'https://placehold.co/300x300/673AB7/FFFFFF?text=Supplement',
    },
    {
      'productCode': 'VET-MED-005',
      'productName': 'Cosequin DS Plus MSM Joint Health Supplement (60 Tabs)',
      'category': 'Medicine',
      'description':
          'Veterinarian recommended glucosamine and chondroitin chewables to support mobility and joint comfort.',
      'price': 1950.00,
      'stockQuantity': 8,
      'minimumStock': 3,
      'unit': 'bottle',
      'imageUrl':
          'https://placehold.co/300x300/795548/FFFFFF?text=Joint+Health',
    },
    {
      'productCode': 'VET-SUP-002',
      'productName': 'Veterinary Grade Sterile Saline Wound Wash (500ml)',
      'category': 'Supplies',
      'description':
          'Non-toxic, safe if licked topical spray for cuts, scratches, hot spots, and post-surgery skin healing.',
      'price': 850.00,
      'stockQuantity': 12,
      'minimumStock': 4,
      'unit': 'bottle',
      'imageUrl': 'https://placehold.co/300x300/009688/FFFFFF?text=Wound+Care',
    },
    {
      'productCode': 'VET-GROOM-001',
      'productName':
          'Madre de Cacao Antifungal & Anti-Mange Pet Shampoo (500ml)',
      'category': 'Grooming',
      'description':
          'Natural herbal shampoo with coconut oil and Madre de Cacao extract to eliminate itchiness, ticks, and mites.',
      'price': 280.00,
      'stockQuantity': 35,
      'minimumStock': 10,
      'unit': 'bottle',
      'imageUrl': 'https://placehold.co/300x300/8BC34A/FFFFFF?text=Shampoo',
    },
    {
      'productCode': 'VET-GROOM-002',
      'productName': 'Oatmeal & Aloe Soothing Pet Conditioner (350ml)',
      'category': 'Grooming',
      'description':
          'Deep moisturizing leave-in coat conditioner leaving silky shine and detangling matted fur.',
      'price': 340.00,
      'stockQuantity': 20,
      'minimumStock': 5,
      'unit': 'bottle',
      'imageUrl': 'https://placehold.co/300x300/CDDC39/FFFFFF?text=Conditioner',
    },
    {
      'productCode': 'VET-GROOM-003',
      'productName':
          'Dentastix Daily Oral Care Treats for Medium Dogs (7 Sticks)',
      'category': 'Grooming',
      'description':
          'Triple action dental stick reduces tartar build-up by up to 80% and freshens breath.',
      'price': 195.00,
      'stockQuantity': 45,
      'minimumStock': 12,
      'unit': 'pack',
      'imageUrl':
          'https://placehold.co/300x300/FFC107/FFFFFF?text=Dental+Sticks',
    },
    {
      'productCode': 'VET-ACC-001',
      'productName': 'Reflective Padded Adjustable Nylon Dog Collar (Medium)',
      'category': 'Accessories',
      'description':
          'Heavy-duty breathable neoprene padding with quick-release buckle and night-reflective stitching.',
      'price': 260.00,
      'stockQuantity': 16,
      'minimumStock': 4,
      'unit': 'piece',
      'imageUrl': 'https://placehold.co/300x300/607D8B/FFFFFF?text=Dog+Collar',
    },
    {
      'productCode': 'VET-ACC-002',
      'productName': 'Breakaway Safety Cat Collar with Bell (Pastel Blue)',
      'category': 'Accessories',
      'description':
          'Quick-release safety latch prevents snagging hazards while keeping outdoor cats audible.',
      'price': 140.00,
      'stockQuantity': 24,
      'minimumStock': 6,
      'unit': 'piece',
      'imageUrl': 'https://placehold.co/300x300/2196F3/FFFFFF?text=Cat+Collar',
    },
    {
      'productCode': 'VET-ACC-003',
      'productName':
          'Heavy Duty 1.5m Shock Absorbing Dog Leash with Padded Handle',
      'category': 'Accessories',
      'description':
          'Elastic bungee leash prevents arm strain during sudden pulls. Includes safety car seat buckle clip.',
      'price': 390.00,
      'stockQuantity': 18,
      'minimumStock': 5,
      'unit': 'piece',
      'imageUrl': 'https://placehold.co/300x300/795548/FFFFFF?text=Dog+Leash',
    },
    {
      'productCode': 'VET-ACC-004',
      'productName':
          'Anti-Gulping Slow Feeder Stainless Steel Pet Bowl (800ml)',
      'category': 'Accessories',
      'description':
          'Non-slip rubber base obstacle bowl prevents bloat and choking by slowing down eager eaters.',
      'price': 320.00,
      'stockQuantity': 22,
      'minimumStock': 6,
      'unit': 'piece',
      'imageUrl': 'https://placehold.co/300x300/9E9E9E/FFFFFF?text=Pet+Bowl',
    },
    {
      'productCode': 'VET-SUP-001',
      'productName':
          'Ultra Absorbent Carbon Charcoal Training Pee Pads (50 Pcs)',
      'category': 'Supplies',
      'description':
          '6-layer leak-proof puppy training pads with active carbon odor neutralizer and attractant scent.',
      'price': 520.00,
      'stockQuantity': 30,
      'minimumStock': 8,
      'unit': 'pack',
      'imageUrl':
          'https://placehold.co/300x300/607D8B/FFFFFF?text=Training+Pads',
    },
  ];
}

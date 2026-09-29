/// Shared search + sort helpers used across list screens.
///
/// Every list screen normalizes queries the same way (trim + lowercase) and
/// matches against ALL visible fields — previously each screen only matched
/// one field (e.g. pets matched `name` only, appointments matched
/// reason/status only), which made search feel broken.
library;

import 'package:flutter/material.dart';

/// Normalize a query / field for case-insensitive contains matching.
String norm(String? v) => (v ?? '').trim().toLowerCase();

/// True when normalized [query] is empty or [fields] contains it in ANY field.
bool matchesQuery(String query, List<String?> fields) {
  final q = norm(query);
  if (q.isEmpty) return true;
  for (final f in fields) {
    if (norm(f).contains(q)) return true;
  }
  return false;
}

/// Generic ascending/descending string comparator (case-insensitive).
int compareStr(String? a, String? b, bool ascending) {
  final r = norm(a).compareTo(norm(b));
  return ascending ? r : -r;
}

/// Generic numeric comparator honoring [ascending].
int compareNum(num a, num b, bool ascending) =>
    ascending ? a.compareTo(b) : b.compareTo(a);

/// Sort options shared by screens. Each screen maps these to its own fields.
enum SortDirection { ascending, descending }

/// Sorts a list of date-like strings (ISO dates, "YYYY-MM-DD HH:mm", etc.)
/// newest-first while tolerating empty/unparseable values (they go last).
/// Returns a new list; the input is not modified.
List<T> sortListOfStrings<T>(
  List<T> items,
  String Function(T) valueOf, {
  bool newestFirst = true,
}) {
  int rank(T item) {
    final raw = valueOf(item).trim();
    if (raw.isEmpty) return 2; // always last
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return 1; // malformed just before empty
    return 0;
  }

  final sorted = [...items]..sort((a, b) {
      final ra = rank(a);
      final rb = rank(b);
      if (ra != rb) return ra.compareTo(rb);
      return newestFirst
          ? valueOf(b).compareTo(valueOf(a))
          : valueOf(a).compareTo(valueOf(b));
    });
  return sorted;
}

/// Parses the loose date strings stored in Firestore models ("2026-09-15",
/// "2026-09-15 14:30", full ISO-8601) into DateTime, returning null when the
/// value is empty or malformed. Used for search/filtering by date.
DateTime? tryParseDateText(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;
  return DateTime.tryParse(value);
}

/// Small reusable search + sort bar used by list screens.
///
/// Renders a [TextField] wired to [controller] plus a sort [DropdownButton]
/// built from [sortOptions] with the current [sortValue]. Screens that have
/// no meaningful sort pass null sortOptions and get a plain search field.
class SearchSortBar extends StatelessWidget {
  final TextEditingController controller;
  final String searchLabel;
  final String searchHint;
  final ValueChanged<String> onChanged;
  final List<String>? sortOptions;
  final String? sortValue;
  final ValueChanged<String?>? onSortChanged;
  final VoidCallback? onClear;

  const SearchSortBar({
    super.key,
    required this.controller,
    required this.searchLabel,
    required this.searchHint,
    required this.onChanged,
    this.sortOptions,
    this.sortValue,
    this.onSortChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: searchLabel,
        hintText: searchHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                  onClear?.call();
                },
              )
            : null,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );

    if (sortOptions == null || sortOptions!.isEmpty) return field;

    return Row(
      children: [
        Expanded(child: field),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: sortValue,
          hint: const Text('Sort'),
          items: sortOptions!
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: onSortChanged,
        ),
      ],
    );
  }
}

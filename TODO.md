# TODO

- [x] Refactor `SalesPosScreen` UI to match the tested `ProductCatalogScreen` look/behavior
  - [x] Replace POS product grid with the catalog-style responsive grid and `_ProductCard`
  - [x] Replace POS cart area with catalog-style draggable bottom sheet cart (`_showCartSheet`, `_CartSheet`)
  - [x] Ensure cart quantity +/- and remove UI match catalog behavior
  - [x] Wire cart sheet "Place Order" to existing `_checkout()` logic
  - [x] Keep role guard (block customer via `AccessDeniedScreen`)
  - [ ] Verify builds (flutter analyze / run)


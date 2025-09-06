Moonworld Tarot Shuffle

This is a Flutter scaffold for a Tarot shuffle and reading app featuring:

- 78-card deck (placeholder data included)
- Riffle shuffle visualization (placeholder)
- Bottom fan spread and drag-to-slot mechanics
- Flip interaction (Y-axis rotation)

To run:

1. Install Flutter and ensure it's on your PATH.
2. From project root:

```powershell
flutter pub get
flutter run
```

Notes:
- Replace placeholder assets in `assets/tarot/cards/` and update `assets/cards.json` with all 78 cards.
- `tarot_card_3d.dart`, `deck_widget.dart`, and `deal_widget.dart` contain the core UI and logic.

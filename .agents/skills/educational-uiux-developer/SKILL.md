---
name: educational-uiux-developer
description: >-
  Expert guide for designing and implementing interactive, gamified educational UI/UX in Flutter
  for Algebrix. Use when building math puzzles, drag-and-drop interactions, mascot (Xy) feedback,
  tactile physics scales, moves/scoring mechanics, and test-safe micro-animations following the
  Atomix design system.
---

# Educational UI/UX & Gamification Developer Skill

This skill guides the design, implementation, and animation of interactive educational features in **Algebrix**. It ensures high pedagogical value, tactile delightful UI/UX, brand consistency with the Atomix design language, and 100% test-safe Flutter code.

---

## 1. Core Educational UI/UX Principles

1. **Concrete Before Abstract (Mental Models)**:
   - Always provide a tangible physical or spatial metaphor before showing raw symbols (e.g., a tilting balance beam for equations, area models for polynomials, number lines for inequalities).
2. **Prevent Blind Trial-and-Error (Scaffolding & Reasoning Checks)**:
   - Every completed interactive puzzle must include a **Reasoning Check** (`_ReasoningCheckCard` / Modal) where mascot Xy prompts: *"Why does this work?"*
   - Reinforce the mathematical invariant (e.g., *"Applying the same operation to both sides preserves equality"*).
3. **Multi-Sensory Feedback Loop**:
   - **Visual**: Immediate state changes, color shifts (mint for success, pink for active, purple for operations).
   - **Physics/Animation**: Tilting beams, wobbling pans on drop, staggered star pop-ins.
   - **Mascot Emotion**: Xy expressions reflecting current state (`xyDefault`, `xyHappy`, `xySad`, `xyExplaining`).
4. **Optimal Moves & Gamified Mastery**:
   - Track `moveCount` and compare with `optimalMoves`.
   - ⭐⭐⭐ **Perfect** ($\le \text{optimalMoves}$): Max XP (+30 XP) + 3 Gold Stars.
   - ⭐⭐ **Great** ($\le \text{optimalMoves} + 2$): +20 XP + 2 Gold Stars.
   - ⭐ **Completed** ($> \text{optimalMoves} + 2$): +10 XP + 1 Gold Star.

---

## 2. Algebrix Design System (Atomix Theme) Tokens

Always use existing project tokens. Never introduce hardcoded colors, arbitrary fonts, or incompatible widget signatures.

### Colors (`AppColors`)
* **Primary / Active**: `AppColors.pink` (`#FF5CA8`), `AppColors.extraLightPink` (`#FFF0F7`)
* **Success / Mint**: `AppColors.mint` (`#62D9C7`), `AppColors.lightMint` (`#E0F7F3`)
* **Operations / Accent**: `AppColors.purple` (`#A98CFF`), `AppColors.lightPurple` (`#EDE7FF`)
* **Reward / Warning**: `AppColors.yellow` (`#FFC857`), `AppColors.lightYellow` (`#FFF8E7`)
* **Text / Background**: `AppColors.text` (`#2D2D2D`), `AppColors.textSecondary` (`#5A5A5A`), `AppColors.background` (`#FDFBFF`)

### Operation Palette Color Mapping
| Operation | Color | Light Background | Icon |
|---|---|---|---|
| Subtract (−) | `AppColors.pink` | `AppColors.extraLightPink` | `Icons.remove_rounded` |
| Add (+) | `AppColors.mint` | `AppColors.lightMint` | `Icons.add_rounded` |
| Divide (÷) | `AppColors.purple` | `AppColors.lightPurple` | `Icons.percent_rounded` |
| Multiply (×) | `AppColors.yellow` | `AppColors.lightYellow` | `Icons.close_rounded` |

### Widget APIs & Signatures
* `PrimaryButton(label: '...', onPressed: () { ... })` — **DO NOT** use `text:`.
* `SecondaryPageAppBar(title: '...', supportingText: '...')` — **DO NOT** use `subtitle:`.
* `RootPageHeader(title: '...', subtitle: '...')` — for top-level navigation pages.
* `showAlgebrixSnackBar(context, message: '...', isError: bool)` — for notifications.
* Typography: Always use `GoogleFonts.nunito()` with weights `w700`, `w800`, or `w900` for numbers and titles.

---

## 3. Test-Safe Animation Patterns

Continuous ambient animations (e.g., idle bobbing chips, pulsing badges) can cause `tester.pumpAndSettle()` in widget tests to time out.

### The Golden Rule of Repeating Animations in Algebrix:
Always guard infinite `.repeat()` calls against widget test environments:

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  final isTesting = WidgetsBinding.instance.runtimeType.toString().contains('Test');
  if (TickerMode.of(context) && !isTesting) {
    if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  } else {
    _controller.stop();
  }
}
```

### Spring Physics & Tilt Calculations
```dart
void _updateTilt() {
  final diff = rightWeight - leftWeight;
  const maxDelta = 30.0;
  final oldTilt = _targetTilt;
  _targetTilt = (diff / maxDelta).clamp(-1.0, 1.0) * 0.12; // ~7° max tilt
  if (widget.isSolved) _targetTilt = 0.0;

  _tiltAnimation = Tween<double>(begin: oldTilt, end: _targetTilt).animate(
    CurvedAnimation(parent: _tiltController, curve: Curves.easeOutBack),
  );
  _tiltController.forward(from: 0);
}
```

---

## 4. Drag-and-Drop & Touch Interaction Architecture

Provide dual interaction modalities for accessibility and convenience:
1. **Direct Drag-and-Drop**: `Draggable<ScaleOp>` onto multiple `DragTarget<ScaleOp>` drop zones (e.g., Center = Both Sides, Left Dish = Left Only, Right Dish = Right Only).
2. **Direct Tap Shortcut**: Tapping a block directly applies it to both sides automatically.
3. **Drop Hover State**: Update `DragTarget` builder to highlight the hovered zone with an active colored border, light background tint, and explicit instructional text (`RELEASE ON LEFT`).

---

## 5. Defensive Responsive Layouts (Zero Overflow Rule)

Never let formula cards or headers cause RenderFlex yellow-and-black stripes on narrow devices (320px–360px width):
* Wrap variable-length header texts in `Flexible` with `overflow: TextOverflow.ellipsis`.
* Use `FittedBox(fit: BoxFit.scaleDown)` for mathematical expressions inside containers or scale pans.
* Keep badges and stat rows inside `Wrap` or `SingleChildScrollView` where appropriate.

# BottomButtonBar Implementation Guide

## Widget Created
- **File**: `lib/widgets/bottom_button_bar.dart`
- **Main Widget**: `BottomButtonBar`
- **Supporting Classes**: `BottomButton`, `BottomButtonType` enum
- **Convenience Builders**: `simpleFinishButton()`, `continueButton()`, `retryAndContinueButtons()`

## Widget Features

### Core Properties:
- `primaryButton` - Single main action button (e.g., "Fullfør", "Fortsett")
- `actionButtons` - List of additional action buttons
- `onAbort` - Callback for abort button (red "Avbryt")
- `abortLabel` - Customizable abort button text
- `useRow` - Layout direction (row for ≤2 buttons, column for more)
- `buttonSpacing` - Gap between buttons (default: 16.0)
- `padding` - Padding around entire bar (default: 16.0 all sides)
- `showAbortButton` - Whether to show abort button

### Button Types:
```dart
enum BottomButtonType {
  filled,      // FilledButton (primary action)
  outlined,    // OutlinedButton (secondary action) - DEFAULT
  abort,       // TextButton with red color
}
```

## Implementation Patterns for Each Test

### 1. Counter Test (`counter_test.dart`)
**Current**: 3 vertical buttons
- FilledButton: "Øk" (action button, part of main content)
- OutlinedButton: "Fullfør" 
- TextButton: "Avbryt" (red)

**New Pattern**:
```dart
BottomButtonBar(
  primaryButton: BottomButton(
    label: 'Fullfør',
    onPressed: () { widget.run.complete(...); },
  ),
  onAbort: () => widget.run.abort('User aborted'),
)
```
**Note**: "Øk" button stays in main content (not bottom), as it's the primary interaction

---

### 2. Tap 10 Test (`tap10_test.dart`)
**Current**: 3 vertical buttons
- FilledButton: "Trykk" (action, enabled based on `done`)
- OutlinedButton: "Fullfør" (enabled when `done`)
- TextButton: "Avbryt" (red)

**New Pattern**:
```dart
BottomButtonBar(
  primaryButton: BottomButton(
    label: 'Fullfør',
    onPressed: done ? () { widget.run.complete(...); } : null,
    enabled: done,
  ),
  onAbort: () => widget.run.abort('User aborted'),
)
```
**Note**: "Trykk" stays in main content (primary interaction)

---

### 3. Stroop Test (`stroop_test.dart`)
**Current**: StroopScreen widget with:
- Mid-screen: Color letter buttons
- Bottom: Optional `bottomButton` (OutlinedButton) + TextButton "Avbryt"

**New Pattern**:
```dart
// When test is complete:
BottomButtonBar(
  primaryButton: BottomButton(
    label: 'Lever resultater',
    onPressed: _finishTest,
  ),
  onAbort: widget.onAbort,
)

// When test is ongoing:
// Don't show bottom button bar
```

---

### 4. Counter Tutorial (`counter_tutorial.dart`)
**Current**: Single OutlinedButton "Fortsett"

**New Pattern**:
```dart
BottomButtonBar(
  primaryButton: BottomButton(
    label: 'Fortsett',
    onPressed: widget.onComplete,
  ),
  onAbort: null,  // No abort in tutorials typically
  showAbortButton: false,
)
// OR use convenience builder:
continueButton(onContinue: widget.onComplete)
```

---

### 5. Tap10 Tutorial (`tap10_tutorial.dart`)
**Current**: Single OutlinedButton "Fortsett" (when completed)

**New Pattern** (same as Counter Tutorial):
```dart
continueButton(onContinue: widget.onComplete)
```

---

### 6. Stroop Tutorial (`stroop_tutorial.dart`)
**Current**: Stages:
- Intro: OutlinedButton "Start veiledning"
- Mid-stage: OutlinedButton "Fortsett" 
- Uses StroopScreen for button management

**New Pattern**: Depends on stage:
```dart
// Intro stage:
continueButton(onContinue: () { setState(...); })

// Progression stages:
// Handled by StroopScreen - no changes needed for now
```

---

### 7. TMT Tutorial (`tmt_tutorial.dart`)
**Current**: Row of buttons when complete:
- OutlinedButton: "Prøv igjen"
- OutlinedButton: "Ferdig å øve"
- TextButton: "Avbryt" (red)

**New Pattern**:
```dart
BottomButtonBar(
  actionButtons: [
    BottomButton(
      label: 'Prøv igjen',
      onPressed: _resetTutorial,
      type: BottomButtonType.outlined,
    ),
    BottomButton(
      label: 'Ferdig å øve',
      onPressed: widget.onComplete,
      type: BottomButtonType.outlined,
    ),
  ],
  onAbort: widget.onAbort,
  useRow: true,
)

// OR use convenience builder:
retryAndContinueButtons(
  onRetry: _resetTutorial,
  onContinue: widget.onComplete,
  onAbort: widget.onAbort,
  retryLabel: 'Prøv igjen',
  continueLabel: 'Ferdig å øve',
)
```

---

### 8. TMT Test (`tmt_test.dart`)
**Current**: Bottom buttons:
- OutlinedButton: "Clear"
- OutlinedButton: "Fullført" (conditional)
- TextButton: "Avbryt" (red)

**New Pattern**:
```dart
BottomButtonBar(
  actionButtons: [
    BottomButton(
      label: 'Clear',
      onPressed: _handleClear,
      enabled: !_testComplete,
    ),
    if (_testComplete)
      BottomButton(
        label: 'Fullført',
        onPressed: () { _submitResult(); },
      ),
  ],
  onAbort: () => widget.run.abort('User aborted'),
  useRow: false,  // Column layout
)
```

---

### 9. Cog Test (`cog_test.dart`)
**Current**: Different phases with different buttons:
- Phase 1 (Intro): FilledButton "Neste"
- Phase 2 (Word Recall): FilledButton "Neste"
- Phase 3 (Hands/Clock): Row with buttons
- Each phase has TextButton "Avbryt" (red)

**New Pattern**: Varies by phase, example:
```dart
// Simple phase:
BottomButtonBar(
  primaryButton: BottomButton(
    label: 'Neste',
    onPressed: _handleNext,
    type: BottomButtonType.filled,  // Using filled for this one
  ),
  onAbort: widget.onAbort,
)

// Complex phase with multiple buttons:
BottomButtonBar(
  actionButtons: [
    BottomButton(label: 'Prøv igjen', onPressed: _retry),
    BottomButton(label: 'Fortsett', onPressed: _continue),
  ],
  onAbort: widget.onAbort,
  useRow: true,
)
```

---

## StroopScreen Integration Note
The `StroopScreen` widget in `stroop_helpers.dart` has its own bottom button logic:
```dart
Padding(
  padding: const EdgeInsets.all(16.0),
  child: Column(
    children: [
      if (bottomButton != null) bottomButton! else const SizedBox(),
      if (bottomButton != null) const SizedBox(height: 12) else const SizedBox(),
      TextButton(onPressed: onAbort, child: const Text('Avbryt')),
    ],
  ),
),
```

**Decision**: 
- Keep StroopScreen as-is for now (it's more specialized)
- Or refactor it to use BottomButtonBar (future improvement)
- The BottomButtonBar can replace its button section later

---

## Migration Order Recommendation
1. **Counter Test** - Simplest (1 action button + abort)
2. **Tap 10 Test** - Similar pattern to Counter
3. **Counter Tutorial** - Simple single button
4. **Tap 10 Tutorial** - Same as Counter Tutorial
5. **Stroop Tutorial** - Partial (intro button only)
6. **TMT Tutorial** - Uses convenience builder `retryAndContinueButtons()`
7. **TMT Test** - Slightly complex with conditional buttons
8. **Cog Test** - Most complex, multiple phases
9. **Stroop Test** - Keep mostly as-is or refactor StroopScreen entirely

---

## Key Design Decisions Made

✅ **Column vs Row**: Automatically selects based on button count
✅ **Consistency**: All "Avbryt" buttons are red via `AppColors.errorRed`
✅ **Spacing**: Configurable but defaults to 16px (can be set per usage)
✅ **Flexibility**: Supports 1-N buttons easily
✅ **Padding**: Consistent 16px padding by default
✅ **Disabled State**: Buttons respect enabled flag
✅ **No Breaking Changes**: Widget is additive, doesn't require immediate refactoring

---

## Next Steps
Ready to implement test by test. Each test file will:
1. Import `BottomButtonBar` and `BottomButton`
2. Replace the bottom button Column/Row code
3. Use convenience builders where applicable
4. Test that layout and functionality remain identical

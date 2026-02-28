# Rename Project to flutter-base-app Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Rename the `flutter_base_app` Flutter project to `flutter_base_app`, update all identifiers, component prefixes, and bundle IDs so the repo can serve as a generic base template at `https://github.com/luizfetrindade/flutter-base-app`.

**Architecture:** Pure rename — no logic changes. Three phases: (1) text substitution in source files via sed, (2) file/directory renames via git mv, (3) root folder rename + git remote update. Verification is running existing tests after each phase.

**Tech Stack:** Flutter, Dart, bash (sed, find, git mv)

---

### Task 1: Text substitution — bundle IDs and class names

This runs sed on all relevant source files (excluding build artifacts).

**Files:**
- Modify: all `.dart`, `.yaml`, `.arb`, `.iml`, `.plist`, `.gradle.kts`, `.xcconfig`, `.md` files
- Exclude: `build/`, `Pods/`, `.dart_tool/`, `pubspec.lock`

**Step 1: Run the substitution script**

Execute from inside the project root (`~/Desktop/Flutter Base App`):

```bash
# Define file targets (exclude generated/binary dirs)
FILES=$(find . \
  -type f \( \
    -name "*.dart" -o -name "*.yaml" -o -name "*.arb" -o \
    -name "*.iml" -o -name "*.plist" -o -name "*.gradle.kts" -o \
    -name "*.xcconfig" -o -name "*.md" \
  \) \
  ! -path "./build/*" \
  ! -path "./Pods/*" \
  ! -path "./.dart_tool/*" \
  ! -path "./ios/Pods/*" \
)

# 1. Bundle IDs (most specific first)
echo "$FILES" | xargs sed -i '' 's/com\.luizfetrindade\.gymHero/com.luizfetrindade.flutter_base_app/g'
echo "$FILES" | xargs sed -i '' 's/com\.luizfetrindade\.flutter_base_app/com.luizfetrindade.flutter_base_app/g'

# 2. Class names (before generic flutter_base_app)
echo "$FILES" | xargs sed -i '' 's/BaseDesignSystem/BaseDesignSystem/g'
echo "$FILES" | xargs sed -i '' 's/BaseButtonVariant/BaseButtonVariant/g'
echo "$FILES" | xargs sed -i '' 's/BaseButton/BaseButton/g'
echo "$FILES" | xargs sed -i '' 's/BaseCard/BaseCard/g'
echo "$FILES" | xargs sed -i '' 's/BaseInputField/BaseInputField/g'

# 3. File references (imports, exports)
echo "$FILES" | xargs sed -i '' 's/base_design_system/base_design_system/g'
echo "$FILES" | xargs sed -i '' 's/base_button_variant/base_button_variant/g'
echo "$FILES" | xargs sed -i '' 's/base_button/base_button/g'
echo "$FILES" | xargs sed -i '' 's/base_card/base_card/g'
echo "$FILES" | xargs sed -i '' 's/base_input_field/base_input_field/g'

# 4. Display name
echo "$FILES" | xargs sed -i '' 's/Flutter Base App/Flutter Base App/g'

# 5. Package name (last, most generic)
echo "$FILES" | xargs sed -i '' 's/flutter_base_app/flutter_base_app/g'
```

**Step 2: Verify the key substitutions landed correctly**

```bash
grep -r "flutter_base_app\|Flutter Base App\|com\.luizfetrindade\.gymHero\|base_button\|base_card\|gh_input\|BaseButton\|BaseCard\|BaseInputField" \
  --include="*.dart" --include="*.yaml" --include="*.arb" --include="*.plist" --include="*.gradle.kts" \
  . --exclude-dir=build --exclude-dir=Pods --exclude-dir=.dart_tool
```

Expected: **no output** (zero matches).

---

### Task 2: Rename files with git mv

Rename each source file so the file names match the new identifiers.

**Files:**
- Rename: `flutter_base_app.iml` → `flutter_base_app.iml`
- Rename: `android/flutter_base_app_android.iml` → `android/flutter_base_app_android.iml`
- Rename: `lib/design_system/base_design_system.dart` → `lib/design_system/base_design_system.dart`
- Rename: `lib/design_system/components/button/base_button.dart` → `base_button.dart`
- Rename: `lib/design_system/components/button/base_button_variant.dart` → `base_button_variant.dart`
- Rename: `lib/design_system/components/card/base_card.dart` → `base_card.dart`
- Rename: `lib/design_system/components/input/base_input_field.dart` → `base_input_field.dart`
- Rename: `test/design_system/components/button/base_button_test.dart` → `base_button_test.dart`
- Rename: `test/design_system/components/card/base_card_test.dart` → `base_card_test.dart`
- Rename: `test/design_system/components/input/base_input_field_test.dart` → `base_input_field_test.dart`

**Step 1: Run git mv for all file renames**

```bash
git mv flutter_base_app.iml flutter_base_app.iml
git mv android/flutter_base_app_android.iml android/flutter_base_app_android.iml
git mv lib/design_system/base_design_system.dart lib/design_system/base_design_system.dart
git mv lib/design_system/components/button/base_button.dart lib/design_system/components/button/base_button.dart
git mv lib/design_system/components/button/base_button_variant.dart lib/design_system/components/button/base_button_variant.dart
git mv lib/design_system/components/card/base_card.dart lib/design_system/components/card/base_card.dart
git mv lib/design_system/components/input/base_input_field.dart lib/design_system/components/input/base_input_field.dart
git mv test/design_system/components/button/base_button_test.dart test/design_system/components/button/base_button_test.dart
git mv test/design_system/components/card/base_card_test.dart test/design_system/components/card/base_card_test.dart
git mv test/design_system/components/input/base_input_field_test.dart test/design_system/components/input/base_input_field_test.dart
```

**Step 2: Verify git sees the renames**

```bash
git status
```

Expected: 10 renames listed under "Changes to be committed", plus all the text changes from Task 1 as modifications.

---

### Task 3: Verify the project compiles and tests pass

Before renaming the root folder (which would break the current terminal session path), confirm everything is consistent.

**Step 1: Get dependencies**

```bash
flutter pub get
```

Expected: Resolving dependencies... exit 0, no errors.

**Step 2: Run all tests**

```bash
flutter test
```

Expected: All tests pass. If any test fails due to a missed substitution, fix it now before proceeding.

**Step 3: Commit everything so far**

```bash
git add -A
git commit -m "refactor: rename flutter_base_app to flutter_base_app"
```

---

### Task 4: Rename root folder and update git remote

**Step 1: Move to parent directory and rename the folder**

```bash
cd ~/Desktop
mv Flutter Base App flutter-base-app
cd flutter-base-app
```

**Step 2: Update the git remote to the new GitHub repo**

```bash
git remote set-url origin https://github.com/luizfetrindade/flutter-base-app.git
```

**Step 3: Verify remote is updated**

```bash
git remote -v
```

Expected:
```
origin  https://github.com/luizfetrindade/flutter-base-app.git (fetch)
origin  https://github.com/luizfetrindade/flutter-base-app.git (push)
```

---

### Task 5: Push to GitHub

**Step 1: Push main branch to the new remote**

```bash
git push -u origin main
```

Expected: Branch 'main' set up to track remote branch 'main' from 'origin'.

**Step 2: Confirm on GitHub**

Open https://github.com/luizfetrindade/flutter-base-app and verify the code is there with the updated file names.

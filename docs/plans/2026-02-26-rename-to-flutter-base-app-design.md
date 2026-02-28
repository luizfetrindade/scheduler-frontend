# Design: Rename Project to flutter-base-app

**Date:** 2026-02-26
**Status:** Approved

## Context

The project `flutter_base_app` will be repurposed as a reusable Flutter base template (`flutter-base-app`) for forking into new apps.

## Decisions

| Decision | Value |
|---|---|
| New package name | `flutter_base_app` |
| New bundle/application ID | `com.luizfetrindade.flutter_base_app` |
| Design system component prefix | `base_` (was `gh_`) |
| Folder name | `flutter-base-app` (was `Flutter Base App`) |

## Scope of Changes

### Text substitutions (all non-binary source files)

| From | To |
|---|---|
| `flutter_base_app` | `flutter_base_app` |
| `Flutter Base App` | `Flutter Base App` |
| `gym hero` | `flutter base app` |
| `com.luizfetrindade.flutter_base_app` | `com.luizfetrindade.flutter_base_app` |
| `gh_` (component prefix) | `base_` |
| `base_design_system` | `base_design_system` |
| `BaseButton`, `BaseCard`, `BaseInputField` | `BaseButton`, `BaseCard`, `BaseInputField` |

### Files renamed

| From | To |
|---|---|
| `flutter_base_app.iml` | `flutter_base_app.iml` |
| `lib/design_system/base_design_system.dart` | `lib/design_system/base_design_system.dart` |
| `lib/design_system/components/button/base_button.dart` | `base_button.dart` |
| `lib/design_system/components/card/base_card.dart` | `base_card.dart` |
| `lib/design_system/components/input/base_input_field.dart` | `base_input_field.dart` |

### Root directory renamed

`~/Desktop/Flutter Base App/` → `~/Desktop/flutter-base-app/`

### Excluded from changes

- `build/` — generated artifacts
- `Pods/` — CocoaPods cache
- `.dart_tool/` — Dart toolchain cache
- `pubspec.lock` — dependency lock file

## What Does NOT Change

- Folder structure under `lib/` (features, core, design_system)
- All dependencies in `pubspec.yaml`
- All business logic (auth, router, i18n)

## Approach

Script-based (bash): `find` + `sed` for text substitution, then individual file renames, then folder rename. Everything is in git so the result is fully auditable and reversible.

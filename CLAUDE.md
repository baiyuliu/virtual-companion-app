# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Flutter-based cross-platform (Android/iOS) AI virtual companion app designed for elderly and mental health users. Creates personalized companions using photo upload (digital avatar) and voice recording (voice cloning).

## Essential Commands

```bash
# Install dependencies
flutter pub get

# Run on device
flutter run -d android
flutter run -d ios

# Code generation (required after modifying Hive models or Riverpod providers)
dart run build_runner build
dart run build_runner watch  # watch mode during development

# Testing
flutter test
flutter test test/widget_test.dart  # single test file

# Lint & format
flutter analyze
dart format lib/
```

## Architecture

**Pattern**: Clean Architecture + Riverpod state management

```
lib/
├── main.dart / app.dart           # Entry point & root widget
├── core/
│   ├── api/                       # Alibaba Cloud + Soul Avatar API clients
│   ├── models/                    # Hive-annotated data models
│   ├── services/                  # Platform services (audio, notifications, permissions)
│   └── utils/
│       ├── constants.dart         # API keys & system-wide config ← configure before running
│       └── memory_manager.dart    # 3-layer memory system
├── features/                      # Screen-level feature modules (each owns its UI + provider)
│   ├── onboarding/                # Photo upload → avatar creation, voice recording → cloning
│   ├── chat/                      # Main conversation loop
│   ├── memory/                    # Memory review UI
│   ├── reminder/                  # Scheduled local notifications
│   └── settings/
└── shared/                        # Reusable widgets + app theme
```

## Key Data Flows

**Onboarding**: photo → Soul Avatar API → `avatar_id` stored; voice recording → Ali TTS CosyVoice → `voice_id` stored in Hive `profile_box`.

**Chat loop**: mic → Ali NLS STT → text → [memory context injected] → Ali Qwen LLM → response text → Ali TTS (cloned voice) → audio playback + Soul Avatar animates.

**Memory system** (in `core/utils/memory_manager.dart`): Three layers all injected into every LLM system prompt:
- **Short-term**: last 20 messages (`messages_box`)
- **Episodic**: auto-generated daily summaries, 7-day window (`memory_box`)
- **Long-term**: persistent user profile — family, health info, interests (`profile_box`)

## External Services

All API credentials go in `lib/core/utils/constants.dart`:
- **Alibaba DashScope** (Qwen-Plus LLM + CosyVoice TTS)
- **Alibaba NLS** (STT + TTS, requires App Key + Access Key/Secret)
- **Soul/硅基智能 API** (digital human avatar generation)

## Code Generation Notes

Hive models use `@HiveType` / `@HiveField` annotations and require generated adapter files (`*.g.dart`). Riverpod providers using `@riverpod` annotation also generate `*.g.dart` files. Always run `build_runner build` after modifying these.

## Elderly-Friendly Constraints

- `ElderlyLanguageAdapter` (in `core/utils/`) enforces <20-char sentences, 0.85x TTS speech rate, simplified vocabulary
- Crisis keyword detection triggers alerts — do not remove or weaken this logic
- UI: portrait-only, large fonts (16-18px base), high contrast (see `shared/theme/app_theme.dart`)

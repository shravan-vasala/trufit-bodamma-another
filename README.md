# TruFit Bodamma 🌻🏋️♀️

> Made with ❤️ for Bodamma

A personal fitness tracking app built for one very important user — my sister. Local-first, private, and sideloaded: no accounts, no cloud, no ads. Her data lives on her phone and nowhere else.

<p align="center">
  <img src="assets/icon/app_icon.png" alt="TruFit Bodamma icon" width="120" />
</p>

## Features

**🏠 Home dashboard**
- Week calendar strip with per-day completion dots (grey = planned, green = done)
- Tap any past day for a summary sheet — workout, meals, habits, steps, sleep, weight, and water at a glance — with full backfill support for missed logs
- Daily progress cards for body stats, physique pictures, body weight, and steps

**💪 Workouts**
- Weekly plan driven by an editable JSON file: Mon/Tue/Thu/Fri strength days (warm up → main workout → cooldown), Wed/Sat cardio, Sunday rest
- Every exercise has an embedded YouTube demo video with in-app fullscreen playback
- Per-set rep logging, per-exercise progress history, rest reminders between sets
- Partial-completion aware: finish guard, skip option, and honest "6/9 done" records

**🍛 AI meal tracking**
- Photograph your food — Gemini identifies the dishes (tuned for South Indian home cooking), estimates portions, calories, and macros
- Editable confirmation sheet before anything is saved; manual entry always available
- Four default meal slots plus custom one-off or recurring slots, daily calorie target with macro totals

**✅ Habits**
- Fully user-defined habits with emoji, four types: checkbox, counter (e.g. water glasses), auto-from-steps, and sleep-log based
- Manual override always wins over sensors — tap the circle to check anything off

**📈 Progress charts**
- Weight, Steps, Sleep, BMI (auto-computed), Body Fat, and Calories
- Weekly / Monthly / 6-month views with gap-aware curves, auto-scaled axes, and tap tooltips
- Dated body measurements with change indicators, and side-by-side physique photo comparison with weights

**⌚ Samsung Health sync**
- Steps sync automatically via Health Connect, with 90-day backfill and 7-day revision re-reads
- Manual entries always take precedence over synced values

**💾 Backup & Restore**
- One-tap full backup (all data + photos) to a single zip via the Android share sheet
- Weekly automatic data-only backups (last 4 kept on device)
- Verify-without-restoring, and full restore onto a fresh install — new-phone migration is: install APK → restore → done
- API keys are stored in Android secure storage and are never included in backups

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Android-first, iOS-compatible) |
| State | Riverpod |
| Storage | Hive (local, date-keyed) + flutter_secure_storage for secrets |
| Charts | fl_chart |
| Video | youtube_player_iframe |
| Health data | health (Health Connect) |
| AI food scan | google_generative_ai (Gemini 2.5 Flash) |
| Navigation | go_router |

Architecture: `models → repositories → providers → screens`, all logs keyed by calendar date.

## Getting started

```bash
flutter pub get
flutter run
```

1. Build and sideload the APK (`flutter build apk --release`)
2. On first launch, set your name, height, and daily calorie target in **Profile → Edit Profile**
3. For AI food scanning: create a free API key at [Google AI Studio](https://aistudio.google.com) and paste it into **Profile → AI Settings**
4. For step/sleep sync: enable data sharing in **Samsung Health → Settings → Health Connect**, then grant permission when the app asks
5. Edit the workout in `assets/data/seed_workout_plan.json` (or in-app via **Profile → Manage Plans**) — each exercise takes a `youtubeUrl`, `displayName`, `reps`, optional coach `note`, and rest time

## Privacy

- 100% local data — no backend, no analytics, no account
- The only network calls: YouTube video playback and the Gemini food-scan API (opt-in, your own key)
- Backups are plain zips you control; share them only with people you trust

## Project structure

```
lib/
├── models/          # Habit, DailyLog, WorkoutPlan, UserProfile, ...
├── repositories/    # Hive-backed, date-keyed persistence
├── providers/       # Riverpod state
├── services/        # Health Connect, Gemini, Backup
├── screens/         # Home, Workout, Progress, Profile
└── router/          # go_router shell with 3 tabs
assets/data/         # Editable workout & meal plan JSON
```

## Credits

Built by a brother, one prompt at a time — vibe-coded with AI agents (Antigravity + Claude), reviewed by Claude, and shaped by real feedback from its one and only user.

🌻 The sunflower-and-dumbbell icon: because she likes both, and because growth takes strength.

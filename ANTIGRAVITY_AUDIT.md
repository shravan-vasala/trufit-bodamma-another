# TruFit Bodamma — Post-Improvement Code Audit

> **Purpose:** Paste sections from this document into Antigravity to fix bugs, clean up code, and improve quality.  
> **Audited:** After onboarding, dark mode, coach caching, rest timer, weekly summary, macros, PRs, reminders, encrypted backup, CSV export, schema migrations, and related changes.  
> **Note:** `flutter analyze` / `flutter test` could not be run in the audit environment (Flutter not on PATH). Run locally before release.

---

## Executive Summary

The app has grown significantly and most new features are **partially integrated**. The highest-risk issues are:

| Priority | Count | Theme |
|----------|-------|-------|
| P0 Critical | 5 | Broken user flows (onboarding, coach notes, dark mode, exercise completion split) |
| P1 High | 8 | Wrong data (daily score meals, notifications timezone, backup gaps) |
| P2 Medium | 12 | Incomplete wiring, duplicate logic, missing invalidations |
| Cleanup | 6 | Dead files, duplicate UI, manifest noise |
| Performance | 7 | Provider over-subscription, unbounded streak loops |
| Testing | 5 | Missing coverage for new features |

**Recommended fix order:** P0 → P1 → Performance → P2 → Cleanup → Tests

---

## P0 — Critical Bugs (Fix First)

### BUG-001: Onboarding screen exists but is never shown

**Files:** `lib/screens/onboarding/onboarding_screen.dart`, `lib/router/app_router.dart`, `lib/screens/home/home_screen.dart`

**Problem:**
- `OnboardingScreen` is fully built with 5 steps and `kOnboardingCompletedKey`.
- **No route** registered in `app_router.dart`.
- **No redirect** checks `onboarding_completed` in SharedPreferences.
- `HomeScreen` still shows legacy `_showNamePrompt()` dialog when `profile.name.isEmpty`.

**Impact:** Users never see onboarding; duplicate/conflicting first-run UX.

**Antigravity prompt:**
```
Wire up onboarding in TruFit Bodamma (Flutter + go_router + Riverpod):

1. Add top-level route `/onboarding` → OnboardingScreen (outside bottom nav shell)
2. In app_router redirect: read SharedPreferences key `onboarding_completed` (from onboarding_screen.dart). If false and path != /onboarding → redirect to /onboarding
3. Remove _showNamePrompt() and related logic from home_screen.dart entirely
4. On onboarding complete, set onboarding_completed=true and context.go('/home')
5. Use sharedPreferencesProvider already overridden in main.dart — do not create duplicate prefs instances in router; pass via redirect ref or read prefs async in GoRouter refreshListenable

Acceptance: fresh install shows onboarding once; returning users go straight to /home
```

---

### BUG-002: Coach note stuck on loading when Health Connect is not authorized

**File:** `lib/screens/home/home_screen.dart` → `_syncSteps()`

**Problem:**
```dart
final isAuth = await hcService.isAuthorized();
if (!isAuth) return;  // ← exits before coach note fetch

if (isManualRefresh) {
  ref.read(coachNoteProvider.notifier).fetchNote(force: true);
}
```

- `CoachNoteNotifier` initial state is `AsyncValue.loading()`.
- First load calls `_syncSteps(isManualRefresh: true)` but **returns early** if HC denied/unavailable.
- Coach card spins forever; templated fallback never runs.

**Antigravity prompt:**
```
Fix coach note never loading when Health Connect is unavailable.

In home_screen.dart _syncSteps():
- Do NOT return early before coach note logic
- Structure as:
  1. If HC authorized → sync steps (existing logic)
  2. Always invalidate dailyLogProvider + habitCompletionsProvider after sync attempt
  3. On first visit OR manual refresh: call coachNoteProvider.fetchNote() — use force:false on resume, force:true on pull-to-refresh
- In CoachNotesCard or CoachNoteNotifier constructor: auto-fetch on first build if state is loading and no cache exists
- fetchNote() must always resolve to data (templated fallback) or error — never stay loading indefinitely

Files: home_screen.dart, coach_notes_card.dart, app_providers.dart (CoachNoteNotifier)
```

---

### BUG-003: Dark mode breaks button/icon contrast (`context.colors.white`)

**File:** `lib/theme/app_colors.dart`

**Problem:**
- `AppColorsDark.white` is mapped to `#1A1A24` (card gray), not actual white.
- Used for text on purple/orange/green buttons: rest timer, finish workout, nav selected label, coach icon, checkmarks.

**Impact:** Dark mode makes primary-button text nearly invisible.

**Antigravity prompt:**
```
Fix dark mode color semantics in app_colors.dart.

Problem: AppColorsDark.white = #1A1A24 is used for button TEXT on colored backgrounds — unreadable.

Solution (pick one, prefer A):
A) Split palette tokens:
   - surface / card → dark gray (#1A1A24)
   - onPrimary / onAccent → always #FFFFFF for text/icons on purple, orange, green
   - Update AppColorsPalette interface with onPrimary, onSurface, surface, card
   - Migrate button text from context.colors.white to context.colors.onPrimary where background is primary/orange/green

B) Keep white as literal white in both themes; add separate cardColor token for card backgrounds

Audit all usages of context.colors.white — ~40 files. Card backgrounds use surface/card; colored buttons use onPrimary.

Run visual check on: bottom nav, rest timer overlay, Finish Workout button, habit checkmarks, onboarding gradient buttons.
```

---

### BUG-004: Dual exercise completion systems are inconsistent

**Files:** `exercise_card.dart`, `log_data_dialog.dart`, `home_screen.dart` (_WorkoutsSection), `workout_screen.dart`, `daily_score_provider.dart`

**Problem:**
Two parallel tracking mechanisms:

| Mechanism | Storage | Used by |
|-----------|---------|---------|
| `exerciseCompletionsProvider` toggle | `workout_sessions` Hive | Workout screen UI checkmarks |
| `ExerciseLog` via Log Data | `exercise_logs` Hive | Home section completion, daily score |

- Tapping checkmark ≠ logging data.
- Logging data via `LogDataDialog` does **not** toggle completion or start rest timer.
- Home shows section complete based on `hasLog()`; workout screen shows incomplete checkmark.

**Antigravity prompt:**
```
Unify exercise completion in TruFit Bodamma — single source of truth.

Rule: An exercise is "complete" when ExerciseLog exists for that date+exerciseName (exerciseLogRepo.hasLog).

Changes:
1. Remove exerciseCompletionsProvider toggle from exercise_card.dart — derive isCompleted from ref.watch + hasLog(dateStr, exercise.name)
2. On LogDataDialog._save(): after saveLog(), start rest timer if exercise.restSecondsAfterSet > 0; invalidate any dependent providers
3. Optional: keep checkmark tap as shortcut that opens LogDataDialog pre-filled (not a separate boolean state)
4. Remove or deprecate WorkoutRepository.toggleExerciseCompletion / workout_sessions box if unused elsewhere
5. Update daily_score_provider to only use hasLog (remove completionsMap OR fallback)
6. Ensure home _WorkoutsSection and workout_screen use same completion logic

Add unit test: saving exercise log marks section complete on home and workout screen.
```

---

### BUG-005: `_syncSteps` blocks all refresh when HC unauthorized

**File:** `lib/screens/home/home_screen.dart`

**Problem:** Same early return prevents `ref.invalidate(dailyLogProvider)` on resume when HC not connected. Manual entries (weight, sleep, steps) won't refresh UI after external changes.

**Fix:** Split HC sync from UI refresh; always invalidate providers after lifecycle resume.

---

## P1 — High Priority Bugs

### BUG-006: Daily score meals calculation uses wrong key

**File:** `lib/providers/daily_score_provider.dart` ~line 123

**Problem:**
```dart
for (final slot in mealPlan.meals) {
  if (mealLog.customSlots.containsKey(slot.name)) {  // WRONG
```
- `Meal.type` = `"breakfast"`, `"lunch"`, etc.
- `Meal.name` = `"Protein Breakfast"`, `"Balanced Lunch"`.
- `customSlots` keys are slot IDs (`breakfast`, `lunch`, …).

**Impact:** Daily score ring almost always shows 0% meal contribution.

**Fix:** Change to `slot.type` or map via `profile.customMealSlots`.

---

### BUG-007: Notification timezone hardcoded to `America/Detroit`

**File:** `lib/services/notification_service.dart` line 21

**Problem:**
```dart
tz.setLocalLocation(tz.getLocation('America/Detroit'));
```

**Impact:** All reminders fire at wrong local time for users in India (UTC+5:30) or anywhere else.

**Fix:** Add `flutter_timezone` package OR use `timezone` with platform local identifier. Set `tz.local` from device timezone in `init()`.

---

### BUG-008: `exercise_prs` Hive box not included in backup

**Files:** `lib/repositories/exercise_log_repository.dart`, `lib/services/backup_service.dart`

**Problem:** PRs stored in separate `exercise_prs` box. `_boxesToBackup` list does not include it.

**Impact:** Restore loses all personal records.

**Fix:** Add `'exercise_prs'` to `_boxesToBackup`.

---

### BUG-009: Onboarding habit selection doesn't remove deselected habits

**Files:** `lib/screens/onboarding/onboarding_screen.dart`, `lib/repositories/habit_repository.dart`

**Problem:**
- `HabitRepository.init()` seeds all 3 default habits on first launch.
- Onboarding `_saveGoals()` only **saves** selected habits — never **deletes** unselected ones.

**Impact:** User deselects "water" in onboarding but still sees it on home.

**Fix:** In `_saveGoals()`, delete habits whose IDs are not in `_selectedHabitIds`. Or clear config box and re-seed only selected.

---

### BUG-010: Phase progress counts `workoutCompleted` not section logs

**File:** `lib/providers/phase_progress_provider.dart`

**Problem:** Week progress uses `dailyLog.workoutCompleted` (set by "Finish Workout" button). User can finish early with 0 exercises logged and count toward phase week.

**Fix:** Align with section/exercise log completion OR rename UI to "workout days marked complete".

---

### BUG-011: Weekly summary over-counts workouts when day marked complete

**File:** `lib/providers/weekly_summary_provider.dart` lines 107-109

**Problem:** If `workoutCompleted=true`, adds **all** sections for that day to `wCompleted` without verifying exercise logs.

**Fix:** Count sections individually via `exerciseLogRepo.hasLog` like home screen does.

---

### BUG-012: `markWorkoutCompleted` double-saves profile with stale state

**File:** `lib/providers/app_providers.dart` ~line 229

**Problem:**
```dart
profileRepo.saveProfile(profile.copyWith(planStartDate: ...));
_ref.read(profileProvider.notifier).updateProfile(profile.copyWith(...)); // uses old profile variable
```

**Fix:** Single call via `profileProvider.notifier.updateProfile` only.

---

### BUG-013: Log data save doesn't refresh workout UI

**File:** `lib/screens/workout/log_data_dialog.dart`

**Problem:** After `repo.saveLog(log)`, no `ref.invalidate()` — workout progress bar and home cards may not update until manual refresh.

**Fix:** Invalidate `dailyLogProvider` or add `exerciseLogsChangedProvider` trigger.

---

## P2 — Medium Issues

### BUG-014: `app_router.dart` missing query params for `calories` and `macros`

**File:** `lib/router/app_router.dart`

**Problem:** Progress deep-link handles weight/steps/sleep/bmi/bodyFat but not `calories` or `macros`. Redirect sends `metric=calories` to `/home/meals` instead of progress tab.

---

### BUG-015: Schema migration v2 incomplete

**File:** `lib/services/schema_migration_service.dart`

**Missing defaults for:**
- `currentPhaseWeek`
- `restTimerSound` / `restTimerVibration`

**Fix:** Add to `_applyV2UserProfileChanges` or create v3 migration.

---

### BUG-016: Reminder config stored in SharedPreferences — not in backup

**File:** `lib/providers/reminders_provider.dart`

**Impact:** Restore backup loses reminder settings. Document as intentional OR export `reminder_config` in backup manifest metadata.

---

### BUG-017: `ThemeModeNotifier` opens separate SharedPreferences

**File:** `lib/providers/theme_provider.dart`

**Problem:** Does not use `sharedPreferencesProvider` from main.dart — minor but inconsistent.

---

### BUG-018: `OfflineBanner` uses hardcoded amber colors

**File:** `lib/widgets/offline_banner.dart`

**Problem:** Ignores `context.colors`; looks wrong in dark mode.

---

### BUG-019: `CoachNotesCard` watches `profileProvider` but never uses it

**File:** `lib/screens/home/widgets/coach_notes_card.dart`

**Fix:** Remove unused watch or use for API key status display.

---

### BUG-020: AndroidManifest duplicate `flutterEmbedding` meta-data

**File:** `android/app/src/main/AndroidManifest.xml` lines 11-13 and 80-83

**Fix:** Remove duplicate block.

---

### BUG-021: Workout reminder weekday mapping assumes plan index = weekday

**File:** `lib/providers/reminders_provider.dart`

**Problem:** `activeDays.add(i + 1)` assumes `workoutPlan.days[0]` = Monday. Breaks if plan order differs or has Rest mid-week.

**Fix:** Map by `dayId`/`label` or store explicit weekday on WorkoutDay model.

---

### BUG-022: Rest timer snackbar shows stale `exerciseName` after completion

**File:** `lib/providers/rest_timer_provider.dart` `_onTimerComplete()`

**Problem:** Sets `isActive: false` in state copyWith but reads `state.exerciseName` after — may be null depending on copyWith order.

**Fix:** Capture `exerciseName` in local variable before clearing state.

---

### BUG-023: `habitStreakProvider` unbounded backward loop

**File:** `lib/providers/app_providers.dart`

**Problem:** `while (true)` walks backwards indefinitely for users with long streaks — O(n) on every rebuild.

**Fix:** Cap at 365 days or cache streak in repository on write.

---

### BUG-024: `getAllProgressPhotosDetailed().first` for last photo date

**File:** `lib/providers/reminders_provider.dart`

**Problem:** Assumes first item is latest. Verify sort order in `MediaRepository` or sort explicitly.

---

### BUG-025: Encrypted backup photos skip on decrypt failure silently

**File:** `lib/services/backup_service.dart`

**Problem:** `continue` on photo decrypt fail — restore succeeds partially without user warning.

**Fix:** Collect failures and show count in restore result UI.

---

## Code Cleanup — Remove / Consolidate

### CLEAN-001: Delete stray test files in `lib/`

**Files to DELETE:**
- `lib/test_const.dart`
- `lib/test_const2.dart`
- `lib/test_const4.dart`

These are junk one-liner widgets with fake `AppColors` — not part of the app.

---

### CLEAN-002: Duplicate first-run name prompt

Remove `_showNamePrompt()` from `home_screen.dart` once onboarding is wired (BUG-001).

---

### CLEAN-003: `refreshTriggerProvider` fully removed — verify no stale references

Grep for `refreshTriggerProvider` — should be zero hits. If any remain, replace with targeted `ref.invalidate()`.

---

### CLEAN-004: Consolidate `sharedPreferencesProvider`

Currently defined in `reminders_provider.dart`. Move to `app_providers.dart` and import everywhere (theme, onboarding, router redirect).

---

### CLEAN-005: Move `CoachNote` model out of repository file

**File:** `lib/repositories/coach_note_repository.dart`

Move `CoachNote` class to `lib/models/coach_note.dart` for consistency with other entities.

---

### CLEAN-006: Remove `const` inconsistency on shell routes

**File:** `app_router.dart`

Several screens use `HomeScreen()` without `const` while others use `const`. Add `const` constructors consistently where possible.

---

## Performance Optimizations

### PERF-001: `context.colors` creates new palette instance every access

**File:** `lib/theme/app_colors.dart`

```dart
Theme.of(this).brightness == Brightness.dark ? AppColorsDark() : AppColorsLight();
```

**Fix:** Use static singletons:
```dart
static final light = AppColorsLight();
static final dark = AppColorsDark();
```

---

### PERF-002: `dailyScoreProvider` over-watches

**File:** `lib/providers/daily_score_provider.dart`

Watches full `dailyLogProvider`, `mealPlanProvider`, `workoutPlanProvider`, and `exerciseCompletionsProvider.family` — triggers recompute on any field change.

**Fix:** Use `.select()` for only needed fields (steps, workoutCompleted).

---

### PERF-003: `habitStreakProvider` recomputes full history on every habit toggle

**Fix:** Memoize by `(habitId, dateString)` or compute streak in repository on write.

---

### PERF-004: `ExerciseCard` calls `getPr()` synchronously in build

**File:** `exercise_card.dart`

**Fix:** `exercisePrProvider.family(exerciseName)` cached provider.

---

### PERF-005: `coachServiceProvider` rebuilds on any profile change

**File:** `app_providers.dart`

Watches entire `profileProvider` but only needs `geminiApiKey`.

**Fix:** `ref.watch(profileProvider.select((p) => p.geminiApiKey))`

---

### PERF-006: `dailyMealLogsRangeProvider` loops day-by-day

**Fix:** Add `MealRepository.getLogsInRange(start, end)` batch method.

---

### PERF-007: Home screen `_syncSteps` on every resume triggers 7-day + 90-day HC sync

**Fix:** Debounce: only full sync if last sync > 15 minutes ago (store timestamp in SharedPreferences).

---

## Quality & Testing Gaps

### Current test coverage (good start)

| File | Covers |
|------|--------|
| `test/widget_test.dart` | Model JSON parsing |
| `test/repositories/daily_log_repository_test.dart` | Daily log CRUD |
| `test/repositories/habit_repository_test.dart` | Habit completion |
| `test/repositories/exercise_log_repository_test.dart` | Exercise logs |
| `test/repositories/workout_repository_test.dart` | Workout completion |
| `test/providers/habit_streak_test.dart` | Streak logic |
| `test/utils/pr_calculator_test.dart` | PR calculation |
| `test/services/backup_service_test.dart` | Backup manifest |

### Missing tests (add these)

```
TEST-001: daily_score_provider_test.dart — verify meal scoring uses slot.type not slot.name
TEST-002: coach_note_notifier_test.dart — cache hit, force refresh, fallback without API key
TEST-003: schema_migration_service_test.dart — v1→v2 profile fields added
TEST-004: backup round-trip with exercise_prs box
TEST-005: encrypted backup create + restore with password
TEST-006: phase_progress_provider_test.dart — week boundary calculations
TEST-007: onboarding habit deselection removes unselected habits
```

### Run before release

```powershell
cd c:\Users\sande\OneDrive\Desktop\trufit\trufit-bodamma
flutter analyze
flutter test
flutter build apk --profile
```

---

## Architecture Improvements

### ARCH-001: Single completion source of truth (see BUG-004)

Document in README: **ExerciseLog = completion** for workouts.

---

### ARCH-002: GoRouter refresh for onboarding + theme

Use `GoRouterRefreshStream` or `refreshListenable` tied to SharedPreferences / profile changes so redirect runs after onboarding completes without manual navigation hack.

---

### ARCH-003: Backup manifest version registry

When adding Hive boxes, enforce checklist:
1. Add to `_boxesToBackup`
2. Add migration if schema changes
3. Add test in `backup_service_test.dart`

Current missing: `exercise_prs`

---

### ARCH-004: Feature flags for optional services

Pattern for Gemini / HC / Notifications:
```dart
enum FeatureAvailability { available, unavailable, disabled }
```
Prevents UI stuck states when optional services fail.

---

## Antigravity Sprint Plan (Recommended Order)

Copy one block at a time into Antigravity.

### Sprint 1 — Broken flows (1-2 days)

1. BUG-001 — Wire onboarding
2. BUG-002 + BUG-005 — Fix coach note + sync decoupling
3. BUG-004 — Unify exercise completion
4. BUG-003 — Fix dark mode onPrimary colors

### Sprint 2 — Wrong data (1 day)

5. BUG-006 — Daily score meals key
6. BUG-007 — Notification timezone
7. BUG-008 — Backup exercise_prs
8. BUG-009 — Onboarding habit deselection

### Sprint 3 — Accuracy (1 day)

9. BUG-010 + BUG-011 — Phase + weekly summary workout counting
10. BUG-013 — Invalidate after log save
11. BUG-012 — Profile double-save

### Sprint 4 — Polish & perf (1 day)

12. CLEAN-001 — Delete test_const files
13. PERF-001 through PERF-005
14. BUG-014 — Router query params
15. Schema v3 migration for missing fields

### Sprint 5 — Tests (1 day)

16. TEST-001 through TEST-005

---

## Quick-Fix Prompts (Copy-Paste Ready)

### Fix daily score meals (BUG-006)

```
In lib/providers/daily_score_provider.dart, fix meal score calculation.

customSlots keys are slot IDs: 'breakfast', 'lunch', 'snack', 'dinner' — NOT meal display names.

Replace:
  mealLog.customSlots.containsKey(slot.name)
With:
  mealLog.customSlots.containsKey(slot.type)

Also consider profile.customMealSlots for custom slots. Match logic used in meals_card.dart (loggedSlotsCount).

Add test in test/providers/daily_score_provider_test.dart proving a logged breakfast slot contributes to mealsScore.
```

---

### Fix notification timezone (BUG-007)

```
Fix NotificationService timezone for TruFit Bodamma (Android, user in India).

Problem: tz.setLocalLocation(tz.getLocation('America/Detroit')) hardcoded in notification_service.dart

Solution:
1. Add flutter_timezone to pubspec.yaml
2. In NotificationService.init(): final tzName = await FlutterTimezone.getLocalTimezone(); tz.setLocalLocation(tz.getLocation(tzName));
3. Fallback to 'Asia/Kolkata' or UTC if lookup fails
4. Remove America/Detroit hardcode

Verify scheduleHabitReminder fires at correct local hour on device.
```

---

### Delete junk files (CLEAN-001)

```
Delete these unused files from lib/ — they are not imported anywhere:
- lib/test_const.dart
- lib/test_const2.dart
- lib/test_const4.dart

Run grep to confirm zero imports before deleting.
```

---

### Add exercise_prs to backup (BUG-008)

```
In lib/services/backup_service.dart, add 'exercise_prs' to _boxesToBackup list (after 'exercise_logs').

Add test in test/services/backup_service_test.dart:
1. Seed exercise_prs box with a sample PR JSON
2. createBackup() → restoreBackup() round trip
3. Assert PR data survives

exercise_prs box is opened in ExerciseLogRepository.init().
```

---

## Files Changed Summary (New Features — Verify Integration)

| Feature | Key Files | Integration Status |
|---------|-----------|-------------------|
| Onboarding | `onboarding_screen.dart` | ❌ Not routed |
| Dark mode | `app_colors.dart`, `theme_provider.dart` | ⚠️ Contrast bugs |
| Coach cache | `coach_note_repository.dart`, `CoachNoteNotifier` | ⚠️ Blocked by HC early return |
| Rest timer+ | `rest_timer_provider.dart`, `app_router.dart` | ✅ Mostly working |
| Daily score | `daily_score_provider.dart`, `week_calendar_strip.dart` | ⚠️ Meals score wrong |
| Weekly summary | `weekly_summary_screen.dart`, provider | ⚠️ Workout over-count |
| Macros | `meals_card.dart`, `progress_screen.dart` | ✅ Working |
| PRs | `pr_calculator.dart`, `log_data_dialog.dart` | ⚠️ Not backed up |
| Reminders | `notification_service.dart`, `reminders_screen.dart` | ⚠️ Wrong timezone |
| Encrypted backup | `backup_encryption_service.dart` | ✅ Implemented |
| CSV export | `csv_export_service.dart` | ✅ Verify in profile UI |
| Schema migration | `schema_migration_service.dart` | ⚠️ Incomplete fields |
| Phase progress | `phase_progress_provider.dart` | ⚠️ Loose completion rules |
| Section filter | `workout_screen.dart` | ✅ Working |
| Accessibility | Semantics on habits, nav, meals | ✅ Partial |
| Error cards | `async_error_card.dart` | ✅ Used in coach, photo scanner |
| Offline banner | `offline_banner.dart` | ⚠️ Dark mode colors |

---

## Local Verification Checklist

After Antigravity fixes, manually test:

- [ ] Fresh install → onboarding → home (no name dialog)
- [ ] Deny Health Connect → coach note still appears (templated)
- [ ] Dark mode → all buttons readable
- [ ] Log exercise data → home workout section turns green without manual checkmark
- [ ] Daily score ring → meals contribute after logging breakfast
- [ ] Set habit reminder 2 min from now → fires at correct local time
- [ ] Backup → uninstall → restore → PRs still visible on exercise card
- [ ] Onboarding with only sleep+walk habits → water habit absent
- [ ] Pull-to-refresh home → steps sync + coach refreshes
- [ ] Encrypted backup round-trip with password

---

*Generated from static analysis of TruFit Bodamma codebase. Re-run audit after each sprint.*

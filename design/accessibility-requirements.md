# Accessibility Requirements

> **Status**: Baseline
> **Author**: Scott + ux-designer
> **Last Updated**: 2026-05-26
> **Accessibility Tier**: Standard

---

## Commitment

Dragon Forge targets a Standard accessibility baseline for PC with full gamepad support and keyboard/mouse fallback. Every required MVP flow must be completable with d-pad or keyboard directional input plus confirm/cancel, without relying on mouse hover, color alone, audio alone, or fast repeated inputs.

This baseline is binding for UX specs, UI implementation stories, and QA acceptance criteria. Individual screens may exceed this tier, but may not go below it without an explicit design revision.

---

## Input

- All required flows must support gamepad d-pad navigation, confirm, and cancel.
- Keyboard fallback must expose the same semantic actions as gamepad: directional navigation, confirm, cancel, tab focus where appropriate, and escape/back.
- Mouse hover may add presentation feedback, but must not replace keyboard/gamepad focus.
- Focus order must be authored and testable for Hub, Shop, Campaign Map, Battle TELEGRAPH, Hatchery, Fusion, Crown, Journal, and terminals.
- Hold interactions must have configurable timing when they gate core actions. Shop `DWELL_REVEAL_THRESHOLD` is a player accessibility setting with a default of 400 ms and an option to disable dwell reveal.
- Irreversible actions must require an explicit confirmation step or hold-confirm pattern and must not trigger from a single accidental tap.
- Controller disconnect must preserve current focus and allow keyboard fallback without losing state.

---

## Visual

- Text must meet WCAG AA contrast targets against its immediate background.
- HUD and menu text must remain readable at 1080p from couch/gamepad distance. Minimum body text target: 18 px equivalent; compact labels may go smaller only when paired with icons and tested for legibility.
- Color-coded state must also be communicated by text, icon shape, pattern, position, or motion profile.
- Element icons, shiny indicators, corruption class, stability class, owned/in-pack states, disabled states, and HP danger states cannot rely on color alone.
- Focus indicators must be visible at rest and must not require hover.
- Flashing, full-screen pulses, corruption glitches, and battle hit effects must respect a reduced-flash/reduced-motion setting.
- The Campaign Map matrix tracker must use filled/hollow icons plus accessible labels, not color alone.

---

## Audio And Haptics

- Audio cues may reinforce information, but every required cue must have a visual or textual equivalent.
- UI confirm/cancel, blocked action, save progress, battle TELEGRAPH, Counter readiness, and KO states must remain legible when music or corruption effects are degraded.
- Controller rumble must be optional.
- Mirror Admin tritone-counter cues must have a visible counter-ready affordance and phase indicator.

---

## Cognitive Load

- Menus must expose disabled but relevant actions where learning depends on seeing them, with clear disabled feedback.
- Error and denial states must explain what happened without revealing hidden stat requirements when GDDs preserve lore opacity.
- Confirmation dialogs must show the action, cost, current balance where relevant, projected balance where relevant, and confirm/cancel affordances.
- Post-commit feedback must happen only after durable state succeeds for purchases, rewards, progression, and endings.
- Long lists, including Roster, must support predictable scrolling and must not wrap unexpectedly unless the relevant GDD explicitly requires wrap.

---

## Screen Reader And Text Alternatives

- Non-text icons must have accessible labels in UI data, even if full screen-reader integration is deferred until implementation.
- Animated result screens must have text summaries of the outcome.
- Dragon cards must expose name, element, level, stage, shiny state, HP, and any relevant status as text-accessible data.
- Corruption class, Mirror Admin phase, and Counter readiness must be available as text labels.

---

## QA Baseline

- Verify every MVP screen with gamepad only and keyboard only.
- Verify mouse hover does not steal keyboard/gamepad focus under Godot 4.6 dual-focus behavior.
- Verify every disabled action produces visible feedback and preserves state.
- Verify reduced-motion mode bypasses Hatchery reveal animation and suppresses high-motion transitions.
- Verify colorblind-safe communication for elements, HP danger, corruption class, stability class, shiny state, and owned/in-pack states.
- Verify no required gameplay information is audio-only.

---

## Follow-Up Questions

- Final screen-reader implementation scope depends on Godot 4.6 UI support and target store requirements.
- Exact font family, icon language, and safe-zone measurements should be locked when Art Bible Sections 5-9 are complete.
- Corruption rendering and restored gold-code overlays must follow ADR-0011 before final accessibility sign-off.

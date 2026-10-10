---
name: camera-feel
description: Own action camera behavior: follow, look-ahead, shake, impact punch, zoom, framing, boss arenas and comfort constraints.
---

# Camera Feel

Use this skill when implementing, reviewing, tuning, or debugging own action camera behavior: follow, look-ahead, shake, impact punch, zoom, framing, boss arenas and comfort constraints. in this Godot 2D/2.5D action/metroidvania project.

## Workflow

- Keep the player and threats readable; camera effects must never hide gameplay information.
- Separate baseline follow behavior from additive impulses such as shake/zoom/offset.
- Scale shake by hit severity and distance; cap stacking to avoid nausea/noise.
- Smooth transitions into boss framing, rooms and vertical traversal.
- Avoid camera motion that fights player movement or causes collision jitter.
- Make amplitude, frequency, duration, zoom and damping tunable.
- Test repeated hits, rapid combos, aerial combat and edge-of-room cases.

## Godot project rules

- Read the repository's `AGENTS.md`, project conventions, input map, autoloads, scene ownership and save/data formats before changing architecture.
- Prefer the project's existing language and patterns; do not migrate GDScript/C# or replace established systems without a concrete reason.
- Avoid unrelated refactors while tuning gameplay.
- Keep designer-facing values centralized and named with units where useful (seconds, pixels/sec, degrees, etc.).
- Never fabricate playtest results, profiler measurements, screenshots or successful runtime checks.

## Completion report

Report: files changed, behavior changed, tunable parameters changed, tests/playtests actually performed, remaining risks, and the next recommended test.

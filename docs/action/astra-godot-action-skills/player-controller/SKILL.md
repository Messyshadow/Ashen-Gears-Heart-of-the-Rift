---
name: player-controller
description: Own responsive player locomotion and action input: run, jump, fall, dash, dodge, wall actions, air control and state transitions.
---

# Player Controller

Use this skill when implementing, reviewing, tuning, or debugging own responsive player locomotion and action input: run, jump, fall, dash, dodge, wall actions, air control and state transitions. in this Godot 2D/2.5D action/metroidvania project.

## Workflow

- Preserve deterministic, responsive input handling.
- Cover acceleration/deceleration, coyote time, jump buffer, variable jump, air control, dash/dodge and wall interactions when present.
- Define priority between locomotion, attack, hurt, dodge, parry and scripted states.
- Avoid frame-rate-dependent movement; use Godot physics timing correctly.
- Keep movement parameters data-driven.
- Test edge cases: ledges, slopes, corners, rapid direction changes, simultaneous inputs and transitions into/out of combat.
- Run playtest after meaningful controller changes.

## Godot project rules

- Read the repository's `AGENTS.md`, project conventions, input map, autoloads, scene ownership and save/data formats before changing architecture.
- Prefer the project's existing language and patterns; do not migrate GDScript/C# or replace established systems without a concrete reason.
- Avoid unrelated refactors while tuning gameplay.
- Keep designer-facing values centralized and named with units where useful (seconds, pixels/sec, degrees, etc.).
- Never fabricate playtest results, profiler measurements, screenshots or successful runtime checks.

## Completion report

Report: files changed, behavior changed, tunable parameters changed, tests/playtests actually performed, remaining risks, and the next recommended test.

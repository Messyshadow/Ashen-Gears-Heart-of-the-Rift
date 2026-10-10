---
name: enemy-ai
description: Own ordinary enemy perception, navigation, tactical state selection, attacks, recovery, reactions and encounter readability.
---

# Enemy AI

Use this skill when implementing, reviewing, tuning, or debugging own ordinary enemy perception, navigation, tactical state selection, attacks, recovery, reactions and encounter readability. in this Godot 2D/2.5D action/metroidvania project.

## Workflow

- Inspect existing FSM/behavior architecture before adding another AI framework.
- Model clear states such as idle/patrol/alert/chase/position/attack/recover/hurt/dead as appropriate.
- Give attacks readable telegraphs and fair recovery windows.
- Prevent attack spam, oscillation and impossible tracking; use cooldowns, commitment and distance bands.
- Integrate hit reactions, stagger, armor and knockback with combat-feel.
- Test one enemy alone and in groups; check crowd pressure and off-screen behavior.
- Run playtest and record reproducible AI failures.

## Godot project rules

- Read the repository's `AGENTS.md`, project conventions, input map, autoloads, scene ownership and save/data formats before changing architecture.
- Prefer the project's existing language and patterns; do not migrate GDScript/C# or replace established systems without a concrete reason.
- Avoid unrelated refactors while tuning gameplay.
- Keep designer-facing values centralized and named with units where useful (seconds, pixels/sec, degrees, etc.).
- Never fabricate playtest results, profiler measurements, screenshots or successful runtime checks.

## Completion report

Report: files changed, behavior changed, tunable parameters changed, tests/playtests actually performed, remaining risks, and the next recommended test.

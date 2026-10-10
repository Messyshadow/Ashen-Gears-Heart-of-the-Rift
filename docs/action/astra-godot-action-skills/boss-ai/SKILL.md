---
name: boss-ai
description: Own boss encounter logic: phases, move selection, spacing, anti-repeat rules, telegraphs, punish windows and difficulty escalation.
---

# Boss AI

Use this skill when implementing, reviewing, tuning, or debugging own boss encounter logic: phases, move selection, spacing, anti-repeat rules, telegraphs, punish windows and difficulty escalation. in this Godot 2D/2.5D action/metroidvania project.

## Workflow

- Treat bosses as authored encounters, not scaled normal enemies.
- Define phase entry/exit conditions and a move-selection policy with distance/context requirements.
- Avoid unfair chains: enforce telegraphs, commitments, cooldowns and punish windows.
- Add anti-repeat weighting and prevent impossible reactions to player input.
- Coordinate attacks with combat-animation, combat-feel, VFX and camera.
- Test each move independently, each phase, transitions, low-health behavior and repeated full fights.
- Tune difficulty by readability and decision pressure before raw damage/HP.

## Godot project rules

- Read the repository's `AGENTS.md`, project conventions, input map, autoloads, scene ownership and save/data formats before changing architecture.
- Prefer the project's existing language and patterns; do not migrate GDScript/C# or replace established systems without a concrete reason.
- Avoid unrelated refactors while tuning gameplay.
- Keep designer-facing values centralized and named with units where useful (seconds, pixels/sec, degrees, etc.).
- Never fabricate playtest results, profiler measurements, screenshots or successful runtime checks.

## Completion report

Report: files changed, behavior changed, tunable parameters changed, tests/playtests actually performed, remaining risks, and the next recommended test.

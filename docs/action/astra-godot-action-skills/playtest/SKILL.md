---
name: playtest
description: Own the verification loop: run the project, reproduce scenarios, observe behavior, record evidence, tune and regression-test.
---

# Playtest

Use this skill when implementing, reviewing, tuning, or debugging own the verification loop: run the project, reproduce scenarios, observe behavior, record evidence, tune and regression-test. in this Godot 2D/2.5D action/metroidvania project.

## Workflow

- Do not claim a gameplay change is good merely because code compiles.
- Before testing, state the scenario and expected observable result.
- Run available automated tests/static checks first, then the game when the environment permits.
- Test a focused scenario, record actual behavior and identify mismatches.
- Change the smallest relevant parameters/code, then repeat the same scenario.
- Regression-test adjacent systems after a successful fix.
- If direct interactive play is unavailable, say so explicitly and provide the exact manual test checklist instead of pretending to have played.

## Godot project rules

- Read the repository's `AGENTS.md`, project conventions, input map, autoloads, scene ownership and save/data formats before changing architecture.
- Prefer the project's existing language and patterns; do not migrate GDScript/C# or replace established systems without a concrete reason.
- Avoid unrelated refactors while tuning gameplay.
- Keep designer-facing values centralized and named with units where useful (seconds, pixels/sec, degrees, etc.).
- Never fabricate playtest results, profiler measurements, screenshots or successful runtime checks.

## Completion report

Report: files changed, behavior changed, tunable parameters changed, tests/playtests actually performed, remaining risks, and the next recommended test.

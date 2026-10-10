---
name: gameplay-vfx
description: Own gameplay-readable VFX: hit sparks, slash trails, impacts, particles, afterimages, warning effects and shader feedback.
---

# Gameplay VFX

Use this skill when implementing, reviewing, tuning, or debugging own gameplay-readable vfx: hit sparks, slash trails, impacts, particles, afterimages, warning effects and shader feedback. in this Godot 2D/2.5D action/metroidvania project.

## Workflow

- VFX must communicate gameplay first and spectacle second.
- Match effect timing and direction to actual contact point, attack vector and damage type.
- Distinguish light/heavy/critical/parry/block/immune hits visually.
- Keep telegraphs readable against backgrounds and avoid obscuring player/enemy silhouettes.
- Pool frequently spawned effects where appropriate and avoid unnecessary allocations.
- Expose intensity/scale/duration parameters for tuning.
- Validate alongside combat-feel, camera-feel and playtest.

## Godot project rules

- Read the repository's `AGENTS.md`, project conventions, input map, autoloads, scene ownership and save/data formats before changing architecture.
- Prefer the project's existing language and patterns; do not migrate GDScript/C# or replace established systems without a concrete reason.
- Avoid unrelated refactors while tuning gameplay.
- Keep designer-facing values centralized and named with units where useful (seconds, pixels/sec, degrees, etc.).
- Never fabricate playtest results, profiler measurements, screenshots or successful runtime checks.

## Completion report

Report: files changed, behavior changed, tunable parameters changed, tests/playtests actually performed, remaining risks, and the next recommended test.

---
name: combat-feel
description: Own attack timing and impact feel: startup/active/recovery, hit stop, hit stun, knockback, input buffer, combo/cancel windows, armor, parry and i-frames.
---

# Combat Feel

Use this skill when implementing, reviewing, tuning, or debugging own attack timing and impact feel: startup/active/recovery, hit stop, hit stun, knockback, input buffer, combo/cancel windows, armor, parry and i-frames. in this Godot 2D/2.5D action/metroidvania project.

## Workflow

- Inspect existing combat architecture before editing.
- Keep tunable combat values data-driven (Resources/config), not scattered magic numbers.
- For every attack define startup, active, recovery, combo/cancel windows and input buffering.
- For every hit define hit stop, hit stun, knockback/launch, armor interaction, parry/block behavior and i-frames.
- Coordinate with animation, VFX, camera and audio hooks; do not duplicate ownership.
- Preserve responsiveness: never add visual weight by making controls arbitrarily sluggish.
- After changes, invoke the playtest workflow and compare before/after behavior.

## Godot project rules

- Read the repository's `AGENTS.md`, project conventions, input map, autoloads, scene ownership and save/data formats before changing architecture.
- Prefer the project's existing language and patterns; do not migrate GDScript/C# or replace established systems without a concrete reason.
- Avoid unrelated refactors while tuning gameplay.
- Keep designer-facing values centralized and named with units where useful (seconds, pixels/sec, degrees, etc.).
- Never fabricate playtest results, profiler measurements, screenshots or successful runtime checks.

## Completion report

Report: files changed, behavior changed, tunable parameters changed, tests/playtests actually performed, remaining risks, and the next recommended test.

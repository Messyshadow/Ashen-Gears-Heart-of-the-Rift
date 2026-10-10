---
name: combat-animation
description: Own combat animation state flow, animation events, transitions, anticipation, contact poses, recovery and synchronization with hitboxes.
---

# Combat Animation

Use this skill when implementing, reviewing, tuning, or debugging own combat animation state flow, animation events, transitions, anticipation, contact poses, recovery and synchronization with hitboxes. in this Godot 2D/2.5D action/metroidvania project.

## Workflow

- Inspect AnimationPlayer/AnimationTree/state machine and existing conventions first.
- Separate animation presentation from authoritative combat state.
- Synchronize hitbox activation/deactivation to explicit animation/combat events.
- Check anticipation, contact pose, follow-through, recovery, transition blending and interruption rules.
- Prevent animation transitions from swallowing buffered inputs or leaving stale hitboxes.
- Expose timing offsets as data where practical.
- Validate changes with combat-feel and playtest.

## Godot project rules

- Read the repository's `AGENTS.md`, project conventions, input map, autoloads, scene ownership and save/data formats before changing architecture.
- Prefer the project's existing language and patterns; do not migrate GDScript/C# or replace established systems without a concrete reason.
- Avoid unrelated refactors while tuning gameplay.
- Keep designer-facing values centralized and named with units where useful (seconds, pixels/sec, degrees, etc.).
- Never fabricate playtest results, profiler measurements, screenshots or successful runtime checks.

## Completion report

Report: files changed, behavior changed, tunable parameters changed, tests/playtests actually performed, remaining risks, and the next recommended test.

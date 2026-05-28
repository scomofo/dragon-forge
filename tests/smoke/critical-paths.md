# Smoke Test: Critical Paths

**Purpose**: Run these checks before QA hand-off.
**Run via**: `/smoke-check`
**Update**: Add entries as implementation stories land.

## Core Stability

1. Game launches without crash.
2. New session can be started.
3. Main input path responds without freezing.

## Core Mechanic

4. Campaign Map can enter a first combat node once implemented.
5. Battle TELEGRAPH accepts a semantic action once implemented.
6. Battle settlement returns to Campaign Map once implemented.

## Data Integrity

7. Save transaction completes without error once Save / Persistence is implemented.
8. Load restores the last committed state once Save / Persistence is implemented.

## Performance

9. No visible frame drops on target hardware during the implemented critical path.
10. No obvious memory growth during a five-minute smoke session once runtime exists.

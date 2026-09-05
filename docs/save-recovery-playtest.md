# Save recovery: browser acceptance

Status: pending. Automated tests cover the storage and UI contracts; these checks establish browser behavior and usability. Use a disposable browser profile and test progress, with a downloaded copy before destructive scenarios. Record browser/version, viewport, input method, steps, and observed result.

| Check | Expected result |
|---|---|
| Fresh start, earn progress, reload | Collection, scraps, route choices, and rewards resume correctly. Settings downloads readable current and previous saves. |
| Legacy save import | Preview shows owned dragons, wins, and scraps. Cancel changes nothing; confirm preserves progress while backfilling missing fields. Reload keeps the imported result. |
| Malformed main JSON; repeat with an invalid nested value such as `inventory: null` | Recovery appears before title/gameplay. Waiting through a heartbeat and reloading leaves the main bytes unchanged. The damaged download matches those bytes. |
| Damaged main with a valid backup | Restore requires confirmation. Success restores progress and keeps the damaged original; cancel leaves both stored values unchanged. Repeat with no main value and a valid backup. |
| Invalid or larger-than-1-MiB import | A readable error appears without replacing current progress. A valid file can still be chosen afterward. |
| Deny storage access before startup | Recovery explains the problem without starting a fresh session. Restoring access and Retry resumes readable progress. |
| Cause a write failure after gameplay starts | The persistent warning appears. Continue through multiple rewards/mutations: the current download includes them all. Restore storage access and Retry; reload only after success and verify progress. In battle, Retry must not restart or leave the fight. |
| Change the main save externally while this tab has pending progress | Retry detects the conflict without overwriting the other value. Download retains this session. Cancel loading the other save keeps recovery open; confirmed Load Saved Progress adopts that save. |
| Fail a restore/import write | Show an error, keep the main value, and retain a usable retry path. Do not show a success message. |
| Start New Game | Cancel preserves progress. Confirm deletes old backup/damaged copies and writes a fresh save. Reload and inspect recovery options: old progress cannot return through Restore Backup. |
| Keyboard, touch, and 390px viewport | Every recovery action and file input is reachable, focus is visible, confirmation text is readable, and no horizontal overflow hides controls. Alerts and status feedback are announced appropriately. |

Failure injection may use a disposable test origin with browser storage permissions or a controlled storage adapter. Do not fill or clear storage on the player's normal profile. Include one actual browser storage denial/quota result alongside injected cases before closing the acceptance gate.

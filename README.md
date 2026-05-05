# ironbark_breathalyzer

**Ironbark Scripts** — server-authoritative breathalyser for QBX / QBCore.

## Dependencies

| Resource | Required |
|----------|----------|
| `ox_lib` | Always |
| `ox_target` | When `Config.DevMode = true` |
| `qbx_core` **or** `qb-core` | One must be running |
| A drinking resource that writes `metadata.alcohol` | For live BAC readings |

The bridge auto-detects your framework at startup (`qbx_core` checked first).

## Installation

1. Drop `ironbark_breathalyzer` into your resources folder
2. Add to `server.cfg` after `ox_lib` and your core:
   ```
   ensure ironbark_breathalyzer
   ```
3. Configure `shared/config.lua`

## Usage

| Input | Action |
|-------|--------|
| `/alcolizer` or `F7` | Breath test on nearest player |
| Interact on any NPC *(DevMode only)* | Breath test with random BAC |
| `/setbac <id> <value>` *(DevMode only)* | Manually set a player's BAC |

Only players with a job listed in `Config.AllowedJobs` can use the device. Enforced server-side.

## Dev Mode

`Config.DevMode = true` enables development features. This includes a `qb-target` option on all nearby NPCs labelled **Breath Test [DEV]**, which generates a random BAC (0.00–0.25) and runs the full UI flow. No money changes hands and no job consequences apply. The result notification is prefixed with `[DEV] NPC Test`.

Additionally, when `Config.DevMode = true`, the `/setbac <id> <value>` command becomes available for in-game use. This allows developers to manually set a player's Blood Alcohol Content (BAC) for testing purposes without requiring in-game alcohol consumption. This command is restricted to server console use when `Config.DevMode = false`.

**Set `Config.DevMode = false` before production deployment.**

## Config (`shared/config.lua`)

| Key | Default | Notes |
|-----|---------|-------|
| `AllowedJobs` | `{'police','sheriff'}` | Server-enforced |
| `LegalLimit` | `0.05` | Float |
| `TestCooldown` | `30` | Seconds per suspect |
| `MaxTestDistance` | `3.5` | Game units |
| `AnimationDuration` | `5000` | Milliseconds |
| `EnableLogging` | `true` | Console output |
| `LogToFile` | `false` | Flat file append |
| `DevMode` | `true` | Enables dev features, including `/setbac` command and NPC testing. Set to `false` for production. |
| `Framework` | `'auto'` | `'auto'` \| `'qbx'` \| `'qb'` |

## Export

```lua
-- From any server-side script:
local result = exports['ironbark_breathalyzer']:getLastResult(serverId)
-- Returns nil if not tested this session, or:
-- {
--   bac, legalLimit, overLimit,
--   officerId, officerName,
--   suspectId, suspectName,
--   timestamp  (os.time())
-- }
```

## How BAC works

BAC is read server-side from `PlayerData.metadata.alcohol`. The client never submits a value. Your drinking resource sets this via:

```lua
local player = exports.qbx_core:GetPlayer(serverId)  -- or qb-core equivalent
player.Functions.SetMetaData('alcohol', 0.09)
```

Config = {}

-- Jobs allowed to conduct breath tests. Enforced server-side.
Config.AllowedJobs = { 'police', 'sheriff' }

-- Legal BAC limit as a float.
-- Australia: 0.05  |  USA: 0.08  |  Zero-tolerance: 0.0
Config.LegalLimit = 0.05

-- Seconds before the same suspect can be tested again.
Config.TestCooldown = 30

-- Maximum distance (game units) between officer and suspect.
Config.MaxTestDistance = 3.5

-- Duration of the breath test animation and progress bar (ms).
Config.AnimationDuration = 5000

-- Print every test result to the server console.
Config.EnableLogging = true

-- Also append results to a flat file (server working directory).
Config.LogToFile     = false
Config.LogFilePath   = 'logs/alcolizer.log'

-- Development Mode: If true, the 'setbac' command is enabled for in-game use.
Config.DevMode = true

-- 'auto' detects qbx_core then qb-core at startup.
-- Set explicitly to 'qbx' or 'qb' to skip detection.
Config.Framework = 'auto'

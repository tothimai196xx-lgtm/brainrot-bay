-- Brainrot Bay — the tsunami. The first wave rolls in 150 seconds after
-- the server starts, then every 240 seconds. A 20-second warning (red
-- banner + siren on the client) gives players time to get inside a base;
-- the wave then sweeps the map for 12 seconds. Anyone caught outside a
-- base loses 10% of their cash and drops whatever they are carrying.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local WaveService = {}

local waveWarningEvent: RemoteEvent? = nil
local economy = nil -- set by init: EconomyService
local baseService = nil -- set by init: BaseService
local stealService = nil -- set by init: StealService
local waveActive = false

function WaveService.setDependencies(economyService, baseServiceModule, stealServiceModule)
	economy = economyService
	baseService = baseServiceModule
	stealService = stealServiceModule
end

function WaveService.setWarningEvent(remote: RemoteEvent)
	waveWarningEvent = remote
end

function WaveService.isWaveActive(): boolean
	return waveActive
end

-- True when the player is standing inside any base (safe from the wave).
function WaveService.isPlayerSafe(player: Player): boolean
	if not baseService then
		return false
	end
	for baseIndex = 1, #Config.BASES do
		if baseService.isInsideBase(player, baseIndex) then
			return true
		end
	end
	return false
end

-- The 20-second warning: tell every client to show the red banner and
-- play the siren, then run the sweep.
function WaveService.warnWave(_arg: any?)
	if waveWarningEvent then
		waveWarningEvent:FireAllClients("warning", Config.WAVE.warningSeconds)
	end
	task.wait(Config.WAVE.warningSeconds)
	WaveService.sweepWave()
end

-- The wave itself: 12 seconds of water sweeping the island. Players
-- outside a base pay the penalty; players inside stay dry.
function WaveService.sweepWave()
	waveActive = true
	if waveWarningEvent then
		waveWarningEvent:FireAllClients("wave", Config.WAVE.sweepSeconds)
	end

	-- A wall of water that crosses the island from west to east.
	local wall = Instance.new("Part")
	wall.Name = "TsunamiWall"
	wall.Size = Vector3.new(4, 26, 120)
	wall.Position = Vector3.new(-70, 12, 0)
	wall.Color = Color3.fromRGB(30, 120, 200)
	wall.Material = Enum.Material.Water
	wall.Transparency = 0.3
	wall.Anchored = true
	wall.CanCollide = false
	wall.Parent = workspace

	task.spawn(function()
		local steps = 60
		for i = 1, steps do
			wall.Position = Vector3.new(-70 + (140 * i / steps), 12, 0)
			task.wait(Config.WAVE.sweepSeconds / steps)
		end
		wall:Destroy()
	end)

	-- Apply the penalty once, halfway through the sweep.
	task.wait(Config.WAVE.sweepSeconds / 2)
	WaveService.applyWavePenalty()

	task.wait(Config.WAVE.sweepSeconds / 2)
	waveActive = false
end

-- Charges every player caught outside a base: 10% of cash gone, and any
-- carried brainrot dropped on the spot.
function WaveService.applyWavePenalty()
	if not economy or not stealService then
		return
	end
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		if not WaveService.isPlayerSafe(player) then
			economy.applyCashLoss(player, Config.WAVE.cashLossFraction)
			stealService.dropCarried(player)
		end
	end
end

-- The wave clock: first wave 150s in, then every 240s, forever.
function WaveService.startWaveTimer()
	task.spawn(function()
		task.wait(Config.WAVE.firstWaveAfterSeconds)
		while true do
			WaveService.warnWave(1)
			task.wait(Config.WAVE.waveEverySeconds)
		end
	end)
end

return WaveService

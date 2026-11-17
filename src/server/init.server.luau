-- Brainrot Bay — server entry point.
-- Wires every service together in dependency order, builds the world,
-- hands each player a base when they join, and starts the loops:
-- conveyor spawns, income ticks, the wave clock and autosave.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local WorldBuilder = require(script.Parent.WorldBuilder)
local EconomyService = require(script.Parent.EconomyService)
local BaseService = require(script.Parent.BaseService)
local BrainrotService = require(script.Parent.BrainrotService)
local StealService = require(script.Parent.StealService)
local WaveService = require(script.Parent.WaveService)

-- Build the island before anything else needs it.
local world = WorldBuilder.buildWorld()

-- Wire the services together (kept out of the modules to avoid cycles).
EconomyService.setBaseService(BaseService)
BaseService.setWorld(world)
BaseService.setEconomy(EconomyService)
BrainrotService.setDependencies(EconomyService, BaseService)
StealService.setBaseService(BaseService)
WaveService.setDependencies(EconomyService, BaseService, StealService)

-- One RemoteEvents folder shared by server and client.
local remoteEvents = Instance.new("Folder")
remoteEvents.Name = "RemoteEvents"
remoteEvents.Parent = ReplicatedStorage

local buyBrainrot = Instance.new("RemoteEvent")
buyBrainrot.Name = "BuyBrainrot"
buyBrainrot.Parent = remoteEvents

local stealBrainrot = Instance.new("RemoteEvent")
stealBrainrot.Name = "StealBrainrot"
stealBrainrot.Parent = remoteEvents

local waveWarning = Instance.new("RemoteEvent")
waveWarning.Name = "WaveWarning"
waveWarning.Parent = remoteEvents

local lockBaseEvent = Instance.new("RemoteEvent")
lockBaseEvent.Name = "LockBase"
lockBaseEvent.Parent = remoteEvents

local rebirthEvent = Instance.new("RemoteEvent")
rebirthEvent.Name = "Rebirth"
rebirthEvent.Parent = remoteEvents

local buyUpgradeEvent = Instance.new("RemoteEvent")
buyUpgradeEvent.Name = "BuyUpgrade"
buyUpgradeEvent.Parent = remoteEvents

WaveService.setWarningEvent(waveWarning)

-- Remote handlers: every request is validated server-side (cash, base
-- ownership, lock state) so a forged client call cannot cheat.
buyBrainrot.OnServerEvent:Connect(function(player, brainrotId)
	BrainrotService.onBrainrotBought(player, brainrotId)
end)

stealBrainrot.OnServerEvent:Connect(function(player, baseIndex, plotIndex)
	if StealService.trySteal(player, baseIndex, plotIndex) then
		-- Deliver the stolen brainrot once the thief steps inside their own base.
		task.spawn(function()
			while StealService.isCarrying(player) do
				local ownBase = BaseService.getBase(player) or 0
				if ownBase > 0 and BaseService.isInsideBase(player, ownBase) then
					StealService.carryBrainrot(player)
					break
				end
				task.wait(0.5)
			end
		end)
	end
end)

lockBaseEvent.OnServerEvent:Connect(function(player)
	BaseService.lockBase(player)
end)

rebirthEvent.OnServerEvent:Connect(function(player)
	EconomyService.tryRebirth(player)
end)

buyUpgradeEvent.OnServerEvent:Connect(function(player, upgradeId)
	EconomyService.buyUpgrade(player, upgradeId)
end)

-- Give every joining player their base and drop them on the spawn pad.
local function onPlayerAdded(player: Player)
	BaseService.assignBase(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.WalkSpeed = Config.WORLD.normalWalkSpeed
		local root = character:WaitForChild("HumanoidRootPart")
		root.CFrame = CFrame.new(Config.SPAWN_POSITION.X, 6, Config.SPAWN_POSITION.Z)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end

-- Start the loops.
BrainrotService.startConveyorLoop()
EconomyService.startIncomeLoop()
WaveService.startWaveTimer()
EconomyService.startAutosave()

print("[Brainrot Bay] server started — island built, conveyor running, first wave in "
	.. tostring(Config.WAVE.firstWaveAfterSeconds) .. "s")

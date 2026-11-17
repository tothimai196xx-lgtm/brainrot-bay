-- Brainrot Bay — player bases and plots. Each joining player is handed the
-- first free base; bought brainrots stand on its 8 plots and earn cash.
-- A base can be locked for 30 seconds (60s cooldown) so thieves stay out.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local Utils = require(ReplicatedStorage.Shared.Utils)
local CharacterFactory = require(script.Parent.CharacterFactory)

local BaseService = {}

local playerBases: { [Player]: number } = {}
local plots: { [number]: { Part } } = {} -- base index -> plot pads
local plotOccupants: { [number]: { [number]: { brainrotId: string, mutation: string?, rate: number, model: Model } } } = {}
local lockedUntil: { [number]: number } = {}
local lockCooldownUntil: { [number]: number } = {}
local world = nil -- set by init: the table WorldBuilder.buildWorld() returned

function BaseService.setWorld(builtWorld)
	world = builtWorld
	plots = builtWorld.plots or {}
end

function BaseService.assignBase(player: Player): number?
	for i = 1, #Config.BASES do
		local taken = false
		for _, owner in pairs(playerBases) do
			if owner == i then
				taken = true
				break
			end
		end
		if not taken then
			playerBases[player] = i
			plotOccupants[i] = {}
			return i
		end
	end
	return nil
end

function BaseService.getBase(player: Player): number?
	return playerBases[player]
end

-- First empty plot index in a base, or nil when the base is full.
local function firstFreePlot(baseIndex: number): number?
	for i = 1, Config.PLOTS_PER_BASE do
		if not (plotOccupants[baseIndex] and plotOccupants[baseIndex][i]) then
			return i
		end
	end
	return nil
end

-- Places a bought (or stolen-and-delivered) brainrot on the player's first
-- free plot and spawns its standing model there.
function BaseService.placeBrainrot(player: Player, brainrotId: string, mutation: string?): boolean
	local baseIndex = playerBases[player]
	if not baseIndex then
		return false
	end
	local plotIndex = firstFreePlot(baseIndex)
	if not plotIndex then
		return false
	end

	local definition = nil
	for _, b in ipairs(Config.BRAINROTS) do
		if b.id == brainrotId then
			definition = b
			break
		end
	end
	if not definition then
		return false
	end

	local rate = definition.rate
	if mutation then
		for _, m in ipairs(Config.MUTATIONS) do
			if m.id == mutation then
				rate *= m.multiplier
				break
			end
		end
	end

	local model = CharacterFactory.buildBrainrotModel(definition, mutation)
	local pads = plots[baseIndex]
	local pad = pads and pads[plotIndex]
	if pad then
		model.Parent = workspace
		local primary = model.PrimaryPart
		if primary then
			primary.CFrame = CFrame.new(pad.Position.X, pad.Position.Y + 1.4, pad.Position.Z)
				* CFrame.Angles(0, math.rad(180), 0)
			primary.Anchored = true
		end
	end

	plotOccupants[baseIndex][plotIndex] = {
		brainrotId = brainrotId,
		mutation = mutation,
		rate = rate,
		model = model,
	}
	return true
end

-- Removes the brainrot from a plot (stolen, or sold) and destroys its model.
function BaseService.removeFromPlot(baseIndex: number, plotIndex: number)
	local occupant = plotOccupants[baseIndex] and plotOccupants[baseIndex][plotIndex]
	if occupant then
		if occupant.model and occupant.model.Parent then
			occupant.model:Destroy()
		end
		plotOccupants[baseIndex][plotIndex] = nil
	end
end

-- Cash earned per second by all brainrots standing on a player's plots.
function BaseService.getIncomePerSecond(player: Player): number
	local baseIndex = playerBases[player]
	if not baseIndex then
		return 0
	end
	local total = 0
	for _, occupant in pairs(plotOccupants[baseIndex] or {}) do
		total += occupant.rate
	end
	return total
end

function BaseService.collectFromPlot(baseIndex: number, plotIndex: number)
	return plotOccupants[baseIndex] and plotOccupants[baseIndex][plotIndex]
end

-- Locks the player's base for Config.LOCK.lockSeconds (+ Shield bonus).
-- Returns false while the cooldown is still running.
function BaseService.lockBase(player: Player): boolean
	local baseIndex = playerBases[player]
	if not baseIndex then
		return false
	end
	local now = os.clock()
	if lockCooldownUntil[baseIndex] and now < lockCooldownUntil[baseIndex] then
		return false
	end
	local shieldLevel = 0
	local economy = BaseService._economy
	if economy then
		shieldLevel = economy.getUpgradeLevel(player, "Shield")
	end
	lockedUntil[baseIndex] = now + Config.LOCK.lockSeconds + shieldLevel * Config.LOCK.shieldBonusSeconds
	lockCooldownUntil[baseIndex] = now + Config.LOCK.cooldownSeconds
	return true
end

function BaseService.isBaseLocked(baseIndex: number): boolean
	return lockedUntil[baseIndex] ~= nil and os.clock() < lockedUntil[baseIndex]
end

function BaseService.lockSecondsLeft(baseIndex: number): number
	if not lockedUntil[baseIndex] then
		return 0
	end
	return math.max(0, lockedUntil[baseIndex] - os.clock())
end

-- True when the player's character is standing inside their own base.
function BaseService.isInsideBase(player: Player, baseIndex: number): boolean
	local character = player.Character
	if not character then
		return false
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local spec = Config.BASES[baseIndex]
	if not spec then
		return false
	end
	return Utils.distanceBetween(root.Position, spec.position) < 11
end

-- Frees a base when its player leaves so a newcomer can take it.
function BaseService.releaseBase(player: Player)
	local baseIndex = playerBases[player]
	if baseIndex then
		for plotIndex = 1, Config.PLOTS_PER_BASE do
			BaseService.removeFromPlot(baseIndex, plotIndex)
		end
		playerBases[player] = nil
	end
end

BaseService._economy = nil
function BaseService.setEconomy(economyService)
	BaseService._economy = economyService
end

Players.PlayerRemoving:Connect(function(player)
	BaseService.releaseBase(player)
end)

return BaseService

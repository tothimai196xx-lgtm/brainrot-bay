-- Brainrot Bay — stealing. A thief walks into another player's OPEN base,
-- touches one of their brainrots and carries it home. While carrying, the
-- thief walks slower; if a wave catches them outside a base (or they are
-- tagged), the stolen brainrot drops where they stand.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local StealService = {}

local carried: { [Player]: { brainrotId: string, mutation: string?, fromBase: number, fromPlot: number } } = {}
local baseService = nil -- set by init: BaseService

function StealService.setBaseService(baseServiceModule)
	baseService = baseServiceModule
end

-- Grabs a brainrot off a plot in another player's base. The base must be
-- unlocked and the plot must hold a brainrot; the thief must not already
-- be carrying more than their carry capacity allows.
function StealService.trySteal(player: Player, baseIndex: number, plotIndex: number): boolean
	if not baseService then
		return false
	end
	local ownBase = baseService.getBase(player)
	if ownBase == baseIndex then
		return false -- stealing from yourself is not a thing
	end
	if baseService.isBaseLocked(baseIndex) then
		return false
	end
	if carried[player] then
		return false -- one at a time unless the Carry upgrade was bought
	end

	local occupant = baseService.collectFromPlot(baseIndex, plotIndex)
	if not occupant then
		return false
	end

	baseService.removeFromPlot(baseIndex, plotIndex)
	carried[player] = {
		brainrotId = occupant.brainrotId,
		mutation = occupant.mutation,
		fromBase = baseIndex,
		fromPlot = plotIndex,
	}

	-- Slow the thief down while they lug the stolen brainrot home.
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.WORLD.carryWalkSpeed
		end
	end
	return true
end

-- The thief reached their own base: the stolen brainrot is theirs now and
-- goes onto their first free plot.
function StealService.carryBrainrot(player: Player): boolean
	local load = carried[player]
	if not load or not baseService then
		return false
	end
	if not baseService.placeBrainrot(player, load.brainrotId, load.mutation) then
		return false
	end
	carried[player] = nil

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.WORLD.normalWalkSpeed
		end
	end
	return true
end

-- Drops whatever the player is carrying (wave hit, or left the game).
-- The brainrot is lost — it does not teleport back to its old base.
function StealService.dropCarried(player: Player)
	if not carried[player] then
		return
	end
	carried[player] = nil
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = Config.WORLD.normalWalkSpeed
		end
	end
end

function StealService.getCarried(player: Player)
	return carried[player]
end

function StealService.isCarrying(player: Player): boolean
	return carried[player] ~= nil
end

return StealService

-- Brainrot Bay — spawns brainrots on the conveyor, rolls mutations and
-- handles purchases. Brainrots walk the belt from west (-23) to east (+23);
-- a player buys one with the E key (client) or the BuyBrainrot remote.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Utils = require(ReplicatedStorage.Shared.Utils)
local CharacterFactory = require(script.Parent.CharacterFactory)

local BrainrotService = {}

local beltModels: { Model } = {}
local beltFolder: Folder? = nil
local economy = nil -- set by init: EconomyService (avoids a require cycle)
local baseService = nil -- set by init: BaseService

function BrainrotService.setDependencies(economyService, baseServiceModule)
	economy = economyService
	baseService = baseServiceModule
end

-- Rolls a mutation id, or nil for the plain 87% of buys.
function BrainrotService.rollMutation(): string?
	local roll = math.random()
	local running = 0
	for _, m in ipairs(Config.MUTATIONS) do
		running += m.chance
		if roll <= running then
			return m.id
		end
	end
	return nil
end

-- Picks a random brainrot definition, weighted toward commons.
local function pickBrainrotDefinition()
	local rarityName = Utils.weightedPick(Config.CONVEYOR.spawnWeights)
	local pool = {}
	for _, b in ipairs(Config.BRAINROTS) do
		if b.rarity == rarityName then
			table.insert(pool, b)
		end
	end
	if #pool == 0 then
		return Config.BRAINROTS[1]
	end
	return pool[math.random(1, #pool)]
end

-- Spawns one brainrot model at the west end of the belt and registers it.
function BrainrotService.spawnBrainrot(definitionOverride): Model?
	if #beltModels >= Config.CONVEYOR.maxOnBelt then
		return nil
	end
	if not beltFolder then
		beltFolder = Instance.new("Folder")
		beltFolder.Name = "ConveyorBrainrots"
		beltFolder.Parent = workspace
	end

	local definition = definitionOverride or pickBrainrotDefinition()
	local model = CharacterFactory.buildBrainrotModel(definition, nil)
	model.Parent = beltFolder

	-- Feet on the belt, facing east (+X) as it walks.
	local primary = model.PrimaryPart
	if primary then
		primary.CFrame = CFrame.new(-Config.CONVEYOR.beltLength / 2 + 2, 5.2, 0)
			* CFrame.Angles(0, math.rad(-90), 0)
	end

	-- A ProximityPrompt on the body lets the player buy with E up close.
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Buy " .. definition.name
	prompt.ObjectText = Utils.formatMoney(definition.cost)
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 8
	prompt.Parent = primary or model

	table.insert(beltModels, model)

	-- The brainrot walks off the east end after its lifetime and despawns.
	task.delay(Config.CONVEYOR.despawnAfterSeconds, function()
		BrainrotService.despawnBrainrot(model)
	end)

	return model
end

function BrainrotService.despawnBrainrot(model: Model)
	local idx = table.find(beltModels, model)
	if idx then
		table.remove(beltModels, idx)
	end
	if model.Parent then
		model:Destroy()
	end
end

-- Moves every brainrot on the belt a step east; called from the heartbeat.
function BrainrotService.stepConveyor(deltaTime: number)
	local speed = 2.2 -- studs per second along the belt
	for i = #beltModels, 1, -1 do
		local model = beltModels[i]
		local primary = model.PrimaryPart
		if not primary or not model.Parent then
			table.remove(beltModels, i)
		else
			local pos = primary.Position
			local nextX = pos.X + speed * deltaTime
			if nextX > Config.CONVEYOR.beltLength / 2 then
				BrainrotService.despawnBrainrot(model)
			else
				primary.CFrame = CFrame.new(nextX, pos.Y, pos.Z) * CFrame.Angles(0, math.rad(-90), 0)
			end
		end
	end
end

-- Buys the brainrot the player is looking at: charges cash, rolls the
-- mutation, moves the model to the player's first free plot.
function BrainrotService.onBrainrotBought(player: Player, brainrotId: string): boolean
	if not economy or not baseService then
		return false
	end
	local model: Model? = nil
	for _, candidate in ipairs(beltModels) do
		if candidate:GetAttribute("BrainrotId") == brainrotId then
			model = candidate
			break
		end
	end
	if not model then
		return false
	end

	local cost = model:GetAttribute("Cost") or 0
	if not economy.spendCash(player, cost) then
		return false
	end

	-- Roll the mutation now that the sale is paid for.
	local mutation = BrainrotService.rollMutation()
	if mutation then
		CharacterFactory.applyMutation(model, mutation)
	end

	BrainrotService.despawnBrainrot(model)
	baseService.placeBrainrot(player, brainrotId, mutation)
	return true
end

-- Spawns a fresh brainrot on the belt every few seconds, forever.
function BrainrotService.startConveyorLoop()
	task.spawn(function()
		while true do
			BrainrotService.spawnBrainrot()
			task.wait(Config.CONVEYOR.spawnEverySeconds)
		end
	end)
	RunService.Heartbeat:Connect(function(deltaTime)
		BrainrotService.stepConveyor(deltaTime)
	end)
end

return BrainrotService

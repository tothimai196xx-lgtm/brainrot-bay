-- Brainrot Bay — money, rebirth, upgrades and saving.
-- Every second the server ticks: each player's plots pay out their combined
-- rate, scaled by the rebirth bonus. Cash and rebirth counts live in
-- leaderstats; progress is saved to a DataStore with pcall so the game
-- never crashes when Studio runs offline.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local EconomyService = {}

local DATASTORE_NAME = "BrainrotBaySaveV1"
local dataStore: DataStore? = nil
do
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(DATASTORE_NAME)
	end)
	if ok then
		dataStore = store
	end
end

local playerData: { [Player]: { cash: number, rebirths: number, lifetimeEarned: number, upgrades: { [string]: number } } } = {}
local baseService = nil -- set by init: BaseService

function EconomyService.setBaseService(baseServiceModule)
	baseService = baseServiceModule
end

local function ensureData(player: Player)
	if not playerData[player] then
		playerData[player] = {
			cash = Config.ECONOMY.startCash,
			rebirths = 0,
			lifetimeEarned = 0,
			upgrades = {},
		}
	end
	return playerData[player]
end

function EconomyService.getCash(player: Player): number
	return ensureData(player).cash
end

function EconomyService.addCash(player: Player, amount: number)
	local data = ensureData(player)
	data.cash += amount
	if amount > 0 then
		data.lifetimeEarned += amount
	end
	EconomyService.refreshLeaderstats(player)
end

-- Takes cash when the player can afford it; returns false otherwise.
function EconomyService.spendCash(player: Player, amount: number): boolean
	local data = ensureData(player)
	if data.cash < amount then
		return false
	end
	data.cash -= amount
	EconomyService.refreshLeaderstats(player)
	return true
end

-- The wave's cut: removes a fraction of the player's carried cash.
function EconomyService.applyCashLoss(player: Player, fraction: number)
	local data = ensureData(player)
	local loss = math.floor(data.cash * fraction)
	data.cash -= loss
	EconomyService.refreshLeaderstats(player)
end

-- Income per second from plots, scaled by the permanent rebirth bonus.
function EconomyService.getIncomePerSecond(player: Player): number
	if not baseService then
		return 0
	end
	local base = baseService.getIncomePerSecond(player)
	local data = ensureData(player)
	return base * (1 + data.rebirths * Config.ECONOMY.rebirthIncomeBonus)
end

-- The 1-second income tick: pay every player their plots' earnings.
function EconomyService.tickIncome()
	while true do
		task.wait(Config.ECONOMY.incomeTickSeconds)
		for _, player in ipairs(Players:GetPlayers()) do
			local income = EconomyService.getIncomePerSecond(player)
			if income > 0 then
				EconomyService.addCash(player, income)
			end
		end
	end
end

function EconomyService.startIncomeLoop()
	task.spawn(EconomyService.tickIncome)
end

-- Rebirth: once lifetime earnings pass the threshold (1M, then x10 each
-- time), reset cash and brainrots for a permanent +25% income per rebirth.
function EconomyService.tryRebirth(player: Player): boolean
	local data = ensureData(player)
	local threshold = Config.ECONOMY.rebirthBaseThreshold
		* (Config.ECONOMY.rebirthThresholdGrowth ^ data.rebirths)
	if data.lifetimeEarned < threshold then
		return false
	end
	data.rebirths += 1
	data.cash = Config.ECONOMY.startCash
	data.lifetimeEarned = 0
	-- Clear the player's plots so the reset is real.
	if baseService then
		local baseIndex = baseService.getBase(player)
		if baseIndex then
			for plotIndex = 1, Config.PLOTS_PER_BASE do
				baseService.removeFromPlot(baseIndex, plotIndex)
			end
		end
	end
	EconomyService.refreshLeaderstats(player)
	return true
end

function EconomyService.getRebirthThreshold(player: Player): number
	local data = ensureData(player)
	return Config.ECONOMY.rebirthBaseThreshold
		* (Config.ECONOMY.rebirthThresholdGrowth ^ data.rebirths)
end

-- Buys one level of an upgrade (WalkSpeed / Carry / Shield) if the player
-- can afford it and has not hit the level cap.
function EconomyService.buyUpgrade(player: Player, upgradeId: string): boolean
	local spec = Config.UPGRADES[upgradeId]
	if not spec then
		return false
	end
	local data = ensureData(player)
	local level = data.upgrades[upgradeId] or 0
	if level >= spec.levels then
		return false
	end
	local cost = spec.costs[level + 1]
	if not EconomyService.spendCash(player, cost) then
		return false
	end
	data.upgrades[upgradeId] = level + 1

	-- WalkSpeed applies immediately to the live character.
	if upgradeId == "WalkSpeed" then
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = Config.WORLD.normalWalkSpeed + spec.bonusPerLevel * (level + 1)
			end
		end
	end
	return true
end

function EconomyService.getUpgradeLevel(player: Player, upgradeId: string): number
	local data = ensureData(player)
	return data.upgrades[upgradeId] or 0
end

function EconomyService.refreshLeaderstats(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	local cash = leaderstats:FindFirstChild("Cash")
	if cash and cash:IsA("IntValue") then
		cash.Value = math.floor(ensureData(player).cash)
	end
	local rebirths = leaderstats:FindFirstChild("Rebirths")
	if rebirths and rebirths:IsA("IntValue") then
		rebirths.Value = ensureData(player).rebirths
	end
end

local function setupLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Value = ensureData(player).cash
	cash.Parent = leaderstats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Value = ensureData(player).rebirths
	rebirths.Parent = leaderstats
	leaderstats.Parent = player
end

-- Loads saved progress (cash, rebirths, upgrades) from the DataStore.
-- A failed load simply starts the player fresh — never an error.
function EconomyService.loadData(player: Player)
	if not dataStore then
		return
	end
	local ok, saved = pcall(function()
		return dataStore:GetAsync("player_" .. player.UserId)
	end)
	if not ok or type(saved) ~= "table" then
		return
	end
	local data = ensureData(player)
	data.cash = saved.cash or data.cash
	data.rebirths = saved.rebirths or 0
	data.upgrades = saved.upgrades or {}
end

-- Saves the player's progress. Called on leave and every 60 seconds.
function EconomyService.saveData(player: Player)
	if not dataStore then
		return
	end
	local data = ensureData(player)
	pcall(function()
		dataStore:SetAsync("player_" .. player.UserId, {
			cash = math.floor(data.cash),
			rebirths = data.rebirths,
			upgrades = data.upgrades,
		})
	end)
end

function EconomyService.startAutosave()
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in ipairs(Players:GetPlayers()) do
				EconomyService.saveData(player)
			end
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	EconomyService.loadData(player)
	setupLeaderstats(player)
end)

Players.PlayerRemoving:Connect(function(player)
	EconomyService.saveData(player)
	playerData[player] = nil
end)

return EconomyService

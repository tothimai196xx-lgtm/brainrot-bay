-- Brainrot Bay — shared configuration.
-- Every number that tunes the game lives here so the services stay small
-- and the economy can be rebalanced from a single file.

local Config = {}

-- Rarity ladder, in unlock order. Each entry carries its display colour
-- (a Color3) and a short label used on the brainrot name tags.
Config.RARITIES = {
	Common = { order = 1, color = Color3.fromRGB(170, 170, 170), label = "Common" },
	Rare = { order = 2, color = Color3.fromRGB(80, 170, 255), label = "Rare" },
	Epic = { order = 3, color = Color3.fromRGB(170, 90, 255), label = "Epic" },
	Legendary = { order = 4, color = Color3.fromRGB(255, 180, 40), label = "Legendary" },
	Mythic = { order = 5, color = Color3.fromRGB(255, 70, 90), label = "Mythic" },
	["Brainrot God"] = { order = 6, color = Color3.fromRGB(0, 230, 190), label = "Brainrot God" },
}

-- The twelve original characters. `rate` is cash earned per second once the
-- brainrot sits on a plot; `cost` is the buy price on the conveyor.
-- `body` / `head` are the base colours, `accessory` picks the extra part
-- CharacterFactory bolts on ("crown", "cap", "antenna", "none").
Config.BRAINROTS = {
	{ id = "noodle-cat", name = "Noodle Cat", rarity = "Common", rate = 5, cost = 100,
		body = Color3.fromRGB(255, 205, 130), head = Color3.fromRGB(255, 230, 180), accessory = "none" },
	{ id = "sir-barksalot", name = "Sir Barksalot", rarity = "Common", rate = 8, cost = 250,
		body = Color3.fromRGB(150, 110, 70), head = Color3.fromRGB(190, 150, 100), accessory = "cap" },
	{ id = "captain-croissant", name = "Captain Croissant", rarity = "Rare", rate = 20, cost = 800,
		body = Color3.fromRGB(230, 170, 60), head = Color3.fromRGB(245, 205, 110), accessory = "cap" },
	{ id = "dj-pickle", name = "DJ Pickle", rarity = "Rare", rate = 35, cost = 1500,
		body = Color3.fromRGB(90, 180, 80), head = Color3.fromRGB(140, 210, 110), accessory = "antenna" },
	{ id = "turbo-toaster", name = "Turbo Toaster", rarity = "Epic", rate = 70, cost = 4000,
		body = Color3.fromRGB(200, 200, 210), head = Color3.fromRGB(235, 235, 245), accessory = "antenna" },
	{ id = "professor-pigeon", name = "Professor Pigeon", rarity = "Epic", rate = 120, cost = 8000,
		body = Color3.fromRGB(130, 140, 160), head = Color3.fromRGB(180, 190, 205), accessory = "crown" },
	{ id = "baron-banana", name = "Baron Banana", rarity = "Legendary", rate = 250, cost = 20000,
		body = Color3.fromRGB(255, 225, 60), head = Color3.fromRGB(255, 240, 130), accessory = "crown" },
	{ id = "queen-quokka", name = "Queen Quokka", rarity = "Legendary", rate = 450, cost = 45000,
		body = Color3.fromRGB(190, 140, 90), head = Color3.fromRGB(220, 180, 130), accessory = "crown" },
	{ id = "lord-lasagna", name = "Lord Lasagna", rarity = "Mythic", rate = 900, cost = 120000,
		body = Color3.fromRGB(220, 120, 50), head = Color3.fromRGB(245, 180, 90), accessory = "crown" },
	{ id = "disco-duckling", name = "Disco Duckling", rarity = "Mythic", rate = 1800, cost = 300000,
		body = Color3.fromRGB(255, 220, 40), head = Color3.fromRGB(255, 245, 160), accessory = "antenna" },
	{ id = "general-gnocchi", name = "General Gnocchi", rarity = "Brainrot God", rate = 5000, cost = 1000000,
		body = Color3.fromRGB(240, 220, 180), head = Color3.fromRGB(255, 245, 220), accessory = "crown" },
	{ id = "cosmic-couch", name = "Cosmic Couch", rarity = "Brainrot God", rate = 12000, cost = 3000000,
		body = Color3.fromRGB(90, 60, 160), head = Color3.fromRGB(150, 110, 230), accessory = "antenna" },
}

-- Mutations roll when a brainrot is bought. `chance` values add up to 0.13;
-- the other 87% of buys stay unmutated. `multiplier` scales the income rate.
Config.MUTATIONS = {
	{ id = "Golden", chance = 0.05, multiplier = 2, tint = Color3.fromRGB(255, 215, 0) },
	{ id = "Diamond", chance = 0.025, multiplier = 4, tint = Color3.fromRGB(185, 242, 255) },
	{ id = "Rainbow", chance = 0.01, multiplier = 8, tint = Color3.fromRGB(255, 120, 200) },
	{ id = "Frozen", chance = 0.03, multiplier = 3, tint = Color3.fromRGB(170, 220, 255) },
	{ id = "Lava", chance = 0.015, multiplier = 6, tint = Color3.fromRGB(255, 90, 30) },
}

Config.ECONOMY = {
	startCash = 250,
	incomeTickSeconds = 1,
	-- Rebirth unlocks once lifetime earnings pass this, then x10 per rebirth.
	rebirthBaseThreshold = 1000000,
	rebirthThresholdGrowth = 10,
	rebirthIncomeBonus = 0.25, -- +25% income per rebirth, forever
}

Config.CONVEYOR = {
	spawnEverySeconds = 6,
	maxOnBelt = 12,
	despawnAfterSeconds = 90,
	beltLength = 46,
	beltWidth = 7,
	-- A new brainrot is picked with weights that favour cheap commons early
	-- and let the rare ones show up as the game goes on.
	spawnWeights = { Common = 55, Rare = 25, Epic = 12, Legendary = 6, Mythic = 1.8, ["Brainrot God"] = 0.2 },
}

Config.WAVE = {
	firstWaveAfterSeconds = 150,
	waveEverySeconds = 240,
	warningSeconds = 20,
	sweepSeconds = 12,
	-- Players caught outside a base lose this share of their carried cash
	-- and drop whatever brainrot they are carrying.
	cashLossFraction = 0.10,
}

Config.LOCK = {
	lockSeconds = 30,
	cooldownSeconds = 60,
	shieldBonusSeconds = 15, -- extra lock time per Shield upgrade level
}

Config.REBIRTH = Config.ECONOMY

-- Base layout: six bases around the island edge. Base 1 (red) is the
-- joining player's base; the rest are filled as players join.
Config.BASES = {
	{ position = Vector3.new(-32, 0, -26), color = Color3.fromRGB(220, 60, 60) },
	{ position = Vector3.new(32, 0, -26), color = Color3.fromRGB(60, 120, 220) },
	{ position = Vector3.new(-38, 0, 6), color = Color3.fromRGB(60, 200, 90) },
	{ position = Vector3.new(38, 0, 6), color = Color3.fromRGB(240, 200, 40) },
	{ position = Vector3.new(-30, 0, 26), color = Color3.fromRGB(170, 90, 220) },
	{ position = Vector3.new(30, 0, 26), color = Color3.fromRGB(240, 130, 60) },
}
Config.PLOTS_PER_BASE = 8
Config.LIGHTHOUSE_POSITION = Vector3.new(-44, 0, -34)
Config.SPAWN_POSITION = Vector3.new(0, 0, 34)

-- Upgrades sold in the shop. `levels` caps how many times each can be bought.
Config.UPGRADES = {
	WalkSpeed = { name = "WalkSpeed", levels = 3, costs = { 500, 2000, 8000 }, bonusPerLevel = 4 },
	Carry = { name = "Carry Capacity", levels = 1, costs = { 15000 }, bonusPerLevel = 1 },
	Shield = { name = "Shield", levels = 3, costs = { 3000, 12000, 40000 }, bonusPerLevel = 0 },
}

-- World tuning.
Config.WORLD = {
	islandRadius = 52,
	seaLevel = -2,
	-- Carrying a stolen brainrot slows the thief down.
	carryWalkSpeed = 10,
	normalWalkSpeed = 16,
}

return Config

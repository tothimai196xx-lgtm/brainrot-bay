-- Brainrot Bay — builds the whole island at server start.
-- Every part is created from code (no pre-placed instances), so the Rojo
-- project stays tiny and the map matches the layout in Config exactly:
-- six bases around the edge, the conveyor down the middle (z = 0),
-- the lighthouse at (-44, -34) and the spawn pad on the south shore.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local WorldBuilder = {}

local function newPart(name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

-- The round sand island sitting in the sea.
function WorldBuilder.buildIsland(): Model
	local island = Instance.new("Model")
	island.Name = "Island"

	local sand = Instance.new("Part")
	sand.Name = "Sand"
	sand.Shape = Enum.PartType.Cylinder
	sand.Size = Vector3.new(6, Config.WORLD.islandRadius * 2, Config.WORLD.islandRadius * 2)
	sand.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
	sand.Color = Color3.fromRGB(238, 214, 150)
	sand.Material = Enum.Material.Sand
	sand.Anchored = true
	sand.TopSurface = Enum.SurfaceType.Smooth
	sand.Parent = island

	local sea = newPart("Sea", Vector3.new(400, 2, 400), Vector3.new(0, Config.WORLD.seaLevel, 0),
		Color3.fromRGB(40, 140, 220), Enum.Material.Water)
	sea.CanCollide = false
	sea.Parent = island

	-- A pale ring of beach around the sand so the edge reads from above.
	local rim = Instance.new("Part")
	rim.Name = "BeachRim"
	rim.Shape = Enum.PartType.Cylinder
	rim.Size = Vector3.new(1, Config.WORLD.islandRadius * 2 + 6, Config.WORLD.islandRadius * 2 + 6)
	rim.CFrame = CFrame.new(0, -0.5, 0) * CFrame.Angles(0, 0, math.rad(90))
	rim.Color = Color3.fromRGB(250, 235, 190)
	rim.Material = Enum.Material.Sand
	rim.Anchored = true
	rim.Parent = island

	return island
end

-- One player base: a platform, a back wall, a flag pole and 8 plot pads.
-- Returns the model plus the list of plot pad parts (in plot order).
function WorldBuilder.buildBase(index: number, position: Vector3, color: Color3): (Model, { Part })
	local spec = Config.BASES[index]
	local base = Instance.new("Model")
	base.Name = "Base" .. tostring(index)

	local platform = newPart("Platform", Vector3.new(17, 1, 13),
		Vector3.new(position.X, 3.5, position.Z), color)
	platform.Material = Enum.Material.Concrete
	platform.Parent = base

	-- Back wall so the base reads as a sheltered nook from the conveyor.
	local wall = newPart("BackWall", Vector3.new(17, 6, 1),
		Vector3.new(position.X, 6.5, position.Z - 6), color)
	wall.Material = Enum.Material.Concrete
	wall.Parent = base

	-- Flag pole with a coloured flag at the seaward corner.
	local pole = newPart("FlagPole", Vector3.new(0.4, 9, 0.4),
		Vector3.new(position.X - 7.5, 8, position.Z + 5.5), Color3.fromRGB(90, 90, 90))
	pole.Parent = base
	local flag = newPart("Flag", Vector3.new(3.4, 2, 0.2),
		Vector3.new(position.X - 5.6, 11.5, position.Z + 5.5), color)
	flag.Material = Enum.Material.Fabric
	flag.Parent = base

	-- A small sign over the entrance naming the base.
	local sign = newPart("Sign", Vector3.new(6, 1.6, 0.4),
		Vector3.new(position.X, 7.6, position.Z + 6.2), Color3.fromRGB(255, 255, 255))
	sign.Parent = base
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = sign
	local signLabel = Instance.new("TextLabel")
	signLabel.Size = UDim2.fromScale(1, 1)
	signLabel.BackgroundTransparency = 1
	signLabel.Text = "BASE " .. tostring(index)
	signLabel.TextScaled = true
	signLabel.Font = Enum.Font.GothamBold
	signLabel.TextColor3 = Color3.fromRGB(40, 40, 40)
	signLabel.Parent = signGui

	-- 8 plot pads in two rows of four. A bought brainrot stands on a pad
	-- and earns cash; an empty pad shows as a pale square.
	local plots = {}
	for row = 0, 1 do
		for col = 0, 3 do
			local plotIndex = row * 4 + col + 1
			local pad = newPart("Plot" .. tostring(plotIndex), Vector3.new(3.2, 0.35, 3.2),
				Vector3.new(position.X - 5.4 + col * 3.6, 4.2, position.Z - 3 + row * 3.6),
				Color3.fromRGB(245, 245, 235))
			pad.Material = Enum.Material.Neon
			pad.Parent = base
			plots[plotIndex] = pad
		end
	end

	return base, plots
end

-- The conveyor belt down the middle of the island (z = 0, along X).
-- Brainrots walk along it from west to east.
function WorldBuilder.buildConveyor(): Model
	local belt = Instance.new("Model")
	belt.Name = "Conveyor"

	local slab = newPart("Belt", Vector3.new(Config.CONVEYOR.beltLength, 1.2, Config.CONVEYOR.beltWidth),
		Vector3.new(0, 3.6, 0), Color3.fromRGB(60, 60, 70))
	slab.Material = Enum.Material.Metal
	slab.Parent = belt

	-- Yellow hazard stripes along both edges.
	for _, zOffset in ipairs({ -3, 3 }) do
		local stripe = newPart("Stripe", Vector3.new(Config.CONVEYOR.beltLength, 0.2, 0.7),
			Vector3.new(0, 4.25, zOffset), Color3.fromRGB(255, 200, 40))
		stripe.Material = Enum.Material.Neon
		stripe.Parent = belt
	end

	-- Side rails so walking brainrots stay visually on the belt.
	for _, zOffset in ipairs({ -3.7, 3.7 }) do
		local rail = newPart("Rail", Vector3.new(Config.CONVEYOR.beltLength, 0.5, 0.3),
			Vector3.new(0, 4.4, zOffset), Color3.fromRGB(120, 120, 130))
		rail.Parent = belt
	end

	return belt
end

function WorldBuilder.buildPalmTree(x: number, z: number): Model
	local tree = Instance.new("Model")
	tree.Name = "PalmTree"

	local trunk = newPart("Trunk", Vector3.new(1, 9, 1), Vector3.new(x, 7.5, z),
		Color3.fromRGB(150, 105, 60), Enum.Material.Wood)
	trunk.Parent = tree
	for i = 0, 4 do
		local angle = (i / 5) * math.pi * 2
		local leaf = newPart("Leaf", Vector3.new(5, 0.4, 1.6),
			Vector3.new(x + math.cos(angle) * 2.4, 12.2, z + math.sin(angle) * 2.4),
			Color3.fromRGB(60, 180, 80), Enum.Material.Leaf)
		leaf.CFrame = CFrame.new(leaf.Position) * CFrame.Angles(0, -angle, math.rad(-18))
		leaf.Parent = tree
	end
	local coconuts = newPart("Coconuts", Vector3.new(1.4, 1.4, 1.4), Vector3.new(x, 11.4, z),
		Color3.fromRGB(110, 75, 40))
	coconuts.Shape = Enum.PartType.Ball
	coconuts.Parent = tree

	return tree
end

-- The striped lighthouse on the north-west point of the island.
function WorldBuilder.buildLighthouse(): Model
	local pos = Config.LIGHTHOUSE_POSITION
	local tower = Instance.new("Model")
	tower.Name = "Lighthouse"

	for i = 0, 4 do
		local bandColor = if i % 2 == 0 then Color3.fromRGB(235, 235, 235) else Color3.fromRGB(220, 60, 60)
		local band = newPart("Band" .. tostring(i), Vector3.new(5, 3, 5),
			Vector3.new(pos.X, 4.5 + i * 3, pos.Z), bandColor)
		band.Parent = tower
	end
	local lamp = newPart("Lamp", Vector3.new(3.6, 2.4, 3.6),
		Vector3.new(pos.X, 20.5, pos.Z), Color3.fromRGB(255, 240, 150))
	lamp.Material = Enum.Material.Neon
	lamp.Parent = tower
	local roof = newPart("Roof", Vector3.new(4.6, 1, 4.6),
		Vector3.new(pos.X, 22.2, pos.Z), Color3.fromRGB(60, 60, 70))
	roof.Parent = tower

	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 240, 150)
	light.Range = 40
	light.Brightness = 2
	light.Parent = lamp

	return tower
end

-- A few slow-drifting clouds high above the island.
function WorldBuilder.buildClouds(): Model
	local clouds = Instance.new("Model")
	clouds.Name = "Clouds"
	local spots = { { -30, 46, -20 }, { 25, 52, -30 }, { 0, 48, 30 }, { 40, 44, 15 }, { -40, 50, 25 } }
	for i, spot in ipairs(spots) do
		local cloud = Instance.new("Model")
		cloud.Name = "Cloud" .. tostring(i)
		for j = 0, 2 do
			local puff = newPart("Puff", Vector3.new(8 - j * 2, 3, 6),
				Vector3.new(spot[1] + j * 4 - 4, spot[2], spot[3]), Color3.fromRGB(255, 255, 255))
			puff.Shape = Enum.PartType.Ball
			puff.CanCollide = false
			puff.Parent = cloud
		end
		cloud.Parent = clouds
	end
	return clouds
end

-- The spawn pad on the south shore where players arrive.
function WorldBuilder.buildSpawnPad(): Part
	local pad = newPart("SpawnPad", Vector3.new(12, 0.6, 8),
		Vector3.new(Config.SPAWN_POSITION.X, 3.3, Config.SPAWN_POSITION.Z),
		Color3.fromRGB(120, 200, 255))
	pad.Material = Enum.Material.Neon
	local spawn = Instance.new("SpawnLocation")
	spawn.Size = pad.Size
	spawn.CFrame = pad.CFrame
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.AllowTeamChangeOnTouch = false
	spawn.Parent = pad
	return pad
end

-- Builds everything and parents it under Workspace. Returns a table of
-- the built pieces so the services can find their bases and plots.
function WorldBuilder.buildWorld(): { [string]: any }
	local world = {}

	world.island = WorldBuilder.buildIsland()
	world.island.Parent = workspace

	world.conveyor = WorldBuilder.buildConveyor()
	world.conveyor.Parent = workspace

	world.lighthouse = WorldBuilder.buildLighthouse()
	world.lighthouse.Parent = workspace

	world.clouds = WorldBuilder.buildClouds()
	world.clouds.Parent = workspace

	world.spawnPad = WorldBuilder.buildSpawnPad()
	world.spawnPad.Parent = workspace

	world.bases = {}
	world.plots = {}
	for i, spec in ipairs(Config.BASES) do
		local base, plots = WorldBuilder.buildBase(i, spec.position, spec.color)
		base.Parent = workspace
		world.bases[i] = base
		world.plots[i] = plots
	end

	-- Palm trees dotted around the shore, clear of bases and the belt.
	local palmSpots = { { -20, -38 }, { 18, -38 }, { -48, 18 }, { 48, -14 }, { -14, 40 }, { 20, 40 } }
	for _, spot in ipairs(palmSpots) do
		local tree = WorldBuilder.buildPalmTree(spot[1], spot[2])
		tree.Parent = workspace
	end

	return world
end

return WorldBuilder

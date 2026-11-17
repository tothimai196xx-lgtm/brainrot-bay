-- Brainrot Bay — turns a brainrot definition into a standing 3D model.
-- Each character is an original blocky figure: a coloured body, a head with
-- eyes, one accessory (crown / cap / antenna) and a floating name tag that
-- shows its name, rarity and income per second.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Utils = require(ReplicatedStorage.Shared.Utils)

local CharacterFactory = {}

local function newPart(name: string, size: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = false
	part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	return part
end

local function addEyes(head: Part, parent: Model)
	for _, xOffset in ipairs({ -0.45, 0.45 }) do
		local eye = newPart("Eye", Vector3.new(0.35, 0.5, 0.2), Color3.fromRGB(30, 30, 30))
		eye.Position = head.Position + Vector3.new(xOffset, 0.15, head.Size.Z / 2 + 0.05)
		eye.Parent = parent
	end
end

local function addAccessory(model: Model, kind: string, head: Part, bodyColor: Color3)
	if kind == "crown" then
		local crown = newPart("Crown", Vector3.new(1.8, 0.7, 1.8), Color3.fromRGB(255, 215, 0))
		crown.Material = Enum.Material.Metal
		crown.Position = head.Position + Vector3.new(0, head.Size.Y / 2 + 0.35, 0)
		crown.Parent = model
		for _, xOffset in ipairs({ -0.6, 0, 0.6 }) do
			local spike = newPart("CrownSpike", Vector3.new(0.35, 0.6, 0.35), Color3.fromRGB(255, 215, 0))
			spike.Material = Enum.Material.Metal
			spike.Position = crown.Position + Vector3.new(xOffset, 0.55, 0)
			spike.Parent = model
		end
	elseif kind == "cap" then
		local cap = newPart("Cap", Vector3.new(2.2, 0.5, 2.2), Color3.fromRGB(220, 60, 60))
		cap.Position = head.Position + Vector3.new(0, head.Size.Y / 2 + 0.25, 0)
		cap.Parent = model
		local brim = newPart("CapBrim", Vector3.new(2.2, 0.2, 1), Color3.fromRGB(220, 60, 60))
		brim.Position = head.Position + Vector3.new(0, head.Size.Y / 2 + 0.1, head.Size.Z / 2 + 0.4)
		brim.Parent = model
	elseif kind == "antenna" then
		local rod = newPart("Antenna", Vector3.new(0.25, 1.4, 0.25), Color3.fromRGB(80, 80, 80))
		rod.Position = head.Position + Vector3.new(0, head.Size.Y / 2 + 0.7, 0)
		rod.Parent = model
		local tip = newPart("AntennaTip", Vector3.new(0.7, 0.7, 0.7), Color3.fromRGB(255, 90, 200))
		tip.Shape = Enum.PartType.Ball
		tip.Material = Enum.Material.Neon
		tip.Position = rod.Position + Vector3.new(0, 0.9, 0)
		tip.Parent = model
	end
end

-- Builds the standing model. `brainrot` is one entry from Config.BRAINROTS;
-- `mutation` is a mutation id string or nil. The model is welded together
-- and rooted at `origin` (the feet sit on the ground there).
function CharacterFactory.buildBrainrotModel(brainrot, mutation: string?): Model
	local model = Instance.new("Model")
	model.Name = brainrot.name

	local bodyColor = brainrot.body
	local headColor = brainrot.head
	if mutation then
		for _, m in ipairs(Config.MUTATIONS) do
			if m.id == mutation then
				bodyColor = m.tint
				break
			end
		end
	end

	local body = newPart("Body", Vector3.new(2.4, 2.2, 1.6), bodyColor)
	body.Position = Vector3.new(0, 1.1, 0)
	body.Parent = model

	local head = newPart("Head", Vector3.new(2, 1.8, 1.8), headColor)
	head.Position = Vector3.new(0, 3.1, 0)
	head.Parent = model

	addEyes(head, model)
	addAccessory(model, brainrot.accessory, head, bodyColor)

	-- Weld everything to the body so the figure moves as one piece.
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") and part ~= body then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = part
			weld.Parent = body
		end
	end
	body.Anchored = false
	model.PrimaryPart = body

	-- Floating name tag: name + rarity + income, tinted by mutation.
	local tag = Instance.new("BillboardGui")
	tag.Name = "NameTag"
	tag.Size = UDim2.new(0, 220, 0, 70)
	tag.StudsOffset = Vector3.new(0, 4.6, 0)
	tag.AlwaysOnTop = true
	tag.Parent = model

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.55, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = brainrot.name
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.Parent = tag

	local rateLabel = Instance.new("TextLabel")
	rateLabel.Position = UDim2.new(0, 0, 0.55, 0)
	rateLabel.Size = UDim2.new(1, 0, 0.45, 0)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = brainrot.rarity .. "  ·  " .. Utils.formatMoney(brainrot.rate) .. "/s"
	rateLabel.TextScaled = true
	rateLabel.Font = Enum.Font.Gotham
	rateLabel.TextColor3 = Utils.rarityColor(brainrot.rarity, Config)
	rateLabel.TextStrokeTransparency = 0.4
	rateLabel.Parent = tag

	model:SetAttribute("BrainrotId", brainrot.id)
	model:SetAttribute("Mutation", mutation or "")
	model:SetAttribute("Rate", brainrot.rate)
	model:SetAttribute("Cost", brainrot.cost)

	return model
end

-- Re-tints a built model after a mutation roll (used when a brainrot is
-- bought and the roll lands after the model was spawned on the belt).
function CharacterFactory.applyMutation(model: Model, mutation: string)
	local tint: Color3? = nil
	local multiplier = 1
	for _, m in ipairs(Config.MUTATIONS) do
		if m.id == mutation then
			tint = m.tint
			multiplier = m.multiplier
			break
		end
	end
	if not tint then
		return
	end
	local body = model:FindFirstChild("Body")
	if body and body:IsA("BasePart") then
		body.Color = tint
	end
	model:SetAttribute("Mutation", mutation)
	local baseRate = model:GetAttribute("Rate") or 0
	model:SetAttribute("Rate", baseRate * multiplier)

	local tag = model:FindFirstChild("NameTag")
	if tag then
		local nameLabel = tag:FindFirstChildOfClass("TextLabel")
		if nameLabel then
			nameLabel.Text = mutation .. " " .. model.Name
		end
	end
end

return CharacterFactory

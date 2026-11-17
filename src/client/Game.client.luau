-- Brainrot Bay — client: HUD, buying, stealing, base lock, rebirth and the
-- tsunami banner. Money and income sit at the TOP-RIGHT (the top-left is
-- covered by Roblox's own menu button); the title sits top-centre and the
-- three action buttons sit at the bottom centre.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Utils = require(ReplicatedStorage.Shared.Utils)

local remotes = ReplicatedStorage:WaitForChild("RemoteEvents")
local buyBrainrot = remotes:WaitForChild("BuyBrainrot")
local stealBrainrot = remotes:WaitForChild("StealBrainrot")
local waveWarning = remotes:WaitForChild("WaveWarning")
local lockBaseEvent = remotes:WaitForChild("LockBase")
local rebirthEvent = remotes:WaitForChild("Rebirth")
local buyUpgradeEvent = remotes:WaitForChild("BuyUpgrade")

-- ---------- HUD ----------

local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotBayGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- Title, top centre.
local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(0.5, 0)
title.Position = UDim2.new(0.5, 0, 0, 12)
title.Size = UDim2.fromOffset(420, 44)
title.BackgroundTransparency = 1
title.Text = "🌊 BRAINROT BAY 🌊"
title.TextSize = 30
title.Font = Enum.Font.GothamBlack
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextStrokeTransparency = 0.3
title.Parent = gui

-- Money panel, top right — clear of the Roblox menu button.
local moneyPanel = Instance.new("Frame")
moneyPanel.Name = "MoneyPanel"
moneyPanel.AnchorPoint = Vector2.new(1, 0)
moneyPanel.Position = UDim2.new(1, -12, 0, 12)
moneyPanel.Size = UDim2.fromOffset(240, 92)
moneyPanel.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
moneyPanel.BackgroundTransparency = 0.25
moneyPanel.BorderSizePixel = 0
moneyPanel.Parent = gui
local moneyCorner = Instance.new("UICorner")
moneyCorner.CornerRadius = UDim.new(0, 12)
moneyCorner.Parent = moneyPanel

local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "CashLabel"
cashLabel.Position = UDim2.new(0, 12, 0, 6)
cashLabel.Size = UDim2.new(1, -24, 0, 36)
cashLabel.BackgroundTransparency = 1
cashLabel.Text = "$250"
cashLabel.TextSize = 28
cashLabel.Font = Enum.Font.GothamBold
cashLabel.TextColor3 = Color3.fromRGB(120, 255, 120)
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.Parent = moneyPanel

local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "IncomeLabel"
incomeLabel.Position = UDim2.new(0, 12, 0, 44)
incomeLabel.Size = UDim2.new(1, -24, 0, 22)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Text = "$0/s"
incomeLabel.TextSize = 18
incomeLabel.Font = Enum.Font.Gotham
incomeLabel.TextColor3 = Color3.fromRGB(255, 230, 120)
incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
incomeLabel.Parent = moneyPanel

local rebirthLabel = Instance.new("TextLabel")
rebirthLabel.Name = "RebirthLabel"
rebirthLabel.Position = UDim2.new(0, 12, 0, 66)
rebirthLabel.Size = UDim2.new(1, -24, 0, 20)
rebirthLabel.BackgroundTransparency = 1
rebirthLabel.Text = "Rebirths: 0"
rebirthLabel.TextSize = 16
rebirthLabel.Font = Enum.Font.Gotham
rebirthLabel.TextColor3 = Color3.fromRGB(180, 200, 255)
rebirthLabel.TextXAlignment = Enum.TextXAlignment.Left
rebirthLabel.Parent = moneyPanel

-- Tsunami banner, hidden until a warning arrives.
local banner = Instance.new("Frame")
banner.Name = "WaveBanner"
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.new(0.5, 0, 0, 64)
banner.Size = UDim2.fromOffset(520, 54)
banner.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
banner.BackgroundTransparency = 0.15
banner.BorderSizePixel = 0
banner.Visible = false
banner.Parent = gui
local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 12)
bannerCorner.Parent = banner

local bannerLabel = Instance.new("TextLabel")
bannerLabel.Size = UDim2.fromScale(1, 1)
bannerLabel.BackgroundTransparency = 1
bannerLabel.Text = "🌊 TSUNAMI INCOMING — GET INSIDE YOUR BASE! 🌊"
bannerLabel.TextSize = 20
bannerLabel.Font = Enum.Font.GothamBlack
bannerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
bannerLabel.Parent = banner

-- Toast line for steal / purchase feedback, bottom centre above buttons.
local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 0, 1, -96)
toast.Size = UDim2.fromOffset(520, 30)
toast.BackgroundTransparency = 1
toast.Text = ""
toast.TextSize = 18
toast.Font = Enum.Font.GothamBold
toast.TextColor3 = Color3.fromRGB(255, 255, 255)
toast.TextStrokeTransparency = 0.3
toast.Parent = gui

local function showToast(message: string, color: Color3)
	toast.Text = message
	toast.TextColor3 = color
	task.delay(4, function()
		if toast.Text == message then
			toast.Text = ""
		end
	end)
end

-- ---------- Action buttons (bottom centre) ----------

local function makeButton(name: string, text: string, xOffset: number, color: Color3): TextButton
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, xOffset, 1, -16)
	button.Size = UDim2.fromOffset(150, 52)
	button.BackgroundColor3 = color
	button.Text = text
	button.TextSize = 18
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button
	return button
end

local lockButton = makeButton("LockBaseButton", "🔒 Lock Base", -170, Color3.fromRGB(60, 120, 220))
local rebirthButton = makeButton("RebirthButton", "♻️ Rebirth", 0, Color3.fromRGB(170, 90, 220))
local stealButton = makeButton("StealButton", "🥷 Steal", 170, Color3.fromRGB(220, 90, 60))

lockButton.MouseButton1Click:Connect(function()
	lockBaseEvent:FireServer()
	showToast("Base locked for 30 seconds!", Color3.fromRGB(120, 180, 255))
end)

rebirthButton.MouseButton1Click:Connect(function()
	rebirthEvent:FireServer()
	showToast("Rebirth requested — check your income bonus!", Color3.fromRGB(200, 150, 255))
end)

-- Steal mode: the next brainrot model the player clicks in another base
-- is the steal target. Clicking is done with a mouse click on the model.
local stealArmed = false
stealButton.MouseButton1Click:Connect(function()
	stealArmed = not stealArmed
	stealButton.Text = stealArmed and "🥷 Steal: ON" or "🥷 Steal"
	showToast(stealArmed and "Steal mode ON — click a brainrot in another base!"
		or "Steal mode off", Color3.fromRGB(255, 180, 120))
end)

-- ---------- Buying with E ----------

-- The nearest brainrot on the belt is the buy target. ContextActionService
-- (not InputBegan + gameProcessedEvent) so the key works even while the
-- Roblox camera holds the arrow keys.
local function nearestBeltBrainrot(): Model?
	local character = player.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end
	local folder = workspace:FindFirstChild("ConveyorBrainrots")
	if not folder then
		return nil
	end
	local best: Model? = nil
	local bestDistance = 10
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") and model.PrimaryPart then
			local d = Utils.distanceBetween(root.Position, model.PrimaryPart.Position)
			if d < bestDistance then
				bestDistance = d
				best = model
			end
		end
	end
	return best
end

local function onBuyAction(_actionName: string, inputState: Enum.UserInputState, _input: InputObject)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	local target = nearestBeltBrainrot()
	if not target then
		showToast("Walk up to a brainrot on the conveyor first!", Color3.fromRGB(255, 200, 120))
		return Enum.ContextActionResult.Sink
	end
	buyBrainrot:FireServer(target:GetAttribute("BrainrotId"))
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("BuyBrainrot", onBuyAction, false, Enum.KeyCode.E)

-- Steal clicks: when steal mode is armed, a click on a brainrot model in
-- another player's base sends the steal request.
local mouse = player:GetMouse()
mouse.Button1Down:Connect(function()
	if not stealArmed then
		return
	end
	local target = mouse.Target
	if not target then
		return
	end
	local model = target:FindFirstAncestorOfClass("Model")
	if not model or not model:GetAttribute("BrainrotId") then
		return
	end
	-- Which base does this model belong to? Its plot pad's parent base.
	local baseIndex = 0
	for i = 1, 6 do
		local base = workspace:FindFirstChild("Base" .. tostring(i))
		if base and model:IsDescendantOf(base) then
			baseIndex = i
			break
		end
	end
	if baseIndex == 0 then
		return
	end
	local plotIndex = 0
	for i = 1, 8 do
		local occupant = model.Parent
		if occupant and occupant.Name == "Base" .. tostring(baseIndex) then
			plotIndex = i
			break
		end
	end
	stealBrainrot:FireServer(baseIndex, plotIndex)
	stealArmed = false
	stealButton.Text = "🥷 Steal"
end)

-- ---------- Wave warnings ----------

waveWarning.OnClientEvent:Connect(function(kind: string, secondsLeft: number)
	if kind == "warning" then
		banner.Visible = true
		bannerLabel.Text = "🌊 TSUNAMI IN " .. tostring(secondsLeft) .. "s — GET INSIDE YOUR BASE! 🌊"
		-- Flash the banner while the warning runs.
		task.spawn(function()
			for _ = 1, 10 do
				if not banner.Visible then
					break
				end
				banner.BackgroundTransparency = 0.45
				task.wait(0.5)
				banner.BackgroundTransparency = 0.15
				task.wait(0.5)
			end
		end)
	elseif kind == "wave" then
		bannerLabel.Text = "🌊 TSUNAMI! HOLD ON! 🌊"
		task.delay(secondsLeft, function()
			banner.Visible = false
		end)
	end
end)

-- ---------- HUD refresh ----------

local function refreshHud()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end
	local cash = leaderstats:FindFirstChild("Cash")
	if cash and cash:IsA("IntValue") then
		cashLabel.Text = Utils.formatMoney(cash.Value)
	end
	local rebirths = leaderstats:FindFirstChild("Rebirths")
	if rebirths and rebirths:IsA("IntValue") then
		rebirthLabel.Text = "Rebirths: " .. tostring(rebirths.Value)
	end
end

player.ChildAdded:Connect(function(child)
	if child.Name == "leaderstats" then
		refreshHud()
		local cash = child:FindFirstChild("Cash")
		if cash then
			cash.Changed:Connect(refreshHud)
		end
	end
end)
refreshHud()

-- Income per second is recomputed from the plots once a second by polling
-- the server through the leaderstats cash delta (cheap, no extra remote).
local lastCash = 0
task.spawn(function()
	while true do
		task.wait(1)
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local cash = leaderstats:FindFirstChild("Cash")
			if cash and cash:IsA("IntValue") then
				local gained = cash.Value - lastCash
				if gained > 0 then
					incomeLabel.Text = Utils.formatMoney(gained) .. "/s"
				end
				lastCash = cash.Value
			end
		end
	end
end)

print("[Brainrot Bay] client ready — press E near a brainrot to buy it")

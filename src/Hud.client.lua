-- Talisman counter, messages, the red dread tint near the ghost, and the catch screen.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local notifyEvent = ReplicatedStorage:WaitForChild("Notify")
local scareEvent = ReplicatedStorage:WaitForChild("Scare")

local player = Players.LocalPlayer

local MESSAGE_TIME = 4
local SCARE_TIME = 1.5
local MAX_DREAD = 0.45 -- strongest tint, when the ghost is on top of you

local WHITE = Color3.fromRGB(255, 255, 255)
local RED = Color3.fromRGB(170, 0, 0)

local gui = Instance.new("ScreenGui")
gui.Name = "Hud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function newLabel(name, position, size, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Text = ""
	label.Parent = gui
	return label
end

local dread = Instance.new("Frame")
dread.Name = "Dread"
dread.Size = UDim2.fromScale(1, 1)
dread.BackgroundColor3 = RED
dread.BackgroundTransparency = 1
dread.BorderSizePixel = 0
dread.Parent = gui

local counter = newLabel("Counter", UDim2.fromScale(0.5, 0.06), UDim2.fromScale(0.3, 0.05), WHITE)
local message = newLabel("Message", UDim2.fromScale(0.5, 0.13), UDim2.fromScale(0.6, 0.04), WHITE)

local scare = Instance.new("TextLabel")
scare.Name = "Scare"
scare.Size = UDim2.fromScale(1, 1)
scare.BackgroundColor3 = Color3.new(0, 0, 0)
scare.BorderSizePixel = 0
scare.Font = Enum.Font.GothamBlack
scare.TextScaled = true
scare.TextColor3 = RED
scare.Text = "SHE FOUND YOU"
scare.Visible = false
scare.ZIndex = 10
scare.Parent = gui

local function updateCounter()
	local found = Workspace:GetAttribute("Talismans") or 0
	counter.Text = string.format("Talismans %d / %d", found, Config.TalismanCount)
end

local messageId = 0
local function showMessage(text)
	messageId += 1
	local id = messageId
	message.Text = text
	task.delay(MESSAGE_TIME, function()
		if messageId == id then
			message.Text = ""
		end
	end)
end

Workspace:GetAttributeChangedSignal("Talismans"):Connect(updateCounter)
updateCounter()

notifyEvent.OnClientEvent:Connect(showMessage)

scareEvent.OnClientEvent:Connect(function()
	scare.Visible = true
	task.delay(SCARE_TIME, function()
		scare.Visible = false
	end)
end)

RunService.RenderStepped:Connect(function()
	local ghost = Workspace:FindFirstChild("Ghost")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not ghost or not root then
		dread.BackgroundTransparency = 1
		return
	end
	local distance = (ghost:GetPivot().Position - root.Position).Magnitude
	local closeness = math.clamp(1 - distance / Config.Ghost.DreadRadius, 0, 1)
	dread.BackgroundTransparency = 1 - closeness * MAX_DREAD
end)

showMessage("Find the talismans to open the gate. Walk quietly - she hears you run.")

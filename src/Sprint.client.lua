-- Hold Left Shift (or the Run button on touch) to sprint while stamina lasts.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local player = Players.LocalPlayer

local stamina = Config.StaminaSeconds
local wantsSprint = false
local exhausted = false -- set when the bar empties; blocks sprinting until it recovers a little

local gui = Instance.new("ScreenGui")
gui.Name = "Stamina"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local bar = Instance.new("Frame")
bar.Name = "Bar"
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.fromScale(0.5, 0.95)
bar.Size = UDim2.fromScale(0.2, 0.012)
bar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
bar.BackgroundTransparency = 0.4
bar.BorderSizePixel = 0
bar.Parent = gui

local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.fromScale(1, 1)
fill.BackgroundColor3 = Color3.fromRGB(230, 230, 220)
fill.BorderSizePixel = 0
fill.Parent = bar

ContextActionService:BindAction("Sprint", function(_, state)
	wantsSprint = state == Enum.UserInputState.Begin
	return Enum.ContextActionResult.Pass
end, true, Enum.KeyCode.LeftShift)
ContextActionService:SetTitle("Sprint", "Run")

RunService.RenderStepped:Connect(function(dt)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	local moving = humanoid.MoveDirection.Magnitude > 0
	local sprinting = wantsSprint and moving and not exhausted

	if sprinting then
		stamina = math.max(0, stamina - dt)
		if stamina == 0 then
			exhausted = true
		end
	else
		stamina = math.min(Config.StaminaSeconds, stamina + Config.StaminaRegen * dt)
		if stamina >= Config.StaminaRecover then
			exhausted = false
		end
	end

	humanoid.WalkSpeed = sprinting and Config.SprintSpeed or Config.WalkSpeed
	fill.Size = UDim2.fromScale(stamina / Config.StaminaSeconds, 1)
end)

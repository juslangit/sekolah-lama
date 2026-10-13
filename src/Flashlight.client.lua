-- A flashlight that follows the camera. Press F (or the Light button on touch) to toggle it.
-- The light exists only on this client, so other players do not see it yet.
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local lamp = Instance.new("Part")
lamp.Name = "Flashlight"
lamp.Anchored = true
lamp.CanCollide = false
lamp.CanQuery = false
lamp.CanTouch = false
lamp.Transparency = 1
lamp.Size = Vector3.new(0.2, 0.2, 0.2)
lamp.Parent = Workspace

local light = Instance.new("SpotLight")
light.Face = Enum.NormalId.Front
light.Angle = 60
light.Range = 50
light.Brightness = 2
light.Shadows = true
light.Parent = lamp

ContextActionService:BindAction("Flashlight", function(_, state)
	if state == Enum.UserInputState.Begin then
		light.Enabled = not light.Enabled
	end
	return Enum.ContextActionResult.Sink
end, true, Enum.KeyCode.F)
ContextActionService:SetTitle("Flashlight", "Light")

RunService.RenderStepped:Connect(function()
	lamp.CFrame = Workspace.CurrentCamera.CFrame
end)

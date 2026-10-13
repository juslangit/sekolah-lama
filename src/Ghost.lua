-- The ghost. She drifts between waypoints, straight through walls, and chases anyone she sees or hears.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local Ghost = {}

local SETTINGS = Config.Ghost
local FLOAT_HEIGHT = 3.5
local EYE_OFFSET = Vector3.new(0, 2, 0)
local LOOK_INTERVAL = 0.2 -- seconds between detection checks
local RUN_MARGIN = 2 -- speed above a walk that counts as noise
local MIN_X = 4 -- keeps her out of the lobby

local random = Random.new()

local function newPiece(model, name, size, offset, color, material, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Size = size
	part.CFrame = CFrame.new(offset)
	part.Color = color
	part.Material = material
	part.Transparency = transparency
	part.Parent = model
	return part
end

-- Built around the origin facing -Z, which is the direction CFrame.lookAt points her.
local function buildModel()
	local model = Instance.new("Model")
	model.Name = "Ghost"

	local white = Color3.fromRGB(225, 225, 220)
	local black = Color3.fromRGB(12, 12, 12)
	local red = Color3.fromRGB(255, 30, 30)

	local body = newPiece(model, "Body", Vector3.new(2.5, 6, 1.5), Vector3.new(0, 0, 0), white, Enum.Material.SmoothPlastic, 0.25)
	newPiece(model, "Hair", Vector3.new(2.8, 3.6, 1.6), Vector3.new(0, 1.8, 0.3), black, Enum.Material.SmoothPlastic, 0)
	newPiece(model, "Face", Vector3.new(1.6, 1.6, 0.3), Vector3.new(0, 2, -0.7), white, Enum.Material.SmoothPlastic, 0)
	newPiece(model, "EyeLeft", Vector3.new(0.3, 0.2, 0.1), Vector3.new(-0.4, 2.2, -0.88), red, Enum.Material.Neon, 0)
	newPiece(model, "EyeRight", Vector3.new(0.3, 0.2, 0.1), Vector3.new(0.4, 2.2, -0.88), red, Enum.Material.Neon, 0)

	local glow = Instance.new("PointLight")
	glow.Color = red
	glow.Brightness = 0.6
	glow.Range = 10
	glow.Parent = body

	model.PrimaryPart = body
	return model
end

-- Starts the ghost. onCatch(player) runs each time she catches someone.
function Ghost.start(world, onCatch)
	local model = buildModel()
	local position = Vector3.new(world.length - 10, FLOAT_HEIGHT, 0)
	model:PivotTo(CFrame.new(position))
	model.Parent = Workspace

	local function randomWaypoint()
		return world.waypoints[random:NextInteger(1, #world.waypoints)]
	end

	local destination = randomWaypoint()
	local target = nil
	local lastNoticed = 0
	local restUntil = 0
	local nextLook = 0

	local function setTarget(player)
		if target ~= player then
			target = player
			model:SetAttribute("Chasing", player ~= nil)
		end
	end

	-- The living character of a player who is past the lobby, or nil.
	local function rootOf(player)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 and root.Position.X > 0 then
			return root, humanoid
		end
		return nil
	end

	-- Nearest player she can hear running or see in a straight line.
	local function detect()
		local eye = position + EYE_OFFSET
		local best, bestDistance
		for _, player in Players:GetPlayers() do
			local root = rootOf(player)
			if root then
				local offset = root.Position - eye
				local distance = offset.Magnitude
				local noticed = false

				if distance <= SETTINGS.HearRadius then
					local velocity = root.AssemblyLinearVelocity
					noticed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude > Config.WalkSpeed + RUN_MARGIN
				end
				if not noticed and distance <= SETTINGS.SightRadius then
					local hit = Workspace:Raycast(eye, offset)
					noticed = hit == nil or hit.Instance:IsDescendantOf(player.Character)
				end

				if noticed and (not bestDistance or distance < bestDistance) then
					best, bestDistance = player, distance
				end
			end
		end
		return best
	end

	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		if now < restUntil then
			return
		end

		if now >= nextLook then
			nextLook = now + LOOK_INTERVAL
			local noticed = detect()
			if noticed then
				setTarget(noticed)
				lastNoticed = now
			elseif target and now - lastNoticed > SETTINGS.LoseTime then
				setTarget(nil)
				destination = randomWaypoint()
			end
		end

		local root, humanoid
		if target then
			root, humanoid = rootOf(target)
		end

		local goal = root and root.Position or destination
		local flat = Vector3.new(goal.X - position.X, 0, goal.Z - position.Z)
		local distance = flat.Magnitude

		if root and distance <= SETTINGS.CatchRadius then
			local caught = target
			humanoid.Health = 0
			setTarget(nil)
			restUntil = now + SETTINGS.RestTime
			destination = randomWaypoint()
			onCatch(caught)
			return
		end

		if distance < 1 then
			if not root then
				destination = randomWaypoint()
			end
			return
		end

		local speed = target and SETTINGS.ChaseSpeed or SETTINGS.PatrolSpeed
		local direction = flat.Unit
		local step = math.min(distance, speed * dt)
		local x = math.clamp(position.X + direction.X * step, MIN_X, world.length - 2)
		position = Vector3.new(x, FLOAT_HEIGHT, position.Z + direction.Z * step)
		model:PivotTo(CFrame.lookAt(position, position + direction))
	end)

	return model
end

return Ghost

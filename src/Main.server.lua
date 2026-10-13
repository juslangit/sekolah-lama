-- Round rules. The server owns the talisman count, the gate and the ghost; clients only walk and trigger prompts.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local World = require(script.Parent:WaitForChild("World"))
local Ghost = require(script.Parent:WaitForChild("Ghost"))

local notifyEvent = Instance.new("RemoteEvent")
notifyEvent.Name = "Notify"
notifyEvent.Parent = ReplicatedStorage

local scareEvent = Instance.new("RemoteEvent")
scareEvent.Name = "Scare"
scareEvent.Parent = ReplicatedStorage

-- Pitch-black night. The only light comes from lamps, talismans and flashlights.
local BLACK = Color3.new(0, 0, 0)
Lighting.ClockTime = 0
Lighting.Brightness = 0
Lighting.Ambient = BLACK
Lighting.OutdoorAmbient = BLACK
Lighting.EnvironmentDiffuseScale = 0
Lighting.EnvironmentSpecularScale = 0
Lighting.GlobalShadows = true
Lighting.FogColor = BLACK
Lighting.FogStart = 10
Lighting.FogEnd = 120

StarterPlayer.CharacterWalkSpeed = Config.WalkSpeed
Players.RespawnTime = Config.RespawnTime

local world = World.build()

local found = 0
local roundOver = false

local function notifyAll(message)
	notifyEvent:FireAllClients(message)
end

local function startRound()
	found = 0
	roundOver = false
	World.setGate(world, false)
	Workspace:SetAttribute("Talismans", 0)

	for _, talisman in World.spawnTalismans(world) do
		talisman:FindFirstChildOfClass("ProximityPrompt").Triggered:Connect(function(player)
			if roundOver or not talisman.Parent then
				return
			end
			talisman:Destroy()
			found += 1
			Workspace:SetAttribute("Talismans", found)

			if found >= Config.TalismanCount then
				World.setGate(world, true)
				notifyAll(player.DisplayName .. " found the last talisman. The gate is open - run!")
			else
				notifyAll(player.DisplayName .. " found a talisman.")
			end
		end)
	end
end

-- The first player through the open gate wins the round for everyone.
world.escape.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player or roundOver or found < Config.TalismanCount then
		return
	end
	roundOver = true
	notifyAll(player.DisplayName .. " escaped! A new night begins soon.")

	task.delay(Config.RoundRestartTime, function()
		startRound()
		for _, other in Players:GetPlayers() do
			other:LoadCharacter()
		end
	end)
end)

local function onPlayerAdded(player)
	if Config.FirstPerson then
		player.CameraMode = Enum.CameraMode.LockFirstPerson
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	onPlayerAdded(player)
end

startRound()

Ghost.start(world, function(player)
	scareEvent:FireClient(player)
end)

local rollHandler = {}

local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Broadcast = game.ReplicatedStorage
	:WaitForChild("Remotes")
	:WaitForChild("Broadcast")

local lastRollTime = 0
local buffered = false
local bufferExpire = 0

local gameconfig
local ObjectOriented

Broadcast.OnClientEvent:Connect(function(tag, data)
	if tag == "gameconfig" then
		gameconfig = data
		ObjectOriented = game:WaitForChild("CustomService").Public.ObjectOriented
	end
end)

local function getInputDirection()
	local x, z = 0, 0
	if UIS:IsKeyDown(Enum.KeyCode.W) then z -= 1 end
	if UIS:IsKeyDown(Enum.KeyCode.S) then z += 1 end
	if UIS:IsKeyDown(Enum.KeyCode.A) then x -= 1 end
	if UIS:IsKeyDown(Enum.KeyCode.D) then x += 1 end
	return Vector3.new(x, 0, z)
end

local function getCameraRelativeDirection(input)
	if input.Magnitude < 0.1 then return nil end

	local camCF = camera.CFrame

	local camForward = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
	if camForward.Magnitude > 0 then camForward = camForward.Unit end

	local camRight = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
	if camRight.Magnitude > 0 then camRight = camRight.Unit end

	local dir =
		(camForward * -input.Z) +
		(camRight * input.X)

	if dir.Magnitude < 0.1 then return nil end
	return dir.Unit, camForward, camRight
end

local function executeRoll()
	if not gameconfig or not ObjectOriented then return end

	local char = player.Character
	if not char or not char.PrimaryPart then return end

	local roll = gameconfig.InputMap.Roll
	local now = tick()
	if now - lastRollTime < roll.Cooldown then return end
	lastRollTime = now

	local input = getInputDirection()
	local direction, camForward, camRight = getCameraRelativeDirection(input)

	if not direction then
		direction = camForward
	end

	local hrp = char.PrimaryPart
	local targetCF = CFrame.lookAt(
		hrp.Position,
		hrp.Position + direction
	)

	hrp.CFrame = targetCF

	local dotForward = direction:Dot(camForward)
    local dotRight = direction:Dot(camRight)

    if dotForward > 0.5 then
        animId = roll.Forward
    elseif dotForward < -0.5 then
        animId = roll.BackRoll
    elseif dotRight > 0 then
        animId = roll.RightRoll
    else
        animId = roll.LeftRoll
    end

	ObjectOriented:Fire(
		char,
		{
			Animation = {
				animType = "Play",
				animId = animId,
				looped = false
			},
			AppyImpulse = {
				force = direction * 55,
				duration = 0.2
			},
			RigTrail = {
				value = 0.8,
				color = Color3.new(1,1,1),
				duration = 0.3
			},
			ChangeFOV = {
				targetFOV = camera.FieldOfView - 18,
				speed = 5,
				duration = 0.25
			},
			ApplyShake = {
				amount = 0.3,
				duration = 0.05,
				smoothness = 0.8
			}
		}
	)
end

UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if not gameconfig then return end

	local roll = gameconfig.InputMap.Roll
	if input.KeyCode == roll.Key then
		buffered = true
		bufferExpire = tick() + 0.15
	end
end)

RS.RenderStepped:Connect(function()
	if buffered then
		if tick() > bufferExpire then
			buffered = false
			return
		end
		executeRoll()
		buffered = false
	end
end)

return rollHandler

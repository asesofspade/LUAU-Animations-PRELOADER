local soulslikeCamera = {}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable

local MIN_DISTANCE = 10
local MAX_DISTANCE = 30
player.CameraMinZoomDistance = MAX_DISTANCE
player.CameraMaxZoomDistance = MAX_DISTANCE

local ZOOM_SPEED = 4
local ZOOM_LERP_SPEED = 10

local Broadcast = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Broadcast")
local comms = game.ReplicatedStorage.Remotes.Comms

local CameraState = {FREE="Free", LOCKED="Locked"}
local state = CameraState.FREE
local currentTarget

local yaw = 0
local pitch = math.rad(-15)

local distance = 15
local targetDistance = distance
local SENS = 0.003
local MIN_PITCH = math.rad(-70)
local MAX_PITCH = math.rad(25)
local ROT_SPEED = 12
local inputVector = Vector3.zero
local character
local humanoid
local hrp
local lockSpeed = 12

local unlockAlpha = 0
local unlockStart = CFrame.new()

local isRunning = false

local function cacheCharacter()
	character = player.Character
	if not character then return end
	humanoid = character:FindFirstChildOfClass("Humanoid")
	hrp = character:FindFirstChild("HumanoidRootPart")
	if humanoid then humanoid.AutoRotate = false end
end

local function getPivot()
	if not hrp then return end
	return hrp.Position + Vector3.new(0, 1.5, 0)
end

local function isValidTarget(model)
	return model and model:IsA("Model") and model ~= character and model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart")
end

local function updateInputVector()
	local x,z=0,0
	if UIS:IsKeyDown(Enum.KeyCode.W) then z-=1 end
	if UIS:IsKeyDown(Enum.KeyCode.S) then z+=1 end
	if UIS:IsKeyDown(Enum.KeyCode.A) then x-=1 end
	if UIS:IsKeyDown(Enum.KeyCode.D) then x+=1 end
	inputVector = Vector3.new(x,0,z)
end

local function rotateCharacter(dt)
	if not hrp or inputVector.Magnitude<0.1 then return end
	local camForward = Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z)
	if camForward.Magnitude<0.001 then return end
	camForward = camForward.Unit
	local camRight = Vector3.new(camera.CFrame.RightVector.X,0,camera.CFrame.RightVector.Z).Unit
	local desiredDir = (camForward*-inputVector.Z)+(camRight*inputVector.X)
	if desiredDir.Magnitude<0.1 then return end
	desiredDir = desiredDir.Unit
	local targetCF = CFrame.lookAt(hrp.Position, hrp.Position+desiredDir)
	hrp.CFrame = hrp.CFrame:Lerp(targetCF, math.clamp(dt*ROT_SPEED,0,1))
end

local function updateFree(dt)
	local pivot = getPivot()
	if not pivot then return end
	local rot = CFrame.fromEulerAnglesYXZ(pitch,yaw,0)
	local camPos = pivot-(rot.LookVector*distance)
	local targetCFrame = CFrame.lookAt(camPos,pivot)
	if unlockAlpha<1 then
		unlockAlpha = math.clamp(unlockAlpha + dt*lockSpeed,0,1)
		local lerpedPos = unlockStart.Position:Lerp(targetCFrame.Position, unlockAlpha)
		camera.CFrame = CFrame.lookAt(lerpedPos,pivot)
	else
		camera.CFrame = targetCFrame
	end
end

local lockPivot = nil
local lockDistance = 20
local lockHeight = 0

local lockStart = nil 

local function updateLockOn(dt)
	if not currentTarget or not isValidTarget(currentTarget) then
		soulslikeCamera:Unlock()
		return
	end

	if not hrp then return end

	local pivot = hrp.Position + Vector3.new(0, 1.5, 0) -- Centro del jugador
	local targetPos = currentTarget.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0)

	local direction = pivot - targetPos
	direction = Vector3.new(direction.X, 0, direction.Z)
	if direction.Magnitude < 0.01 then direction = Vector3.new(0,0,-1) end
	direction = direction.Unit

	local camPos = pivot + Vector3.new(0, lockHeight, 0) + direction * distance

	if not lockStart then lockStart = camPos end

	lockStart = lockStart:Lerp(camPos, math.clamp(lockSpeed * dt, 0, 1))
	camera.CFrame = CFrame.lookAt(lockStart, targetPos)
end

UIS.InputChanged:Connect(function(input, gpe)
	if gpe then return end

	if state == CameraState.FREE then
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			yaw -= input.Delta.X * SENS
			pitch = math.clamp(pitch - input.Delta.Y * SENS, MIN_PITCH, MAX_PITCH)
		end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			targetDistance = math.clamp(targetDistance - input.Position.Z * ZOOM_SPEED, MIN_DISTANCE, MAX_DISTANCE)
		end
	elseif state == CameraState.LOCKED then
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			targetDistance = math.clamp(targetDistance - input.Position.Z * ZOOM_SPEED, MIN_DISTANCE, MAX_DISTANCE)
		end
	end
end)

UIS.InputBegan:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isRunning = true
	end
end)

UIS.InputEnded:Connect(function(input, gpe)
	if gpe then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		isRunning = false
	end
end)

RunService.RenderStepped:Connect(function(dt)
	if not character or not hrp then return end
	distance += (targetDistance - distance) * math.clamp(dt*ZOOM_LERP_SPEED,0,1)
	updateInputVector()
	
	if state == CameraState.FREE or (state == CameraState.LOCKED and isRunning) then
		rotateCharacter(dt)
	end
	
	if state==CameraState.FREE then
		updateFree(dt)
	elseif state==CameraState.LOCKED then
		if not isRunning then
			if humanoid and currentTarget and isValidTarget(currentTarget) then
				local targetPos = currentTarget.HumanoidRootPart.Position + Vector3.new(0,1.5,0)
				local desiredLook = CFrame.lookAt(hrp.Position, targetPos, Vector3.yAxis)
				hrp.CFrame = hrp.CFrame:Lerp(desiredLook, math.clamp(dt * lockSpeed, 0, 1))
			end
		else
				rotateCharacter(dt)

		end
		updateLockOn(dt)
	end
end)

function soulslikeCamera:LockOn(target)
	if not isValidTarget(target) then return end
	currentTarget = target
	state = CameraState.LOCKED
	lockPivot = nil
	lockStart = camera.CFrame.Position
end


function soulslikeCamera:Unlock()
    if state==CameraState.FREE then return end
    if not character or not hrp then
        state = CameraState.FREE
        return
    end

    unlockStart = camera.CFrame
    unlockAlpha = 0
    lockPivot = nil
    currentTarget = nil

    local lookDir = (unlockStart.Position - hrp.Position).Unit
    yaw = math.atan2(lookDir.X, lookDir.Z)
    pitch = math.asin(lookDir.Y)

    state = CameraState.FREE
end

function soulslikeCamera:SetDistance(value)
	targetDistance = math.clamp(value, MIN_DISTANCE, MAX_DISTANCE)
end

function soulslikeCamera:SetSensitivity(value)
	SENS = value
end

comms.Event:Connect(function(tag,data)
	if tag=="lock" and data.target then
		lockSpeed = data.speed or 12
		soulslikeCamera:LockOn(data.target)
	elseif tag=="unlock" then
		soulslikeCamera:Unlock()
	end
end)

Broadcast.OnClientEvent:Connect(function(data)
	if typeof(data)~="table" or not data.Camera then return end
	local cam = data.Camera
	if cam.LockOn then soulslikeCamera:LockOn(cam.LockOn) end
	if cam.Unlock then soulslikeCamera:Unlock() end
	if cam.Distance then soulslikeCamera:SetDistance(cam.Distance) end
	if cam.Sensitivity then soulslikeCamera:SetSensitivity(cam.Sensitivity) end
end)

player.CharacterAdded:Connect(cacheCharacter)
if player.Character then cacheCharacter() end

return soulslikeCamera

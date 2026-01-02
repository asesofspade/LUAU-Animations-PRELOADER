local FocusOnEnemy = {}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local comms = game.ReplicatedStorage.Remotes.Comms

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Broadcast = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Broadcast")

local gameconfig
local ObjectOriented

local lockedEnemy = nil

Broadcast.OnClientEvent:Connect(function(tag, data)
    if tag == "gameconfig" then
        gameconfig = data
        local cs = game:FindFirstChild("CustomService")
        if cs then
            ObjectOriented = cs.Public.ObjectOriented
        end
    end
end)

local function getEnemyUnderMouse()
    local mousePos = UIS:GetMouseLocation()
    local mouseRay = camera:ScreenPointToRay(mousePos.X, mousePos.Y)
    
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {player.Character} 
    rayParams.IgnoreWater = true

    local raycastResult = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 500, rayParams)
    if raycastResult then
        local hitPart = raycastResult.Instance
        local model = hitPart:FindFirstAncestorOfClass("Model")
        if model and CollectionService:HasTag(model, "Enemy") then
            return model
        end
    end
    return nil
end

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not gameconfig or not gameconfig.InputMap then return end
    local key = gameconfig.InputMap.Focus

    if input.KeyCode == key then
        if lockedEnemy then
            if ObjectOriented then
                comms:Fire("unlock")
            end
            lockedEnemy = nil
        else
            local enemy = getEnemyUnderMouse()
            if enemy then
                lockedEnemy = enemy
                if ObjectOriented then
                    comms:Fire("lock", {target = lockedEnemy, speed = 8})
                end
            end
        end
    end
end)

return FocusOnEnemy

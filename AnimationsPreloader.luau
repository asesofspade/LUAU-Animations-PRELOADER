local AnimationPreloader = {}
local ContentProvider = game:GetService("ContentProvider")
local Broadcast = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Broadcast")

AnimationPreloader.Animations = {}

local function gatherAnimIds(tableOrValue)
    local ids = {}

    local function traverse(value)
        if typeof(value) == "table" then
            for _, v in pairs(value) do
                traverse(v)
            end
        elseif typeof(value) == "string" and value:match("^rbxassetid://") then
            table.insert(ids, value)
        end
    end

    traverse(tableOrValue)
    return ids
end

local function preloadAnimations(gameconfig)
    local animIds = gatherAnimIds(gameconfig)
    local assetsToPreload = {}

    for _, id in ipairs(animIds) do
        local anim = Instance.new("Animation")
        anim.AnimationId = id
        table.insert(assetsToPreload, anim)
        AnimationPreloader.Animations[id] = anim
    end

    if #assetsToPreload > 0 then
        ContentProvider:PreloadAsync(assetsToPreload)
    end
end

Broadcast.OnClientEvent:Connect(function(tag, data)
    if tag == "gameconfig" then
        preloadAnimations(data)
    end
end)

function AnimationPreloader:GetAnimation(animId)
    return AnimationPreloader.Animations[animId]
end

return AnimationPreloader

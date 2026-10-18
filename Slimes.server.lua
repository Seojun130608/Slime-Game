-- Put this Script in ServerScriptService alongside Grassland.
-- Piece 1: one table stores the appearance and fixed rarity of each type.
local types = {
    {name = "Grass", rarity = "Common", color = Color3.fromRGB(110, 210, 80)},
    {name = "Mud", rarity = "Common", color = Color3.fromRGB(135, 90, 60)},
    {name = "Water", rarity = "Uncommon", color = Color3.fromRGB(70, 175, 245)},
    {name = "Honey", rarity = "Rare", color = Color3.fromRGB(245, 160, 40)},
    {name = "Crystal", rarity = "Epic", color = Color3.fromRGB(175, 115, 245)},
    {name = "Gold", rarity = "Legendary", color = Color3.fromRGB(255, 215, 65)},
}

-- Piece 2: a helper creates one anchored, rounded part.
local function ball(name, size, position, color, parent)
    local part = Instance.new("Part")
    part.Name = name
    part.Shape = Enum.PartType.Ball
    part.Size = size
    part.Position = position
    part.Color = color
    part.Material = Enum.Material.SmoothPlastic
    part.Anchored = true
    part.CanCollide = false
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

-- Piece 3: wait until Grassland has finished creating the nests.
local map = workspace:WaitForChild("SlimeMap")
local nests = map:WaitForChild("Nests")
if map:FindFirstChild("WildSlimes") then return end
local slimes = Instance.new("Folder")
slimes.Name = "WildSlimes"
slimes.Parent = map

for index, slimeType in ipairs(types) do
    -- Two types per nest: indices 1/2, 3/4, and 5/6.
    local nestIndex = math.ceil(index / 2)
    local nest = nests:WaitForChild("Nest" .. nestIndex)
    local center = nest:GetAttribute("SpawnCenter") or nest:GetBoundingBox().Position
    local side = index % 2 == 1 and -4 or 4
    local position = Vector3.new(center.X + side, center.Y, center.Z)

    local slime = Instance.new("Model")
    slime.Name = slimeType.name .. "Slime"
    slime:SetAttribute("SlimeType", slimeType.name)
    slime:SetAttribute("Rarity", slimeType.rarity)
    slime.Parent = slimes

    -- The bottom is hidden beneath the ground for a flat-bottomed dome.
    local body = ball("Body", Vector3.new(4, 3, 4), position + Vector3.new(0, 0.45, 0), slimeType.color, slime)
    body.Transparency = 0.08
    slime.PrimaryPart = body
    local black = Color3.fromRGB(20, 20, 25)
    ball("LeftEye", Vector3.new(0.28, 0.4, 0.22), position + Vector3.new(-0.65, 1, 1.77), black, slime)
    ball("RightEye", Vector3.new(0.28, 0.4, 0.22), position + Vector3.new(0.65, 1, 1.77), black, slime)
    ball("Mouth", Vector3.new(0.4, 0.18, 0.18), position + Vector3.new(0, 0.65, 1.98), black, slime)
end
print("Slimes ready: Grass, Mud, Water, Honey, Crystal, Gold")

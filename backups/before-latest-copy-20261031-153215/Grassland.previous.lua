-- Roblox Luau. Run in Studio's Command Bar to build and save an editable map,
-- or paste into a Script in ServerScriptService to build it when Play starts.
-- Coordinates: X/Z span the ground; Y is height.
if workspace:FindFirstChild("SlimeMap") then
    return -- Keep the existing map instead of making duplicates.
end

local map = Instance.new("Model")
map.Name = "SlimeMap"

-- A function lets us reuse the same part setup.
local function part(name, size, position, color, parent)
    local item = Instance.new("Part")
    item.Name = name
    item.Size = size
    item.Position = position
    item.Anchored = true
    item.Color = color
    item.Material = Enum.Material.SmoothPlastic
    item.TopSurface = Enum.SurfaceType.Smooth
    item.BottomSurface = Enum.SurfaceType.Smooth
    item.Parent = parent
    return item
end

local ground = workspace:FindFirstChild("Grassland") or workspace:FindFirstChild("Baseplate")
if not ground then
    ground = part("Grassland", Vector3.new(300, 1, 300), Vector3.new(0, -0.5, 0), Color3.fromRGB(86, 150, 65), map)
end
ground.Name = "Grassland"
ground.Size = Vector3.new(300, 1, 300)
ground.Position = Vector3.new(0, -0.5, 0)
ground.Anchored = true
ground.CanCollide = true
ground.Color = Color3.fromRGB(86, 150, 65)
ground.Material = Enum.Material.Grass
ground.Parent = map

local bases = Instance.new("Folder")
bases.Name = "Bases"
bases.Parent = map
for index, x in ipairs({-65, 65}) do
    local base = Instance.new("Model")
    base.Name = "Base" .. index
    base.Parent = bases
    part("Platform", Vector3.new(44, 1, 36), Vector3.new(x, 0.5, 65), Color3.fromRGB(210, 190, 140), base)
    -- Borders mark the future safe zones; protection is a later feature.
    local border = Color3.fromRGB(190, 245, 205)
    part("Border", Vector3.new(44, 0.2, 1), Vector3.new(x, 1.1, 47.5), border, base)
    part("Border", Vector3.new(44, 0.2, 1), Vector3.new(x, 1.1, 82.5), border, base)
    part("Border", Vector3.new(1, 0.2, 34), Vector3.new(x - 21.5, 1.1, 65), border, base)
    part("Border", Vector3.new(1, 0.2, 34), Vector3.new(x + 21.5, 1.1, 65), border, base)
end

local nests = Instance.new("Folder")
nests.Name = "Nests"
nests.Parent = map
for index, position in ipairs({Vector3.new(-70, 0, -45), Vector3.new(0, 0, -75), Vector3.new(70, 0, -45)}) do
    local nest = Instance.new("Model")
    nest.Name = "Nest" .. index
    nest.Parent = nests
    -- Small blocks make a hollow ring. CFrame rotates each block around Y.
    for segment = 0, 23 do
        local angle = segment * math.pi * 2 / 24
        local offset = Vector3.new(math.cos(angle) * 12, 0.75, math.sin(angle) * 12)
        local rim = part("Rim", Vector3.new(3.5, 1.5, 3.5), position + offset, Color3.fromRGB(160, 112, 58), nest)
        rim.CFrame = CFrame.new(position + offset) * CFrame.Angles(0, -angle, 0)
    end
end
map.Parent = workspace

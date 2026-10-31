-- Roblox Luau: ServerScriptService > Grassland.
-- Six open fenced grass pens. Inventory handles roaming and passive income.
if workspace:FindFirstChild("SlimeMap") then return end
local map = Instance.new("Model")
map.Name = "SlimeMap"
local V = Vector3.new
local C = Color3.fromRGB
local palette = {
    grass = C(102, 180, 72), stone = C(130, 166, 100), trim = C(230, 207, 162),
    dark = C(78, 100, 53), wood = C(157, 111, 65), path = C(112, 187, 79),
}

-- One helper handles every anchored building block.
local function part(name, size, position, color, parent, material)
    local p = Instance.new("Part")
    p.Name, p.Size, p.Position = name, size, position
    p.Color = color
    p.Anchored = true
    p.Material = material or Enum.Material.SmoothPlastic
    p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end
local function model(name, parent)
    local m = Instance.new("Model")
    m.Name, m.Parent = name, parent
    return m
end
local function sign(text, size, position, color, parent)
    local board = part("Sign", size, position, color, parent)
    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Back -- Visible while walking north from the plaza.
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 35
    gui.Parent = board
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = palette.trim
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.Parent = gui
    return board
end
local function cylinder(name, radius, height, position, color, parent)
    local p = part(name, V(height, radius * 2, radius * 2), position, color, parent)
    p.Shape = Enum.PartType.Cylinder
    p.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
    return p
end
-- 1. A narrow corridor joins the wider ranch plaza.
-- Separate floors remove the unused strips outside the tunnel walls.
part("Grassland", V(102, 2, 610), V(0, -1, -180), palette.grass, map, Enum.Material.Grass)
part("PlazaGround", V(192, 2, 130), V(0, -1, 190), palette.grass, map, Enum.Material.Grass)
local walls = model("BoundaryWalls", map)
for _, x in ipairs({-96, 96}) do
    part("EdgeWall", V(4, 40, 130), V(x, 20, 190), palette.stone, walls)
    part("WallCap", V(5, 1, 130), V(x, 40.5, 190), palette.trim, walls)
    for z = 135, 255, 40 do
        part("Buttress", V(6, 42, 6), V(x, 21, z), palette.dark, walls)
    end
end
-- Shoulders close the sides where the plaza meets the corridor.
for _, x in ipairs({-73, 73}) do
    part("PlazaShoulder", V(46, 40, 3), V(x, 20, 125), palette.stone, walls)
    part("ShoulderCap", V(46, 1, 4), V(x, 40.5, 125), palette.trim, walls)
end
part("NorthEndWall", V(102, 40, 4), V(0, 20, -485), palette.stone, walls)
part("NorthEndCap", V(102, 1, 5), V(0, 40.5, -485), palette.trim, walls)
part("SouthEndWall", V(192, 40, 4), V(0, 20, 255), palette.stone, walls)
part("SouthEndCap", V(192, 1, 5), V(0, 40.5, 255), palette.trim, walls)

-- 2. An open-air corridor with tall walls and wall-mounted lights.
part("Plaza", V(172, 0.2, 122), V(0, 0.1, 190), palette.path, map, Enum.Material.Grass)
local tunnel = model("NurseryTunnel", map)
part("MainPath", V(22, 0.18, 616), V(0, 0.09, -175), palette.path, tunnel, Enum.Material.Grass)
for _, x in ipairs({-12, 12}) do
    part("PathEdging", V(1, 0.24, 616), V(x, 0.12, -175), C(78, 150, 59), tunnel, Enum.Material.Grass)
end
for _, x in ipairs({-49, 49}) do
    part("TunnelWall", V(3, 40, 604), V(x, 20, -177), palette.stone, tunnel)
    part("WallBase", V(4, 2, 604), V(x, 1, -177), palette.dark, tunnel)
    part("CorridorWallCap", V(4, 1, 604), V(x, 40.5, -177), palette.trim, tunnel)
end
for z = -450, 100, 55 do
    for _, x in ipairs({-47, 47}) do
        part("WallColumn", V(4, 42, 5), V(x, 21, z), palette.dark, tunnel)
        part("ColumnFoot", V(6, 2, 7), V(x, 1, z), palette.trim, tunnel)
    end
    for _, x in ipairs({-45, 45}) do
        local lamp = part("WallLight", V(0.5, 3, 2), V(x, 12, z), C(255, 235, 170), tunnel, Enum.Material.Neon)
        local light = Instance.new("PointLight")
        light.Color, light.Brightness, light.Range = C(255, 235, 190), 0.65, 28
        light.Parent = lamp
    end
end
-- Collection replaces the old overhead entrance sign.
local collectZone = model("CollectZone", map)
local pad = part("CollectionPad", V(95, 0.15, 4), V(0, 0.32, 126), C(158, 219, 166), collectZone)
for _, z in ipairs({124.125, 127.875}) do
    part("CollectionBorder", V(95, 0.2, 0.25), V(0, 0.45, z), C(205, 255, 211), collectZone, Enum.Material.Neon)
end
for _, x in ipairs({-47.375, 47.375}) do
    part("CollectionBorder", V(0.25, 0.2, 4), V(x, 0.45, 126), C(205, 255, 211), collectZone, Enum.Material.Neon)
end
local floorGui = Instance.new("SurfaceGui")
floorGui.Face, floorGui.SizingMode = Enum.NormalId.Top, Enum.SurfaceGuiSizingMode.PixelsPerStud
floorGui.PixelsPerStud, floorGui.Parent = 30, pad
local floorLabel = Instance.new("TextLabel")
floorLabel.Size = UDim2.fromScale(1, 1)
floorLabel.BackgroundTransparency = 1
floorLabel.Text, floorLabel.TextColor3 = "COLLECT ZONE", C(37, 81, 51)
floorLabel.Font, floorLabel.TextScaled = Enum.Font.GothamBold, true
floorLabel.Parent = floorGui
-- An invisible volume detects the player's position, not the carried body's.
local trigger = part("CollectionTrigger", V(95, 12, 4), V(0, 6, 126), C(255, 255, 255), collectZone)
trigger.Transparency, trigger.CanCollide, trigger.CanTouch, trigger.CanQuery = 1, false, false, false
sign("STEAL A SLIME", V(48, 7, 1), V(0, 16, 248), palette.dark, map)

-- 3. Six open grass pens: three on either side of the center lane.
local bases = model("Bases", map)
local fenceColor = C(175, 126, 74)
local railColor = C(202, 157, 99)
local function fenceRail(position, size, parent)
    for _, height in ipairs({1.4, 3}) do
        part("FenceRail", size, position + V(0, height, 0), railColor, parent, Enum.Material.Wood)
    end
end
local function fencePost(position, parent)
    part("FencePost", V(1.2, 4.3, 1.2), position + V(0, 2.15, 0), fenceColor, parent, Enum.Material.Wood)
    part("PostCap", V(1.5, 0.3, 1.5), position + V(0, 4.45, 0), palette.trim, parent, Enum.Material.Wood)
end
for row, z in ipairs({156, 194, 232}) do
    for sideIndex, side in ipairs({-1, 1}) do
        local index = (row - 1) * 2 + sideIndex
        local x = side * 55
        local base = model("Base" .. index, bases)
        base:SetAttribute("BaseIndex", index)
        base:SetAttribute("EntrancePosition", V(side * 22, 0, z))
        part("PenGrass", V(66, 0.12, 30), V(x, 0.06, z), C(117, 192, 83), base, Enum.Material.Grass)
        -- Long fences at the north and south edges of each pen.
        for _, dz in ipairs({-15, 15}) do
            fenceRail(V(x, 0, z + dz), V(66, 0.45, 0.6), base)
            for dx = -33, 33, 11 do
                fencePost(V(x + dx, 0, z + dz), base)
            end
        end
        -- Back fence and two short front sections leave a 12-stud entrance.
        local backX, frontX = side * 88, side * 22
        fenceRail(V(backX, 0, z), V(0.6, 0.45, 30), base)
        fencePost(V(backX, 0, z), base)
        for _, dz in ipairs({-10.5, 10.5}) do
            fenceRail(V(frontX, 0, z + dz), V(0.6, 0.45, 9), base)
        end
        fencePost(V(frontX, 0, z - 6), base)
        fencePost(V(frontX, 0, z + 6), base)
        local board = sign("BASE 0" .. index, V(8, 2.2, 0.5), V(frontX, 4, z - 10.5), palette.wood, base)
        board.CFrame = CFrame.new(board.Position) * CFrame.Angles(0, -side * math.pi / 2, 0)
        -- These are reserved spots; placement and income are later features.
        -- A shared pen replaces individual collection/display pads.
        base:SetAttribute("PenCapacity", 6)

    end
end

-- 4. Nursery bays leave the center lane clear.
local nests = model("Nests", map)
local nurseryPositions = {V(-27, 0, 45), V(27, 0, -65), V(-27, 0, -175), V(27, 0, -285), V(-27, 0, -395)}
local nurseryColors = {C(157, 196, 104), C(114, 184, 196), C(172, 150, 207), C(226, 183, 102), C(214, 137, 131)}
for index, center in ipairs(nurseryPositions) do
    local nest = model("Nest" .. index, nests)
    nest:SetAttribute("SpawnCenter", center + V(0, 0.7, 0))
    nest:SetAttribute("Zone", index)
    local accent = nurseryColors[index]
    sign("ZONE 0" .. index, V(22, 3, 0.6), V(-35, 12, center.Z + 35), palette.dark, tunnel)
    part("ZoneSignPost", V(1, 12, 1), V(-35, 6, center.Z + 35), accent, tunnel)
    cylinder("StonePlinth", 15, 0.5, center + V(0, 0.25, 0), palette.trim, nest)
    cylinder("SoftBed", 12, 0.2, center + V(0, 0.6, 0), accent, nest)
    for segment = 0, 31 do
        local angle = segment * math.pi * 2 / 32
        local position = center + V(math.cos(angle) * 13, 0.9, math.sin(angle) * 13)
        local rim = part("NestRim", V(2.8, 0.8, 2.8), position, palette.wood, nest)
        rim.CFrame = CFrame.new(position) * CFrame.Angles(0, -angle, 0)
    end
    for _, dx in ipairs({-11, 11}) do
        part("CanopyPost", V(1, 9, 1), center + V(dx, 4.5, -9), palette.wood, nest)
    end
    part("Canopy", V(28, 1, 8), center + V(0, 9, -10), accent, nest)
    sign("NURSERY 0" .. index, V(22, 2.5, 0.5), center + V(0, 7, -8), palette.dark, nest)
    -- A short side path connects each bay to the main walkway.
    part("NurseryApproach", V(12, 0.15, 7), V(center.X / 2, 0.075, center.Z), palette.path, tunnel, Enum.Material.Grass)
end

-- The existing spawn is reused so a second spawn is never created.
local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation")
if spawn then
    spawn.CFrame = CFrame.new(0, 0.6, 229)
    spawn.Size = V(10, 1, 10)
    spawn.Transparency = 1
    spawn.CanCollide = false
    spawn.Neutral = true
    for _, decoration in ipairs(spawn:GetChildren()) do
        if decoration:IsA("Decal") or decoration:IsA("Texture") then
            decoration.Transparency = 1
        end
    end
end
map:SetAttribute("MapVersion", "SixGrassPens")
map.Parent = workspace

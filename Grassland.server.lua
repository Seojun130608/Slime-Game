-- Roblox Luau: ServerScriptService > Grassland.
-- Map appearance only. Safe-zone and display-slot gameplay come later.
if workspace:FindFirstChild("SlimeMap") then return end
local map = Instance.new("Model")
map.Name = "SlimeMap"
local V = Vector3.new
local C = Color3.fromRGB
local palette = {
    grass = C(109, 164, 86), stone = C(213, 219, 194), trim = C(245, 235, 205),
    dark = C(57, 82, 65), wood = C(145, 107, 74), path = C(224, 209, 169),
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
local function shrub(position, parent)
    part("Planter", V(7, 1.3, 7), position + V(0, 0.65, 0), palette.trim, parent)
    local leaves = part("Shrub", V(6, 5, 6), position + V(0, 3.1, 0), C(75, 133, 76), parent, Enum.Material.Grass)
    leaves.Shape = Enum.PartType.Ball
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
part("Plaza", V(172, 0.2, 122), V(0, 0.1, 190), palette.path, map)
local tunnel = model("NurseryTunnel", map)
part("MainPath", V(22, 0.18, 616), V(0, 0.09, -175), palette.path, tunnel)
for _, x in ipairs({-12, 12}) do
    part("PathEdging", V(1, 0.24, 616), V(x, 0.12, -175), palette.trim, tunnel)
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
sign("SLIME NURSERIES", V(44, 5, 1), V(0, 18, 126), palette.dark, tunnel)
for _, x in ipairs({-25, 25}) do
    part("GatewayPost", V(4, 21, 5), V(x, 10.5, 126), palette.dark, tunnel)
end
sign("STEAL A SLIME", V(48, 7, 1), V(0, 16, 248), palette.dark, map)

-- 3. Two ranch bases with shelter, fences, and decorative display pads.
local bases = model("Bases", map)
for index, x in ipairs({-52, 52}) do
    local base = model("Base" .. index, bases)
    local accent = index == 1 and C(87, 148, 134) or C(112, 128, 178)
    part("Foundation", V(62, 1, 64), V(x, 0.5, 183), palette.trim, base)
    part("Deck", V(58, 0.18, 60), V(x, 1.09, 183), C(192, 163, 119), base, Enum.Material.WoodPlanks)
    -- Low entry steps can be walked up without jumping.
    part("Step", V(24, 0.5, 4), V(x, 0.25, 149), palette.trim, base)
    part("SafeZoneBorder", V(58, 0.12, 1), V(x, 1.24, 152), C(181, 238, 197), base, Enum.Material.Neon)
    for _, dx in ipairs({-27, 27}) do
        for _, z in ipairs({190, 211}) do
            part("ShelterPost", V(1.5, 13, 1.5), V(x + dx, 7.5, z), palette.wood, base)
        end
        part("FenceRail", V(1, 1, 56), V(x + dx, 3, 183), palette.trim, base)
        for z = 157, 209, 13 do
            part("FencePost", V(1.6, 4, 1.6), V(x + dx, 3, z), palette.wood, base)
        end
    end
    part("BackWall", V(56, 5, 1.5), V(x, 3.5, 212), accent, base)
    for _, side in ipairs({-1, 1}) do
        local roof = part("PitchedRoof", V(31, 1, 28), V(x + side * 14.5, 15, 200), accent, base)
        roof.CFrame = CFrame.new(roof.Position) * CFrame.Angles(0, 0, math.rad(-side * 12))
    end
    sign("RANCH " .. index .. "  |  SAFE ZONE", V(40, 3, 0.6), V(x, 11, 214), palette.dark, base)
    for _, dx in ipairs({-14, 14}) do
        for _, z in ipairs({170, 192}) do
            cylinder("DisplayPad", 5, 0.3, V(x + dx, 1.4, z), palette.trim, base)
            cylinder("PadInset", 4.3, 0.1, V(x + dx, 1.6, z), accent, base)
        end
    end
    shrub(V(x - 24, 0, 145), base)
    shrub(V(x + 24, 0, 145), base)
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
    part("NurseryApproach", V(12, 0.15, 7), V(center.X / 2, 0.075, center.Z), palette.path, tunnel)
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
map:SetAttribute("MapVersion", "OpenSkyFiveZoneCorridor")
map.Parent = workspace

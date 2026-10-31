-- Roblox Luau: ServerScriptService > Guardians.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local capture = script.Parent:WaitForChild("Capture")
local captured = capture:WaitForChild("SlimeCaptured")
local secured = capture:WaitForChild("SlimeSecured")
local released = capture:WaitForChild("SlimeReleased")
local caught = capture:WaitForChild("ParentCaught")
local map = workspace:WaitForChild("SlimeMap")
local slimes = map:WaitForChild("WildSlimes")
local trigger = map:WaitForChild("CollectZone"):WaitForChild("CollectionTrigger")
local safeZ = trigger.Position.Z - trigger.Size.Z / 2
local SPEED, GRACE, CATCH_DISTANCE = 14, 1.5, 6
local V = Vector3.new
local records = {}
local parents = Instance.new("Folder")
parents.Name, parents.Parent = "Guardians", map

-- PIECE 1: build a large parent with the baby's color and angry eyebrows.
local function part(name, size, color, frame, parent, ball)
    local p = Instance.new("Part")
    p.Name, p.Size, p.Color, p.CFrame = name, size, color, frame
    p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery = true, false, false, false
    p.Material = Enum.Material.SmoothPlastic
    if ball then p.Shape = Enum.PartType.Ball end
    p.Parent = parent
    return p
end
local function register(slime)
    if records[slime] then return records[slime] end
    if not slime:IsA("Model") then return end
    slime:WaitForChild("Mouth")
    local body = slime.PrimaryPart
    if not body then return end
    local nest = map.Nests:FindFirstChild("Nest" .. tostring(slime:GetAttribute("NestIndex")))
    if not nest then return end
    local center = nest:GetAttribute("SpawnCenter")
    local side = body.Position.X < center.X and -1 or 1
    local home = V(center.X + side * 9, 0, center.Z - 24)
    local model = Instance.new("Model")
    model.Name = slime:GetAttribute("SlimeType") .. "Parent"
    model:SetAttribute("SlimeType", slime:GetAttribute("SlimeType"))
    model:SetAttribute("State", "Idle")
    local root = part("Root", V(1, 1, 1), body.Color, CFrame.new(home), model)
    root.Transparency = 1
    model.PrimaryPart = root
    local skin = part("Body", V(14, 12, 14), body.Color, CFrame.new(home + V(0, 4.2, 0)), model, true)
    skin.Transparency = 0.06
    local black = Color3.fromRGB(25, 30, 24)
    for _, x in ipairs({-2.3, 2.3}) do
        part("Eye", V(0.9, 1.2, 0.45), black, CFrame.new(home + V(x, 5.5, -6.3)), model, true)
        part("AngryBrow", V(2.5, 0.5, 0.45), black,
            CFrame.new(home + V(x, 6.5, -6)) * CFrame.Angles(0, 0, math.rad(x < 0 and -25 or 25)), model)
    end
    part("Mouth", V(2.3, 0.55, 0.4), black, CFrame.new(home + V(0, 3.6, -6.9)), model, true)
    model.Parent = parents
    local record = {
        slime = slime, model = model, home = home, position = home,
        rotation = CFrame.Angles(0, math.pi, 0), phase = 0,
        revision = 0, nextPath = 0, waypoints = {}, waypoint = 1,
    }
    records[slime] = record
    model:PivotTo(CFrame.new(home) * record.rotation)
    return record
end

-- PIECE 2: capture starts a chase; collection, release, or leaving ends it.
local function stop(record)
    local player = record.target
    if player and player:GetAttribute("ChasedBy") == record.model.Name then
        player:SetAttribute("ChasedBy", nil)
    end
    record.target, record.character = nil, nil
    record.revision = record.revision + 1
    record.waypoints, record.waypoint, record.nextPath = {}, 1, 0
    record.model:SetAttribute("State", "Returning")
    record.model:SetAttribute("TargetUserId", nil)
end
captured.Event:Connect(function(player, slime)
    local record = records[slime] or register(slime)
    if not record then return end
    if record.target then stop(record) end
    record.target, record.character = player, player.Character
    record.wakeAt = os.clock() + GRACE
    record.revision = record.revision + 1
    record.waypoints, record.waypoint, record.nextPath = {}, 1, 0
    record.model:SetAttribute("State", "Chasing")
    record.model:SetAttribute("TargetUserId", player.UserId)
    player:SetAttribute("ChasedBy", record.model.Name)
end)
local function endChase(_, slime)
    local record = records[slime]
    if record then stop(record) end
end
secured.Event:Connect(endChase)
released.Event:Connect(endChase)
Players.PlayerRemoving:Connect(function(player)
    for _, record in pairs(records) do
        if record.target == player then stop(record) end
    end
end)

-- PIECE 3: request paths without blocking the frame update.
-- A revision number prevents an old path from replacing a newer chase.
local obstacles = RaycastParams.new()
obstacles.FilterType = Enum.RaycastFilterType.Include
obstacles.FilterDescendantsInstances = {map.NurseryTunnel, map.Nests, map.BoundaryWalls}
local function clearStep(position, delta)
    for _, height in ipairs({3, 9}) do
        if workspace:Raycast(position + V(0, height, 0), delta, obstacles) then return false end
    end
    return true
end
local function requestPath(record, goal, now)
    if record.pathBusy or now < record.nextPath then return end
    record.pathBusy, record.nextPath = true, now + 1
    local revision, start = record.revision, record.position
    task.spawn(function()
        local path = PathfindingService:CreatePath({AgentRadius = 7, AgentHeight = 11, AgentCanJump = false, WaypointSpacing = 5})
        local ok = pcall(function() path:ComputeAsync(start + V(0, 2, 0), goal + V(0, 2, 0)) end)
        record.pathBusy = false
        if record.revision ~= revision then return end
        if ok and path.Status == Enum.PathStatus.Success then
            local waypoints = path:GetWaypoints()
            local leavesCorridor = false
            for _, waypoint in ipairs(waypoints) do
                if math.abs(waypoint.Position.X) > 40 or waypoint.Position.Z > safeZ - 7 then
                    leavesCorridor = true
                    break
                end
            end
            -- The wide center lane gives large parents room around nursery roofs.
            if leavesCorridor then
                record.waypoints, record.waypoint = {{Position = V(0, 0, start.Z)}}, 1
            else
                record.waypoints, record.waypoint = waypoints, 2
            end
        else
            record.waypoints, record.waypoint = {}, 1
        end
    end)
end
local function tick(record, dt, now)
    local goal
    if record.target then
        local player, character = record.target, record.character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not player.Parent or player.Character ~= character or not root or not humanoid or humanoid.Health <= 0
            or player:GetAttribute("CarryingSlime") ~= record.slime.Name or root.Position.Z >= safeZ then
            stop(record)
        elseif now >= record.wakeAt then
            local delta = root.Position - record.position
            local horizontal = V(delta.X, 0, delta.Z)
            if horizontal.Magnitude <= CATCH_DISTANCE and math.abs(delta.Y) < 12 then
                -- Check the line of sight before catching through an obstacle.
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = {character, parents, record.slime}
                if not workspace:Raycast(record.position + V(0, 4, 0), root.Position - (record.position + V(0, 4, 0)), params) then
                    caught:Fire(player, record.slime)
                    stop(record)
                else
                    goal = V(math.clamp(root.Position.X, -39, 39), 0, math.min(root.Position.Z, safeZ - 7))
                end
            else
                goal = V(math.clamp(root.Position.X, -39, 39), 0, math.min(root.Position.Z, safeZ - 7))
            end
        end
    end
    if not record.target and record.model:GetAttribute("State") == "Returning" then
        if (record.position - record.home).Magnitude < 1.1 then
            record.position = record.home
            record.model:SetAttribute("State", "Idle")
        else
            goal = record.home
        end
    end
    local moved = false
    if goal then
        requestPath(record, goal, now)
        local waypoint = record.waypoints[record.waypoint]
        local destination = waypoint and V(waypoint.Position.X, 0, waypoint.Position.Z) or goal
        local delta = destination - record.position
        if delta.Magnitude < 1 then
            record.waypoint = record.waypoint + 1
        else
            local step = delta.Unit * math.min(delta.Magnitude, SPEED * math.min(dt, 0.1))
            local nextPosition = record.position + step
            if nextPosition.Z <= safeZ - 7 and math.abs(nextPosition.X) <= 40 and clearStep(record.position, step) then
                record.position = nextPosition
                record.rotation = record.rotation:Lerp(CFrame.lookAt(V(0, 0, 0), delta.Unit), math.min(1, dt * 8))
                moved = true
            else
                record.nextPath = 0
            end
        end
    end
    record.phase = record.phase + dt * (moved and 8 or 2)
    local bounce = math.abs(math.sin(record.phase)) * (moved and 0.7 or 0.08)
    record.model:PivotTo(CFrame.new(record.position + V(0, bounce, 0)) * record.rotation)
end
slimes.ChildAdded:Connect(function(slime) task.spawn(register, slime) end)
for _, slime in ipairs(slimes:GetChildren()) do task.spawn(register, slime) end
RunService.Heartbeat:Connect(function(dt)
    local now = os.clock()
    for _, record in pairs(records) do tick(record, dt, now) end
end)
print("Guardians ready: giant parents chase captured babies and stop at the collect zone.")

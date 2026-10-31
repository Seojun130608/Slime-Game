-- Roblox Luau: ServerScriptService > Capture.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterPack = game:GetService("StarterPack")
local ServerStorage = game:GetService("ServerStorage")
local CombatRules = require(script.Parent:WaitForChild("CombatRules"))
local UpgradeRules = require(script.Parent:WaitForChild("UpgradeRules"))
local secured = Instance.new("Folder")
secured.Name, secured.Parent = "SecuredSlimes", ServerStorage
local collectionTrigger
local HOLD_SECONDS, REACH = 2, 10
local random = Random.new()
local states, attempts, carrying, messageVersions = {}, {}, {}, {}
local function movement(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    local record = carrying[player]
    local speedLevel, grabberLevel = player:GetAttribute("SpeedLevel") or 0, player:GetAttribute("GrabberLevel") or 0
    if CombatRules.IsStunned(player) then
        humanoid.WalkSpeed = 0
    elseif record then
        humanoid.WalkSpeed = UpgradeRules.CarrySpeed(speedLevel, grabberLevel, record.state.weight, player:GetAttribute("GrabberPower") or 10)
    else
        humanoid.WalkSpeed = UpgradeRules.Speed(speedLevel)
    end
end
local refreshMovement = Instance.new("BindableFunction")
refreshMovement.Name, refreshMovement.OnInvoke = "RefreshMovement", movement
refreshMovement.Parent = script

-- PIECE 1: build the grabber and give each player clear instructions.
local function piece(name, size, color, parent)
    local p = Instance.new("Part")
    p.Name, p.Size, p.Color = name, size, color
    p.Material = Enum.Material.SmoothPlastic
    p.CanCollide, p.Massless = false, true
    p.Parent = parent
    return p
end
local tool = Instance.new("Tool")
tool.Name, tool.CanBeDropped = "Slime Grabber", false
local handle = piece("Handle", Vector3.new(1, 1, 2), Color3.fromRGB(65, 106, 94), tool)
local nozzle = piece("Nozzle", Vector3.new(1.4, 1.4, 0.6), Color3.fromRGB(190, 240, 205), tool)
nozzle.CFrame = handle.CFrame * CFrame.new(0, 0, -1.2)
local joint = Instance.new("WeldConstraint")
joint.Part0, joint.Part1, joint.Parent = handle, nozzle, handle
local tip = Instance.new("Attachment")
tip.Name, tip.Position, tip.Parent = "TetherTip", Vector3.new(0, 0, -1.6), handle
tool.Parent = StarterPack

local function hint(player, text)
    local gui = player:FindFirstChild("PlayerGui")
    gui = gui and gui:FindFirstChild("CaptureHint")
    if gui then gui.Message.Text = text end
end
local function defaultHint(player)
    if carrying[player] then
        if player:GetAttribute("ChasedBy") then
            return "GIANT PARENT CHASING! Reach the green COLLECT ZONE!  |  Q: drop baby"
        end
        return "Carry this baby to the green COLLECT ZONE to secure it.  |  Q: drop baby"
    end
    return "Collected: " .. (player:GetAttribute("CollectedSlimes") or 0) .. "  |  Equip Slime Grabber [1] and hold E near a baby"
end
local function message(player, text)
    local version = (messageVersions[player] or 0) + 1
    messageVersions[player] = version
    hint(player, text)
    task.delay(4, function()
        if player.Parent and messageVersions[player] == version then
            hint(player, defaultHint(player))
        end
    end)
end
local function setupCharacter(player, character)
    local backpack = player:WaitForChild("Backpack")
    if not backpack:FindFirstChild(tool.Name) and not character:FindFirstChild(tool.Name) then
        tool:Clone().Parent = backpack
    end
    local playerGui = player:WaitForChild("PlayerGui")
    if not playerGui:FindFirstChild("CaptureHint") then
        local gui = Instance.new("ScreenGui")
        gui.Name, gui.ResetOnSpawn = "CaptureHint", false
        local label = Instance.new("TextLabel")
        label.Name = "Message"
        label.AnchorPoint = Vector2.new(0.5, 1)
        label.Position, label.Size = UDim2.new(0.5, 0, 1, -85), UDim2.new(0.8, 0, 0, 54)
        label.BackgroundColor3 = Color3.fromRGB(35, 55, 46)
        label.BackgroundTransparency = 0.15
        label.TextColor3 = Color3.fromRGB(245, 240, 220)
        label.Font, label.TextSize, label.TextWrapped = Enum.Font.GothamMedium, 17, true
        label.Parent, gui.Parent = gui, playerGui
    end
    hint(player, defaultHint(player))
    character:WaitForChild("Humanoid")
    movement(player)
end

-- PIECE 2: the server checks equipment, range, timing, power, and ownership.
-- Weights live only in this server table, never as visible model attributes.
local function power(player)
    local value = player:GetAttribute("GrabberPower")
    if type(value) ~= "number" or value ~= value then return 10 end
    return math.clamp(value, 0, 1000000)
end
local function eligible(player, state)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local equipped = character and character:FindFirstChild("Slime Grabber")
    if not root or not humanoid or humanoid.Health <= 0 then return false end
    if not equipped or not equipped:IsA("Tool") then return false end
    if CombatRules.IsStunned(player) then return false end
    if carrying[player] or state.slime:GetAttribute("Captured") then return false end
    if state.owner and state.owner ~= player then return false end
    if not state.slime.PrimaryPart or not state.slime:IsDescendantOf(workspace) then return false end
    if (root.Position - state.slime.PrimaryPart.Position).Magnitude > REACH then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    -- Avatars and cosmetic accessories must not block collecting a nearby baby.
    local exclusions = {state.slime}
    for _, other in ipairs(Players:GetPlayers()) do
        if other.Character then table.insert(exclusions, other.Character) end
    end
    params.FilterDescendantsInstances = exclusions
    local origin = root.Position + Vector3.new(0, 1, 0)
    if workspace:Raycast(origin, state.slime.PrimaryPart.Position - origin, params) then return false end
    return true, root, humanoid, equipped
end
local function cancel(player)
    local state = attempts[player]
    if not state then return end
    attempts[player] = nil
    state.owner, state.started, state.released = nil, nil, nil
    if state.beam then state.beam:Destroy(); state.beam = nil end
end
local function begin(player, state)
    if not eligible(player, state) then
        message(player, "Equip your grabber, move closer, and carry only one baby at a time.")
        return
    end
    cancel(player)
    state.weight = state.weight or random:NextInteger(1, 20)
    if state.weight > power(player) then
        message(player, "This baby needs more Grabber Power. Try another slime.")
        return
    end
    local _, _, _, equipped = eligible(player, state)
    state.owner, state.started, state.released = player, os.clock(), nil
    state.holdSeconds = UpgradeRules.HoldSeconds(player:GetAttribute("GrabberLevel") or 0)
    attempts[player] = state
    local beam = Instance.new("Beam")
    beam.Attachment0 = equipped.Handle.TetherTip
    beam.Attachment1 = state.attachment
    beam.Width0, beam.Width1, beam.FaceCamera = 0.15, 0.1, true
    beam.Color = ColorSequence.new(Color3.fromRGB(190, 245, 205))
    beam.Parent, state.beam = state.slime.PrimaryPart, beam
    message(player, "Keep holding E to pull this baby free...")
end

-- PIECE 3: weld a successful capture to the character and apply slowdown.
-- Future chase code can listen to this server-only event.
local captured = Instance.new("BindableEvent")
captured.Name, captured.Parent = "SlimeCaptured", script
local released = Instance.new("BindableEvent")
released.Name, released.Parent = "SlimeReleased", script
local function release(player, dropFrame)
    cancel(player)
    local record = carrying[player]
    if not record then return end
    carrying[player] = nil
    for _, weld in ipairs(record.welds) do weld:Destroy() end
    for _, p in ipairs(record.state.slime:GetDescendants()) do
        if p:IsA("BasePart") then p.Anchored = true end
    end
    local state = record.state
    state.dropVersion = (state.dropVersion or 0) + 1
    state.dropped = dropFrame ~= nil
    state.dropExpires = state.dropped and (os.clock() + CombatRules.DropLifetime) or nil
    state.prompt.HoldDuration = state.dropped and 0 or HOLD_SECONDS
    state.prompt.ActionText = state.dropped and "Pick up dropped baby" or "Pull with grabber"
    record.state.slime:PivotTo(dropFrame or record.state.home)
    record.state.slime:SetAttribute("Captured", false)
    record.state.slime:SetAttribute("CarrierUserId", nil)
    record.state.prompt.Enabled = true
    if record.humanoid.Parent then record.humanoid.WalkSpeed = UpgradeRules.Speed(player:GetAttribute("SpeedLevel") or 0) end
    player:SetAttribute("CarryingSlime", nil)
    released:Fire(player, record.state.slime)
end
local caught = Instance.new("BindableEvent")
caught.Name, caught.Parent = "ParentCaught", script
caught.Event:Connect(function(player, slime)
    local record = carrying[player]
    if record and record.state.slime == slime then
        release(player)
        message(player, "The parent caught you! The baby returned to its nursery.")
    end
end)
local function finish(player, state)
    if state.dropped then
        if state.dropExpires and os.clock() >= state.dropExpires then return end
    else
        if attempts[player] ~= state or state.owner ~= player then return end
        local elapsed = (state.released or os.clock()) - state.started
        if elapsed < state.holdSeconds - 0.08 then cancel(player); return end
    end
    local valid, root, humanoid = eligible(player, state)

    if not valid or state.weight > power(player) then cancel(player); return end
    cancel(player)
    local slime, body = state.slime, state.slime.PrimaryPart
    state.dropped, state.dropExpires = false, nil
    state.dropVersion = (state.dropVersion or 0) + 1
    state.prompt.HoldDuration, state.prompt.ActionText = HOLD_SECONDS, "Pull with grabber"
    state.prompt.Enabled = false
    slime:SetAttribute("Captured", true)
    slime:SetAttribute("CarrierUserId", player.UserId)
    player:SetAttribute("CarryingSlime", slime.Name)
    slime:PivotTo(root.CFrame * CFrame.new(2.5, 1, -3))
    local welds = {}
    for _, p in ipairs(slime:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Anchored, p.CanCollide, p.Massless = false, false, true
            if p ~= body then
                local weld = Instance.new("WeldConstraint")
                weld.Part0, weld.Part1, weld.Parent = body, p, body
                table.insert(welds, weld)
            end
        end
    end
    local grip = Instance.new("WeldConstraint")
    grip.Part0, grip.Part1, grip.Parent = root, body, body
    table.insert(welds, grip)
    local speed = humanoid.WalkSpeed
    carrying[player] = {state = state, humanoid = humanoid, speed = speed, welds = welds}
    movement(player)
    message(player, "Captured " .. slime:GetAttribute("SlimeType") .. "! Run to the COLLECT ZONE before its parent catches you.")
    captured:Fire(player, slime, state.weight)
end

-- Collection stores secured babies privately for this session.
-- The later inventory feature can read these models and their hidden weights.
local slimeSecured = Instance.new("BindableEvent")
slimeSecured.Name, slimeSecured.Parent = "SlimeSecured", script
local function collect(player, record)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or record.humanoid.Health <= 0 or not collectionTrigger then return end
    local position = collectionTrigger.CFrame:PointToObjectSpace(root.Position)
    local half = collectionTrigger.Size / 2
    if math.abs(position.X) > half.X or math.abs(position.Y) > half.Y or math.abs(position.Z) > half.Z then return end
    local folder = secured:FindFirstChild(tostring(player.UserId))
    if not folder then return end
    -- Clear carrying first, so repeated frames cannot award the same baby twice.
    carrying[player] = nil
    for _, weld in ipairs(record.welds) do weld:Destroy() end
    local slime = record.state.slime
    for _, item in ipairs(slime:GetDescendants()) do
        if item:IsA("BasePart") then item.Anchored = true end
    end
    slime.Parent = folder -- ServerStorage does not replicate to players.
    slime:SetAttribute("Weight", record.state.weight)
    slime:SetAttribute("Secured", true)
    slime:SetAttribute("CarrierUserId", nil)
    record.humanoid.WalkSpeed = UpgradeRules.Speed(player:GetAttribute("SpeedLevel") or 0)
    player:SetAttribute("CarryingSlime", nil)
    player:SetAttribute("CollectedSlimes", #folder:GetChildren())
    states[slime] = nil
    message(player, "Secured " .. slime:GetAttribute("SlimeType") .. " baby! Collected: " .. #folder:GetChildren())
    slimeSecured:Fire(player, slime, record.state.weight)
end

local function setupPlayer(player)
    local folder = Instance.new("Folder")
    folder.Name, folder.Parent = tostring(player.UserId), secured
    player:SetAttribute("CollectedSlimes", 0)
    if player:GetAttribute("GrabberPower") == nil then player:SetAttribute("GrabberPower", 10) end
    for _, attribute in ipairs({"SpeedLevel", "GrabberLevel", "GrabberPower"}) do
        player:GetAttributeChangedSignal(attribute):Connect(function() movement(player) end)
    end
    player.CharacterRemoving:Connect(function() release(player) end)
    player.CharacterAdded:Connect(function(character)
        setupCharacter(player, character)
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.Died:Connect(function() release(player) end)
    end)
    if player.Character then
        local character = player.Character
        task.spawn(function()
            setupCharacter(player, character)
            character:WaitForChild("Humanoid").Died:Connect(function() release(player) end)
        end)
    end
end
Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
    release(player)
    messageVersions[player] = nil
    local folder = secured:FindFirstChild(tostring(player.UserId))
    if folder then folder:Destroy() end
end)
for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end

RunService.Heartbeat:Connect(function()
    for player, state in pairs(attempts) do
        if not eligible(player, state) or (state.released and os.clock() - state.released > 0.2) then
            cancel(player)
        end
    end
    for player, record in pairs(carrying) do collect(player, record) end
    local now = os.clock()
    for _, state in pairs(states) do
        if state.dropped and state.dropExpires and now >= state.dropExpires then
            cancel(state.owner)
            state.dropped, state.dropExpires = false, nil
            state.prompt.Enabled = true
            state.prompt.HoldDuration, state.prompt.ActionText = HOLD_SECONDS, "Pull with grabber"
            state.slime:PivotTo(state.home)
        end
    end
end)
local slimes = workspace:WaitForChild("SlimeMap"):WaitForChild("WildSlimes")
collectionTrigger = slimes.Parent:WaitForChild("CollectZone"):WaitForChild("CollectionTrigger")
local function register(slime)
    if not slime:IsA("Model") or states[slime] then return end
    slime:WaitForChild("Mouth") -- The spawner creates the mouth last.
    local body = slime.PrimaryPart
    if not body then return end
    local attachment = Instance.new("Attachment")
    attachment.Parent = body
    local prompt = Instance.new("ProximityPrompt")
    prompt.Name, prompt.ObjectText, prompt.ActionText = "CapturePrompt", slime:GetAttribute("SlimeType") .. " baby", "Pull with grabber"
    prompt.HoldDuration, prompt.MaxActivationDistance = HOLD_SECONDS, REACH
    prompt.RequiresLineOfSight = false -- The server checks the actual path.
    prompt.Parent = body
    local state = {slime = slime, prompt = prompt, attachment = attachment, home = slime:GetPivot()}
    states[slime] = state
    prompt.PromptButtonHoldBegan:Connect(function(player)
        if not state.dropped then begin(player, state) end
    end)
    prompt.PromptButtonHoldEnded:Connect(function(player)
        if attempts[player] == state then state.released = os.clock() end
    end)
    prompt.Triggered:Connect(function(player) finish(player, state) end)
end
slimes.ChildAdded:Connect(function(slime) task.spawn(register, slime) end)
for _, slime in ipairs(slimes:GetChildren()) do task.spawn(register, slime) end
print("Capture ready: equip Slime Grabber, then hold E near a baby.")


-- Only server scripts can invoke this function. It atomically releases capture ownership.
local interrupt = Instance.new("BindableFunction")
interrupt.Name = "InterruptForBat"
interrupt.OnInvoke = function(player)
    cancel(player)
    local record = carrying[player]
    if not record then return false end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then release(player); return false end
    local position = Vector3.new(math.clamp(root.Position.X, -38, 38), root.Position.Y, math.min(root.Position.Z, CombatRules.SafeZ - 4))
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclusions = {record.state.slime}
    for _, other in ipairs(Players:GetPlayers()) do
        if other.Character then table.insert(exclusions, other.Character) end
    end
    local map = workspace:FindFirstChild("SlimeMap")
    if map then
        if map:FindFirstChild("WildSlimes") then table.insert(exclusions, map.WildSlimes) end
        if map:FindFirstChild("Guardians") then table.insert(exclusions, map.Guardians) end
    end
    params.FilterDescendantsInstances = exclusions
    local ground = workspace:Raycast(position + Vector3.new(0, 4, 0), Vector3.new(0, -100, 0), params)
    local dropFrame
    if ground then
        local height = record.state.slime.PrimaryPart.Size.Y * 0.5 + 0.1
        dropFrame = CFrame.new(ground.Position + Vector3.new(0, height, 0)) * record.state.home.Rotation
    end
    release(player, dropFrame)
    message(player, dropFrame and "You dropped your baby! Equip your grabber and pick it back up." or "Your baby returned to its nursery.")
    return dropFrame ~= nil
end
interrupt.Parent = script

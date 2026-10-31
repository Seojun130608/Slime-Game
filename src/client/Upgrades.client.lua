-- StarterPlayerScripts > UpgradesUI. Buttons request purchases; the server decides.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CAS = game:GetService("ContextActionService")
local Prompts = game:GetService("ProximityPromptService")
local player = Players.LocalPlayer
local remote = RS:WaitForChild("SlimeUpgrades")
local state, pending = nil, false
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn, gui.DisplayOrder = "SlimeUpgradesUI", false, 5
gui.Parent = player:WaitForChild("PlayerGui")
local function round(object)
    local corner = Instance.new("UICorner", object); corner.CornerRadius = UDim.new(0, 10)
end
local function label(parent, name, y, height, text, size)
    local object = Instance.new("TextLabel", parent)
    object.Name, object.Text = name, text
    object.Position, object.Size = UDim2.new(0, 16, 0, y), UDim2.new(1, -32, 0, height)
    object.BackgroundTransparency, object.TextWrapped = 1, true
    object.Font, object.TextSize, object.TextColor3 = Enum.Font.GothamBold, size, Color3.fromRGB(240, 255, 226)
    return object
end
local function button(parent, name, y, text)
    local object = Instance.new("TextButton", parent)
    object.Name, object.Text = name, text
    object.Position, object.Size = UDim2.new(0, 16, 0, y), UDim2.new(1, -32, 0, 44)
    object.BackgroundColor3, object.TextColor3 = Color3.fromRGB(101, 184, 63), Color3.new(1, 1, 1)
    object.Font, object.TextSize = Enum.Font.GothamBold, 17
    round(object)
    return object
end
local open = button(gui, "OpenUpgrades", 0, "UPGRADES [U]")
open.Position, open.Size = UDim2.new(0, 16, 0.48, -58), UDim2.fromOffset(174, 50)
local panel = Instance.new("Frame", gui)
panel.Name, panel.Visible, panel.AnchorPoint = "Panel", false, Vector2.new(0.5, 0.5)
panel.Position, panel.Size = UDim2.fromScale(0.5, 0.4), UDim2.new(0.9, 0, 0, 400)
panel.BackgroundColor3 = Color3.fromRGB(35, 63, 47); round(panel)
local bounds = Instance.new("UISizeConstraint", panel)
bounds.MaxSize = Vector2.new(510, 400)
label(panel, "Heading", 12, 32, "UPGRADES", 24)
local cash = label(panel, "Cash", 48, 28, "Cash: $0", 19)
local speed = label(panel, "Speed", 82, 42, "Loading...", 17)
local speedBuy = button(panel, "BuySpeed", 128, "Loading...")
local power = label(panel, "Grabber", 184, 48, "Loading...", 16)
local powerBuy = button(panel, "BuyGrabber", 237, "Loading...")
local notice = label(panel, "Notice", 287, 48, "Upgrades last this session. Saving comes later.", 14)
local close = button(panel, "Close", 345, "CLOSE")
local function update()
    local balance = player:GetAttribute("Cash") or 0
    cash.Text = string.format("Cash: $%.2f", balance)
    if not state then return end
    speed.Text = string.format("SPEED  %d / %d\nRun speed: %d", state.speedLevel, state.maxLevel, state.speed)
    power.Text = string.format("GRABBER POWER  %d / %d\nPower: %d  ·  Pull: %.2fs  ·  Less carrying slowdown", state.grabberLevel, state.maxLevel, state.power, state.holdSeconds)
    for _, item in ipairs({{speedBuy, state.speedCost}, {powerBuy, state.grabberCost}}) do
        local object, cost = item[1], item[2]
        object.Text = cost and ("BUY — $" .. cost) or "MAX LEVEL"
        object.Active = cost ~= nil and not pending
        object.AutoButtonColor = object.Active
        object.BackgroundColor3 = cost and balance >= cost and Color3.fromRGB(101, 184, 63) or Color3.fromRGB(91, 105, 82)
    end
end
local function toggle()
    panel.Visible = not panel.Visible
    if panel.Visible then
        local inventory = player.PlayerGui:FindFirstChild("SlimeInventoryUI")
        if inventory then inventory.Panel.Visible = false end
        remote:FireServer("Request")
    end
end
open.Activated:Connect(toggle)
close.Activated:Connect(function() panel.Visible = false end)
CAS:BindAction("OpenSlimeUpgrades", function(_, input)
    if input == Enum.UserInputState.Begin then toggle() end
    return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.U)
local function buy(kind)
    if not state or pending or not (kind == "Speed" and state.speedCost or kind == "Grabber" and state.grabberCost) then return end
    pending = true; update()
    remote:FireServer("Buy", kind)
    task.delay(0.35, function() pending = false; update() end)
end
speedBuy.Activated:Connect(function() buy("Speed") end)
powerBuy.Activated:Connect(function() buy("Grabber") end)
remote.OnClientEvent:Connect(function(data)
    state, pending = data, false
    if data.message then notice.Text = data.message end
    update()
end)
player:GetAttributeChangedSignal("Cash"):Connect(update)
-- Only the local hold bar changes. Capture still measures the hold on the server.
local visible, holding = {}, {}
local function updatePrompt(prompt)
    if not holding[prompt] and prompt.Name == "CapturePrompt" and prompt.ActionText == "Pull with grabber" then
        prompt.HoldDuration = 2 / (1 + 0.15 * (player:GetAttribute("GrabberLevel") or 0))
    end
end
Prompts.PromptShown:Connect(function(prompt) visible[prompt] = true; updatePrompt(prompt) end)
Prompts.PromptHidden:Connect(function(prompt) visible[prompt], holding[prompt] = nil, nil end)
Prompts.PromptButtonHoldBegan:Connect(function(prompt) holding[prompt] = true end)
Prompts.PromptButtonHoldEnded:Connect(function(prompt) holding[prompt] = nil; updatePrompt(prompt) end)
player:GetAttributeChangedSignal("GrabberLevel"):Connect(function()
    for prompt in pairs(visible) do updatePrompt(prompt) end
end)
update(); remote:FireServer("Request")

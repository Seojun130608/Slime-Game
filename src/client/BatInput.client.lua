-- StarterPlayerScripts: standard tool activation supports mouse, touch and controller.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("SlimeBatSwing")
local connected = setmetatable({}, {__mode = "k"})
local function watch(tool)
    if not tool:IsA("Tool") or tool.Name ~= "Slime Bat" or connected[tool] then return end
    connected[tool] = true
    tool.Activated:Connect(function() remote:FireServer() end)
end
local function characterAdded(character)
    character.ChildAdded:Connect(watch)
    for _, tool in ipairs(character:GetChildren()) do watch(tool) end
end
player.CharacterAdded:Connect(characterAdded)
if player.Character then characterAdded(player.Character) end
local gui = Instance.new("ScreenGui")
gui.Name, gui.ResetOnSpawn = "BatFeedback", false
gui.Parent = player:WaitForChild("PlayerGui")
local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(.5, 0)
label.Position, label.Size = UDim2.new(.5,0,.18,0), UDim2.new(.8,0,0,48)
label.BackgroundColor3, label.BackgroundTransparency = Color3.fromRGB(25,65,52), .1
label.TextColor3, label.TextSize, label.Font = Color3.new(1,1,1), 20, Enum.Font.GothamBold
label.TextWrapped, label.Visible, label.Parent = true, false, gui
Instance.new("UICorner", label).CornerRadius = UDim.new(0,10)
local version = 0
remote.OnClientEvent:Connect(function(kind, message)
    if kind ~= "Message" then return end
    version += 1
    local current = version
    label.Text, label.Visible, label.TextTransparency = message, true, 0
    task.delay(2, function()
        if current ~= version then return end
        label.Visible = false
    end)
end)

-- Carrying players can put a baby down before switching to their bat.
local function updateDropAction()
    ContextActionService:UnbindAction("DropBaby")
    if player:GetAttribute("CarryingSlime") then
        ContextActionService:BindAction("DropBaby", function(_, state)
            if state == Enum.UserInputState.Begin then remote:FireServer("Drop") end
            return Enum.ContextActionResult.Sink
        end, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
        ContextActionService:SetTitle("DropBaby", "Drop Baby")
        ContextActionService:SetPosition("DropBaby", UDim2.new(1, -160, 1, -170))
    end
end
player:GetAttributeChangedSignal("CarryingSlime"):Connect(updateDropAction)
updateDropAction()

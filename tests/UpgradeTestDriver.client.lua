-- Included only in Upgrade-Test.rbxlx, never the playable place.
local Players, RS = game:GetService("Players"), game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local control = RS:WaitForChild("UpgradeTestControl")
local upgrades = RS:WaitForChild("SlimeUpgrades")
local inventory = RS:WaitForChild("SlimeInventory")
local latest, inv
upgrades.OnClientEvent:Connect(function(data) latest = data end)
inventory.OnClientEvent:Connect(function(kind, data) if kind == "Snapshot" then inv = data end end)
control.OnClientEvent:Connect(function(id, action, args)
    local ok, result = pcall(function()
        args = args or {}
        if action == "Buy" then upgrades:FireServer("Buy", args.kind); task.wait(.3); return latest
        elseif action == "Request" then upgrades:FireServer("Request"); task.wait(.3); return latest
        elseif action == "Invalid" then
            upgrades:FireServer("Buy", args.kind, -1000000, args.userId)
            task.wait(.3)
        elseif action == "FakeCash" then
            player:SetAttribute("Cash", 1e9); upgrades:FireServer("Buy", "Speed"); task.wait(.3)
        elseif action == "Inventory" then
            inventory:FireServer(args.action, args.id); task.wait(.3); return inv
        elseif action == "Capture" then
            local c = player.Character
            c.Humanoid:EquipTool(player.Backpack:FindFirstChild("Slime Grabber") or c:FindFirstChild("Slime Grabber"))
            task.wait(.2)
            local prompt = workspace.SlimeMap.WildSlimes[args.kind].Body.CapturePrompt
            -- Exercise the real client prompt duration, including the local upgraded bar.
            local duration = args.hold or prompt.HoldDuration
            prompt:InputHoldBegin(); task.wait(duration + .08); prompt:InputHoldEnd(); task.wait(.2)
            return {duration=prompt.HoldDuration, carrying=player:GetAttribute("CarryingSlime")}
        elseif action == "Bat" then
            local c = player.Character
            c.Humanoid:EquipTool(player.Backpack:FindFirstChild("Slime Bat") or c:FindFirstChild("Slime Bat"))
            RS.SlimeBatSwing:FireServer("Swing"); task.wait(.12)
        elseif action == "UI" then
            local gui = player.PlayerGui:WaitForChild("SlimeUpgradesUI", 5)
            gui.Panel.Visible = true
            upgrades:FireServer("Request"); task.wait(.3)
            return {speed=gui.Panel.Speed.Text, power=gui.Panel.Grabber.Text,
                cash=gui.Panel.Cash.Text, speedButton=gui.Panel.BuySpeed.Text, powerButton=gui.Panel.BuyGrabber.Text}
        end
        return true
    end)
    control:FireServer(id, ok, result)
end)
control:FireServer("Ready", true)

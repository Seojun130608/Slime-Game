-- Test-only client. Included solely in Bat-Test.rbxlx.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local control=RS:WaitForChild("BatTestControl")
local swing=RS:WaitForChild("SlimeBatSwing")
control.OnClientEvent:Connect(function(id,action,arg)
    local ok,err=pcall(function()
        local char=player.Character or player.CharacterAdded:Wait()
        local hum=char:WaitForChild("Humanoid")
        if action=="Capture" then
            hum:EquipTool(player.Backpack:FindFirstChild("Slime Grabber") or char:FindFirstChild("Slime Grabber"))
            task.wait(.2)
            local prompt=workspace.SlimeMap.WildSlimes[arg].Body.CapturePrompt
            prompt:InputHoldBegin();task.wait(2.2);prompt:InputHoldEnd();task.wait(.2)
        elseif action=="Pickup" then
            hum:EquipTool(player.Backpack:FindFirstChild("Slime Grabber") or char:FindFirstChild("Slime Grabber"))
            task.wait(.15)
            local prompt=workspace.SlimeMap.WildSlimes[arg].Body.CapturePrompt
            task.wait(.3);prompt:InputHoldBegin();task.wait(.25);prompt:InputHoldEnd();task.wait(.3)
        elseif action=="Begin" then
            hum:EquipTool(player.Backpack:FindFirstChild("Slime Grabber") or char:FindFirstChild("Slime Grabber"))
            task.wait(.15);workspace.SlimeMap.WildSlimes[arg].Body.CapturePrompt:InputHoldBegin();task.wait(.3)
        elseif action=="Release" then
            workspace.SlimeMap.WildSlimes[arg].Body.CapturePrompt:InputHoldEnd()
        elseif action=="Bat" then
            hum:EquipTool(player.Backpack:FindFirstChild("Slime Bat") or char:FindFirstChild("Slime Bat"))
            task.wait(.15)
            char["Slime Bat"]:Activate();task.wait(.15)
        elseif action=="Swing" then swing:FireServer();task.wait(.1)
        elseif action=="Drop" then swing:FireServer("Drop");task.wait(.15)
        elseif action=="Unequip" then hum:UnequipTools();task.wait(.15)
        end
    end)
    control:FireServer(id,ok,err)
end)
control:FireServer("Ready",true)

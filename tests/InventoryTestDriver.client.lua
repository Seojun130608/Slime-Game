-- Only packaged into Inventory-Test.rbxlx.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local control=RS:WaitForChild("InventoryTestControl")
local remote=RS:WaitForChild("SlimeInventory")
local snapshot
remote.OnClientEvent:Connect(function(kind,data) if kind=="Snapshot" then snapshot=data end end)
control.OnClientEvent:Connect(function(id,action,args)
    local ok,result=pcall(function()
        args=args or {}
        local character=player.Character or player.CharacterAdded:Wait()
        if action=="Capture" then
            character.Humanoid:EquipTool(player.Backpack:FindFirstChild("Slime Grabber") or character:FindFirstChild("Slime Grabber"))
            task.wait(.2)
            local prompt=workspace.SlimeMap.WildSlimes[args.kind].Body.CapturePrompt
            prompt:InputHoldBegin();task.wait(2.2);prompt:InputHoldEnd();task.wait(.2)
        elseif action=="Snapshot" then
            remote:FireServer("Request");task.wait(.3);return snapshot
        elseif action=="SlotPrompt" then
            local prompt=workspace.SlimeMap.Bases["Base"..args.base].CollectionSpots["Spot"..args.slot].CollectionSpot.PlacementPrompt
            prompt:InputHoldBegin();task.wait(.1);prompt:InputHoldEnd();task.wait(.2)
        elseif action=="UIOpen" then
            local gui=player.PlayerGui:WaitForChild("SlimeInventoryUI",5)
            gui.Panel.Visible=true;remote:FireServer("Request");task.wait(.4)
            local cards,previews=0,0
            for _,child in ipairs(gui.Panel.Items:GetChildren()) do
                if child:IsA("TextButton") then
                    cards+=1
                    assert(child:FindFirstChild("SlimeName") and child:FindFirstChild("Status"),"Card labels missing")
                    if child:FindFirstChildWhichIsA("ViewportFrame") then previews+=1 end
                end
            end
            return {cards=cards,previews=previews,base=gui.Panel.Details.Base.Text}
        elseif action=="UI" then
            local gui=player.PlayerGui:WaitForChild("SlimeInventoryUI",5)
            assert(gui and gui.OpenInventory and gui.Panel,"Missing inventory UI")
            return {button=gui.OpenInventory.Text,base=player:GetAttribute("BaseIndex")}
        else
            remote:FireServer(action,args.id,args.slot);task.wait(.25)
        end
        return true
    end)
    control:FireServer(id,ok,result)
end)
control:FireServer("Ready",true)

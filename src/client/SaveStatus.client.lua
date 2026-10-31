local player=game:GetService("Players").LocalPlayer
local gui=Instance.new("ScreenGui",player:WaitForChild("PlayerGui"))
gui.Name,gui.ResetOnSpawn="SaveStatusUI",false
local label=Instance.new("TextLabel",gui)
label.AnchorPoint=Vector2.new(.5,0)
label.Position,label.Size=UDim2.new(.5,0,0,36),UDim2.new(.9,0,0,24)
label.BackgroundColor3,label.BackgroundTransparency=Color3.fromRGB(30,48,38),.15
label.TextColor3,label.Font,label.TextSize=Color3.fromRGB(230,245,220),Enum.Font.GothamMedium,12
label.TextWrapped=true
local function update() label.Text=player:GetAttribute("SaveStatus") or "Loading progress..." end
player:GetAttributeChangedSignal("SaveStatus"):Connect(update)
update()
return nil

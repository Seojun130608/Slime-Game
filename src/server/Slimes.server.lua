local Catalog=require(script.Parent:WaitForChild("SlimeCatalog"))
local Factory=require(script.Parent:WaitForChild("SlimeFactory"))
local map=workspace:WaitForChild("SlimeMap")
local nests=map:WaitForChild("Nests")
if map:FindFirstChild("WildSlimes") then return end
local slimes=Instance.new("Folder",map);slimes.Name="WildSlimes"
for index,definition in ipairs(Catalog.Types) do
 local nestIndex=math.ceil(index/2)
 local nest=nests:WaitForChild("Nest"..nestIndex)
 local center=nest:GetAttribute("SpawnCenter") or nest:GetBoundingBox().Position
 local side=index%2==1 and -4 or 4
 local model=Factory.Create(definition.name,center+Vector3.new(side,0,0))
 model:SetAttribute("NestIndex",nestIndex);model.Parent=slimes
end
print("Slimes ready: Grass, Mud, Water, Honey, Crystal, Gold")

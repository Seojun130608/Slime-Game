local Catalog=require(script.Parent:WaitForChild("SlimeCatalog"))
local Factory={}
function Factory.Create(kind,position)
    local definition=assert(Catalog.Find(kind),"Unknown slime type")
    local model=Instance.new("Model");model.Name=kind.."Slime"
    model:SetAttribute("SlimeType",kind);model:SetAttribute("Rarity",definition.rarity)
    local function ball(name,size,offset,color)
        local p=Instance.new("Part")
        p.Name,p.Size,p.Position,p.Color=name,size,position+offset,color
        p.Shape,p.Material=Enum.PartType.Ball,Enum.Material.SmoothPlastic
        p.Anchored,p.CanCollide=true,false
        p.TopSurface,p.BottomSurface=Enum.SurfaceType.Smooth,Enum.SurfaceType.Smooth
        p.Parent=model
        return p
    end
    local body=ball("Body",Vector3.new(4,3,4),Vector3.new(0,.45,0),definition.color)
    body.Transparency=.08;model.PrimaryPart=body
    local black=Color3.fromRGB(20,20,25)
    ball("LeftEye",Vector3.new(.28,.4,.22),Vector3.new(-.65,1,1.77),black)
    ball("RightEye",Vector3.new(.28,.4,.22),Vector3.new(.65,1,1.77),black)
    ball("Mouth",Vector3.new(.4,.18,.18),Vector3.new(0,.65,1.98),black)
    return model
end
return Factory

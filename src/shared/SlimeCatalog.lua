-- Fixed appearances and rarities used by spawning and saved inventory restoration.
local Catalog = {Types = {
    {name="Grass",rarity="Common",color=Color3.fromRGB(110,210,80)},
    {name="Mud",rarity="Common",color=Color3.fromRGB(135,90,60)},
    {name="Water",rarity="Uncommon",color=Color3.fromRGB(70,175,245)},
    {name="Honey",rarity="Rare",color=Color3.fromRGB(245,160,40)},
    {name="Crystal",rarity="Epic",color=Color3.fromRGB(175,115,245)},
    {name="Gold",rarity="Legendary",color=Color3.fromRGB(255,215,65)},
}}
function Catalog.Find(kind)
    for _, definition in ipairs(Catalog.Types) do
        if definition.name==kind then return definition end
    end
end
return Catalog

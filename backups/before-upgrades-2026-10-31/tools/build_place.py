"""Preserve the Studio-authored Code Class map and package current scripts with inventory."""
from pathlib import Path
import xml.etree.ElementTree as E
import copy,json
ROOT=Path(__file__).resolve().parents[1]
r=E.parse(ROOT/'Steal-A-Slime-Bat.rbxlx').getroot()
refs={n.get('referent') for n in r.findall('.//Item')};i=0
sources=[]
def name(n):
    p=n.find("Properties/string[@name='Name']")
    return p.text if p is not None else ''
def new(cls,nm,parent):
    global i
    i+=1;ref=f'RBXInventory{i}'
    assert ref not in refs;refs.add(ref)
    n=E.SubElement(parent,'Item',{'class':cls,'referent':ref});p=E.SubElement(n,'Properties');E.SubElement(p,'string',{'name':'Name'}).text=nm
    return n
def upsert(parent,cls,nm,src):
    n=next((n for n in parent.findall('Item') if name(n)==nm),None)
    if n is None:n=new(cls,nm,parent)
    assert n.get('class')==cls
    p=n.find("Properties/ProtectedString[@name='Source']")
    if p is None:p=E.SubElement(n.find('Properties'),'ProtectedString',{'name':'Source'})
    p.text=src
    return n
ss=next(n for n in r.findall('Item') if n.get('class')=='ServerScriptService')
sp=next(n for n in r.findall('Item') if n.get('class')=='StarterPlayer')
sps=next(n for n in sp.findall('Item') if n.get('class')=='StarterPlayerScripts')
for nm,fn,cls in [('Grassland','Grassland.server.lua','Script'),('Slimes','Slimes.server.lua','Script'),('CombatRules','CombatRules.lua','ModuleScript'),('Capture','Capture.server.lua','Script'),('Guardians','Guardians.server.lua','Script'),('Bat','Bat.server.lua','Script'),('Inventory','Inventory.server.lua','Script'),('IncomeRules','IncomeRules.lua','ModuleScript')]:
    src=(ROOT/fn).read_text();upsert(ss,cls,nm,src);sources.append(('ServerScriptService',cls,nm,src))
for nm,fn in [('BatInput','BatInput.client.lua'),('InventoryUI','Inventory.client.lua')]:
    src=(ROOT/fn).read_text();upsert(sps,'LocalScript',nm,src);sources.append(('StarterPlayerScripts','LocalScript',nm,src))
# Remove saved pad geometry as well as the runtime map builder's pads.
for base in r.findall(".//Item[@class='Model']"):
    for child in list(base.findall('Item')):
        if name(child)=='CollectionSpots':base.remove(child)
E.indent(r);out=ROOT/'Steal-A-Slime-Pens.rbxlx';E.ElementTree(r).write(out,encoding='utf-8',xml_declaration=True)
lines=['assert(not game:GetService("RunService"):IsRunning(), "Stop testing before installing")']
for parent,cls,nm,src in sources:
    expr='game:GetService("ServerScriptService")' if parent=='ServerScriptService' else 'game:GetService("StarterPlayer").StarterPlayerScripts'
    lines.append('do local p='+expr+'; local s=p:FindFirstChild('+json.dumps(nm)+'); if not s then s=Instance.new('+json.dumps(cls)+');s.Name='+json.dumps(nm)+';s.Parent=p end;assert(s.ClassName=='+json.dumps(cls)+');s.Source='+json.dumps(src,ensure_ascii=False)+' end')
lines.append('print("Roaming pens and passive income installed.")')
(ROOT/'Install-Pens.commandbar.lua').write_text('\n'.join(lines))
test=copy.deepcopy(r)
tss=next(n for n in test.findall('Item') if n.get('class')=='ServerScriptService')
tsp=next(n for n in test.findall('Item') if n.get('class')=='StarterPlayer')
tsps=next(n for n in tsp.findall('Item') if n.get('class')=='StarterPlayerScripts')
for parent,cls,nm,fn in [(tss,'Script','PenIntegration','PenIntegration.server.lua'),(tsps,'LocalScript','PenTestDriver','PenTestDriver.client.lua')]:
    if (ROOT/'tests'/fn).exists():upsert(parent,cls,nm,(ROOT/'tests'/fn).read_text())
E.indent(test);E.ElementTree(test).write(ROOT/'tests/Pen-Test.rbxlx',encoding='utf-8',xml_declaration=True)
print('Built current inventory place, preserving map geometry and previous bat build.')

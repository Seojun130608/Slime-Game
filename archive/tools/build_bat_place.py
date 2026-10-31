"""Package the current Code Class Luau scripts into a locally openable Studio place."""
from pathlib import Path
import xml.etree.ElementTree as E
import json
ROOT=Path(__file__).resolve().parents[1]
r=E.Element('roblox',{'version':'4'});E.SubElement(r,'External').text='null';E.SubElement(r,'External').text='nil'
i=0
sources=[]
def item(cls,name,parent):
    global i
    i+=1;n=E.SubElement(parent,'Item',{'class':cls,'referent':f'RBX{i}'})
    p=E.SubElement(n,'Properties');E.SubElement(p,'string',{'name':'Name'}).text=name
    return n
def prop(n,kind,name,val):E.SubElement(n.find('Properties'),kind,{'name':name}).text=str(val)
workspace=item('Workspace','Workspace',r)
spawn=item('SpawnLocation','SpawnLocation',workspace)
for kind,key,value in [('bool','Anchored','true'),('bool','Neutral','true'),('bool','CanCollide','false'),('float','Transparency',1),('float','Duration',0)]:prop(spawn,kind,key,value)
for key,values in [('size',(10,1,10)),('Position',(0,.6,229))]:
    v=E.SubElement(spawn.find('Properties'),'Vector3',{'name':key})
    for axis,num in zip(('X','Y','Z'),values):E.SubElement(v,axis).text=str(num)

lighting=item('Lighting','Lighting',r)
for k,v in [('ClockTime',13),('Brightness',2),('FogEnd',3000)]:prop(lighting,'float',k,v)
prop(lighting,'bool','GlobalShadows','false')
ss=item('ServerScriptService','ServerScriptService',r)
for name,filename,cls in [('Grassland','Grassland.server.lua','Script'),('Slimes','Slimes.server.lua','Script'),('CombatRules','CombatRules.lua','ModuleScript'),('Capture','Capture.server.lua','Script'),('Guardians','Guardians.server.lua','Script'),('Bat','Bat.server.lua','Script')]:
    source=(ROOT/filename).read_text();n=item(cls,name,ss);prop(n,'ProtectedString','Source',source);sources.append(('ServerScriptService',name,cls,source))
sp=item('StarterPlayer','StarterPlayer',r);sps=item('StarterPlayerScripts','StarterPlayerScripts',sp)
source=(ROOT/'BatInput.client.lua').read_text();n=item('LocalScript','BatInput',sps);prop(n,'ProtectedString','Source',source);sources.append(('StarterPlayerScripts','BatInput','LocalScript',source))
E.indent(r);out=ROOT/'Steal-A-Slime-Bat.rbxlx';E.ElementTree(r).write(out,encoding='utf-8',xml_declaration=True)
# Also patch a saved existing Code Class place through Studio's Command Bar in edit mode.
lines=['assert(not game:GetService("RunService"):IsRunning(), "Stop playtesting before installing")']
for parent,name,cls,source in sources:
    parentexpr='game:GetService("ServerScriptService")' if parent=='ServerScriptService' else 'game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")'
    lines.append('do local parent='+parentexpr+'; local s=parent:FindFirstChild('+json.dumps(name)+'); if s then assert(s.ClassName=='+json.dumps(cls)+') else s=Instance.new('+json.dumps(cls)+'); s.Name='+json.dumps(name)+'; s.Parent=parent end; s.Source='+json.dumps(source)+' end')
lines.append('print("Slime Bat installed. Save locally, then start a 2-player test.")')
(ROOT/'Install-Bat.commandbar.lua').write_text('\n'.join(lines))
print('Packaged Code Class map, capture, guardians, bat, and client controls:',out.name)

# A separate test-only place exercises real client/server behavior; never ship its test controls.
import copy
testroot=copy.deepcopy(r)
tss=next(n for n in testroot.findall('Item') if n.get('class')=='ServerScriptService')
tsp=next(n for n in testroot.findall('Item') if n.get('class')=='StarterPlayer').find('Item')
for parent,cls,name,fn in [(tss,'Script','BatIntegration','BatIntegration.server.lua'),(tsp,'LocalScript','BatTestDriver','BatTestDriver.client.lua')]:
    if (ROOT/'tests'/fn).exists():
        n=item(cls,name,parent);prop(n,'ProtectedString','Source',(ROOT/'tests'/fn).read_text())
E.indent(testroot);E.ElementTree(testroot).write(ROOT/'tests/Bat-Test.rbxlx',encoding='utf-8',xml_declaration=True)

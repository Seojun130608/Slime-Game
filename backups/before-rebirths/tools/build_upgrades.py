"""Package upgrades into the current roaming-pen place, preserving the earlier milestone."""
from pathlib import Path
import xml.etree.ElementTree as E
import copy
import json

ROOT = Path(__file__).resolve().parents[1]
tree = E.parse(ROOT / 'archive/milestones/Steal-A-Slime-Pens.rbxlx')
root = tree.getroot()
refs = {item.get('referent') for item in root.findall('.//Item')}
serial = 0
def name(item):
    return item.findtext("Properties/string[@name='Name']", '')
def upsert(parent, cls, label, source):
    global serial
    item = next((item for item in parent.findall('Item') if name(item) == label), None)
    if item is None:
        serial += 1
        ref = f'RBXUpgrades{serial}'
        assert ref not in refs
        refs.add(ref)
        item = E.SubElement(parent, 'Item', {'class': cls, 'referent': ref})
        props = E.SubElement(item, 'Properties')
        E.SubElement(props, 'string', {'name': 'Name'}).text = label
    assert item.get('class') == cls
    props = item.find('Properties')
    field = props.find("ProtectedString[@name='Source']")
    if field is None: field = E.SubElement(props, 'ProtectedString', {'name': 'Source'})
    field.text = source
    return item
ss = next(item for item in root.findall('Item') if item.get('class') == 'ServerScriptService')
sp = next(item for item in root.findall('Item') if item.get('class') == 'StarterPlayer')
sps = next(item for item in sp.findall('Item') if item.get('class') == 'StarterPlayerScripts')
SOURCES = [('Grassland', 'src/server/Grassland.server.lua', 'Script'), ('Slimes', 'src/server/Slimes.server.lua', 'Script'), ('Capture', 'src/server/Capture.server.lua', 'Script'), ('Guardians', 'src/server/Guardians.server.lua', 'Script'), ('Bat', 'src/server/Bat.server.lua', 'Script'), ('Inventory', 'src/server/Inventory.server.lua', 'Script'), ('Upgrades', 'src/server/Upgrades.server.lua', 'Script'), ('CombatRules', 'src/shared/CombatRules.lua', 'ModuleScript'), ('IncomeRules', 'src/shared/IncomeRules.lua', 'ModuleScript'), ('UpgradeRules', 'src/shared/UpgradeRules.lua', 'ModuleScript')]
CLIENTS = [('BatInput', 'src/client/BatInput.client.lua', 'LocalScript'), ('InventoryUI', 'src/client/Inventory.client.lua', 'LocalScript'), ('UpgradesUI', 'src/client/Upgrades.client.lua', 'LocalScript')]
for label, filename, cls in SOURCES:
    upsert(ss, cls, label, (ROOT / filename).read_text())
for label, filename, cls in CLIENTS:
    upsert(sps, cls, label, (ROOT / filename).read_text())
E.indent(root)
tree.write(ROOT / 'Steal-A-Slime-Upgrades.rbxlx', encoding='utf-8', xml_declaration=True)
lines = ['assert(not game:GetService("RunService"):IsRunning(), "Stop testing before installing")']
for label, filename, cls in SOURCES + CLIENTS:
    parent = 'game:GetService("StarterPlayer").StarterPlayerScripts' if cls == 'LocalScript' else 'game:GetService("ServerScriptService")'
    lines.append('do local p=' + parent + '; local s=p:FindFirstChild(' + json.dumps(label) + '); if not s then s=Instance.new(' + json.dumps(cls) + ');s.Name=' + json.dumps(label) + ';s.Parent=p end;assert(s.ClassName==' + json.dumps(cls) + ');s.Source=' + json.dumps((ROOT / filename).read_text()) + ' end')
lines.append('print("Speed and Grabber Power upgrades installed.")')
(ROOT / 'tools/install_current.commandbar.lua').write_text('\n'.join(lines))
test = copy.deepcopy(root)
tss = next(item for item in test.findall('Item') if item.get('class') == 'ServerScriptService')
tsp = next(item for item in test.findall('Item') if item.get('class') == 'StarterPlayer')
tsps = next(item for item in tsp.findall('Item') if item.get('class') == 'StarterPlayerScripts')
upsert(tss, 'Script', 'UpgradeIntegration', (ROOT / 'tests/UpgradeIntegration.server.lua').read_text())
upsert(tsps, 'LocalScript', 'UpgradeTestDriver', (ROOT / 'tests/UpgradeTestDriver.client.lua').read_text())
E.indent(test)
E.ElementTree(test).write(ROOT / 'tests/Upgrade-Test.rbxlx', encoding='utf-8', xml_declaration=True)
print('Built clean upgrade place and isolated integration test place.')

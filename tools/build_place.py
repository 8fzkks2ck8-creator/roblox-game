#!/usr/bin/env python3
"""Preserve uploaded assets/services and inject editable source plus a static map preview."""
import argparse, base64, copy, pathlib, xml.etree.ElementTree as ET
from validate import ROOT, run
from import_ui_pack import import_pack

def name(item):
    e=item.find("Properties/*[@name='Name']")
    return e.text if e is not None else ''
def child(item, label):
    return next(i for i in item.findall('Item') if name(i)==label)
def prop(parent,tag,key,value):
    old=parent.find(f"*[@name='{key}']")
    if old is not None: parent.remove(old)
    el=ET.SubElement(parent,tag,name=key)
    if value is not None: el.text=str(value)
    return el
ENUMS={'Material':{'Plastic':256,'SmoothPlastic':272,'Slate':800,'Grass':1280,'Neon':288,'Glass':1568},'SurfaceType':{'Smooth':0,'Studs':3},'PartType':{'Ball':0,'Cylinder':2},'Font':{'GothamBold':19,'FredokaOne':26}}

def write_props(properties, data, cls):
    for key,value in data.items():
        if key=='Position' and cls in ('Part','SpawnLocation'): continue
        if isinstance(value,bool): prop(properties,'bool',key,str(value).lower())
        elif isinstance(value,(int,float)): prop(properties,'int' if key in ('Duration',) else 'float',key,value)
        elif isinstance(value,str): prop(properties,'string',key,value)
        elif isinstance(value,dict):
            typ=value['_type']
            if typ=='Enum': prop(properties,'token','shape' if key=='Shape' else key,ENUMS[value['Group']][value['Name']])
            elif typ=='Color3':
                if cls in ('Part','SpawnLocation') and key=='Color':
                    rgb=[round(value[k]*255) for k in ('R','G','B')]
                    prop(properties,'Color3uint8','Color3uint8',(255<<24)+(rgb[0]<<16)+(rgb[1]<<8)+rgb[2])
                else:
                    el=prop(properties,'Color3',key,None)
                    for k in ('R','G','B'): ET.SubElement(el,k).text=str(value[k])
            elif typ=='Vector3':
                el=prop(properties,'Vector3','size' if key=='Size' and cls in ('Part','SpawnLocation') else key,None)
                for k in ('X','Y','Z'): ET.SubElement(el,k).text=str(value[k])
            elif typ=='CFrame':
                el=prop(properties,'CoordinateFrame',key,None)
                for k in ('X','Y','Z'): ET.SubElement(el,k).text=str(value[k])
                for index,v in enumerate(value['R']): ET.SubElement(el,f'R{index//3}{index%3}').text=str(v)
            elif typ=='UDim2':
                el=prop(properties,'UDim2',key,None)
                for k in ('XS','XO','YS','YO'): ET.SubElement(el,k).text=str(value.get(k, value.get(k[0],0) if k.endswith('O') else 0))
            elif typ=='Vector2':
                el=prop(properties,'Vector2',key,None)
                for k in ('X','Y'): ET.SubElement(el,k).text=str(value[k])
            else: raise ValueError(typ)
        else: raise ValueError((key,value))

def xml_node(data,seq):
    item=ET.Element('Item',{'class':data['class'],'referent':f'RBX_RIFT_POLISH_{next(seq)}'})
    props=ET.SubElement(item,'Properties')
    write_props(props,data['props'],data['class'])
    for kid in data['children']: item.append(xml_node(kid,seq))
    # Runtime-only attributes are recreated by World.Build on Play.
    return item

def build(luau,compiler,output):
    world,lighting=run(luau,compiler)
    tree=ET.parse(ROOT/'assets/AnimeRift.original.rbxlx');root=tree.getroot()
    rs=child(root,'ReplicatedStorage');rift=child(rs,'AnimeRift')
    sss=child(root,'ServerScriptService')
    client=child(child(child(root,'StarterPlayer'),'StarterPlayerScripts'),'Client')
    targets=[(client,'src/client/Client.client.luau')]
    for legacy in list(sss.findall('Item')):
        if name(legacy)=='Combat': sss.remove(legacy)
    for file in (ROOT/'src/server').glob('*.luau'):
        label=file.name.replace('.server.luau','').replace('.luau','')
        try: item=child(sss,label)
        except StopIteration:
            item=ET.SubElement(sss,'Item',{'class':'Script' if '.server.' in file.name else 'ModuleScript','referent':'RBX_RIFT_SERVER_'+label});ET.SubElement(item,'Properties');prop(item.find('Properties'),'string','Name',label)
        targets.append((item,str(file.relative_to(ROOT))))
    for file in (ROOT/'src/shared').glob('*.luau'):
        label=file.stem
        try: item=child(rift,label)
        except StopIteration:
            item=ET.SubElement(rift,'Item',{'class':'ModuleScript','referent':'RBX_RIFT_MODULE_'+label});ET.SubElement(item,'Properties');prop(item.find('Properties'),'string','Name',label)
        targets.append((item,str(file.relative_to(ROOT))))
    for item,file in targets: prop(item.find('Properties'),'ProtectedString','Source',(ROOT/file).read_text())
    workspace=child(root,'Workspace')
    for old in list(workspace.findall('Item')):
        if name(old) not in ('Terrain','Camera','RiftLayout'): workspace.remove(old)
    layout=child(workspace,'RiftLayout')
    for old in list(layout.findall('Item')):
        if name(old)!='LobbySpawn': layout.remove(old)
    import itertools
    seq=itertools.count(1);workspace.append(xml_node(world,seq))
    light=child(root,'Lighting');write_props(light.find('Properties'),lighting['props'],'Lighting')
    for data in lighting['children']:
        for prior in list(light.findall('Item')):
            if name(prior)==data['props']['Name']: light.remove(prior)
        light.append(xml_node(data,seq))
    import_pack(rift,root)
    output.parent.mkdir(parents=True,exist_ok=True)
    tree.write(output,encoding='utf-8',xml_declaration=True)
    # Verify the exported source is exact and all original imported rigs remain.
    final=ET.parse(output).getroot()
    assert len(list(final.iter('Item')))>1000
    refs=[i.get('referent') for i in final.iter('Item')];assert len(refs)==len(set(refs)), 'Duplicate referents'
    for item,file in targets:
        exported=next(i for i in final.iter('Item') if i.get('referent')==item.get('referent'))
        assert exported.find("Properties/*[@name='Source']").text==(ROOT/file).read_text()
    final_rift=child(child(final,'ReplicatedStorage'),'AnimeRift')
    assert ET.tostring(child(rift,'Assets'))==ET.tostring(child(final_rift,'Assets')), 'Imported assets changed'
    print(f'BUILT {output} ({output.stat().st_size:,} bytes); {len(targets)} script sources verified')
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--luau',default='luau');p.add_argument('--compiler',default='luau-compile');p.add_argument('--output',type=pathlib.Path,default=ROOT/'AnimeRift_Clicker.rbxlx');a=p.parse_args()
    build(a.luau,a.compiler,a.output)

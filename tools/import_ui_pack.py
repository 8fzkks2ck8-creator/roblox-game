import copy,xml.etree.ElementTree as E
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def name(i):
 p=i.find("Properties/*[@name='Name']");return p.text if p is not None else ''
def import_pack(rift,original):
 assets=next(i for i in rift.findall('Item') if name(i)=='Assets')
 pack=next(i for i in original.iter('Item') if name(i)=='MegaPack' and i.get('class')=='Frame')
 folder=E.SubElement(assets,'Item',{'class':'Folder','referent':'RBX_RIFT_UI_IMPORTED'})
 props=E.SubElement(folder,'Properties');E.SubElement(props,'string',name='Name').text='UIMegaPack'
 for index,source in enumerate(pack.findall('Item')):
  if source.get('class') not in ('ImageButton','ImageLabel'):continue
  item=copy.deepcopy(source)
  for parent in item.iter('Item'):
   for child in list(parent.findall('Item')):
    if child.get('class') in ('Script','LocalScript','ModuleScript'):parent.remove(child)
  for j,child in enumerate(item.iter('Item')):child.set('referent',f'RBX_IMPORTED_UI_{index}_{j}')
  folder.append(item)
 return folder

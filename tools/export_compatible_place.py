"""Preserve Studio's legacy asset-property wire format after a Lune export.
Only URI-backed Content values are supported. Object-backed content fails closed.
"""
import struct,ctypes,ctypes.util,collections,json,sys
Z=ctypes.CDLL(ctypes.util.find_library('zstd'));L=ctypes.CDLL(ctypes.util.find_library('lz4'))
Z.ZSTD_decompress.restype=ctypes.c_size_t;L.LZ4_decompress_safe.restype=ctypes.c_int
L.LZ4_compressBound.restype=ctypes.c_int;L.LZ4_compress_default.restype=ctypes.c_int
U=lambda n:struct.pack('<I',n)
def string(b):return U(len(b))+b
def readstr(b,p):
 n=struct.unpack_from('<I',b,p)[0];return b[p+4:p+4+n],p+4+n
def chunks(path):
 b=open(path,'rb').read();p=32
 while p+16<=len(b):
  start=p;tag,cl,ul,res=struct.unpack_from('<4sIII',b,p);p+=16;raw=b[p:p+(cl or ul)];p+=cl or ul;data=raw
  if cl:
   dest=ctypes.create_string_buffer(ul)
   n=Z.ZSTD_decompress(dest,ul,raw,len(raw)) if raw[:4]==b'\x28\xb5\x2f\xfd' else L.LZ4_decompress_safe(raw,dest,len(raw),ul)
   assert n==ul,'Decompression failed';data=dest.raw
  yield tag,data,b[start:p]
def layout(path):
 classes={};props=collections.defaultdict(set)
 for tag,data,_ in chunks(path):
  if tag==b'INST':
   cid=struct.unpack_from('<I',data)[0];name,pos=readstr(data,4);count=struct.unpack_from('<I',data,pos+1)[0];classes[cid]=(name.decode(),count)
  if tag==b'PROP':
   cid=struct.unpack_from('<I',data)[0];name,pos=readstr(data,4);props[classes[cid][0]].add(name.decode())
 return classes,props

def convert(src,dst,reference):
 classes,_=layout(src);_,legacy=layout(reference);out=bytearray(open(src,'rb').read(32));report=[]
 for tag,data,encoded in chunks(src):
  if tag!=b'PROP':out.extend(encoded);continue
  cid=struct.unpack_from('<I',data)[0];name,p=readstr(data,4)
  if data[p]!=0x22:out.extend(encoded);continue
  prop=name.decode();cls,n=classes[cid];body=data[p+1:]
  base=prop.removesuffix('Content')
  candidates=[base,base+'Id',base+'ID']
  mapped=next((x for x in candidates if x in legacy[cls]),None)
  mapped={('Sound','AudioContent'):'SoundId',('UnionOperation','Content'):'AssetId',('WrapTarget','HSRContent'):'HSRAssetId'}.get((cls,prop),mapped)
  kinds=[]
  for i in range(n):
   value=int.from_bytes(bytes(body[i+j*n] for j in range(4)),'big');kinds.append((value>>1)^-(value&1))
  q=4*n;uri_count=struct.unpack_from('<I',body,q)[0];q+=4;uris=[]
  for _ in range(uri_count):v,q=readstr(body,q);uris.append(v)
  obj_count=struct.unpack_from('<I',body,q)[0];q+=4
  assert obj_count==0 and all(k in (0,1) for k in kinds),'Object-backed content cannot be represented as an asset URI'
  assert struct.unpack_from('<I',body,q)[0]==0 and q+4==len(body),'Unexpected content payload'
  assert sum(k==1 for k in kinds)==len(uris),'URI count mismatch'
  pool=iter(uris);values=[next(pool) if k else b'' for k in kinds]
  if mapped is None:
   assert not uris, f'Nonempty unsupported property {cls}.{prop}'
   report.append({'class':cls,'from':prop,'to':'dropped-empty-default','instances':n,'nonempty':0})
   continue
  new=U(cid)+string(mapped.encode())+b'\x01'+b''.join(string(v) for v in values)
  dest=ctypes.create_string_buffer(L.LZ4_compressBound(len(new)));size=L.LZ4_compress_default(new,dest,len(new),len(dest));assert size>0
  out.extend(struct.pack('<4sIII',tag,size,len(new),0));out.extend(dest.raw[:size])
  report.append({'class':cls,'from':prop,'to':mapped,'instances':n,'nonempty':len(uris)})
 open(dst,'wb').write(out)
 return report
if __name__=='__main__':
 report=convert(*sys.argv[1:]);print(json.dumps(report,indent=2))

-- Lossless R2 triangle vertex indexing, no changes to triangle raster order.
local M={}
function M.compact(triangles,checkpoint)
 assert(type(triangles)=="table" and #triangles%3==0,"triangle vertex list required")
 local vertices,indices,by_x={},{},{}
 for i=1,#triangles do
  local v=triangles[i]
  assert(type(v)=="table" and #v==8,"R2 vertex must contain eight attributes")
  local ys=by_x[v[1]]
  if not ys then ys={};by_x[v[1]]=ys end
  local list=ys[v[2]]
  if not list then list={};ys[v[2]]=list end
  local matched
  for k=1,#list do
   local id=list[k]
   local u=vertices[id]
   local equal=true
   for a=1,8 do if u[a]~=v[a] then equal=false;break end end
   if equal then matched=id;break end
  end
  if not matched then
   matched=#vertices+1;vertices[matched]=v;list[#list+1]=matched
  end
  indices[i]=matched
  if checkpoint and i%256==0 then checkpoint() end
 end
 return vertices,indices
end
return M

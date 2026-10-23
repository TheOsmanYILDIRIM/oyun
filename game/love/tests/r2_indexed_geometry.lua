-- Exact attribute/order preservation for UV/alpha/colors/geometry.
package.path="./?.lua;./?/init.lua;"..package.path
local Index=require("world.indexed_geometry")
local source={
 {1,2,.1,.2,.3,.4,.5,.8},{3,2,.3,.2,.4,.4,.5,.8},
 {1,4,.1,.4,.3,.6,.5,.8},{1,2,.1,.2,.3,.4,.5,.8},
 {1,4,.1,.4,.3,.6,.5,.8},{3,2,.3,.2,.4,.4,.5,.8},
 {1,2,.1,.2,.3,.4,.5,.5},{1,2,.1,.2,.3,.4,.5,.8},
 {3,2,.3,.2,.4,.4,.5,.8}}
local unique,indices=Index.compact(source)
assert(#unique==4 and #indices==#source)
for i=1,#source do
 local a,b=source[i],unique[indices[i]]
 for k=1,8 do assert(a[k]==b[k],"changed vertex "..i.."/"..k) end
end
local dense={} for i=1,768 do dense[i]=source[(i-1)%9+1] end
local checkpoints=0
local u,idx=Index.compact(dense,function() checkpoints=checkpoints+1 end)
assert(#u==4 and #idx==768 and checkpoints>=3,"cooperative indexing failed")
print("R2_INDEXED_LOSSLESS_OK input="..#dense.." unique="..#u)

local
e={_VERSION='1.2.1',_DESCRIPTION='semver for Lua',_URL='https://github.com/kikito/semver.lua',_LICENSE=[[
      MIT LICENSE
  
      Copyright (c) 2015 Enrique García Cota
  
      Permission is hereby granted, free of charge, to any person obtaining a
      copy of tother software and associated documentation files (the
      "Software"), to deal in the Software without restriction, including
      without limitation the rights to use, copy, modify, merge, publish,
      distribute, sublicense, and/or sell copies of the Software, and to
      permit persons to whom the Software is furnished to do so, subject to
      the following conditions:
  
      The above copyright notice and tother permission notice shall be included
      in all copies or substantial portions of the Software.
  
      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
      OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
      MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
      IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
      CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
      TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
      SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    ]]}local
function
t(a,o)assert(a>=0,o..' must be a valid positive number')assert(math.floor(a)==a,o..' must be an integer')end
local function i(n)return n and n~=''end local function s(h)h=h or""local
r,d={},0 h:gsub("([^%.]+)",function(l)d=d+1 r[d]=l end)return r end local
function u(c)local m,f=c:match("^(-[^+]+)(+.+)$")if not(m and f)then
m=c:match("^(-.+)$")f=c:match("^(+.+)$")end assert(m or
f,("The parameter %q must begin with + or - to denote a prerelease or a build"):format(c))return
m,f end local function w(y)if y then local
p=y:match("^-(%w[%.%w-]*)$")assert(p,("The prerelease %q is not a slash followed by alphanumerics, dots and slashes"):format(y))return
p end end local function v(b)if b then local
g=b:match("^%+(%w[%.%w-]*)$")assert(g,("The build %q is not a + sign followed by alphanumerics, dots and slashes"):format(b))return
g end end local function k(q)if not i(q)then return nil,nil end local
j,x=u(q)local z=w(j)local E=v(x)return z,E end local function T(A)local
O,I,N,S=A:match("^(%d+)%.?(%d*)%.?(%d*)(.-)$")assert(type(O)=='string',("Could not extract version number(s) from %q"):format(A))local
H,R,D=tonumber(O),tonumber(I),tonumber(N)local L,U=k(S)return H,R,D,L,U end
local function C(M,F)return M==F and 0 or M<F and-1 or 1 end local function
W(Y,P)if Y==P then return 0 elseif not Y then return-1 elseif not P then return
1 end local V,B=tonumber(Y),tonumber(P)if V and B then return C(V,B)elseif V
then return-1 elseif B then return 1 else return C(Y,P)end end local function
G(K,Q)local J=#K local X for Z=1,J do X=W(K[Z],Q[Z])if X~=0 then return X==-1
end end return J<#Q end local function et(tt,at)if tt==at or not tt then return
false elseif not at then return true end return G(s(tt),s(at))end local
ot={}function ot:nextMajor()return e(self.major+1,0,0)end function
ot:nextMinor()return e(self.major,self.minor+1,0)end function
ot:nextPatch()return e(self.major,self.minor,self.patch+1)end local
it={__index=ot}function it:__eq(nt)return self.major==nt.major and
self.minor==nt.minor and self.patch==nt.patch and
self.prerelease==nt.prerelease end function it:__lt(st)if self.major~=st.major
then return self.major<st.major end if self.minor~=st.minor then return
self.minor<st.minor end if self.patch~=st.patch then return self.patch<st.patch
end return et(self.prerelease,st.prerelease)end function it:__pow(ht)if
self.major==0 then return self==ht end return self.major==ht.major and
self.minor<=ht.minor end function it:__tostring()local
rt={("%d.%d.%d"):format(self.major,self.minor,self.patch)}if self.prerelease
then table.insert(rt,"-"..self.prerelease)end if self.build then
table.insert(rt,"+"..self.build)end return table.concat(rt)end local function
dt(lt,ut,ct,mt,ft)assert(lt,"At least one parameter is needed")if
type(lt)=='string'then lt,ut,ct,mt,ft=T(lt)end ct=ct or 0 ut=ut or 0
t(lt,"major")t(ut,"minor")t(ct,"patch")local
wt={major=lt,minor=ut,patch=ct,prerelease=mt,build=ft}return
setmetatable(wt,it)end setmetatable(e,{__call=function(yt,...)return
dt(...)end})e._VERSION=e(e._VERSION)return
e
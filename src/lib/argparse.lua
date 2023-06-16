local function e(t,a)for o,i in pairs(a)do if type(i)=="table"then i=e({},i)end
t[o]=i end return t end local function n(s,h,r)local d={}d.__index=d if r then
d.__prototype=e(e({},r.__prototype),s)else d.__prototype=s end if h then local
l={}for u,c in ipairs(h)do local m,f=c[1],c[2]d[m]=function(w,y)if not
f(w,y)then w["_"..m]=y end return w end l[m]=true end function
d.__call(p,...)if type((...))=="table"then for v,b in pairs((...))do if
l[v]then p[v](p,b)end end else local g=select("#",...)for k,q in ipairs(h)do if
k>g or k>h.args then break end local arg=select(k,...)if arg~=nil then
p[q[1]](p,arg)end end end return p end end local j={}j.__index=r function
j.__call(x,...)local z=e({},x.__prototype)setmetatable(z,x)return z(...)end
return setmetatable(d,j)end local function E(T,A,O)for I,N in ipairs(A)do if
type(O)==N then return true end end
error(("bad property '%s' (%s expected, got %s)"):format(T,table.concat(A," or "),type(O)))end
local function S(H,...)local R={...}return{H,function(D,L)E(H,R,L)end}end local
U={"name",function(C,M)E("name",{"string"},M)for F in M:gmatch("%S+")do
C._name=C._name or F
table.insert(C._aliases,F)table.insert(C._public_aliases,F)if
F:find("_",1,true)then table.insert(C._aliases,(F:gsub("_","-")))end end return
true end}local W={"hidden_name",function(Y,P)E("hidden_name",{"string"},P)for V
in P:gmatch("%S+")do table.insert(Y._aliases,V)if V:find("_",1,true)then
table.insert(Y._aliases,(V:gsub("_","-")))end end return true end}local
function B(G)if tonumber(G)then return tonumber(G),tonumber(G)end if G=="*"then
return 0,math.huge end if G=="+"then return 1,math.huge end if G=="?"then
return 0,1 end if G:match"^%d+%-%d+$"then local
K,Q=G:match"^(%d+)%-(%d+)$"return tonumber(K),tonumber(Q)end if
G:match"^%d+%+$"then local J=G:match"^(%d+)%+$"return tonumber(J),math.huge end
end local function X(Z)return{Z,function(et,tt)E(Z,{"number","string"},tt)local
at,ot=B(tt)if not at then error(("bad property '%s'"):format(Z))end
et["_min"..Z],et["_max"..Z]=at,ot end}end local it={}local
nt={"action",function(st,ht)E("action",{"function","string"},ht)if
type(ht)=="string"and not it[ht]then
error(("unknown action '%s'"):format(ht))end end}local
rt={"init",function(dt)dt._has_init=true end}local
lt={"default",function(ut,ct)if type(ct)~="string"then ut._init=ct
ut._has_init=true return true end end}local
mt={"add_help",function(ft,wt)E("add_help",{"boolean","string","table"},wt)if
ft._help_option_idx then
table.remove(ft._options,ft._help_option_idx)ft._help_option_idx=nil end if wt
then local
yt=ft:flag():description"Show this help message and exit.":action(function()print(ft:get_help())error()end)if
wt~=true then yt=yt(wt)end if not yt._name then yt"-h""--help"end
ft._help_option_idx=#ft._options end end}local
pt=n({_arguments={},_options={},_commands={},_mutexes={},_groups={},_require_command=true,_handle_options=true},{args=3,S("name","string"),S("description","string"),S("epilog","string"),S("usage","string"),S("help","string"),S("require_command","boolean"),S("handle_options","boolean"),S("action","function"),S("command_target","string"),S("help_vertical_space","number"),S("usage_margin","number"),S("usage_max_width","number"),S("help_usage_margin","number"),S("help_description_margin","number"),S("help_max_width","number"),mt})local
vt=n({_aliases={},_public_aliases={}},{args=3,U,S("description","string"),S("epilog","string"),W,S("summary","string"),S("target","string"),S("usage","string"),S("help","string"),S("require_command","boolean"),S("handle_options","boolean"),S("action","function"),S("command_target","string"),S("help_vertical_space","number"),S("usage_margin","number"),S("usage_max_width","number"),S("help_usage_margin","number"),S("help_description_margin","number"),S("help_max_width","number"),S("hidden","boolean"),mt},pt)local
bt=n({_minargs=1,_maxargs=1,_mincount=1,_maxcount=1,_defmode="unused",_show_default=true},{args=5,S("name","string"),S("description","string"),lt,S("convert","function","table"),X("args"),S("target","string"),S("defmode","string"),S("show_default","boolean"),S("argname","string","table"),S("choices","table"),S("hidden","boolean"),nt,rt})local
gt=n({_aliases={},_public_aliases={},_mincount=0,_overwrite=true},{args=6,U,S("description","string"),lt,S("convert","function","table"),X("args"),X("count"),W,S("target","string"),S("defmode","string"),S("show_default","boolean"),S("overwrite","boolean"),S("argname","string","table"),S("choices","table"),S("hidden","boolean"),nt,rt},bt)function
pt:_inherit_property(kt,qt)local jt=self while true do local xt=jt["_"..kt]if
xt~=nil then return xt end if not jt._parent then return qt end jt=jt._parent
end end function bt:_get_argument_list()local zt={}local Et=1 while
Et<=math.min(self._minargs,3)do local Tt=self:_get_argname(Et)if self._default
and self._defmode:find"a"then Tt="["..Tt.."]"end table.insert(zt,Tt)Et=Et+1 end
while Et<=math.min(self._maxargs,3)do
table.insert(zt,"["..self:_get_argname(Et).."]")Et=Et+1 if
self._maxargs==math.huge then break end end if Et<self._maxargs then
table.insert(zt,"...")end return zt end function bt:_get_usage()local
At=table.concat(self:_get_argument_list()," ")if self._default and
self._defmode:find"u"then if self._maxargs>1 or(self._minargs==1 and not
self._defmode:find"a")then At="["..At.."]"end end return At end function
it.store_true(Ot,It)Ot[It]=true end function it.store_false(Nt,St)Nt[St]=false
end function it.store(Ht,Rt,Dt)Ht[Rt]=Dt end function it.count(Lt,Ut,Ct,Mt)if
not Mt then Lt[Ut]=Lt[Ut]+1 end end function
it.append(Ft,Wt,Yt,Pt)Ft[Wt]=Ft[Wt]or{}table.insert(Ft[Wt],Yt)if Pt then
table.remove(Ft[Wt],1)end end function it.concat(Vt,Bt,Gt,Kt)if Kt then
error("'concat' action can't handle too many invocations")end
Vt[Bt]=Vt[Bt]or{}for Qt,Jt in ipairs(Gt)do table.insert(Vt[Bt],Jt)end end
function bt:_get_action()local Xt,Zt if self._maxcount==1 then if
self._maxargs==0 then Xt,Zt="store_true",nil else Xt,Zt="store",nil end else if
self._maxargs==0 then Xt,Zt="count",0 else Xt,Zt="append",{}end end if
self._action then Xt=self._action end if self._has_init then Zt=self._init end
if type(Xt)=="string"then Xt=it[Xt]end return Xt,Zt end function
bt:_get_argname(ea)local ta=self._argname or self:_get_default_argname()if
type(ta)=="table"then return ta[ea]else return ta end end function
bt:_get_choices_list()return"{"..table.concat(self._choices,",").."}"end
function bt:_get_default_argname()if self._choices then return
self:_get_choices_list()else return"<"..self._name..">"end end function
gt:_get_default_argname()if self._choices then return
self:_get_choices_list()else return"<"..self:_get_default_target()..">"end end
function bt:_get_label_lines()if self._choices then
return{self:_get_choices_list()}else return{self._name}end end function
gt:_get_label_lines()local aa=self:_get_argument_list()if#aa==0 then
return{table.concat(self._public_aliases,", ")}end local oa=-1 for ia,na in
ipairs(self._public_aliases)do oa=math.max(oa,#na)end local
sa=table.concat(aa," ")local ha={}for ra,da in ipairs(self._public_aliases)do
local la=(" "):rep(oa-#da)..da.." "..sa if ra~=#self._public_aliases then
la=la..","end table.insert(ha,la)end return ha end function
vt:_get_label_lines()return{table.concat(self._public_aliases,", ")}end
function bt:_get_description()if self._default and self._show_default then if
self._description then
return("%s (default: %s)"):format(self._description,self._default)else
return("default: %s"):format(self._default)end else return self._description
or""end end function vt:_get_description()return self._summary or
self._description or""end function gt:_get_usage()local
ua=self:_get_argument_list()table.insert(ua,1,self._name)ua=table.concat(ua," ")if
self._mincount==0 or self._default then ua="["..ua.."]"end return ua end
function bt:_get_default_target()return self._name end function
gt:_get_default_target()local ca for ma,fa in ipairs(self._public_aliases)do if
fa:sub(1,1)==fa:sub(2,2)then ca=fa:sub(3)break end end ca=ca or
self._name:sub(2)return(ca:gsub("-","_"))end function gt:_is_vararg()return
self._maxargs~=self._minargs end function pt:_get_fullname(wa)local
ya=self._parent if wa and not ya then return""end local pa={self._name}while ya
do if not wa or ya._parent then table.insert(pa,1,ya._name)end ya=ya._parent
end return table.concat(pa," ")end function pt:_update_charset(va)va=va or{}for
ba,ga in ipairs(self._commands)do ga:_update_charset(va)end for ka,qa in
ipairs(self._options)do for ka,ja in ipairs(qa._aliases)do va[ja:sub(1,1)]=true
end end return va end function pt:argument(...)local
xa=bt(...)table.insert(self._arguments,xa)return xa end function
pt:option(...)local za=gt(...)table.insert(self._options,za)return za end
function pt:flag(...)return self:option():args(0)(...)end function
pt:command(...)local Ea=vt():add_help(true)(...)Ea._parent=self
table.insert(self._commands,Ea)return Ea end function pt:mutex(...)local
Ta={...}for Aa,Oa in ipairs(Ta)do local Ia=getmetatable(Oa)assert(Ia==gt or
Ia==bt,("bad argument #%d to 'mutex' (Option or Argument expected)"):format(Aa))end
table.insert(self._mutexes,Ta)return self end function
pt:group(Na,...)assert(type(Na)=="string",("bad argument #1 to 'group' (string expected, got %s)"):format(type(Na)))local
Sa={name=Na,...}for Ha,Ra in ipairs(Sa)do local
Da=getmetatable(Ra)assert(Da==gt or Da==bt or
Da==vt,("bad argument #%d to 'group' (Option or Argument or Command expected)"):format(Ha+1))end
table.insert(self._groups,Sa)return self end local La="Usage: "function
pt:get_usage()if self._usage then return self._usage end local
Ua=self:_inherit_property("usage_margin",#La)local
Ca=self:_inherit_property("usage_max_width",70)local
Ma={La..self:_get_fullname()}local function Fa(Wa)if#Ma[#Ma]+1+#Wa<=Ca then
Ma[#Ma]=Ma[#Ma].." "..Wa else Ma[#Ma+1]=(" "):rep(Ua)..Wa end end local
Ya={}local Pa={}local Va={}local Ba={}local function Ga(Ka,Qa)if Va[Ka]then
return end Va[Ka]=true local Ja={}for Xa,Za in ipairs(Ka)do if not Za._hidden
and not Pa[Za]then if getmetatable(Za)==gt or Za==Qa then
table.insert(Ja,Za:_get_usage())Pa[Za]=true end end end if#Ja==1 then
Fa(Ja[1])elseif#Ja>1 then Fa("("..table.concat(Ja," | ")..")")end end local
function eo(to)if not to._hidden and not Pa[to]then
Fa(to:_get_usage())Pa[to]=true end end for ao,oo in ipairs(self._mutexes)do
local no=false local so=false for ao,ho in ipairs(oo)do if getmetatable(ho)==gt
then if ho:_is_vararg()then no=true end else so=true
Ba[ho]=Ba[ho]or{}table.insert(Ba[ho],oo)end Ya[ho]=true end if not no and not
so then Ga(oo)end end for ro,lo in ipairs(self._options)do if not Ya[lo]and not
lo:_is_vararg()then eo(lo)end end for uo,co in ipairs(self._arguments)do local
mo if Ya[co]then for uo,fo in ipairs(Ba[co])do if not Va[fo]then mo=fo end end
end if mo then Ga(mo,co)else eo(co)end end for wo,yo in ipairs(self._mutexes)do
Ga(yo)end for po,vo in ipairs(self._options)do eo(vo)end if#self._commands>0
then if self._require_command then Fa("<command>")else Fa("[<command>]")end
Fa("...")end return table.concat(Ma,"\n")end local function bo(go)if go==""then
return{}end local ko={}if go:sub(-1)~="\n"then go=go.."\n"end for qo in
go:gmatch("([^\n]*)\n")do table.insert(ko,qo)end return ko end local function
jo(xo,zo)local Eo={}local To=xo:match("^ *")if xo:find("^ *[%*%+%-]")then
To=To.." "..xo:match("^ *[%*%+%-]( *)")end local Ao={}local Oo=0 local Io=1
while true do local No,So,Ho=xo:find("([^ ]+)",Io)if not No then break end
local Ro=xo:sub(Io,No-1)Io=So+1 if(#Ao==0)or(Oo+#Ro+#Ho<=zo)then
table.insert(Ao,Ro)table.insert(Ao,Ho)Oo=Oo+#Ro+#Ho else
table.insert(Eo,table.concat(Ao))Ao={To,Ho}Oo=#To+#Ho end end if#Ao>0 then
table.insert(Eo,table.concat(Ao))end if#Eo==0 then Eo[1]=""end return Eo end
local function Do(Lo,Uo)local Co={}for Mo,Fo in ipairs(Lo)do local
Wo=jo(Fo,Uo)for Mo,Yo in ipairs(Wo)do table.insert(Co,Yo)end end return Co end
function pt:_get_element_help(Po)local Vo=Po:_get_label_lines()local
Bo=bo(Po:_get_description())local Go={}local
Ko=self:_inherit_property("help_usage_margin",1)local Qo=(" "):rep(Ko)local
Jo=self:_inherit_property("help_description_margin",23)local
Xo=(" "):rep(Jo)local Zo=self:_inherit_property("help_max_width")if Zo then
local ei=math.max(Zo-Jo,10)Bo=Do(Bo,ei)end if#Vo[1]>=(Jo-Ko)then for ti,ai in
ipairs(Vo)do table.insert(Go,Qo..ai)end for oi,ii in ipairs(Bo)do
table.insert(Go,Xo..ii)end else for ni=1,math.max(#Vo,#Bo)do local
si=Vo[ni]local hi=Bo[ni]local ri=""if si then ri=Qo..si end if hi and
hi~=""then ri=ri..(" "):rep(Jo-#ri)..hi end table.insert(Go,ri)end end return
table.concat(Go,"\n")end local function di(li)local ui={}for ci,mi in
ipairs(li)do ui[getmetatable(mi)]=true end return ui end function
pt:_add_group_help(fi,wi,yi,pi)local vi={yi}for bi,gi in ipairs(pi)do if not
gi._hidden and not wi[gi]then wi[gi]=true
table.insert(vi,self:_get_element_help(gi))end end if#vi>1 then
table.insert(fi,table.concat(vi,("\n"):rep(self:_inherit_property("help_vertical_space",0)+1)))end
end function pt:get_help()if self._help then return self._help end local
ki={self:get_usage()}local qi=self:_inherit_property("help_max_width")if
self._description then local ji=self._description if qi then
ji=table.concat(Do(bo(ji),qi),"\n")end table.insert(ki,ji)end local
xi={[bt]={},[gt]={},[vt]={}}for zi,Ei in ipairs(self._groups)do local
Ti=di(Ei)for zi,Ai in ipairs({bt,gt,vt})do if Ti[Ai]then
table.insert(xi[Ai],Ei)break end end end local
Oi={{name="Arguments",type=bt,elements=self._arguments},{name="Options",type=gt,elements=self._options},{name="Commands",type=vt,elements=self._commands}}local
Ii={}for Ni,Si in ipairs(Oi)do local Hi=xi[Si.type]for Ni,Ri in ipairs(Hi)do
self:_add_group_help(ki,Ii,Ri.name..":",Ri)end local Di=Si.name..":"if#Hi>0
then Di="Other "..Di:gsub("^.",string.lower)end
self:_add_group_help(ki,Ii,Di,Si.elements)end if self._epilog then local
Li=self._epilog if qi then Li=table.concat(Do(bo(Li),qi),"\n")end
table.insert(ki,Li)end return table.concat(ki,"\n\n")end function
pt:add_help_command(Ui)if Ui then assert(type(Ui)=="string"or
type(Ui)=="table",("bad argument #1 to 'add_help_command' (string or table expected, got %s)"):format(type(Ui)))end
local
Ci=self:command():description"Show help for commands."Ci:argument"command":description"The command to show help for.":args"?":action(function(Mi,Mi,Fi)if
not Fi then print(self:get_help())error()else for Mi,Wi in
ipairs(self._commands)do for Mi,Yi in ipairs(Wi._aliases)do if Yi==Fi then
print(Wi:get_help())error()end end end end
Ci:error(("unknown command '%s'"):format(Fi))end)if Ui then Ci=Ci(Ui)end if not
Ci._name then Ci"help"end Ci._is_help_command=true return self end function
pt:_is_shell_safe()if self._basename then if
self._basename:find("[^%w_%-%+%.]")then return false end else for Pi,Vi in
ipairs(self._aliases)do if Vi:find("[^%w_%-%+%.]")then return false end end end
for Bi,Gi in ipairs(self._options)do for Bi,Ki in ipairs(Gi._aliases)do if
Ki:find("[^%w_%-%+%.]")then return false end end if Gi._choices then for Bi,Qi
in ipairs(Gi._choices)do if Qi:find("[%s'\"]")then return false end end end end
for Ji,Xi in ipairs(self._arguments)do if Xi._choices then for Ji,Zi in
ipairs(Xi._choices)do if Zi:find("[%s'\"]")then return false end end end end
for en,tn in ipairs(self._commands)do if not tn:_is_shell_safe()then return
false end end return true end function pt:add_complete(an)if an then
assert(type(an)=="string"or
type(an)=="table",("bad argument #1 to 'add_complete' (string or table expected, got %s)"):format(type(an)))end
local
on=self:option():description"Output a shell completion script for the specified shell.":args(1):choices{"bash","zsh","fish"}:action(function(nn,nn,sn)io.write(self["get_"..sn.."_complete"](self))error()end)if
an then on=on(an)end if not on._name then on"--completion"end return self end
function pt:add_complete_command(hn)if hn then assert(type(hn)=="string"or
type(hn)=="table",("bad argument #1 to 'add_complete_command' (string or table expected, got %s)"):format(type(hn)))end
local
rn=self:command():description"Output a shell completion script."rn:argument"shell":description"The shell to output a completion script for.":choices{"bash","zsh","fish"}:action(function(dn,dn,ln)io.write(self["get_"..ln.."_complete"](self))error()end)if
hn then rn=rn(hn)end if not rn._name then rn"completion"end return self end
local function un(cn)return cn:gsub("[/\\]*$",""):match(".*[/\\]([^/\\]*)")or
cn end local function mn(fn)local
wn=fn:_get_description():match("^(.-)%.%s")return wn or
fn:_get_description():match("^(.-)%.?$")end function pt:_get_options()local
yn={}for pn,vn in ipairs(self._options)do for pn,bn in ipairs(vn._aliases)do
table.insert(yn,bn)end end return table.concat(yn," ")end function
pt:_get_commands()local gn={}for kn,qn in ipairs(self._commands)do for kn,jn in
ipairs(qn._aliases)do table.insert(gn,jn)end end return table.concat(gn," ")end
function pt:_bash_option_args(xn,zn)local En={}for Tn,An in
ipairs(self._options)do if An._choices or An._minargs>0 then local On if
An._choices then
On='COMPREPLY=($(compgen -W "'..table.concat(An._choices," ")..'" -- "$cur"))'else
On='COMPREPLY=($(compgen -f -- "$cur"))'end
table.insert(En,(" "):rep(zn+4)..table.concat(An._aliases,"|")..")")table.insert(En,(" "):rep(zn+8)..On)table.insert(En,(" "):rep(zn+8).."return 0")table.insert(En,(" "):rep(zn+8)..";;")end
end if#En>0 then
table.insert(xn,(" "):rep(zn)..'case "$prev" in')table.insert(xn,table.concat(En,"\n"))table.insert(xn,(" "):rep(zn).."esac\n")end
end function pt:_bash_get_cmd(In,Nn)if#self._commands==0 then return end
table.insert(In,(" "):rep(Nn)..'args=("${args[@]:1}")')table.insert(In,(" "):rep(Nn)..'for arg in "${args[@]}"; do')table.insert(In,(" "):rep(Nn+4)..'case "$arg" in')for
Sn,Hn in ipairs(self._commands)do
table.insert(In,(" "):rep(Nn+8)..table.concat(Hn._aliases,"|")..")")if
self._parent then
table.insert(In,(" "):rep(Nn+12)..'cmd="$cmd '..Hn._name..'"')else
table.insert(In,(" "):rep(Nn+12)..'cmd="'..Hn._name..'"')end
table.insert(In,(" "):rep(Nn+12)..'opts="$opts '..Hn:_get_options()..'"')Hn:_bash_get_cmd(In,Nn+12)table.insert(In,(" "):rep(Nn+12).."break")table.insert(In,(" "):rep(Nn+12)..";;")end
table.insert(In,(" "):rep(Nn+4).."esac")table.insert(In,(" "):rep(Nn).."done")end
function pt:_bash_cmd_completions(Rn)local Dn={}if self._parent then
self:_bash_option_args(Dn,12)end if#self._commands>0 then
table.insert(Dn,(" "):rep(12)..'COMPREPLY=($(compgen -W "'..self:_get_commands()..'" -- "$cur"))')elseif
self._is_help_command then
table.insert(Dn,(" "):rep(12)..'COMPREPLY=($(compgen -W "'..self._parent:_get_commands()..'" -- "$cur"))')end
if#Dn>0 then
table.insert(Rn,(" "):rep(8).."'"..self:_get_fullname(true).."')")table.insert(Rn,table.concat(Dn,"\n"))table.insert(Rn,(" "):rep(12)..";;")end
for Ln,Un in ipairs(self._commands)do Un:_bash_cmd_completions(Rn)end end
function
pt:get_bash_complete()self._basename=un(self._name)assert(self:_is_shell_safe())local
Cn={([[
_%s() {
    local IFS=$' \t\n'
    local args cur prev cmd opts arg
    args=("${COMP_WORDS[@]}")
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="%s"
]]):format(self._basename,self:_get_options())}self:_bash_option_args(Cn,4)self:_bash_get_cmd(Cn,4)if#self._commands>0
then
table.insert(Cn,"")table.insert(Cn,(" "):rep(4)..'case "$cmd" in')self:_bash_cmd_completions(Cn)table.insert(Cn,(" "):rep(4).."esac\n")end
table.insert(Cn,([=[
    if [[ "$cur" = -* ]]; then
        COMPREPLY=($(compgen -W "$opts" -- "$cur"))
    fi
}

complete -F _%s -o bashdefault -o default %s
]=]):format(self._basename,self._basename))return
table.concat(Cn,"\n")end function pt:_zsh_arguments(Mn,Fn,Wn)if self._parent
then
table.insert(Mn,(" "):rep(Wn).."options=(")table.insert(Mn,(" "):rep(Wn+2).."$options")else
table.insert(Mn,(" "):rep(Wn).."local -a options=(")end for Yn,Pn in
ipairs(self._options)do local Vn={}if#Pn._aliases>1 then if Pn._maxcount>1 then
table.insert(Vn,'"*"')end
table.insert(Vn,"{"..table.concat(Pn._aliases,",")..'}"')else
table.insert(Vn,'"')if Pn._maxcount>1 then table.insert(Vn,"*")end
table.insert(Vn,Pn._name)end if Pn._description then local
Bn=mn(Pn):gsub('["%]:`$]',"\\%0")table.insert(Vn,"["..Bn.."]")end if
Pn._maxargs==math.huge then table.insert(Vn,":*")end if Pn._choices then
table.insert(Vn,": :("..table.concat(Pn._choices," ")..")")elseif Pn._maxargs>0
then table.insert(Vn,": :_files")end
table.insert(Vn,'"')table.insert(Mn,(" "):rep(Wn+2)..table.concat(Vn))end
table.insert(Mn,(" "):rep(Wn)..")")table.insert(Mn,(" "):rep(Wn).."_arguments -s -S \\")table.insert(Mn,(" "):rep(Wn+2).."$options \\")if
self._is_help_command then
table.insert(Mn,(" "):rep(Wn+2)..'": :('..self._parent:_get_commands()..')" \\')else
for Gn,Kn in ipairs(self._arguments)do local Qn if Kn._choices then
Qn=": :("..table.concat(Kn._choices," ")..")"else Qn=": :_files"end if
Kn._maxargs==math.huge then
table.insert(Mn,(" "):rep(Wn+2)..'"*'..Qn..'" \\')break end for
Gn=1,Kn._maxargs do table.insert(Mn,(" "):rep(Wn+2)..'"'..Qn..'" \\')end end
if#self._commands>0 then
table.insert(Mn,(" "):rep(Wn+2)..'": :_'..Fn..'_cmds" \\')table.insert(Mn,(" "):rep(Wn+2)..'"*:: :->args" \\')end
end table.insert(Mn,(" "):rep(Wn+2).."&& return 0")end function
pt:_zsh_cmds(Jn,Xn)table.insert(Jn,"\n_"..Xn.."_cmds() {")table.insert(Jn,"  local -a commands=(")for
Zn,es in ipairs(self._commands)do local ts={}if#es._aliases>1 then
table.insert(ts,"{"..table.concat(es._aliases,",")..'}"')else
table.insert(ts,'"'..es._name)end if es._description then
table.insert(ts,":"..mn(es):gsub('["`$]',"\\%0"))end
table.insert(Jn,"    "..table.concat(ts)..'"')end
table.insert(Jn,'  )\n  _describe "command" commands\n}')end function
pt:_zsh_complete_help(as,os,is,ns)if#self._commands==0 then return end
self:_zsh_cmds(os,is)table.insert(as,"\n"..(" "):rep(ns).."case $words[1] in")for
ss,hs in ipairs(self._commands)do local rs=is.."_"..hs._name
table.insert(as,(" "):rep(ns+2)..table.concat(hs._aliases,"|")..")")hs:_zsh_arguments(as,rs,ns+4)hs:_zsh_complete_help(as,os,rs,ns+4)table.insert(as,(" "):rep(ns+4)..";;\n")end
table.insert(as,(" "):rep(ns).."esac")end function
pt:get_zsh_complete()self._basename=un(self._name)assert(self:_is_shell_safe())local
ds={("#compdef %s\n"):format(self._basename)}local
ls={}table.insert(ds,"_"..self._basename.."() {")if#self._commands>0 then
table.insert(ds,"  local context state state_descr line")table.insert(ds,"  typeset -A opt_args\n")end
self:_zsh_arguments(ds,self._basename,2)self:_zsh_complete_help(ds,ls,self._basename,2)table.insert(ds,"\n  return 1")table.insert(ds,"}")local
us=table.concat(ds,"\n")if#ls>0 then us=us.."\n"..table.concat(ls,"\n")end
return us.."\n\n_"..self._basename.."\n"end local function cs(ms)return
ms:gsub("[\\']","\\%0")end function pt:_fish_get_cmd(fs,ws)if#self._commands==0
then return end
table.insert(fs,(" "):rep(ws).."set -e cmdline[1]")table.insert(fs,(" "):rep(ws).."for arg in $cmdline")table.insert(fs,(" "):rep(ws+4).."switch $arg")for
ys,ps in ipairs(self._commands)do
table.insert(fs,(" "):rep(ws+8).."case "..table.concat(ps._aliases," "))table.insert(fs,(" "):rep(ws+12).."set cmd $cmd "..ps._name)ps:_fish_get_cmd(fs,ws+12)table.insert(fs,(" "):rep(ws+12).."break")end
table.insert(fs,(" "):rep(ws+4).."end")table.insert(fs,(" "):rep(ws).."end")end
function pt:_fish_complete_help(vs,bs)local gs="complete -c "..bs
table.insert(vs,"")for ks,qs in ipairs(self._commands)do local
js=table.concat(qs._aliases," ")local xs if self._parent then
xs=("%s -n '__fish_%s_using_command %s' -xa '%s'"):format(gs,bs,self:_get_fullname(true),js)else
xs=("%s -n '__fish_%s_using_command' -xa '%s'"):format(gs,bs,js)end if
qs._description then xs=("%s -d '%s'"):format(xs,cs(mn(qs)))end
table.insert(vs,xs)end if self._is_help_command then local
zs=("%s -n '__fish_%s_using_command %s' -xa '%s'"):format(gs,bs,self:_get_fullname(true),self._parent:_get_commands())table.insert(vs,zs)end
for Es,Ts in ipairs(self._options)do local As={gs}if self._parent then
table.insert(As,"-n '__fish_"..bs.."_seen_command "..self:_get_fullname(true).."'")end
for Es,Os in ipairs(Ts._aliases)do if Os:match("^%-.$")then
table.insert(As,"-s "..Os:sub(2))elseif Os:match("^%-%-.+")then
table.insert(As,"-l "..Os:sub(3))end end if Ts._choices then
table.insert(As,"-xa '"..table.concat(Ts._choices," ").."'")elseif
Ts._minargs>0 then table.insert(As,"-r")end if Ts._description then
table.insert(As,"-d '"..cs(mn(Ts)).."'")end
table.insert(vs,table.concat(As," "))end for Is,Ns in ipairs(self._commands)do
Ns:_fish_complete_help(vs,bs)end end function
pt:get_fish_complete()self._basename=un(self._name)assert(self:_is_shell_safe())local
Ss={}if#self._commands>0 then
table.insert(Ss,([[
function __fish_%s_print_command
    set -l cmdline (commandline -poc)
    set -l cmd]]):format(self._basename))self:_fish_get_cmd(Ss,4)table.insert(Ss,([[
    echo "$cmd"
end

function __fish_%s_using_command
    test (__fish_%s_print_command) = "$argv"
    and return 0
    or return 1
end

function __fish_%s_seen_command
    string match -q "$argv*" (__fish_%s_print_command)
    and return 0
    or return 1
end]]):format(self._basename,self._basename,self._basename,self._basename))end
self:_fish_complete_help(Ss,self._basename)return
table.concat(Ss,"\n").."\n"end local function Hs(Rs,Ds)local Ls={}local Us
local Cs={}for Ms in pairs(Rs)do if type(Ms)=="string"then for Fs=1,#Ms do
Us=Ms:sub(1,Fs-1)..Ms:sub(Fs+1)if not Ls[Us]then Ls[Us]={}end
table.insert(Ls[Us],Ms)end end end for Ws=1,#Ds+1 do
Us=Ds:sub(1,Ws-1)..Ds:sub(Ws+1)if Rs[Us]then Cs[Us]=true elseif Ls[Us]then for
Ys,Ps in ipairs(Ls[Us])do Cs[Ps]=true end end end local Vs=next(Cs)if Vs then
if next(Cs,Vs)then local Bs={}for Gs in pairs(Cs)do
table.insert(Bs,"'"..Gs.."'")end
table.sort(Bs)return"\nDid you mean one of these: "..table.concat(Bs," ").."?"else
return"\nDid you mean '"..Vs.."'?"end else return""end end local
Ks=n({invocations=0})function Ks:__call(Qs,Js)self.state=Qs
self.result=Qs.result self.element=Js self.target=Js._target or
Js:_get_default_target()self.action,self.result[self.target]=Js:_get_action()return
self end function Ks:error(Xs,...)self.state:error(Xs,...)end function
Ks:convert(Zs,eh)local th=self.element._convert if th then local ah,oh if
type(th)=="function"then ah,oh=th(Zs)elseif type(th[eh])=="function"then
ah,oh=th[eh](Zs)else ah=th[Zs]end if ah==nil then self:error(oh
and"%s"or"malformed argument '%s'",oh or Zs)end Zs=ah end return Zs end
function Ks:default(ih)return self.element._defmode:find(ih)and
self.element._default end local function nh(sh,hh,rh,dh)local lh=""if hh~=rh
then lh="at "..(dh and"most"or"least").." "end local uh=dh and rh or hh return
lh..tostring(uh).." "..sh..(uh==1 and""or"s")end function
Ks:set_name(ch)self.name=("%s '%s'"):format(ch and"option"or"argument",ch or
self.element._name)end function Ks:invoke()self.open=true self.overwrite=false
if self.invocations>=self.element._maxcount then if self.element._overwrite
then self.overwrite=true else local
mh=nh("time",self.element._mincount,self.element._maxcount,true)self:error("%s must be used %s",self.name,mh)end
else self.invocations=self.invocations+1 end self.args={}if
self.element._maxargs<=0 then self:close()end return self.open end function
Ks:check_choices(fh)if self.element._choices then for wh,yh in
ipairs(self.element._choices)do if fh==yh then return end end local
ph="'"..table.concat(self.element._choices,"', '").."'"local
vh=getmetatable(self.element)==gt self:error("%s%s must be one of %s",vh
and"argument for "or"",self.name,ph)end end function
Ks:pass(bh)self:check_choices(bh)bh=self:convert(bh,#self.args+1)table.insert(self.args,bh)if#self.args>=self.element._maxargs
then self:close()end return self.open end function
Ks:complete_invocation()while#self.args<self.element._minargs do
self:pass(self.element._default)end end function Ks:close()if self.open then
self.open=false if#self.args<self.element._minargs then if
self:default("a")then self:complete_invocation()else if#self.args==0 then if
getmetatable(self.element)==bt then self:error("missing %s",self.name)elseif
self.element._maxargs==1 then
self:error("%s requires an argument",self.name)end end
self:error("%s requires %s",self.name,nh("argument",self.element._minargs,self.element._maxargs))end
end local gh if self.element._maxargs==0 then gh=self.args[1]elseif
self.element._maxargs==1 then if self.element._minargs==0 and
self.element._mincount~=self.element._maxcount then gh=self.args else
gh=self.args[1]end else gh=self.args end
self.action(self.result,self.target,gh,self.overwrite)end end local
kh=n({result={},options={},arguments={},argument_i=1,element_to_mutexes={},mutex_to_element_state={},command_actions={}})function
kh:__call(qh,jh)self.parser=qh self.error_handler=jh
self.charset=qh:_update_charset()self:switch(qh)return self end function
kh:error(xh,...)self.error_handler(self.parser,xh:format(...))end function
kh:switch(zh)self.parser=zh if zh._action then
table.insert(self.command_actions,{action=zh._action,name=zh._name})end for
Eh,Th in ipairs(zh._options)do Th=Ks(self,Th)table.insert(self.options,Th)for
Eh,Ah in ipairs(Th.element._aliases)do self.options[Ah]=Th end end for Oh,Ih in
ipairs(zh._mutexes)do for Oh,Nh in ipairs(Ih)do if not
self.element_to_mutexes[Nh]then self.element_to_mutexes[Nh]={}end
table.insert(self.element_to_mutexes[Nh],Ih)end end for Sh,Hh in
ipairs(zh._arguments)do
Hh=Ks(self,Hh)table.insert(self.arguments,Hh)Hh:set_name()Hh:invoke()end
self.handle_options=zh._handle_options
self.argument=self.arguments[self.argument_i]self.commands=zh._commands for
Rh,Dh in ipairs(self.commands)do for Rh,Lh in ipairs(Dh._aliases)do
self.commands[Lh]=Dh end end end function kh:get_option(Uh)local
Ch=self.options[Uh]if not Ch then
self:error("unknown option '%s'%s",Uh,Hs(self.options,Uh))else return Ch end
end function kh:get_command(Mh)local Fh=self.commands[Mh]if not Fh then
if#self.commands>0 then
self:error("unknown command '%s'%s",Mh,Hs(self.commands,Mh))else
self:error("too many arguments")end else return Fh end end function
kh:check_mutexes(Wh)if self.element_to_mutexes[Wh.element]then for Yh,Ph in
ipairs(self.element_to_mutexes[Wh.element])do local
Vh=self.mutex_to_element_state[Ph]if Vh and Vh~=Wh then
self:error("%s can not be used together with %s",Wh.name,Vh.name)else
self.mutex_to_element_state[Ph]=Wh end end end end function
kh:invoke(Bh,Gh)self:close()Bh:set_name(Gh)self:check_mutexes(Bh,Gh)if
Bh:invoke()then self.option=Bh end end function kh:pass(Kh)if self.option then
if not self.option:pass(Kh)then self.option=nil end elseif self.argument then
self:check_mutexes(self.argument)if not self.argument:pass(Kh)then
self.argument_i=self.argument_i+1
self.argument=self.arguments[self.argument_i]end else local
Qh=self:get_command(Kh)self.result[Qh._target or Qh._name]=true if
self.parser._command_target then
self.result[self.parser._command_target]=Qh._name end self:switch(Qh)end end
function kh:close()if self.option then self.option:close()self.option=nil end
end function kh:finalize()self:close()for Jh=self.argument_i,#self.arguments do
local Xh=self.arguments[Jh]if#Xh.args==0 and Xh:default("u")then
Xh:complete_invocation()else Xh:close()end end if self.parser._require_command
and#self.commands>0 then self:error("a command is required")end for Zh,er in
ipairs(self.options)do er.name=er.name
or("option '%s'"):format(er.element._name)if er.invocations==0 then if
er:default("u")then er:invoke()er:complete_invocation()er:close()end end local
tr=er.element._mincount if er.invocations<tr then if er:default("a")then while
er.invocations<tr do er:invoke()er:close()end elseif er.invocations==0 then
self:error("missing %s",er.name)else
self:error("%s must be used %s",er.name,nh("time",tr,er.element._maxcount))end
end end for ar=#self.command_actions,1,-1 do
self.command_actions[ar].action(self.result,self.command_actions[ar].name)end
end function kh:parse(ir)for nr,sr in ipairs(ir)do local hr=true if
self.handle_options then local rr=sr:sub(1,1)if self.charset[rr]then if#sr>1
then hr=false if sr:sub(2,2)==rr then if#sr==2 then if self.options[sr]then
local dr=self:get_option(sr)self:invoke(dr,sr)else self:close()end
self.handle_options=false else local lr=sr:find"="if lr then local
ur=sr:sub(1,lr-1)local cr=self:get_option(ur)if cr.element._maxargs<=0 then
self:error("option '%s' does not take arguments",ur)end
self:invoke(cr,ur)self:pass(sr:sub(lr+1))else local
mr=self:get_option(sr)self:invoke(mr,sr)end end else for fr=2,#sr do local
wr=rr..sr:sub(fr,fr)local yr=self:get_option(wr)self:invoke(yr,wr)if fr~=#sr
and yr.element._maxargs>0 then self:pass(sr:sub(fr+1))break end end end end end
end if hr then self:pass(sr)end end self:finalize()return self.result end
function
pt:error(pr)io.stderr:write(("%s\n\nError: %s\n"):format(self:get_usage(),pr))error()end
local vr=rawget(_G,"arg")or{}function pt:_parse(br,gr)return
kh(self,gr):parse(br or vr)end function pt:parse(kr)return
self:_parse(kr,self.error)end local function qr(jr)return
tostring(jr).."\noriginal "..debug.traceback("",2):sub(2)end function
pt:pparse(xr)local zr local Er,Tr=xpcall(function()return
self:_parse(xr,function(Ar,Or)zr=Or error(Or,0)end)end,qr)if Er then return
true,Tr elseif not zr then error(Tr,0)else return false,zr end end local
Ir={}Ir.version="0.7.3"setmetatable(Ir,{__call=function(Nr,...)return
pt(vr[0]):add_help(true)(...)end})return
Ir
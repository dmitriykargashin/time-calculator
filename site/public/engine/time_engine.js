(function dartProgram(){function copyProperties(a,b){var t=Object.keys(a)
for(var s=0;s<t.length;s++){var r=t[s]
b[r]=a[r]}}function mixinPropertiesHard(a,b){var t=Object.keys(a)
for(var s=0;s<t.length;s++){var r=t[s]
if(!b.hasOwnProperty(r)){b[r]=a[r]}}}function mixinPropertiesEasy(a,b){Object.assign(b,a)}var z=function(){var t=function(){}
t.prototype={p:{}}
var s=new t()
if(!(Object.getPrototypeOf(s)&&Object.getPrototypeOf(s).p===t.prototype.p))return false
try{if(typeof navigator!="undefined"&&typeof navigator.userAgent=="string"&&navigator.userAgent.indexOf("Chrome/")>=0)return true
if(typeof version=="function"&&version.length==0){var r=version()
if(/^\d+\.\d+\.\d+\.\d+$/.test(r))return true}}catch(q){}return false}()
function inherit(a,b){a.prototype.constructor=a
a.prototype["$i"+a.name]=a
if(b!=null){if(z){Object.setPrototypeOf(a.prototype,b.prototype)
return}var t=Object.create(b.prototype)
copyProperties(a.prototype,t)
a.prototype=t}}function inheritMany(a,b){for(var t=0;t<b.length;t++){inherit(b[t],a)}}function mixinEasy(a,b){mixinPropertiesEasy(b.prototype,a.prototype)
a.prototype.constructor=a}function mixinHard(a,b){mixinPropertiesHard(b.prototype,a.prototype)
a.prototype.constructor=a}function lazy(a,b,c,d){var t=a
a[b]=t
a[c]=function(){if(a[b]===t){a[b]=d()}a[c]=function(){return this[b]}
return a[b]}}function lazyFinal(a,b,c,d){var t=a
a[b]=t
a[c]=function(){if(a[b]===t){var s=d()
if(a[b]!==t){A.fc(b)}a[b]=s}var r=a[b]
a[c]=function(){return r}
return r}}function makeConstList(a,b){if(b!=null)A.E(a,b)
a.$flags=7
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var t=0;t<a.length;++t){convertToFastObject(a[t])}}var y=0
function instanceTearOffGetter(a,b){var t=null
return a?function(c){if(t===null)t=A.c4(b)
return new t(c,this)}:function(){if(t===null)t=A.c4(b)
return new t(this,null)}}function staticTearOffGetter(a){var t=null
return function(){if(t===null)t=A.c4(a).prototype
return t}}var x=0
function tearOffParameters(a,b,c,d,e,f,g,h,i,j){if(typeof h=="number"){h+=x}return{co:a,iS:b,iI:c,rC:d,dV:e,cs:f,fs:g,fT:h,aI:i||0,nDA:j}}function installStaticTearOff(a,b,c,d,e,f,g,h){var t=tearOffParameters(a,true,false,c,d,e,f,g,h,false)
var s=staticTearOffGetter(t)
a[b]=s}function installInstanceTearOff(a,b,c,d,e,f,g,h,i,j){c=!!c
var t=tearOffParameters(a,false,c,d,e,f,g,h,i,!!j)
var s=instanceTearOffGetter(c,t)
a[b]=s}function setOrUpdateInterceptorsByTag(a){var t=v.interceptorsByTag
if(!t){v.interceptorsByTag=a
return}copyProperties(a,t)}function setOrUpdateLeafTags(a){var t=v.leafTags
if(!t){v.leafTags=a
return}copyProperties(a,t)}function updateTypes(a){var t=v.types
var s=t.length
t.push.apply(t,a)
return s}function updateHolder(a,b){copyProperties(b,a)
return a}var hunkHelpers=function(){var t=function(a,b,c,d,e){return function(f,g,h,i){return installInstanceTearOff(f,g,a,b,c,d,[h],i,e,false)}},s=function(a,b,c,d){return function(e,f,g,h){return installStaticTearOff(e,f,a,b,c,[g],h,d)}}
return{inherit:inherit,inheritMany:inheritMany,mixin:mixinEasy,mixinHard:mixinHard,installStaticTearOff:installStaticTearOff,installInstanceTearOff:installInstanceTearOff,_instance_0u:t(0,0,null,["$0"],0),_instance_1u:t(0,1,null,["$1"],0),_instance_2u:t(0,2,null,["$2"],0),_instance_0i:t(1,0,null,["$0"],0),_instance_1i:t(1,1,null,["$1"],0),_instance_2i:t(1,2,null,["$2"],0),_static_0:s(0,null,["$0"],0),_static_1:s(1,null,["$1"],0),_static_2:s(2,null,["$2"],0),makeConstList:makeConstList,lazy:lazy,lazyFinal:lazyFinal,updateHolder:updateHolder,convertToFastObject:convertToFastObject,updateTypes:updateTypes,setOrUpdateInterceptorsByTag:setOrUpdateInterceptorsByTag,setOrUpdateLeafTags:setOrUpdateLeafTags}}()
function initializeDeferredHunk(a){x=v.types.length
a(hunkHelpers,v,w,$)}var J={
c7(a,b,c,d){return{i:a,p:b,e:c,x:d}},
bB(a){var t,s,r,q,p,o=a[v.dispatchPropertyName]
if(o==null)if($.c6==null){A.f0()
o=a[v.dispatchPropertyName]}if(o!=null){t=o.p
if(!1===t)return o.i
if(!0===t)return a
s=Object.getPrototypeOf(a)
if(t===s)return o.i
if(o.e===s)throw A.b(A.cs("Return interceptor for "+A.d(t(a,o))))}r=a.constructor
if(r==null)q=null
else{p=$.bq
if(p==null)p=$.bq=v.getIsolateTag("_$dart_js")
q=r[p]}if(q!=null)return q
q=A.f5(a)
if(q!=null)return q
if(typeof a=="function")return B.K
t=Object.getPrototypeOf(a)
if(t==null)return B.A
if(t===Object.prototype)return B.A
if(typeof r=="function"){p=$.bq
if(p==null)p=$.bq=v.getIsolateTag("_$dart_js")
Object.defineProperty(r,p,{value:B.w,enumerable:false,writable:true,configurable:true})
return B.w}return B.w},
cn(a){if(a<256)switch(a){case 9:case 10:case 11:case 12:case 13:case 32:case 133:case 160:return!0
default:return!1}switch(a){case 5760:case 8192:case 8193:case 8194:case 8195:case 8196:case 8197:case 8198:case 8199:case 8200:case 8201:case 8202:case 8232:case 8233:case 8239:case 8287:case 12288:case 65279:return!0
default:return!1}},
dz(a,b){var t,s
for(t=a.length;b<t;){s=a.charCodeAt(b)
if(s!==32&&s!==13&&!J.cn(s))break;++b}return b},
dA(a,b){var t,s,r
for(t=a.length;b>0;b=s){s=b-1
if(!(s<t))return A.a(a,s)
r=a.charCodeAt(s)
if(r!==32&&r!==13&&!J.cn(r))break}return b},
a6(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.af.prototype
return J.aL.prototype}if(typeof a=="string")return J.a_.prototype
if(a==null)return J.ag.prototype
if(typeof a=="boolean")return J.aK.prototype
if(Array.isArray(a))return J.v.prototype
if(typeof a!="object"){if(typeof a=="function")return J.G.prototype
if(typeof a=="symbol")return J.a1.prototype
if(typeof a=="bigint")return J.a0.prototype
return a}if(a instanceof A.p)return a
return J.bB(a)},
b1(a){if(typeof a=="string")return J.a_.prototype
if(a==null)return a
if(Array.isArray(a))return J.v.prototype
if(typeof a!="object"){if(typeof a=="function")return J.G.prototype
if(typeof a=="symbol")return J.a1.prototype
if(typeof a=="bigint")return J.a0.prototype
return a}if(a instanceof A.p)return a
return J.bB(a)},
eV(a){if(a==null)return a
if(Array.isArray(a))return J.v.prototype
if(typeof a!="object"){if(typeof a=="function")return J.G.prototype
if(typeof a=="symbol")return J.a1.prototype
if(typeof a=="bigint")return J.a0.prototype
return a}if(a instanceof A.p)return a
return J.bB(a)},
eW(a){if(a==null)return a
if(typeof a!="object"){if(typeof a=="function")return J.G.prototype
if(typeof a=="symbol")return J.a1.prototype
if(typeof a=="bigint")return J.a0.prototype
return a}if(a instanceof A.p)return a
return J.bB(a)},
di(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.a6(a).ag(a,b)},
dj(a){return J.eW(a).a9(a)},
dk(a){return J.eV(a).gM(a)},
U(a){return J.b1(a).gk(a)},
dl(a){return J.a6(a).gu(a)},
aa(a){return J.a6(a).h(a)},
aI:function aI(){},
aK:function aK(){},
ag:function ag(){},
aj:function aj(){},
L:function L(){},
aQ:function aQ(){},
as:function as(){},
G:function G(){},
a0:function a0(){},
a1:function a1(){},
v:function v(a){this.$ti=a},
aJ:function aJ(){},
bc:function bc(a){this.$ti=a},
aD:function aD(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
ah:function ah(){},
af:function af(){},
aL:function aL(){},
a_:function a_(){}},A={bO:function bO(){},
d2(a){var t,s
for(t=$.I.length,s=0;s<t;++s)if(a===$.I[s])return!0
return!1},
cl(){return new A.bg("No element")},
aN:function aN(a){this.a=a},
ac:function ac(){},
ak:function ak(){},
f:function f(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
Y:function Y(){},
ap:function ap(a,b){this.a=a
this.$ti=b},
d5(a){var t=v.mangledGlobalNames[a]
if(t!=null)return t
return"minified:"+a},
fC(a,b){var t
if(b!=null){t=b.x
if(t!=null)return t}return u.p.b(a)},
d(a){var t
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
t=J.aa(a)
return t},
dG(a,b){var t,s=/^\s*[+-]?((0x[a-f0-9]+)|(\d+)|([a-z0-9]+))\s*$/i.exec(a)
if(s==null)return null
if(3>=s.length)return A.a(s,3)
t=s[3]
if(t!=null)return parseInt(a,10)
if(s[2]!=null)return parseInt(a,16)
return null},
cp(a){var t,s
if(!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(a))return null
t=parseFloat(a)
if(isNaN(t)){s=B.c.af(a)
if(s==="NaN"||s==="+NaN"||s==="-NaN")return t
return null}return t},
aR(a){var t,s,r,q
if(a instanceof A.p)return A.A(A.S(a),null)
t=J.a6(a)
if(t===B.J||t===B.L||u.o.b(a)){s=B.y(a)
if(s!=="Object"&&s!=="")return s
r=a.constructor
if(typeof r=="function"){q=r.name
if(typeof q=="string"&&q!=="Object"&&q!=="")return q}}return A.A(A.S(a),null)},
dH(a){var t,s,r
if(typeof a=="number"||A.c3(a))return J.aa(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.K)return a.h(0)
t=$.db()
for(s=0;s<1;++s){r=t[s].aF(a)
if(r!=null)return r}return"Instance of '"+A.aR(a)+"'"},
a(a,b){if(a==null)J.U(a)
throw A.b(A.c5(a,b))},
c5(a,b){var t,s="index"
if(!A.cT(b))return new A.V(!0,b,s,null)
t=A.a3(J.U(a))
if(b<0||b>=t)return A.dx(b,t,a,s)
return A.dI(b,s)},
cY(a){return new A.V(!0,a,null,null)},
b(a){return A.u(a,new Error())},
u(a,b){var t
if(a==null)a=new A.bj()
b.dartException=a
t=A.fd
if("defineProperty" in Object){Object.defineProperty(b,"message",{get:t})
b.name=""}else b.toString=t
return b},
fd(){return J.aa(this.dartException)},
F(a,b){throw A.u(a,b==null?new Error():b)},
j(a,b,c){var t
if(b==null)b=0
if(c==null)c=0
t=Error()
A.F(A.er(a,b,c),t)},
er(a,b,c){var t,s,r,q,p,o,n,m,l
if(typeof b=="string")t=b
else{s="[]=;add;removeWhere;retainWhere;removeRange;setRange;setInt8;setInt16;setInt32;setUint8;setUint16;setUint32;setFloat32;setFloat64".split(";")
r=s.length
q=b
if(q>r){c=q/r|0
q%=r}t=s[q]}p=typeof c=="string"?c:"modify;remove from;add to".split(";")[c]
o=u.j.b(a)?"list":"ByteData"
n=a.$flags|0
m="a "
if((n&4)!==0)l="constant "
else if((n&2)!==0){l="unmodifiable "
m="an "}else l=(n&1)!==0?"fixed-length ":""
return new A.aW("'"+t+"': Cannot "+p+" "+m+l+o)},
fb(a){throw A.b(A.bN(a))},
dw(a1){var t,s,r,q,p,o,n,m,l,k,j=a1.co,i=a1.iS,h=a1.iI,g=a1.nDA,f=a1.aI,e=a1.fs,d=a1.cs,c=e[0],b=d[0],a=j[c],a0=a1.fT
a0.toString
t=i?Object.create(new A.aU().constructor.prototype):Object.create(new A.ab(null,null).constructor.prototype)
t.$initialize=t.constructor
s=i?function static_tear_off(){this.$initialize()}:function tear_off(a2,a3){this.$initialize(a2,a3)}
t.constructor=s
s.prototype=t
t.$_name=c
t.$_target=a
r=!i
if(r)q=A.cj(c,a,h,g)
else{t.$static_name=c
q=a}t.$S=A.ds(a0,i,h)
t[b]=q
for(p=q,o=1;o<e.length;++o){n=e[o]
if(typeof n=="string"){m=j[n]
l=n
n=m}else l=""
k=d[o]
if(k!=null){if(r)n=A.cj(l,n,h,g)
t[k]=n}if(o===f)p=n}t.$C=p
t.$R=a1.rC
t.$D=a1.dV
return s},
ds(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.b("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.dp)}throw A.b("Error in functionType of tearoff")},
dt(a,b,c,d){var t=A.cg
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,t)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,t)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,t)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,t)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,t)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,t)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,t)}},
cj(a,b,c,d){if(c)return A.dv(a,b,d)
return A.dt(b.length,d,a,b)},
du(a,b,c,d){var t=A.cg,s=A.dq
switch(b?-1:a){case 0:throw A.b(new A.bf("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,s,t)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,s,t)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,s,t)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,s,t)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,s,t)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,s,t)
default:return function(e,f,g){return function(){var r=[g(this)]
Array.prototype.push.apply(r,arguments)
return e.apply(f(this),r)}}(d,s,t)}},
dv(a,b,c){var t,s
if($.ce==null)$.ce=A.cd("interceptor")
if($.cf==null)$.cf=A.cd("receiver")
t=b.length
s=A.du(t,c,a,b)
return s},
c4(a){return A.dw(a)},
dp(a,b){return A.bu(v.typeUniverse,A.S(a.a),b)},
cg(a){return a.a},
dq(a){return a.b},
cd(a){var t,s,r,q=new A.ab("receiver","interceptor"),p=Object.getOwnPropertyNames(q)
p.$flags=1
t=p
for(p=t.length,s=0;s<p;++s){r=t[s]
if(q[r]===a)return r}throw A.b(A.W("Field name "+a+" not found."))},
eX(a){return v.getIsolateTag(a)},
fA(a,b,c){Object.defineProperty(a,b,{value:c,enumerable:false,writable:true,configurable:true})},
f5(a){var t,s,r,q,p,o=A.aB($.d1.$1(a)),n=$.bz[o]
if(n!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}t=$.bF[o]
if(t!=null)return t
s=v.interceptorsByTag[o]
if(s==null){r=A.cP($.cX.$2(a,o))
if(r!=null){n=$.bz[r]
if(n!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}t=$.bF[r]
if(t!=null)return t
s=v.interceptorsByTag[r]
o=r}}if(s==null)return null
t=s.prototype
q=o[0]
if(q==="!"){n=A.bI(t)
$.bz[o]=n
Object.defineProperty(a,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
return n.i}if(q==="~"){$.bF[o]=t
return t}if(q==="-"){p=A.bI(t)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:p,enumerable:false,writable:true,configurable:true})
return p.i}if(q==="+")return A.d3(a,t)
if(q==="*")throw A.b(A.cs(o))
if(v.leafTags[o]===true){p=A.bI(t)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:p,enumerable:false,writable:true,configurable:true})
return p.i}else return A.d3(a,t)},
d3(a,b){var t=Object.getPrototypeOf(a)
Object.defineProperty(t,v.dispatchPropertyName,{value:J.c7(b,t,null,null),enumerable:false,writable:true,configurable:true})
return b},
bI(a){return J.c7(a,!1,null,!!a.$iai)},
f7(a,b,c){var t=b.prototype
if(v.leafTags[a]===true)return A.bI(t)
else return J.c7(t,c,null,null)},
f0(){if(!0===$.c6)return
$.c6=!0
A.f1()},
f1(){var t,s,r,q,p,o,n,m
$.bz=Object.create(null)
$.bF=Object.create(null)
A.f_()
t=v.interceptorsByTag
s=Object.getOwnPropertyNames(t)
if(typeof window!="undefined"){window
r=function(){}
for(q=0;q<s.length;++q){p=s[q]
o=$.d4.$1(p)
if(o!=null){n=A.f7(p,t[p],o)
if(n!=null){Object.defineProperty(o,v.dispatchPropertyName,{value:n,enumerable:false,writable:true,configurable:true})
r.prototype=o}}}}for(q=0;q<s.length;++q){p=s[q]
if(/^[A-Za-z_]/.test(p)){m=t[p]
t["!"+p]=m
t["~"+p]=m
t["-"+p]=m
t["+"+p]=m
t["*"+p]=m}}},
f_(){var t,s,r,q,p,o,n=B.B()
n=A.a5(B.C,A.a5(B.D,A.a5(B.x,A.a5(B.x,A.a5(B.E,A.a5(B.F,A.a5(B.G(B.y),n)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){t=dartNativeDispatchHooksTransformer
if(typeof t=="function")t=[t]
if(Array.isArray(t))for(s=0;s<t.length;++s){r=t[s]
if(typeof r=="function")n=r(n)||n}}q=n.getTag
p=n.getUnknownTag
o=n.prototypeForTag
$.d1=new A.bC(q)
$.cX=new A.bD(p)
$.d4=new A.bE(o)},
a5(a,b){return a(b)||b},
eT(a,b){var t=b.length,s=v.rttc[""+t+";"+a]
if(s==null)return null
if(t===0)return s
if(t===s.length)return s.apply(null,b)
return s(b)},
co(a,b,c,d,e,f){var t=b?"m":"",s=c?"":"i",r=d?"u":"",q=e?"s":"",p=function(g,h){try{return new RegExp(g,h)}catch(o){return o}}(a,t+s+r+q+f)
if(p instanceof RegExp)return p
throw A.b(A.ae("Illegal RegExp pattern ("+String(p)+")",a))},
eU(a){if(a.indexOf("$",0)>=0)return a.replace(/\$/g,"$$$$")
return a},
f8(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
f9(a,b,c){var t=A.fa(a,b,c)
return t},
fa(a,b,c){var t,s,r
if(b===""){if(a==="")return c
t=a.length
for(s=c,r=0;r<t;++r)s=s+a[r]+c
return s.charCodeAt(0)==0?s:s}if(a.indexOf(b,0)<0)return a
if(a.length<500||c.indexOf("$",0)>=0)return a.split(b).join(c)
return a.replace(new RegExp(A.f8(b),"g"),A.eU(c))},
ar:function ar(){},
K:function K(){},
aG:function aG(){},
aV:function aV(){},
aU:function aU(){},
ab:function ab(a,b){this.a=a
this.b=b},
bf:function bf(a){this.a=a},
bC:function bC(a){this.a=a},
bD:function bD(a){this.a=a},
bE:function bE(a){this.a=a},
aM:function aM(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null},
b_:function b_(a){this.b=a},
fc(a){throw A.u(new A.aN("Field '"+a+"' has been assigned during initialization."),new Error())},
bn(a){var t=new A.bm(a)
return t.b=t},
bm:function bm(a){this.a=a
this.b=null},
eq(a){return a},
dF(a,b,c){var t=new DataView(a,b)
return t},
c1(a,b,c){if(a>>>0!==a||a>=c)throw A.b(A.c5(b,a))},
O:function O(){},
am:function am(){},
bv:function bv(a){this.a=a},
aO:function aO(){},
a2:function a2(){},
al:function al(){},
aP:function aP(){},
an:function an(){},
av:function av(){},
aw:function aw(){},
bR(a,b){var t=b.c
return t==null?b.c=A.ay(a,"ck",[b.x]):t},
cq(a){var t=a.w
if(t===6||t===7)return A.cq(a.x)
return t===11||t===12},
dL(a){return a.as},
bA(a){return A.bt(v.typeUniverse,a,!1)},
Q(a0,a1,a2,a3){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a=a1.w
switch(a){case 5:case 1:case 2:case 3:case 4:return a1
case 6:t=a1.x
s=A.Q(a0,t,a2,a3)
if(s===t)return a1
return A.cK(a0,s,!0)
case 7:t=a1.x
s=A.Q(a0,t,a2,a3)
if(s===t)return a1
return A.cJ(a0,s,!0)
case 8:r=a1.y
q=A.a4(a0,r,a2,a3)
if(q===r)return a1
return A.ay(a0,a1.x,q)
case 9:p=a1.x
o=A.Q(a0,p,a2,a3)
n=a1.y
m=A.a4(a0,n,a2,a3)
if(o===p&&m===n)return a1
return A.bZ(a0,o,m)
case 10:l=a1.x
k=a1.y
j=A.a4(a0,k,a2,a3)
if(j===k)return a1
return A.cL(a0,l,j)
case 11:i=a1.x
h=A.Q(a0,i,a2,a3)
g=a1.y
f=A.eQ(a0,g,a2,a3)
if(h===i&&f===g)return a1
return A.cI(a0,h,f)
case 12:e=a1.y
a3+=e.length
d=A.a4(a0,e,a2,a3)
p=a1.x
o=A.Q(a0,p,a2,a3)
if(d===e&&o===p)return a1
return A.c_(a0,o,d,!0)
case 13:c=a1.x
if(c<a3)return a1
b=a2[c-a3]
if(b==null)return a1
return b
default:throw A.b(A.aE("Attempted to substitute unexpected RTI kind "+a))}},
a4(a,b,c,d){var t,s,r,q,p=b.length,o=A.bw(p)
for(t=!1,s=0;s<p;++s){r=b[s]
q=A.Q(a,r,c,d)
if(q!==r)t=!0
o[s]=q}return t?o:b},
eR(a,b,c,d){var t,s,r,q,p,o,n=b.length,m=A.bw(n)
for(t=!1,s=0;s<n;s+=3){r=b[s]
q=b[s+1]
p=b[s+2]
o=A.Q(a,p,c,d)
if(o!==p)t=!0
m.splice(s,3,r,q,o)}return t?m:b},
eQ(a,b,c,d){var t,s=b.a,r=A.a4(a,s,c,d),q=b.b,p=A.a4(a,q,c,d),o=b.c,n=A.eR(a,o,c,d)
if(r===s&&p===q&&n===o)return b
t=new A.aZ()
t.a=r
t.b=p
t.c=n
return t},
E(a,b){a[v.arrayRti]=b
return a},
cZ(a){var t=a.$S
if(t!=null){if(typeof t=="number")return A.eZ(t)
return a.$S()}return null},
f2(a,b){var t
if(A.cq(b))if(a instanceof A.K){t=A.cZ(a)
if(t!=null)return t}return A.S(a)},
S(a){if(a instanceof A.p)return A.N(a)
if(Array.isArray(a))return A.aA(a)
return A.c2(J.a6(a))},
aA(a){var t=a[v.arrayRti],s=u.b
if(t==null)return s
if(t.constructor!==s.constructor)return s
return t},
N(a){var t=a.$ti
return t!=null?t:A.c2(a)},
c2(a){var t=a.constructor,s=t.$ccache
if(s!=null)return s
return A.ez(a,t)},
ez(a,b){var t=a instanceof A.K?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,s=A.ed(v.typeUniverse,t.name)
b.$ccache=s
return s},
eZ(a){var t,s=v.types,r=s[a]
if(typeof r=="string"){t=A.bt(v.typeUniverse,r,!1)
s[a]=t
return t}return r},
eY(a){return A.R(A.N(a))},
eP(a){var t=a instanceof A.K?A.cZ(a):null
if(t!=null)return t
if(u.R.b(a))return J.dl(a).a
if(Array.isArray(a))return A.aA(a)
return A.S(a)},
R(a){var t=a.r
return t==null?a.r=new A.bs(a):t},
bJ(a){return A.R(A.bt(v.typeUniverse,a,!1))},
ey(a){var t=this
t.b=A.eO(t)
return t.b(a)},
eO(a){var t,s,r,q,p
if(a===u.K)return A.eG
if(A.T(a))return A.eK
t=a.w
if(t===6)return A.ew
if(t===1)return A.cV
if(t===7)return A.eB
s=A.eN(a)
if(s!=null)return s
if(t===8){r=a.x
if(a.y.every(A.T)){a.f="$i"+r
if(r==="y")return A.eE
if(a===u.m)return A.eD
return A.eJ}}else if(t===10){q=A.eT(a.x,a.y)
p=q==null?A.cV:q
return p==null?A.c0(p):p}return A.eu},
eN(a){if(a.w===8){if(a===u.S)return A.cT
if(a===u.i||a===u.H)return A.eF
if(a===u.N)return A.eI
if(a===u.y)return A.c3}return null},
ex(a){var t=this,s=A.et
if(A.T(t))s=A.en
else if(t===u.K)s=A.c0
else if(A.a7(t)){s=A.ev
if(t===u.t)s=A.ej
else if(t===u.v)s=A.cP
else if(t===u.u)s=A.eg
else if(t===u.n)s=A.cO
else if(t===u.I)s=A.ei
else if(t===u.z)s=A.el}else if(t===u.S)s=A.a3
else if(t===u.N)s=A.aB
else if(t===u.y)s=A.ef
else if(t===u.H)s=A.em
else if(t===u.i)s=A.eh
else if(t===u.m)s=A.ek
t.a=s
return t.a(a)},
eu(a){var t=this
if(a==null)return A.a7(t)
return A.f4(v.typeUniverse,A.f2(a,t),t)},
ew(a){if(a==null)return!0
return this.x.b(a)},
eJ(a){var t,s=this
if(a==null)return A.a7(s)
t=s.f
if(a instanceof A.p)return!!a[t]
return!!J.a6(a)[t]},
eE(a){var t,s=this
if(a==null)return A.a7(s)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
t=s.f
if(a instanceof A.p)return!!a[t]
return!!J.a6(a)[t]},
eD(a){var t=this
if(a==null)return!1
if(typeof a=="object"){if(a instanceof A.p)return!!a[t.f]
return!0}if(typeof a=="function")return!0
return!1},
cU(a){if(typeof a=="object"){if(a instanceof A.p)return u.m.b(a)
return!0}if(typeof a=="function")return!0
return!1},
et(a){var t=this
if(a==null){if(A.a7(t))return a}else if(t.b(a))return a
throw A.u(A.cQ(a,t),new Error())},
ev(a){var t=this
if(a==null||t.b(a))return a
throw A.u(A.cQ(a,t),new Error())},
cQ(a,b){return new A.b0("TypeError: "+A.cC(a,A.A(b,null)))},
cC(a,b){return A.b8(a)+": type '"+A.A(A.eP(a),null)+"' is not a subtype of type '"+b+"'"},
C(a,b){return new A.b0("TypeError: "+A.cC(a,b))},
eB(a){var t=this
return t.x.b(a)||A.bR(v.typeUniverse,t).b(a)},
eG(a){return a!=null},
c0(a){if(a!=null)return a
throw A.u(A.C(a,"Object"),new Error())},
eK(a){return!0},
en(a){return a},
cV(a){return!1},
c3(a){return!0===a||!1===a},
ef(a){if(!0===a)return!0
if(!1===a)return!1
throw A.u(A.C(a,"bool"),new Error())},
eg(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.u(A.C(a,"bool?"),new Error())},
eh(a){if(typeof a=="number")return a
throw A.u(A.C(a,"double"),new Error())},
ei(a){if(typeof a=="number")return a
if(a==null)return a
throw A.u(A.C(a,"double?"),new Error())},
cT(a){return typeof a=="number"&&Math.floor(a)===a},
a3(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.u(A.C(a,"int"),new Error())},
ej(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.u(A.C(a,"int?"),new Error())},
eF(a){return typeof a=="number"},
em(a){if(typeof a=="number")return a
throw A.u(A.C(a,"num"),new Error())},
cO(a){if(typeof a=="number")return a
if(a==null)return a
throw A.u(A.C(a,"num?"),new Error())},
eI(a){return typeof a=="string"},
aB(a){if(typeof a=="string")return a
throw A.u(A.C(a,"String"),new Error())},
cP(a){if(typeof a=="string")return a
if(a==null)return a
throw A.u(A.C(a,"String?"),new Error())},
ek(a){if(A.cU(a))return a
throw A.u(A.C(a,"JSObject"),new Error())},
el(a){if(a==null)return a
if(A.cU(a))return a
throw A.u(A.C(a,"JSObject?"),new Error())},
cW(a,b){var t,s,r
for(t="",s="",r=0;r<a.length;++r,s=", ")t+=s+A.A(a[r],b)
return t},
eM(a,b){var t,s,r,q,p,o,n=a.x,m=a.y
if(""===n)return"("+A.cW(m,b)+")"
t=m.length
s=n.split(",")
r=s.length-t
for(q="(",p="",o=0;o<t;++o,p=", "){q+=p
if(r===0)q+="{"
q+=A.A(m[o],b)
if(r>=0)q+=" "+s[r];++r}return q+"})"},
cR(a2,a3,a4){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=", ",a1=null
if(a4!=null){t=a4.length
if(a3==null)a3=A.E([],u.s)
else a1=a3.length
s=a3.length
for(r=t;r>0;--r)B.a.j(a3,"T"+(s+r))
for(q=u.X,p="<",o="",r=0;r<t;++r,o=a0){n=a3.length
m=n-1-r
if(!(m>=0))return A.a(a3,m)
p=p+o+a3[m]
l=a4[r]
k=l.w
if(!(k===2||k===3||k===4||k===5||l===q))p+=" extends "+A.A(l,a3)}p+=">"}else p=""
q=a2.x
j=a2.y
i=j.a
h=i.length
g=j.b
f=g.length
e=j.c
d=e.length
c=A.A(q,a3)
for(b="",a="",r=0;r<h;++r,a=a0)b+=a+A.A(i[r],a3)
if(f>0){b+=a+"["
for(a="",r=0;r<f;++r,a=a0)b+=a+A.A(g[r],a3)
b+="]"}if(d>0){b+=a+"{"
for(a="",r=0;r<d;r+=3,a=a0){b+=a
if(e[r+1])b+="required "
b+=A.A(e[r+2],a3)+" "+e[r]}b+="}"}if(a1!=null){a3.toString
a3.length=a1}return p+"("+b+") => "+c},
A(a,b){var t,s,r,q,p,o,n,m=a.w
if(m===5)return"erased"
if(m===2)return"dynamic"
if(m===3)return"void"
if(m===1)return"Never"
if(m===4)return"any"
if(m===6){t=a.x
s=A.A(t,b)
r=t.w
return(r===11||r===12?"("+s+")":s)+"?"}if(m===7)return"FutureOr<"+A.A(a.x,b)+">"
if(m===8){q=A.eS(a.x)
p=a.y
return p.length>0?q+("<"+A.cW(p,b)+">"):q}if(m===10)return A.eM(a,b)
if(m===11)return A.cR(a,b,null)
if(m===12)return A.cR(a.x,b,a.y)
if(m===13){o=a.x
n=b.length
o=n-1-o
if(!(o>=0&&o<n))return A.a(b,o)
return b[o]}return"?"},
eS(a){var t=v.mangledGlobalNames[a]
if(t!=null)return t
return"minified:"+a},
ee(a,b){var t=a.tR[b]
while(typeof t=="string")t=a.tR[t]
return t},
ed(a,b){var t,s,r,q,p,o=a.eT,n=o[b]
if(n==null)return A.bt(a,b,!1)
else if(typeof n=="number"){t=n
s=A.az(a,5,"#")
r=A.bw(t)
for(q=0;q<t;++q)r[q]=s
p=A.ay(a,b,r)
o[b]=p
return p}else return n},
eb(a,b){return A.cM(a.tR,b)},
ea(a,b){return A.cM(a.eT,b)},
bt(a,b,c){var t,s=a.eC,r=s.get(b)
if(r!=null)return r
t=A.cG(A.cE(a,null,b,!1))
s.set(b,t)
return t},
bu(a,b,c){var t,s,r=b.z
if(r==null)r=b.z=new Map()
t=r.get(c)
if(t!=null)return t
s=A.cG(A.cE(a,b,c,!0))
r.set(c,s)
return s},
ec(a,b,c){var t,s,r,q=b.Q
if(q==null)q=b.Q=new Map()
t=c.as
s=q.get(t)
if(s!=null)return s
r=A.bZ(a,b,c.w===9?c.y:[c])
q.set(t,r)
return r},
M(a,b){b.a=A.ex
b.b=A.ey
return b},
az(a,b,c){var t,s,r=a.eC.get(c)
if(r!=null)return r
t=new A.D(null,null)
t.w=b
t.as=c
s=A.M(a,t)
a.eC.set(c,s)
return s},
cK(a,b,c){var t,s=b.as+"?",r=a.eC.get(s)
if(r!=null)return r
t=A.e8(a,b,s,c)
a.eC.set(s,t)
return t},
e8(a,b,c,d){var t,s,r
if(d){t=b.w
s=!0
if(!A.T(b))if(!(b===u.P||b===u.T))if(t!==6)s=t===7&&A.a7(b.x)
if(s)return b
else if(t===1)return u.P}r=new A.D(null,null)
r.w=6
r.x=b
r.as=c
return A.M(a,r)},
cJ(a,b,c){var t,s=b.as+"/",r=a.eC.get(s)
if(r!=null)return r
t=A.e6(a,b,s,c)
a.eC.set(s,t)
return t},
e6(a,b,c,d){var t,s
if(d){t=b.w
if(A.T(b)||b===u.K)return b
else if(t===1)return A.ay(a,"ck",[b])
else if(b===u.P||b===u.T)return u.O}s=new A.D(null,null)
s.w=7
s.x=b
s.as=c
return A.M(a,s)},
e9(a,b){var t,s,r=""+b+"^",q=a.eC.get(r)
if(q!=null)return q
t=new A.D(null,null)
t.w=13
t.x=b
t.as=r
s=A.M(a,t)
a.eC.set(r,s)
return s},
ax(a){var t,s,r,q=a.length
for(t="",s="",r=0;r<q;++r,s=",")t+=s+a[r].as
return t},
e5(a){var t,s,r,q,p,o=a.length
for(t="",s="",r=0;r<o;r+=3,s=","){q=a[r]
p=a[r+1]?"!":":"
t+=s+q+p+a[r+2].as}return t},
ay(a,b,c){var t,s,r,q=b
if(c.length>0)q+="<"+A.ax(c)+">"
t=a.eC.get(q)
if(t!=null)return t
s=new A.D(null,null)
s.w=8
s.x=b
s.y=c
if(c.length>0)s.c=c[0]
s.as=q
r=A.M(a,s)
a.eC.set(q,r)
return r},
bZ(a,b,c){var t,s,r,q,p,o
if(b.w===9){t=b.x
s=b.y.concat(c)}else{s=c
t=b}r=t.as+(";<"+A.ax(s)+">")
q=a.eC.get(r)
if(q!=null)return q
p=new A.D(null,null)
p.w=9
p.x=t
p.y=s
p.as=r
o=A.M(a,p)
a.eC.set(r,o)
return o},
cL(a,b,c){var t,s,r="+"+(b+"("+A.ax(c)+")"),q=a.eC.get(r)
if(q!=null)return q
t=new A.D(null,null)
t.w=10
t.x=b
t.y=c
t.as=r
s=A.M(a,t)
a.eC.set(r,s)
return s},
cI(a,b,c){var t,s,r,q,p,o=b.as,n=c.a,m=n.length,l=c.b,k=l.length,j=c.c,i=j.length,h="("+A.ax(n)
if(k>0){t=m>0?",":""
h+=t+"["+A.ax(l)+"]"}if(i>0){t=m>0?",":""
h+=t+"{"+A.e5(j)+"}"}s=o+(h+")")
r=a.eC.get(s)
if(r!=null)return r
q=new A.D(null,null)
q.w=11
q.x=b
q.y=c
q.as=s
p=A.M(a,q)
a.eC.set(s,p)
return p},
c_(a,b,c,d){var t,s=b.as+("<"+A.ax(c)+">"),r=a.eC.get(s)
if(r!=null)return r
t=A.e7(a,b,c,s,d)
a.eC.set(s,t)
return t},
e7(a,b,c,d,e){var t,s,r,q,p,o,n,m
if(e){t=c.length
s=A.bw(t)
for(r=0,q=0;q<t;++q){p=c[q]
if(p.w===1){s[q]=p;++r}}if(r>0){o=A.Q(a,b,s,0)
n=A.a4(a,c,s,0)
return A.c_(a,o,n,c!==n)}}m=new A.D(null,null)
m.w=12
m.x=b
m.y=c
m.as=d
return A.M(a,m)},
cE(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
cG(a){var t,s,r,q,p,o,n,m=a.r,l=a.s
for(t=m.length,s=0;s<t;){r=m.charCodeAt(s)
if(r>=48&&r<=57)s=A.e0(s+1,r,m,l)
else if((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124)s=A.cF(a,s,m,l,!1)
else if(r===46)s=A.cF(a,s,m,l,!0)
else{++s
switch(r){case 44:break
case 58:l.push(!1)
break
case 33:l.push(!0)
break
case 59:l.push(A.P(a.u,a.e,l.pop()))
break
case 94:l.push(A.e9(a.u,l.pop()))
break
case 35:l.push(A.az(a.u,5,"#"))
break
case 64:l.push(A.az(a.u,2,"@"))
break
case 126:l.push(A.az(a.u,3,"~"))
break
case 60:l.push(a.p)
a.p=l.length
break
case 62:A.e2(a,l)
break
case 38:A.e1(a,l)
break
case 63:q=a.u
l.push(A.cK(q,A.P(q,a.e,l.pop()),a.n))
break
case 47:q=a.u
l.push(A.cJ(q,A.P(q,a.e,l.pop()),a.n))
break
case 40:l.push(-3)
l.push(a.p)
a.p=l.length
break
case 41:A.e_(a,l)
break
case 91:l.push(a.p)
a.p=l.length
break
case 93:p=l.splice(a.p)
A.cH(a.u,a.e,p)
a.p=l.pop()
l.push(p)
l.push(-1)
break
case 123:l.push(a.p)
a.p=l.length
break
case 125:p=l.splice(a.p)
A.e4(a.u,a.e,p)
a.p=l.pop()
l.push(p)
l.push(-2)
break
case 43:o=m.indexOf("(",s)
l.push(m.substring(s,o))
l.push(-4)
l.push(a.p)
a.p=l.length
s=o+1
break
default:throw"Bad character "+r}}}n=l.pop()
return A.P(a.u,a.e,n)},
e0(a,b,c,d){var t,s,r=b-48
for(t=c.length;a<t;++a){s=c.charCodeAt(a)
if(!(s>=48&&s<=57))break
r=r*10+(s-48)}d.push(r)
return a},
cF(a,b,c,d,e){var t,s,r,q,p,o,n=b+1
for(t=c.length;n<t;++n){s=c.charCodeAt(n)
if(s===46){if(e)break
e=!0}else{if(!((((s|32)>>>0)-97&65535)<26||s===95||s===36||s===124))r=s>=48&&s<=57
else r=!0
if(!r)break}}q=c.substring(b,n)
if(e){t=a.u
p=a.e
if(p.w===9)p=p.x
o=A.ee(t,p.x)[q]
if(o==null)A.F('No "'+q+'" in "'+A.dL(p)+'"')
d.push(A.bu(t,p,o))}else d.push(q)
return n},
e2(a,b){var t,s=a.u,r=A.cD(a,b),q=b.pop()
if(typeof q=="string")b.push(A.ay(s,q,r))
else{t=A.P(s,a.e,q)
switch(t.w){case 11:b.push(A.c_(s,t,r,a.n))
break
default:b.push(A.bZ(s,t,r))
break}}},
e_(a,b){var t,s,r,q=a.u,p=b.pop(),o=null,n=null
if(typeof p=="number")switch(p){case-1:o=b.pop()
break
case-2:n=b.pop()
break
default:b.push(p)
break}else b.push(p)
t=A.cD(a,b)
p=b.pop()
switch(p){case-3:p=b.pop()
if(o==null)o=q.sEA
if(n==null)n=q.sEA
s=A.P(q,a.e,p)
r=new A.aZ()
r.a=t
r.b=o
r.c=n
b.push(A.cI(q,s,r))
return
case-4:b.push(A.cL(q,b.pop(),t))
return
default:throw A.b(A.aE("Unexpected state under `()`: "+A.d(p)))}},
e1(a,b){var t=b.pop()
if(0===t){b.push(A.az(a.u,1,"0&"))
return}if(1===t){b.push(A.az(a.u,4,"1&"))
return}throw A.b(A.aE("Unexpected extended operation "+A.d(t)))},
cD(a,b){var t=b.splice(a.p)
A.cH(a.u,a.e,t)
a.p=b.pop()
return t},
P(a,b,c){if(typeof c=="string")return A.ay(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.e3(a,b,c)}else return c},
cH(a,b,c){var t,s=c.length
for(t=0;t<s;++t)c[t]=A.P(a,b,c[t])},
e4(a,b,c){var t,s=c.length
for(t=2;t<s;t+=3)c[t]=A.P(a,b,c[t])},
e3(a,b,c){var t,s,r=b.w
if(r===9){if(c===0)return b.x
t=b.y
s=t.length
if(c<=s)return t[c-1]
c-=s
b=b.x
r=b.w}else if(c===0)return b
if(r!==8)throw A.b(A.aE("Indexed base must be an interface type"))
t=b.y
if(c<=t.length)return t[c-1]
throw A.b(A.aE("Bad index "+c+" for "+b.h(0)))},
f4(a,b,c){var t,s=b.d
if(s==null)s=b.d=new Map()
t=s.get(c)
if(t==null){t=A.k(a,b,null,c,null)
s.set(c,t)}return t},
k(a,b,c,d,e){var t,s,r,q,p,o,n,m,l,k,j
if(b===d)return!0
if(A.T(d))return!0
t=b.w
if(t===4)return!0
if(A.T(b))return!1
if(b.w===1)return!0
s=t===13
if(s)if(A.k(a,c[b.x],c,d,e))return!0
r=d.w
q=u.P
if(b===q||b===u.T){if(r===7)return A.k(a,b,c,d.x,e)
return d===q||d===u.T||r===6}if(d===u.K){if(t===7)return A.k(a,b.x,c,d,e)
return t!==6}if(t===7){if(!A.k(a,b.x,c,d,e))return!1
return A.k(a,A.bR(a,b),c,d,e)}if(t===6)return A.k(a,q,c,d,e)&&A.k(a,b.x,c,d,e)
if(r===7){if(A.k(a,b,c,d.x,e))return!0
return A.k(a,b,c,A.bR(a,d),e)}if(r===6)return A.k(a,b,c,q,e)||A.k(a,b,c,d.x,e)
if(s)return!1
q=t!==11
if((!q||t===12)&&d===u.Z)return!0
p=t===10
if(p&&d===u.L)return!0
if(r===12){if(b===u.g)return!0
if(t!==12)return!1
o=b.y
n=d.y
m=o.length
if(m!==n.length)return!1
c=c==null?o:o.concat(c)
e=e==null?n:n.concat(e)
for(l=0;l<m;++l){k=o[l]
j=n[l]
if(!A.k(a,k,c,j,e)||!A.k(a,j,e,k,c))return!1}return A.cS(a,b.x,c,d.x,e)}if(r===11){if(b===u.g)return!0
if(q)return!1
return A.cS(a,b,c,d,e)}if(t===8){if(r!==8)return!1
return A.eC(a,b,c,d,e)}if(p&&r===10)return A.eH(a,b,c,d,e)
return!1},
cS(a2,a3,a4,a5,a6){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1
if(!A.k(a2,a3.x,a4,a5.x,a6))return!1
t=a3.y
s=a5.y
r=t.a
q=s.a
p=r.length
o=q.length
if(p>o)return!1
n=o-p
m=t.b
l=s.b
k=m.length
j=l.length
if(p+k<o+j)return!1
for(i=0;i<p;++i){h=r[i]
if(!A.k(a2,q[i],a6,h,a4))return!1}for(i=0;i<n;++i){h=m[i]
if(!A.k(a2,q[p+i],a6,h,a4))return!1}for(i=0;i<j;++i){h=m[n+i]
if(!A.k(a2,l[i],a6,h,a4))return!1}g=t.c
f=s.c
e=g.length
d=f.length
for(c=0,b=0;b<d;b+=3){a=f[b]
for(;;){if(c>=e)return!1
a0=g[c]
c+=3
if(a<a0)return!1
a1=g[c-2]
if(a0<a){if(a1)return!1
continue}h=f[b+1]
if(a1&&!h)return!1
h=g[c-1]
if(!A.k(a2,f[b+2],a6,h,a4))return!1
break}}while(c<e){if(g[c+1])return!1
c+=3}return!0},
eC(a,b,c,d,e){var t,s,r,q,p,o=b.x,n=d.x
while(o!==n){t=a.tR[o]
if(t==null)return!1
if(typeof t=="string"){o=t
continue}s=t[n]
if(s==null)return!1
r=s.length
q=r>0?new Array(r):v.typeUniverse.sEA
for(p=0;p<r;++p)q[p]=A.bu(a,b,s[p])
return A.cN(a,q,null,c,d.y,e)}return A.cN(a,b.y,null,c,d.y,e)},
cN(a,b,c,d,e,f){var t,s=b.length
for(t=0;t<s;++t)if(!A.k(a,b[t],d,e[t],f))return!1
return!0},
eH(a,b,c,d,e){var t,s=b.y,r=d.y,q=s.length
if(q!==r.length)return!1
if(b.x!==d.x)return!1
for(t=0;t<q;++t)if(!A.k(a,s[t],c,r[t],e))return!1
return!0},
a7(a){var t=a.w,s=!0
if(!(a===u.P||a===u.T))if(!A.T(a))if(t!==6)s=t===7&&A.a7(a.x)
return s},
T(a){var t=a.w
return t===2||t===3||t===4||t===5||a===u.X},
cM(a,b){var t,s,r=Object.keys(b),q=r.length
for(t=0;t<q;++t){s=r[t]
a[s]=b[s]}},
bw(a){return a>0?new Array(a):v.typeUniverse.sEA},
D:function D(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
aZ:function aZ(){this.c=this.b=this.a=null},
bs:function bs(a){this.a=a},
bp:function bp(){},
b0:function b0(a){this.a=a},
c:function c(){},
dV(a,b){var t,s,r=$.q(),q=a.length,p=4-q%4
if(p===4)p=0
for(t=0,s=0;s<q;++s){t=t*10+a.charCodeAt(s)-48;++p
if(p===4){r=r.i(0,$.c9()).I(0,A.at(t))
t=0
p=0}}if(b)return r.q(0)
return r},
cu(a){if(48<=a&&a<=57)return a-48
return(a|32)-97+10},
dW(a,b,c){var t,s,r,q,p,o,n,m=a.length,l=m-b,k=B.z.ar(l/4),j=new Uint16Array(k),i=k-1,h=l-i*4
for(t=b,s=0,r=0;r<h;++r,t=q){q=t+1
if(!(t<m))return A.a(a,t)
p=A.cu(a.charCodeAt(t))
if(p>=16)return null
s=s*16+p}o=i-1
if(!(i>=0&&i<k))return A.a(j,i)
j[i]=s
for(;t<m;o=n){for(s=0,r=0;r<4;++r,t=q){q=t+1
if(!(t>=0&&t<m))return A.a(a,t)
p=A.cu(a.charCodeAt(t))
if(p>=16)return null
s=s*16+p}n=o-1
if(!(o>=0&&o<k))return A.a(j,o)
j[o]=s}if(k===1){if(0>=k)return A.a(j,0)
m=j[0]===0}else m=!1
if(m)return $.q()
m=A.w(k,j)
return new A.o(m===0?!1:c,j,m)},
dY(a,b){var t,s,r,q,p,o
if(a==="")return null
t=$.d9().ab(a)
if(t==null)return null
s=t.b
r=s.length
if(1>=r)return A.a(s,1)
q=s[1]==="-"
if(4>=r)return A.a(s,4)
p=s[4]
o=s[3]
if(5>=r)return A.a(s,5)
if(p!=null)return A.dV(p,q)
if(o!=null)return A.dW(o,2,q)
return null},
w(a,b){var t,s=b.length
for(;;){if(a>0){t=a-1
if(!(t<s))return A.a(b,t)
t=b[t]===0}else t=!1
if(!t)break;--a}return a},
bX(a,b,c,d){var t,s,r,q=new Uint16Array(d),p=c-b
for(t=a.length,s=0;s<p;++s){r=b+s
if(!(r>=0&&r<t))return A.a(a,r)
r=a[r]
if(!(s<d))return A.a(q,s)
q[s]=r}return q},
ct(a){var t
if(a===0)return $.q()
if(a===1)return $.J()
if(a===2)return $.da()
if(Math.abs(a)<4294967296)return A.at(B.b.aD(a))
t=A.dS(a)
return t},
at(a){var t,s,r,q,p=a<0
if(p){if(a===-9223372036854776e3){t=new Uint16Array(4)
t[3]=32768
s=A.w(4,t)
return new A.o(s!==0,t,s)}a=-a}if(a<65536){t=new Uint16Array(1)
t[0]=a
s=A.w(1,t)
return new A.o(s===0?!1:p,t,s)}if(a<=4294967295){t=new Uint16Array(2)
t[0]=a&65535
t[1]=B.b.H(a,16)
s=A.w(2,t)
return new A.o(s===0?!1:p,t,s)}s=B.b.v(B.b.gaa(a)-1,16)+1
t=new Uint16Array(s)
for(r=0;a!==0;r=q){q=r+1
if(!(r<s))return A.a(t,r)
t[r]=a&65535
a=B.b.v(a,65536)}s=A.w(s,t)
return new A.o(s===0?!1:p,t,s)},
dS(a){var t,s,r,q,p,o,n
if(isNaN(a)||a==1/0||a==-1/0)throw A.b(A.W("Value must be finite: "+a))
a=Math.floor(a)
if(a===0)return $.q()
t=$.d8()
for(s=t.$flags|0,r=0;r<8;++r){s&2&&A.j(t)
t[r]=0}s=J.dj(B.N.gaq(t))
s.$flags&2&&A.j(s,13)
s.setFloat64(0,a,!0)
q=(t[7]<<4>>>0)+(t[6]>>>4)-1075
p=new Uint16Array(4)
p[0]=(t[1]<<8>>>0)+t[0]
p[1]=(t[3]<<8>>>0)+t[2]
p[2]=(t[5]<<8>>>0)+t[4]
p[3]=t[6]&15|16
o=new A.o(!1,p,4)
if(q<0)n=o.E(0,-q)
else n=q>0?o.A(0,q):o
return n},
bY(a,b,c,d){var t,s,r,q,p
if(b===0)return 0
if(c===0&&d===a)return b
for(t=b-1,s=a.length,r=d.$flags|0;t>=0;--t){q=t+c
if(!(t<s))return A.a(a,t)
p=a[t]
r&2&&A.j(d)
if(!(q>=0&&q<d.length))return A.a(d,q)
d[q]=p}for(t=c-1;t>=0;--t){r&2&&A.j(d)
if(!(t<d.length))return A.a(d,t)
d[t]=0}return b+c},
cA(a,b,c,d){var t,s,r,q,p,o,n,m=B.b.v(c,16),l=B.b.J(c,16),k=16-l,j=B.b.A(1,k)-1
for(t=b-1,s=a.length,r=d.$flags|0,q=0;t>=0;--t){if(!(t<s))return A.a(a,t)
p=a[t]
o=t+m+1
n=B.b.E(p,k)
r&2&&A.j(d)
if(!(o>=0&&o<d.length))return A.a(d,o)
d[o]=(n|q)>>>0
q=B.b.A((p&j)>>>0,l)}r&2&&A.j(d)
if(!(m>=0&&m<d.length))return A.a(d,m)
d[m]=q},
cv(a,b,c,d){var t,s,r,q=B.b.v(c,16)
if(B.b.J(c,16)===0)return A.bY(a,b,q,d)
t=b+q+1
A.cA(a,b,c,d)
for(s=d.$flags|0,r=q;--r,r>=0;){s&2&&A.j(d)
if(!(r<d.length))return A.a(d,r)
d[r]=0}s=t-1
if(!(s>=0&&s<d.length))return A.a(d,s)
if(d[s]===0)t=s
return t},
dX(a,b,c,d){var t,s,r,q,p,o,n=B.b.v(c,16),m=B.b.J(c,16),l=16-m,k=B.b.A(1,m)-1,j=a.length
if(!(n>=0&&n<j))return A.a(a,n)
t=B.b.E(a[n],m)
s=b-n-1
for(r=d.$flags|0,q=0;q<s;++q){p=q+n+1
if(!(p<j))return A.a(a,p)
o=a[p]
p=B.b.A((o&k)>>>0,l)
r&2&&A.j(d)
if(!(q<d.length))return A.a(d,q)
d[q]=(p|t)>>>0
t=B.b.E(o,m)}r&2&&A.j(d)
if(!(s>=0&&s<d.length))return A.a(d,s)
d[s]=t},
bl(a,b,c,d){var t,s,r,q,p=b-d
if(p===0)for(t=b-1,s=a.length,r=c.length;t>=0;--t){if(!(t<s))return A.a(a,t)
q=a[t]
if(!(t<r))return A.a(c,t)
p=q-c[t]
if(p!==0)return p}return p},
dT(a,b,c,d,e){var t,s,r,q,p,o
for(t=a.length,s=c.length,r=e.$flags|0,q=0,p=0;p<d;++p){if(!(p<t))return A.a(a,p)
o=a[p]
if(!(p<s))return A.a(c,p)
q+=o+c[p]
r&2&&A.j(e)
if(!(p<e.length))return A.a(e,p)
e[p]=q&65535
q=B.b.H(q,16)}for(p=d;p<b;++p){if(!(p>=0&&p<t))return A.a(a,p)
q+=a[p]
r&2&&A.j(e)
if(!(p<e.length))return A.a(e,p)
e[p]=q&65535
q=B.b.H(q,16)}r&2&&A.j(e)
if(!(b>=0&&b<e.length))return A.a(e,b)
e[b]=q},
aY(a,b,c,d,e){var t,s,r,q,p,o
for(t=a.length,s=c.length,r=e.$flags|0,q=0,p=0;p<d;++p){if(!(p<t))return A.a(a,p)
o=a[p]
if(!(p<s))return A.a(c,p)
q+=o-c[p]
r&2&&A.j(e)
if(!(p<e.length))return A.a(e,p)
e[p]=q&65535
q=0-(B.b.H(q,16)&1)}for(p=d;p<b;++p){if(!(p>=0&&p<t))return A.a(a,p)
q+=a[p]
r&2&&A.j(e)
if(!(p<e.length))return A.a(e,p)
e[p]=q&65535
q=0-(B.b.H(q,16)&1)}},
cB(a,b,c,d,e,f){var t,s,r,q,p,o,n,m,l
if(a===0)return
for(t=b.length,s=d.length,r=d.$flags|0,q=0;--f,f>=0;e=m,c=p){p=c+1
if(!(c<t))return A.a(b,c)
o=b[c]
if(!(e>=0&&e<s))return A.a(d,e)
n=a*o+d[e]+q
m=e+1
r&2&&A.j(d)
d[e]=n&65535
q=B.b.v(n,65536)}for(;q!==0;e=m){if(!(e>=0&&e<s))return A.a(d,e)
l=d[e]+q
m=e+1
r&2&&A.j(d)
d[e]=l&65535
q=B.b.v(l,65536)}},
dU(a,b,c){var t,s,r,q=b.length
if(!(c>=0&&c<q))return A.a(b,c)
t=b[c]
if(t===a)return 65535
s=c-1
if(!(s>=0&&s<q))return A.a(b,s)
r=B.b.T((t<<16|b[s])>>>0,a)
if(r>65535)return 65535
return r},
f3(a){var t=A.dG(a,null)
if(t!=null)return t
throw A.b(A.ae(a,null))},
d0(a){var t=A.cp(a)
if(t!=null)return t
throw A.b(A.ae("Invalid double",a))},
bQ(a,b){return new A.aM(a,A.co(a,!1,b,!1,!1,""))},
cr(a,b,c){var t=J.dk(b)
if(!t.n())return a
if(c.length===0){do a+=A.d(t.gB())
while(t.n())}else{a+=A.d(t.gB())
while(t.n())a=a+c+A.d(t.gB())}return a},
b8(a){if(typeof a=="number"||A.c3(a)||a==null)return J.aa(a)
if(typeof a=="string")return JSON.stringify(a)
return A.dH(a)},
aE(a){return new A.b5(a)},
W(a){return new A.V(!1,null,null,a)},
dI(a,b){return new A.aS(null,null,!0,a,b,"Value not in range")},
aT(a,b,c,d,e){return new A.aS(b,c,!0,a,d,"Invalid value")},
dJ(a,b,c){if(0>a||a>c)throw A.b(A.aT(a,0,c,"start",null))
if(b!=null){if(a>b||b>c)throw A.b(A.aT(b,a,c,"end",null))
return b}return c},
dx(a,b,c,d){return new A.ba(b,!0,a,d,"Index out of range")},
aX(a){return new A.aW(a)},
cs(a){return new A.bk(a)},
bN(a){return new A.b6(a)},
ae(a,b){return new A.aH(a,b)},
dy(a,b,c){var t,s
if(A.d2(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}t=A.E([],u.s)
B.a.j($.I,a)
try{A.eL(a,t)}finally{if(0>=$.I.length)return A.a($.I,-1)
$.I.pop()}s=A.cr(b,u.U.a(t),", ")+c
return s.charCodeAt(0)==0?s:s},
cm(a,b,c){var t,s
if(A.d2(a))return b+"..."+c
t=new A.bh(b)
B.a.j($.I,a)
try{s=t
s.a=A.cr(s.a,a,", ")}finally{if(0>=$.I.length)return A.a($.I,-1)
$.I.pop()}t.a+=c
s=t.a
return s.charCodeAt(0)==0?s:s},
eL(a,b){var t,s,r,q,p,o,n,m=a.gM(a),l=0,k=0
for(;;){if(!(l<80||k<3))break
if(!m.n())return
t=A.d(m.gB())
B.a.j(b,t)
l+=t.length+2;++k}if(!m.n()){if(k<=5)return
if(0>=b.length)return A.a(b,-1)
s=b.pop()
if(0>=b.length)return A.a(b,-1)
r=b.pop()}else{q=m.gB();++k
if(!m.n()){if(k<=4){B.a.j(b,A.d(q))
return}s=A.d(q)
if(0>=b.length)return A.a(b,-1)
r=b.pop()
l+=s.length+2}else{p=m.gB();++k
for(;m.n();q=p,p=o){o=m.gB();++k
if(k>100){for(;;){if(!(l>75&&k>3))break
if(0>=b.length)return A.a(b,-1)
l-=b.pop().length+2;--k}B.a.j(b,"...")
return}}r=A.d(q)
s=A.d(p)
l+=s.length+r.length+4}}if(k>b.length+2){l+=5
n="..."}else n=null
for(;;){if(!(l>80&&b.length>3))break
if(0>=b.length)return A.a(b,-1)
l-=b.pop().length+2
if(n==null){l+=5
n="..."}}if(n!=null)B.a.j(b,n)
B.a.j(b,r)
B.a.j(b,s)},
o:function o(a,b,c){this.a=a
this.b=b
this.c=c},
bo:function bo(){},
b7:function b7(){},
b5:function b5(a){this.a=a},
bj:function bj(){},
V:function V(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
aS:function aS(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
ba:function ba(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
aW:function aW(a){this.a=a},
bk:function bk(a){this.a=a},
bg:function bg(a){this.a=a},
b6:function b6(a){this.a=a},
bd:function bd(){},
aH:function aH(a,b){this.a=a
this.b=b},
bb:function bb(){},
m:function m(){},
ao:function ao(){},
p:function p(){},
bh:function bh(a){this.a=a},
cb(a,b){return new A.r(a,b)},
X(a){return new A.r(A.ct(a),0)},
dm(a){var t=A.aF(a)
if(t==null)throw A.b(A.ae('Invalid decimal number: "'+a+'"',null))
return t},
aF(a){var t,s,r,q,p,o,n,m,l,k=$.d6().ab(a)
if(k==null)return null
t=k.b
s=t.length
if(1>=s)return A.a(t,1)
r=t[1]
r.toString
if(2>=s)return A.a(t,2)
q=t[2]
q.toString
if(4>=s)return A.a(t,4)
p=t[4]
if(p==null)p=""
if(q.length===0&&p.length===0)return null
if(6>=s)return A.a(t,6)
o=t[6]
n=o==null?0:A.f3(o)
t=q+p
m=A.dY(t,null)
if(m==null)A.F(A.ae("Could not parse BigInt",t))
l=r==="-"?m.q(0):m
return new A.r(l,p.length-n)},
cc(a,b,c){var t,s=a.a,r=s?a.q(0):a,q=r.T(0,b),p=r.F(0,q.i(0,b)),o=p.p(0,$.q())
if(o!==0){t=p.A(0,1).p(0,b)
o=!1
switch(c.a){case 0:break
case 1:o=t>=0
break
case 2:if(t<=0){if(t===0){if(q.c!==0){o=q.b
if(0>=o.length)return A.a(o,0)
o=(o[0]&1)===0}else o=!0
o=!o}}else o=!0
break
default:o=null}if(o)q=q.I(0,$.J())}return s?q.q(0):q},
aq:function aq(a,b){this.a=a
this.b=b},
r:function r(a,b){this.a=a
this.b=b},
ad(a){return new A.b9(a)},
dZ(a){var t
if(0>=a.length)return A.a(a,0)
t=a.charCodeAt(0)
return t>=48&&t<=57},
b9:function b9(a){this.a=a},
br:function br(a){this.a=a
this.b=0},
dP(a){var t,s,r,q,p,o,n,m,l=A.E([],u.h),k=new A.H(l),j=new A.bi(k)
for(t=A.N(a),s=new A.f(a,a.gk(0),t.l("f<c.E>")),t=t.l("c.E");s.n();){r=s.d
if(r==null)r=t.a(r)
q=r.a
switch(q.a){case 13:j.$1($.b4())
break
case 12:j.$1($.b3())
break
case 11:j.$1($.b2())
break
case 10:j.$1($.a9())
break
case 9:j.$1($.bL())
break
case 8:j.$1($.bK())
break
case 7:j.$1($.bM())
break
case 6:q=$.l()
B.a.j(l,new A.h(B.p,q,"+"))
p=A.aF(r.c)
q=p==null?q:p
r=r.c
B.a.j(l,new A.h(B.m,q,r))
break
case 4:case 5:case 1:case 0:case 3:case 2:r=$.l()
p=q.c
o=new A.h(q,r,p)
n=!1
if(q===B.l||q===B.k||q===B.i||q===B.e||q===B.f||q===B.h||q===B.j||q===B.d){m=r.b
r=r.a
q=$.B()
n=m-m
n=r.i(0,q.m(n)).p(0,r.i(0,q.m(n)))!==0
r=n}else r=n
if(r)o.c=p+"s"
B.a.j(l,o)
break
default:break}}return k},
dQ(a,a0){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e=A.E([],u.h),d=A.dO(a),c=$.q(),b=d.a.p(0,c)===0
for(t=a0.a,s=0;r=t.length,s<r;++s){q=t[s].a
p=$.aC()
o=A.dM(d.K(26,B.q),q)
if(s===r-1){r=o.a
n=r.p(0,c)
if(n!==0){n=o.K(7,B.q).a1().D()
B.a.j(e,new A.h(B.m,o,n))
n=q.c
m=new A.h(q,o,n)
l=!1
if(q===B.l||q===B.k||q===B.i||q===B.e||q===B.f||q===B.h||q===B.j||q===B.d){q=$.l()
k=o.b
j=q.b
i=k>j?k:j
l=$.B()
l=r.i(0,l.m(i-k)).p(0,q.a.i(0,l.m(i-j)))!==0
r=l}else r=l
if(r)m.c=n+"s"
B.a.j(e,m)}else if(b){r=p.D()
B.a.j(e,new A.h(B.m,p,r))
r=q.c
n=new A.h(q,p,r)
m=!1
if(q===B.l||q===B.k||q===B.i||q===B.e||q===B.f||q===B.h||q===B.j||q===B.d){q=$.l()
k=p.b
j=q.b
i=k>j?k:j
m=$.B()
m=p.a.i(0,m.m(i-k)).p(0,q.a.i(0,m.m(i-j)))!==0
q=m}else q=m
if(q)n.c=r+"s"
B.a.j(e,n)}}else{h=o.K(0,B.O)
k=o.b
j=h.b
i=k>j?k:j
r=$.B()
n=h.a
g=new A.r(o.a.i(0,r.m(i-k)).F(0,n.i(0,r.m(i-j))),i).K(26,B.q)
m=n.p(0,c)
if(m!==0){m=h.D()
B.a.j(e,new A.h(B.m,h,m))
m=q.c
l=new A.h(q,h,m)
f=!1
if(q===B.l||q===B.k||q===B.i||q===B.e||q===B.f||q===B.h||q===B.j||q===B.d){f=$.l()
k=f.b
i=j>k?j:k
r=n.i(0,r.m(i-j)).p(0,f.a.i(0,r.m(i-k)))!==0}else r=f
if(r)l.c=m+"s"
B.a.j(e,l)}r=g.a.p(0,c)
p=r===0?p:A.dN(g,q)}d=p.K(7,B.q).a1()}return new A.H(e)},
bS(a){var t
$label0$0:{if(B.j===a){t=$.b4()
break $label0$0}if(B.h===a){t=$.b3()
break $label0$0}if(B.f===a){t=$.b2()
break $label0$0}if(B.e===a){t=$.a9()
break $label0$0}if(B.k===a){t=$.bL()
break $label0$0}if(B.i===a){t=$.bK()
break $label0$0}if(B.l===a){t=$.bM()
break $label0$0}t=null
break $label0$0}return t},
dM(a,b){var t,s,r,q
if(b===B.d)return a
t=A.bS(b)
if(t==null)return $.aC()
s=t.a
r=s.p(0,$.q())
if(r===0)A.F(A.aX("Division by zero"))
q=a.a
r=t.b
if(r>=0)q=q.i(0,$.B().m(r))
else s=s.i(0,$.B().m(-r))
if(s.a){q=q.q(0)
s=s.q(0)}return new A.r(A.cc(q,s,B.P),a.b)},
dO(a){var t,s,r,q,p,o,n,m,l,k,j=$.aC()
for(t=A.N(a),s=new A.f(a,a.gk(0),t.l("f<c.E>")),t=t.l("c.E"),r=j;s.n();){q=s.d
if(q==null)q=t.a(q)
p=q.a
if(p===B.m){q=q.c
o=A.aF(q)
if(o==null)A.F(A.ae('Invalid decimal number: "'+q+'"',null))
r=o}else if(p===B.d){n=j.b
m=r.b
l=n>m?n:m
q=$.B()
j=new A.r(j.a.i(0,q.m(l-n)).I(0,r.a.i(0,q.m(l-m))),l)}else{k=A.bS(p)
if(k!=null){q=r.a.i(0,k.a)
n=r.b+k.b
m=j.b
l=m>n?m:n
p=$.B()
j=new A.r(j.a.i(0,p.m(l-m)).I(0,q.i(0,p.m(l-n))),l)}}}return j},
dN(a,b){var t=A.bS(b)
if(t==null)return $.aC()
return a.i(0,t)},
bi:function bi(a){this.a=a},
z(a,b,c){var t,s,r=c==null,q=r?a.c:c,p=new A.h(a,b,q),o=!1
if(r)if(a.gad()){r=$.l()
t=b.b
s=r.b
t=t>s?t:s
r=b.a8(t).p(0,r.a8(t))!==0}else r=o
else r=o
if(r)p.c=q+"s"
return p},
h:function h(a,b,c){this.a=a
this.b=b
this.c=c},
n:function n(a,b,c){this.c=a
this.a=b
this.b=c},
H:function H(a){this.a=a},
es(a,b){var t,s,r,q,p,o,n,m,l
try{t=A.bP(a)
s=A.ci(t)
if(J.U(s)===0)return""
for(o=s,n=A.S(o),o=new A.f(o,J.U(o),n.l("f<c.E>")),n=n.l("c.E");o.n();){m=o.d
r=m==null?n.a(m):m
if(r.a===B.n)return"ERROR"}q=A.bP(b)
p=A.dQ(s,q)
o=p.aE()
return o}catch(l){return"ERROR"}},
eA(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e='{"ok":false,"error":true}'
try{t=A.bP(a)
s=A.ci(t)
if(J.U(s)===0)return'{"ok":false}'
for(o=s,n=A.S(o),o=new A.f(o,J.U(o),n.l("f<c.E>")),n=n.l("c.E");o.n();){m=o.d
r=m==null?n.a(m):m
if(r.a===B.n)return e}o=s
n=J.b1(o)
if(n.gk(o)===0)A.F(A.cl())
q=A.d0(n.C(o,0).b.D())
p=new A.bx(q)
o=A.d(q)
n=A.d(p.$1($.bM()))
m=A.d(p.$1($.bK()))
l=A.d(p.$1($.bL()))
k=A.d(p.$1($.a9()))
j=A.d(p.$1($.b2()))
i=A.d(p.$1($.b3()))
h=A.d(p.$1($.b4()))
g=A.d(q)
return'{"ok":true,"msec":"'+o+'","Year":"'+n+'","Month":"'+m+'","Week":"'+l+'","Day":"'+k+'","Hour":"'+j+'","Minute":"'+i+'","Second":"'+h+'","MSecond":"'+g+'"}'}catch(f){return e}},
f6(){var t,s,r="Attempting to rewrap a JS function.",q=v.G,p=new A.bG()
if(typeof p=="function")A.F(A.W(r))
t=function(a,b){return function(c,d){return a(b,c,d,arguments.length)}}(A.ep,p)
s=$.c8()
t[s]=p
q.evaluateTime=t
p=new A.bH()
if(typeof p=="function")A.F(A.W(r))
t=function(a,b){return function(c){return a(b,c,arguments.length)}}(A.eo,p)
t[s]=p
q.intervalBreakdown=t},
bx:function bx(a){this.a=a},
bG:function bG(){},
bH:function bH(){},
eo(a,b,c){u.Z.a(a)
if(A.a3(c)>=1)return a.$1(b)
return a.$0()},
ep(a,b,c,d){u.Z.a(a)
A.a3(d)
if(d>=2)return a.$2(b,c)
if(d===1)return a.$1(b)
return a.$0()},
ci(a){var t=a.au()
if(t.aw())return A.ch(t)
return A.ch(A.dP(A.dr(t)))},
ch(a){var t,s,r,q,p,o,n,m,l,k,j,i
if(a.gk(0)!==0&&a.gS(a).a.gac())a.a_(a,a.a.length-1)
o=a.a
n=!1
if(o.length>=2)if(a.gS(a).a===B.v){n=o.length
m=n-2
if(!(m>=0))return A.a(o,m)
m=o[m].a.gac()
n=m}if(n){a.a_(a,o.length-1)
a.a_(a,o.length-1)}t=a.h(0)
s=new A.H(A.E([],u.h))
if(J.di(t,""))return s
try{l=new A.br(t)
k=l.ae()
j=l.G()
if(j!=null)A.F(A.ad('Unexpected character "'+j+'" at position '+l.b))
r=k
if(!isFinite(r))throw A.b(B.I)
q=J.aa(r)
p=A.dm(q)
o=A.z(B.m,p,q)
B.a.j(s.a,o)
o=A.z(B.d,p,null)
B.a.j(s.a,o)
return s}catch(i){o=A.z(B.n,$.l(),"ERROR")
B.a.j(s.a,o)
return s}},
dr(a){var t,s,r,q,p,o,n=A.E([],u.h)
for(t=A.N(a),s=new A.f(a,a.gk(0),t.l("f<c.E>")),t=t.l("c.E"),r=!1;s.n();){q=s.d
if(q==null)q=t.a(q)
p=q.a
switch(p.a){case 6:if(!r){o=$.l()
B.a.j(n,new A.h(B.Q,o,"("))
r=!0}break
case 4:case 5:case 1:case 0:o=$.l()
B.a.j(n,new A.h(B.v,o,")"))
r=!1
break
default:break}o=q.b
q=q.c
B.a.j(n,new A.h(p,o,q))}B.a.j(n,A.z(B.v,$.l(),null))
return new A.H(n)},
bP(a){var t,s,r,q=A.f9(a," ",""),p=A.E([],u.h),o=new A.H(p)
for(t=q.length,s=0;s<t;){r=A.dC(q,s,o)
B.a.j(p,r)
s+=A.dB(q,s,r)}return o},
dB(a,b,c){var t,s,r,q=c.a
if(q.gad()){t=q.c.length
s=b+t
q=a.length
if(s<q){if(!(s>=0))return A.a(a,s)
r=a.charCodeAt(s)===115}else r=!1
return t+(r?1:0)}return c.c.length},
dC(a,b,c){var t,s,r=a.length
if(!(b>=0&&b<r))return A.a(a,b)
t=a.charCodeAt(b)
if(t>=48&&t<=57){s=$.d7()
if(b>r)A.F(A.aT(b,0,r,null,null))
r=s.am(a,b).b
if(0>=r.length)return A.a(r,0)
r=r[0]
r.toString
s=A.aF(r)
return A.z(B.m,s==null?$.l():s,r)}if(!(t>=65&&t<=90))r=t>=97&&t<=122
else r=!0
if(r)return A.dD(a,b,c)
r=a[b]
s=!0
if(r!=="+")if(r!=="\u2212")if(r!=="\xd7")if(r!=="\xf7")if(r!=="-")if(r!=="/")r=r==="*"
else r=s
else r=s
else r=s
else r=s
else r=s
else r=s
if(r)return A.dE(a,b)
return A.z(B.n,$.l(),null)},
dE(a,b){var t,s,r=null
if(!(b>=0&&b<a.length))return A.a(a,b)
t=a[b]
s=t==="+"
if(s||s)return A.z(B.p,$.l(),r)
if(t==="\u2212"||t==="-")return A.z(B.r,$.l(),r)
if(t==="\xf7"||t==="/")return A.z(B.t,$.l(),r)
if(t==="\xd7"||t==="*")return A.z(B.o,$.l(),r)
return A.z(B.n,$.l(),r)},
dD(a,b,c){var t,s,r,q,p,o,n,m,l,k,j=$.l()
if(c.gk(0)!==0&&c.gS(c).a===B.m){t=A.aF(c.gS(c).c)
j=t==null?j:t}for(s=0;s<8;++s){r=B.M[s]
q=r.c
if(B.c.a0(a,q,b)){p=new A.h(r,j,q)
o=!1
if(r===B.l||r===B.k||r===B.i||r===B.e||r===B.f||r===B.h||r===B.j||r===B.d){o=$.l()
n=j.b
m=o.b
l=n>m?n:m
k=$.B()
k=j.a.i(0,k.m(l-n)).p(0,o.a.i(0,k.m(l-m)))!==0
o=k}if(o)p.c=q+"s"
return p}}return A.z(B.n,j,null)}},B={}
var w=[A,J,B]
var $={}
A.bO.prototype={}
J.aI.prototype={
ag(a,b){return a===b},
h(a){return"Instance of '"+A.aR(a)+"'"},
gu(a){return A.R(A.c2(this))}}
J.aK.prototype={
h(a){return String(a)},
gu(a){return A.R(u.y)},
$it:1,
$iby:1}
J.ag.prototype={
h(a){return"null"},
$it:1}
J.aj.prototype={$ix:1}
J.L.prototype={
h(a){return String(a)}}
J.aQ.prototype={}
J.as.prototype={}
J.G.prototype={
h(a){var t=a[$.c8()]
if(t==null)return this.ai(a)
return"JavaScript function for "+J.aa(t)},
$iZ:1}
J.a0.prototype={
h(a){return String(a)}}
J.a1.prototype={
h(a){return String(a)}}
J.v.prototype={
j(a,b){A.aA(a).c.a(b)
a.$flags&1&&A.j(a,29)
a.push(b)},
L(a,b){if(!(b>=0&&b<a.length))return A.a(a,b)
return a[b]},
h(a){return A.cm(a,"[","]")},
gM(a){return new J.aD(a,a.length,A.aA(a).l("aD<1>"))},
gk(a){return a.length},
sk(a,b){a.$flags&1&&A.j(a,"set length","change the length of")
if(b<0)throw A.b(A.aT(b,0,null,"newLength",null))
if(b>a.length)A.aA(a).c.a(null)
a.length=b},
O(a,b,c){A.aA(a).c.a(c)
a.$flags&2&&A.j(a)
if(!(b>=0&&b<a.length))throw A.b(A.c5(a,b))
a[b]=c},
$im:1,
$iy:1}
J.aJ.prototype={
aF(a){var t,s,r
if(!Array.isArray(a))return null
t=a.$flags|0
if((t&4)!==0)s="const, "
else if((t&2)!==0)s="unmodifiable, "
else s=(t&1)!==0?"fixed, ":""
r="Instance of '"+A.aR(a)+"'"
if(s==="")return r
return r+" ("+s+"length: "+a.length+")"}}
J.bc.prototype={}
J.aD.prototype={
gB(){var t=this.d
return t==null?this.$ti.c.a(t):t},
n(){var t,s=this,r=s.a,q=r.length
if(s.b!==q){r=A.fb(r)
throw A.b(r)}t=s.c
if(t>=q){s.d=null
return!1}s.d=r[t]
s.c=t+1
return!0}}
J.ah.prototype={
aD(a){var t
if(a>=-2147483648&&a<=2147483647)return a|0
if(isFinite(a)){t=a<0?Math.ceil(a):Math.floor(a)
return t+0}throw A.b(A.aX(""+a+".toInt()"))},
ar(a){var t,s
if(a>=0){if(a<=2147483647){t=a|0
return a===t?t:t+1}}else if(a>=-2147483648)return a|0
s=Math.ceil(a)
if(isFinite(s))return s
throw A.b(A.aX(""+a+".ceil()"))},
h(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
J(a,b){var t=a%b
if(t===0)return 0
if(t>0)return t
return t+b},
T(a,b){if((a|0)===a)if(b>=1||b<-1)return a/b|0
return this.a7(a,b)},
v(a,b){return(a|0)===a?a/b|0:this.a7(a,b)},
a7(a,b){var t=a/b
if(t>=-2147483648&&t<=2147483647)return t|0
if(t>0){if(t!==1/0)return Math.floor(t)}else if(t>-1/0)return Math.ceil(t)
throw A.b(A.aX("Result of truncating division is "+A.d(t)+": "+A.d(a)+" ~/ "+b))},
A(a,b){if(b<0)throw A.b(A.cY(b))
return b>31?0:a<<b>>>0},
E(a,b){var t
if(b<0)throw A.b(A.cY(b))
if(a>0)t=this.a6(a,b)
else{t=b>31?31:b
t=a>>t>>>0}return t},
H(a,b){var t
if(a>0)t=this.a6(a,b)
else{t=b>31?31:b
t=a>>t>>>0}return t},
a6(a,b){return b>31?0:a>>>b},
gu(a){return A.R(u.H)},
$ia8:1}
J.af.prototype={
gaa(a){var t,s=a<0?-a-1:a,r=s
for(t=32;r>=4294967296;){r=this.v(r,4294967296)
t+=32}return t-Math.clz32(r)},
gu(a){return A.R(u.S)},
$it:1,
$ie:1}
J.aL.prototype={
gu(a){return A.R(u.i)},
$it:1}
J.a_.prototype={
av(a,b){var t=b.length,s=a.length
if(t>s)return!1
return b===this.a2(a,s-t)},
a0(a,b,c){var t
if(c<0||c>a.length)throw A.b(A.aT(c,0,a.length,null,null))
t=c+b.length
if(t>a.length)return!1
return b===a.substring(c,t)},
ah(a,b){return this.a0(a,b,0)},
P(a,b,c){return a.substring(b,A.dJ(b,c,a.length))},
a2(a,b){return this.P(a,b,null)},
af(a){var t,s,r,q=a.trim(),p=q.length
if(p===0)return q
if(0>=p)return A.a(q,0)
if(q.charCodeAt(0)===133){t=J.dz(q,1)
if(t===p)return""}else t=0
s=p-1
if(!(s>=0))return A.a(q,s)
r=q.charCodeAt(s)===133?J.dA(q,s):p
if(t===0&&r===p)return q
return q.substring(t,r)},
i(a,b){var t,s
if(0>=b)return""
if(b===1||a.length===0)return a
if(b!==b>>>0)throw A.b(B.H)
for(t=a,s="";;){if((b&1)===1)s=t+s
b=b>>>1
if(b===0)break
t+=t}return s},
aB(a,b,c){var t=b-a.length
if(t<=0)return a
return this.i(c,t)+a},
h(a){return a},
gu(a){return A.R(u.N)},
gk(a){return a.length},
$it:1,
$ibe:1,
$ii:1}
A.aN.prototype={
h(a){return"LateInitializationError: "+this.a}}
A.ac.prototype={}
A.ak.prototype={
gM(a){return new A.f(this,this.gk(0),this.$ti.l("f<1>"))},
az(a){var t,s,r=this.a,q=J.b1(r),p=q.gk(r)
for(t=0,s="";t<p;++t){s+=A.d(q.L(r,q.gk(r)-1-t))
if(p!==q.gk(r))throw A.b(A.bN(this))}return s.charCodeAt(0)==0?s:s}}
A.f.prototype={
gB(){var t=this.d
return t==null?this.$ti.c.a(t):t},
n(){var t,s=this,r=s.a,q=J.b1(r),p=q.gk(r)
if(s.b!==p)throw A.b(A.bN(r))
t=s.c
if(t>=p){s.d=null
return!1}s.d=q.L(r,t);++s.c
return!0}}
A.Y.prototype={
sk(a,b){throw A.b(A.aX("Cannot change the length of a fixed-length list"))}}
A.ap.prototype={
gk(a){return J.U(this.a)},
L(a,b){var t=this.a,s=J.b1(t)
return s.L(t,s.gk(t)-1-b)}}
A.ar.prototype={}
A.K.prototype={
h(a){var t=this.constructor,s=t==null?null:t.name
return"Closure '"+A.d5(s==null?"unknown":s)+"'"},
$iZ:1,
gaG(){return this},
$C:"$1",
$R:1,
$D:null}
A.aG.prototype={$C:"$2",$R:2}
A.aV.prototype={}
A.aU.prototype={
h(a){var t=this.$static_name
if(t==null)return"Closure of unknown static method"
return"Closure '"+A.d5(t)+"'"}}
A.ab.prototype={
h(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.aR(this.a)+"'")}}
A.bf.prototype={
h(a){return"RuntimeError: "+this.a}}
A.bC.prototype={
$1(a){return this.a(a)},
$S:0}
A.bD.prototype={
$2(a,b){return this.a(a,b)},
$S:1}
A.bE.prototype={
$1(a){return this.a(A.aB(a))},
$S:2}
A.aM.prototype={
h(a){return"RegExp/"+this.a+"/"+this.b.flags},
gan(){var t=this,s=t.d
if(s!=null)return s
s=t.b
return t.d=A.co(t.a,s.multiline,!s.ignoreCase,s.unicode,s.dotAll,"y")},
ab(a){var t=this.b.exec(a)
if(t==null)return null
return new A.b_(t)},
am(a,b){var t,s=this.gan()
if(s==null)s=A.c0(s)
s.lastIndex=b
t=s.exec(a)
if(t==null)return null
return new A.b_(t)},
$ibe:1,
$idK:1}
A.b_.prototype={}
A.bm.prototype={
t(){var t=this.b
if(t===this)throw A.b(new A.aN("Field '"+this.a+"' has not been initialized."))
return t}}
A.O.prototype={
gu(a){return B.R},
ap(a,b,c){var t=new DataView(a,b)
return t},
a9(a){return this.ap(a,0,null)},
$it:1,
$iO:1}
A.am.prototype={
gaq(a){if(((a.$flags|0)&2)!==0)return new A.bv(a.buffer)
else return a.buffer}}
A.bv.prototype={
a9(a){var t=A.dF(this.a,0,null)
t.$flags=3
return t}}
A.aO.prototype={
gu(a){return B.S},
$it:1}
A.a2.prototype={
gk(a){return a.length},
$iai:1}
A.al.prototype={
O(a,b,c){A.a3(c)
a.$flags&2&&A.j(a)
A.c1(b,a,a.length)
a[b]=c},
$im:1,
$iy:1}
A.aP.prototype={
gu(a){return B.T},
C(a,b){A.c1(b,a,a.length)
return a[b]},
$it:1,
$ibT:1}
A.an.prototype={
gu(a){return B.U},
gk(a){return a.length},
C(a,b){A.c1(b,a,a.length)
return a[b]},
$it:1}
A.av.prototype={}
A.aw.prototype={}
A.D.prototype={
l(a){return A.bu(v.typeUniverse,this,a)},
aH(a){return A.ec(v.typeUniverse,this,a)}}
A.aZ.prototype={}
A.bs.prototype={
h(a){return A.A(this.a,null)}}
A.bp.prototype={
h(a){return this.a}}
A.b0.prototype={}
A.c.prototype={
gM(a){return new A.f(a,this.gk(a),A.S(a).l("f<c.E>"))},
L(a,b){return this.C(a,b)},
gS(a){if(this.gk(a)===0)throw A.b(A.cl())
return this.C(a,this.gk(a)-1)},
aj(a,b,c){var t,s=this,r=s.gk(a),q=c-b
for(t=c;t<r;++t)s.O(a,t-q,s.C(a,t))
s.sk(a,r-q)},
a_(a,b){var t=this.C(a,b)
this.aj(a,b,b+1)
return t},
h(a){return A.cm(a,"[","]")},
$im:1,
$iy:1}
A.o.prototype={
q(a){var t,s,r=this,q=r.c
if(q===0)return r
t=!r.a
s=r.b
q=A.w(q,s)
return new A.o(q===0?!1:t,s,q)},
ak(a){var t,s,r,q,p,o,n,m=this.c
if(m===0)return $.q()
t=m+a
s=this.b
r=new Uint16Array(t)
for(q=m-1,p=s.length;q>=0;--q){o=q+a
if(!(q<p))return A.a(s,q)
n=s[q]
if(!(o>=0&&o<t))return A.a(r,o)
r[o]=n}p=this.a
o=A.w(t,r)
return new A.o(o===0?!1:p,r,o)},
al(a){var t,s,r,q,p,o,n,m,l=this,k=l.c
if(k===0)return $.q()
t=k-a
if(t<=0)return l.a?$.ca():$.q()
s=l.b
r=new Uint16Array(t)
for(q=s.length,p=a;p<k;++p){o=p-a
if(!(p>=0&&p<q))return A.a(s,p)
n=s[p]
if(!(o<t))return A.a(r,o)
r[o]=n}o=l.a
n=A.w(t,r)
m=new A.o(n===0?!1:o,r,n)
if(o)for(p=0;p<a;++p){if(!(p<q))return A.a(s,p)
if(s[p]!==0)return m.F(0,$.J())}return m},
A(a,b){var t,s,r,q,p,o=this
if(b<0)throw A.b(A.W("shift-amount must be posititve "+b))
t=o.c
if(t===0)return o
s=B.b.v(b,16)
if(B.b.J(b,16)===0)return o.ak(s)
r=t+s+1
q=new Uint16Array(r)
A.cA(o.b,t,b,q)
t=o.a
p=A.w(r,q)
return new A.o(p===0?!1:t,q,p)},
E(a,b){var t,s,r,q,p,o,n,m,l,k=this
if(b<0)throw A.b(A.W("shift-amount must be posititve "+b))
t=k.c
if(t===0)return k
s=B.b.v(b,16)
r=B.b.J(b,16)
if(r===0)return k.al(s)
q=t-s
if(q<=0)return k.a?$.ca():$.q()
p=k.b
o=new Uint16Array(q)
A.dX(p,t,b,o)
t=k.a
n=A.w(q,o)
m=new A.o(n===0?!1:t,o,n)
if(t){t=p.length
if(!(s>=0&&s<t))return A.a(p,s)
if((p[s]&B.b.A(1,r)-1)>>>0!==0)return m.F(0,$.J())
for(l=0;l<s;++l){if(!(l<t))return A.a(p,l)
if(p[l]!==0)return m.F(0,$.J())}}return m},
p(a,b){var t,s=this.a
if(s===b.a){t=A.bl(this.b,this.c,b.b,b.c)
return s?0-t:t}return s?-1:1},
U(a,b){var t,s,r,q=this,p=q.c,o=a.c
if(p<o)return a.U(q,b)
if(p===0)return $.q()
if(o===0)return q.a===b?q:q.q(0)
t=p+1
s=new Uint16Array(t)
A.dT(q.b,p,a.b,o,s)
r=A.w(t,s)
return new A.o(r===0?!1:b,s,r)},
R(a,b){var t,s,r,q=this,p=q.c
if(p===0)return $.q()
t=a.c
if(t===0)return q.a===b?q:q.q(0)
s=new Uint16Array(p)
A.aY(q.b,p,a.b,t,s)
r=A.w(p,s)
return new A.o(r===0?!1:b,s,r)},
I(a,b){var t,s,r=this,q=r.c
if(q===0)return b
t=b.c
if(t===0)return r
s=r.a
if(s===b.a)return r.U(b,s)
if(A.bl(r.b,q,b.b,t)>=0)return r.R(b,s)
return b.R(r,!s)},
F(a,b){var t,s,r=this,q=r.c
if(q===0)return b.q(0)
t=b.c
if(t===0)return r
s=r.a
if(s!==b.a)return r.U(b,s)
if(A.bl(r.b,q,b.b,t)>=0)return r.R(b,s)
return b.R(r,!s)},
i(a,b){var t,s,r,q,p,o,n,m=this.c,l=b.c
if(m===0||l===0)return $.q()
t=m+l
s=this.b
r=b.b
q=new Uint16Array(t)
for(p=r.length,o=0;o<l;){if(!(o<p))return A.a(r,o)
A.cB(r[o],s,0,q,o,m);++o}p=this.a!==b.a
n=A.w(t,q)
return new A.o(n===0?!1:p,q,n)},
V(a){var t,s,r,q
if(this.c<a.c)return $.q()
this.a3(a)
t=$.bV.t()-$.au.t()
s=A.bX($.bU.t(),$.au.t(),$.bV.t(),t)
r=A.w(t,s)
q=new A.o(!1,s,r)
return this.a!==a.a&&r>0?q.q(0):q},
a5(a){var t,s,r,q=this
if(q.c<a.c)return q
q.a3(a)
t=A.bX($.bU.t(),0,$.au.t(),$.au.t())
s=A.w($.au.t(),t)
r=new A.o(!1,t,s)
if($.bW.t()>0)r=r.E(0,$.bW.t())
return q.a&&r.c>0?r.q(0):r},
a3(a){var t,s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d=this,c=d.c
if(c===$.cx&&a.c===$.cz&&d.b===$.cw&&a.b===$.cy)return
t=a.b
s=a.c
r=s-1
if(!(r>=0&&r<t.length))return A.a(t,r)
q=16-B.b.gaa(t[r])
if(q>0){p=new Uint16Array(s+5)
o=A.cv(t,s,q,p)
n=new Uint16Array(c+5)
m=A.cv(d.b,c,q,n)}else{n=A.bX(d.b,0,c,c+2)
o=s
p=t
m=c}r=o-1
if(!(r>=0&&r<p.length))return A.a(p,r)
l=p[r]
k=m-o
j=new Uint16Array(m)
i=A.bY(p,o,k,j)
h=m+1
r=n.$flags|0
if(A.bl(n,m,j,i)>=0){r&2&&A.j(n)
if(!(m>=0&&m<n.length))return A.a(n,m)
n[m]=1
A.aY(n,h,j,i,n)}else{r&2&&A.j(n)
if(!(m>=0&&m<n.length))return A.a(n,m)
n[m]=0}r=o+2
g=new Uint16Array(r)
if(!(o>=0&&o<r))return A.a(g,o)
g[o]=1
A.aY(g,o+1,p,o,g)
f=m-1
for(r=n.length;k>0;){e=A.dU(l,n,f);--k
A.cB(e,g,0,n,k,o)
if(!(f>=0&&f<r))return A.a(n,f)
if(n[f]<e){i=A.bY(g,o,k,j)
A.aY(n,h,j,i,n)
while(--e,n[f]<e)A.aY(n,h,j,i,n)}--f}$.cw=d.b
$.cx=c
$.cy=t
$.cz=s
$.bU.b=n
$.bV.b=h
$.au.b=o
$.bW.b=q},
T(a,b){if(b.c===0)throw A.b(B.u)
return this.V(b)},
m(a){var t,s
if(a<0)throw A.b(A.W("Exponent must not be negative: "+a))
if(a===0)return $.J()
t=$.J()
for(s=this;a!==0;){if((a&1)===1)t=t.i(0,s)
a=B.b.H(a,1)
if(a!==0)s=s.i(0,s)}return t},
h(a){var t,s,r,q,p,o=this,n=o.c
if(n===0)return"0"
if(n===1){if(o.a){n=o.b
if(0>=n.length)return A.a(n,0)
return B.b.h(-n[0])}n=o.b
if(0>=n.length)return A.a(n,0)
return B.b.h(n[0])}t=A.E([],u.s)
n=o.a
s=n?o.q(0):o
while(s.c>1){r=$.c9()
if(r.c===0)A.F(B.u)
q=s.a5(r).h(0)
B.a.j(t,q)
p=q.length
if(p===1)B.a.j(t,"000")
if(p===2)B.a.j(t,"00")
if(p===3)B.a.j(t,"0")
s=s.V(r)}r=s.b
if(0>=r.length)return A.a(r,0)
B.a.j(t,B.b.h(r[0]))
if(n)B.a.j(t,"-")
return new A.ap(t,u.r).az(0)},
$idn:1}
A.bo.prototype={
h(a){return this.a4()}}
A.b7.prototype={}
A.b5.prototype={
h(a){var t=this.a
if(t!=null)return"Assertion failed: "+A.b8(t)
return"Assertion failed"}}
A.bj.prototype={}
A.V.prototype={
gX(){return"Invalid argument"+(!this.a?"(s)":"")},
gW(){return""},
h(a){var t=this,s=t.c,r=s==null?"":" ("+s+")",q=t.d,p=q==null?"":": "+q,o=t.gX()+r+p
if(!t.a)return o
return o+t.gW()+": "+A.b8(t.gY())},
gY(){return this.b}}
A.aS.prototype={
gY(){return A.cO(this.b)},
gX(){return"RangeError"},
gW(){var t,s=this.e,r=this.f
if(s==null)t=r!=null?": Not less than or equal to "+A.d(r):""
else if(r==null)t=": Not greater than or equal to "+A.d(s)
else if(r>s)t=": Not in inclusive range "+A.d(s)+".."+A.d(r)
else t=r<s?": Valid value range is empty":": Only valid value is "+A.d(s)
return t}}
A.ba.prototype={
gY(){return A.a3(this.b)},
gX(){return"RangeError"},
gW(){if(A.a3(this.b)<0)return": index must not be negative"
var t=this.f
if(t===0)return": no indices are valid"
return": index should be less than "+t},
gk(a){return this.f}}
A.aW.prototype={
h(a){return"Unsupported operation: "+this.a}}
A.bk.prototype={
h(a){return"UnimplementedError: "+this.a}}
A.bg.prototype={
h(a){return"Bad state: "+this.a}}
A.b6.prototype={
h(a){var t=this.a
if(t==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.b8(t)+"."}}
A.bd.prototype={
h(a){return"Out of Memory"}}
A.aH.prototype={
h(a){var t=this.a,s=""!==t?"FormatException: "+t:"FormatException",r=this.b
if(typeof r=="string"){if(r.length>78)r=B.c.P(r,0,75)+"..."
return s+"\n"+r}else return s}}
A.bb.prototype={
h(a){return"IntegerDivisionByZeroException"}}
A.m.prototype={
gk(a){var t,s=this.gM(this)
for(t=0;s.n();)++t
return t},
h(a){return A.dy(this,"(",")")}}
A.ao.prototype={
h(a){return"null"}}
A.p.prototype={$ip:1,
h(a){return"Instance of '"+A.aR(this)+"'"},
gu(a){return A.eY(this)},
toString(){return this.h(this)}}
A.bh.prototype={
gk(a){return this.a.length},
h(a){var t=this.a
return t.charCodeAt(0)==0?t:t}}
A.aq.prototype={
a4(){return"RoundingMode."+this.b}}
A.r.prototype={
a8(a){return this.a.i(0,$.B().m(a-this.b))},
i(a,b){return new A.r(this.a.i(0,b.a),this.b+b.b)},
K(a,b){var t=this,s=a-t.b
if(s===0)return t
if(s>0)return new A.r(t.a.i(0,$.B().m(s)),a)
return new A.r(A.cc(t.a,$.B().m(-s),b),a)},
a1(){var t,s,r,q=this.a,p=$.q(),o=q.p(0,p)
if(o===0)return $.aC()
t=this.b
for(;;){o=$.B()
if(o.c===0)A.F(B.u)
s=q.a5(o)
if(s.a)s=o.a?s.F(0,o):s.I(0,o)
r=s.p(0,p)
if(!(r===0))break
q=q.V(o);--t}return new A.r(q,t)},
D(){var t,s,r=this.a,q=r.a,p=(q?r.q(0):r).h(0),o=this.b
if(o<=0){r=r.p(0,$.q())
t=r===0?"0":p+B.c.i("0",-o)}else{r=p.length
if(r<=o)t="0."+B.c.aB(p,o,"0")
else{s=r-o
t=B.c.P(p,0,s)+"."+B.c.a2(p,s)}}return q?"-"+t:t},
h(a){return this.D()}}
A.b9.prototype={
h(a){return"ExpressionEvaluationException: "+this.a}}
A.br.prototype={
G(){var t,s,r=this.a,q=r.length
for(;;){t=this.b
s=t<q
if(!(s&&r[t]===" "))break
this.b=t+1}return s?r[t]:null},
ae(){var t,s=this,r=s.Z()
for(;;){t=s.G()
if(t==="+"){++s.b
r+=s.Z()}else if(t==="-"){++s.b
r-=s.Z()}else return r}},
Z(){var t,s,r=this,q=r.N()
for(;;){t=r.G()
if(t==="*"){++r.b
q*=r.N()}else if(t==="/"){++r.b
s=r.N()
if(s===0)throw A.b(A.ad("Division by zero!"))
q/=s}else return q}},
N(){var t=this,s=t.G()
if(s==="+"){++t.b
return t.N()}if(s==="-"){++t.b
return-t.N()}return t.aC()},
aC(){var t,s=this,r=s.G()
if(r==null)throw A.b(A.ad("Unexpected end of expression"))
if(r==="("){++s.b
t=s.ae()
if(s.G()!==")")throw A.b(A.ad('Expected ")"'));++s.b
return t}if(A.dZ(r)||r===".")return s.ao()
throw A.b(A.ad('Unexpected character "'+r+'" at position '+s.b))},
ao(){var t,s,r,q,p,o=this.b,n=this.a,m=n.length,l=o
for(;;){if(l<m){t=n[l]
if(0>=t.length)return A.a(t,0)
s=t.charCodeAt(0)
t=s>=48&&s<=57||t==="."}else t=!1
if(!t)break;++l
this.b=l}r=B.c.P(n,o,l)
q=B.c.ah(r,".")?"0"+r:r
p=A.cp(B.c.av(q,".")?q+"0":q)
if(p==null)throw A.b(A.ad('Invalid number "'+r+'"'))
return p}}
A.bi.prototype={
$1(a){var t=this.a.a
B.a.j(t,A.z(B.o,$.l(),null))
B.a.j(t,A.z(B.m,a,a.D()))},
$S:3}
A.h.prototype={
aA(a){return this.c.length}}
A.n.prototype={
a4(){return"TokenType."+this.b},
gac(){var t=this
return t===B.p||t===B.r||t===B.t||t===B.o},
gad(){var t=this
return t===B.l||t===B.k||t===B.i||t===B.e||t===B.f||t===B.h||t===B.j||t===B.d}}
A.H.prototype={
gk(a){return this.a.length},
sk(a,b){B.a.sk(this.a,b)},
C(a,b){var t=this.a
if(!(b>=0&&b<t.length))return A.a(t,b)
return t[b]},
O(a,b,c){u.q.a(c)
B.a.O(this.a,b,c)
return c},
au(){var t,s,r,q,p,o=A.E([],u.h)
for(t=A.N(this),s=new A.f(this,this.gk(0),t.l("f<c.E>")),t=t.l("c.E");s.n();){r=s.d
if(r==null)r=t.a(r)
q=r.a
p=r.b
r=r.c
B.a.j(o,new A.h(q,p,r))}return new A.H(o)},
h(a){var t,s,r,q,p
for(t=A.N(this),s=new A.f(this,this.gk(0),t.l("f<c.E>")),t=t.l("c.E"),r="";s.n();r=q){q=s.d
if(q==null)q=t.a(q)
p=q.a
$label0$0:{if(B.p===p){q="+"
break $label0$0}if(B.r===p){q="-"
break $label0$0}if(B.t===p){q="/"
break $label0$0}if(B.o===p){q="*"
break $label0$0}q=q.c
break $label0$0}q=r+q}return r.charCodeAt(0)==0?r:r},
aE(){var t,s,r,q,p
for(t=A.N(this),s=new A.f(this,this.gk(0),t.l("f<c.E>")),t=t.l("c.E"),r="";s.n();r=q){q=s.d
if(q==null)q=t.a(q)
p=q.a
$label0$0:{if(B.p===p){q=" +"
break $label0$0}if(B.r===p){q=" -"
break $label0$0}if(B.t===p){q=" /"
break $label0$0}if(B.o===p){q=" *"
break $label0$0}q=" "+q.c
break $label0$0}q=r+q}return B.c.af(r.charCodeAt(0)==0?r:r)},
aw(){var t,s,r
for(t=A.N(this),s=new A.f(this,this.gk(0),t.l("f<c.E>")),t=t.l("c.E");s.n();){r=s.d
r=(r==null?t.a(r):r).a
if(r===B.l||r===B.k||r===B.i||r===B.e||r===B.f||r===B.h||r===B.j||r===B.d)return!1}return!0}}
A.bx.prototype={
$1(a){return B.z.h(this.a/A.d0(a.D()))},
$S:5}
A.bG.prototype={
$2(a,b){return A.es(A.aB(a),A.aB(b))},
$S:6}
A.bH.prototype={
$1(a){return A.eA(A.aB(a))},
$S:7};(function aliases(){var t=J.L.prototype
t.ai=t.h})();(function installTearOffs(){var t=hunkHelpers._instance_0i
t(A.h.prototype,"gk","aA",4)})();(function inheritance(){var t=hunkHelpers.mixin,s=hunkHelpers.inherit,r=hunkHelpers.inheritMany
s(A.p,null)
r(A.p,[A.bO,J.aI,A.ar,J.aD,A.b7,A.m,A.f,A.Y,A.K,A.aM,A.b_,A.bm,A.bv,A.D,A.aZ,A.bs,A.c,A.o,A.bo,A.bd,A.aH,A.bb,A.ao,A.bh,A.r,A.b9,A.br,A.h])
r(J.aI,[J.aK,J.ag,J.aj,J.a0,J.a1,J.ah,J.a_])
r(J.aj,[J.L,J.v,A.O,A.am])
r(J.L,[J.aQ,J.as,J.G])
s(J.aJ,A.ar)
s(J.bc,J.v)
r(J.ah,[J.af,J.aL])
r(A.b7,[A.aN,A.bf,A.bp,A.b5,A.bj,A.V,A.aW,A.bk,A.bg,A.b6])
s(A.ac,A.m)
s(A.ak,A.ac)
s(A.ap,A.ak)
r(A.K,[A.aG,A.aV,A.bC,A.bE,A.bi,A.bx,A.bH])
r(A.aV,[A.aU,A.ab])
r(A.aG,[A.bD,A.bG])
r(A.am,[A.aO,A.a2])
s(A.av,A.a2)
s(A.aw,A.av)
s(A.al,A.aw)
r(A.al,[A.aP,A.an])
s(A.b0,A.bp)
r(A.V,[A.aS,A.ba])
r(A.bo,[A.aq,A.n])
s(A.H,A.c)
t(A.av,A.c)
t(A.aw,A.Y)})()
var v={G:typeof self!="undefined"?self:globalThis,typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{e:"int",d_:"double",a8:"num",i:"String",by:"bool",ao:"Null",y:"List",p:"Object",fm:"Map",x:"JSObject"},mangledNames:{},types:["@(@)","@(@,i)","@(i)","~(r)","e()","i(r)","i(i,i)","i(i)"],interceptorsByTag:null,leafTags:null,arrayRti:Symbol("$ti")}
A.eb(v.typeUniverse,JSON.parse('{"G":"L","aQ":"L","as":"L","fn":"O","aK":{"by":[],"t":[]},"ag":{"t":[]},"aj":{"x":[]},"L":{"x":[]},"v":{"y":["1"],"x":[],"m":["1"]},"aJ":{"ar":[]},"bc":{"v":["1"],"y":["1"],"x":[],"m":["1"]},"ah":{"a8":[]},"af":{"e":[],"a8":[],"t":[]},"aL":{"a8":[],"t":[]},"a_":{"i":[],"be":[],"t":[]},"ac":{"m":["1"]},"ak":{"m":["1"]},"ap":{"ak":["1"],"m":["1"]},"K":{"Z":[]},"aG":{"Z":[]},"aV":{"Z":[]},"aU":{"Z":[]},"ab":{"Z":[]},"aM":{"dK":[],"be":[]},"O":{"x":[],"t":[]},"am":{"x":[]},"aO":{"x":[],"t":[]},"a2":{"ai":["1"],"x":[]},"al":{"c":["e"],"y":["e"],"ai":["e"],"x":[],"m":["e"],"Y":["e"]},"aP":{"bT":[],"c":["e"],"y":["e"],"ai":["e"],"x":[],"m":["e"],"Y":["e"],"t":[],"c.E":"e"},"an":{"c":["e"],"y":["e"],"ai":["e"],"x":[],"m":["e"],"Y":["e"],"t":[],"c.E":"e"},"c":{"y":["1"],"m":["1"]},"e":{"a8":[]},"i":{"be":[]},"o":{"dn":[]},"H":{"c":["h"],"y":["h"],"m":["h"],"c.E":"h"},"dR":{"y":["e"],"m":["e"]},"bT":{"y":["e"],"m":["e"]}}'))
A.ea(v.typeUniverse,JSON.parse('{"ac":1,"a2":1}'))
var u=(function rtii(){var t=A.bA
return{Z:t("Z"),U:t("m<@>"),s:t("v<i>"),h:t("v<h>"),b:t("v<@>"),T:t("ag"),m:t("x"),g:t("G"),p:t("ai<@>"),j:t("y<@>"),P:t("ao"),K:t("p"),L:t("fo"),r:t("ap<i>"),N:t("i"),q:t("h"),R:t("t"),o:t("as"),y:t("by"),i:t("d_"),S:t("e"),O:t("ck<ao>?"),z:t("x?"),X:t("p?"),v:t("i?"),u:t("by?"),I:t("d_?"),t:t("e?"),n:t("a8?"),H:t("a8")}})();(function constants(){var t=hunkHelpers.makeConstList
B.J=J.aI.prototype
B.a=J.v.prototype
B.b=J.af.prototype
B.z=J.ah.prototype
B.c=J.a_.prototype
B.K=J.G.prototype
B.L=J.aj.prototype
B.N=A.an.prototype
B.A=J.aQ.prototype
B.w=J.as.prototype
B.u=new A.bb()
B.y=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
B.B=function() {
  var toStringFunction = Object.prototype.toString;
  function getTag(o) {
    var s = toStringFunction.call(o);
    return s.substring(8, s.length - 1);
  }
  function getUnknownTag(object, tag) {
    if (/^HTML[A-Z].*Element$/.test(tag)) {
      var name = toStringFunction.call(object);
      if (name == "[object Object]") return null;
      return "HTMLElement";
    }
  }
  function getUnknownTagGenericBrowser(object, tag) {
    if (object instanceof HTMLElement) return "HTMLElement";
    return getUnknownTag(object, tag);
  }
  function prototypeForTag(tag) {
    if (typeof window == "undefined") return null;
    if (typeof window[tag] == "undefined") return null;
    var constructor = window[tag];
    if (typeof constructor != "function") return null;
    return constructor.prototype;
  }
  function discriminator(tag) { return null; }
  var isBrowser = typeof HTMLElement == "function";
  return {
    getTag: getTag,
    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,
    prototypeForTag: prototypeForTag,
    discriminator: discriminator };
}
B.G=function(getTagFallback) {
  return function(hooks) {
    if (typeof navigator != "object") return hooks;
    var userAgent = navigator.userAgent;
    if (typeof userAgent != "string") return hooks;
    if (userAgent.indexOf("DumpRenderTree") >= 0) return hooks;
    if (userAgent.indexOf("Chrome") >= 0) {
      function confirm(p) {
        return typeof window == "object" && window[p] && window[p].name == p;
      }
      if (confirm("Window") && confirm("HTMLElement")) return hooks;
    }
    hooks.getTag = getTagFallback;
  };
}
B.C=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
B.F=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Firefox") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "GeoGeolocation": "Geolocation",
    "Location": "!Location",
    "WorkerMessageEvent": "MessageEvent",
    "XMLDocument": "!Document"};
  function getTagFirefox(o) {
    var tag = getTag(o);
    return quickMap[tag] || tag;
  }
  hooks.getTag = getTagFirefox;
}
B.E=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Trident/") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "HTMLDDElement": "HTMLElement",
    "HTMLDTElement": "HTMLElement",
    "HTMLPhraseElement": "HTMLElement",
    "Position": "Geoposition"
  };
  function getTagIE(o) {
    var tag = getTag(o);
    var newTag = quickMap[tag];
    if (newTag) return newTag;
    if (tag == "Object") {
      if (window.DataView && (o instanceof window.DataView)) return "DataView";
    }
    return tag;
  }
  function prototypeForTagIE(tag) {
    var constructor = window[tag];
    if (constructor == null) return null;
    return constructor.prototype;
  }
  hooks.getTag = getTagIE;
  hooks.prototypeForTag = prototypeForTagIE;
}
B.D=function(hooks) {
  var getTag = hooks.getTag;
  var prototypeForTag = hooks.prototypeForTag;
  function getTagFixed(o) {
    var tag = getTag(o);
    if (tag == "Document") {
      if (!!o.xmlVersion) return "!Document";
      return "!HTMLDocument";
    }
    return tag;
  }
  function prototypeForTagFixed(tag) {
    if (tag == "Document") return null;
    return prototypeForTag(tag);
  }
  hooks.getTag = getTagFixed;
  hooks.prototypeForTag = prototypeForTagFixed;
}
B.x=function(hooks) { return hooks; }

B.H=new A.bd()
B.I=new A.aH("Non-finite result",null)
B.l=new A.n("Year",7,"year")
B.i=new A.n("Month",8,"month")
B.k=new A.n("Week",9,"week")
B.e=new A.n("Day",10,"day")
B.f=new A.n("Hour",11,"hour")
B.h=new A.n("Minute",12,"minute")
B.j=new A.n("Second",13,"second")
B.d=new A.n("MSecond",14,"mSecond")
B.M=t([B.l,B.i,B.k,B.e,B.f,B.h,B.j,B.d],A.bA("v<n>"))
B.O=new A.aq(0,"down")
B.q=new A.aq(1,"halfUp")
B.P=new A.aq(2,"halfEven")
B.o=new A.n("\xd7",4,"multiply")
B.n=new A.n("ERROR",15,"error")
B.Q=new A.n("(",2,"parenthesesLeft")
B.r=new A.n("\u2212",1,"minus")
B.t=new A.n("\xf7",5,"divide")
B.p=new A.n("+",0,"plus")
B.v=new A.n(")",3,"parenthesesRight")
B.m=new A.n("0.0",6,"number")
B.R=A.bJ("fi")
B.S=A.bJ("fj")
B.T=A.bJ("bT")
B.U=A.bJ("dR")})();(function staticFields(){$.bq=null
$.I=A.E([],A.bA("v<p>"))
$.cf=null
$.ce=null
$.d1=null
$.cX=null
$.d4=null
$.bz=null
$.bF=null
$.c6=null
$.cw=null
$.cx=null
$.cy=null
$.cz=null
$.bU=A.bn("_lastQuoRemDigits")
$.bV=A.bn("_lastQuoRemUsed")
$.au=A.bn("_lastRemUsed")
$.bW=A.bn("_lastRem_nsh")})();(function lazyInitializers(){var t=hunkHelpers.lazyFinal,s=hunkHelpers.lazy
t($,"fk","c8",()=>A.eX("_$dart_dartClosure"))
t($,"fw","db",()=>A.E([new J.aJ()],A.bA("v<ar>")))
t($,"fv","q",()=>A.at(0))
t($,"ft","J",()=>A.at(1))
t($,"fu","da",()=>A.at(2))
t($,"fr","ca",()=>$.J().q(0))
t($,"fp","c9",()=>A.at(1e4))
s($,"fs","d9",()=>A.bQ("^\\s*([+-]?)((0x[a-f0-9]+)|(\\d+)|([a-z0-9]+))\\s*$",!1))
t($,"fq","d8",()=>new Uint8Array(A.eq(8)))
t($,"fh","aC",()=>A.cb($.q(),0))
t($,"fg","l",()=>A.cb($.J(),0))
t($,"ff","B",()=>A.ct(10))
t($,"fe","d6",()=>A.bQ("^([+-]?)(\\d*)(\\.(\\d*))?([eE]([+-]?\\d+))?$",!0))
t($,"fH","b4",()=>A.X(1000))
t($,"fL","dh",()=>A.X(60))
t($,"fK","dg",()=>A.X(60))
t($,"fB","df",()=>A.X(24))
t($,"fy","dd",()=>A.X(7))
t($,"fx","dc",()=>A.X(30))
t($,"fz","de",()=>A.X(365))
t($,"fF","b3",()=>$.b4().i(0,$.dh()))
t($,"fE","b2",()=>$.b3().i(0,$.dg()))
t($,"fD","a9",()=>$.b2().i(0,$.df()))
t($,"fI","bL",()=>$.a9().i(0,$.dd()))
t($,"fG","bK",()=>$.a9().i(0,$.dc()))
t($,"fJ","bM",()=>$.a9().i(0,$.de()))
t($,"fl","d7",()=>A.bQ("-?[\\d.]+",!0))})();(function nativeSupport(){!function(){var t=function(a){var n={}
n[a]=1
return Object.keys(hunkHelpers.convertToFastObject(n))[0]}
v.getIsolateTag=function(a){return t("___dart_"+a+v.isolateTag)}
var s="___dart_isolate_tags_"
var r=Object[s]||(Object[s]=Object.create(null))
var q="_ZxYxX"
for(var p=0;;p++){var o=t(q+"_"+p+"_")
if(!(o in r)){r[o]=1
v.isolateTag=o
break}}v.dispatchPropertyName=v.getIsolateTag("dispatch_record")}()
hunkHelpers.setOrUpdateInterceptorsByTag({ArrayBuffer:A.O,SharedArrayBuffer:A.O,ArrayBufferView:A.am,DataView:A.aO,Uint16Array:A.aP,Uint8Array:A.an})
hunkHelpers.setOrUpdateLeafTags({ArrayBuffer:true,SharedArrayBuffer:true,ArrayBufferView:false,DataView:true,Uint16Array:true,Uint8Array:false})
A.a2.$nativeSuperclassTag="ArrayBufferView"
A.av.$nativeSuperclassTag="ArrayBufferView"
A.aw.$nativeSuperclassTag="ArrayBufferView"
A.al.$nativeSuperclassTag="ArrayBufferView"})()
Function.prototype.$1=function(a){return this(a)}
Function.prototype.$2=function(a,b){return this(a,b)}
Function.prototype.$0=function(){return this()}
convertAllToFastObject(w)
convertToFastObject($);(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!="undefined"){a(document.currentScript)
return}var t=document.scripts
function onLoad(b){for(var r=0;r<t.length;++r){t[r].removeEventListener("load",onLoad,false)}a(b.target)}for(var s=0;s<t.length;++s){t[s].addEventListener("load",onLoad,false)}})(function(a){v.currentScript=a
var t=A.f6
if(typeof dartMainRunner==="function"){dartMainRunner(t,[])}else{t([])}})})()
//# sourceMappingURL=time_engine.js.map

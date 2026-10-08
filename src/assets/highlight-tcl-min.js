/*!
  Highlight.js v11.12.0 (git: fc3f06392f)
  (c) 2006-2026 Josh Goebel <hello@joshgoebel.com> and other contributors
  License: BSD-3-Clause
 */
var hljs=function(){"use strict";class e{constructor(e){
void 0===e.data&&(e.data={}),this.data=e.data,this.isMatchIgnored=!1}
ignoreMatch(){this.isMatchIgnored=!0}}function t(e){
return e.replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;").replace(/'/g,"&#x27;")
}function n(e,...t){const n=Object.create(null);for(const t in e)n[t]=e[t]
;return t.forEach(e=>{for(const t in e)n[t]=e[t]}),n}function i(e){
if(null===e||"object"!=typeof e||Object.isFrozen(e))return e;Object.freeze(e)
;for(const t of Object.getOwnPropertyNames(e))i(e[t]);return e}
const r=e=>!!e.scope;class s{constructor(e,t){
this.buffer="",this.classPrefix=t.classPrefix,e.walk(this)}addText(e){
this.buffer+=t(e)}openNode(e){if(!r(e))return;const t=((e,{prefix:t})=>{
if(e.startsWith("language:"))return e.replace("language:","language-")
;if(e.includes(".")){const n=e.split(".")
;return[`${t}${n.shift()}`,...n.map((e,t)=>`${e}${"_".repeat(t+1)}`)].join(" ")}
return`${t}${e}`})(e.scope,{prefix:this.classPrefix});this.span(t)}closeNode(e){
r(e)&&(this.buffer+="</span>")}value(){return this.buffer}span(e){
this.buffer+=`<span class="${e}">`}}const o=(e={})=>{const t={children:[]}
;return Object.assign(t,e),t};class a{constructor(){
this.rootNode=o(),this.stack=[this.rootNode]}get top(){
return this.stack[this.stack.length-1]}get root(){return this.rootNode}add(e){
this.top.children.push(e)}openNode(e){const t=o({scope:e})
;this.add(t),this.stack.push(t)}closeNode(){
if(this.stack.length>1)return this.stack.pop()}closeAllNodes(){
for(;this.closeNode(););}toJSON(){return JSON.stringify(this.rootNode,null,4)}
walk(e){return this.constructor._walk(e,this.rootNode)}static _walk(e,t){
return"string"==typeof t?e.addText(t):t.children&&(e.openNode(t),
t.children.forEach(t=>this._walk(e,t)),e.closeNode(t)),e}static _collapse(e){
"string"!=typeof e&&e.children&&(e.children.every(e=>"string"==typeof e)?e.children=[e.children.join("")]:e.children.forEach(e=>{
a._collapse(e)}))}}class l extends a{constructor(e){super(),this.options=e}
addText(e){""!==e&&this.add(e)}startScope(e){this.openNode(e)}endScope(){
this.closeNode()}__addSublanguage(e,t){const n=e.root
;t&&(n.scope="language:"+t),this.add(n)}toHTML(){
return new s(this,this.options).value()}finalize(){
return this.closeAllNodes(),!0}}function c(e){
return e?"string"==typeof e?e:e.source:null}function g(e){return h("(?=",e,")")}
function u(e){return h("(?:",e,")*")}function d(e){return h("(?:",e,")?")}
function h(...e){return e.map(e=>c(e)).join("")}function p(...e){const t=(e=>{
const t=e[e.length-1]
;return"object"==typeof t&&t.constructor===Object?(e.splice(e.length-1,1),t):{}
})(e);return"("+(t.capture?"":"?:")+e.map(e=>c(e)).join("|")+")"}function f(e){
return RegExp(e.toString()+"|").exec("").length-1}
const b=RegExp(p(/\[(?:[^\\\]]|\\.)*\]/,/\(\?<(?![=!])[^>]+>/,/\(\?'[^']+'/,/\(\??/,/\\([1-9][0-9]*)/,/\\./))
;function m(e,{joinWith:t}){let n=0;return e.map(e=>{n+=1;const t=n
;let i=c(e),r="";for(;i.length>0;){const e=b.exec(i);if(!e){r+=i;break}
r+=i.substring(0,e.index),
i=i.substring(e.index+e[0].length),"\\"===e[0][0]&&e[1]?r+="\\"+(Number(e[1])+t):(r+=e[0],
("("===e[0]||/^\(\?[<']/.test(e[0]))&&n++)}return r}).map(e=>`(${e})`).join(t)}
const _="[a-zA-Z]\\w*",x="[a-zA-Z_]\\w*",E="\\b\\d+(\\.\\d+)?",y="(-?)(\\b0[xX][a-fA-F0-9]+|(\\b\\d+(\\.\\d*)?|\\.\\d+)([eE][-+]?\\d+)?)",w="\\b(0b[01]+)",k={
begin:"\\\\[\\s\\S]",relevance:0},O={scope:"string",begin:"'",end:"'",
illegal:"\\n",contains:[k]},v={scope:"string",begin:'"',end:'"',illegal:"\\n",
contains:[k]},N=(e,t,i={})=>{const r=n({scope:"comment",begin:e,end:t,
contains:[]},i);r.contains.push({scope:"doctag",
begin:"[ ]*(?=(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):)",
end:/(TODO|FIXME|NOTE|BUG|OPTIMIZE|HACK|XXX):/,excludeBegin:!0,relevance:0})
;const s=p("I","a","is","so","us","to","at","if","in","it","on",/[A-Za-z]+['](d|ve|re|ll|t|s|n)/,/[A-Za-z]+[-][a-z]+/,/[A-Za-z][a-z]{2,}/)
;return r.contains.push({begin:h(/[ ]+/,"(",s,/[.]?[:]?([.][ ]|[ ])/,"){3}")}),r
},M=N("//","$"),S=N("/\\*","\\*/"),A=N("#","$");var R=Object.freeze({
__proto__:null,APOS_STRING_MODE:O,BACKSLASH_ESCAPE:k,BINARY_NUMBER_MODE:{
scope:"number",begin:w,relevance:0},BINARY_NUMBER_RE:w,COMMENT:N,
C_BLOCK_COMMENT_MODE:S,C_LINE_COMMENT_MODE:M,C_NUMBER_MODE:{scope:"number",
begin:y,relevance:0},C_NUMBER_RE:y,END_SAME_AS_BEGIN:e=>Object.assign(e,{
"on:begin":(e,t)=>{t.data._beginMatch=e[1]},"on:end":(e,t)=>{
t.data._beginMatch!==e[1]&&t.ignoreMatch()}}),HASH_COMMENT_MODE:A,IDENT_RE:_,
MATCH_NOTHING_RE:/\b\B/,METHOD_GUARD:{begin:"\\.\\s*"+x,relevance:0},
NUMBER_MODE:{scope:"number",begin:E,relevance:0},NUMBER_RE:E,
PHRASAL_WORDS_MODE:{
begin:/\b(a|an|the|are|I'm|isn't|don't|doesn't|won't|but|just|should|pretty|simply|enough|gonna|going|wtf|so|such|will|you|your|they|like|more)\b/
},QUOTE_STRING_MODE:v,REGEXP_MODE:{scope:"regexp",begin:/\/(?=[^/\n]*\/)/,
end:/\/[gimuy]*/,contains:[k,{begin:/\[/,end:/\]/,relevance:0,contains:[k]}]},
RE_STARTERS_RE:"!|!=|!==|%|%=|&|&&|&=|\\*|\\*=|\\+|\\+=|,|-|-=|/=|/|:|;|<<|<<=|<=|<|===|==|=|>>>=|>>=|>=|>>>|>>|>|\\?|\\[|\\{|\\(|\\^|\\^=|\\||\\|=|\\|\\||~",
SHEBANG:(e={})=>{const t=/^#![ ]*\//
;return e.binary&&(e.begin=h(t,/.*\b/,e.binary,/\b.*/)),n({scope:"meta",begin:t,
end:/$/,relevance:0,"on:begin":(e,t)=>{0!==e.index&&t.ignoreMatch()}},e)},
TITLE_MODE:{scope:"title",begin:_,relevance:0},UNDERSCORE_IDENT_RE:x,
UNDERSCORE_TITLE_MODE:{scope:"title",begin:x,relevance:0}});function j(e,t){
"."===e.input[e.index-1]&&t.ignoreMatch()}function T(e,t){
void 0!==e.className&&(e.scope=e.className,delete e.className)}function I(e,t){
t&&e.beginKeywords&&(e.begin="\\b("+e.beginKeywords.split(" ").join("|")+")(?!\\.)(?=\\b|\\s)",
e.__beforeBegin=j,e.keywords=e.keywords||e.beginKeywords,delete e.beginKeywords,
void 0===e.relevance&&(e.relevance=0))}function B(e,t){
Array.isArray(e.illegal)&&(e.illegal=p(...e.illegal))}function L(e,t){
if(e.match){
if(e.begin||e.end)throw Error("begin & end are not supported with match")
;e.begin=e.match,delete e.match}}function P(e,t){
void 0===e.relevance&&(e.relevance=1)}const C=(e,t)=>{if(!e.beforeMatch)return
;if(e.starts)throw Error("beforeMatch cannot be used with starts")
;const n=Object.assign({},e);Object.keys(e).forEach(t=>{delete e[t]
}),e.keywords=n.keywords,e.begin=h(n.beforeMatch,g(n.begin)),e.starts={
relevance:0,contains:[Object.assign(n,{endsParent:!0})]
},e.relevance=0,delete n.beforeMatch
},D=["of","and","for","in","not","or","if","then","parent","list","value"]
;function H(e,t,n="keyword"){const i=Object.create(null)
;return"string"==typeof e?r(n,e.split(" ")):Array.isArray(e)?r(n,e):Object.keys(e).forEach(n=>{
Object.assign(i,H(e[n],t,n))}),i;function r(e,n){
t&&(n=n.map(e=>e.toLowerCase())),n.forEach(t=>{const n=t.split("|")
;i[n[0]]=[e,$(n[0],n[1])]})}}function $(e,t){
return t?Number(t):(e=>D.includes(e.toLowerCase()))(e)?0:1}const U={},z=e=>{
console.error(e)},W=(e,...t)=>{console.log("WARN: "+e,...t)},Z=(e,t)=>{
U[`${e}/${t}`]||(console.log(`Deprecated as of ${e}. ${t}`),U[`${e}/${t}`]=!0)
},G=Error();function K(e,t,{key:n}){let i=0;const r=e[n],s={},o={}
;for(let e=1;e<=t.length;e++)o[e+i]=r[e],s[e+i]=!0,i+=f(t[e-1])
;e[n]=o,e[n]._emit=s,e[n]._multi=!0}function X(e){(e=>{
e.scope&&"object"==typeof e.scope&&null!==e.scope&&(e.beginScope=e.scope,
delete e.scope)})(e),"string"==typeof e.beginScope&&(e.beginScope={
_wrap:e.beginScope}),"string"==typeof e.endScope&&(e.endScope={_wrap:e.endScope
}),(e=>{if(Array.isArray(e.begin)){
if(e.skip||e.excludeBegin||e.returnBegin)throw z("skip, excludeBegin, returnBegin not compatible with beginScope: {}"),
G
;if("object"!=typeof e.beginScope||null===e.beginScope)throw z("beginScope must be object"),
G;K(e,e.begin,{key:"beginScope"}),e.begin=m(e.begin,{joinWith:""})}})(e),(e=>{
if(Array.isArray(e.end)){
if(e.skip||e.excludeEnd||e.returnEnd)throw z("skip, excludeEnd, returnEnd not compatible with endScope: {}"),
G
;if("object"!=typeof e.endScope||null===e.endScope)throw z("endScope must be object"),
G;K(e,e.end,{key:"endScope"}),e.end=m(e.end,{joinWith:""})}})(e)}function F(e){
function t(t,n){
return RegExp(c(t),"m"+(e.case_insensitive?"i":"")+(e.unicodeRegex?"u":"")+(n?"g":""))
}class i{constructor(){
this.matchIndexes={},this.regexes=[],this.matchAt=1,this.position=0}
addRule(e,t){
t.position=this.position++,this.matchIndexes[this.matchAt]=t,this.regexes.push([t,e]),
this.matchAt+=f(e)+1}compile(){0===this.regexes.length&&(this.exec=()=>null)
;const e=this.regexes.map(e=>e[1]);this.matcherRe=t(m(e,{joinWith:"|"
}),!0),this.lastIndex=0}exec(e){this.matcherRe.lastIndex=this.lastIndex
;const t=this.matcherRe.exec(e);if(!t)return null
;const n=t.findIndex((e,t)=>t>0&&void 0!==e),i=this.matchIndexes[n]
;return t.splice(0,n),Object.assign(t,i)}}class r{constructor(){
this.rules=[],this.multiRegexes=[],
this.count=0,this.lastIndex=0,this.regexIndex=0}getMatcher(e){
if(this.multiRegexes[e])return this.multiRegexes[e];const t=new i
;return this.rules.slice(e).forEach(([e,n])=>t.addRule(e,n)),
t.compile(),this.multiRegexes[e]=t,t}resumingScanAtSamePosition(){
return 0!==this.regexIndex}considerAll(){this.regexIndex=0}addRule(e,t){
this.rules.push([e,t]),"begin"===t.type&&this.count++}exec(e){
const t=this.getMatcher(this.regexIndex);t.lastIndex=this.lastIndex
;let n=t.exec(e)
;if(this.resumingScanAtSamePosition())if(n&&n.index===this.lastIndex);else{
const t=this.getMatcher(0);t.lastIndex=this.lastIndex+1,n=t.exec(e)}
return n&&(this.regexIndex+=n.position+1,
this.regexIndex===this.count&&this.considerAll()),n}}
if(e.compilerExtensions||(e.compilerExtensions=[]),
e.contains&&e.contains.includes("self"))throw Error("ERR: contains `self` is not supported at the top-level of a language.  See documentation.")
;return e.classNameAliases=n(e.classNameAliases||{}),function i(s,o){const a=s
;if(s.isCompiled)return a
;[T,L,X,C].forEach(e=>e(s,o)),e.compilerExtensions.forEach(e=>e(s,o)),
s.__beforeBegin=null,[I,B,P].forEach(e=>e(s,o)),s.isCompiled=!0;let l=null
;return"object"==typeof s.keywords&&s.keywords.$pattern&&(s.keywords=Object.assign({},s.keywords),
l=s.keywords.$pattern,
delete s.keywords.$pattern),l=l||/\w+/,s.keywords&&(s.keywords=H(s.keywords,e.case_insensitive)),
a.keywordPatternRe=t(l,!0),
o&&(s.begin||(s.begin=/\B|\b/),a.beginRe=t(a.begin),s.end||s.endsWithParent||(s.end=/\B|\b/),
s.end&&(a.endRe=t(a.end)),
a.terminatorEnd=c(a.end)||"",s.endsWithParent&&o.terminatorEnd&&(a.terminatorEnd+=(s.end?"|":"")+o.terminatorEnd)),
s.illegal&&(a.illegalRe=t(s.illegal)),
s.contains||(s.contains=[]),s.contains=[].concat(...s.contains.map(e=>(e=>(e.variants&&!e.cachedVariants&&(e.cachedVariants=e.variants.map(t=>n(e,{
variants:null},t))),e.cachedVariants?e.cachedVariants:V(e)?n(e,{
starts:e.starts?n(e.starts):null
}):Object.isFrozen(e)?n(e):e))("self"===e?s:e))),s.contains.forEach(e=>{i(e,a)
}),s.starts&&i(s.starts,o),a.matcher=(e=>{const t=new r
;return e.contains.forEach(e=>t.addRule(e.begin,{rule:e,type:"begin"
})),e.terminatorEnd&&t.addRule(e.terminatorEnd,{type:"end"
}),e.illegal&&t.addRule(e.illegal,{type:"illegal"}),t})(a),a}(e)}function V(e){
return!!e&&(e.endsWithParent||V(e.starts))}class q extends Error{
constructor(e,t){super(e),this.name="HTMLInjectionError",this.html=t}}
const Y=t,J=n,Q=Symbol("nomatch"),ee=t=>{
const n=Object.create(null),r=Object.create(null),s=[];let o=!0
;const a="Could not find the language '{}', did you forget to load/include a language module?",c={
disableAutodetect:!0,name:"Plain text",contains:[]};let f={
ignoreUnescapedHTML:!1,throwUnescapedHTML:!1,noHighlightRe:/^(no-?highlight)$/i,
languageDetectRe:/\blang(?:uage)?-([\w-]+)\b/i,classPrefix:"hljs-",
cssSelector:"pre code",languages:null,__emitter:l};function b(e){
return f.noHighlightRe.test(e)}function m(e,t,n){let i="",r=""
;"object"==typeof t?(i=e,
n=t.ignoreIllegals,r=t.language):(Z("10.7.0","highlight(lang, code, ...args) has been deprecated."),
Z("10.7.0","Please use highlight(code, options) instead.\nhttps://github.com/highlightjs/highlight.js/issues/2277"),
r=e,i=t),void 0===n&&(n=!0);const s={code:i,language:r};N("before:highlight",s)
;const o=s.result?s.result:_(s.language,s.code,n)
;return o.code=s.code,N("after:highlight",o),o}function _(t,i,r,s){
const l=Object.create(null);function c(e,t){return e.keywords[t]}function g(){
if(!S.keywords)return void R.addText(j);let e=0;S.keywordPatternRe.lastIndex=0
;let t=S.keywordPatternRe.exec(j),n="";for(;t;){n+=j.substring(e,t.index)
;const i=O.case_insensitive?t[0].toLowerCase():t[0],r=c(S,i);if(r){const[e,s]=r
;if(R.addText(n),
n="",l[i]=(l[i]||0)+1,l[i]<=7&&(T+=s),e.startsWith("_"))n+=t[0];else{
const n=O.classNameAliases[e]||e;d(t[0],n)}}else n+=t[0]
;e=S.keywordPatternRe.lastIndex,t=S.keywordPatternRe.exec(j)}
n+=j.substring(e),R.addText(n)}function u(){null!=S.subLanguage?(()=>{
if(""===j)return;let e=null;if("string"==typeof S.subLanguage){
if(!n[S.subLanguage])return void R.addText(j)
;e=_(S.subLanguage,j,!0,A[S.subLanguage]),A[S.subLanguage]=e._top
}else e=x(j,S.subLanguage.length?S.subLanguage:null)
;S.relevance>0&&(T+=e.relevance),R.__addSublanguage(e._emitter,e.language)
})():g(),j=""}function d(e,t){
""!==e&&(R.startScope(t),R.addText(e),R.endScope())}function h(e,t){let n=1
;const i=t.length-1;for(;n<=i;){if(!e._emit[n]){n++;continue}
const i=O.classNameAliases[e[n]]||e[n],r=t[n];i?d(r,i):(j=r,g(),j=""),n++}}
function p(e,t){
return e.scope&&"string"==typeof e.scope&&R.openNode(O.classNameAliases[e.scope]||e.scope),
e.beginScope&&(e.beginScope._wrap?(d(j,O.classNameAliases[e.beginScope._wrap]||e.beginScope._wrap),
j=""):e.beginScope._multi&&(h(e.beginScope,t),j="")),M.push(e),S=e,S}
function b(t,n,i){const r=M[t];let s=((e,t)=>{const n=e&&e.exec(t)
;return n&&0===n.index})(r.endRe,i);if(s){if(r["on:end"]){const t=new e(r)
;r["on:end"](n,t),t.isMatchIgnored&&(s=!1)}if(s){for(;M[t].endsParent&&t>0;)t--
;return t}}return r.endsWithParent&&t>0?b(t-1,n,i):null}function m(e){
return 0===S.matcher.regexIndex?(j+=e[0],1):(L=!0,0)}function E(e){
const t=e[0],n=i.substring(e.index),r=b(M.length-1,e,n);if(null===r)return Q
;const s=M[r],o=S
;for(S.endScope&&S.endScope._wrap?(u(),d(t,S.endScope._wrap)):S.endScope&&S.endScope._multi?(u(),
h(S.endScope,e)):o.skip?j+=t:(o.returnEnd||o.excludeEnd||(j+=t),
u(),o.excludeEnd&&(j=t));M.length>r;)S.scope&&R.closeNode(),
S.skip||S.subLanguage||(T+=S.relevance),M.pop(),S=M[M.length-1]
;return s.starts&&p(s.starts,e),o.returnEnd?0:t.length}let y={};function w(n,s){
const a=s&&s[0];if(j+=n,null==a)return u(),0
;if("begin"===y.type&&"end"===s.type&&y.index===s.index&&""===a){
if(j+=i.slice(s.index,s.index+1),!o){const e=Error(`0 width match regex (${t})`)
;throw e.languageName=t,e.badRule=y.rule,e}return 1}
if(y=s,"begin"===s.type)return(t=>{
const n=t[0],i=t.rule,r=new e(i),s=[i.__beforeBegin,i["on:begin"]]
;for(const e of s)if(e&&(e(t,r),r.isMatchIgnored))return m(n)
;return i.skip?j+=n:(i.excludeBegin&&(j+=n),
u(),i.returnBegin||i.excludeBegin||(j=n)),p(i,t),i.returnBegin?0:n.length})(s)
;if("illegal"===s.type&&!r){
const e=Error('Illegal lexeme "'+a+'" for mode "'+(S.scope||"<unnamed>")+'"')
;throw e.mode=S,e}if("end"===s.type){const e=E(s);if(e!==Q)return e}
if("illegal"===s.type&&""===a)return s.index===i.length||(j+="\n"),1
;if(B>1e5&&B>3*s.index)throw Error("potential infinite loop, way more iterations than matches")
;return j+=a,a.length}const O=k(t)
;if(!O)throw z(a.replace("{}",t)),Error('Unknown language: "'+t+'"')
;const v=F(O);let N="";const M=s?s.slice():[v];let S=M[M.length-1]
;const A={},R=new f.__emitter(f);(()=>{for(let e=1;e<M.length;e++){
const t=M[e].scope;t&&R.openNode(t)}})();let j="",T=0,I=0,B=0,L=!1;try{
if(O.__emitTokens)O.__emitTokens(i,R);else{for(S.matcher.considerAll();;){
B++,L?L=!1:S.matcher.considerAll(),S.matcher.lastIndex=I
;const e=S.matcher.exec(i);if(!e)break;const t=w(i.substring(I,e.index),e)
;I=e.index+t}w(i.substring(I))}return R.finalize(),N=R.toHTML(),{language:t,
value:N,relevance:T,illegal:!1,_emitter:R,_top:M}}catch(e){
if(e.message&&e.message.includes("Illegal"))return{language:t,value:Y(i),
illegal:!0,relevance:0,_illegalBy:{message:e.message,index:I,
context:i.slice(I-100,I+100),mode:e.mode,resultSoFar:N},_emitter:R};if(o)return{
language:t,value:Y(i),illegal:!1,relevance:0,errorRaised:e,_emitter:R,_top:M}
;throw e}}function x(e,t){t=t||f.languages||Object.keys(n);const i=(e=>{
const t={value:Y(e),illegal:!1,relevance:0,_top:[c],_emitter:new f.__emitter(f)}
;return t._emitter.addText(e),t})(e),r=t.filter(k).filter(v).map(t=>_(t,e,!1))
;r.unshift(i);const s=r.sort((e,t)=>{
if(e.relevance!==t.relevance)return t.relevance-e.relevance
;if(e.language&&t.language){if(k(e.language).supersetOf===t.language)return 1
;if(k(t.language).supersetOf===e.language)return-1}return 0}),[o,a]=s,l=o
;return l.secondBest=a,l}function E(e){let t=null;const n=(e=>{
let t=e.className+" ";t+=e.parentNode?e.parentNode.className:""
;const n=f.languageDetectRe.exec(t);if(n){const t=k(n[1])
;return t||(W(a.replace("{}",n[1])),
W("Falling back to no-highlight mode for this block.",e)),t?n[1]:"no-highlight"}
return t.split(/\s+/).find(e=>b(e)||k(e))})(e);if(b(n))return
;if(N("before:highlightElement",{el:e,language:n
}),e.dataset.highlighted)return void console.log("Element previously highlighted. To highlight again, first unset `dataset.highlighted`.",e)
;if(e.children.length>0&&(f.ignoreUnescapedHTML||(console.warn("One of your code blocks includes unescaped HTML. This is a potentially serious security risk."),
console.warn("https://github.com/highlightjs/highlight.js/wiki/security"),
console.warn("The element with unescaped HTML:"),
console.warn(e)),f.throwUnescapedHTML))throw new q("One of your code blocks includes unescaped HTML.",e.innerHTML)
;t=e;const i=t.textContent,s=n?m(i,{language:n,ignoreIllegals:!0}):x(i)
;e.innerHTML=s.value,e.dataset.highlighted="yes",((e,t,n)=>{const i=t&&r[t]||n
;e.classList.add("hljs"),e.classList.add("language-"+i)
})(e,n,s.language),e.result={language:s.language,re:s.relevance,
relevance:s.relevance},s.secondBest&&(e.secondBest={
language:s.secondBest.language,relevance:s.secondBest.relevance
}),N("after:highlightElement",{el:e,result:s,text:i})}let y=!1;function w(){
if("loading"===document.readyState)return y||window.addEventListener("DOMContentLoaded",()=>{
w()},!1),void(y=!0);document.querySelectorAll(f.cssSelector).forEach(E)}
function k(e){return e=(e||"").toLowerCase(),n[e]||n[r[e]]}
function O(e,{languageName:t}){"string"==typeof e&&(e=[e]),e.forEach(e=>{
r[e.toLowerCase()]=t})}function v(e){const t=k(e);return t&&!t.disableAutodetect
}function N(e,t){const n=e;s.forEach(e=>{e[n]&&e[n](t)})}Object.assign(t,{
highlight:m,highlightAuto:x,highlightAll:w,highlightElement:E,
highlightBlock:e=>(Z("10.7.0","highlightBlock will be removed entirely in v12.0"),
Z("10.7.0","Please use highlightElement now."),E(e)),configure:e=>{f=J(f,e)},
initHighlighting:()=>{
w(),Z("10.6.0","initHighlighting() deprecated.  Use highlightAll() now.")},
initHighlightingOnLoad:()=>{
w(),Z("10.6.0","initHighlightingOnLoad() deprecated.  Use highlightAll() now.")
},registerLanguage:(e,i)=>{let r=null;try{r=i(t)}catch(t){
if(z("Language definition for '{}' could not be registered.".replace("{}",e)),
!o)throw t;z(t),r=c}
r.name||(r.name=e),n[e]=r,r.rawDefinition=i.bind(null,t),r.aliases&&O(r.aliases,{
languageName:e})},unregisterLanguage:e=>{delete n[e]
;for(const t of Object.keys(r))r[t]===e&&delete r[t]},
listLanguages:()=>Object.keys(n),getLanguage:k,registerAliases:O,
autoDetection:v,inherit:J,addPlugin:e=>{(e=>{
e["before:highlightBlock"]&&!e["before:highlightElement"]&&(e["before:highlightElement"]=t=>{
e["before:highlightBlock"](Object.assign({block:t.el},t))
}),e["after:highlightBlock"]&&!e["after:highlightElement"]&&(e["after:highlightElement"]=t=>{
e["after:highlightBlock"](Object.assign({block:t.el},t))})})(e),s.push(e)},
removePlugin:e=>{const t=s.indexOf(e);-1!==t&&s.splice(t,1)}}),t.debugMode=()=>{
o=!1},t.safeMode=()=>{o=!0},t.versionString="11.12.0",t.regex={concat:h,
lookahead:g,either:p,optional:d,anyNumberOfTimes:u}
;for(const e in R)"object"==typeof R[e]&&i(R[e]);return Object.assign(t,R),t
},te=ee({});te.newInstance=()=>ee({});var ne=Object.freeze({__proto__:null,
grmr_tcl:e=>{const t=e.regex,n=/[a-zA-Z_][a-zA-Z0-9_]*/,i={className:"number",
variants:[e.BINARY_NUMBER_MODE,e.C_NUMBER_MODE]};return{name:"Tcl",
aliases:["tk"],
keywords:["after","append","apply","array","auto_execok","auto_import","auto_load","auto_mkindex","auto_mkindex_old","auto_qualify","auto_reset","bgerror","binary","break","catch","cd","chan","clock","close","concat","continue","dde","dict","encoding","eof","error","eval","exec","exit","expr","fblocked","fconfigure","fcopy","file","fileevent","filename","flush","for","foreach","format","gets","glob","global","history","http","if","incr","info","interp","join","lappend|10","lassign|10","lindex|10","linsert|10","list","llength|10","load","lrange|10","lrepeat|10","lreplace|10","lreverse|10","lsearch|10","lset|10","lsort|10","mathfunc","mathop","memory","msgcat","namespace","open","package","parray","pid","pkg::create","pkg_mkIndex","platform","platform::shell","proc","puts","pwd","read","refchan","regexp","registry","regsub|10","rename","return","safe","scan","seek","set","socket","source","split","string","subst","switch","tcl_endOfWord","tcl_findLibrary","tcl_startOfNextWord","tcl_startOfPreviousWord","tcl_wordBreakAfter","tcl_wordBreakBefore","tcltest","tclvars","tell","time","tm","trace","unknown","unload","unset","update","uplevel","upvar","variable","vwait","while"],
contains:[e.COMMENT(";[ \\t]*#","$"),e.COMMENT("^[ \\t]*#","$"),{
beginKeywords:"proc",end:"[\\{]",excludeEnd:!0,contains:[{className:"title",
begin:"[ \\t\\n\\r]+(::)?[a-zA-Z_]((::)?[a-zA-Z0-9_])*",end:"[ \\t\\n\\r]",
endsWithParent:!0,excludeEnd:!0}]},{className:"variable",variants:[{
begin:t.concat(/\$/,t.optional(/::/),n,"(::",n,")*")},{
begin:"\\$\\{(::)?[a-zA-Z_]((::)?[a-zA-Z0-9_])*",end:"\\}",contains:[i]}]},{
className:"string",contains:[e.BACKSLASH_ESCAPE],
variants:[e.inherit(e.QUOTE_STRING_MODE,{illegal:null})]},i]}}});const ie=te
;for(const e of Object.keys(ne)){const t=e.replace("grmr_","").replace("_","-")
;ie.registerLanguage(t,ne[e])}return ie}()
;"object"==typeof exports&&"undefined"!=typeof module&&(module.exports=hljs);
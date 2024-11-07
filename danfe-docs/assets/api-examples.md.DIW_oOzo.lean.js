import{u as p,c as i,j as a,a as n,a3 as F,t as e,k as l,o as d}from"./chunks/framework.ohJJpums.js";const m={class:"language-bash vp-adaptive-theme"},u={class:"shiki github-dark-high-contrast",style:{"background-color":"#0a0c10",color:"#f0f3f6"},tabindex:"0"},y={class:"line"},D={style:{color:"#F0F3F6"}},f={class:"line"},g={style:{color:"#F0F3F6"}},C={class:"line"},b={style:{color:"#F0F3F6"}},B=JSON.parse('{"title":"Runtime API Examples","description":"","frontmatter":{"outline":"deep"},"headers":[],"relativePath":"api-examples.md","filePath":"api-examples.md"}'),P={name:"api-examples.md"},I=Object.assign(P,{setup(x){const{site:A,theme:t,page:o,frontmatter:r}=p();return(k,s)=>(d(),i("div",null,[s[24]||(s[24]=a("h1",{id:"runtime-api-examples",tabindex:"-1"},[n("Runtime API Examples "),a("a",{class:"header-anchor",href:"#runtime-api-examples","aria-label":'Permalink to "Runtime API Examples"'},"​")],-1)),s[25]||(s[25]=a("p",null,"This page demonstrates usage of some of the runtime APIs provided by VitePress.",-1)),s[26]||(s[26]=a("p",null,[n("The main "),a("code",null,"useData()"),n(" API can be used to access site, theme, and page data for the current page. It works in both "),a("code",null,".md"),n(" and "),a("code",null,".vue"),n(" files:")],-1)),a("div",m,[s[22]||(s[22]=a("button",{title:"Copy Code",class:"copy"},null,-1)),s[23]||(s[23]=a("span",{class:"lang"},"bash",-1)),a("pre",u,[a("code",null,[s[9]||(s[9]=F(`<span class="line"><span style="color:#FF9492;">&lt;</span><span style="color:#F0F3F6;">script setup</span><span style="color:#FF9492;">&gt;</span></span>
<span class="line"><span style="color:#FFB757;">import</span><span style="color:#ADDCFF;"> {</span><span style="color:#ADDCFF;"> useData</span><span style="color:#ADDCFF;"> }</span><span style="color:#ADDCFF;"> from</span><span style="color:#ADDCFF;"> &#39;vitepress&#39;</span></span>
<span class="line"></span>
<span class="line"><span style="color:#FFB757;">const</span><span style="color:#ADDCFF;"> {</span><span style="color:#ADDCFF;"> theme,</span><span style="color:#ADDCFF;"> page,</span><span style="color:#ADDCFF;"> frontmatter</span><span style="color:#ADDCFF;"> }</span><span style="color:#ADDCFF;"> =</span><span style="color:#ADDCFF;"> useData</span><span style="color:#F0F3F6;">()</span></span>
<span class="line"><span style="color:#FF9492;">&lt;</span><span style="color:#F0F3F6;">/script</span><span style="color:#FF9492;">&gt;</span></span>
<span class="line"></span>
<span class="line"><span style="color:#BDC4CC;">## Results</span></span>
<span class="line"></span>
<span class="line"><span style="color:#BDC4CC;">### Theme Data</span></span>
`,18)),a("span",y,[s[0]||(s[0]=a("span",{style:{color:"#FF9492"}},"<",-1)),s[1]||(s[1]=a("span",{style:{color:"#F0F3F6"}},"pre",-1)),s[2]||(s[2]=a("span",{style:{color:"#FF9492"}},">",-1)),a("span",D,e(l(t))+"</pre>",1)]),s[10]||(s[10]=n(`
`)),s[11]||(s[11]=a("span",{class:"line"},null,-1)),s[12]||(s[12]=n(`
`)),s[13]||(s[13]=a("span",{class:"line"},[a("span",{style:{color:"#BDC4CC"}},"### Page Data")],-1)),s[14]||(s[14]=n(`
`)),a("span",f,[s[3]||(s[3]=a("span",{style:{color:"#FF9492"}},"<",-1)),s[4]||(s[4]=a("span",{style:{color:"#F0F3F6"}},"pre",-1)),s[5]||(s[5]=a("span",{style:{color:"#FF9492"}},">",-1)),a("span",g,e(l(o))+"</pre>",1)]),s[15]||(s[15]=n(`
`)),s[16]||(s[16]=a("span",{class:"line"},null,-1)),s[17]||(s[17]=n(`
`)),s[18]||(s[18]=a("span",{class:"line"},[a("span",{style:{color:"#BDC4CC"}},"### Page Frontmatter")],-1)),s[19]||(s[19]=n(`
`)),a("span",C,[s[6]||(s[6]=a("span",{style:{color:"#FF9492"}},"<",-1)),s[7]||(s[7]=a("span",{style:{color:"#F0F3F6"}},"pre",-1)),s[8]||(s[8]=a("span",{style:{color:"#FF9492"}},">",-1)),a("span",b,e(l(r))+"</pre>",1)]),s[20]||(s[20]=n(`
`)),s[21]||(s[21]=a("span",{class:"line"},null,-1))])])]),s[27]||(s[27]=a("h2",{id:"results",tabindex:"-1"},[n("Results "),a("a",{class:"header-anchor",href:"#results","aria-label":'Permalink to "Results"'},"​")],-1)),s[28]||(s[28]=a("h3",{id:"theme-data",tabindex:"-1"},[n("Theme Data "),a("a",{class:"header-anchor",href:"#theme-data","aria-label":'Permalink to "Theme Data"'},"​")],-1)),a("pre",null,e(l(t)),1),s[29]||(s[29]=a("h3",{id:"page-data",tabindex:"-1"},[n("Page Data "),a("a",{class:"header-anchor",href:"#page-data","aria-label":'Permalink to "Page Data"'},"​")],-1)),a("pre",null,e(l(o)),1),s[30]||(s[30]=a("h3",{id:"page-frontmatter",tabindex:"-1"},[n("Page Frontmatter "),a("a",{class:"header-anchor",href:"#page-frontmatter","aria-label":'Permalink to "Page Frontmatter"'},"​")],-1)),a("pre",null,e(l(r)),1),s[31]||(s[31]=a("h2",{id:"more",tabindex:"-1"},[n("More "),a("a",{class:"header-anchor",href:"#more","aria-label":'Permalink to "More"'},"​")],-1)),s[32]||(s[32]=a("p",null,[n("Check out the documentation for the "),a("a",{href:"https://vitepress.dev/reference/runtime-api#usedata",target:"_blank",rel:"noreferrer"},"full list of runtime APIs"),n(".")],-1))]))}});export{B as __pageData,I as default};

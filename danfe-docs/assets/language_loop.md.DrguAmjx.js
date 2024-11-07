import{_ as a,c as n,a3 as l,o as p}from"./chunks/framework.ohJJpums.js";const d=JSON.parse('{"title":"Loops","description":"","frontmatter":{},"headers":[],"relativePath":"language/loop.md","filePath":"language/loop.md"}'),o={name:"language/loop.md"};function e(t,s,c,F,r,i){return p(),n("div",null,s[0]||(s[0]=[l(`<h1 id="loops" tabindex="-1">Loops <a class="header-anchor" href="#loops" aria-label="Permalink to &quot;Loops&quot;">​</a></h1><p>Danfe has only two looping keyword: <code>for</code> and <code>ghum</code>, with several forms.</p><h2 id="condtion-for" tabindex="-1">Condtion <code>for</code> <a class="header-anchor" href="#condtion-for" aria-label="Permalink to &quot;Condtion \`for\`&quot;">​</a></h2><div class="vp-code-group vp-adaptive-theme"><div class="tabs"><input type="radio" name="group-Y_J5I" id="tab-2gEaftW" checked><label data-title="English" for="tab-2gEaftW">English</label><input type="radio" name="group-Y_J5I" id="tab-JaLqI6E"><label data-title="Nepali" for="tab-JaLqI6E">Nepali</label></div><div class="blocks"><div class="language-danfe vp-adaptive-theme active"><button title="Copy Code" class="copy"></button><span class="lang">danfe</span><pre class="shiki github-dark-high-contrast" style="background-color:#0a0c10;color:#f0f3f6;" tabindex="0"><code><span class="line"><span style="color:#FFB757;">sum</span><span style="color:#FF9492;"> =</span><span style="color:#91CBFF;"> 0</span></span>
<span class="line"><span style="color:#FFB757;">i</span><span style="color:#FF9492;"> =</span><span style="color:#91CBFF;"> 0</span></span>
<span class="line"></span>
<span class="line"><span style="color:#FF9492;">for</span><span style="color:#F0F3F6;"> i </span><span style="color:#FF9492;">&lt;</span><span style="color:#FFB1AF;font-style:italic;"> 100</span><span style="color:#F0F3F6;"> {     </span><span style="color:#BDC4CC;"># loop until i is less than 100</span></span>
<span class="line"><span style="color:#FFB757;">    sum</span><span style="color:#FF9492;"> =</span><span style="color:#F0F3F6;"> sum </span><span style="color:#FF9492;">+</span><span style="color:#F0F3F6;"> i</span></span>
<span class="line"><span style="color:#FFB757;">    i</span><span style="color:#FF9492;"> =</span><span style="color:#F0F3F6;"> i </span><span style="color:#FF9492;">+</span><span style="color:#91CBFF;"> 1</span></span>
<span class="line"><span style="color:#F0F3F6;">}</span></span>
<span class="line"></span>
<span class="line"><span style="color:#FF9492;">println</span><span style="color:#F0F3F6;">(sum)      </span><span style="color:#BDC4CC;"># &quot;4950&quot;</span></span>
<span class="line"></span></code></pre></div><div class="language-danfe vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">danfe</span><pre class="shiki github-dark-high-contrast" style="background-color:#0a0c10;color:#f0f3f6;" tabindex="0"><code><span class="line"><span style="color:#FFB757;">sum</span><span style="color:#FF9492;"> =</span><span style="color:#91CBFF;"> 0</span></span>
<span class="line"><span style="color:#FFB757;">i</span><span style="color:#FF9492;"> =</span><span style="color:#91CBFF;"> 0</span></span>
<span class="line"></span>
<span class="line"><span style="color:#FF9492;">ghum</span><span style="color:#F0F3F6;"> i </span><span style="color:#FF9492;">&lt;</span><span style="color:#FFB1AF;font-style:italic;"> 100</span><span style="color:#F0F3F6;"> {     </span><span style="color:#BDC4CC;"># loop until i is less than 100</span></span>
<span class="line"><span style="color:#FFB757;">    sum</span><span style="color:#FF9492;"> =</span><span style="color:#F0F3F6;"> sum </span><span style="color:#FF9492;">+</span><span style="color:#F0F3F6;"> i</span></span>
<span class="line"><span style="color:#FFB757;">    i</span><span style="color:#FF9492;"> =</span><span style="color:#F0F3F6;"> i </span><span style="color:#FF9492;">+</span><span style="color:#91CBFF;"> 1</span></span>
<span class="line"><span style="color:#F0F3F6;">}</span></span>
<span class="line"></span>
<span class="line"><span style="color:#DBB7FF;">dekhauln</span><span style="color:#F0F3F6;">(sum)      </span><span style="color:#BDC4CC;"># &quot;4950&quot;</span></span>
<span class="line"></span></code></pre></div></div></div><h2 id="bare-for" tabindex="-1">Bare <code>for</code> <a class="header-anchor" href="#bare-for" aria-label="Permalink to &quot;Bare \`for\`&quot;">​</a></h2><div class="vp-code-group vp-adaptive-theme"><div class="tabs"><input type="radio" name="group-xED_g" id="tab-ucJ9pro" checked><label data-title="English" for="tab-ucJ9pro">English</label><input type="radio" name="group-xED_g" id="tab-UgEmDbJ"><label data-title="Nepali" for="tab-UgEmDbJ">Nepali</label></div><div class="blocks"><div class="language-danfe vp-adaptive-theme active"><button title="Copy Code" class="copy"></button><span class="lang">danfe</span><pre class="shiki github-dark-high-contrast" style="background-color:#0a0c10;color:#f0f3f6;" tabindex="0"><code><span class="line"><span style="color:#FFB757;">num</span><span style="color:#FF9492;"> =</span><span style="color:#91CBFF;"> 0</span></span>
<span class="line"></span>
<span class="line"><span style="color:#FF9492;">for</span><span style="color:#F0F3F6;"> {     </span><span style="color:#BDC4CC;"># loops forever until stopped</span></span>
<span class="line"><span style="color:#FFB757;">    num</span><span style="color:#FF9492;"> =</span><span style="color:#F0F3F6;"> num </span><span style="color:#FF9492;">+</span><span style="color:#91CBFF;"> 2</span></span>
<span class="line"><span style="color:#FF9492;">    if</span><span style="color:#F0F3F6;"> num </span><span style="color:#FF9492;">&gt;</span><span style="color:#FFB1AF;font-style:italic;"> 10</span><span style="color:#F0F3F6;"> {</span></span>
<span class="line"><span style="color:#FF9492;">        break</span></span>
<span class="line"><span style="color:#F0F3F6;">    }</span></span>
<span class="line"><span style="color:#F0F3F6;">}</span></span>
<span class="line"></span>
<span class="line"><span style="color:#FF9492;">println</span><span style="color:#F0F3F6;">(num)      </span><span style="color:#BDC4CC;"># &quot;12&quot;</span></span>
<span class="line"></span></code></pre></div><div class="language-danfe vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">danfe</span><pre class="shiki github-dark-high-contrast" style="background-color:#0a0c10;color:#f0f3f6;" tabindex="0"><code><span class="line"><span style="color:#FFB757;">num</span><span style="color:#FF9492;"> =</span><span style="color:#91CBFF;"> 0</span></span>
<span class="line"></span>
<span class="line"><span style="color:#FF9492;">ghum</span><span style="color:#F0F3F6;"> {            </span><span style="color:#BDC4CC;"># loops forever until stopped</span></span>
<span class="line"><span style="color:#FFB757;">    num</span><span style="color:#FF9492;"> =</span><span style="color:#F0F3F6;"> num </span><span style="color:#FF9492;">+</span><span style="color:#91CBFF;"> 2</span></span>
<span class="line"><span style="color:#FF9492;">    if</span><span style="color:#F0F3F6;"> num </span><span style="color:#FF9492;">&gt;</span><span style="color:#FFB1AF;font-style:italic;"> 10</span><span style="color:#F0F3F6;"> {</span></span>
<span class="line"><span style="color:#FF9492;">        break</span><span style="color:#BDC4CC;">     # breaks out of the loop</span></span>
<span class="line"><span style="color:#F0F3F6;">    }</span></span>
<span class="line"><span style="color:#F0F3F6;">}</span></span>
<span class="line"></span>
<span class="line"><span style="color:#DBB7FF;">dekhauln</span><span style="color:#F0F3F6;">(num)      </span><span style="color:#BDC4CC;"># &quot;12&quot;</span></span>
<span class="line"></span></code></pre></div></div></div><h2 id="break-continue" tabindex="-1"><code>break</code> &amp; <code>continue</code> <a class="header-anchor" href="#break-continue" aria-label="Permalink to &quot;\`break\` &amp; \`continue\`&quot;">​</a></h2><div class="vp-code-group vp-adaptive-theme"><div class="tabs"><input type="radio" name="group-xC28c" id="tab-BQJrChH" checked><label data-title="English" for="tab-BQJrChH">English</label><input type="radio" name="group-xC28c" id="tab-hwoSPmr"><label data-title="Nepali" for="tab-hwoSPmr">Nepali</label></div><div class="blocks"><div class="language-danfe vp-adaptive-theme active"><button title="Copy Code" class="copy"></button><span class="lang">danfe</span><pre class="shiki github-dark-high-contrast" style="background-color:#0a0c10;color:#f0f3f6;" tabindex="0"><code><span class="line"><span style="color:#FFB757;">num</span><span style="color:#FF9492;"> =</span><span style="color:#91CBFF;"> 0</span></span>
<span class="line"></span>
<span class="line"><span style="color:#FF9492;">for</span><span style="color:#F0F3F6;"> {              </span><span style="color:#BDC4CC;"># loops forever until stopped</span></span>
<span class="line"><span style="color:#FFB757;">    num</span><span style="color:#FF9492;"> =</span><span style="color:#F0F3F6;"> num </span><span style="color:#FF9492;">+</span><span style="color:#91CBFF;"> 1</span></span>
<span class="line"><span style="color:#FF9492;">    if</span><span style="color:#F0F3F6;"> num </span><span style="color:#FF9492;">%</span><span style="color:#FFB1AF;font-style:italic;"> 2</span><span style="color:#F0F3F6;">  {  </span><span style="color:#BDC4CC;"># num % 2 != 0 </span></span>
<span class="line"><span style="color:#FF9492;">        continue</span><span style="color:#BDC4CC;">   # does not execute the instructions bellow</span></span>
<span class="line"><span style="color:#F0F3F6;">    }</span></span>
<span class="line"><span style="color:#FF9492;">    if</span><span style="color:#F0F3F6;"> num </span><span style="color:#FF9492;">&gt;</span><span style="color:#FFB1AF;font-style:italic;"> 10</span><span style="color:#F0F3F6;"> {</span></span>
<span class="line"><span style="color:#FF9492;">        break</span><span style="color:#BDC4CC;">      # breaks out of the loop</span></span>
<span class="line"><span style="color:#F0F3F6;">    }</span></span>
<span class="line"><span style="color:#FF9492;">    println</span><span style="color:#F0F3F6;">(num)</span></span>
<span class="line"><span style="color:#F0F3F6;">}</span></span>
<span class="line"></span>
<span class="line"></span></code></pre></div><div class="language-danfe vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">danfe</span><pre class="shiki github-dark-high-contrast" style="background-color:#0a0c10;color:#f0f3f6;" tabindex="0"><code><span class="line"><span style="color:#FFB757;">num</span><span style="color:#FF9492;"> =</span><span style="color:#91CBFF;"> 0</span></span>
<span class="line"></span>
<span class="line"><span style="color:#FF9492;">ghum</span><span style="color:#F0F3F6;"> {             </span><span style="color:#BDC4CC;"># loops forever until stopped</span></span>
<span class="line"><span style="color:#FFB757;">    num</span><span style="color:#FF9492;"> =</span><span style="color:#F0F3F6;"> num </span><span style="color:#FF9492;">+</span><span style="color:#91CBFF;"> 1</span></span>
<span class="line"><span style="color:#FF9492;">    if</span><span style="color:#F0F3F6;"> num </span><span style="color:#FF9492;">%</span><span style="color:#FFB1AF;font-style:italic;"> 2</span><span style="color:#F0F3F6;">  {  </span><span style="color:#BDC4CC;"># num % 2 != 0 </span></span>
<span class="line"><span style="color:#FF9492;">        xod</span><span style="color:#BDC4CC;">        # does not execute the instructions bellow</span></span>
<span class="line"><span style="color:#F0F3F6;">    }</span></span>
<span class="line"><span style="color:#FF9492;">    if</span><span style="color:#F0F3F6;"> num </span><span style="color:#FF9492;">&gt;</span><span style="color:#FFB1AF;font-style:italic;"> 10</span><span style="color:#F0F3F6;"> {</span></span>
<span class="line"><span style="color:#FF9492;">        todh</span><span style="color:#BDC4CC;">       # breaks out of the loop</span></span>
<span class="line"><span style="color:#F0F3F6;">    }</span></span>
<span class="line"><span style="color:#FF9492;">    println</span><span style="color:#F0F3F6;">(num)</span></span>
<span class="line"><span style="color:#F0F3F6;">}</span></span>
<span class="line"></span>
<span class="line"></span></code></pre></div></div></div><div class="language-md vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">md</span><pre class="shiki github-dark-high-contrast" style="background-color:#0a0c10;color:#f0f3f6;" tabindex="0"><code><span class="line"><span style="color:#91CBFF;font-weight:bold;"># Output</span></span>
<span class="line"><span style="color:#F0F3F6;">2</span></span>
<span class="line"><span style="color:#F0F3F6;">4</span></span>
<span class="line"><span style="color:#F0F3F6;">6</span></span>
<span class="line"><span style="color:#F0F3F6;">8</span></span>
<span class="line"><span style="color:#F0F3F6;">10</span></span>
<span class="line"></span></code></pre></div><div class="info custom-block"><p class="custom-block-title">INFO</p><p>Array and Table <code>for</code> where you use the <code>in</code> key word is comming soon...</p></div>`,10)]))}const u=a(o,[["render",e]]);export{d as __pageData,u as default};

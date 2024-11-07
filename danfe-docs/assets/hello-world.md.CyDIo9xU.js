import{_ as e,c as o,a3 as s,o as n}from"./chunks/framework.ohJJpums.js";const u=JSON.parse('{"title":"Hello World","description":"","frontmatter":{},"headers":[],"relativePath":"hello-world.md","filePath":"hello-world.md"}'),t={name:"hello-world.md"};function l(r,a,p,c,i,d){return n(),o("div",null,a[0]||(a[0]=[s(`<h1 id="hello-world" tabindex="-1">Hello World <a class="header-anchor" href="#hello-world" aria-label="Permalink to &quot;Hello World&quot;">​</a></h1><div class="language-danfe vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">danfe</span><pre class="shiki github-dark-high-contrast" style="background-color:#0a0c10;color:#f0f3f6;" tabindex="0"><code><span class="line"><span style="color:#FF9492;">println</span><span style="color:#F0F3F6;">(</span><span style="color:#ADDCFF;">&quot;Hello World&quot;</span><span style="color:#F0F3F6;">)</span></span>
<span class="line"></span></code></pre></div><p>Save this snippet into a file named <code>hello.df</code>. Now do: <code>./danfe run hello.df</code>. <br></p><p><strong>Congratulations 🎉</strong> - you just wrote and executed your first Danfe program! <br></p><p>In Danfe the <code>file you run is the entry point to your program</code>. But there is a special keyword defined called <code>__module__</code> which is initialized at the start. By using that keyword you can check if the file is the entry point or not.</p><div class="language-danfe vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">danfe</span><pre class="shiki github-dark-high-contrast" style="background-color:#0a0c10;color:#f0f3f6;" tabindex="0"><code><span class="line"><span style="color:#FF9492;">if</span><span style="color:#F0F3F6;"> __module__ </span><span style="color:#FF9492;">==</span><span style="color:#ADDCFF;"> &quot;main&quot;</span><span style="color:#F0F3F6;"> {</span></span>
<span class="line"><span style="color:#FF9492;">    println</span><span style="color:#F0F3F6;">(</span><span style="color:#ADDCFF;">&quot;Hello World&quot;</span><span style="color:#F0F3F6;">)</span></span>
<span class="line"><span style="color:#F0F3F6;">}</span></span>
<span class="line"></span></code></pre></div><p>This makes sure the function is called only if it is the <code>entry point</code> to the program. This feature is heavly inspired by the <code>__name__</code> feature of <a href="https://docs.python.org/3/library/__main__.html" target="_blank" rel="noreferrer">Python</a>.</p><p><code>println</code> is one of the few <a href="/built-in-functions.html">built-in functions</a>. It prints the value passed to it to standard output.</p><h2 id="intresting-fact" tabindex="-1">Intresting Fact: <a class="header-anchor" href="#intresting-fact" aria-label="Permalink to &quot;Intresting Fact:&quot;">​</a></h2><p>Most of the keyword is mapped to it&#39;s <code>nepali counterpart</code>. You can write the same <code>hello world</code> program as:</p><div class="language-danfe vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">danfe</span><pre class="shiki github-dark-high-contrast" style="background-color:#0a0c10;color:#f0f3f6;" tabindex="0"><code><span class="line"><span style="color:#BDC4CC;"># yedi is the nepali counterpart of if</span></span>
<span class="line"><span style="color:#FF9492;">yedi</span><span style="color:#F0F3F6;"> __module__ </span><span style="color:#FF9492;">==</span><span style="color:#ADDCFF;"> &quot;main&quot;</span><span style="color:#F0F3F6;"> {</span></span>
<span class="line"><span style="color:#BDC4CC;">    # dekhau is the nepali couterpart of print</span></span>
<span class="line"><span style="color:#DBB7FF;">    dekhau</span><span style="color:#F0F3F6;">(</span><span style="color:#ADDCFF;">&quot;Hello World&quot;</span><span style="color:#F0F3F6;">)</span></span>
<span class="line"><span style="color:#F0F3F6;">}</span></span>
<span class="line"></span></code></pre></div><p>Learn more about keywords <a href="/keywords.html">here</a>.</p>`,12)]))}const F=e(t,[["render",l]]);export{u as __pageData,F as default};

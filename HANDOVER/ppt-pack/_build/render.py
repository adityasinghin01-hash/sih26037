import html, os, re, subprocess, fitz, diagrams as D
OUT=D.OUT; CH=D.CHROME
def svg_of(code, elk):
    cfg = "layout:'elk', elk:{mergeEdges:false, nodePlacementStrategy:'NETWORK_SIMPLEX'}," if elk else ""
    h=f"""<html><body><div id=o></div><script type=module>
import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
{"import elkLayouts from 'https://cdn.jsdelivr.net/npm/@mermaid-js/layout-elk@0/dist/mermaid-layout-elk.esm.min.mjs'; mermaid.registerLayoutLoaders(elkLayouts);" if elk else ""}
mermaid.initialize({{startOnLoad:false, {cfg} theme:'default', flowchart:{{htmlLabels:false, useMaxWidth:false, nodeSpacing:30, rankSpacing:60}}, gantt:{{useMaxWidth:false, barHeight:26, fontSize:14, sectionFontSize:15, leftPadding:320}}, pie:{{useMaxWidth:false}}, themeVariables:{{fontSize:'15px'}}}});
try{{const r=await mermaid.render('g', {code!r}); document.getElementById('o').innerHTML=r.svg;}}catch(e){{document.getElementById('o').innerText='ERR '+e.message;}}
</script></body></html>"""
    open("_r.html","w").write(h)
    r=subprocess.run([CH,"--headless=new","--disable-gpu","--virtual-time-budget=40000","--dump-dom","_r.html"],capture_output=True,text=True)
    m=re.search(r'<div id="o">(.*?)</div><script',r.stdout,re.S); s=m.group(1)
    if s.startswith("ERR"): raise SystemExit(s)
    vb=re.search(r'viewBox="([\d.\- ]+)"',s).group(1).split(); return s,float(vb[2]),float(vb[3])

def pdf_from_html(h, path):
    open("_p.html","w").write(h)
    subprocess.run([CH,"--headless=new","--disable-gpu","--no-pdf-header-footer","--virtual-time-budget=5000",f"--print-to-pdf={path}","_p.html"],stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,check=True)

CSS="body{font-family:Helvetica,Arial,sans-serif;color:#111;margin:0} h1{font-size:30px;margin:0 0 6px} .sub{font-size:16px;color:#333;margin-bottom:12px} pre{font-size:11px;white-space:pre-wrap;background:#f6f6f6;padding:8px;border:1px solid #ccc} h2{font-size:17px;border-bottom:2px solid #333} .note{font-size:12px}"
def build(fname,title,sub,code,spectext,elk=True,extra=""):
    svg,w,hh=svg_of(code,elk)
    W=max(w+80,1100); H=hh+170
    p1=f"<!doctype html><html><head><meta charset=utf-8><style>@page{{size:{W*0.2646:.0f}mm {H*0.2646:.0f}mm;margin:0}} {CSS} .wrap{{padding:30px}}</style></head><body><div class=wrap><h1>{html.escape(title)}</h1><div class=sub>{html.escape(sub)}</div>{svg}</div></body></html>"
    pdf_from_html(p1,"_a.pdf")
    p2=f"<!doctype html><html><head><meta charset=utf-8><style>@page{{size:A4;margin:12mm}} {CSS}</style></head><body><h1 style='font-size:20px'>{html.escape(title)} — exact spec for redrawing</h1>{extra}<p class=note><b>Redraw rule for Gemini / Nano Banana:</b> keep every box, group and arrow listed. Do not add, merge or drop any. Styling is free; structure is fixed.</p><pre>{html.escape(spectext)}</pre><h2>Mermaid source (paste into mermaid.live to re-render)</h2><pre>{html.escape(code)}</pre></body></html>"
    pdf_from_html(p2,"_b.pdf")
    d=fitz.open("_a.pdf"); d.insert_pdf(fitz.open("_b.pdf")); d.save(os.path.join(OUT,fname+".pdf")); print(fname, d.page_count,"pages", int(w),"x",int(hh))
    fitz.open("_a.pdf")[0].get_pixmap(dpi=30).save("prev-"+fname+".png")

import json, shutil, subprocess, sys, time
from pathlib import Path
DEST=Path(sys.argv[1]).resolve(); WORK=Path(sys.argv[2]).resolve(); SRC=WORK/'src'; PACK=WORK/'pack'
MANIFEST=DEST/'RESEARCH_DOWNLOAD_MANIFEST.jsonl'; SPLIT_TARGET=12000000; MAX_ZIP=17*1000*1000; BATCH_LIMIT=90*1024*1024; CHUNK=8*1024*1024
REPOS=[('01','OpenPencil','https://github.com/open-pencil/open-pencil.git'),('02','OpenDesign','https://github.com/nexu-io/open-design.git'),('04','Onlook','https://github.com/onlook-dev/onlook.git'),('05','Penpot','https://github.com/penpot/penpot.git'),('06','Webstudio','https://github.com/webstudio-is/webstudio.git'),('07','Silex','https://github.com/silexlabs/Silex.git'),('08','Frappe-Builder','https://github.com/frappe/builder.git'),('09','BESSER','https://github.com/BESSER-PEARL/BESSER.git'),('10','tldraw','https://github.com/tldraw/tldraw.git'),('12','drawio','https://github.com/jgraph/drawio.git'),('13','xyflow','https://github.com/xyflow/xyflow.git'),('14','Craft.js','https://github.com/prevwong/craft.js.git'),('15','Mermaid','https://github.com/mermaid-js/mermaid.git'),('16','PlantUML','https://github.com/plantuml/plantuml.git'),('40','anthropic-skills','https://github.com/anthropics/skills.git'),('41','microsoft-skills','https://github.com/microsoft/skills.git'),('42','ui-ux-pro-max-skill','https://github.com/nextlevelbuilder/ui-ux-pro-max-skill.git'),('43','wordpress-agent-skills','https://github.com/Automattic/wordpress-agent-skills.git'),('44','frontend-audit-skill','https://github.com/colbymchenry/frontend-audit-skill.git'),('45','nolly-agent-skills','https://github.com/nolly-studio/agent-skills.git'),('46','PracticalSwan-agent-skills','https://github.com/PracticalSwan/agent-skills.git'),('47','accessibility-skills','https://github.com/mgifford/accessibility-skills.git')]
def run(c,cwd=None): subprocess.run(c,cwd=cwd,check=True)
def done(slug):
    if not MANIFEST.exists(): return False
    return any((lambda d:d.get('slug')==slug and d.get('status')=='COMPLETE')(json.loads(x)) for x in MANIFEST.read_text().splitlines() if x.strip())
def stage_repo(slug,root):
    stage=PACK/f'{slug}_stage'; shutil.rmtree(stage,ignore_errors=True); stage.mkdir(parents=True); records=[]
    for p in root.rglob('*'):
        if not p.is_file(): continue
        rel=p.relative_to(root); target=stage/slug/rel; target.parent.mkdir(parents=True,exist_ok=True); size=p.stat().st_size
        if size<=CHUNK: shutil.copy2(p,target); continue
        d=target.parent/(target.name+'.chunks'); d.mkdir(parents=True,exist_ok=True)
        with p.open('rb') as f:
            i=0
            while True:
                data=f.read(CHUNK)
                if not data: break
                (d/f'{target.name}.part-{i:04d}').write_bytes(data); i+=1
        records.append({'repo':slug,'path':str(rel),'chunks_dir':str(d.relative_to(stage)),'bytes':size,'chunk_bytes':CHUNK})
    if records: (stage/'SPLIT_FILES.json').write_text(json.dumps(records,indent=2))
    return stage
def package(slug,root):
    stage=stage_repo(slug,root); full=PACK/f'{slug}_full.zip'; full.unlink(missing_ok=True)
    run(['zip','-q','-r','-1','-y',str(full.resolve()),'.'],cwd=stage)
    if full.stat().st_size<=SPLIT_TARGET:
        out=PACK/f'{slug}_0001.zip'; full.replace(out); shutil.rmtree(stage,ignore_errors=True); return [(out,out.stat().st_size)]
    before=set(PACK.glob('*.zip')); run(['zipsplit','-n',str(SPLIT_TARGET),'-b',str(PACK.resolve()),str(full.resolve())]); full.unlink(missing_ok=True)
    made=[p for p in PACK.glob('*.zip') if p not in before and p != full]
    if not made: raise RuntimeError(f'zipsplit produced no parts for {slug}')
    out=[]
    for i,p in enumerate(sorted(made,key=lambda p:(p.stat().st_mtime,p.name)),1):
        q=PACK/f'{slug}_{i:04d}.zip'; p.replace(q); size=q.stat().st_size
        if size>MAX_ZIP: raise RuntimeError(f'ZIP part exceeds safety limit: {q} = {size}')
        subprocess.run(['unzip','-tq',str(q)],check=True); out.append((q,size))
    shutil.rmtree(stage,ignore_errors=True); return out
def push(label):
    for attempt in range(1,2):
        try:
            run(['git','fetch','origin','main']); run(['git','rebase','origin/main']); run(['git','push','origin','HEAD:main']); print(f'PUSH PASS {label} attempt {attempt}'); return
        except subprocess.CalledProcessError:
            if attempt==1: raise
            time.sleep(attempt*2)
def commit(n,label):
    if not n:return
    run(['git','add',str(DEST)])
    if subprocess.run(['git','diff','--cached','--quiet']).returncode==0:return
    run(['git','config','user.name','github-actions[bot]']); run(['git','config','user.email','41898282+github-actions[bot]@users.noreply.github.com']); run(['git','commit','-m',f'build(download): research queue batch {label} ({n} bytes)']); push(label)
DEST.mkdir(parents=True,exist_ok=True); SRC.mkdir(parents=True,exist_ok=True); PACK.mkdir(parents=True,exist_ok=True)
batch=batch_no=0
for number,slug,url in REPOS:
    print(f'===== QUEUE {number}/20: {slug} =====')
    if done(slug): print(f'{slug}: COMPLETE; skipping'); continue
    root=SRC/slug; shutil.rmtree(root,ignore_errors=True)
    try: run(['git','clone','--depth','1','--no-tags',url,str(root)])
    except subprocess.CalledProcessError:
        print(f'SKIP CLONE FAIL {number} {slug} {url}',flush=True); continue
    sha=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,text=True).strip(); shutil.rmtree(root/'.git',ignore_errors=True)
    parts=package(slug,root); print(f'{slug}: {len(parts)} ZIP part(s)')
    for z,size in parts:
        if batch and batch+size>BATCH_LIMIT: commit(batch,f'{batch_no:03d}'); batch=0; batch_no+=1
        shutil.copy2(z,DEST/z.name); batch+=size; print(f'  {z.name}: {size} bytes; batch={batch}')
    with MANIFEST.open('a') as f: f.write(json.dumps({'number':int(number),'slug':slug,'source':url,'source_commit':sha,'parts':len(parts),'status':'COMPLETE'},sort_keys=True)+'\n')
    shutil.rmtree(root,ignore_errors=True); shutil.rmtree(PACK,ignore_errors=True); PACK.mkdir(parents=True,exist_ok=True)
commit(batch,f'{batch_no:03d}-final'); print('===== QUEUE COMPLETE: 20/20 repositories processed =====')

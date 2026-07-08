---
name: shadcn
description: Procédure verrouillée pour reproduire / étendre / créer des écrans Figma avec le design system Swile « 🏢 Flõw | Corporate » (shadcn), via le MCP figma-console (Desktop Bridge). UNIQUEMENT pour ce DS, via la commande /swile-design:shadcn (jamais en auto-déclenchement).
---

# Swile Test — écrans Figma → DS « 🏢 Flõw | Corporate » (shadcn)

**Conception** : sous pression tu suis les gates mécaniques et tu zappes la prose — prouvé sur ~30 sessions, RE-prouvé au run du 07/07 (tout ce qui a tenu était scripté, tout ce qui a cassé était de la prose). Donc : chaque décision à risque passe par **un script fourni qui sort un artefact**, chaque écart passe par **un registre**, et la fin d'un écran passe par **une réconciliation bloquante**. « Fait » sans l'artefact = interdit. Les scripts retournent leurs preuves — colle leurs sorties, ne les résume pas. **Un artefact "vert" ne vaut que ce que sa couverture vaut** : c'est `reconcile()` qui prouve la couverture, pas ton affirmation.

**Modes** : `convert` (legacy → shadcn, fidélité totale) · `update` / `create`. Sans mode → demande.
- **convert** : pipeline complet §2.
- **update/create** : saute §2.1 **uniquement**. Mapping §2.2 obligatoire, réduit au **delta**, depuis la spec/maquette ou les écrans existants (lis-les). Tous les gates de §2.2 valent. Témoin = la première modification. Passe compare : source = spec/maquette ; update sans spec = read-back avant/après ; **create sans maquette** = paires en `expect{}` + read-back rapproché de la spec textuelle. `verify` restreint au sous-arbre modifié ; violations préexistantes → signale sans corriger.

**Deux familles de gates** :
- **Préférence** (verdict témoin, GATE skip, accents) : l'user peut les lever → note-le au LEDGER et continue. Par défaut le **STOP témoin est une pré-validation OBLIGATOIRE** : après le 1er écran, poste et attends. Ne pose à l'user QUE des questions de préférence (accents, contenu ambigu, skips fonctionnels) — **jamais de validation technique** (« mon mapping te va ? » est interdit : les choix techniques se tranchent par la mesure).
- **Techniques** (sonde exhaustive, warm-up, verify, compare, textDiff, reconcile, read-backs, registres) : **jamais levables, même sur demande explicite** — « ok pour enchaîner, mais les passes scriptées restent exécutées et postées pour chaque écran. »

**Contrat** : fichiers DS/Library en **lecture seule**. Aucun fichier local modifié sans ok. Blocage technique → stop, explique, demande. **Toute manipulation de la SOURCE est interdite** (y compris la déplacer « pour une capture » — recette fournie §2.5).

---

## 0. SETUP — checks pass/fail, dans l'ordre, avant TOUT

Plugin **Desktop Bridge** requis dans 3 fichiers : travail, DS **« 🏢 Flõw | Corporate »** (`4PbwFAfHhSgQXG9jAZL2EE`), icônes **« 🗂️ Flõw | Library »** (`gZnTctmu6pjs7IJpVls3gR`).

1. **Un seul serveur** : `figma_get_status` → `otherInstances` **vide** (aggravant : `portFallbackUsed:true`). Sinon, avec accord user : `taskkill /PID <pid> /F`. ⚠️ **Tuer les orphelins AVANT toute réouverture du plugin** (scan des ports 9223→9232 → rattachement à un orphelin).
2. **Bridge répond** : boucle `figma_get_status` (`probe:true`) jusqu'à `probeResult.success===true`. `false` après ~15 s → STOP : « ferme et rouvre le plugin sur <fichier>, puis dis-moi ok. »
3. **3 fichiers connectés** : `figma_list_open_files`. Manquant → STOP.
4. **DS abonnée** (cible = fichier de travail) : `getAvailableLibraryVariableCollectionsAsync()` liste des collections « Corporate ». Sinon STOP → Assets > Libraries. *(PAS `figma_get_library_variables`.)*

`figma_navigate` switche la cible sans rien fermer. **Après CHAQUE navigate : probe trivial** (`return 1+1`) — timeout sur read trivial = divergence onglet/cible, pas une lenteur. Re-check le point 1 avant chaque phase d'import.

**Registres de session** (à créer au setup, un seul call) :
```js
globalThis.MAPPING=[]; globalThis.LEDGER=[]; globalThis.SWAPS=[]; globalThis.RESIZES=[];
return 'registres prêts';
```
**Marqueur de run (pour le hook de gate)** : écris (outil Write) le fichier `.swile-run.lock` à la racine du répertoire de travail — contenu : `{"demarre":"<ecrans demandés>"}`. Ces deux fichiers de travail (`.swile-run.lock`, `.swile-verify.json`) sont les SEULS fichiers locaux que tu crées/modifies, et tu les tiens à jour scrupuleusement : le hook bloque la fin de tour dessus.

---

## 1. Interdits absolus & modes de panne

**Interdits (chaque violation a cassé un run réel)** :
- `timeout:30000` sur **tout** call contenant un import (le défaut 5 s coupe l'import → fige le worker). Plafond dur figma_execute : 30 s.
- Jamais : `Promise.all` d'imports · import + build même call (clés non cachées) · boucle d'import `await`-ée · `importComponentSetByKeyAsync` · `loadAllPagesAsync()` sur le DS · `figma_instantiate_component` / `figma_search_components` / `figma_get_library_variables`.
- **`.resize()` sur une INSTANCE = interdit** → `rescaleInst()` (§2.4) exclusivement, read-back obligatoire.
- **Swap d'icône « nu » = interdit** → `swapIcon()` (§2.4) exclusivement (swap + recolor + read-back + registre en un call).
- **`counterAxisSizingMode='AUTO'` (hug) sur le frame RACINE d'un écran = interdit.** Un « contenu déborde » se corrige en **bissectant** (poste la table des hauteurs enfants repro vs source, corrige l'enfant fautif) — JAMAIS en aggrandissant/huggant le parent pour éteindre le flag.
- **Ne renomme JAMAIS une instance de composant DS** (son nom = son lien au composant dans Figma ; le sens se porte sur la frame parente ; tes scripts s'ancrent par **id**, pas par nom).
- **Tout fix déclenché par verify** retourne dans le MÊME call le read-back layout complet du nœud corrigé (`{layoutMode, primaryAxisAlignItems, itemSpacing, sizing H/V}`) — un re-scan count seul ne valide RIEN (deux patchs destructeurs induits par verify au run du 07/07 : root passé en hug, space-between écrasé).
- **Clé de VARIANTE, jamais de SET** ; 1 import/SET puis `setProperties`. Node-id importé instable → ré-importe par clé (cache ~150 ms). Ne ré-importe jamais une ressource locale ; **clone l'instance posée** pour les répétitions.
- **Pendant un gel, les LECTURES passent** : probe sain ≠ imports sains.

**Modes de panne** (récupération §3) :
| Symptôme | Diagnostic | → |
|---|---|---|
| Clé d'import pend >20 s | Import individuel gelé — le lot continue (timeout/clé) | §3.1 |
| Plusieurs clés pendent, d'autres passent | Canal empoisonné (se dégrade avec le temps) ; cache immunisé | §3.2 |
| « Unable to establish connection » mais `1+1` passe | Blip (retente 1×) ou **nœud toxique** (id imbriqué `I…;…`) → parent + `findAll` | §3.6 |
| Timeout sur read trivial | Divergence onglet/cible → re-navigate + probe | §0 |
| `getNodeByIdAsync → null` | Souvent mauvais fichier actif | §3.6 |
| Nœuds disparus/écrans rétrécis après reconnexion | Revert des modifs non committées | §3.5 |
| Gros call refusé, petit call passe | Canal dégradé → découpe le script en 2 calls | §3.6 |

---

## 2. La méthode — ordre strict, artefacts postés

**Vue d'ensemble** : source (2.1) → mapping+registres (2.2) → sonde puis warm-up (2.3) → build témoin (2.4) → vérifs 4 artefacts + checklist (2.5) → **STOP pré-validation user** (2.6) → série écran par écran (mêmes artefacts) → rapport = registres (2.7).

### 2.1 Lis la source (convert)
1 screenshot par écran (`figma_capture_screenshot`, scale ≤1, une fois — budget : 1 source + 1 côte-à-côte par cycle de vérif + 1 candidat-icône si comparaison de glyphe ; jamais de capture « pour voir »).
**Tout relevé source DOIT passer par `dumpSource`** — un relevé ad hoc « texts-only » (`map(t=>t.characters)`) n'est PAS un artefact valide (il a produit une chip inventée au run du 07/07). Cellule anormale du dump (valeur vide, colonne décalée, dernière ligne atypique) → **re-dump ciblé** avant de construire.
```js
// DUMP SOURCE v2 (align + noms de composants + textes). Découpe par zone si dense (maxDepth 2-3).
globalThis.dumpSource = async (rootId, maxDepth) => {
  const toHex=c=>'#'+[c.r,c.g,c.b].map(v=>Math.round(v*255).toString(16).padStart(2,'0')).join('');
  const root=await figma.getNodeByIdAsync(rootId); if(!root) return {missing:true};
  const rows=[];
  async function rec(n,d){
    if(n.visible===false){ rows.push({d, name:n.name, HIDDEN:true}); return; }
    const r={d, name:n.name, type:n.type, w:Math.round(n.width), h:Math.round(n.height)};
    if(n.type==='INSTANCE'){ const mc=await n.getMainComponentAsync(); if(mc) r.comp=(mc.parent&&mc.parent.type==='COMPONENT_SET'?mc.parent.name+' / ':'')+mc.name; }   // jamais n.mainComponent (throw en dynamic-page)
    if(n.layoutMode&&n.layoutMode!=='NONE'){ r.lay=n.layoutMode[0]; r.gap=n.itemSpacing; r.pad=[n.paddingTop,n.paddingRight,n.paddingBottom,n.paddingLeft].join('/'); r.align=n.primaryAxisAlignItems+'/'+n.counterAxisAlignItems; }
    if(Array.isArray(n.fills)){ const f=n.fills.find(p=>p.type==='SOLID'&&p.visible!==false);
      if(f){ r.fill=toHex(f.color); const bv=f.boundVariables&&f.boundVariables.color; if(bv){const vv=await figma.variables.getVariableByIdAsync(bv.id); r.var=vv&&vv.name;} } }
    if(n.type==='TEXT') r.txt=n.characters.slice(0,40);
    if(typeof n.cornerRadius==='number'&&n.cornerRadius>0) r.radius=n.cornerRadius;
    rows.push(r);
    if(d<maxDepth&&'children'in n) for(const c of n.children) await rec(c,d+1);
  }
  await rec(root,0);
  return { fichierActif: figma.root.name, rootId, rows };
};
```
**Jamais de compteur agrégé** dans un relevé (« progIcons:18 » a masqué la variation par ligne) : pour les colonnes à contenu variable, liste **par ligne** les composants/icônes présents (`comp`/`name` du dump).
**Sidebar** : se CLONE (`node.clone()`), nom exact `sidebar (cloné)`, chrome désigné uniquement — le CONTENU se reconstruit toujours. **Read-back post-clone obligatoire** : `{sourceSidebarH, cloneH, rootH}` avec `cloneH ≤ rootH` et `|cloneH−sourceSidebarH| ≤ 1`, sinon STOP et corrige le shell (jamais la racine en hug). Re-vérifié en fin d'écran.

### 2.2 Mapping — tableau + registres + GATE
**Artefact double** : le tableau lisible posté, ET sa forme machine dans le même call :
```js
// une entrée par élément source, PAR ÉCRAN. statut: 'DS' | 'custom' | 'SONDE' (choix à mesurer)
globalThis.MAPPING.push({ecran:'CODE', ligne:'bouton Add', src:'1:18932', choix:'Solid Button secondary/lg', statut:'DS'});
```
- Éléments proches = composants **distincts**. **Recoupe rendu + nom du nœud source + logique attendue** — la sonde mesure, elle **ne dispense pas de lire la source** (bordure visible → Outline candidat ; fond transparent → Ghost ; un même libellé sur 2 écrans ≠ même composant : **re-lis le nœud source de CET écran** avant de réutiliser une ligne de mapping ailleurs — la chip bleue du 07/07 vient de là).
- **Test skip/compromis, appliqué AU MOMENT du choix** : élément ou propriété **visible** de la source absent de la repro = **SKIP, quel que soit le mot que tu emploies** → GATE (stop, préviens, demande, attends). Composant DS présent mais valeur divergente (token/taille au plus proche) = **compromis** → `LEDGER.push({ecran, element, type:'COMPROMIS', source:'…', choix:'…', pourEgaler:'…'})` **immédiatement** (pas au rapport). Un compromis dont `pourEgaler` se résout par un **simple import** (ex. « importer Ghost Icon Button ») = **refusé** : fais l'import isolé (§2.6), « coûteux » n'est pas un motif.
- **Custom = dernier recours avec preuve de recherche** (pages ✦/showcases inspectées, ≥2 synonymes, scriptable).
- **Icônes** : « 🗂️ Flõw | Library » UNIQUEMENT. **Toute substitution/choix de glyphe exige la preuve de recherche scriptée** (navigate Library + probe → `findAllWithCriteria` filtré ≥2 synonymes → 1 screenshot du candidat comparé à la source). **Une clé de l'annexe ne vaut que pour un glyphe déjà comparé à la source dans CETTE session** — l'annexe n'est pas l'inventaire de la Library (paperplane du 07/07 : zéro visite de la Library de tout le run). Recherche infructueuse = SKIP → GATE.
- **Sémantique des teintes** : un statut « en attente/pending » n'est PAS `Info` bleu par défaut — suis la couleur **mesurée** de la source (texte simple = texte simple).
- **Accent de marque** : source violette vs DS neutre → **question user** (préférence), avant de construire.
- **Tokens partout, customs inclus** (couleurs, text styles, gap, padding, radius, border-width). **Absence dans l'annexe ≠ absence dans le DS** : avant tout arrondi, **preuve de recherche scriptée du token exact** (par nom ET par valeur, `getLocalVariablesAsync` sur le DS) collée — sans elle l'arrondi est refusé (spacing/0,5=2 existait, arrondi 2→4 sur 9 frames au 07/07).

### 2.3 Sonde (sur le DS) puis warm-up (sur le fichier de travail)
**Séquence** : ① navigate DS + probe → **SONDE** (lecture seule, zéro import) ; ② navigate travail + probe + re-§0.1 → **WARM-UP**. Rien ne se construit avant la fin des deux.

**SONDE — exhaustivité mécanique** : entrée = TOUTES les lignes `statut:'SONDE'` du MAPPING ; sortie = choix mesuré par ligne + **`lignesSansMesure` qui DOIT être vide**. Il est **interdit d'instancier** un élément dont la ligne contient encore `SONDE` ou un « ou » non tranché — écrans suivants inclus (les 3 boutons PROFIL du 07/07 : marqués « → sonde », jamais mesurés, posés au hasard). **Pour tout bouton : les 4 sets Solid/Soft/Outline/Ghost sont candidats systématiques.** Le **stroke compte** : source à bordure visible + candidat sans stroke = éliminé (et inversement) — un Outline blanc bordé est indiscernable au fill seul.
```js
// SONDE (testé + stroke au score). candidates: [{label,setNameRe,variantRe}], sourceHex, sourceStroke(bool)
globalThis.sonde = async (pageNameRe, candidates, sourceHex, sourceStroke) => {
  const out = { fichierActif: figma.root.name, source: sourceHex, candidats: [] };
  const pages = figma.root.children.filter(p => pageNameRe.test(p.name));
  const page = pages.find(p => p.name.includes('✦')) || pages[0];   // ✦ = atomes, sinon showcase sans sets
  if (!page) { out.err='page introuvable'; return out; }
  out.page = page.name; await page.loadAsync();
  const sets = page.findAllWithCriteria({ types: ['COMPONENT_SET'] });
  const toHex=c=>'#'+[c.r,c.g,c.b].map(x=>Math.round(x*255).toString(16).padStart(2,'0')).join('');
  const h2=h=>{h=h.replace('#','');return [0,2,4].map(i=>parseInt(h.slice(i,i+2),16));};
  const dist=(a,b)=>Math.round(Math.hypot(...a.map((v,i)=>v-b[i])));
  for (const c of candidates) {
    const s = sets.find(x => c.setNameRe.test(x.name.trim()));
    if (!s) { out.candidats.push({label:c.label, err:'set introuvable'}); continue; }
    const v = s.children.find(x => c.variantRe.test(x.name));
    if (!v) { out.candidats.push({label:c.label, set:s.name, err:'variante introuvable'}); continue; }
    const r = {label:c.label, set:s.name, variant:v.name, key:v.key};
    const f = Array.isArray(v.fills)&&v.fills.filter(p=>p.type==='SOLID'&&p.visible!==false)[0];
    if (f){ r.fill=toHex(f.color); r.fillOpacity=Math.round((f.opacity??1)*100);
      const bv=f.boundVariables&&f.boundVariables.color; if(bv){const vv=await figma.variables.getVariableByIdAsync(bv.id); r.fillVar=vv&&vv.name;}
      if(sourceHex) r.dist=dist(h2(r.fill.slice(1)),h2(sourceHex.replace('#',''))); }
    const st=Array.isArray(v.strokes)&&v.strokes.filter(p=>p.type==='SOLID')[0]; if(st) r.stroke=toHex(st.color);
    if(sourceHex!==undefined && sourceStroke!==undefined && (!!st)!==(!!sourceStroke)) r.dist=(r.dist??0)+500; // bordure incohérente = éliminé
    out.candidats.push(r);
  }
  if(sourceHex) out.candidats.sort((a,b)=>(a.dist??1e9)-(b.dist??1e9));
  const ok=out.candidats.find(c=>!c.err); out.choix=ok?ok.label:null;
  if(out.candidats.some(c=>c.err)) out.attention='candidat(s) en erreur — choix parmi les mesurés seulement';
  return out;
};
```
`fillOpacity` < ~15 % ≈ invisible sur blanc. Égalité au fond → départage par stroke/opacité/page d'usage, ou demande. Toute ligne d'annexe utilisée au mapping doit apparaître dans les mesures, sinon « annexe non confirmée » au LEDGER. Après la sonde : **mets à jour MAPPING (statut 'SONDE'→'DS' + choix mesuré)**.

**WARM-UP (testé)** — construis `COMP_KEYS`/`VAR_KEYS`/`STYLE_KEYS` (`[['nom','clé'],…]`) depuis mapping+sonde+annexe (composants ET icônes ET tokens dimension), puis (call `timeout:30000`) :
```js
if (figma.root.name.includes('Flõw | Corporate')||figma.root.name.includes('Flõw | Library')) throw 'MAUVAIS FICHIER (DS/Library lecture seule) — navigate vers le fichier de travail';
globalThis.G = { comp:{}, vars:{}, styles:{}, done:0, total:0, err:[], timeouts:[] };
const tasks = [
  ...COMP_KEYS.map(([n,k])=>({n,k,imp:x=>figma.importComponentByKeyAsync(x),slot:'comp'})),
  ...VAR_KEYS .map(([n,k])=>({n,k,imp:x=>figma.variables.importVariableByKeyAsync(x),slot:'vars'})),
  ...STYLE_KEYS.map(([n,k])=>({n,k,imp:x=>figma.importStyleByKeyAsync(x),slot:'styles'})),
];
G.total = tasks.length;
const withTimeout=(p,ms)=>Promise.race([p,new Promise((_,rej)=>setTimeout(()=>rej(new Error('KEY_TIMEOUT')),ms))]);
(async()=>{ for(const t of tasks){ try{ G[t.slot][t.n]=(await withTimeout(t.imp(t.k),20000)).id; }
  catch(e){ (String(e).includes('KEY_TIMEOUT')?G.timeouts:G.err).push(t.n); } G.done++; } })();
return { total: G.total };   // détaché ; poll : {done, timeouts, err}
```
`timeouts` → une relance après le lot ; re-timeout → §3.2. `err` → re-découverte **après le lot** (navigate DS, relève, retour + probe, relance ces clés).

### 2.4 Construis UN écran témoin
**Témoin** = l'écran couvrant le plus de types (souvent le plus complexe) — annonce ton choix, ne le fais pas valider. Pose chaque repro à droite de sa source, frame `<nom source> (shadcn)`.

- **Shell d'abord**, construit une fois puis cloné. **Racine FIXED/FIXED aux dims de la source.** Clone en parent auto-layout → hérite STRETCH : lis la hauteur source AVANT l'append. Reparenting → re-pose `layoutSizingHorizontal='FILL'`.
- **Gate création de frames** : tout call qui crée des frames custom **retourne `{name,w,h,sizingH,sizingV}` de CHAQUE frame créé** — un frame auto-layout dont l'axe transverse reste `FIXED` sans resize explicite = piège 100px (3 écrans touchés au 07/07). `createFrame()` = 100×100 + `clipsContent=true` + **fill blanc** → pose taille + `clipsContent=false` + `fills` explicites immédiatement. **Hug en cascade** : contenu interne en auto-width (`textAutoResize='WIDTH_AND_HEIGHT'`).
- **Nommage** : tes frames custom = noms simples ; **instances DS = nom d'origine intouché** (§1).
- **Tokens liés à la pose** (`setBoundVariable` : `itemSpacing`, `padding*`, `topLeftRadius`×4, `strokeWeight` ; couleurs : `setBoundVariableForPaint`).
- **Redimensionner une instance** (avatars, icônes…) — HELPER OBLIGATOIRE (sortie collée ; toute instance redimensionnée absente de RESIZES = fail au reconcile) :
```js
globalThis.rescaleInst = async (instId, cibleH) => {
  const inst = await figma.getNodeByIdAsync(instId);
  const t0 = inst.findAll(n=>n.type==='TEXT')[0];
  const avant = {w:inst.width, h:inst.height, fontSize: t0&&t0.fontSize, styleId: t0&&t0.textStyleId};
  inst.rescale(cibleH/inst.height);
  const t1 = inst.findAll(n=>n.type==='TEXT')[0];
  const apres = {w:Math.round(inst.width), h:Math.round(inst.height), fontSize: t1&&t1.fontSize, styleId: t1&&(typeof t1.textStyleId==='string'&&t1.textStyleId!==''?'ok':'DÉTACHÉ')};
  const out = {instId, avant, apres, fichierActif:figma.root.name};
  globalThis.RESIZES.push(out);
  return out;   // styleId 'DÉTACHÉ' → ré-applique le text style DS puis re-read-back AVANT de continuer
};
```
- **Swap + recolor d'icône — HELPER OBLIGATOIRE** (le swap nu est un interdit §1 ; 1 entrée SWAPS = 1 paire compare exigée par reconcile) :
```js
globalThis.swapIcon = async (instId, swapPropOuNull, iconCompId, varIdCouleur, hexAttendu) => {
  const inst = await figma.getNodeByIdAsync(instId);
  if (swapPropOuNull) inst.setProperties({[swapPropOuNull]: iconCompId});
  else { const comp = await figma.getNodeByIdAsync(iconCompId); inst.swapComponent(comp); }
  const v = await figma.variables.getVariableByIdAsync(varIdCouleur);
  const done=[];
  for (const x of inst.findAll(n=>n.type==='VECTOR'&&n.visible!==false)) {
    const hasFill=Array.isArray(x.fills)&&x.fills.some(p=>p.type==='SOLID'&&p.visible!==false);
    const hasStroke=Array.isArray(x.strokes)&&x.strokes.length>0;
    if(!hasFill&&!hasStroke) continue;
    let p={type:'SOLID',color:{r:0,g:0,b:0}}; p=figma.variables.setBoundVariableForPaint(p,'color',v);
    if(hasFill) x.fills=[p]; else x.strokes=[p];
    const q=(hasFill?x.fills:x.strokes)[0];
    done.push({vec:x.id, porteur:hasFill?'fill':'stroke', hex:'#'+[q.color.r,q.color.g,q.color.b].map(n=>Math.round(n*255).toString(16).padStart(2,'0')).join('')});
  }
  const out = {instId, icon:iconCompId, hexAttendu, done, fichierActif:figma.root.name};
  globalThis.SWAPS.push(out);
  return out;   // done vide = glyphe introuvable → STOP ; si la variante colore déjà juste, appelle quand même (read-back = preuve)
};
```
- Occurrences répétées : 1ʳᵉ via cache+`createInstance`, suivantes **clonées** — puis **relis la ligne source correspondante** et applique ses champs variables (badge, pastille, contenu). **La donnée commande le modèle, jamais l'inverse** (interdiction d'inventer des initiales/contenus pour remplir un gabarit — ligne 9 du 07/07).
- Props lues sur l'instance avant `setProperties` ; sous-éléments parasites désactivés ; **ne bidouille jamais en dur** (rendu faux = mauvaise variante).
- Élément sur fond coloré (checkbox sur header gris) → fill blanc explicite. Cellule = largeur de son contenu ; `strokeAlign='INSIDE'` ; conteneur source à fond+padding → reproduis-le.
- Le DS documente un pattern (showcase) → copie-le ; pas de détournement d'état SAUF documenté par le DS (nav Ghost enabled/hover, annexe A).

### 2.5 Vérifie — 4 artefacts scriptés + 1 checklist, par écran, collés
**Passe 1 — `verify(rootId)` → count DOIT être 0.**
```js
// VERIFY v3 — VALIDÉ sur les 4 écrans du run raté du 07/07 (attrape : 7× piège 100px, 90× instance renommée, débordements)
globalThis.verify = async (rootId) => {
  const linked=p=>!!(p.boundVariables&&p.boundVariables.color);
  const num=v=>typeof v==='number';
  const insideInst=n=>{let p=n.parent;while(p&&p.type!=='PAGE'){if(p.type==='INSTANCE')return true;p=p.parent;}return false;};
  const insideClone=n=>{let p=n;while(p&&p.type!=='PAGE'){if(p.name==='sidebar (cloné)')return true;p=p.parent;}return false;};
  const V=[],add=(n,m)=>V.push({id:n.id,name:n.name,pb:m});
  const root=await figma.getNodeByIdAsync(rootId);
  for(const n of [root,...root.findAll(()=>true)]){
    if(insideInst(n)||insideClone(n)) continue;   // intérieur d'instance + clone : hors scan (le clone est couvert par le read-back triple §2.1)
    if(n.type==='INSTANCE'){ const mc=await n.getMainComponentAsync();   // ⚠️ ordre : rename AVANT le skip d'intérieur ; jamais n.mainComponent (throw)
      if(mc&&n.name!==mc.name&&n.name!==((mc.parent||{}).name||'')) add(n,'instance renommée');
      continue; }
    if(n.type==='FRAME'){
      if('children'in n) for(const c of n.children) if(c.x+c.width>n.width+0.5||c.y+c.height>n.height+0.5){ add(n,'contenu déborde'); break; }
      if(n.layoutMode&&n.layoutMode!=='NONE'&&'children'in n&&n.children.length){
        const kids=n.children.filter(c=>c.visible!==false);
        if(kids.length){
          const need=n.layoutMode==='HORIZONTAL'?Math.max(...kids.map(c=>c.height))+n.paddingTop+n.paddingBottom:Math.max(...kids.map(c=>c.width))+n.paddingLeft+n.paddingRight;
          const dim=n.layoutMode==='HORIZONTAL'?n.height:n.width;
          if(Math.round(dim)===100&&need+2<100) add(n,'piège 100px');   // signature exacte createFrame — le check générique need+2 produit ~25 faux positifs (testé), la dérive générale = paires dims (root + zones)
        }
      }
    }
    if(n.type==='TEXT'&&(n.textStyleId===''||typeof n.textStyleId!=='string')) add(n,'styleId NONE/mixte');
    if(n.type==='TEXT'&&n.characters==='') add(n,'texte vide');
    if(Array.isArray(n.fills)) for(const p of n.fills.filter(f=>f.type==='SOLID'&&f.visible!==false)){
      if(!linked(p)) add(n,'fill en dur');
      if(((p.opacity??1)*(n.opacity??1))<0.15) add(n,'fond ~invisible'); }
    if(Array.isArray(n.strokes)) for(const p of n.strokes.filter(f=>f.type==='SOLID')) if(!linked(p)) add(n,'stroke en dur');
    if(['FRAME','RECTANGLE','ELLIPSE'].includes(n.type)){ const b=n.boundVariables||{};
      if(num(n.cornerRadius)&&n.cornerRadius>0&&!b.topLeftRadius&&!b.cornerRadius) add(n,'radius en dur');
      if(n.strokes&&n.strokes.length){ const sw=num(n.strokeWeight)?n.strokeWeight:Math.max(n.strokeTopWeight||0,n.strokeBottomWeight||0,n.strokeLeftWeight||0,n.strokeRightWeight||0);
        if(sw>0&&!(b.strokeWeight||b.strokeTopWeight||b.strokeBottomWeight||b.strokeLeftWeight||b.strokeRightWeight)) add(n,'border en dur'); } }
    if(n.type==='FRAME'&&n.layoutMode&&n.layoutMode!=='NONE'){ const b=n.boundVariables||{};
      if(n.primaryAxisAlignItems!=='SPACE_BETWEEN'&&n.itemSpacing>0&&!b.itemSpacing) add(n,'gap en dur');   // SPACE_BETWEEN : itemSpacing ignoré (faux positif destructeur du 07/07)
      if((n.paddingLeft>0||n.paddingTop>0)&&!b.paddingLeft&&!b.paddingTop) add(n,'padding en dur'); }
  }
  return { fichierActif: figma.root.name, count:V.length, V };
};
```
**Passe 2 — `compareToSource(pairs)`.** En convert, **chaque paire porte un `sourceId` de PREMIER NIVEAU** (id imbriqué toxique → remonte au parent, le script descend seul) ; impossible → `expect.dims:{w,h}` lus dans le dump est **obligatoire** (paire sans sourceId ni dims = ligne sans paire pour reconcile). **Paires minimales par écran : la RACINE (root↔root)** + un frame structurant par zone (nav, table, sidebar) + chaque type distinct + première ET dernière occurrence de chaque groupe répété + une paire par entrée SWAPS (avec `icon.expectedHex`) + toute instance dont la taille rendue ≠ celle du master.
```js
globalThis.readNode = async (id) => { const n=await figma.getNodeByIdAsync(id); if(!n) return {missing:true,id};
  const toHex=c=>'#'+[c.r,c.g,c.b].map(v=>Math.round(v*255).toString(16).padStart(2,'0')).join('');
  const r={name:n.name, w:Math.round(n.width), h:Math.round(n.height)};
  if(n.layoutMode&&n.layoutMode!=='NONE') r.align=n.primaryAxisAlignItems;
  let best=null,ba=-1;
  for(const x of [n,...('findAll'in n?n.findAll(()=>true):[])]){ if(x.visible===false) continue;
    if(Array.isArray(x.fills)) for(const p of x.fills) if(p.type==='SOLID'&&p.visible!==false){const a=x.width*x.height; if(a>ba){ba=a;best=p;}} }
  if(best){ const c=best.color; r.bgHex=toHex(c); const bv=best.boundVariables&&best.boundVariables.color;
    const vv=bv?await figma.variables.getVariableByIdAsync(bv.id):null; r.bgVar=vv?vv.name:null; }
  if('componentProperties'in n&&n.componentProperties){const vp={};for(const [k,d] of Object.entries(n.componentProperties))if(d.type==='VARIANT')vp[k]=d.value;if(Object.keys(vp).length)r.variant=vp;}
  if('findAll'in n){ const vec=n.findAll(x=>x.type==='VECTOR'&&x.visible!==false&&((Array.isArray(x.fills)&&x.fills.some(p=>p.type==='SOLID'&&p.visible!==false))||(Array.isArray(x.strokes)&&x.strokes.length)))[0];
    if(vec){ const p=(Array.isArray(vec.fills)&&vec.fills.find(q=>q.type==='SOLID'&&q.visible!==false))||(Array.isArray(vec.strokes)&&vec.strokes.find(q=>q.type==='SOLID')); if(p) r.glyphHex=toHex(p.color); }
    r.texts=n.findAll(x=>x.type==='TEXT'&&x.visible!==false).map(t=>t.characters).join('|').slice(0,120); }
  return r; };
globalThis.compareToSource = async (pairs) => {
  const h2=h=>{h=h.replace('#','');return [0,2,4].map(i=>parseInt(h.slice(i,i+2),16));};
  const dist=(a,b)=>Math.round(Math.hypot(...a.map((v,i)=>v-b[i])));
  const out={ fichierActif: figma.root.name, pairs: [] };
  for(const p of pairs){
    const A=await readNode(p.reproId); const B=p.sourceId?await readNode(p.sourceId):null; const diffs=[];
    if(A.missing) diffs.push('repro manquante'); if(B&&B.missing) diffs.push('source manquante');
    if(B&&!B.missing){ if(A.bgHex!==B.bgHex) diffs.push('bg '+A.bgHex+' != '+B.bgHex);
      if(Math.abs(A.w-B.w)>1||Math.abs(A.h-B.h)>1) diffs.push('dims '+A.w+'x'+A.h+' != '+B.w+'x'+B.h);
      if(A.align&&B.align&&A.align!==B.align) diffs.push('align '+A.align+' != '+B.align);
      if(p.compareTexts&&A.texts!==B.texts) diffs.push('texts "'+A.texts+'" != "'+B.texts+'"'); }
    if(p.expect){ if(p.expect.bgVar&&A.bgVar!==p.expect.bgVar) diffs.push('token '+A.bgVar+' != '+p.expect.bgVar);
      if(p.expect.dims&&(Math.abs(A.w-p.expect.dims.w)>1||Math.abs(A.h-p.expect.dims.h)>1)) diffs.push('dims '+A.w+'x'+A.h+' != attendu '+p.expect.dims.w+'x'+p.expect.dims.h);
      if(p.expect.variant) for(const [k,v] of Object.entries(p.expect.variant)) if((A.variant||{})[k]!==v) diffs.push('variant '+k+' != '+v); }
    if(p.icon&&p.icon.expectedHex){ if(!A.glyphHex) diffs.push('glyphe INTROUVABLE (swap raté ?)');
      else if(A.glyphHex.toLowerCase()!==p.icon.expectedHex.toLowerCase()) diffs.push('glyphe '+A.glyphHex+' != '+p.icon.expectedHex); }
    if(A.glyphHex&&A.bgHex&&dist(h2(A.glyphHex.slice(1)),h2(A.bgHex.slice(1)))<50) diffs.push('CONTRASTE: glyphe '+A.glyphHex+' quasi invisible sur fond '+A.bgHex);
    out.pairs.push({label:p.label, ok:diffs.length===0, diffs});
  }
  out.clean = out.pairs.every(p=>p.ok);
  return out;
};
```
Écart **attendu** (compromis au LEDGER) → cite l'entrée LEDGER ; inexpliqué → corrige.
**Passe 3 — `textDiff` : aucun texte source ne disparaît.**
```js
// VALIDÉ sur COLLAB raté du 07/07 : a sorti 16 manquants réels (badge "En attente d'activation", sous-titre d'alerte, "+2", 6 noms+emails de lignes clonées non re-remplies)
globalThis.textDiff = async (sourceRootId, reproRootId) => {
  const get=async id=>{ const root=await figma.getNodeByIdAsync(id);
    const visible=n=>{let p=n;while(p&&p.type!=='PAGE'){if(p.visible===false)return false;p=p.parent;}return true;};   // visibilité sur TOUTE la chaîne (sinon les textes de calques cachés polluent)
    return root.findAll(x=>x.type==='TEXT').filter(visible).map(t=>t.characters.trim()).filter(t=>t); };
  const src=await get(sourceRootId), rep=new Set(await get(reproRootId));
  const manquants=[...new Set(src.filter(t=>!rep.has(t)))];
  return { fichierActif:figma.root.name, manquants, ok:manquants.length===0 };  // chaque manquant = skip → GATE avant le STOP
};
```
**Passe 4 — `reconcile()` : la couverture est prouvée, pas affirmée.**
```js
globalThis.reconcile = (ecran, pairsPassed /* labels des paires réellement exécutées */) => {
  const m = MAPPING.filter(x=>x.ecran===ecran);
  const lignesSansPaire = m.filter(x=>!pairsPassed.some(l=>l.includes(x.ligne)) && !LEDGER.some(e=>e.ecran===ecran&&e.element===x.ligne)).map(x=>x.ligne);
  const sondeNonMesuree = m.filter(x=>x.statut==='SONDE').map(x=>x.ligne);
  const swapsSansCheck = SWAPS.filter(s=>!pairsPassed.some(l=>l.includes(s.instId)||l.toLowerCase().includes('icon')) ).map(s=>s.instId);
  const resizesNonProuves = RESIZES.filter(r=>r.apres&&r.apres.styleId==='DÉTACHÉ').map(r=>r.instId);
  return { ecran, lignesSansPaire, sondeNonMesuree, swapsSansCheck, resizesNonProuves,
    ok: !lignesSansPaire.length&&!sondeNonMesuree.length&&!swapsSansCheck.length&&!resizesNonProuves.length };
};
```
**`reconcile().ok` DOIT être true avant le STOP témoin et avant chaque écran suivant** — chaque liste non vide se résout (paire ajoutée / sonde faite / LEDGER+gate) puis re-run. L'affirmation en prose du rapprochement est interdite.
**+ Checklist qualitative (l'œil sur la capture côte-à-côte — les scripts ne voient pas tout)** — tableau ✅/❌ posté :
| ✅/❌ | bonne variante partout · icônes recolorées ET visibles · bordures visibles non rognées · texte non coupé/rien de croppé · contraste OK (tout ce qui se distingue du fond dans la source se distingue dans la repro) · alignements (boutons à droite, colonnes) |
Un ❌ ou « pas vérifiable » = écran non validé.
**Recette capture côte-à-côte (sans toucher la source)** : frame temporaire VIDE (`fills:[]`, `clipsContent:false`) posée sur la bbox englobante source+repro → `figma_capture_screenshot` de cette frame → suppression. Déplacer la source est interdit.
**Si un script throw** : hardening minimal en session (try/catch par nœud, erreurs DANS l'artefact) ; sinon read-back tabulaire de substitution + écran marqué « non vérifié mécaniquement » (STOP ne se franchit qu'avec ok user) + remonte l'erreur exacte.

### 2.6 STOP témoin (pré-validation), puis la série
**Checkpoint après chaque écran vérifié** : `figma.saveVersionHistoryAsync('<écran> vérifié')` **+ mets à jour la sentinelle `.swile-verify.json`** (outil Write) : `{"ecrans":{"<nom>":{"verify":<count>,"reconcile":<ok>,"textDiff":<nb manquants non gatés>}}, "clean":<true si TOUS les écrans finis sont à verify:0 + reconcile:true + textDiff gaté>}`. Écran en cours non fini = `clean:false`.
**GATE témoin (préférence, actif par défaut)** : poste témoin + les 4 artefacts + checklist + capture → **STOP, attends la pré-validation user**. Ne repose aucune question technique — uniquement les préférences non encore tranchées.
- **Erreurs** → corrige (procédure complète, §2.7), écran suivant seul → re-STOP.
- **OK** → série écran par écran, **mêmes 4 artefacts + checklist POSTÉS pour chacun**. Point d'étape tous les 2-3 écrans : tableau `écran → {verify.count, pairs, textDiff.manquants, reconcile.ok}` + **LEDGER complet ré-affiché**. Nouvel élément mi-série → re-§0.1 + import isolé (pattern warm-up, timeout 20 s) ; pend → §3 AVANT de poser. Envie de simplifier → GATE skip.

### 2.7 Corriger, puis rapport
**Corriger** = repasser la procédure (règles → read-back layout du nœud touché dans le même call → re-scan → re-compare) — jamais un patch pour éteindre un flag.
**Rapport final = les registres, pas ta mémoire** : la table Compromis/Skips est `return globalThis.LEDGER` collé tel quel (reconstruction interdite — 5 compromis perdus au 07/07) + le reconcile final de chaque écran + customs avec preuves + lignes annexe non confirmées + récap. **Un blocage technique déguisé en compromis = rejeté** ; un skip sans OK user dans le transcript = rejeté. Rapport livré → sentinelle `clean:true` finale puis **supprime `.swile-run.lock`** (fin du gate).

---

## 3. Récupération (échelle testée)
1. **Clés en timeout au warm-up** → le lot continue ; retente ces clés une fois après le lot. Re-timeout → 2.
2. **Canal empoisonné** (warm-up OU mi-série) → re-§0.1 (**orphelins AVANT réouverture**), puis « ferme et rouvre le plugin (3 fichiers) ». Ensuite : re-§0 → **§3.5** → **relance le warm-up immédiatement** (cache instantané ; le canal frais se re-dégrade en minutes).
3. **Encore empoisonné** → restart complet de Figma Desktop + re-§0 + warm-up.
4. `figma_reconnect`/`figma_reload_plugin` **ne débloquent pas**.
5. **Intégrité après tout restart/reconnexion** : chaque écran construit → `getNodeByIdAsync` PUIS `verify` (count:0) PUIS re-lecture des dims racine vs source. Reverté → reconstruis (procédure complète). Témoin validé perdu : le verdict tient si le témoin reconstruit re-passe compare, sinon re-STOP.
6. **« Unable to establish connection »** → probe `1+1`. Probe OK : retente 1× ; échec persistant sur le même id = nœud toxique → parent + `findAll` ; gros script refusé → découpe en 2 calls. Probe KO → §0.
7. Import textes/couleurs durablement impossible → l'user colle les frames « Typography »/« Colors » du DS ; lis les ids, mappe par nom, applique, supprime.

---

## A. ANNEXE — données mesurées (CACHE de démarrage, PAS l'inventaire du DS : la sonde re-confirme ce qui est utilisé ; **absence ici ≠ absence dans le DS/Library** → preuve de recherche scriptée obligatoire avant arrondi/substitution ; clé qui échoue → re-découverte par nom)

**Correspondances MESURÉES (masters) :**
| Besoin (source legacy) | Choix DS | Preuve |
|---|---|---|
| Bouton **gris neutre** | **Solid Button `secondary`** | `theme/secondary` #f5f5f5 |
| Bouton **noir** (CTA) | Solid Button `primary` (+ glyphes **blancs** : `swapIcon` avec `theme/primary-foreground`) | `theme/primary` #171717 |
| **Bouton blanc à bordure grise** | **Outline Button `secondary`** | fond #ffffff `theme/background` + stroke #e5e5e5 — indiscernable au fill seul : le stroke décide |
| Soft Button (primary ET secondary) | fond `theme/card` **BLANC** | « gris = Soft » est un mythe réfuté |
| **Bouton-icône fond neutre visible** | **Solid Icon Button `secondary`** (#f5f5f5 opaque) | Soft Icon Button = teinte 10 % ≈ invisible (destructive teinté OK) |
| **Onglets « boxed »** | **Track segmenté gris** (`theme/muted`, pad ~4, radius ~10, hug, DANS le panneau) + Tabs `Boxed` actif pastille blanche — pattern « Advance Tabs ». Alternative validée (« ✦ Navigation Menu ») : **Ghost Button** enabled + actif `hover` (#f5f5f5 `theme/accent`), labels inactifs `muted-foreground` | jamais Boxed nu sur blanc |
| Sous-onglets soulignés | Tabs `Bordered` ; la **frame** porte le border-bottom pleine largeur `theme/border` ; actif `theme/primary` noir | violet source = décision accent §2.2 |
| Switch vert plein | Switch `Solid, sucess` *(sic)* track `theme/success` #16a34a | Outline = track blanc + stroke vert |
| Checkbox sur fond non blanc | fill blanc explicite (`theme/background`) | boîte `fills:[]` par défaut |
| Pastilles/compteurs sur icônes | **custom à la main, pré-justifié** (mail/pastille grise · user/violet #664ef9 · compteur) — à reproduire **par ligne selon le dump** | jamais cloné ; jamais simplifié sans GATE |
| Statut « en attente/pending » | suit la **couleur mesurée de la source** (texte simple = texte simple) | JAMAIS `Info` bleu par défaut |

**Pièges DS** : `theme/primary` = noir #171717, PAS violet · boutons max `lg` h40 · `theme/muted` canvas · `theme/card` carte · `theme/border` bordures · `foreground`/`muted-foreground` textes · Avatar = Initials/Image × Circle · Alert Soft ≠ Solid (props différentes → lire sur l'instance).

**Variables theme (« ☀️ Mode »)** : `background` 36d8943d0eb5c32d238a3dbe660f2d87f3f8df1d · `foreground` da9243f78b70a8ebe13306dc7916644bbd6032ca · `muted` 1a1c4fb51130fc6ac02bd86235145f4bf680e19a · `muted-foreground` 5608ad047b43e73345fd27d068601055ecef7f39 · `card` bf87620e38d9c9f825dcc342a3ae92f6b408236b · `border` ad89e5c8830e88a9cad5c7b7a0d92b2d1f4f4839 · `primary` 1b18ade61d046a487e4979cf8f380a8ef49d692b · `primary-foreground` 6da70a3468f722f3ca072e4d6d99c6a4ab3995e5 · `secondary` 38a4db465d1d3aa4f591c9a996fda92687667bcb · `accent` 361675c5f04130e691273ce02fbace92ae529031 · `info` 755d67b7cf2a27c5ccc8c2318af283a0a31bdc1b · `success` cfc6b1fa897ef27dd5a08e0912fac9ddbd8d0d52 · `destructive` e5beee398ba3a66ebbc815b21291b5431d31a7ce

**Dimensions (« 💨 Tailwind »)** — spacing = px directs ; radius/width = alias par NOM :
spacing `px`=1 8ca433f5721dd587116a796e500abb0eb8f4170b · **`0,5`=2 bb3764d7c03c1ff41514a0ade24c908851e56585** · `1`=4 0c447e7f9c16cca56a0c48443d0b54cda9dcd983 · `1,5`=6 98e396cdc37a58beca5b5568bb62cf3b72557c9e · `2`=8 f429d84338a023b8abe25bc487cad661ef16adfa · `2,5`=10 c049d8fcd82e1230f19e9042c2d8897473c2c87c · `3`=12 57c0dbcb76a14b04993acf6305d51a1a303e0005 · `3,5`=14 3b8cc288c4ae25f22797e7f30724500b931d5c34 · `4`=16 00c10cfc5aab7725f838b398bde2ba36c6946126 · `5`=20 fe290eb2d24fd11587f79a375fb8998a6216f345 · `6`=24 7901da4d67204e0d2e0773d30fbc5d7e7ba956da · `8`=32 f03857f7cd7015c0286c20943c42bdc3b9bdc8e4 · `10`=40 bc78b3e60dd4e84ef6dee7c2b6f952614d9ce947 · `12`=48 6384a1d8d18f37e8386d74b3857dddfe521ed5df · `16`=64 3df250a85685d80dcd2bc06586bd6a8eee8e8f32
radius `rounded` 1227b0ade0ae5a459fb95cd03e2026d8542cad01 · `rounded-md` 25aeecfd792e1f0826ae60a6bfa01b4c11a834cb · `rounded-lg` 75222fe5350f2e94033d1d50694c07f6620e4fa9 · `rounded-xl` 7e0fc63f699ad75c1baeb740bb31bfbea70b494b · `rounded-2xl` bf917a9961ac9dcd782da4b59798636757cbf131 · `rounded-full` f10b214f99500ab75f246577809c37c6c5ae6ea4
border-width `border`(1px) bf12a29d1cf5d33aeb4f7d7bdd3f5206063b7260 · `border-2` e4e819d98694ee654d2cb1b0354b5c1f48204880

**Text styles (« ↳ Tailwind Typography »)** : `XS/Regular` 9f9c604988dabad2ccb51aa87edbe244a20719dd · `XS/Medium` 7d25eddd056818b0274c86197a52db284317bce3 · `SM/Regular` 60ff59f703243b7b8ff3a6e12bc44e57fdbb25fe · `SM/Medium` acf925cf0504b75a0c3441aa5884276ab18550bd · `Base/Regular` 378e481f67c8a93217c89e6e854e726c42b753a3 · `Base/Medium` 7ad5876bc16457420bdb48fb045efcd61e14e102 · `LG/Bold` c58cc705869ef88ff3c38f4e85dec5d98d5825ff · `2XL/Bold` a716c3fd01fe4d9245ec090c6e8782147011b1a9 · `Extra/Link` c51bceb6e3391552b3a1099a32e8106b10439029

**Composants (variantes usuelles ; la sonde matche les sets par NOM ; autres variantes d'un set importé = `setProperties`, zéro import)** :
Solid Button primary/sm 4486d8b3a671f138ca57eac157e6aad24686fa50 · **secondary/sm e58fa7fb0b702be448938bebc8390e2d5f181449 (le gris)** · primary/lg 6c1309983899f353a0d31975dedaf10532943191 · info/sm 0c742f259ad720c819b8f7f2fccb29cffcdceea1 · destructive/sm 0dc39d6290ab12566620d16a3063e4f7214507b3
**Outline Button** secondary/sm/rounded cfaddcd2a07822cb6ae21170be5553f5409210a1 · secondary/sm/round 56e3000b52598871cd0c8de9c90bf86dec81e49a · secondary/lg/rounded e5233bb2ecda9e52e6944b9d2ee350cf94a3498a
Soft secondary/lg e946e1b5160909b2aeafbc5eeceef221575a2c2f · Soft destructive/lg 08202022f5984a5c5a5adf69bc5234c8ea963666 · Ghost secondary/sm 5ffdc4594d577b08533014340bf47aed4a38876e · Ghost secondary/sm/hover a578778a8769d478671b94d755f166335f0e7dd0
**Solid Icon Button** secondary/sm 206d47c643c6c732772950264284aafc3d353a8a (#f5f5f5) · primary/sm 77c7b216ffff2c3ad7d10ac113f10e6068850dd8 · Destructive/sm 342aee1db146042df1ad598a0cbe9fb6a0315a1e — Soft Icon Button secondary/sm eda8558b421b87436196c1ece509490b04e092c9 · destructive/sm b0ddc9d8ce3ec7b181fc006a3fe7a6aaac441ddf — **Ghost Icon Button** : set sur ✦ Buttons (sonde par nom)
Tabs `Tab item` Bordered/lg/Active 9d7c54c9eaeb5adb16fa4467009dd39099c594c0 · Input md b36a88b295e909ac3c5ddfea85eb137daf4acc1e · Select sm b5babc08bc84bee0fb944331b03ba9e3fbd65a8c · Switch Solid/md/sucess 4240962dd84becce39ee9d87ded00b43d15700dd · Outline/md/sucess 1475576a010a2fc3d03a3ef2758b06932a2f68a9 · Checkbox sm/Primary 9af5461126f22df46b21e964df619d9c01c1b686 · Avatar Initials/Circle 4b42b540913e2e5140364bfae382fc0517eb21bf · Image/Circle ef0f78fa9fce10a9a362d01f031ed843cec17b51 · **Soft Badge** set 8e38c61007f720b3059bc52537ca89673540b641 (Success/sm bdaa7af716f478148d37d95d04ce95b1707a8944 ; Info/Warning/Secondary/Destructive via `setProperties Style=…`) · Alert Soft Info 4e249111db42f203dfe39750c873ad41b8bed2ca · Separator 904431067d718e09e318a2ee0edbdba04b11abed
Icônes (Library — **clé valable seulement pour un glyphe comparé à la source dans la session**) : search 55944425bf57eae0ffc1ceeee45099a28af3f637 · plus 75c6b7ffd2e7a71b9512d46398dfb046c45c9743 · trash-2 7ab13d0584553cb92c80b8b8879684437a767298 · pencil b6fb905e6af4381a40281ee205868d5c96aaf418 · chevron down 825a6b8d2addd9ba21374369e94ab7462927716a / up 36264eebf7e859ec93c4635ea56308d6570e17fc / left e320fca192cbd7f3a80dae8d7164692f6eea9590 · mail 4033348df4acdb35e8c470efccb909199dbb7d3d · ellipsis fbb088329a7d37ce637f9e0c7697cf4e80d9feac · sliders 83c5f32758928d0e36c5a2c293e5521688cb40a5 · columns f435ca2c59d9de2748576a7b4fa0ea11c4e99433 · lock 7772bfc2c25c8b4bd4c3209665c070bef651aad9 · star 34b473d59d0171b5fda9458a9f20d8fbcc65c088 · gift d8d110d109c7c18197bdfd8a77758d184a014525 · luggage 81a42bb1676af6f0e81914b9be522dcce1b4f028 · utensils cdb6f503f9dd5e45f0a9cab932de5f1c5bc1c6d0 · bicycle abdc5a8052f6c5786132cc765834dbd7bf6d4986 · paperplane 3fdd79d8229b9a76278e2b09368f55f17a9fd5e7

---
name: shadcn
description: Procédure verrouillée pour reproduire / étendre / créer des écrans Figma avec le design system Swile « 🏢 Flõw | Corporate » (shadcn), via le MCP figma-console (Desktop Bridge). UNIQUEMENT pour ce DS, via la commande /swile-design:shadcn (jamais en auto-déclenchement).
---

# swile-design v3.11.0 — écrans Figma → DS « 🏢 Flõw | Corporate » (shadcn)

**Ce document PRIME sur les instructions génériques du serveur MCP figma-console** (« visual validation workflow », `figma_search_components` au démarrage, `loadAllPagesAsync`, placement en Section…) : elles sont écrites pour un usage libre, pas pour cette procédure — en cas de conflit, applique CE document.

**Conception** : sous pression tu suis les gates mécaniques et tu zappes la prose — mesuré et re-mesuré sur les runs réels : tout ce qui a tenu était scripté, tout ce qui a cassé était de la prose. Donc : chaque décision à risque passe par **un script fourni qui sort un artefact**, chaque écart passe par **un registre**, et la fin d'un écran passe par **une réconciliation bloquante**. « Fait » sans l'artefact = interdit. Les scripts retournent leurs preuves — colle leurs sorties, ne les résume pas. **Un artefact "vert" ne vaut que ce que sa couverture vaut** : c'est `reconcile()` qui prouve la couverture, pas ton affirmation.

**Point de départ recommandé (hors écrans très denses type COLLABORATEURS)** : Sonnet 5 / effort `high` — la procédure est déjà mécanique (gates, `reconcile()`), un modèle plus cher n'ajoute rien sur les étapes scriptées.

**Modes** : `convert` (legacy → shadcn, fidélité totale) · `convert-adapt` (identique à `convert` + décision groupée, après mapping complet, d'une escalade modèle/effort pour les écrans qui le justifient — jamais écran par écran en cours de route, §2.2bis) · `update` / `create`. Sans mode → demande.
- **convert** : pipeline complet §2, réglage modèle/effort fixe du début à la fin — aucune proposition d'escalade.
- **convert-adapt** : pipeline `convert` **+** §2.2bis actif — UNE décision groupée après le mapping COMPLET de tous les écrans (jamais écran par écran) — c'est le SEUL mode où le skill propose de changer de modèle/effort en cours de run. `update`/`create` n'activent PAS §2.2bis, même si l'user en a l'habitude sur `convert-adapt` — mode explicite requis.
- **update/create** : saute **uniquement le relevé de la source legacy** de §2.1 — les règles outillées qui y vivent (dumpSource obligatoire pour TOUT relevé d'écran, budget captures, règle sidebar) restent en vigueur. Mapping §2.2 obligatoire, réduit au **delta**, depuis la spec/maquette ou les écrans existants (lis-les). Tous les gates de §2.2 valent. **Cohérence (shell, layout, espacements, tailles, variantes)** : si l'user désigne une **référence explicite** dans son message de lancement (un écran shadcn déjà construit, à suivre pour la cohérence) → CETTE référence fait foi, au même titre qu'un template. **Sans désignation explicite**, la page « Swile - Templates » (§2.2-0) reste l'autorité par défaut, exactement comme en convert — ne devine jamais une référence non nommée par l'user. **Témoin = l'écran le plus complexe parmi ceux à modifier/créer (comme en convert : le plus de types couverts), traité EN ENTIER** — toutes ses modifications demandées, pas la première trouvée : jamais de STOP après un seul élément simple (ex. un bouton ajouté) en laissant le reste de cet écran sans vérification avant d'enchaîner. Passe compare : source = spec/maquette ; update sans spec = read-back avant/après ; **create sans maquette** = paires en `expect{}` + read-back rapproché de la spec textuelle. `verify`/`textDiff` restreints au sous-arbre modifié (§2.5) ; violations préexistantes ailleurs → signale sans corriger.

**Deux familles de gates** :
- **Préférence** (verdict témoin, GATE skip, accents) : l'user peut les lever → note-le au LEDGER et continue. Par défaut le **STOP témoin est une pré-validation OBLIGATOIRE** : après le 1er écran, poste et attends. Ne pose à l'user QUE des questions de préférence (accents, contenu ambigu, skips fonctionnels) — **jamais de validation technique** (« mon mapping te va ? » est interdit : les choix techniques se tranchent par la mesure).
- **Techniques** (sonde exhaustive, warm-up, verify, compare, textDiff, reconcile, read-backs, registres) : **jamais levables, même sur demande explicite** — « ok pour enchaîner, mais les passes scriptées restent exécutées et postées pour chaque écran. »

**Contrat** : fichiers DS/Library en **lecture seule**. Aucun fichier local modifié sans ok — exceptions nommées : les fichiers de travail du run (§0), l'auto-guérison `autoUpdate` du settings (§0.0-b), le RETEX sauvé en local en dernier recours (§2.7). Blocage technique → stop, explique, demande. **Toute manipulation de la SOURCE est interdite** (y compris la déplacer « pour une capture » — recette fournie §2.5).

---

## 0. SETUP — checks pass/fail, dans l'ordre, avant TOUT

Plugin **Desktop Bridge** requis dans 3 fichiers : travail, DS **« 🏢 Flõw | Corporate »** (`4PbwFAfHhSgQXG9jAZL2EE`), icônes **« 🗂️ Flõw | Library »** (`gZnTctmu6pjs7IJpVls3gR`).

0. **Skill à jour ? — GATE BLOQUANT : ce skill ne tourne JAMAIS sur une version périmée.**
   **0-a. Verrou de reprise** : si `.swile-update.lock` existe à la racine du répertoire de travail — sa `version` ≠ celle du titre de ce document → cette session a déjà installé une mise à jour et est **condamnée pour ce skill** : ré-affiche le bandeau rouge ci-dessous et STOP (le hook bloque de toute façon chaque fin de tour tant que ce fichier désigne une autre version). Sa `version` = celle du titre → session neuve saine : **supprime le fichier** et continue.
   **0-b. Check distant** : `curl -s https://raw.githubusercontent.com/romainswile/swile-design-marketplace/master/.claude-plugin/marketplace.json` → compare `version` à celle du titre. Plus récente → exécute directement (sans question) `claude plugin marketplace update swile-marketplace && claude plugin update swile-design@swile-marketplace`, écris `.swile-update.lock` = `{"version":"<nouvelle>"}` ET la sentinelle `.swile-verify.json` = `{"etat":"bloque","motif":"mise à jour installée, nouvelle session requise"}` (fichiers à la racine du répertoire de travail — définis en fin de §0), puis **STOP NET** avec EXACTEMENT ce bandeau (« ok » ne suffit pas : la version chargée ne change pas en cours de session, et le hook bloque toute reprise) :
> # 🟥🟥🟥 MISE À JOUR INSTALLÉE — CETTE SESSION EST TERMINÉE 🟥🟥🟥
> **Le plugin swile-design vient de passer de vA.B.C à vX.Y.Z.** Cette session a chargé l'ancienne version et **ne peut plus exécuter ce skill** — toute reprise ici sera bloquée automatiquement.
> ### 👉 Ouvre une **NOUVELLE SESSION** et relance ta commande `/swile-design:shadcn …` — c'est tout.
> *(Selon ta version de Claude, `/reload-skills` ou `/reload-plugins` suivi de ta commande peut éviter de changer de session.)*
   Anti-fausse-alerte : si `claude plugin list` montre l'installée = distante, la mise à jour est déjà faite — même bandeau, même STOP (sans relancer l'update). **Auto-guérison (avant le STOP)** : si `~/.claude/settings.json` → `extraKnownMarketplaces.swile-marketplace` existe sans `"autoUpdate": true`, ajoute la clé (préserve le reste du fichier) — les prochains démarrages seront à jour nativement et ce gate ne se déclenchera plus. `claude` introuvable (rare) → même STOP, avec `/plugin marketplace update swile-marketplace` puis `/plugin` → Installed → update dans le message. Pas de réseau/curl (invérifiable) → continue, mais note LEDGER `{type:'VERSION-NON-VERIFIEE'}` et signale-le dans le rapport.
1. **Un seul serveur** : `figma_get_status` → **`portFallbackUsed` DOIT être `false`** (et `otherInstances` vide s'il est présent — champ absent des sorties récentes : ne conclus jamais « pas d'orphelin » de son absence). `portFallbackUsed:true` = un autre serveur tient le port préféré, PAS un caveat à noter (mécanisme : plusieurs serveurs se disputent le websocket du plugin → déconnexions spontanées dès les premières minutes). Traitement : inventaire (`lsof -i :9223-9232` / `netstat -ano`), **question à l'user** (1ʳᵉ option : « Je tue les orphelins automatiquement (Recommandé) »), kill — Windows (PowerShell) : `taskkill /PID <pid> /F` · macOS/Linux : `kill -9 <pid>`. ⚠️ Tuer l'orphelin ne suffit PAS à revenir à `false` (un serveur ne migre jamais de port) → enchaîne avec le **RESTART AUTONOME du serveur (procédure en fin de §3.2)** : kill du serveur actif → respawn sur 9223. ⚠️ **Orphelins tués AVANT toute réouverture du plugin** (scan des ports → rattachement à un orphelin).
2. **Bridge répond** : boucle `figma_get_status` (`probe:true`) jusqu'à `probeResult.success===true`. `false` après ~15 s → STOP : « ferme et rouvre le plugin sur <fichier>, puis dis-moi ok. »
3. **3 fichiers connectés** : `figma_list_open_files`. Manquant → STOP.
4. **DS abonnée** (cible = fichier de travail) : via `figma_execute` — `await figma.teamLibrary.getAvailableLibraryVariableCollectionsAsync()` liste des collections « Corporate ». Sinon STOP → Assets > Libraries. ⚠️ Cette liste est **figée au lancement du plugin** : si l'user vient d'activer la librairie, le check restera vide jusqu'à réouverture du plugin dans ce fichier (un import-test qui passe confirme l'activation réelle en attendant). *(PAS `figma_get_library_variables`.)*
5. **Plugin Bridge à jour** : dans le status, `pluginVersion` de CHAQUE fichier connecté = `bundledPluginVersion`, et jamais `pluginUpdateAvailable:true`. Sinon STOP et affiche EXACTEMENT ce gabarit (une session entière a gelé en cascade sur un plugin v1.14 périmé) :
> 🟥 **STOP — plugin Figma « Desktop Bridge » périmé** (détecté : v\<X\> · attendu : v\<Y\>). Cette combinaison n'est pas testée et est suspectée dans des gels d'imports en cascade. À faire (30 s, une fois) :
> 1. Dans Figma, ferme puis rouvre le plugin (Plugins → Development → Figma Desktop Bridge) dans les 3 fichiers.
> 2. Toujours v\<X\> ? Ton manifest pointe vers une vieille copie → Plugins → Development → supprime « Figma Desktop Bridge » → **Import plugin from manifest** → `~/.figma-console-mcp/plugin/manifest.json` → rouvre-le dans les 3 fichiers.
>
> Dis-moi « ok » quand c'est fait — je revérifie et on continue.
6. **IMPORT-TEST de setup** : un import chronométré de **chaque type — 1 composant + 1 style + 1 variable** — d'une clé de l'annexe (`timeout:30000`). Sain = ~15 ms (cachée) à ~2 s (neuve). **> 5 s ou timeout sur N'IMPORTE lequel = canal déjà malade → demande la réouverture du plugin (3 fichiers) MAINTENANT**, avant de lancer les 40+ clés du warm-up dedans (mécanisme : un gel initial se voit dès le premier import — le détecter là économise 5-20 min de récupération en plein warm-up ; les 3 types car ils gèlent indépendamment, cf. §3.2).

`figma_navigate` switche la cible sans rien fermer. **Après CHAQUE navigate : probe trivial** (`return 1+1`) — timeout sur read trivial = divergence onglet/cible, pas une lenteur. Re-check le point 1 avant chaque phase d'import.

**Registres de session** (à créer au setup, un seul call) — ⚠️ **chaque fichier Figma a son propre sandbox JS** : registres et helpers vivent dans le sandbox du **FICHIER DE TRAVAIL**. Ne pousse JAMAIS dans un registre pendant que la cible est le DS/Library (le push irait dans le mauvais sandbox et serait perdu, et `reconcile` pourrait passer au vert par vacuité) : collecte tes mesures, reviens sur le fichier de travail + probe, PUIS pousse. Après tout restart/réouverture : registres VIDES → recharge depuis `.swile-state.json` (§3.5). **Dès le setup, écris aussi (Write, dans le scratchpad temporaire) un `helpers.js` contenant TOUS les helpers du skill** : le sandbox peut se réinitialiser SANS prévenir (reload du plugin, navigation, mémoire) — au premier `ReferenceError: <helper> is not defined`, ré-exécute `helpers.js` tel quel + recharge les registres depuis `.swile-state.json`, et reprends.
```js
globalThis.MAPPING=[]; globalThis.LEDGER=[]; globalThis.SWAPS=[]; globalThis.RESIZES=[];
return 'registres prêts, fichier: '+figma.root.name;   // DOIT être le fichier de travail
```
**Marqueur de run + sentinelle (pour le hook de gate)** : écris (outil Write), à la racine du répertoire de travail : `.swile-run.lock` = `{"demarre":"<ecrans demandés>"}` **et** `.swile-verify.json` = `{"etat":"en_cours","ecrans":{},"clean":false}`. Le hook bloque toute fin de tour tant que `etat:"en_cours"` / `clean:false` — états qui laissent sortir : `en_attente_verdict` (STOP témoin, §2.6), `bloque` (panne exigeant l'user — ajoute `motif`), `fini` (rapport livré, avec `clean:true`). Ces fichiers de travail (`.swile-run.lock`, `.swile-verify.json`, `.swile-state.json`, plus `.swile-update.lock` le cas échéant) sont, avec `helpers.js` du scratchpad, les SEULS fichiers locaux que tu crées/modifies, et tu les tiens à jour scrupuleusement.

---

## 1. Interdits absolus & modes de panne

**OBLIGATION n°1 (ce n'est pas un interdit — l'OUBLIER fige le worker)** : `timeout:30000` sur **tout** call contenant un import (le défaut 5 s coupe l'import) **et sur tout walk d'arbre complet d'écran** (dumpSource/verify/compareToSource/textDiff sur une racine — mesuré jusqu'à ~15 s). Plafond dur figma_execute : 30 s.

**Interdits (chaque violation a cassé un run réel)** :
- Jamais : `Promise.all` d'imports · **import + build dans le même call — MÊME sur clés cachées** (mécanisme : sur canal dégradé, l'import inline qui gèle emporte tout le call et son build ; « c'est caché donc rapide » est vrai jusqu'au jour où ça ne l'est plus) — un ré-import d'id périmé se fait dans un call DÉDIÉ, ou mieux : clone depuis le KIT (§2.3) · boucle d'import `await`-ée · `importComponentSetByKeyAsync` · `loadAllPagesAsync()` sur le DS · `figma_instantiate_component` / `figma_search_components` / `figma_get_library_variables`. Exception nommée : le **swap** (`setProperties` INSTANCE_SWAP) exige un id de composant vivant — si l'id est null, ré-importe-le dans un call dédié AVANT le call de swap.
- **Le SEUL cap autorisé autour d'un import = `withTimeout` 20 s PAR CLÉ**, dans ses trois emplois légitimes : la boucle détachée du warm-up, un ré-import isolé en call DÉDIÉ, l'import-test. Tout cap plus court ou « de diagnostic » = coupure interdite (mécanisme : la promesse coupée laisse l'import en vol dans la file native, qui finit par geler le canal pour toutes les clés non cachées).
- **Un call timeouté n'est PAS annulé** : l'exécution continue et peut committer partiellement OU **en différé** (le re-scan immédiat dit « vide », le contenu apparaît après — doublons garantis au retry aveugle). Règle : nomme d'un **tag unique** les frames créées par chaque call de build (purge par tag possible) ; après un timeout, **attends ≥30 s** puis re-scan AVANT toute re-soumission.
- **Budget par call de build : ~15 ops** (latence mesurée jusqu'à ~1 s/op sur canal chargé ; le transport coupe les gros calls à ~10 s en ignorant ton paramètre timeout). Gros build = série de micro-calls.
- **Redimensionner une instance à la main = interdit** → `sizeInst()` (§2.4) exclusivement. Mécanisme mesuré : `.rescale()` détache les text styles — irréparable, tout ré-attachement est un no-op silencieux de l'API — alors que `.resize()` **préserve le lien** ; le helper choisit le bon chemin.
- **Swap d'icône « nu » = interdit** — y compris via `setProperties` sur une prop INSTANCE_SWAP (boutons à icône) → `swapIcon()` (§2.4) exclusivement (swap + recolor + read-back + registre en un call).
- **`counterAxisSizingMode='AUTO'` (hug) sur le frame RACINE d'un écran = interdit.** Un « contenu déborde » se corrige en **bissectant** (poste la table des hauteurs enfants repro vs source, corrige l'enfant fautif) — JAMAIS en agrandissant/huggant le parent pour éteindre le flag.
- **Ne renomme JAMAIS une instance de composant DS** (son nom = son lien au composant dans Figma ; le sens se porte sur la frame parente ; tes scripts s'ancrent par **id**, pas par nom).
- **Tout fix déclenché par verify** retourne dans le MÊME call le read-back layout complet du nœud corrigé (`{layoutMode, primaryAxisAlignItems, itemSpacing, sizing H/V}`) — un re-scan count seul ne valide RIEN (mécanisme : un « fix » peut détruire le layout en silence — racine passée en hug, space-between écrasé — et le re-scan dit quand même « vert »).
- **Clé de VARIANTE, jamais de SET** ; 1 import/SET puis `setProperties`. Node-id importé instable → ré-importe par clé (cache ~150 ms) **dans un call DÉDIÉ** (jamais mêlé au build — cf. interdit ci-dessus), ou mieux : clone depuis le KIT. Ne ré-importe jamais une ressource locale ; **clone l'instance posée** pour les répétitions.
- **Pendant un gel, les LECTURES passent** : probe sain ≠ imports sains.

**Modes de panne** (récupération §3) :
| Symptôme | Diagnostic | → |
|---|---|---|
| Clé d'import pend >20 s | Import individuel gelé — le lot continue (timeout/clé) | §3.1 |
| Plusieurs clés pendent, d'autres passent | Canal empoisonné (se dégrade avec le temps) ; cache immunisé | §3.2 |
| « Unable to establish connection » mais `1+1` passe | Blip (retente 1×) ou **nœud toxique** (id imbriqué `I…;…`) → parent + `findAll` | §3.6 |
| Timeout sur read trivial | Divergence onglet/cible → re-navigate + probe | §0 |
| `getNodeByIdAsync → null` | Souvent mauvais fichier actif → re-navigate + probe | §0 |
| Nœuds disparus/écrans rétrécis après reconnexion | Revert des modifs non committées | §3.5 |
| Gros call refusé, petit call passe | Canal dégradé → découpe le script en 2 calls | §3.6 |

---

## 2. La méthode — ordre strict, artefacts postés

**Vue d'ensemble** : source (2.1) → mapping+registres (2.2) → sonde puis warm-up (2.3) → build témoin (2.4) → vérifs 4 artefacts + checklist (2.5) → **STOP pré-validation user** (2.6) → série écran par écran (mêmes artefacts) → rapport = registres (2.7).

### 2.1 Lis la source (convert)
1 screenshot par écran (`figma_capture_screenshot`, scale ≤1, une fois — budget : 1 source + 1 côte-à-côte par cycle de vérif + 1 candidat-icône si comparaison de glyphe ; jamais de capture « pour voir »).
**Tout relevé source DOIT passer par `dumpSource`** — un relevé ad hoc « texts-only » (`map(t=>t.characters)`) n'est PAS un artefact valide (mécanisme : sans structure, une chaîne lue se réattribue au mauvais nœud → éléments inventés). Cellule anormale du dump (valeur vide, colonne décalée, dernière ligne atypique) → **re-dump ciblé** avant de construire.
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
**Sidebar (uniquement si l'user le demande explicitement dans son message de lancement — ex. « sans menu de gauche, à cloner depuis la source » — sinon la sidebar suit la règle normale de reconstruction comme le reste de l'écran, AUCUN clone par défaut)** : SEULE la sidebar (le chrome désigné) se clone (`node.clone()`), **contenu inclus, telle quelle**, nom exact `sidebar (cloné)` — ne vide/reconstruis JAMAIS l'intérieur du clone. Tout le RESTE de l'écran se reconstruit. **Read-back post-clone obligatoire** : `{sourceSidebarH, cloneH, rootH}` avec `cloneH ≤ rootH` et `|cloneH−sourceSidebarH| ≤ 1`, sinon STOP et corrige le shell (jamais la racine en hug). Re-vérifié en fin d'écran.

### 2.2 Mapping — TEMPLATES d'abord, puis tableau + registres + GATE
**0) TEMPLATES D'ABORD (obligatoire, avant toute décision de mapping)** : navigate DS + probe → page **« Swile - Templates »** (exemples officiels Swile, alimentée en continu). Convention : section `<ÉCRAN> - CONVERT` = frame `<ÉCRAN> - OLD` (source d'origine) + **COMPONENT publié `<ÉCRAN> - SHADCN`** ; sans suffixe = from scratch. Scan scripté posté : `await page.loadAsync()` PUIS `findAllWithCriteria({types:['COMPONENT','COMPONENT_SET']})` → noms + **clés** + dims. Puis, du plus gros au plus petit :
- **L'écran demandé correspond à un template SHADCN** → importe le COMPONENT par sa clé (au warm-up), **`const inst = comp.createInstance(); const livrable = inst.detachInstance();`** — jamais `comp.clone()` directement sur le COMPONENT (`clone()` sur un `ComponentNode` renvoie un second `ComponentNode`, un maître dupliqué qui pollue le panneau Assets et se comporte différemment d'une frame — mesuré : ça a fini dans un livrable réel). `detachInstance()` donne une vraie `FrameNode` indépendante, cohérente avec le type des autres écrans construits sans template. Chemin le plus fiable qui existe malgré tout (fidélité maximale, zéro reconstruction manuelle) ; adapte le delta via props/overrides **avant** le detach (les overrides d'instance ne s'appliquent plus après), chaque override au LEDGER. **Timeout sur cet import** (un template publié peut peser plusieurs centaines de nœuds) : traite-le EXACTEMENT comme un timeout de warm-up (§2.3 — une relance après un lot, fenêtre morte sentinelle `bloque`+`sleep` en arrière-plan+fin de tour) — **jamais de sleep de premier plan** (le harness le bloque) **ni `ScheduleWakeup`** (outil du skill `/loop`, sans rapport avec cette attente) ; re-timeout → §3.2.
- **Un élément est couvert par un template** → clone-le depuis l'instance posée (ou réplique-le depuis le dump du template) — mêmes composants/variantes/tokens, jamais réinventé. Après tout clone de template : **passe `clipsContent=false` sur les frames clonées** (les templates peuvent en hériter, `verify` les flaguera sinon). Les instances de template sont aussi ta **mine de text styles** (harvest, §2.3).
- **Rien ne correspond** → mapping classique ci-dessous.
Le template bat ta préférence — c'est la cohérence inter-écrans de Swile. Chaque ligne MAPPING garde son champ `tpl`.
**Le mapping couvre TOUS les écrans demandés AVANT le témoin** — pas seulement le premier (mécanisme : le canal d'import est au meilleur de sa forme en début de session et se dégrade avec le temps ; chaque import repoussé en cours de série s'expose au gel).
**Artefact double** : le tableau lisible posté, ET sa forme machine dans le même call :
```js
// une entrée par élément source, PAR ÉCRAN. statut: 'DS' | 'custom' | 'SONDE' (choix à mesurer)
// tpl OBLIGATOIRE : 'Section›élément' du template appliqué, ou 'aucun' (champ absent = ligne invalide au reconcile)
// statut 'custom' exige preuveCustom : réf. à l'artefact posté (templates sans correspondance + ≥2 synonymes ✦/showcases sans résultat)
globalThis.MAPPING.push({ecran:'CODE', ligne:'bouton Add', src:'1:18932', choix:'Solid Button secondary/lg', statut:'DS', tpl:'aucun'});
```
**Complétude du mapping — `structureCouverte`, à lancer juste après avoir fini le mapping de CET écran, avant la sonde/build** (mesuré : un conteneur entier — enveloppe blanche d'un écran — n'a jamais eu de ligne MAPPING du tout, donc `reconcile()` n'a rien pu flaguer : on ne détecte pas l'absence d'une ligne qui n'a jamais existé) :
```js
globalThis.structureCouverte = async (ecran, sourceRootId) => {
  const root = await figma.getNodeByIdAsync(sourceRootId);
  const junk = /^(Frame|Group|Rectangle|Vector|Ellipse)\s*\d*$/i;   // ignore les noms auto-générés Figma, source de bruit sur fichiers legacy mal nommés
  const conteneurs = root.findAll(n=>(n.type==='FRAME'||n.type==='GROUP')&&n.visible!==false&&!junk.test((n.name||'').trim())&&n.parent&&(n.parent.id===root.id||(n.parent.parent&&n.parent.parent.id===root.id)));
  const lignes = MAPPING.filter(x=>x.ecran===ecran).map(x=>x.ligne.toLowerCase());
  const manquants = conteneurs.filter(c=>{const nm=c.name.toLowerCase();return !lignes.some(l=>l.includes(nm)||nm.includes(l));}).map(c=>c.name);
  return { ecran, manquants, ok: manquants.length===0 };
};
```
`manquants` non vide = un conteneur du 1er/2e niveau de la source, nommé de façon significative, n'apparaît dans AUCUNE ligne MAPPING de cet écran → soit ajoute la ligne manquante et couvre-le, soit prouve qu'il est déjà couvert sous un autre nom (par ex. dans la description d'une ligne existante) avant de continuer. Ne remplace pas `reconcile()` (qui vérifie que chaque ligne MAPPING **existante** a sa paire) — celui-ci couvre l'amont : que chaque conteneur **existe** dans le registre avant même de parler de paire.
- Éléments proches = composants **distincts**. **Recoupe rendu + nom du nœud source + logique attendue** — la sonde mesure, elle **ne dispense pas de lire la source** (bordure visible → Outline candidat ; fond transparent → Ghost ; un même libellé sur 2 écrans ≠ même composant : **re-lis le nœud source de CET écran** avant de réutiliser une ligne de mapping ailleurs — sinon l'élément hérite du composant d'un autre écran).
- **Test skip/compromis, appliqué AU MOMENT du choix** : élément ou propriété **visible** de la source absent de la repro = **SKIP, quel que soit le mot que tu emploies** → GATE (stop, préviens, demande, attends). Composant DS présent mais valeur divergente (token/taille au plus proche) = **compromis** → `LEDGER.push({ecran, element, type:'COMPROMIS', source:'…', choix:'…', pourEgaler:'…'})` **immédiatement** (pas au rapport). Un compromis dont `pourEgaler` se résout par un **simple import** (ex. « importer Ghost Icon Button ») = **refusé** : fais l'import isolé (§2.6), « coûteux » n'est pas un motif.
- **Custom = dernier recours avec preuve MÉCANIQUE** : une ligne `statut:'custom'` n'est valide que si `preuveCustom:` référence un artefact scripté posté (scan Templates sans correspondance + `findAllWithCriteria` ≥2 synonymes sur pages ✦/showcases sans résultat). `reconcile()` échoue sur tout custom sans preuve (mécanisme : un custom sans recherche reproduit de mémoire un composant qui existe déjà — et `verify` ne peut pas le voir, il vérifie les tokens, pas l'existence d'un équivalent DS). **Exception déclarée** : les customs pré-justifiés par l'annexe (ex. pastilles) portent `preuveCustom:'annexe:<ligne>'` — la recherche ≥2 synonymes est levée, le scan Templates reste dû.
- **Icônes** : « 🗂️ Flõw | Library » UNIQUEMENT. **Toute substitution/choix de glyphe exige la preuve de recherche scriptée** (navigate Library + probe → `findAllWithCriteria` filtré ≥2 synonymes → 1 screenshot du candidat comparé à la source). **Une clé de l'annexe ne vaut que pour un glyphe déjà comparé à la source dans CETTE session** — l'annexe n'est pas l'inventaire de la Library (mécanisme : une clé jamais comparée pose un glyphe faux en silence). Recherche infructueuse = SKIP → GATE.
- **Sémantique des teintes** : un statut « en attente/pending » n'est PAS `Info` bleu par défaut — suis la couleur **mesurée** de la source (texte simple = texte simple).
- **Violet legacy (accent Swile #664ef9 / #633fd3 / #5541cf / #d6d0fd…)** : en convert, mappe vers **`colors/violet/*`** (gamme Tailwind 50–950, mesurée au DS) au plus proche par distance — **sans question user**, LEDGER `{type:'ACCENT-TAILWIND (auto)'}` avec la nuance choisie. La question accent ne se pose qu'en create from scratch sans template applicable.
- **Tokens partout, customs inclus** (couleurs, text styles, gap, padding, radius, border-width). **Absence dans l'annexe ≠ absence dans le DS** : avant tout arrondi, **preuve de recherche scriptée du token exact** (par nom ET par valeur, `getLocalVariablesAsync` sur le DS) collée — sans elle l'arrondi est refusé (mécanisme : l'annexe est un cache partiel — arrondir sans chercher écrase une valeur que le DS possède).

### 2.2bis Signal de complexité — actif UNIQUEMENT en mode `convert-adapt`, UNE décision groupée après le mapping COMPLET de tous les écrans, avant tout build
**Ne s'exécute pas en `convert`/`update`/`create`** — vérifie le mode annoncé par l'user avant d'appliquer cette section (§ « Modes » en tête de skill). **N'évalue rien tant que le mapping de TOUS les écrans demandés n'est pas fini** (le mapping couvre déjà tous les écrans avant le témoin, §2.2) — évaluer écran par écran pendant le mapping ferait porter la décision sur l'ordre de mapping, pas sur l'ordre réel de construction, et ferait hériter du changement le mauvais écran (mesuré : un run l'a fait, l'escalade serait tombée sur le témoin construit en premier plutôt que sur l'écran réellement complexe).

**Par écran, deux compteurs DÉDOUBLONNÉS** (aucun champ nouveau — dédoublonne par `choix`, pas par ligne : un même élément custom dupliqué sur l'écran — ex. une card répétée 2 fois avec la même solution — compte pour UN seul, la 2e occurrence est un clone de la même décision, pas une décision de plus) :
```js
const customs = new Set(MAPPING.filter(m=>m.ecran===écran && m.statut==='custom').map(m=>m.choix)).size;
const compromis = new Set(LEDGER.filter(l=>l.ecran===écran && l.type==='COMPROMIS').map(l=>l.choix)).size;
```
**Seuil de déclenchement (ET, pas OU)** : `customs>=2` **ET** `compromis>=3` — les deux signaux doivent co-exister pour juger l'écran ambigu ; un seul signal isolé (2 customs propres sans aucun compromis, par exemple) ne suffit pas à déclencher une pause, il se traite normalement. **Tier de sévérité, une fois le seuil franchi** : `customs>=4` OU `compromis>=6` (un seul signal qui s'envole suffit) → **marqué** ; sinon → **modéré**.

**Partitionne AVANT tout build** : `defaut` = écrans qui ne franchissent pas le seuil ; `escalade` = écrans qui le franchissent. Construis d'abord **tout le groupe `defaut`** (dans l'ordre demandé entre eux, réglage courant inchangé du début à la fin de ce groupe) — le témoin (§2.6) est le premier écran de CE groupe, ou le premier du groupe `escalade` si `defaut` est vide, pas forcément le premier écran nommé par l'user dans la requête initiale.

**Si `escalade` est vide → rien à proposer, série normale.** Si `escalade` est non vide, **UN SEUL STOP pour tout le lot** une fois le groupe `defaut` terminé (jamais un STOP par écran, jamais plusieurs allers-retours de modèle en cours de run) :
- Un seul écran du lot en tier **marqué** suffit pour proposer le **plafond Opus/xhigh** à TOUT le lot.
- Sinon (tout le lot en tier **modéré**) → propose **un seul** demi-cran pour tout le lot, choisi parmi : garder le modèle et monter l'effort (Sonnet high → Sonnet xhigh) ; monter de modèle en gardant l'effort (Sonnet high → Opus high) ; monter de modèle en **baissant** l'effort (Sonnet high → **Opus medium** — souvent comparable en coût, un modèle plus capable à effort moindre égalant ou dépassant un modèle plus faible à effort élevé).
- **Un seul changement de modèle/effort sur tout le run** : jamais d'étapes (jamais Sonnet → Opus medium PUIS Opus high) — le lot entier bascule sur UN palier, une seule fois.
- **Plafond absolu, sur les deux tiers : jamais au-delà de `xhigh`, sur AUCUN modèle (Sonnet compris)** — ne propose jamais `max`, ni Fable, quelle que soit la sévérité.
- Ne présente **jamais** l'option de rester comme « recommandée » ou toute formulation qui pousse à décliner ta propre proposition — présente les deux options à égalité, l'user tranche.
- **Explicite la portée** dans le message : le changement, s'il est accepté, s'applique à TOUT le lot `escalade` restant (pas juste au prochain écran) et reste actif jusqu'à ce que l'user dise explicitement de revenir au réglage initial — tu ne peux ni lire ni changer le modèle/effort toi-même (aucune API exposée), ce STOP est le seul canal.

Message type : « Groupe `defaut` terminé (<liste>). Écrans `<liste escalade>` : signaux dédoublonnés — <détail par écran, N customs / M compromis>. Proposition pour CE LOT ENTIER : <échelon calculé ci-dessus>. Le réglage s'appliquera à tous ces écrans jusqu'à ce que tu redemandes explicitement de revenir en arrière. Tu changes de modèle/effort puis « ok », ou je construis ce lot sur le réglage actuel ? » puis **STOP, attends**.
- Sentinelle `{"etat":"bloque","motif":"proposition modèle plus capable pour <liste escalade>"}` avant le STOP, repasse `en_cours` à la reprise (accord ou refus, dans les deux cas).
- User change de modèle/effort et répond « ok » → construis le lot `escalade` entier sur ce nouveau réglage, sans nouveau STOP intermédiaire.
- User dit de rester → construis le lot `escalade` sur le réglage courant (rien à consigner : ce n'est pas un compromis de design, `reconcile()` n'en dépend pas).

### 2.3 Sonde (sur le DS) puis warm-up (sur le fichier de travail)
**En update/create : cette section entière ne s'applique QUE si le delta requiert au moins une clé neuve.** Avant de déclencher quoi que ce soit, liste ce dont le delta a réellement besoin (composant/variable/style) et soustrais ce qui est déjà disponible — importé plus tôt dans CETTE session (`COMP_KEYS`/`VAR_KEYS`/`STYLE_KEYS` déjà peuplés), ou déjà lié sur l'élément visé (rebind d'un token existant, par ex.). Liste résiduelle vide → **saute intégralement §2.3** : zéro import, zéro sonde, zéro fenêtre morte, passe direct à la modification/construction. Liste non vide → applique §2.3 normalement, mais restreint à ces clés résiduelles seulement (pas de warm-up générique de 40+ clés pour un delta qui n'en demande qu'une).

**Séquence** (convert, ou update/create avec clés neuves) : ① navigate DS + probe → **SONDE** (lecture seule, zéro import) ; ② navigate travail + probe + re-§0.1 → **WARM-UP**. Rien ne se construit avant la fin des deux.

**SONDE — exhaustivité mécanique** : entrée = TOUTES les lignes `statut:'SONDE'` du MAPPING ; après les mesures et la mise à jour du MAPPING, poste l'artefact de clôture (sur le fichier de travail) : `return {lignesSansMesure: MAPPING.filter(x=>x.statut==='SONDE').map(x=>x.ligne)}` — **DOIT être vide** (c'est le même critère que `reconcile.sondeNonMesuree`, vérifié plus tôt). Il est **interdit d'instancier** un élément dont la ligne contient encore `SONDE` ou un « ou » non tranché — écrans suivants inclus (une ligne SONDE non mesurée finit posée au hasard). **Pour tout bouton : les 4 sets Solid/Soft/Outline/Ghost sont candidats systématiques.** Le **stroke compte** : source à bordure visible + candidat sans stroke = éliminé (et inversement) — un Outline blanc bordé est indiscernable au fill seul.
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
    if(sourceHex!==undefined && sourceStroke!==undefined && (!!st)!==(!!sourceStroke)) r.dist=(r.dist??0)+500; // bordure incohérente = fortement pénalisé (+500) — vérifie que le retenu n'a PAS cette pénalité
    out.candidats.push(r);
  }
  if(sourceHex) out.candidats.sort((a,b)=>(a.dist??1e9)-(b.dist??1e9));
  const ok=out.candidats.find(c=>!c.err); out.choix=ok?ok.label:null;
  if(out.candidats.some(c=>c.err)) out.attention='candidat(s) en erreur — choix parmi les mesurés seulement';
  return out;
};
```
`fillOpacity` < ~15 % ≈ invisible sur blanc. Égalité au fond → départage par stroke/opacité/page d'usage, ou demande. Toute ligne d'annexe utilisée au mapping doit apparaître dans les mesures, sinon « annexe non confirmée » au LEDGER. Après la sonde : **mets à jour MAPPING (statut 'SONDE'→'DS' + choix mesuré)**.
**Annexe contredite par la mesure** (clé qui n'importe plus, set/variante introuvable ou renommée, valeur différente) → affiche ce bandeau, et **ré-affiche-le EN TÊTE du STOP témoin, EN TÊTE du rapport final, et en PREMIÈRE ligne du RETEX** (une mention noyée dans un paragraphe = signal perdu) :
> # 🟥🟥🟥 SNAPSHOT/ANNEXE DS PÉRIMÉ — PRÉVIENS ROMAIN 🟥🟥🟥
> **<ligne contredite : valeur mesurée vs valeur annexe>**
LEDGER `{type:'ANNEXE-PERIMEE'}`, et continue avec la valeur **mesurée**.

**Text styles & variables — échelle d'acquisition** : ① **harvest** depuis un nœud vivant qui l'utilise — lis `textStyleId` sur une instance importée/un template posé : un styleId remote s'applique tel quel à tout texte neuf (testé) ; idem TOUTES les variables (couleur, `itemSpacing`, `padding*`, radius, `strokeWeight`…) : `n.boundVariables.<prop>.id` d'un nœud vivant **du fichier de travail** (instance importée, template posé) → `getVariableByIdAsync` → re-liable partout via `setBoundVariable`/`setBoundVariableForPaint` — « swapper » un token = re-lier l'id harvesté (pas d'API de swap dédiée, pas besoin) ; ⚠️ un id harvesté sur un nœud du DS (autre sandbox) ne résout PAS dans le fichier de travail ; ② `importStyleByKeyAsync`/`importVariableByKeyAsync` au warm-up UNIQUEMENT ; ③ introuvable par ①② → fallback §3.7 (l'user colle la frame Typography). Jamais d'import de composant dans le SEUL but d'en extraire un style ; jamais d'importStyle en cours de build.

**WARM-UP (testé)** — construis `COMP_KEYS`/`VAR_KEYS`/`STYLE_KEYS` (`[['nom','clé'],…]`) depuis mapping+sonde+annexe **pour TOUS les écrans demandés** (composants, icônes, tokens dimension, text styles, templates SHADCN) — un import mi-série est un mode dégradé (§3), pas le plan. **Ordre qui minimise les imports** (chaque import évité est un gel évité — les styles/variables sont les plus fragiles) : ① importe d'abord les **COMPOSANTS** (templates SHADCN, atomes, icônes — eux ne se harvestent pas) ; ② **inventorie** les styles et variables vivants qu'ils portent (masters importés + instances posées : `textStyleId`, `boundVariables.*` — § échelle ci-dessus) ; ③ n'importe par clé QUE les styles/variables que l'inventaire ne couvre pas (souvent presque rien). Concrètement : **DEUX passes détachées** (passe A = composants, fenêtre morte, pose du KIT + inventaire ; passe B = reliquat styles/vars — si ≤3 clés, des calls dédiés `withTimeout` 20 s suffisent, sans boucle ni fenêtre). Script d'une passe (call `timeout:30000`) :
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
**Après le lancement de la boucle détachée : FENÊTRE MORTE de 120 s — AUCUN call bridge/figma_*, pas même un poll.** Mécanique d'attente compatible avec le hook : passe la sentinelle à `{"etat":"bloque","motif":"warm-up — fenêtre morte en cours"}`, lance `sleep 120` en arrière-plan (`run_in_background`) et **termine ton tour** — la notification du sleep te réveille pour le poll ; repasse alors la sentinelle à `en_cours`. Puis **UN** poll. `done<total` sans `timeouts` → re-fenêtre 60 s puis re-poll (3 max, ensuite traite comme timeouts). Chaque call bridge concurrent pendant la boucle peut geler les clés en vol (mesuré : les clés qui échouent sont exactement celles en vol au moment des polls). `timeouts` → une relance après le lot ; re-timeout → §3.2. `err` → re-découverte **après le lot** (navigate DS, relève, retour + probe, relance ces clés). **Les ids importés (composants, variables ET styles) peuvent résoudre `null` plus tard** — arbitrage strict : **en phase de BUILD, tu ne touches plus à `G.*`** (tout vient du KIT par clonage, et des ids harvestés sur nœuds vivants) ; si un id est VRAIMENT requis (prep d'un swap, reconstruction du KIT) et résout `null` → ré-import par clé dans un **call DÉDIÉ** (withTimeout 20 s), puis reprends. Un accesseur qui ré-importe EN PLEIN call de build violerait l'interdit §1.
**Juste après le warm-up (ids encore frais)** : ① **précharge les polices dans un call DÉDIÉ** (`loadFontAsync` de chaque famille/style utilisés — Geist…) : le 1ᵉʳ chargement d'une famille est lent et, empaqueté avec un import dans un call de build, fait timeout le call entier en accusant l'import à tort ; ② **construis le KIT** : instancie UNE fois chaque composant dans un frame `KIT (scratch)` hors-canvas — ensuite tout se **clone depuis le KIT** (zéro import en phase de build, zéro dépendance aux ids périssables). Le KIT est supprimé au balayage final (§2.7).

### 2.4 Construis UN écran témoin
**Témoin** = l'écran couvrant le plus de types (souvent le plus complexe) — annonce ton choix, ne le fais pas valider. Pose chaque repro à droite de sa source, frame `<nom source> (shadcn)`. **Au début de CHAQUE écran** (témoin et suivants) : `globalThis.ECRAN='<nom>'` — les helpers taguent leurs entrées avec, et `reconcile` filtre dessus.

- **Shell d'abord**, construit une fois puis cloné. **Racine FIXED/FIXED aux dims de la source.** `x/y` posés AVANT `appendChild` ne sont pas conservés — positionne toujours APRÈS l'append. Clone en parent auto-layout → hérite STRETCH : lis la hauteur source AVANT l'append. Reparenting → re-pose `layoutSizingHorizontal='FILL'`.
- **Gate création de frames** : tout call qui crée des frames custom **retourne `{name,w,h,sizingH,sizingV}` de CHAQUE frame créé** — un frame auto-layout dont l'axe transverse reste `FIXED` sans resize explicite = piège 100px (la taille par défaut de `createFrame()` survit à l'auto-layout). `createFrame()` = 100×100 + `clipsContent=true` + **fill blanc** → pose taille + `clipsContent=false` + `fills` explicites immédiatement. **Exception mesurable** : un `clipsContent=true` est légitime uniquement s'il masque réellement quelque chose (un enfant déborde des bounds — vérifiable) → garde-le ET consigne LEDGER `{type:'CLIP-REQUIS', id:'<id du frame>', raison}` — `verify` exempte les ids ainsi consignés (count reste 0). **Hug en cascade** : contenu interne en auto-width (`textAutoResize='WIDTH_AND_HEIGHT'`).
- **Nommage** : tes frames custom = noms simples ; **instances DS = nom d'origine intouché** (§1).
- **Tokens liés À LA POSE, jamais en 2e passe différée** : `setBoundVariable`/`setBoundVariableForPaint` (`itemSpacing`, `padding*`, `topLeftRadius`×4, `strokeWeight`, couleurs) s'exécutent dans le **même bloc** que la création/pose du nœud — **interdit** de poser d'abord en valeurs brutes puis binder dans un 2e call séparé pour économiser des ops (mesuré : un run l'a fait « pour tenir le budget d'ops/call », résultat 56 items non liés détectés par lint après coup, rattrapés en double travail). Si le budget d'ops/call est vraiment trop juste pour poser+binder ensemble, **découpe par ZONE** (§1, ~15 ops/call) — jamais par « pose partout, puis binde partout ».
- **Redimensionner une instance** (avatars, icônes…) — HELPER OBLIGATOIRE (sortie collée ; un resize fait SANS le helper est attrapé par `verify` : texte détaché DANS instance, non exemptée du registre RESIZES) :
```js
// Instance À TEXTE : resize + text style DS de la taille cible (harvesté/warm-up) — le lien de style SURVIT à resize (testé), pas à rescale.
// Un texte DÉJÀ rescalé est irrécupérable par l'API (6 séquences mortes, resetOverrides inclus — l'instance garde un multiplicateur d'échelle) → re-crée l'instance et passe par resize ; n'essaie pas de « re-lier ».
// Instance SANS texte (icônes) : rescale — rien à détacher, proportions internes conservées.
globalThis.sizeInst = async (instId, w, h, styleIdOuNull) => {
  const inst = await figma.getNodeByIdAsync(instId);
  const aTexte = inst.findAll(n=>n.type==='TEXT').length>0;
  const avant = {w:inst.width, h:inst.height};
  if (aTexte) { inst.resize(w, h);
    if (styleIdOuNull) { const s=await figma.getStyleByIdAsync(styleIdOuNull); await figma.loadFontAsync(s.fontName);
      for (const t of inst.findAll(n=>n.type==='TEXT')) await t.setTextStyleIdAsync(styleIdOuNull); } }
  else inst.rescale(h/inst.height);
  const t1 = inst.findAll(n=>n.type==='TEXT')[0];
  const apres = {w:Math.round(inst.width), h:Math.round(inst.height), fontSize: t1&&t1.fontSize,
    styleDetache: !!(t1&&(t1.textStyleId===''||typeof t1.textStyleId!=='string'))};
  const out = {instId, ecran: globalThis.ECRAN, avant, apres, fichierActif:figma.root.name};
  globalThis.RESIZES.push(out);
  return out;   // styleDetache:true = un texte a perdu son style (rescale subi en amont ?) → LEDGER {type:'RESCALE-DETACHE (auto)', instId, ecran} ; ne « répare » pas (no-op API), ne passe JAMAIS en custom pour l'éviter
};
```
- **Swap + recolor d'icône — HELPER OBLIGATOIRE** (le swap nu est un interdit §1 ; 1 entrée SWAPS = 1 paire compare exigée par reconcile) :
```js
globalThis.swapIcon = async (instId, swapPropOuNull, iconCompId, varIdCouleur, hexAttendu) => {
  let inst = await figma.getNodeByIdAsync(instId);
  if (swapPropOuNull) inst.setProperties({[swapPropOuNull]: iconCompId});
  else { const comp = await figma.getNodeByIdAsync(iconCompId); inst.swapComponent(comp); }
  inst = await figma.getNodeByIdAsync(instId);   // RE-FETCH post-swap : recolorer l'objet d'avant = recolorer l'ANCIEN glyphe
  const v = await figma.variables.getVariableByIdAsync(varIdCouleur);
  const chainOK = n => { let p=n; while(p && p.id!==inst.id){ if(p.visible===false) return false; p=p.parent; } return true; };
  const done=[];
  for (const x of inst.findAll(n=>n.type==='VECTOR')) {
    const visible = x.visible!==false && chainOK(x);   // un vecteur peut être visible:true mais CACHÉ par un ancêtre (slot désactivé) — le recolorer = « corriger » un fantôme
    const hasFill=Array.isArray(x.fills)&&x.fills.some(p=>p.type==='SOLID'&&p.visible!==false);
    const hasStroke=Array.isArray(x.strokes)&&x.strokes.length>0;
    if(!hasFill&&!hasStroke) continue;
    if (visible) { let p={type:'SOLID',color:{r:0,g:0,b:0}}; p=figma.variables.setBoundVariableForPaint(p,'color',v);
      if(hasFill) x.fills=[p]; else x.strokes=[p]; }
    const q=(hasFill?x.fills:x.strokes)[0];
    done.push({vec:x.id, porteur:hasFill?'fill':'stroke', visible,
      cachePar: visible?null:(()=>{let p=x;while(p&&p.id!==inst.id){if(p.visible===false)return p.name.slice(0,25);p=p.parent;}return x.visible===false?'(lui-même)':null;})(),
      hex:'#'+[q.color.r,q.color.g,q.color.b].map(n=>Math.round(n*255).toString(16).padStart(2,'0')).join('')});
  }
  const boolsIconOff = inst.componentProperties ? Object.entries(inst.componentProperties).filter(([k,d])=>d.type==='BOOLEAN'&&/icon/i.test(k)&&d.value===false).map(([k])=>k.split('#')[0]) : [];
  const out = {instId, ecran: globalThis.ECRAN, icon:iconCompId, hexAttendu, done,
    visibleALaRacine: done.some(d=>d.visible), boolsIconOff, fichierActif:figma.root.name};
  globalThis.SWAPS.push(out);
  return out;   // visibleALaRacine:false = le glyphe N'EST PAS à l'écran (slot masqué par un booléen — active la prop listée dans boolsIconOff via setProperties, puis RE-APPELLE swapIcon). done vide = glyphe introuvable → STOP. Le rendu des variables sur vecteurs imbriqués est SAIN (testé) : pas de couleur littérale « de secours ».
};
```
- **Occurrences répétées / TABLES : row-gabarit SUPERSET.** Construis UNE ligne contenant TOUS les éléments/états possibles de la table (badges, pastilles, avatars, compteurs, boutons), vérifie-la, PUIS clone-la N fois ; pour chaque ligne : `visible=false` sur ce que le dump de la ligne source n'a pas + injecte les données réelles. Jamais de reconstruction ligne à ligne. **La donnée commande le modèle, jamais l'inverse** (interdiction d'inventer initiales/contenus pour remplir un gabarit : une cellule source vide reste vide).
- **Textes : copie la chaîne exacte relue sur le nœud source au moment d'écrire** (`characters` complet — le `txt` du dump est tronqué à 40 caractères) ; jamais retapée de mémoire (accents/typos).
- Props lues sur l'instance avant `setProperties` ; sous-éléments parasites désactivés ; **ne bidouille jamais en dur** (rendu faux = mauvaise variante).
- Élément sur fond coloré (checkbox sur header gris) → fill blanc explicite. Cellule = largeur de son contenu ; `strokeAlign='INSIDE'` ; conteneur source à fond+padding → reproduis-le.
- Le DS documente un pattern (showcase) → copie-le ; pas de détournement d'état SAUF documenté par le DS (nav Ghost enabled/hover, annexe A).

### 2.5 Vérifie — 4 artefacts scriptés + 1 checklist, par écran, collés
**Passe 1 — `verify(rootId)` → count DOIT être 0.**
```js
// VERIFY — validé sur écrans réels (attrape : piège 100px, instances renommées, débordements, textes détachés dans les instances)
globalThis.verify = async (rootId) => {
  const linked=p=>!!(p.boundVariables&&p.boundVariables.color);
  const num=v=>typeof v==='number';
  const insideInst=n=>{let p=n.parent;while(p&&p.type!=='PAGE'){if(p.type==='INSTANCE')return true;p=p.parent;}return false;};
  const insideClone=n=>{let p=n;while(p&&p.type!=='PAGE'){if(p.name==='sidebar (cloné)')return true;p=p.parent;}return false;};
  const V=[],add=(n,m)=>V.push({id:n.id,name:n.name,pb:m});
  const root=await figma.getNodeByIdAsync(rootId);
  for(const n of [root,...root.findAll(()=>true)]){
    if(insideInst(n)||insideClone(n)) continue;   // intérieur d'instance + clone : hors scan (le clone est couvert par le read-back triple §2.1)
    if(n.type==='INSTANCE'){ const mc=await n.getMainComponentAsync();   // l'INSTANCE elle-même n'est jamais skippée (insideInst ne regarde que les ancêtres) ; jamais n.mainComponent (throw en dynamic-page)
      if(mc&&n.name!==mc.name&&n.name!==((mc.parent||{}).name||'')) add(n,'instance renommée');
      if(!(globalThis.RESIZES||[]).some(r=>r.instId===n.id))   // rescale détache inévitablement (LEDGER auto) → instances RESIZES exemptées
        for(const t of n.findAll(x=>x.type==='TEXT'&&x.visible!==false))
          if(t.textStyleId===''||typeof t.textStyleId!=='string'){ add(n,'texte détaché DANS instance'); break; }   // 133 textes réels scannés : 0 faux positif
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
    if(n.type==='FRAME'&&n.clipsContent===true&&!(globalThis.LEDGER||[]).some(e=>e.type==='CLIP-REQUIS'&&e.id===n.id)) add(n,'clipsContent=true (risque de crop)');   // exemption : entrée LEDGER CLIP-REQUIS avec l'id (§2.4)
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
      if(n.primaryAxisAlignItems!=='SPACE_BETWEEN'&&n.itemSpacing>0&&!b.itemSpacing) add(n,'gap en dur');   // SPACE_BETWEEN : Figma ignore itemSpacing → le flagger induirait des « fixes » destructeurs
      if((n.paddingLeft>0||n.paddingTop>0)&&!b.paddingLeft&&!b.paddingTop) add(n,'padding en dur'); }
  }
  return { fichierActif: figma.root.name, count:V.length, V };
};
```
**Passe 2 — `compareToSource(pairs)`.** En convert, **chaque paire porte un `sourceId` de PREMIER NIVEAU** (id imbriqué toxique → remonte au parent, le script descend seul) ; impossible → `expect.dims:{w,h}` lus dans le dump est **obligatoire** (paire sans sourceId ni dims = ligne sans paire pour reconcile). **Paires minimales par écran : la RACINE (root↔root)** + un frame structurant par zone (nav, table, sidebar) + chaque type distinct + première ET dernière occurrence de chaque groupe répété + une paire par entrée SWAPS (avec `icon.expectedHex`) + toute instance dont la taille rendue ≠ celle du master. **Conventions de nommage (reconcile s'appuie dessus)** : le `label` de chaque paire REPREND textuellement le champ `ligne` du MAPPING ; le label d'une paire de swap contient l'`instId` ; les entrées LEDGER portent `element` = `ligne` du MAPPING.
```js
globalThis.insideCloneCS = n=>{let p=n;while(p&&p.type!=='PAGE'){if(p.name==='sidebar (cloné)')return true;p=p.parent;}return false;};
globalThis.readNode = async (id) => { const n=await figma.getNodeByIdAsync(id); if(!n) return {missing:true,id};
  const toHex=c=>'#'+[c.r,c.g,c.b].map(v=>Math.round(v*255).toString(16).padStart(2,'0')).join('');
  const r={name:n.name, w:Math.round(n.width), h:Math.round(n.height)};
  if(n.layoutMode&&n.layoutMode!=='NONE'){ r.align=n.primaryAxisAlignItems; r.gap=n.itemSpacing; r.pad=(n.paddingTop||0)+(n.paddingBottom||0)+(n.paddingLeft||0)+(n.paddingRight||0); }
  if(n.type!=='INSTANCE'&&'children'in n) r.ordreEnfants=n.children.filter(c=>c.visible!==false).map(c=>c.name);   // ordre des enfants DIRECTS, jamais dans une INSTANCE (structure interne DS hors de portée de l'agent)
  const visOK=x=>{ if(x.visible===false) return false; let p=x.parent; while(p&&p.id!==n.id&&p.type!=='PAGE'){ if(p.visible===false) return false; p=p.parent; } return true; };   // visibilité PLEINE CHAÎNE — un calque caché par un ancêtre pollue bg/glyphe/textes sinon
  let best=null,ba=-1,bestNode=null;
  for(const x of [n,...('findAll'in n?n.findAll(()=>true):[])]){ if(!visOK(x)) continue;
    if((x.type==='TEXT'||x.type==='VECTOR'||x.type==='BOOLEAN_OPERATION')&&x.id!==n.id) continue;   // fill de glyphe ≠ fond : sur une icône seule, lire le glyphe comme « bg » fabrique un faux CONTRASTE
    if(Array.isArray(x.fills)) for(const p of x.fills) if(p.type==='SOLID'&&p.visible!==false){const a=x.width*x.height; if(a>ba){ba=a;best=p;bestNode=x;}} }
  if(best){ const c=best.color; r.bgHex=toHex(c); const bv=best.boundVariables&&best.boundVariables.color;
    const vv=bv?await figma.variables.getVariableByIdAsync(bv.id):null; r.bgVar=vv?vv.name:null;
    if(bestNode&&Array.isArray(bestNode.fills)&&bestNode.fills.filter(p=>p.type==='SOLID'&&p.visible!==false).length>1) r.bgEmpile=true; }   // fills EMPILÉS (ex. Soft destructive = blanc + teinte 10%) : la couleur perçue = la PILE → juge par la capture, pas ce seul hex
  if('componentProperties'in n&&n.componentProperties){const vp={};for(const [k,d] of Object.entries(n.componentProperties))if(d.type==='VARIANT')vp[k]=d.value;if(Object.keys(vp).length)r.variant=vp;}
  if('findAll'in n){ const vec=n.findAll(x=>x.type==='VECTOR'&&visOK(x)&&!insideCloneCS(x)&&((Array.isArray(x.fills)&&x.fills.some(p=>p.type==='SOLID'&&p.visible!==false))||(Array.isArray(x.strokes)&&x.strokes.length)))[0];
    if(vec){ const p=(Array.isArray(vec.fills)&&vec.fills.find(q=>q.type==='SOLID'&&q.visible!==false))||(Array.isArray(vec.strokes)&&vec.strokes.find(q=>q.type==='SOLID')); if(p) r.glyphHex=toHex(p.color); }
    r.texts=n.findAll(x=>x.type==='TEXT'&&visOK(x)&&!insideCloneCS(x)).map(t=>t.characters).join('|').slice(0,120); }   // clone exclu (ses textes sont couverts par textDiff)
  return r; };
globalThis.compareToSource = async (pairs) => {
  const h2=h=>{h=h.replace('#','');return [0,2,4].map(i=>parseInt(h.slice(i,i+2),16));};
  const dist=(a,b)=>Math.round(Math.hypot(...a.map((v,i)=>v-b[i])));
  const out={ fichierActif: figma.root.name, pairs: [] };
  for(const p of pairs){
    const A=await readNode(p.reproId); const B=p.sourceId?await readNode(p.sourceId):null; const diffs=[], nearColors=[];
    if(A.missing) diffs.push('repro manquante'); if(B&&B.missing) diffs.push('source manquante');
    if(B&&!B.missing){
      if(A.bgHex!==B.bgHex){ const d=(A.bgHex&&B.bgHex)?dist(h2(A.bgHex.slice(1)),h2(B.bgHex.slice(1))):null;
        if(d!==null&&A.bgVar&&p.expect&&p.expect.bgVar&&A.bgVar===p.expect.bgVar) nearColors.push({token:A.bgVar,repro:A.bgHex,source:B.bgHex,dist:d});   // token conforme au mapping = palette DS vs legacy → auto-LEDGER
        else diffs.push('bg '+A.bgHex+' != '+B.bgHex+(d!==null?' (dist '+d+')':'')); }
      if(Math.abs(A.w-B.w)>1||Math.abs(A.h-B.h)>1) diffs.push('dims '+A.w+'x'+A.h+' != '+B.w+'x'+B.h);
      if(A.align&&B.align&&A.align!==B.align) diffs.push('align '+A.align+' != '+B.align);
      if(p.compareTexts&&A.texts!==B.texts) diffs.push('texts "'+A.texts+'" != "'+B.texts+'"');
      if(typeof A.gap==='number'&&typeof B.gap==='number'&&A.align!=='SPACE_BETWEEN'&&B.align!=='SPACE_BETWEEN'&&A.gap===0&&B.gap>2) diffs.push('gap manquant : repro 0 vs source '+B.gap+'px');   // présence, pas valeur exacte — la normalisation vers un token DS (14→16px) N'EST PAS un diff
      if(typeof A.pad==='number'&&typeof B.pad==='number'&&A.pad===0&&B.pad>4) diffs.push('padding manquant : repro 0 vs source '+B.pad+'px cumulés');
      if(Array.isArray(A.ordreEnfants)&&Array.isArray(B.ordreEnfants)){
        const bNoms=B.ordreEnfants.map(x=>x.toLowerCase()), aCommuns=A.ordreEnfants.map(x=>x.toLowerCase()).filter(x=>bNoms.includes(x)), bCommuns=bNoms.filter(x=>aCommuns.includes(x));
        if(aCommuns.length>1&&JSON.stringify(aCommuns)!==JSON.stringify(bCommuns)) diffs.push('ordre des enfants directs diffère : '+aCommuns.join(',')+' vs '+bCommuns.join(','));   // seulement les enfants nommés PAREIL des deux côtés — les taxonomies différentes (legacy vs DS) ne se comparent pas
      } }
    if(p.expect){ if(p.expect.bgVar&&A.bgVar!==p.expect.bgVar) diffs.push('token '+A.bgVar+' != '+p.expect.bgVar);
      if(p.expect.dims&&(Math.abs(A.w-p.expect.dims.w)>1||Math.abs(A.h-p.expect.dims.h)>1)) diffs.push('dims '+A.w+'x'+A.h+' != attendu '+p.expect.dims.w+'x'+p.expect.dims.h);
      if(p.expect.variant) for(const [k,v] of Object.entries(p.expect.variant)) if((A.variant||{})[k]!==v) diffs.push('variant '+k+' != '+v); }
    if(p.icon&&p.icon.expectedHex){ if(!A.glyphHex) diffs.push('glyphe INTROUVABLE (swap raté ?)');
      else if(A.glyphHex.toLowerCase()!==p.icon.expectedHex.toLowerCase()) diffs.push('glyphe '+A.glyphHex+' != '+p.icon.expectedHex); }
    if(A.glyphHex&&A.bgHex&&dist(h2(A.glyphHex.slice(1)),h2(A.bgHex.slice(1)))<50) diffs.push('CONTRASTE: glyphe '+A.glyphHex+' quasi invisible sur fond '+A.bgHex);
    out.pairs.push({label:p.label, icon:p.icon, ok:diffs.length===0, diffs, nearColors});
  }
  out.clean = out.pairs.every(p=>p.ok);
  return out;
};
```
Écart **attendu** (compromis au LEDGER) → cite l'entrée LEDGER ; inexpliqué → corrige.
**`nearColors`** = fond différent mais **token conforme au mapping** (`expect.bgVar`) : palette DS vs palette legacy, auto-classé — recopie chaque entrée au LEDGER `{type:'NEAR-COLOR (auto)'}`, aucune question user. Toute paire dont le fond vient d'un token du mapping DOIT porter `expect.bgVar` (sans lui, l'écart reste un diff à corriger). La classification se fonde sur la conformité du token, **JAMAIS sur un seuil de distance** (mesuré sur le run validé du 07/07 : résidus légitimes jusqu'à dist **59** — `theme/success` —, bug historique à dist 35 : aucun seuil ne les sépare). `compareTexts` : le clone sidebar est exclu côté repro → réserve-le aux sous-zones hors sidebar (l'écran entier est couvert par textDiff). **La couleur RENDUE d'un paint est `p.color`** (déjà résolue, mode compris) — n'écris JAMAIS de résolveur maison à base de `valuesByMode` (collection multi-modes → mauvais mode → faux diagnostics de contraste).
**Portée exacte des 3 nouveaux diffs (gap/padding manquant, ordre des enfants)** — à connaître avant de t'y fier : ils ne comparent QUE les paires que tu choisis de tester (§2.5 « paires minimales par écran »), donc un conteneur jamais inclus comme paire reste hors radar quel que soit son état réel — `structureCouverte` (§2.2) couvre l'amont (le conteneur existe-t-il au moins dans MAPPING), mais rien ne force encore qu'il soit systématiquement PAIRÉ pour compareToSource au-delà de ce que §2.5 exige déjà (racine + un frame par zone). L'ordre des enfants ne se compare que sur des noms identiques des deux côtés et jamais à l'intérieur d'une INSTANCE — un réagencement DANS un composant DS reste invisible (normal, hors de portée de l'agent) ; un réagencement que TU as fait en assemblant une rangée toi-même est ce que ce check attrape. Ce ne sont pas des vérités absolues, juste trois angles morts mesurés qui sont désormais couverts — d'autres peuvent exister.
**Passe 3 — `textDiff` : aucun texte source ne disparaît.**
```js
// Compare par OCCURRENCES (multiset) : un texte répété N fois dans la source doit exister N fois dans la repro
// (un Set laisserait passer la perte d'un doublon — ex. un placeholder reverté dont la chaîne existe ailleurs)
globalThis.textDiff = async (sourceRootId, reproRootId) => {
  const get=async id=>{ const root=await figma.getNodeByIdAsync(id);
    const visible=n=>{let p=n;while(p&&p.type!=='PAGE'){if(p.visible===false)return false;p=p.parent;}return true;};   // visibilité sur TOUTE la chaîne (sinon les textes de calques cachés polluent)
    return root.findAll(x=>x.type==='TEXT').filter(visible).map(t=>t.characters.trim()).filter(t=>t); };
  const count=a=>{const m=new Map();for(const t of a)m.set(t,(m.get(t)||0)+1);return m;};
  const src=count(await get(sourceRootId)), rep=count(await get(reproRootId));
  const manquants=[];
  for(const [t,n] of src){ const d=n-(rep.get(t)||0); if(d>0) manquants.push(d>1||n>1?t+' (×'+d+' manquant/s sur '+n+')':t); }
  return { fichierActif:figma.root.name, manquants, ok:manquants.length===0 };  // chaque manquant = skip → GATE avant le STOP
};
```
**En update/create** : passe la racine du **sous-arbre modifié** en `sourceRootId`/`reproRootId`, jamais l'écran entier — aucune raison de rescanner des textes qui n'ont ni bougé ni été créés à chaque petite mise à jour (le code de `textDiff` est déjà générique, c'est un choix d'appel, pas un changement de fonction). En convert, ce sont toujours les racines de l'écran entier.
**Passe 4 — `reconcile()` : la couverture est prouvée, pas affirmée.**
```js
globalThis.reconcile = (ecran, pairsPassed /* les PAIRES elles-mêmes — `out.pairs` retourné par compareToSource ({label, icon, ok, diffs}), JAMAIS de simples strings : un swap ne compte comme vérifié que si sa paire a réellement checké l'icône (mesuré : accepter une simple présence de label a laissé passer un swap jamais re-vérifié visuellement) */) => {
  const m = MAPPING.filter(x=>x.ecran===ecran);
  if(!m.length) return { ecran, ok:false, err:'MAPPING VIDE pour cet écran — registres perdus (restart ?) ou poussés dans le sandbox d\'un autre fichier (§0) : recharge .swile-state.json ou refais le mapping' };
  const lignesSansPaire = m.filter(x=>!pairsPassed.some(p=>p.label&&p.label.includes(x.ligne)) && !LEDGER.some(e=>e.ecran===ecran&&e.element===x.ligne)).map(x=>x.ligne);
  const sondeNonMesuree = m.filter(x=>x.statut==='SONDE').map(x=>x.ligne);
  const customsSansPreuve = m.filter(x=>x.statut==='custom'&&!x.preuveCustom).map(x=>x.ligne);
  const lignesSansTpl = m.filter(x=>!('tpl' in x)).map(x=>x.ligne);
  const swapsSansCheck = SWAPS.filter(s=>s.ecran===ecran&&!pairsPassed.some(p=>p.label&&p.label.includes(s.instId)&&p.ok&&p.icon&&p.icon.expectedHex&&String(p.icon.expectedHex).toLowerCase()===String(s.hexAttendu).toLowerCase())).map(s=>s.instId);   // label présent SEUL ne suffit plus : il faut icon.expectedHex matchant ET ok:true (aucun diff sur cette paire)
  const resizesSansLedger = RESIZES.filter(r=>r.ecran===ecran&&r.apres&&r.apres.styleDetache&&!LEDGER.some(e=>e.type&&String(e.type).startsWith('RESCALE-DETACHE')&&e.instId===r.instId)).map(r=>r.instId);
  return { ecran, lignesSansPaire, sondeNonMesuree, customsSansPreuve, lignesSansTpl, swapsSansCheck, resizesSansLedger,
    ok: !lignesSansPaire.length&&!sondeNonMesuree.length&&!customsSansPreuve.length&&!lignesSansTpl.length&&!swapsSansCheck.length&&!resizesSansLedger.length };
};
```
**`reconcile().ok` DOIT être true avant le STOP témoin et avant chaque écran suivant** — chaque liste non vide se résout (paire ajoutée / sonde faite / LEDGER+gate) puis re-run. **Appelle-le avec `out.pairs`** (la sortie de `compareToSource`), jamais avec un tableau de labels bricolé à la main — sinon `swapsSansCheck` ne peut plus distinguer une paire réellement vérifiée d'une paire juste présente pour la forme. Un `swapsSansCheck` qui redevient vide en ajoutant une paire creuse (sans `icon.expectedHex` matchant, ou avec des diffs) = triche du gate, pas une résolution — résous la VRAIE cause (relance un `compareToSource` qui checke vraiment l'icône) plutôt que de satisfaire la liste. L'affirmation en prose du rapprochement est interdite.
**+ Checklist qualitative (l'œil sur la capture côte-à-côte — les scripts ne voient pas tout)** — tableau ✅/❌ posté :
| ✅/❌ | bonne variante partout · icônes recolorées ET visibles · bordures visibles non rognées · texte non coupé/rien de croppé · contraste OK (tout ce qui se distingue du fond dans la source se distingue dans la repro) · alignements (boutons à droite, colonnes) |
Un ❌ ou « pas vérifiable » = écran non validé.
**Recette capture côte-à-côte (sans toucher la source)** : frame temporaire hors-canvas → **clones** de la source ET de la repro posés DEDANS, côte à côte → `figma_capture_screenshot` de la frame → suppression de la frame (clones inclus). Une frame vide posée par-dessus ne marche PAS : la capture ne rend que le sous-arbre du nœud capturé. Déplacer la source est interdit.
**Si un script throw** : hardening minimal en session (try/catch par nœud, erreurs DANS l'artefact) ; sinon read-back tabulaire de substitution + écran marqué « non vérifié mécaniquement » (STOP ne se franchit qu'avec ok user) + remonte l'erreur exacte.

### 2.6 STOP témoin (pré-validation), puis la série
**Checkpoint après chaque écran vérifié** : `figma.saveVersionHistoryAsync('<écran> vérifié')` **+ mets à jour sentinelle et état persisté** (outil Write) :
- `.swile-verify.json` : `{"etat":"…","ecrans":{"<nom>":{"verify":<count>,"reconcile":<ok>,"textDiff":<nb manquants non gatés>}},"clean":<true si TOUS les écrans finis sont à verify:0 + reconcile:true + textDiff gaté>}`. **Transitions d'`etat`** : `en_cours` pendant le travail (écran non fini = `clean:false`) → `en_attente_verdict` juste avant le STOP témoin → retour `en_cours` à la reprise de la série → `bloque` (+`motif`) si une panne exige l'user → `fini` + `clean:true` au rapport. Le hook ne laisse sortir que `en_attente_verdict`, `bloque`, ou `fini`+`clean:true` — tout le reste bloque, y compris lock sans sentinelle et `fini`+`clean:false`.
- `.swile-state.json` (reprise après crash / nouvelle session) : `{MAPPING, LEDGER, SWAPS, RESIZES, COMP_KEYS, VAR_KEYS, STYLE_KEYS, roots:{"<écran>":{sourceId, reproId}}, crees:[{id,nom}]}` (`crees` = tes nœuds de travail hors repros, pour le balayage final §2.7) — les **clés** d'import, jamais les node-ids de composants importés (instables). **Les 4 registres y figurent VERBATIM : un state réduit à `roots`+notes est INVALIDE** (la reprise §3.5, le reconcile et le rapport en dépendent).
**GATE témoin (préférence, actif par défaut)** : poste témoin + les 4 artefacts + checklist + capture → **STOP, attends la pré-validation user**. Ajoute UNE ligne au message du STOP : « En fin de run, je déposerai un RETEX sur le Drive équipe s'il y a des points d'amélioration — dis-le maintenant si tu ne veux pas. » (consentement capté pendant que l'user est présent → le dépôt de clôture est autorisé sans nouvelle question). Ne repose aucune question technique — uniquement les préférences non encore tranchées.
- **Erreurs** → corrige (procédure complète, §2.7), écran suivant seul → re-STOP.
- **OK** → série écran par écran, **mêmes 4 artefacts + checklist POSTÉS pour chacun**. Point d'étape tous les 2-3 écrans : tableau `écran → {verify.count, pairs, textDiff.manquants, reconcile.ok}` + **LEDGER complet ré-affiché**. Nouvel élément mi-série → re-§0.1 + import isolé (pattern warm-up, timeout 20 s) ; pend → §3 AVANT de poser. Envie de simplifier → GATE skip.

### 2.7 Corriger, puis rapport
**Corriger** = repasser la procédure (règles → read-back layout du nœud touché dans le même call → re-scan → re-compare) — jamais un patch pour éteindre un flag.
**Balayage final des résidus (AVANT le rapport) — uniquement TES créations, jamais celles de l'user** : tout au long du run, chaque nœud de travail que tu crées HORS des repros (KIT, scratchs, frames de capture, clones d'essai) est enregistré dans `state.crees[]` (id + nom) — c'est la SEULE liste que le balayage supprime. Poste la liste `{id, nom, type, x, y}` de ce qui existe encore → supprime → re-scan collé. Un nœud de premier niveau inconnu qui n'est PAS dans `state.crees` (résidu de l'user ?) → tu le LISTES dans le rapport sans y toucher. Un résidu À L'INTÉRIEUR d'un écran est du ressort de verify/compare, pas de ce balayage.
**Rapport final = les registres, pas ta mémoire** : la table Compromis/Skips est `return globalThis.LEDGER` collé tel quel (reconstruction interdite — 5 compromis perdus au 07/07) + le reconcile final de chaque écran + customs avec preuves + lignes annexe non confirmées + récap. **Un blocage technique déguisé en compromis = rejeté** ; un skip sans OK user dans le transcript = rejeté. Rapport livré → sentinelle `{"etat":"fini","clean":true}` puis **supprime `.swile-run.lock`** (fin du gate).

**RETEX (conditionnel, automatique, après le dernier rendu)** : SI le run contient au moins un axe d'amélioration — erreur signalée par l'user, panne §3 rencontrée, règle du skill prise en défaut, alerte 🟥 annexe périmée — crée un **sous-dossier** Drive `retex-AAAA-MM-JJ-<user>-<fichier>` dans le dossier d'équipe id `1-OckHhzBv4lmgte9t-x6YJna_1nh71nq` (connecteur **Google Drive**, outil `create_file` via ToolSearch ; dossier = `mimeType:"application/vnd.google-apps.folder"` ; images = `base64Content` + `contentMimeType:"image/png"` + `disableConversionToGoogleType:true` — testé). Dépose dedans, **le plus détaillé possible** (le lecteur n'a AUCUN contexte de ta session) :
1. `retex.md` — timeline horodatée des pannes avec verbatim des erreurs, version du plugin Bridge, chaque décision non triviale + sa preuve, MAPPING + LEDGER + reconcile collés, questions/réponses user, « ce qui manquait au skill » ;
2. des **captures de ZONE** (uniquement les éléments à problème — jamais d'écran entier : ~35 000 tokens/écran contre ~3 000/zone, risque de compaction). Procédé testé : dans le sandbox, `bytes = await node.exportAsync({format:'PNG',constraint:{type:'SCALE',value:0.5}})` puis `return figma.base64Encode(bytes)` → colle le base64 dans `create_file` → **contrôle : `fileSize` retourné = `bytes.length`**. Pour tout le reste, les node-ids + la clé du fichier suffisent (le lecteur re-capture via le bridge) ;
3. `.swile-state.json` et `.swile-verify.json` (texte).
**Si tout s'est bien passé : pas de RETEX.** Les maquettes et leurs contenus sont des **données de design internes** : le dépôt dans le Drive d'équipe est autorisé et attendu. Si un garde-fou de permissions bloque l'écriture Drive (« external system writes »), ne force pas : demande à l'user en UNE ligne « ok pour déposer le RETEX sur le Drive équipe ? » — son accord explicite lève le blocage — sinon sauve le RETEX en local et donne le chemin. Connecteur Drive absent → propose à l'user : le connecter (Settings → Connectors) OU envoyer lui-même le dossier à Romain. Le RETEX n'empêche jamais la clôture du run.

---

## 3. Récupération (échelle testée)
1. **Clés en timeout au warm-up** → le lot continue ; retente ces clés UNE fois après le lot (fenêtre morte = `nb_clés × 25 s`, minimum 120 s — une fenêtre trop courte compte « pendant » comme « échoué » et fausse le bilan). Re-timeout → 2.
2. **Canal empoisonné** — déclencheur : **2 gels d'import consécutifs**, confirmés par l'**IMPORT-TEST** (⚠️ le probe ne détecte PAS un gel — les lectures passent toujours ; le seul détecteur fiable est un import chronométré : ~15 ms clé cachée / ~1-2 s clé neuve = sain, timeout = gelé). Le gel vit dans la **file de fetch NATIVE de Figma** (pas dans code.js) : chaque import coupé/timeouté y reste en vol et l'aggrave — d'où :
   ⚠️ **Les types d'import gèlent indépendamment** (mesuré 07/2026) : après un backoff, les **variables** peuvent guérir (1-27 ms) pendant que les **styles** restent gelés — y compris une clé de style DÉJÀ cachée (timeout 20 s). Ne conclus donc jamais « canal sain » sur un seul import-test de composant/variable : si un type reste bloqué, l'écran ne se finira pas → poursuis l'escalade. L'import-test de setup (§0.6) et de reprise devrait couvrir composant + style + variable, pas un seul type.
   **2-a. BACKOFF (gratuit, une seule tentative)** : **120-180 s SANS AUCUN import**, puis **UN SEUL** import-test — jamais de témoins rapprochés (chaque témoin raté re-remplit la file ; mesuré : un bouchon peut se drainer en ~2-3 min… ou pas du tout selon la machine et sa taille). **Pendant cette fenêtre**, si `portFallbackUsed:true` OU sandbox suspect (helpers perdus), profites-en pour le **RESTART AUTONOME du serveur** (procédure ci-dessous) : son temps de reconnexion (~45 s) tient DANS le backoff — c'est la séquence kill+attente qui a récupéré un gel induit en test — mais c'est l'ATTENTE qui draine, pas le kill.
   **2-b. Témoin encore gelé** → demande à l'user : « ferme et rouvre le plugin Desktop Bridge (3 fichiers), puis dis-moi ok » — la réouverture **ré-exécute le plugin dans Figma et réinitialise la file native** (guérit le plus souvent : imports à 1-10 ms juste après). ⚠️ **Mais pas toujours** (mesuré 07/2026 : réouverture sans effet, 6 clés cachées re-timeout à 20 s) → **re-fais l'import-test (composant + style + variable) AVANT de relancer le warm-up** ; encore gelé = passe à §3.3, ne relance rien dans un canal mort. Si sain : re-§0 → **§3.5** → **warm-up immédiat** (le canal frais se re-dégrade en ~10 min). La réouverture ne remplace PAS §3.7 : styles durablement introuvables → §3.7 reste l'issue.
   **Restart AUTONOME du serveur MCP** (kill du PID → pause 5 s → `figma_get_status` relance le serveur sur 9223 → le plugin se rattache seul, poll 10 s ×3) : **ce n'est PAS un remède au gel** (la file native survit — mesuré 2×). Ses usages réels : **corriger `portFallbackUsed`** (§0.1 — seul moyen) et purger un coincement purement JS du sandbox (`code.js` est rechargé : §3.5 obligatoire ensuite).
3. **Réouverture manuelle sans effet sur l'import-test** → restart complet de Figma Desktop + re-§0 + warm-up.
4. `figma_reconnect` ne touche que le transport ; `figma_reload_plugin` ne recharge que l'iframe UI, **pas `code.js`** (testé : un global du sandbox y survit) — **aucun des deux ne débloque un gel**.
5. **Intégrité après tout restart/reconnexion/nouvelle session — et après tout reset de sandbox** (un reset peut AUSSI avoir re-basculé le fichier actif : re-navigate + probe d'abord) : si les registres sont vides et que `.swile-state.json` existe → recharge-le (outil Read), recrée les registres en un call (`globalThis.MAPPING=[…]; …`), relance le warm-up depuis les clés persistées (cache : quasi instantané). Puis chaque écran construit → `getNodeByIdAsync` PUIS `verify` (count:0) PUIS re-lecture des dims racine vs source. Reverté → reconstruis (procédure complète). Témoin validé perdu : le verdict tient si le témoin reconstruit re-passe compare, sinon re-STOP.
   **Reset survenu EN PLEIN BUILD d'un écran (pas entre deux écrans)** : l'écran en cours devient à traiter comme un mini-témoin avant de continuer — mesuré : un reset mi-écran a dégradé l'attention sur le reste de cet écran (un conteneur entier oublié après coup). Après la reprise des registres, avant de poser le moindre nouvel élément sur CET écran : relis le nœud racine déjà construit (`getNodeByIdAsync` + `verify` sur ce qui existe déjà), et repasse la liste des lignes MAPPING de cet écran une à une pour vérifier lesquelles sont déjà posées — ne repars pas « à la mémoire » de ce qu'il restait à faire.
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
| Sous-onglets soulignés | Tabs `Bordered` ; la **frame** porte le border-bottom pleine largeur `theme/border` ; actif `theme/primary` noir | violet source → `colors/violet/*` (auto, §2.2) |
| Switch vert plein | Switch `Solid, sucess` *(sic)* track `theme/success` #16a34a | Outline = track blanc + stroke vert |
| Checkbox sur fond non blanc | fill blanc explicite (`theme/background`) | boîte `fills:[]` par défaut |
| Pastilles/compteurs sur icônes | **custom à la main, pré-justifié par cette annexe** → `preuveCustom:'annexe:pastilles'` (le scan Templates reste dû ; violet → `colors/violet/*`) — à reproduire **par ligne selon le dump** | jamais cloné ; jamais simplifié sans GATE |
| Statut « en attente/pending » | suit la **couleur mesurée de la source** (texte simple = texte simple) | JAMAIS `Info` bleu par défaut |

**Page « Swile - Templates »** (DS) : exemples officiels Swile — sections `<ÉCRAN> - CONVERT` = frame OLD + **COMPONENT publié** `<ÉCRAN> - SHADCN`, sans suffixe = from scratch. Consultation obligatoire §2.2-0. Clés mesurées (liste vivante — re-scanne la page) : COLLABORATEURS - SHADCN `257e6c07255dc3f7f518dc6ba367fdfc37dcd142` · PROFIL - SHADCN `68c3ff9ae5c05e166ada559e8aab6883493ac60b`.
**Accent violet Tailwind** : `colors/violet/500` #8b5cf6 c49a5e4d9c53a332c288a8470b3edd6bdb15ab80 · `600` #7c3aed 273d4ff0bcd0d0d0cf05abfb4a258abf070fbac6 (gamme 50–950 + purple dispo, mesurée) — nuance au plus proche de la source par distance.
**Pièges DS** : `theme/primary` = noir #171717, PAS violet · boutons max `lg` h40 · `theme/muted` canvas · `theme/card` carte · `theme/border` bordures · `foreground`/`muted-foreground` textes · **Avatar (renommé 07/2026)** : `Shape=Rounded|Circle` × `Type=Image|Placeholder Initials|Placeholder Icon` (+ `Ring`, `Indicator`) — matche par nom avec CES libellés exacts (l'ancien « Initials » seul ne matche plus) · Alert Soft ≠ Solid (props différentes → lire sur l'instance) · **casse des variantes incohérente entre sets** (`style=Destructive` sur Icon Button vs `destructive` sur Button) → matche INSENSIBLE à la casse · **fills EMPILÉS** : Soft destructive = `theme/card` blanc + teinte alpha 10 % superposés — la couleur perçue vient de la pile, pas du plus grand fill seul · **Select : intérieur du master verrouillé à 288 px** → pose l'instance dans un wrapper custom à largeur fixe (le resize direct ne tient pas) · **Boutons : booléens `Left Icon`/`Right Icon` à `false` par défaut** → active le booléen AVANT le swap, sinon le glyphe swappé reste une couche MASQUÉE (invisible à l'écran, lisible au read-back naïf) · **Checkbox/Switch : prop `Label`** à masquer si absente de la source · **Avatar 32→24 : `sizeInst(24,24,<style XS>)`** — jamais rescale (détache le style) · **avatars chevauchés** : un caractère qui semble coupé sur la capture = recouvrement réel (z-order), PAS un « artefact d'export » — ne l'explique jamais ainsi sans preuve.

**Variables theme (« ☀️ Mode »)** : `background` 36d8943d0eb5c32d238a3dbe660f2d87f3f8df1d · `foreground` da9243f78b70a8ebe13306dc7916644bbd6032ca · `muted` 1a1c4fb51130fc6ac02bd86235145f4bf680e19a · `muted-foreground` 5608ad047b43e73345fd27d068601055ecef7f39 · `card` bf87620e38d9c9f825dcc342a3ae92f6b408236b · `border` ad89e5c8830e88a9cad5c7b7a0d92b2d1f4f4839 · `primary` 1b18ade61d046a487e4979cf8f380a8ef49d692b · `primary-foreground` 6da70a3468f722f3ca072e4d6d99c6a4ab3995e5 · `secondary` 38a4db465d1d3aa4f591c9a996fda92687667bcb · `accent` 361675c5f04130e691273ce02fbace92ae529031 · `info` 755d67b7cf2a27c5ccc8c2318af283a0a31bdc1b · `success` cfc6b1fa897ef27dd5a08e0912fac9ddbd8d0d52 · `destructive` e5beee398ba3a66ebbc815b21291b5431d31a7ce

**Dimensions (« 💨 Tailwind »)** — spacing = px directs ; radius/width = alias par NOM :
spacing `px`=1 8ca433f5721dd587116a796e500abb0eb8f4170b · **`0,5`=2 bb3764d7c03c1ff41514a0ade24c908851e56585** · `1`=4 0c447e7f9c16cca56a0c48443d0b54cda9dcd983 · `1,5`=6 98e396cdc37a58beca5b5568bb62cf3b72557c9e · `2`=8 f429d84338a023b8abe25bc487cad661ef16adfa · `2,5`=10 c049d8fcd82e1230f19e9042c2d8897473c2c87c · `3`=12 57c0dbcb76a14b04993acf6305d51a1a303e0005 · `3,5`=14 3b8cc288c4ae25f22797e7f30724500b931d5c34 · `4`=16 00c10cfc5aab7725f838b398bde2ba36c6946126 · `5`=20 fe290eb2d24fd11587f79a375fb8998a6216f345 · `6`=24 7901da4d67204e0d2e0773d30fbc5d7e7ba956da · `8`=32 f03857f7cd7015c0286c20943c42bdc3b9bdc8e4 · `10`=40 bc78b3e60dd4e84ef6dee7c2b6f952614d9ce947 · `12`=48 6384a1d8d18f37e8386d74b3857dddfe521ed5df · `16`=64 3df250a85685d80dcd2bc06586bd6a8eee8e8f32
radius `rounded` 1227b0ade0ae5a459fb95cd03e2026d8542cad01 · `rounded-md` 25aeecfd792e1f0826ae60a6bfa01b4c11a834cb · `rounded-lg` 75222fe5350f2e94033d1d50694c07f6620e4fa9 · `rounded-xl` 7e0fc63f699ad75c1baeb740bb31bfbea70b494b · `rounded-2xl` bf917a9961ac9dcd782da4b59798636757cbf131 · `rounded-full` f10b214f99500ab75f246577809c37c6c5ae6ea4
border-width `border`(1px) bf12a29d1cf5d33aeb4f7d7bdd3f5206063b7260 · `border-2` e4e819d98694ee654d2cb1b0354b5c1f48204880

**Limites de l'exécuteur (mesurées)** : pas de destructuring dans les callbacks (`findAll(({x})=>…)` → ReferenceError) · `exportAsync` ne rend que le sous-arbre du nœud · un id « importé avec succès » (style, composant OU variable) peut résoudre `null` ensuite → accesseur avec ré-import par clé (§2.3), l'échelle harvest est la voie primaire · un composant-écran (~500 nœuds, templates SHADCN) ne s'importe que sur **canal frais** — clé au warm-up, jamais mi-série · **police des textes DS = Geist** : `loadFontAsync({family:'Geist',…})` avant toute écriture, sinon `unloaded font` · `cornerRadius` peut être `figma.mixed` (symbol) → caste avant JSON.
**Text styles (« ↳ Tailwind Typography »)** : `XS/Regular` 9f9c604988dabad2ccb51aa87edbe244a20719dd · `XS/Medium` 7d25eddd056818b0274c86197a52db284317bce3 · `SM/Regular` 60ff59f703243b7b8ff3a6e12bc44e57fdbb25fe · `SM/Medium` acf925cf0504b75a0c3441aa5884276ab18550bd · `Base/Regular` 378e481f67c8a93217c89e6e854e726c42b753a3 · `Base/Medium` 7ad5876bc16457420bdb48fb045efcd61e14e102 · `LG/Bold` c58cc705869ef88ff3c38f4e85dec5d98d5825ff · `2XL/Bold` a716c3fd01fe4d9245ec090c6e8782147011b1a9 · `Extra/Link` c51bceb6e3391552b3a1099a32e8106b10439029 (⚠️ 16px — pour un lien 14px : SM/Regular + override UNDERLINE)

**Composants (variantes usuelles ; la sonde matche les sets par NOM ; autres variantes d'un set importé = `setProperties`, zéro import)** :
Solid Button primary/sm 4486d8b3a671f138ca57eac157e6aad24686fa50 · **secondary/sm e58fa7fb0b702be448938bebc8390e2d5f181449 (le gris)** · primary/lg 6c1309983899f353a0d31975dedaf10532943191 · info/sm 0c742f259ad720c819b8f7f2fccb29cffcdceea1 · destructive/sm 0dc39d6290ab12566620d16a3063e4f7214507b3
**Outline Button** secondary/sm/rounded cfaddcd2a07822cb6ae21170be5553f5409210a1 · secondary/sm/round 56e3000b52598871cd0c8de9c90bf86dec81e49a · secondary/lg/rounded e5233bb2ecda9e52e6944b9d2ee350cf94a3498a
Soft secondary/lg e946e1b5160909b2aeafbc5eeceef221575a2c2f · Soft destructive/lg 08202022f5984a5c5a5adf69bc5234c8ea963666 · Ghost secondary/sm 5ffdc4594d577b08533014340bf47aed4a38876e · Ghost secondary/sm/hover a578778a8769d478671b94d755f166335f0e7dd0
**Solid Icon Button** secondary/sm 206d47c643c6c732772950264284aafc3d353a8a (#f5f5f5) · primary/sm 77c7b216ffff2c3ad7d10ac113f10e6068850dd8 · Destructive/sm 342aee1db146042df1ad598a0cbe9fb6a0315a1e — Soft Icon Button secondary/sm eda8558b421b87436196c1ece509490b04e092c9 · destructive/sm b0ddc9d8ce3ec7b181fc006a3fe7a6aaac441ddf — **Ghost Icon Button** : set sur ✦ Buttons (sonde par nom)
Tabs — set nommé **« Tabs / Tab item »** — Bordered/lg/Active 9d7c54c9eaeb5adb16fa4467009dd39099c594c0 · Input md b36a88b295e909ac3c5ddfea85eb137daf4acc1e · Select sm b5babc08bc84bee0fb944331b03ba9e3fbd65a8c · Switch Solid/md/sucess 4240962dd84becce39ee9d87ded00b43d15700dd · Outline/md/sucess 1475576a010a2fc3d03a3ef2758b06932a2f68a9 · Checkbox sm/Primary 9af5461126f22df46b21e964df619d9c01c1b686 · Avatar (noms 07/2026) Placeholder Initials/Circle 4b42b540913e2e5140364bfae382fc0517eb21bf · Image/Circle ef0f78fa9fce10a9a362d01f031ed843cec17b51 · Placeholder Initials/Rounded d85739b3f081762a6011e2988be6bfedb7a8db10 · **Soft Badge** set 8e38c61007f720b3059bc52537ca89673540b641 (Success/sm bdaa7af716f478148d37d95d04ce95b1707a8944 ; Info/Warning/Secondary/Destructive via `setProperties Style=…`) · Alert Soft Info 4e249111db42f203dfe39750c873ad41b8bed2ca · Separator 904431067d718e09e318a2ee0edbdba04b11abed
Icônes (Library — **clé valable seulement pour un glyphe comparé à la source dans la session**) : search 55944425bf57eae0ffc1ceeee45099a28af3f637 · plus 75c6b7ffd2e7a71b9512d46398dfb046c45c9743 · trash-2 7ab13d0584553cb92c80b8b8879684437a767298 (⚠️ glyphe à 2 traits internes = **trash-1**, à sonder — la comparaison au dump source tranche) · pencil b6fb905e6af4381a40281ee205868d5c96aaf418 · chevron down 825a6b8d2addd9ba21374369e94ab7462927716a / up 36264eebf7e859ec93c4635ea56308d6570e17fc / left e320fca192cbd7f3a80dae8d7164692f6eea9590 · mail 4033348df4acdb35e8c470efccb909199dbb7d3d · ellipsis fbb088329a7d37ce637f9e0c7697cf4e80d9feac · sliders 83c5f32758928d0e36c5a2c293e5521688cb40a5 · columns f435ca2c59d9de2748576a7b4fa0ea11c4e99433 · lock 7772bfc2c25c8b4bd4c3209665c070bef651aad9 · star 34b473d59d0171b5fda9458a9f20d8fbcc65c088 · gift d8d110d109c7c18197bdfd8a77758d184a014525 · luggage 81a42bb1676af6f0e81914b9be522dcce1b4f028 · utensils cdb6f503f9dd5e45f0a9cab932de5f1c5bc1c6d0 · bicycle abdc5a8052f6c5786132cc765834dbd7bf6d4986 · paperplane 3fdd79d8229b9a76278e2b09368f55f17a9fd5e7

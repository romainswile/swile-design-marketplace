# swile-design

**Reproduction d'écrans Figma vers le design system « 🏢 Flõw | Corporate » (shadcn)** — plugin Claude Code/Desktop. Une fois installé, tout est automatique : le skill vérifie lui-même à chaque lancement qu'il est à jour et se met à niveau si besoin.

---

## 🚀 Installation (une fois, ~1 minute — aucun compte requis)

Selon votre version de Claude, le menu d'accès diffère :

**Vous avez la dernière version de Claude :**

> **Settings** → **Plugins** → **Add** → **Add marketplace** → collez le lien ci-dessous → **Sync** → cliquez sur le **« + »** à droite de la carte **Swile Design**

**Vous avez une version plus ancienne** *(le plus probable : mises à jour bloquées sur nos Mac)* :

> **Settings** → **Connectors** → **Customize** → le **« + »** à droite de **Personal plugins** (menu de gauche) → **Add** → **Add marketplace** → collez le lien ci-dessous → **Sync** → cliquez sur le **« + »** à droite de la carte **Swile Design**

Le lien à coller dans les deux cas :
```
https://github.com/romainswile/swile-design-marketplace
```

C'est tout : le pont Figma (MCP figma-console) est inclus et démarre tout seul, et le skill **ne tourne jamais sur une version périmée** — il vérifie sa version à chaque lancement, se met à niveau tout seul si besoin (il vous demande alors juste un `/reload-plugins` avant de reprendre) et active l'auto-update pour les fois suivantes.

---

## 🎨 Utilisation

**1.** Ouvrir Figma avec le plugin **Figma Desktop Bridge** lancé (Plugins → Development) dans les 3 fichiers : votre fichier de travail · le DS « 🏢 Flõw | Corporate » · la librairie « 🗂️ Flõw | Library »

**2.** Dans une **nouvelle session** Claude, choisir son mode :

| Commande | Usage |
|---|---|
| `/swile-design:shadcn convert` | Reproduire des écrans actuels vers shadcn |
| `/swile-design:shadcn update` | Étendre ou modifier des écrans shadcn existants |
| `/swile-design:shadcn create` | Créer de nouveaux écrans from scratch en partant directement de shadcn |

Exemple :
```
/swile-design:shadcn convert les écrans des sections "LISTE", "CONFIGURATION" et "FORM" du projet politique (page : parametres) sans le menu de gauche (copie/colle celui de la source)
```

💡 **Astuce** : mettez tous vos écrans dans le même run — la préparation se paie une seule fois.

**3.** En fin de session, si des points d'amélioration ou des erreurs ont été relevés, un rapport est déposé automatiquement dans le dossier Drive de l'équipe (connecteur Google Drive requis — si absent, le skill vous proposera de le connecter ou d'envoyer le rapport à Romain).

⚠️ Si le skill affiche une alerte **« SNAPSHOT/ANNEXE DS PÉRIMÉ »** : prévenez Romain.

---

<details>
<summary>🔧 Dépannage : installer sans les menus</summary>

CLI : `/plugin marketplace add romainswile/swile-design-marketplace` puis `/plugin install swile-design@swile-marketplace`

Si le pont Figma ne démarre pas (outils `figma_*` absents) : vérifier Node.js, ou l'ajouter manuellement : `claude mcp add figma-console -- npx -y figma-console-mcp@latest`. Un token Figma personnel (`FIGMA_ACCESS_TOKEN`) n'est nécessaire que pour des fonctions annexes — pas pour le skill.

Ou dans `~/.claude/settings.json` :
```json
{
  "extraKnownMarketplaces": {
    "swile-marketplace": { "source": { "source": "github", "repo": "romainswile/swile-design-marketplace" } }
  },
  "enabledPlugins": { "swile-design@swile-marketplace": true }
}
```
</details>

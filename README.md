# swile-design — reproduction d'écrans Figma vers le DS « 🏢 Flõw | Corporate »

Plugin Claude Code/Desktop. Une fois installé, tout est automatique — et le skill vérifie lui-même à chaque lancement qu'il est à jour.

## Installation (une fois, ~1 minute — aucun compte requis)

Dans Claude : **Settings → Plugins → Add marketplace** → coller :
```
https://github.com/romainswile/swile-design-marketplace
```
→ installer **swile-design**. C'est tout : le pont Figma (MCP figma-console) est inclus et démarre tout seul, et le skill se met à jour **automatiquement** (il vérifie sa version à chaque lancement, se met à niveau si besoin et active l'auto-update pour les fois suivantes — rien à faire).

## Utilisation

1. Ouvrir Figma avec le plugin **Figma Desktop Bridge** lancé (Plugins → Development) dans : votre fichier de travail + le DS « 🏢 Flõw | Corporate » + la librairie « 🗂️ Flõw | Library »
2. Dans une nouvelle session Claude, choisir son mode :

| Commande | Usage |
|---|---|
| `/swile-design:shadcn convert` | Reproduire des écrans actuels vers shadcn |
| `/swile-design:shadcn update` | Étendre ou modifier des écrans shadcn existants |
| `/swile-design:shadcn create` | Créer de nouveaux écrans from scratch en partant directement de shadcn |

Exemple :
```
/swile-design:shadcn convert les écrans des sections "LISTE", "CONFIGURATION" et "FORM" du projet politique (page : parametres) sans le menu de gauche (copie/colle celui de la source)
```
Astuce : mettez tous vos écrans dans le même run (la préparation se paie une seule fois).

3. En fin de session, si des points d'amélioration ou des erreurs ont été relevés, un rapport est déposé automatiquement dans le dossier Drive de l'équipe (connecteur Google Drive requis — si absent, le skill vous proposera de le connecter ou d'envoyer le rapport à Romain).

⚠️ Si le skill affiche une alerte **« SNAPSHOT/ANNEXE DS PÉRIMÉ »** : prévenez Romain.

---
<details>
<summary>Dépannage : installer sans le menu Plugins</summary>

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

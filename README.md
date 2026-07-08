# swile-design — reproduction d'écrans Figma vers le DS « 🏢 Flõw | Corporate »

Plugin Claude Code/Desktop. Une fois installé, tout est automatique — y compris les mises à jour.

## Installation (une fois, ~1 minute — aucun compte requis)

Dans Claude : **Settings → Plugins → Add marketplace** → coller :
```
https://github.com/romainswile/swile-design-marketplace
```
→ installer **swile-design**. C'est tout. Les mises à jour arrivent ensuite toutes seules.

## Utilisation

1. Ouvrir Figma avec le plugin **Desktop Bridge** lancé dans : votre fichier de travail + le DS « 🏢 Flõw | Corporate » + la librairie « 🗂️ Flõw | Library »
2. Dans une nouvelle session Claude :
```
/swile-design:shadcn convert les sections <...> du fichier "<votre fichier>"
```
Astuce : mettez tous vos écrans dans le même run (la préparation se paie une seule fois).

3. En fin de session, si des points d'amélioration ou des erreurs ont été relevés, un rapport est déposé automatiquement dans le dossier Drive de l'équipe (connecteur Google Drive requis — si absent, le skill vous proposera de le connecter ou d'envoyer le rapport à Romain).

⚠️ Si le skill affiche une alerte **« ANNEXE/SNAPSHOT DS PÉRIMÉ »** : prévenez Romain.

---
<details>
<summary>Dépannage : installer sans le menu Plugins</summary>

CLI : `/plugin marketplace add romainswile/swile-design-marketplace` puis `/plugin install swile-design@swile-marketplace`

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

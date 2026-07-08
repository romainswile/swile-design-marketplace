# Swile Figma Marketplace — plugin `swile-plugin`

Marketplace privé Claude Code contenant le plugin **swile-plugin** : reproduction d'écrans Figma avec le design system **« 🏢 Flõw | Corporate »** (shadcn), procédure verrouillée + vérifications scriptées + gate de fin de tour.

## Installation (une fois)

**Prérequis** : accès en lecture à ce repo (demander une invitation à Romain), et Git configuré avec votre compte GitHub.

### Option A — Interface Claude Desktop
Settings → Plugins → **Add marketplace** → coller l'URL de ce repo → installer **swile-plugin**.

### Option B — CLI Claude Code
```
/plugin marketplace add romainswile/swile-figma-marketplace
/plugin install swile-plugin@swile-marketplace
```

### Option C — settings.json (si ni A ni B)
Ajouter dans `~/.claude/settings.json` :
```json
{
  "extraKnownMarketplaces": {
    "swile-marketplace": { "source": { "source": "github", "repo": "romainswile/swile-figma-marketplace" } }
  },
  "enabledPlugins": { "swile-plugin@swile-marketplace": true }
}
```

## Utilisation

Dans une nouvelle session, avec Figma ouvert et le plugin **Desktop Bridge** lancé dans : votre fichier de travail + le DS « 🏢 Flõw | Corporate » + la librairie « 🗂️ Flõw | Library » :

```
/swile-plugin:swile-test-v3 convert les sections <...> du fichier "<votre fichier>"
```

Conseil : groupez tous vos écrans dans un même run (la préparation se paie une fois par run).

## Mises à jour

Automatiques : à chaque bump de version poussé ici, votre Claude récupère la nouvelle version au prochain démarrage. Rien à faire.

## Signaler un problème

Chaque run dépose automatiquement un RETEX (rapport + compromis + suggestions) dans le dossier Drive partagé de l'équipe. En cas de résultat incorrect : notez l'ID de session et l'URL du fichier Figma, et partagez-les à Romain.

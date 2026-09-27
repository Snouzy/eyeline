# Eyeline v1 — plan et suivi

> Pour un agent : exécuter tâche par tâche, cocher au fur et à mesure. Spec : `docs/specs/2026-09-27-eyeline-design.md` (à lire avant).

**But :** app iPhone de prompteur, colonne de texte collée à la zone cachée par l'Osmo Pocket 3, défilement à vitesse constante.

**Architecture :** SwiftUI pour les écrans, un `UITextView` (TextKit 1) piloté par `CADisplayLink` pour le défilement, un fichier `.txt` par script, réglages en `@AppStorage`. Logique pure dans `Layout` et `ScriptStore`, testée.

**Stack :** Swift 6, iOS 18+, Xcode 26.4, Swift Testing, XCUITest. Aucune dépendance.

**Code de référence :** tout le code de ce plan a déjà compilé sans warning et passé les tests (29 unitaires, 2 UI) dans un prototype jetable, sur iOS 18.3.1 et 26.4.1. Chaque tâche le recopie dans le dépôt, test d'abord.

## Contraintes globales

- iPhone seulement, iOS 18.0 minimum, paysage seulement.
- Swift 6, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES`, zéro warning (build système compris).
- Aucune dépendance, aucun accès réseau, aucune demande d'autorisation.
- Textes de l'interface en français ; code, commentaires, docs en anglais.
- Bundle `com.snouzy.eyeline`. Équipe de signature dans `Config/Local.xcconfig` (ignoré par git).
- Commandes :
  - tests : `xcodebuild -project Eyeline.xcodeproj -scheme Eyeline -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.4.1' test`
  - plancher iOS 18 : même commande avec `name=iPhone 16 Pro,OS=18.3.1`
- Chaque commit : `/ponytail-review`, puis un « oui » explicite de l'utilisateur. Jamais de push sur `main`.

## Points à surveiller en revue

1. Script très long (5 000 mots et plus) : l'ouverture du prompteur ne gèle pas plus d'une demi-seconde et le défilement reste fluide. À vérifier sur l'iPhone (`ensureLayout` fait toute la mise en page).
2. Mot plus large que la colonne (URL, mot composé) : il passe à la ligne sans sortir de la colonne. Couvert par le défaut de 220 pt ; à vérifier à 80 pt de texte.
3. App passée en arrière-plan pendant le défilement : elle se met en pause, le texte ne saute pas au retour. `scenePhase` dans `PrompterView` ; à vérifier à la main.
4. Réglages hors limites venant d'un autre écran ou d'une ancienne version : bande, colonne et ligne restent à l'écran. Couvert par `BandTests` et `ColumnTests` (valeurs bornées à la lecture).
5. App tuée avec un script vide ouvert : le script vide disparaît au lancement suivant. Couvert par `listDeletesEmptyScripts`.

## Tâche 1 — Squelette du dépôt

**Fichiers :** `.gitignore`, `LICENSE`, `Config/Base.xcconfig`, `Config/Local.xcconfig.example`, `Config/Info.plist`, `Eyeline.xcodeproj/project.pbxproj`, `Eyeline.xcodeproj/xcshareddata/xcschemes/Eyeline.xcscheme`, `Eyeline/EyelineApp.swift` (écran minimal), `CLAUDE.md`, `.claude/rules/swift.md`, `tasks/lessons.md`.

- [x] `git init`, branche `main`
- [x] Projet écrit à la main : trois cibles (`Eyeline`, `EyelineTests`, `EyelineUITests`), dossiers synchronisés, `developmentRegion = fr`
- [x] `Base.xcconfig` inclut `Local.xcconfig` s'il existe (`#include?`)
- [x] `Info.plist` : paysage gauche et droite, `CADisableMinimumFrameDurationOnPhone`, `UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace`
- [x] Build : `** BUILD SUCCEEDED **`, aucune ligne `warning:`
- [x] `CLAUDE.md`, `.claude/rules/swift.md`, `tasks/lessons.md` sur le modèle de `trace`

## Tâche 2 — Réglages et calculs purs (TDD)

**Fichiers :** `Eyeline/Settings.swift`, `Eyeline/Layout.swift`, `EyelineTests/LayoutTests.swift`.

**Interfaces produites :**
- `enum ColumnSide: String { case left, right }`, `enum BandEdge { case leading, trailing }`
- `enum Setting` : clés et défauts (`wordsPerMinute` 130, `fontSize` 34, `columnWidth` 220, `columnSide` .right, `bandCenter` 0.5, `bandWidth` 280, `readingLine` 0.5) et bornes
- `Layout.bandFrame(center:width:in:) -> CGRect`, `draggingEdge(_:of:by:in:) -> (center: Double, width: Double)`, `stripWidth(band:side:in:) -> Double`, `columnFrame(band:side:width:in:) -> CGRect`, `readingLineY(_:height:) -> Double`, `readingLine(atY:height:) -> Double`, `lineHeight(fontSize:) -> Double`, `offsetRange(textHeight:lineHeight:readingY:) -> ClosedRange<Double>`, `pointsPerSecond(wordsPerMinute:textHeight:wordCount:) -> Double`, `fadeStops(readingY:lineHeight:height:) -> [Double]`, `wordCount(_:) -> Int`, `title(_:) -> String?`, `duration(wordCount:wordsPerMinute:) -> Int`, `summary(wordCount:wordsPerMinute:) -> String`

- [x] Écrire `LayoutTests.swift` : bande centrée, bande dans l'écran, largeur bornée, glisser un bord garde l'autre, un bord ne croise pas l'autre, un bord s'arrête au bord de l'écran, colonne droite et gauche collées à la bande, colonne = toute la bande latérale si plus étroite, ligne de lecture bornée, vitesse (120 mots/min, 1 000 pt, 100 mots → 20 pt/s), vitesse nulle sans mots, plage de défilement (480, 48, 200 → -176...256), une ligne → plage d'un point, arrêts du fondu `[0.15, 0.35, 0.85, 1]`, comptage des mots, titre, durée arrondie (212 mots → 100 s), résumés « 1 mot · ≈ 0 s », « 87 mots · ≈ 40 s », « 390 mots · ≈ 3 min », « 325 mots · ≈ 2 min 30 s »
- [x] Lancer les tests : échec de compilation (`Layout` absent)
- [x] Écrire `Settings.swift` et `Layout.swift`
- [x] Lancer les tests : tous passent

## Tâche 3 — Stockage des scripts (TDD)

**Fichiers :** `Eyeline/ScriptStore.swift`, `EyelineTests/ScriptStoreTests.swift`.

**Interfaces produites :** `struct Script: Identifiable, Equatable { let id: String; var text: String; var modified: Date }` ; `@Observable final class ScriptStore` avec `init(folder:now:)`, `scripts`, `errorMessage`, `reload()`, `create(text:) -> Script?`, `save(id:text:)`, `delete(id:)`.

- [x] Écrire `ScriptStoreTests.swift` : nom de fichier = date (`2026-09-27 14.03.21.txt`), même seconde → « 2 », « 3 », ordre dernier modifié d'abord, enregistrer écrit et remonte le script, même texte → rien ne bouge, supprimer efface le fichier, fichiers illisibles et non `.txt` ignorés, scripts vides supprimés au chargement, dossier absent → message d'erreur
- [x] Lancer : échec de compilation
- [x] Écrire `ScriptStore.swift`
- [x] Lancer : tous passent

## Tâche 4 — Liste et éditeur

**Fichiers :** `Eyeline/EyelineApp.swift`, `Eyeline/ScriptListView.swift`, `Eyeline/EditorView.swift`, `EyelineUITests/FlowTests.swift` (premier test).

- [x] Écrire le test UI `testLeavingAnEmptyScriptDeletesIt` (appareil en paysage)
- [x] Lancer : échec (bouton « Nouveau script » absent)
- [x] Écrire la liste (`PasteButton`, « + », glisser pour supprimer, alerte d'erreur, état vide) et l'éditeur (enregistrement à chaque frappe, « Lire » grisé sans mots, suppression si vide à la fermeture)
- [x] Lancer : passe. Capture `simctl` de la liste

## Tâche 5 — Prompteur et réglages à l'écran

**Fichiers :** `Eyeline/ScrollingText.swift`, `Eyeline/PrompterView.swift`, `Eyeline/SetupView.swift`, `EyelineUITests/FlowTests.swift` (second test).

- [x] Écrire le test UI `testWriteReadPauseAndSetUp` : taper un texte, « Lire », tap → un chiffre du compte à rebours, commandes cachées, tap → pause, « Réglages » → « OK », « Fermer »
- [x] Lancer : échec (pas de bouton « Lire »)
- [x] Écrire `ScrollingText` (TextKit 1, `CADisplayLink` seulement pendant le défilement, masque de fondu sans animation implicite), `PrompterView` (phases, compte à rebours, pause en arrière-plan, écran allumé, commandes dans la bande opposée), `SetupView` (bords de bande, ligne de lecture, panneau)
- [x] Lancer toute la suite sur iOS 26.4.1 et 18.3.1 : tout passe, zéro warning
- [x] Captures `simctl` du prompteur et du réglage

## Tâche 6 — README et installation

- [x] `README.md` en anglais sur le modèle de `trace` : pourquoi, tableau des angles, fonctions, installation depuis Xcode, utilisation, licence, remerciements
- [x] `CLAUDE.md` : section « Current state » à jour
- [x] `Config/Local.xcconfig` avec l'équipe de l'utilisateur, build et installation sur son iPhone

## À vérifier à la main (iPhone)

- [ ] Défilement fluide à 120 Hz, sans saccade
- [ ] Réglage de la bande derrière la Pocket, depuis la place de tournage
- [ ] Lisibilité entre 60 cm et 1 m
- [ ] Enregistrement test avec la Pocket 3 : la lecture se voit-elle moins qu'avant ?
- [ ] Script de 5 000 mots : ouverture et défilement
- [ ] Arrière-plan pendant le défilement : pause, pas de saut
- [ ] Le dossier Eyeline apparaît dans l'app Fichiers

## Revue

- Tâches 1 à 6 faites le 27/09/2026. Zéro warning. Simulateurs iOS 26.4.1 et 18.3.1 : 29 tests unitaires et 2 tests UI passent.
- App Release de 588 Ko, signée avec l'équipe X46PFJFYKM, installée et lancée sur l'iPhone 16 Pro Max.
- Le prototype a changé quatre points de la spec (colonne 220 pt, commandes du côté opposé, bande réglée par ses bords, scripts vides supprimés au chargement) et ajouté la cible de tests UI. Détail dans la spec, section « Changes after the spike ».
- Rien n'est commité ni poussé.

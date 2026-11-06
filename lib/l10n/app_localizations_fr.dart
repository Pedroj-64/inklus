// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonOk => 'OK';

  @override
  String get commonRestore => 'Restaurer';

  @override
  String get commonShare => 'Partager';

  @override
  String get commonGotIt => 'Compris';

  @override
  String commonError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get settingsTitle => 'Réglages';

  @override
  String settingsSubtitle(String version) {
    return 'Inklus $version · vos notes sont stockées sur cet appareil';
  }

  @override
  String get settingsSectionDrive => 'Google Drive';

  @override
  String get settingsSectionAppearance => 'Apparence';

  @override
  String get settingsSectionFiles => 'Sauvegardes et fichiers';

  @override
  String get settingsSectionTools => 'Outils';

  @override
  String get settingsSectionAbout => 'À propos';

  @override
  String get settingsImportTitle => 'Importer un .inklus ou une sauvegarde';

  @override
  String get settingsImportSubtitle =>
      'Un cahier (.inklus) ou une sauvegarde complète (.zip) ; détecté automatiquement';

  @override
  String get settingsExportTitle => 'Exporter la sauvegarde complète';

  @override
  String get settingsExportSubtitle =>
      'Tous les cahiers, images et la corbeille dans un seul .zip';

  @override
  String get settingsAutosaveTitle => 'Enregistrement automatique';

  @override
  String get settingsAutosaveSubtitle =>
      'Chaque modification est enregistrée instantanément sur cet appareil. Une version est conservée à chaque ouverture et fermeture d’une note (menu ⋮ → Historique des versions).';

  @override
  String get settingsStatsTitle => 'Statistiques d’écriture';

  @override
  String get settingsStatsSubtitle => 'Traits, pages, séries et activité';

  @override
  String get settingsRemindersTitle => 'Rappels';

  @override
  String get settingsRemindersSubtitle => 'Alertes liées à vos cahiers';

  @override
  String get settingsTrashTitle => 'Corbeille';

  @override
  String get settingsTrashSubtitle =>
      'Récupérez les cahiers et notes supprimés';

  @override
  String get settingsAppTagline =>
      'L’écriture manuscrite pour tablettes à stylet';

  @override
  String get settingsFreeTitle => 'Libre et ouvert';

  @override
  String get settingsFreeSubtitle =>
      'Open source (GPL-3.0). Aucune fonction payante, aucune publicité, aucune analyse.';

  @override
  String get settingsPrivacyTitle => 'Politique de confidentialité';

  @override
  String get settingsPrivacySubtitle =>
      'Quelles données l’appli traite et où elles vont';

  @override
  String get settingsSourceTitle => 'Code source';

  @override
  String get settingsSourceSubtitle =>
      'Signalez un bug ou proposez des améliorations sur GitHub';

  @override
  String get settingsErrorLogTitle => 'Journal d’erreurs';

  @override
  String get settingsErrorLogSubtitle =>
      'Stocké uniquement sur cet appareil ; vous pouvez le partager pour aider à corriger un bug';

  @override
  String get settingsErrorLogEmpty => 'Aucune erreur enregistrée';

  @override
  String settingsErrorLogCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count erreurs enregistrées',
      one: '1 erreur enregistrée',
    );
    return '$_temp0';
  }

  @override
  String get settingsErrorLogShareSubtitle =>
      'Par e-mail ou dans une issue GitHub';

  @override
  String get settingsErrorLogClear => 'Effacer le journal';

  @override
  String get settingsErrorLogCleared => 'Journal effacé';

  @override
  String settingsErrorLogSubject(String version) {
    return 'Journal d’erreurs d’Inklus $version';
  }

  @override
  String settingsOpenFailed(String url) {
    return 'Impossible d’ouvrir $url';
  }

  @override
  String get settingsTheme => 'Thème';

  @override
  String get settingsLowPowerTitle => 'Mode économie';

  @override
  String get settingsLowPowerSubtitle =>
      'Moins de mémoire sur les tablettes et téléphones modestes : images plus légères. S\'applique à l\'ouverture de la note suivante.';

  @override
  String get settingsThemeLight => 'Clair';

  @override
  String get settingsThemeDark => 'Sombre';

  @override
  String get settingsThemeSystem => 'Système';

  @override
  String get driveConnected => 'Connecté';

  @override
  String get driveCloudCopy => 'Sauvegarde dans le cloud';

  @override
  String get driveGoogleAccount => 'Compte Google';

  @override
  String get driveOptionalPitch =>
      'Facultatif : gardez une copie de vos notes dans votre Google Drive';

  @override
  String get driveConnect => 'Se connecter';

  @override
  String get driveUploadNow => 'Envoyer maintenant';

  @override
  String get driveUploadNowSubtitle =>
      'Envoie les notes des cahiers dont la synchronisation est activée';

  @override
  String get driveRestore => 'Restaurer depuis Drive';

  @override
  String get driveRestoreSubtitle =>
      'Récupère les versions les plus récentes et les notes manquantes sur cet appareil';

  @override
  String get driveNoteVersions => 'Versions d’une note';

  @override
  String get driveNoteVersionsSubtitle =>
      'Dans l’éditeur : ⋮ → Historique des versions';

  @override
  String get driveSwitchAccount => 'Changer de compte';

  @override
  String get driveSignOut => 'Se déconnecter';

  @override
  String get driveAccount => 'Compte';

  @override
  String driveConnectedAs(String email) {
    return 'Connecté en tant que $email';
  }

  @override
  String get driveNotConfigured => 'Google n’est pas configuré';

  @override
  String get driveSignOutQuestion => 'Se déconnecter ?';

  @override
  String get driveSignOutBody =>
      'Les sauvegardes ne seront plus envoyées vers Google Drive. Les copies déjà présentes dans Drive sont conservées.';

  @override
  String get driveSignedOut => 'Déconnecté';

  @override
  String driveUploaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes envoyées vers Drive',
      one: '1 note envoyée vers Drive',
      zero: 'Aucun cahier n’a la synchronisation activée',
    );
    return '$_temp0';
  }

  @override
  String get driveRestoreBody =>
      'Les notes de cet appareil ne sont remplacées que si la copie de Drive est plus récente. Les notes manquantes ici retournent dans leur cahier (ou dans un nouveau cahier « Récupéré depuis Drive »).';

  @override
  String get backupSaveTitle => 'Enregistrer la sauvegarde Inklus';

  @override
  String get backupSaved => 'Sauvegarde enregistrée';

  @override
  String get driveSignInIncomplete => 'La connexion n’a pas abouti';

  @override
  String get driveDetails => 'Détails';

  @override
  String get driveSignInHelpTitle => 'Connexion impossible';

  @override
  String driveSignInHelpBody(String details) {
    return 'Si vous venez de fermer le sélecteur de compte, tout va bien. Si vous avez choisi un compte et qu’il ne se connecte pas, c’est presque toujours que la clé de signature de l’appli (SHA-1) n’est pas enregistrée dans Google Cloud pour com.inklus.inklus.\n\nDétail technique :\n$details';
  }

  @override
  String get driveNotebooksTitle => 'Cahiers synchronisés';

  @override
  String get driveNotebooksSubtitle =>
      'Chaque cahier est enregistré dans Drive → Inklus → son propre dossier. Choisissez lesquels.';

  @override
  String get driveNotebooksEmpty => 'Aucun cahier pour le moment.';

  @override
  String get driveSyncMenu => 'Synchroniser avec Drive';

  @override
  String get driveSyncEnabled => 'Synchronisation activée';

  @override
  String get driveSyncDisabled => 'Synchronisation désactivée';

  @override
  String get textEditHint => 'Écrivez ici…';

  @override
  String get textEditMove => 'Déplacer la zone';

  @override
  String get textEditWidth => 'Largeur de la zone';

  @override
  String get textEditSmaller => 'Plus petit';

  @override
  String get textEditLarger => 'Plus grand';

  @override
  String get textEditBold => 'Gras';

  @override
  String get textEditItalic => 'Italique';

  @override
  String get textEditUnderline => 'Souligné';

  @override
  String get textEditStrike => 'Barré';

  @override
  String get textEditColor => 'Couleur du texte';

  @override
  String get textEditHighlight => 'Surlignage';

  @override
  String get textEditAlign => 'Alignement';

  @override
  String get textEditSpacing => 'Interligne';

  @override
  String get textEditLinkActive => 'Lien vers une page (actif)';

  @override
  String get textEditLink => 'Lien vers une page';

  @override
  String get textEditDelete => 'Supprimer la zone';

  @override
  String get textEditDone => 'Terminé';

  @override
  String get textEditWholeBox => 'Toute la zone';

  @override
  String get textEditNoHighlight => 'Sans surlignage';

  @override
  String get textEditUnlink => 'Supprimer le lien';

  @override
  String commonPageN(int n) {
    return 'Page $n';
  }

  @override
  String get marketWhereTemplate => 'dans le menu Modèle de la page';

  @override
  String get marketWherePalette => 'dans les couleurs de chaque stylo';

  @override
  String get marketWhereStickers =>
      'dans Plus d’outils → Insérer un autocollant';

  @override
  String get marketHeroTitle => 'Découvrez et personnalisez';

  @override
  String get marketHeroSubtitle =>
      'Modèles, palettes et autocollants de la communauté. Gratuits et sous licence ouverte.';

  @override
  String get marketSearch => 'Rechercher des packs';

  @override
  String get marketTitle => 'Marketplace';

  @override
  String get marketOfflineCache =>
      'Hors ligne : affichage du dernier catalogue téléchargé';

  @override
  String get marketOfflineBundled =>
      'Hors ligne : affichage des packs inclus dans l’appli';

  @override
  String get marketAll => 'Tous';

  @override
  String get marketTemplates => 'Modèles';

  @override
  String get marketPalettes => 'Palettes';

  @override
  String get marketStickers => 'Autocollants';

  @override
  String get marketPalette => 'Palette';

  @override
  String get marketNoResults => 'Aucun pack correspondant';

  @override
  String get marketRemove => 'Retirer';

  @override
  String get marketInstall => 'Installer';

  @override
  String marketUninstalled(String name) {
    return '« $name » désinstallé';
  }

  @override
  String marketInstalled(String name, String where) {
    return '« $name » installé : $where';
  }

  @override
  String marketInstallFailed(String name, String error) {
    return 'Impossible d’installer « $name » : $error';
  }

  @override
  String get createTplBlank => 'Vierge';

  @override
  String get createTplRuled => 'Lignes';

  @override
  String get createTplGrid => 'Quadrillé';

  @override
  String get createTplDots => 'Pointillé';

  @override
  String get createTplMusic => 'Portée';

  @override
  String get createTplPlanner => 'Agenda';

  @override
  String get createTplHabit => 'Habitudes';

  @override
  String get createTplCornell => 'Cornell';

  @override
  String get createTplWeekly => 'Semaine';

  @override
  String get createTplMonthly => 'Mois';

  @override
  String get createTplTodo => 'Tâches';

  @override
  String get createTplStoryboard => 'Storyboard';

  @override
  String get createTplMillimeter => 'Papier millimétré';

  @override
  String get createTplSheet => 'Feuille A4';

  @override
  String get createTitle => 'Nouveau cahier';

  @override
  String get createName => 'Nom';

  @override
  String get createNameHint => 'Mon cahier';

  @override
  String get createCover => 'Couverture';

  @override
  String get createDesign => 'Motif';

  @override
  String get createYourImage => 'Votre image';

  @override
  String get createChangeImage => 'Changer l’image';

  @override
  String get createColor => 'Couleur';

  @override
  String get createNext => 'Suivant';

  @override
  String get createStep2 => 'Étape 2 : choisissez un modèle';

  @override
  String get createBackToStep1 => 'Retour à l’étape 1';

  @override
  String get createTemplate => 'Modèle';

  @override
  String get createMoreTemplates => 'Afficher plus de modèles';

  @override
  String get createFewer => 'Afficher moins';

  @override
  String get createInfinite => 'Canevas infini';

  @override
  String get createInfiniteOn =>
      'Le canevas s’agrandit à mesure que vous écrivez';

  @override
  String get createInfiniteOff => 'Feuille de taille fixe (A4)';

  @override
  String get createAction => 'Créer le cahier';

  @override
  String createDefaultName(int n) {
    return 'Cahier $n';
  }

  @override
  String createCoverSemantics(String name) {
    return 'Couverture $name';
  }

  @override
  String get libRenameTitle => 'Renommer le cahier';

  @override
  String get libDeleteTitle => 'Supprimer le cahier';

  @override
  String get libDelete => 'Supprimer';

  @override
  String get libCoverColor => 'Couleur de couverture';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get libSortTitle => 'Trier les cahiers';

  @override
  String get libSortNewestFirst => 'Plus récents d’abord';

  @override
  String get libSortOldestFirst => 'Plus anciens d’abord';

  @override
  String get libSortTitleAZ => 'Titre A → Z';

  @override
  String get libSortTitleZA => 'Titre Z → A';

  @override
  String get libNavAll => 'Tous';

  @override
  String get libNavRecent => 'Récents';

  @override
  String get libNavFavorites => 'Favoris';

  @override
  String get libNavFolders => 'Dossiers';

  @override
  String get libImport => 'Importer un .inklus';

  @override
  String get libTrash => 'Corbeille';

  @override
  String get libLightMode => 'Mode clair';

  @override
  String get libDarkMode => 'Mode sombre';

  @override
  String get libMoreOptions => 'Plus d’options';

  @override
  String get libMyNotebooks => 'Mes cahiers';

  @override
  String get libClearFilter => 'Effacer le filtre';

  @override
  String get libSearchHint => 'Rechercher par nom ou étiquette';

  @override
  String get libSearchInNotes =>
      'Rechercher dans les notes (texte et écriture manuscrite)';

  @override
  String get libSearchContent => 'Dans le contenu';

  @override
  String get libSortNewest => 'Plus récents';

  @override
  String get libSortOldest => 'Plus anciens';

  @override
  String get libSortNameAZ => 'Nom A–Z';

  @override
  String get libSortNameZA => 'Nom Z–A';

  @override
  String get libGrid => 'Grille';

  @override
  String get libList => 'Liste';

  @override
  String get libNoResults => 'Aucun cahier trouvé';

  @override
  String get libEmptyTitle => 'Commencez à écrire';

  @override
  String get libNoResultsHint => 'Essayez un autre nom ou une autre étiquette.';

  @override
  String get libUnfavorite => 'Retirer des favoris';

  @override
  String get libFavorite => 'Ajouter aux favoris';

  @override
  String get libRename => 'Renommer';

  @override
  String get libDuplicate => 'Dupliquer';

  @override
  String get libCoverAndColor => 'Couverture et couleur';

  @override
  String get libTags => 'Étiquettes';

  @override
  String get libSyncOff => 'Arrêter la synchronisation avec Drive';

  @override
  String get libMoveToTrash => 'Mettre à la corbeille';

  @override
  String get libNotebookOptions => 'Options du cahier';

  @override
  String libSyncWillSync(String title) {
    return '« $title » sera synchronisé avec Drive';
  }

  @override
  String libSyncStopped(String title) {
    return '« $title » n’est plus synchronisé';
  }

  @override
  String libDeleteBody(String title) {
    return '« $title » sera mis à la corbeille. Vous pourrez le restaurer depuis là.';
  }

  @override
  String libImportError(String error) {
    return 'Erreur d’importation : $error';
  }

  @override
  String libCountAll(int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total cahiers',
      one: '1 cahier',
    );
    return '$_temp0';
  }

  @override
  String libCountOf(int shown, int total) {
    return '$shown sur $total cahiers';
  }

  @override
  String libNotebookSemantics(String title, String when) {
    return 'Cahier $title, $when';
  }

  @override
  String get libEmptyHint =>
      'Créez un nouveau cahier ou importez-en un existant\\npour commencer.';

  @override
  String get noteRenameTitle => 'Renommer la note';

  @override
  String get noteDeleteTitle => 'Supprimer la note';

  @override
  String get noteNew => 'Nouvelle note';

  @override
  String get noteNameHint => 'Ma note';

  @override
  String get noteCreate => 'Créer';

  @override
  String get noteEmptyTitle => 'Aucune note';

  @override
  String get noteEmptyHint =>
      'Créez votre première note pour commencer à écrire.';

  @override
  String get noteCreateAction => 'Créer une note';

  @override
  String get noteOptions => 'Options';

  @override
  String get timeNow => 'à l’instant';

  @override
  String get noteTplInfinite => 'Infinie';

  @override
  String get noteTplSheet => 'Feuille fixe';

  @override
  String get noteTplPlanner => 'Agenda';

  @override
  String get tplInfiniteHint =>
      'Les modèles infinis s’agrandissent à mesure que vous écrivez';

  @override
  String get tplNormalSheet => 'Feuille standard';

  @override
  String get tplOwn => 'Votre propre modèle';

  @override
  String get tplFromMarket => 'Depuis le marketplace';

  @override
  String get tplMine => 'Mes modèles';

  @override
  String get tplSaveCurrent => 'Enregistrer l’actuel';

  @override
  String get tplCustomize => 'Personnaliser';

  @override
  String get tplLineColor => 'Couleur des lignes';

  @override
  String get tplSpacing => 'Espacement';

  @override
  String get tplFixedSheet => 'Feuille de taille fixe';

  @override
  String get tplSheetSize => 'Taille de la feuille';

  @override
  String get tplLetter => 'Lettre';

  @override
  String get tplHowTitle => 'Comment utiliser le modèle ?';

  @override
  String get tplHowBody => 'L’image servira de fond pour écrire.';

  @override
  String get tplAsSheet => 'Comme feuille fixe';

  @override
  String get tplAsFill => 'Remplissage infini';

  @override
  String get tplOnlyImage =>
      'Seuls les modèles avec une image peuvent être enregistrés';

  @override
  String get tplSaveTitle => 'Enregistrer le modèle';

  @override
  String get tplDefaultName => 'Mon modèle';

  @override
  String get tplSaved => 'Modèle enregistré';

  @override
  String get tplDeleteTitle => 'Supprimer le modèle';

  @override
  String get tplDeleteBody => 'Supprimer ce modèle enregistré ?';

  @override
  String get colorCustomTitle => 'Couleur personnalisée';

  @override
  String get colorCurrent => 'Actuelle';

  @override
  String get colorNew => 'Nouvelle';

  @override
  String get colorWheel => 'Roue';

  @override
  String get colorHue => 'Teinte';

  @override
  String get colorSaturation => 'Saturation';

  @override
  String get colorBrightness => 'Luminosité';

  @override
  String get colorUse => 'Utiliser';

  @override
  String timeMinAgo(int n) {
    return 'il y a $n min';
  }

  @override
  String timeHoursAgo(int n) {
    return 'il y a $n h';
  }

  @override
  String timeDaysAgo(int n) {
    return 'il y a $n j';
  }

  @override
  String get timeDeletedNow => 'supprimé à l’instant';

  @override
  String timeDeletedMin(int n) {
    return 'supprimé il y a $n min';
  }

  @override
  String timeDeletedHours(int n) {
    return 'supprimé il y a $n h';
  }

  @override
  String timeDeletedDays(int n) {
    return 'supprimé il y a $n jours';
  }

  @override
  String timeDeletedOn(String date) {
    return 'supprimé le $date';
  }

  @override
  String noteDeleteBody(String title) {
    return '« $title » sera retirée de ce cahier.';
  }

  @override
  String noteDefaultName(int n) {
    return 'Note $n';
  }

  @override
  String noteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$_temp0';
  }

  @override
  String notePageCount(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0 · $when';
  }

  @override
  String tplImageLoadFailed(String error) {
    return 'Impossible de charger l’image : $error';
  }

  @override
  String tplSaveFailed(String error) {
    return 'Erreur d’enregistrement : $error';
  }

  @override
  String get colorSliders => 'Curseurs';

  @override
  String get selPaste => 'Coller';

  @override
  String get selCopy => 'Copier';

  @override
  String get selCopied => 'Copié';

  @override
  String get selThinner => 'Plus fin';

  @override
  String get selThicker => 'Plus épais';

  @override
  String get selToText => 'Convertir en texte';

  @override
  String get selDeselect => 'Désélectionner';

  @override
  String get selNoText => 'Aucun texte reconnu dans la sélection';

  @override
  String get selConvert => 'Convertir';

  @override
  String get popPenType => 'Type de stylo';

  @override
  String get popThickness => 'Épaisseur';

  @override
  String get popStraighten => 'Redresser les formes';

  @override
  String get popNo => 'Non';

  @override
  String get popOnHold => 'En maintenant';

  @override
  String get popAlways => 'Toujours';

  @override
  String get popShapeOffHint => 'Les traits restent tels quels.';

  @override
  String get popShapeHoldHint =>
      'Maintenez le stylet immobile presque une seconde après avoir terminé une ligne, un cercle, un triangle ou un rectangle.';

  @override
  String get popShapeAlwaysHint =>
      'Toute forme reconnaissable est redressée quand vous levez le stylet.';

  @override
  String get popAdvanced => 'Réglages avancés du trait';

  @override
  String get popMode => 'Mode';

  @override
  String get popPartial => 'Partiel';

  @override
  String get popStroke => 'Trait';

  @override
  String get popHighlighter => 'Surligneur';

  @override
  String get popEraseOff =>
      'N’efface que ce que vous touchez, comme une gomme.';

  @override
  String get popEraseStroke => 'Efface le trait entier quand on le touche.';

  @override
  String get popEraseHighlighter =>
      'N’efface que le surligneur ; l’encre n’est pas touchée.';

  @override
  String get popSize => 'Taille';

  @override
  String get tbBackToLibrary => 'Retour à la bibliothèque';

  @override
  String get tbHidePages => 'Masquer les pages';

  @override
  String get tbPages => 'Pages';

  @override
  String get tbHideLayers => 'Masquer les calques';

  @override
  String get tbLayers => 'Calques';

  @override
  String get tbInsertImage => 'Insérer une image';

  @override
  String get tbRuler => 'Règle';

  @override
  String get tbRulerNext => 'Règle (toucher : rapporteur)';

  @override
  String get tbProtractorNext => 'Rapporteur (toucher : masquer)';

  @override
  String get tbMoveSelect => 'Déplacer / sélectionner images et traits';

  @override
  String get tbFill => 'Remplir une zone';

  @override
  String get tbHideMagnifier => 'Masquer la loupe';

  @override
  String get tbMagnifier => 'Loupe';

  @override
  String get tbLaserOff => 'Désactiver le pointeur laser';

  @override
  String get tbLaser => 'Pointeur laser';

  @override
  String get tbInsertSticker => 'Insérer un autocollant';

  @override
  String get tbPageTemplate => 'Modèle de page';

  @override
  String get tbMoreTools => 'Plus d’outils';

  @override
  String get tbUndo => 'Annuler';

  @override
  String get tbRedo => 'Rétablir';

  @override
  String get pgUnbookmark => 'Retirer le marque-page';

  @override
  String get pgBookmark => 'Marquer la page';

  @override
  String get pgShowAll => 'Tout afficher';

  @override
  String get pgOnlyBookmarked => 'Marquées seulement';

  @override
  String get commonClose => 'Fermer';

  @override
  String get pgOptions => 'Options de la page';

  @override
  String get pgNew => 'Nouvelle page';

  @override
  String get tagTitle => 'Étiquettes du cahier';

  @override
  String get tagSubtitle =>
      'Pour le retrouver et le regrouper dans des dossiers intelligents';

  @override
  String get tagActive => 'Étiquettes actives';

  @override
  String get tagOthers => 'Autres étiquettes';

  @override
  String get tagNew => 'Nouvelle étiquette…';

  @override
  String get tagAdd => 'Ajouter une étiquette';

  @override
  String get tagSave => 'Enregistrer les étiquettes';

  @override
  String get trashDeleteForever => 'Supprimer définitivement';

  @override
  String get trashEmptyTitle => 'Vider la corbeille';

  @override
  String get trashEmpty => 'Vider';

  @override
  String get trashSubtitleEmpty => 'Ce que vous supprimez reste ici 30 jours';

  @override
  String get trashEmptyState => 'La corbeille est vide';

  @override
  String get trashLegacy => 'Cahier (ancien format)';

  @override
  String get trashNote => 'Note';

  @override
  String get trashReturn => 'Remettre dans son cahier';

  @override
  String get strokeSubtitle => 'Pression, lissage et fluidité du trait';

  @override
  String get strokeNone =>
      'La gomme et la sélection n’ont pas d’options de trait.';

  @override
  String get strokeQuickSize => 'Taille rapide';

  @override
  String get strokePressure => 'Variation de pression';

  @override
  String get strokePressureDesc =>
      'De combien l’épaisseur change quand vous appuyez';

  @override
  String get strokeSmoothing => 'Lissage';

  @override
  String get strokeSmoothingDesc => 'Arrondit les courbes du trait';

  @override
  String get strokeStabilizer => 'Stabilisateur';

  @override
  String get strokeStabilizerDesc => 'Réduit le tremblement de la main';

  @override
  String get strokeReset => 'Réinitialiser les réglages';

  @override
  String get sizeThin => 'Fin';

  @override
  String get sizeMedium => 'Moyen';

  @override
  String get sizeThick => 'Épais';

  @override
  String get sizeExtra => 'Très épais';

  @override
  String get sizeSmall => 'Petit';

  @override
  String get sizeLarge => 'Grand';

  @override
  String get toolPen => 'Stylo bille';

  @override
  String get toolPencil => 'Crayon';

  @override
  String get toolCalligraphy => 'Plume de calligraphie';

  @override
  String get toolBrush => 'Pinceau';

  @override
  String get toolMarker => 'Marqueur';

  @override
  String get toolSpray => 'Aérosol';

  @override
  String get toolEraser => 'Gomme';

  @override
  String get toolSelect => 'Déplacer / sélectionner';

  @override
  String get toolLasso => 'Lasso';

  @override
  String get toolFill => 'Remplissage';

  @override
  String get toolText => 'Texte';

  @override
  String selRecognizeFailed(String error) {
    return 'Reconnaissance impossible : $error';
  }

  @override
  String tbPenSlot(String tool, int n) {
    return '$tool $n';
  }

  @override
  String get canvasSemantics => 'Zone de dessin';

  @override
  String tbPageOf(int n, int total) {
    return 'Page $n sur $total';
  }

  @override
  String pgPagesCount(int n) {
    return 'Pages ($n)';
  }

  @override
  String strokeOptionsOf(String tool) {
    return 'Options de $tool';
  }

  @override
  String trashRestoredMsg(String title) {
    return '« $title » restauré';
  }

  @override
  String trashPurgeBody(String title) {
    return '« $title » sera supprimé définitivement. Cette action est irréversible.';
  }

  @override
  String trashEmptyBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments seront supprimés définitivement',
      one: '1 élément sera supprimé définitivement',
    );
    return '$_temp0. Cette action est irréversible.';
  }

  @override
  String trashSubtitleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count éléments',
      one: '1 élément',
    );
    return '$_temp0 · supprimés automatiquement après 30 jours';
  }

  @override
  String get trashEmptyStateBody =>
      'Les cahiers et notes que vous supprimez sont conservés ici 30 jours avant d’être définitivement effacés.';

  @override
  String trashNotebookKind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return 'Cahier · $_temp0';
  }

  @override
  String trashNoteOf(String title) {
    return 'Note de « $title »';
  }

  @override
  String get trashLeftTomorrow => 'supprimé demain';

  @override
  String trashLeftDays(int n) {
    return '$n jours restants';
  }

  @override
  String trashInfoLine(String what, String deleted, String left) {
    return '$what · $deleted · $left';
  }

  @override
  String get edLayerLocked =>
      'Calque verrouillé — déverrouillez-le pour modifier';

  @override
  String get expTitle => 'Options d’exportation';

  @override
  String get expLow => 'Basse (1024 px)';

  @override
  String get expMedium => 'Moyenne (2048 px)';

  @override
  String get expHigh => 'Haute (4096 px)';

  @override
  String get expMax => 'Maximale (8192 px)';

  @override
  String get expTransparent => 'Fond transparent';

  @override
  String get expTransparentHint => 'Sans modèle ni papier';

  @override
  String get expStrokesOnly => 'Traits uniquement';

  @override
  String get expStrokesOnlyHint => 'Sans images ni modèle';

  @override
  String get expExport => 'Exporter';

  @override
  String get ocrUnsupported => 'L’OCR n’est disponible que sur Android et iOS';

  @override
  String get ocrWorking => 'Reconnaissance du texte…';

  @override
  String get ocrNoText => 'Aucun texte reconnu sur cette page';

  @override
  String get ocrResultTitle => 'Texte reconnu';

  @override
  String get ocrCopied => 'Texte copié dans le presse-papiers';

  @override
  String get edGoogleAccount => 'Compte Google';

  @override
  String get edSyncedCloud => 'Synchronisé avec le cloud';

  @override
  String get edRestoreCloud => 'Restaurer depuis le cloud';

  @override
  String get edRestoreCloudHint =>
      'Dernière version (la dernière écriture l’emporte)';

  @override
  String get edDriveVersions => 'Voir les versions dans Drive';

  @override
  String get edUploadInklus => 'Envoyer le fichier .inklus';

  @override
  String get edSyncOnForNotebook => 'Synchronisation : activée pour ce cahier';

  @override
  String get edSyncOffForNotebook =>
      'Synchronisation : désactivée pour ce cahier';

  @override
  String get edSyncDisabledMsg => 'Synchronisation désactivée pour ce cahier';

  @override
  String get edSyncEnabledMsg => 'Synchronisation activée pour ce cahier';

  @override
  String get edNoteSynced => 'Note synchronisée avec Google Drive';

  @override
  String get edPasswordHint => 'Mot de passe (laisser vide si non chiffré)';

  @override
  String get edNoCloudCopy =>
      'Il n’y a pas encore de copie de cette note dans Google Drive';

  @override
  String get edNoteRestored => 'Note restaurée depuis Google Drive';

  @override
  String get edIsFullBackup =>
      'Ce fichier est une sauvegarde complète, pas un cahier .inklus';

  @override
  String get edNoPassword => 'Sans mot de passe';

  @override
  String get edNotebookTitle => 'Titre du cahier';

  @override
  String get pdfUnsupported =>
      'L’importation de PDF n’est disponible que sur Android/iOS pour l’instant';

  @override
  String get pdfReadFailed => 'Impossible de lire le PDF';

  @override
  String get verRestoreTitle => 'Restaurer la version';

  @override
  String get verRestored => 'Version restaurée';

  @override
  String get verEncrypted => 'Copie chiffrée';

  @override
  String get verPasswordHint => 'Mot de passe de la copie';

  @override
  String get verDecrypt => 'Déchiffrer';

  @override
  String get inkUnsupported =>
      'La reconnaissance de l’écriture manuscrite n’est disponible que sur Android et iOS';

  @override
  String get edDeleteImage => 'Supprimer l’image';

  @override
  String get edExitPresent => 'Quitter la présentation';

  @override
  String get edLaserOff => 'Désactiver le laser';

  @override
  String get edGoToPage => 'Aller à la page';

  @override
  String get edGo => 'Aller';

  @override
  String get edNoStickers => 'Vous n’avez encore aucun autocollant installé.';

  @override
  String get edOpenMarket => 'Ouvrir le marketplace';

  @override
  String get edSyncing => 'Synchronisation…';

  @override
  String get edSyncToDrive => 'Synchroniser avec Google Drive';

  @override
  String get edSynced => 'Synchronisé';

  @override
  String get edSyncError => 'Erreur de synchronisation';

  @override
  String get menuPagePng => 'Page en image (PNG)';

  @override
  String get menuPagePdf => 'Page en PDF';

  @override
  String get menuNotePdf => 'Note entière (PDF)';

  @override
  String get menuStrokesSvg => 'Traits (SVG)';

  @override
  String get menuPptx => 'Présentation (PowerPoint)';

  @override
  String get menuInklusCopy => 'Copier en .inklus';

  @override
  String get menuShareImage => 'Partager l’image';

  @override
  String get menuSharePdf => 'Partager le PDF';

  @override
  String get menuShareInklus => 'Partager le .inklus';

  @override
  String get menuExportShare => 'Exporter et partager';

  @override
  String get menuTemplate => 'Modèle…';

  @override
  String get menuGoToPage => 'Aller à la page…';

  @override
  String get menuImportPdf => 'Importer un PDF à annoter';

  @override
  String get menuClearPage => 'Effacer la page';

  @override
  String get menuPage => 'Page';

  @override
  String get menuSearchNote => 'Rechercher dans la note';

  @override
  String get menuIndexInk =>
      'Indexer l’écriture manuscrite (pour la rechercher)';

  @override
  String get menuIndexInkUnsupported =>
      'Indexer l’écriture manuscrite (Android/iOS uniquement)';

  @override
  String get menuOcr => 'Reconnaître le texte (OCR)';

  @override
  String get menuOcrUnsupported => 'OCR (Android/iOS uniquement)';

  @override
  String get menuVersions => 'Historique des versions';

  @override
  String get menuReminder => 'Créer un rappel';

  @override
  String get menuNightOff => 'Désactiver le mode nuit';

  @override
  String get menuNightOn => 'Mode nuit d’écriture';

  @override
  String get menuPresent => 'Mode présentation';

  @override
  String get menuHapticsOn => 'Vibration à l’écriture : activée';

  @override
  String get menuHapticsOff => 'Vibration à l’écriture : désactivée';

  @override
  String get menuContinuousScroll => 'Défilement continu entre les feuilles';

  @override
  String get menuView => 'Affichage';

  @override
  String get menuBackup => 'Exporter la sauvegarde complète';

  @override
  String get menuRestoreBackup => 'Importer un .inklus ou une sauvegarde';

  @override
  String get menuData => 'Données';

  @override
  String get menuStats => 'Statistiques d’écriture';

  @override
  String get clearPageBody =>
      'Tout le contenu de la page sera effacé. Vous pourrez annuler ensuite.';

  @override
  String get clearPageAction => 'Effacer';

  @override
  String get pgPrev => 'Page précédente';

  @override
  String get pgNext => 'Page suivante';

  @override
  String get zoomOut => 'Zoom arrière';

  @override
  String get zoomFit => 'Ajuster à l’écran';

  @override
  String get zoomIn => 'Zoom avant';

  @override
  String get shareTextPage => 'Page Inklus';

  @override
  String get shareTextNotebook => 'Cahier Inklus';

  @override
  String edInsertImageFailed(String error) {
    return 'Impossible d’insérer l’image : $error';
  }

  @override
  String expSvgFailed(String error) {
    return 'Erreur d’exportation SVG : $error';
  }

  @override
  String ocrFailed(String error) {
    return 'Erreur de reconnaissance du texte : $error';
  }

  @override
  String expFailed(String error) {
    return 'Erreur d’exportation : $error';
  }

  @override
  String expPreview(String name) {
    return 'Aperçu : $name';
  }

  @override
  String expSaveDialog(String name) {
    return 'Enregistrer $name';
  }

  @override
  String expDone(String path) {
    return 'Exporté : $path';
  }

  @override
  String expSaveFailed(String error) {
    return 'Impossible d’enregistrer le fichier : $error';
  }

  @override
  String shareFailed(String error) {
    return 'Erreur de partage : $error';
  }

  @override
  String edSignInIncomplete(String detail) {
    return 'La connexion n’a pas abouti. Détail : $detail';
  }

  @override
  String uploadFailed(String error) {
    return 'Erreur d’envoi : $error';
  }

  @override
  String restoreFailed(String error) {
    return 'Erreur de restauration : $error';
  }

  @override
  String edFileUploaded(String name) {
    return 'Fichier « $name » envoyé vers Google Drive';
  }

  @override
  String pdfImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return 'PDF importé : $_temp0 à annoter';
  }

  @override
  String pdfImportFailed(String error) {
    return 'Erreur d’importation du PDF : $error';
  }

  @override
  String verRestoreBody(String date) {
    return 'La note reviendra à son état du $date.\\n\\nL’état actuel est d’abord enregistré comme version locale : vous pourrez donc annuler la restauration depuis ce même historique.';
  }

  @override
  String verRestoreFailed(String error) {
    return 'Impossible de restaurer la version : $error';
  }

  @override
  String pptxFailed(String error) {
    return 'Erreur d’exportation PowerPoint : $error';
  }

  @override
  String reminderCreated(String date, String time) {
    return 'Rappel créé pour le $date à $time';
  }

  @override
  String inkIndexed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return 'Écriture manuscrite indexée sur $_temp0 : vous pouvez maintenant la rechercher';
  }

  @override
  String inkFailed(String error) {
    return 'Impossible de reconnaître l’écriture manuscrite : $error';
  }

  @override
  String backupFailed(String error) {
    return 'Erreur d’exportation de la sauvegarde : $error';
  }

  @override
  String importDoneOpen(String message) {
    return '$message. Ouvrez-le depuis la bibliothèque.';
  }

  @override
  String noteHasPages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return 'La note compte $_temp0';
  }

  @override
  String stickerInsertFailed(String error) {
    return 'Impossible d’insérer l’autocollant : $error';
  }

  @override
  String get remNoNotebooks => 'Aucun cahier à associer';

  @override
  String get remPickNotebook => 'Sélectionnez le cahier';

  @override
  String get remPickHint => 'Le rappel ouvrira ce cahier';

  @override
  String get remCreated => 'Rappel créé';

  @override
  String get remMessageTitle => 'Message du rappel';

  @override
  String get remMessageHint => 'Ex. : Réviser les notes de cours';

  @override
  String get remNoMessage => 'Sans message';

  @override
  String get remTitle => 'Rappels';

  @override
  String get remSubtitle => 'Alertes liées à vos cahiers';

  @override
  String get remEmptyTitle => 'Aucun rappel';

  @override
  String get remPending => 'En attente';

  @override
  String get remDone => 'Terminés';

  @override
  String get statsTitle => 'Statistiques';

  @override
  String get statsSubtitle => 'Votre activité d’écriture sur cet appareil';

  @override
  String get statsEmptyTitle => 'Pas encore de données';

  @override
  String get statsStrokes => 'Traits';

  @override
  String get statsMinutes => 'Minutes';

  @override
  String get statsActiveDays => 'Jours actifs';

  @override
  String get statsStreaks => 'Séries';

  @override
  String get statsCurrentStreak => 'Série actuelle';

  @override
  String get statsRecord => 'Record';

  @override
  String get statsActivity => 'Activité — 30 derniers jours';

  @override
  String get statsDaysWithPages => 'Jours avec de nouvelles pages';

  @override
  String get smartTitle => 'Dossiers intelligents';

  @override
  String get smartSubtitle => 'Organisez vos cahiers automatiquement';

  @override
  String get smartByColor => 'Par couleur';

  @override
  String get smartByTag => 'Par étiquette';

  @override
  String get onbSkip => 'Passer';

  @override
  String get onbStart => 'Commencer';

  @override
  String get onb1Title => 'Écrivez avec votre stylet';

  @override
  String get onb2Title => 'Déplacez-vous avec les doigts';

  @override
  String get onb3Title => 'Les outils en haut';

  @override
  String get onb4Title => 'Vos notes vous appartiennent';

  @override
  String get layerAdd => 'Ajouter un calque';

  @override
  String get layerRename => 'Renommer le calque';

  @override
  String get verSubtitle =>
      'Lors de la restauration, l’état actuel est d’abord enregistré';

  @override
  String get verOnDevice => 'Sur cet appareil';

  @override
  String get verNoLocal =>
      'Il n’y a pas encore de copies locales de cette note.';

  @override
  String get verOnDrive => 'Sur Google Drive';

  @override
  String get verNotUploaded =>
      'Cette note n’a pas encore été envoyée vers Drive.';

  @override
  String get smartThisWeek => 'Cette semaine';

  @override
  String get smartNoTags => 'Sans étiquette';

  @override
  String get smartOther => 'Autres';

  @override
  String get colorNone => 'Sans couleur';

  @override
  String get colorBlue => 'Bleu';

  @override
  String get colorGreen => 'Vert';

  @override
  String get colorRed => 'Rouge';

  @override
  String get colorOrange => 'Orange';

  @override
  String get colorPurple => 'Violet';

  @override
  String get colorPink => 'Rose';

  @override
  String get colorTurquoise => 'Turquoise';

  @override
  String get colorGray => 'Gris';

  @override
  String get onb1Body =>
      'Posez la main sans crainte : Inklus reconnaît le stylet et ignore votre paume. Le bout gomme du stylet ou le bouton latéral efface.';

  @override
  String get onb2Body =>
      'Avec le stylet, un doigt fait défiler la page et deux doigts zooment. Vous pouvez dessiner de nouveau avec le doigt depuis la barre d’outils.';

  @override
  String get onb3Body =>
      'Touchez un outil pour l’utiliser, puis touchez-le à nouveau pour voir ses options : épaisseur, couleur, gomme partielle, formes…';

  @override
  String get onb4Body =>
      'Tout est enregistré sur cet appareil, sans compte ni publicité. Si vous le souhaitez, vous pouvez sauvegarder dans votre Google Drive.';

  @override
  String get remEmptyBody =>
      'Créez des rappels liés à vos cahiers pour ne jamais rien oublier.';

  @override
  String get statsEmptyBody =>
      'Commencez à écrire dans vos cahiers et vos statistiques apparaîtront ici.';

  @override
  String get remOverdue => ' · en retard';

  @override
  String statsDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String statsDayTooltip(String date, int strokes, int pages) {
    return '$date : $strokes traits, $pages pages';
  }

  @override
  String get searchInNote => 'Rechercher dans cette note';

  @override
  String get searchInAll => 'Rechercher dans toutes les notes';

  @override
  String get searchPrompt => 'Saisissez pour rechercher';

  @override
  String searchMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count résultats',
      one: '1 résultat',
    );
    return '$_temp0';
  }

  @override
  String get searchInfo =>
      'Inclut les zones de texte et l’écriture manuscrite déjà reconnue (menu Note → Indexer l’écriture manuscrite).';

  @override
  String get searchTitleMatch => 'Titre';

  @override
  String get pgDuplicate => 'Dupliquer la page';

  @override
  String get pgDelete => 'Supprimer la page';

  @override
  String verDriveFailed(String error) {
    return 'Impossible d’interroger Drive : $error';
  }

  @override
  String colorSemantics(String hex) {
    return 'Couleur #$hex';
  }

  @override
  String get errNotInklus =>
      'Le fichier n’est ni un cahier .inklus ni une sauvegarde Inklus.';

  @override
  String get errNotInklusFile => 'Cahier .inklus non valide';

  @override
  String get errNotInklusV2 => 'Cahier .inklus v2 non valide';

  @override
  String get errCatalogTooLarge => 'Le catalogue est trop volumineux';

  @override
  String errCatalogVersion(String version) {
    return 'Version de catalogue non prise en charge : $version';
  }

  @override
  String get errOcrUnsupported =>
      'L’OCR n’est disponible que sur Android et iOS.';

  @override
  String get errNotSignedIn => 'Connectez-vous d’abord avec Google.';

  @override
  String get errEncrypted =>
      'La copie est chiffrée : un mot de passe est nécessaire';

  @override
  String driveConfigBody(String details) {
    return 'Erreur de configuration Google (clientConfigurationError).\\n\\nCause probable : le SHA-1 de signature de cette appli n’est pas enregistré dans Google Cloud Console pour le paquet com.inklus.inklus.\\n\\nSolution :\\n1. Allez dans Google Cloud Console → API et services → Identifiants\\n2. Créez ou modifiez l’ID client OAuth Android avec le paquet com.inklus.inklus et votre SHA-1 de signature\\n3. Activez Google Sign-In sur l’écran de consentement\\n\\nErreur d’origine : $details';
  }

  @override
  String get noticeStylus =>
      'Stylet détecté : le doigt fait désormais défiler la page (activez-le dans la barre d’outils si vous voulez dessiner avec le doigt)';

  @override
  String get noticePageDeleted => 'Page supprimée';

  @override
  String get noticeFileUploaded => 'Fichier envoyé vers Google Drive';

  @override
  String importBackupRestored(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cahiers',
      one: '1 cahier',
    );
    return 'Sauvegarde restaurée : $_temp0';
  }

  @override
  String importNotebookDone(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return 'Cahier « $title » importé ($_temp0)';
  }

  @override
  String importNotebookSimple(String title) {
    return 'Cahier « $title » importé';
  }

  @override
  String get driveRestoreNone =>
      'Il n’y a aucune copie d’Inklus dans votre Google Drive';

  @override
  String get driveRestoreUpToDate => 'Tout est à jour : rien à restaurer';

  @override
  String driveRestoreUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes mises à jour',
      one: '1 note mise à jour',
    );
    return '$_temp0';
  }

  @override
  String driveRestoreAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count récupérées',
      one: '1 récupérée',
    );
    return '$_temp0';
  }

  @override
  String get driveRecovered => 'Récupéré depuis Drive';

  @override
  String get packClassicName => 'Cahiers classiques';

  @override
  String get packClassicDesc =>
      'Lignes larges et étroites, quadrillage de 5 mm, pointillés et portée.';

  @override
  String get packTechName => 'Papier technique';

  @override
  String get packTechDesc =>
      'Fin quadrillage de papier millimétré et agenda en colonnes, en tons doux.';

  @override
  String get packStudyName => 'Palette d’étude';

  @override
  String get packStudyDesc =>
      'Encre bleue et noire, rouge de correction, vert et orange pour souligner.';

  @override
  String get packPastelName => 'Palette pastel';

  @override
  String get packPastelDesc =>
      'Tons doux pour de jolies notes et de beaux schémas.';

  @override
  String get packEarthName => 'Palette terre';

  @override
  String get packEarthDesc =>
      'Ocres, olive et terre cuite, avec un bon contraste sur le papier.';

  @override
  String get coverSimple => 'Dégradé';

  @override
  String get coverClassic => 'Classique';

  @override
  String get coverAurora => 'Aurore';

  @override
  String get coverWaves => 'Vagues';

  @override
  String get coverGeometric => 'Géométrique';

  @override
  String get coverSun => 'Soleil';

  @override
  String get coverDots => 'Points';

  @override
  String get coverLines => 'Lignes';

  @override
  String get untitled => 'Sans titre';

  @override
  String get defaultNotebookTitle => 'Mon cahier';

  @override
  String get createFromFile => 'Ou partez d’un fichier';

  @override
  String get createFromFileHint =>
      'Importez un PDF ou des photos et écrivez par-dessus chaque page.';

  @override
  String get createFromPdf => 'Depuis un PDF';

  @override
  String get createFromImages => 'Depuis des images';

  @override
  String get createFromFileRemove => 'Retirer le fichier';

  @override
  String createFromFilePages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get menuTwoFingerUndo => 'Annuler d’un toucher à deux doigts';

  @override
  String get popEraserAutoRevert =>
      'Revenir à l’outil précédent après avoir effacé';

  @override
  String get saveFailed =>
      'Impossible d’enregistrer la note. Libérez de l’espace : une nouvelle tentative aura lieu automatiquement.';

  @override
  String get tplHalfLetter => 'Demi-lettre';
}

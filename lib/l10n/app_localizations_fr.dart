// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Suivi des dépenses';

  @override
  String get navHome => 'Accueil';

  @override
  String get navExpenses => 'Dépenses';

  @override
  String get navLists => 'Listes';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Réglages';

  @override
  String get navBudget => 'Budget';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonConfirm => 'Confirmer';

  @override
  String get commonYes => 'Oui';

  @override
  String get commonNo => 'Non';

  @override
  String get commonUndo => 'Annuler';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonToday => 'Aujourd\'hui';

  @override
  String get commonYesterday => 'Hier';

  @override
  String get homeEmptyTitle => 'Aucune dépense';

  @override
  String get homeEmptyHint =>
      'Ajoutez votre première dépense avec le bouton ci-dessous';

  @override
  String get homeNoBudgetTitle => 'Mode budget désactivé';

  @override
  String homeNoBudgetHint(String monthTotal) {
    return '$monthTotal dépensés ce mois-ci';
  }

  @override
  String get homeEnableBudget => 'Activer le budget';

  @override
  String get homeAvailable => 'Disponible';

  @override
  String get homeSpent => 'Dépensé';

  @override
  String get homeRemaining => 'Restant';

  @override
  String homeCyclePeriod(String start, String end) {
    return 'Cycle $start – $end';
  }

  @override
  String homeDaysLeft(int count) {
    return '$count jour(s) restant(s)';
  }

  @override
  String homeDailyAllowance(int days, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other:
          '$days jours restants dans ce cycle — vous pouvez dépenser $amount/jour',
      one: '1 jour restant dans ce cycle — vous pouvez dépenser $amount/jour',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentExpenses => 'Dépenses récentes';

  @override
  String homeCycleEnded(String amount) {
    return 'Cycle terminé — restant $amount';
  }

  @override
  String get homeNegativeRemaining => 'Budget dépassé';

  @override
  String homeCarryOverLine(String amount) {
    return '+ Report du cycle précédent : $amount';
  }

  @override
  String get expenseAdd => 'Ajouter une dépense';

  @override
  String get expenseEdit => 'Modifier la dépense';

  @override
  String get expenseName => 'Nom';

  @override
  String get expenseNameHint => 'Qu\'avez-vous acheté ?';

  @override
  String get expenseAmount => 'Montant';

  @override
  String get expenseQuantity => 'Quantité';

  @override
  String get expenseUnitPrice => 'Prix unitaire';

  @override
  String get expenseCategory => 'Catégorie';

  @override
  String get expenseNoCategory => 'Non classé';

  @override
  String get expenseNote => 'Note';

  @override
  String get expenseMoreDetails => 'Plus de détails';

  @override
  String get expenseSaved => 'Dépense enregistrée';

  @override
  String get expenseDeleted => 'Dépense supprimée';

  @override
  String expenseDeleteConfirm(String amount) {
    return 'Supprimer cette dépense de $amount ?';
  }

  @override
  String get expenseInvalidAmount => 'Saisissez un montant valide';

  @override
  String get expenseInvalidQuantity => 'Saisissez une quantité valide';

  @override
  String get expenseInvalidName => 'Saisissez un nom';

  @override
  String get expenseSpentNow => 'Maintenant';

  @override
  String get expenseAmountComputed =>
      'Montant calculé : quantité × prix unitaire';

  @override
  String get expenseGroupMode => 'Achat groupé (même endroit)';

  @override
  String get expenseGroupModeHint =>
      'Les articles sont regroupés sous une seule carte. Ajoutez chaque article puis terminez.';

  @override
  String get expenseGroupNext => 'Enregistrer et ajouter le suivant';

  @override
  String expenseGroupDone(int count) {
    return 'Terminé ($count)';
  }

  @override
  String expenseGroupItems(int count) {
    return '$count article(s)';
  }

  @override
  String get expenseGroupTotal => 'Total du groupe';

  @override
  String get expensesEmpty => 'Aucune dépense';

  @override
  String get expensesSearch => 'Rechercher des dépenses';

  @override
  String get expensesFilterPeriod => 'Période';

  @override
  String get expensesFilterCategory => 'Catégorie';

  @override
  String get expensesAllCategories => 'Toutes les catégories';

  @override
  String get expensesDayTotal => 'Total du jour';

  @override
  String get expenseSourceShoppingList => 'Depuis une liste';

  @override
  String get budgetTitle => 'Budget';

  @override
  String get budgetDisabledTitle => 'Mode budget désactivé';

  @override
  String get budgetDisabledHint =>
      'Définissez un montant disponible par cycle pour suivre le restant.';

  @override
  String get budgetEnable => 'Activer le budget';

  @override
  String get budgetStartDay => 'Jour de début du cycle';

  @override
  String get budgetInitialAmount => 'Montant disponible par cycle';

  @override
  String get budgetDefaultAmount => 'Montant par défaut par cycle';

  @override
  String get budgetDefaultAmountHint =>
      'Utilisé comme montant de départ des futurs cycles.';

  @override
  String get budgetCarryOver => 'Reporter le solde restant au cycle suivant';

  @override
  String get budgetCarryOverHint =>
      'Si activé, l\'excédent (ou le déficit) passe au cycle suivant.';

  @override
  String get budgetCurrentCycle => 'Cycle actuel';

  @override
  String get budgetSpentInCycle => 'Dépensé dans ce cycle';

  @override
  String budgetCarryOverApplied(String amount) {
    return 'Report appliqué : $amount';
  }

  @override
  String get budgetStartFromToday => 'Commencer aujourd\'hui plutôt';

  @override
  String get budgetStartFromTodayHint =>
      'Le cycle commence aujourd\'hui et se termine avec la période en cours.';

  @override
  String get budgetEditAmount => 'Modifier le montant disponible (restant)';

  @override
  String get budgetEditAmountNote =>
      'Cette modification ne s\'applique qu\'au cycle actuel.';

  @override
  String get budgetStartNewCycleNow =>
      'Clôturer le cycle et en commencer un nouveau';

  @override
  String get budgetNewCycleConfirm =>
      'Clôturer le cycle actuel et en commencer un nouveau maintenant ?';

  @override
  String get budgetHistory => 'Historique des cycles';

  @override
  String get budgetCycleClosed => 'Fermé';

  @override
  String get budgetCycleActive => 'Actif';

  @override
  String get budgetDisable => 'Désactiver le budget';

  @override
  String get budgetDisableConfirm =>
      'Désactiver le mode budget ? Les cycles passés restent dans l\'historique.';

  @override
  String get budgetOverBudget =>
      'Vous avez dépensé plus que le montant disponible.';

  @override
  String get budgetDailyInfo =>
      'Ceci est un indicateur, pas une limite de dépense.';

  @override
  String get listsTitle => 'Listes de courses';

  @override
  String get listsEmpty => 'Aucune liste';

  @override
  String get listsNew => 'Nouvelle liste';

  @override
  String get listsNewName => 'Nom de la liste';

  @override
  String get listsCreate => 'Créer';

  @override
  String get listsAddItem => 'Ajouter un article';

  @override
  String get listItemName => 'Nom de l\'article';

  @override
  String get listItemEstPrice => 'Prix estimé';

  @override
  String get listEstimatedTotal => 'Total estimé';

  @override
  String listItemsWithoutEstimate(int count) {
    return '$count article(s) sans estimation';
  }

  @override
  String listVsRemaining(String total, String remaining) {
    return '$total sur $remaining restants';
  }

  @override
  String get listMarkPurchased => 'Acheté';

  @override
  String get listActualPrice => 'Prix réel';

  @override
  String listActualPriceHint(String estimated) {
    return 'Estimé $estimated';
  }

  @override
  String get listConvertQuestion => 'Enregistrer comme dépense maintenant ?';

  @override
  String get listConvertTitle => 'Convertir en dépense';

  @override
  String get listConverted => 'Enregistré comme dépense';

  @override
  String get listArchive => 'Archiver';

  @override
  String get listUnarchive => 'Désarchiver';

  @override
  String get listArchivedSection => 'Archivées';

  @override
  String get listDeleteItem => 'Retirer l\'article';

  @override
  String get listEmptyList => 'Cette liste est vide';

  @override
  String get statsTitle => 'Statistiques';

  @override
  String get statsToday => 'Aujourd\'hui';

  @override
  String get statsThisWeek => 'Cette semaine';

  @override
  String get statsThisMonth => 'Ce mois';

  @override
  String get statsThisCycle => 'Ce cycle';

  @override
  String get statsCustom => 'Personnalisé';

  @override
  String get statsTotalSpent => 'Total dépensé';

  @override
  String get statsAvgDaily => 'Moyenne par jour';

  @override
  String get statsByCategory => 'Dépenses par catégorie';

  @override
  String get statsTopDays => 'Jours de plus fortes dépenses';

  @override
  String get statsNoData => 'Aucune dépense sur cette période';

  @override
  String get statsUncategorized => 'Non classé';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsCurrency => 'Devise';

  @override
  String get settingsBudget => 'Réglages du budget';

  @override
  String get settingsPrivacy => 'Confidentialité';

  @override
  String get settingsData => 'Gestion des données';

  @override
  String get settingsBackupExport => 'Exporter une sauvegarde';

  @override
  String get settingsBackupExportHint =>
      'Enregistrer toutes vos données dans un seul fichier';

  @override
  String get settingsBackupRestore => 'Restaurer une sauvegarde';

  @override
  String get settingsBackupRestoreHint =>
      'Remplacer toutes les données actuelles par un fichier de sauvegarde';

  @override
  String get settingsBackupRestoreConfirm =>
      'Restaurer cette sauvegarde ? Toutes les données actuelles seront remplacées.';

  @override
  String get settingsBackupExported => 'Sauvegarde exportée';

  @override
  String get settingsBackupRestored => 'Sauvegarde restaurée';

  @override
  String get settingsBackupFailed =>
      'Échec de la sauvegarde. Veuillez réessayer.';

  @override
  String get settingsBackupInvalidFile =>
      'Ce fichier n\'est pas une sauvegarde valide.';

  @override
  String get settingsBackupTooNew =>
      'Cette sauvegarde provient d\'une version plus récente de l\'application. Mettez-la d\'abord à jour.';

  @override
  String get settingsPrivacyText =>
      'Toutes les données sont stockées localement sur cet appareil. L\'application fonctionne entièrement hors ligne et n\'envoie aucune information financière.';

  @override
  String get settingsPrivacyPolicy => 'Lire la politique de confidentialité';

  @override
  String get settingsClearData => 'Supprimer toutes les données';

  @override
  String get settingsClearDataConfirm =>
      'Supprimer définitivement toutes les dépenses, listes et historiques de budget sur cet appareil ?';

  @override
  String get settingsClearDataFinal => 'C\'est irréversible. Tout supprimer ?';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get aboutDevelopedBy => 'Développé par Amine Triki';

  @override
  String get firstRunTitle => 'Bienvenue';

  @override
  String get firstRunHint =>
      'Enregistrez ce que vous dépensez et comprenez ce qu\'il reste.';

  @override
  String get firstRunChooseCurrency => 'Choisissez votre devise';

  @override
  String get firstRunCurrencyHint => 'Modifiable plus tard dans les réglages.';

  @override
  String get firstRunStart => 'Commencer';

  @override
  String get privacyConsentTitle => 'Politique de confidentialité';

  @override
  String get privacyConsentMessage =>
      'Veuillez lire et accepter la politique de confidentialité avant d\'utiliser l\'application.';

  @override
  String get privacyReadPolicy => 'Lire la politique de confidentialité';

  @override
  String get privacyAccept => 'Accepter et continuer';

  @override
  String get privacyDecline => 'Refuser et quitter';

  @override
  String get errorInvalidInput => 'Entrée invalide';

  @override
  String get errorGeneric => 'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get catFood => 'Alimentation';

  @override
  String get catHome => 'Maison';

  @override
  String get catTransport => 'Transport';

  @override
  String get catBills => 'Factures';

  @override
  String get catHealth => 'Santé';

  @override
  String get catEntertainment => 'Loisirs';

  @override
  String get catOther => 'Autre';
}

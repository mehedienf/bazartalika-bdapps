import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const String _englishCode = 'en';
  static const String _bengaliCode = 'bn';

  static final AppSettings _instance = AppSettings._internal();
  factory AppSettings() => _instance;
  AppSettings._internal();

  String _currentLanguage = 'en';

  String get currentLanguage => _currentLanguage;

  // Access to SharedPreferences
  Future<SharedPreferences?> get prefs async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey) ?? 'en';
    if (_currentLanguage != savedLanguage) {
      _currentLanguage = savedLanguage;
      notifyListeners();
    }
  }

  Future<void> setLanguage(String language) async {
    if (language != _englishCode && language != _bengaliCode) {
      return;
    }
    if (_currentLanguage == language) {
      return;
    }
    _currentLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
    notifyListeners();
  }

  // Translation strings
  Map<String, Map<String, String>> get translations => {
    'en': {
      'app_language': 'Language',
      'enterPhoneNumber': 'Enter Phone Number',
      'robi_airtel_number': 'Robi/Airtel Number',
      'enterValidPhoneNumber': 'Please enter a valid 11-digit number',
      'enterOtpError': 'Please enter a valid 4-6 digit OTP.',
      'invalidOrExpiredOtp': 'Invalid or Expired OTP!',
      'verifyOtpAppBarTitle': 'OTP Verification',
      'verifyOtpTitle': 'Verify OTP',
      'otpSentToNumber': 'OTP sent to number',
      'subscriptionOtpPrompt': 'Enter the OTP to confirm your subscription.',
      'verifyOtpButton': 'Verify',
      'wrongNumberGoBack': 'Wrong number? Go back',

      'appName': 'App Name',
      'bazartalika': 'BazarTalika',
      'home': 'Home',
      'notes': 'Notes',
      'settings': 'Settings',
      'language': 'Language',
      'english': 'English',
      'bengali': 'Bengali',
      'about': 'About',
      'version': 'Version',
      'logout': 'Logout',
      'profile': 'Profile',
      'balance': 'Balance',
      'youWillGet': 'You\'ll Get',
      'youWillGive': 'You\'ll Give',
      'netBalance': 'Net Balance',
      'give': 'Give',
      'take': 'Take',
      'addPerson': 'Add Person',
      'personAdded': 'Person added',
      'deletePerson': 'Delete Person',
      'deleteNote': 'Delete Note',
      'editNote': 'Edit Note',
      'noNotes': 'No notes yet',
      'startTyping': 'Start typing...',
      'title': 'Title',
      'untitled': 'Untitled',
      'noContent': 'No content',
      'areYouSure': 'Are you sure?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'save': 'Save',
      'add': 'Add',
      'financialSummary': 'Total Summary',
      'noPersonsAdded': 'No persons added yet.',
      'pullDownToRefresh': 'Pull down to refresh',
      'workingOfflineSyncWhenOnline':
          'Working offline - Data will sync when online',
      'dataSyncedSuccessfully': 'Data synced successfully!',
      'connectionLostWorkingOffline': 'Connection lost! Working offline.',
      'workingOfflineUsingLocalData': 'Working offline - Using local data',
      'backgroundSyncEnabled': 'Background sync enabled',
      'backgroundSyncDisabled': 'Background sync disabled',
      'welcome': 'Welcome',
      'user': 'User',
      'lastSync': 'Last Sync',
      'never': 'Never',
      'tapToRetrySync': 'Tap to retry sync',
      'userProfile': 'User Profile',
      'close': 'Close',
      'notesSyncedSuccessfully': 'Notes synced successfully!',
      'tapToCreateNote': 'Tap + to create a note',
      'deleteNoteConfirm': 'Are you sure you want to delete this note?',
      'noteDeleted': 'Note deleted',
      'iGave': 'I Gave',
      'iTook': 'I Took',
      'transactionHistory': 'Transaction History',
      'noTransactionsYet': 'No transactions yet.',
      'deleteTransaction': 'Delete Transaction',
      'transactionAdded': 'Transaction added',
      'transactionDeleted': 'Transaction deleted',
      'deleteTransactionConfirm':
          'Are you sure you want to delete this transaction?',
      'amount': 'Amount',
      'enterAmount': 'Enter amount',
      'enterValidAmount': 'Enter valid amount',
      'noteOptional': 'Note (optional)',
      'errorLoadingData': 'Error loading data',
      'errorSaving': 'Error saving',
      'personName': 'Person name',
      'deletePersonConfirm': 'Are you sure you want to delete',
      'trackExpensesWithEase': 'Track your credit and debts with ease',
      'signingIn': 'Signing in...',
      'signInWithGoogle': 'Sign in with Google',
      'continueAsGuest': 'Continue as Guest',
      'automaticCloudBackup': 'Automatic cloud backup',
      'syncAcrossDevices': 'Sync across devices',
      'successfullySignedIn': 'Successfully signed in!',
      'signInCancelled': 'Sign in was cancelled',
      'signInFailed': 'Sign in failed',
      'networkErrorCheckConnection':
          'Network error. Please check your internet connection.',
      'googleSignInFailedTryAgain': 'Google Sign In failed. Please try again.',
      'signedInAsGuest': 'Signed in as guest!',
      'anonymousSignInFailed': 'Anonymous sign in failed',
      'logoutBackupSuccess': 'Backup completed before logout',
      'logoutBackupFailed':
          'Could not fully backup data before logout. Local data is kept.',
      'appDeveloperInfo': 'About App',
      'developerName': 'Developer',
      'companyName': 'Company',
      'Gave': 'Give',
      'Took': 'Take',
      'IncomeExpense': 'Expenses',
      'Transactions': 'Transactions',
      'totalIncome': 'Total Income',
      'totalExpense': 'Total Expense',
      'incomeExpenseSummary': 'Total Income & Expense Summary',
      'debitCreditSummary': 'Total Debit & Credit Summary',
      'income': 'Income',
      'expense': 'Expense',
      'deleteIncomeExpense': 'Delete Income/Expense',
      'deleteIncomeExpenseConfirm':
          'Are you sure you want to delete this income/expense?',
      'incomeExpenseDeleted': 'Income/Expense deleted!',
      'addTransaction': 'Add Transaction',
      'addIncomeExpense': 'Add Income/Expense',
      'to': 'to',
      'tobn': '',
      'from': 'from',
      'frombn': '',
      'backgroundSync': 'Background Sync',
      'backupPending': 'Backup pending',
      'noPendingBackup': 'No pending backup',
      'DataSavedLocally': 'Data saved locally',
      'nextButton': 'Next',
      'robiAirtelSubscribersOnly': 'Robi/Airtel subscribers only',
      'dailyChargeInfo': 'Charge 4 Taka + VAT+SD+SC/day',
      'resendOtpButton': 'Resend OTP',
      'dataSavedLocally': 'Data saved locally',
      'error_saving': 'Error saving',
      'no_active_budget_expense':
          'No active budget! Please create a budget first to add an expense.',
      'add_expense': 'Add Expense',
      'cannot_create_multiple_budgets':
          'You must delete or archive the active budget before creating a new one.',
      'create_budget': 'Create Budget',
      'duration_days': 'Duration (Days)',
      'enter_duration': 'Enter duration',
      'enter_valid_duration': 'Enter valid duration',
      'budget_amount': 'Budget Amount',
      'enter_budget_amount': 'Enter budget amount',
      'enter_valid_amount': 'Enter valid amount',
      'create': 'Create',
      'no_active_budget': 'No Active Budget',
      'remaining_budget': 'Remaining Budget',
      'duration_short_label': 'd',
      'days_left_label': 'days left',
      'delete_budget_title': 'Delete Budget',
      'delete_budget_confirm_1':
          'Are you sure you want to delete this budget of ৳',
      'delete_budget_confirm_2': '? This action cannot be undone.',
      'archive_budget_confirm_1':
          'Are you sure you want to archive this budget of ৳',
      'archive_budget_confirm_2':
          '? It will be moved to the archived budgets list.',
      'created_label': 'Created:',
      'duration': 'Duration:',
      'days': 'Days',
      'budget_label': 'Budget',
      'budget_details_archived': '(Archived)',
      'other_transactions': 'Other Transactions',
      'deleteConfirm': 'Are you sure you want to delete?',
      'deleteExpense': 'Delete Expense',
      'ExpenseDeleted': 'Expense Deleted!',
      'archive': 'Archive',
      'enableBackgroundSync': 'Enable Background Sync',
      'unsubscribe_success': 'You have been unsubscribed successfully.',
      'unsubscribe_failed': 'Unsubscription failed. Please try again.',
      'archived_label': 'Archived',
      'budget_deleted_msg': 'Budget deleted',
      'delete_expense_confirm': 'Are you sure you want to delete this expense?',
      'expense_added': 'Expense added',
      'ExpenseAdded': 'Expense added',
      'archive_budget_title': 'Archive Budget',
      'budget_archived_msg': 'Budget archived',
    },
    'bn': {
      'app_language': 'ভাষা',
      'budget_archived_msg': 'বাজেট আর্কাইভ করা হয়েছে',
      'archive_budget_title': 'বাজেট আর্কাইভ করুন',
      'ExpenseAdded': 'খরচ যোগ করা হয়েছে',
      'expense_added': 'খরচ যোগ করা হয়েছে',
      'delete_expense_confirm': 'আপনি কি এই খরচটি মুছতে চান?',
      'archived_label': 'আর্কাইভ করা হয়েছে',
      'budget_deleted_msg': 'বাজেট মুছে ফেলা হয়েছে',
      'unsubscribe_success': 'আপনি সফলভাবে আনসাবস্ক্রাইব করেছেন।',
      'unsubscribe_failed':
          'আনসাবস্ক্রাইব করতে ব্যর্থ হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।',
      'automaticCloudBackup': 'স্বয়ংক্রিয় ক্লাউড ব্যাকআপ',
      'syncAcrossDevices': 'সব ডিভাইসে সিঙ্ক',
      'successfullySignedIn': 'সফলভাবে সাইন ইন হয়েছে!',
      'signInCancelled': 'সাইন ইন বাতিল হয়েছে',
      'signInFailed': 'সাইন ইন ব্যর্থ হয়েছে',
      'networkErrorCheckConnection':
          'নেটওয়ার্ক সমস্যা। ইন্টারনেট সংযোগ পরীক্ষা করুন।',
      'googleSignInFailedTryAgain':
          'গুগল সাইন ইন ব্যর্থ হয়েছে। আবার চেষ্টা করুন।',
      'signedInAsGuest': 'গেস্ট হিসেবে সাইন ইন হয়েছে!',
      'anonymousSignInFailed': 'গেস্ট সাইন ইন ব্যর্থ হয়েছে',
      'logoutBackupSuccess': 'লগআউটের আগে ব্যাকআপ সম্পন্ন হয়েছে',
      'logoutBackupFailed':
          'লগআউটের আগে সম্পূর্ণ ব্যাকআপ করা যায়নি। লোকাল ডাটা রাখা হয়েছে।',
      'appDeveloperInfo': 'অ্যাপ সম্পর্কে',
      'developerName': 'ডেভেলপার',
      'companyName': 'কোম্পানি',
      'enableBackgroundSync': 'ব্যাকগ্রাউন্ড সিঙ্ক চালু করুন',
      'robiAirtelSubscribersOnly': 'শুধুমাত্র রবি/এয়ারটেল গ্রাহক',
      'dailyChargeInfo': 'চার্জ 4 টাকা + VAT+SD+SC/দিন',
      'resendOtpButton': 'OTP পুনরায় পাঠান',
      'nextButton': 'পরবর্তী',
      'enterPhoneNumber': 'ফোন নম্বর লিখুন',
      'robi_airtel_number': 'রবি/এয়ারটেল নম্বর',
      'enterValidPhoneNumber': 'অনুগ্রহ করে সঠিক ১১-ডিজিটের নম্বর দিন',
      'enterOtpError': 'দয়া করে ৪-৬ ডিজিটের সঠিক OTP দিন।',
      'invalidOrExpiredOtp': 'ভুল অথবা মেয়াদোত্তীর্ণ OTP!',
      'verifyOtpAppBarTitle': 'OTP যাচাইকরণ',
      'verifyOtpTitle': 'OTP ভেরিফাই করুন',
      'otpSentToNumber': 'নম্বরে পাঠানো হয়েছে',
      'subscriptionOtpPrompt': 'সাবস্ক্রিপশন নিশ্চিত করতে OTP দিয়ে যাচাই করুন।',
      'verifyOtpButton': 'যাচাই করুন',
      'wrongNumberGoBack': 'ভুল নম্বর? ফিরে যান',

      'appName': 'অ্যাপের নাম',
      'bazartalika': 'বাজারতালিকা',
      'home': 'হোম',
      'notes': 'নোট',
      'settings': 'সেটিংস',
      'language': 'ভাষা',
      'english': 'English',
      'bengali': 'বাংলা',
      'about': 'সম্পর্কে',
      'version': 'সংস্করণ',
      'logout': 'লগ আউট',
      'profile': 'প্রোফাইল',
      'balance': 'ব্যালেন্স',
      'youWillGet': 'আপনি পাবেন',
      'youWillGive': 'আপনি দেবেন',
      'netBalance': 'নেট ব্যালেন্স',
      'give': 'দেয়',
      'take': 'নেয়',
      'addPerson': 'ব্যক্তি যোগ করুন',
      'personAdded': 'ব্যক্তি যোগ করা হয়েছে',
      'deletePerson': 'ব্যক্তি মুছুন',
      'deleteNote': 'নোট মুছুন',
      'editNote': 'নোট সম্পাদনা করুন',
      'noNotes': 'এখনো কোন নোট নেই',
      'startTyping': 'লেখা শুরু করুন...',
      'title': 'শিরোনাম',
      'untitled': 'শিরোনামহীন',
      'noContent': 'কোন কন্টেন্ট নেই',
      'areYouSure': 'আপনি কি নিশ্চিত?',
      'cancel': 'বাতিল',
      'delete': 'মুছুন',
      'save': 'সংরক্ষণ',
      'add': 'যোগ করুন',
      'financialSummary': 'মোট হিসাব সংক্ষেপ',
      'noPersonsAdded': 'এখনো কোন ব্যক্তি যোগ করা হয়নি।',
      'pullDownToRefresh': 'রিফ্রেশ করতে নিচে টানুন',
      'workingOfflineSyncWhenOnline':
          'অফলাইনে চলছে - অনলাইনে এলে ডাটা সিঙ্ক হবে',
      'dataSyncedSuccessfully': 'ডাটা সফলভাবে সিঙ্ক হয়েছে!',
      'connectionLostWorkingOffline': 'সংযোগ বিচ্ছিন্ন! অফলাইনে চলছে।',
      'workingOfflineUsingLocalData':
          'অফলাইনে চলছে - লোকাল ডাটা ব্যবহার করা হচ্ছে',
      'backgroundSyncEnabled': 'ব্যাকগ্রাউন্ড সিঙ্ক চালু হয়েছে',
      'backgroundSyncDisabled': 'ব্যাকগ্রাউন্ড সিঙ্ক বন্ধ হয়েছে',
      'welcome': 'স্বাগতম',
      'user': 'ব্যবহারকারী',
      'lastSync': 'সর্বশেষ সিঙ্ক',
      'never': 'কখনও না',
      'tapToRetrySync': 'পুনরায় সিঙ্ক করতে ট্যাপ করুন',
      'userProfile': 'ব্যবহারকারীর প্রোফাইল',
      'close': 'বন্ধ করুন',
      'notesSyncedSuccessfully': 'নোট সফলভাবে সিঙ্ক হয়েছে!',
      'tapToCreateNote': 'নোট তৈরি করতে + চাপুন',
      'deleteNoteConfirm': 'আপনি কি এই নোটটি মুছতে চান?',
      'noteDeleted': 'নোট মুছে ফেলা হয়েছে',
      'iGave': 'আমি দিয়েছি',
      'iTook': 'আমি নিয়েছি',
      'transactionHistory': 'লেনদেনের ইতিহাস',
      'noTransactionsYet': 'এখনও কোনো লেনদেন নেই।',
      'deleteTransaction': 'লেনদেন মুছুন',
      'transactionAdded': 'লেনদেন যোগ করা হয়েছে',
      'transactionDeleted': 'লেনদেন মুছে ফেলা হয়েছে',
      'deleteTransactionConfirm': 'আপনি কি এই লেনদেনটি মুছতে চান?',
      'amount': 'পরিমাণ',
      'enterAmount': 'পরিমাণ লিখুন',
      'enterValidAmount': 'সঠিক পরিমাণ লিখুন',
      'noteOptional': 'নোট (ঐচ্ছিক)',
      'errorLoadingData': 'ডাটা লোড করতে সমস্যা হয়েছে',
      'errorSaving': 'সংরক্ষণে সমস্যা হয়েছে',
      'personName': 'ব্যক্তির নাম',
      'deletePersonConfirm': 'আপনি কি মুছতে চান',
      'trackExpensesWithEase': 'সহজে আপনার দেনা পাওনা ট্র্যাক করুন',
      'signingIn': 'সাইন ইন হচ্ছে...',
      'signInWithGoogle': 'গুগল দিয়ে সাইন ইন করুন',
      'continueAsGuest': 'গেস্ট হিসেবে চালিয়ে যান',
      'Gave': 'দিলাম',
      'Took': 'নিলাম',
      'IncomeExpense': 'আয়ব্যয়',
      'Transactions': 'লেনদেন',
      'totalIncome': 'আয় করেছেন',
      'totalExpense': 'ব্যয় করেছেন',
      'incomeExpenseSummary': 'মোট আয় ও ব্যয়ের সংক্ষেপ',
      'debitCreditSummary': 'মোট দেনা ও পাওনার সংক্ষেপ',
      'income': 'আয়',
      'expense': 'ব্যয়',
      'deleteIncomeExpense': 'আয়/ব্যয় মুছুন',
      'deleteIncomeExpenseConfirm': 'আপনি কি এই আয়/ব্যয়টি মুছতে চান?',
      'incomeExpenseDeleted': 'আয়/ব্যয় মুছে ফেলা হয়েছে!',
      'addTransaction': 'লেনদেন যোগ করুন',
      'addIncomeExpense': 'আয়/ব্যয় যোগ করুন',
      'to': '',
      'tobn': 'কে',
      'from': '',
      'frombn': 'থেকে',
      'backgroundSync': 'ব্যাকগ্রাউন্ড সিঙ্ক',
      'backupPending': 'ব্যাকআপ বাকি',
      'noPendingBackup': 'কোন ব্যাকআপ বাকি নেই',
      'DataSavedLocally': 'ডাটা লোকালি সংরক্ষণ করা হয়েছে',
      'dataSavedLocally': 'ডেটা লোকালি সেভ হয়েছে',
      'error_saving': 'সেভ করতে সমস্যা হয়েছে',
      'no_active_budget_expense':
          'কোনো সক্রিয় বাজেট নেই! খরচ যোগ করার আগে একটি বাজেট তৈরি করুন।',
      'add_expense': 'খরচ যোগ করুন',
      'cannot_create_multiple_budgets':
          'নতুন একটি তৈরি করার আগে বর্তমান সক্রিয় বাজেট মুছতে বা আর্কাইভ করতে হবে।',
      'create_budget': 'বাজেট তৈরি করুন',
      'duration_days': 'মেয়াদ (দিন)',
      'enter_duration': 'মেয়াদ উল্লেখ করুন',
      'enter_valid_duration': 'সঠিক মেয়াদ দিন',
      'budget_amount': 'বাজেটের পরিমাণ',
      'enter_budget_amount': 'বাজেটের পরিমাণ লিখুন',
      'enter_valid_amount': 'সঠিক পরিমাণ দিন',
      'create': 'তৈরি করুন',
      'no_active_budget': 'কোনো সক্রিয় বাজেট নেই',
      'remaining_budget': 'অবশিষ্ট বাজেট',
      'duration_short_label': 'দিন',
      'days_left_label': 'দিন বাকি',
      'delete_budget_title': 'বাজেট মুছুন',
      'delete_budget_confirm_1': 'আপনি কি ৳',
      'delete_budget_confirm_2':
          ' এর এই বাজেটটি মুছতে চান? মুছে ফেললে পুনরায় ফিরিয়ে আনা সম্ভব না।',
      'archive_budget_confirm_1': 'আপনি কি ৳',
      'archive_budget_confirm_2':
          ' এর এই বাজেটটি আর্কাইভ করতে চান? এটি পূর্ববর্তী বাজেটের তালিকায় স্থানান্তরিত হবে।',
      'created_label': 'তৈরি:',
      'duration': 'মেয়াদ:',
      'days': 'দিন',
      'budget_label': 'বাজেট',
      'budget_details_archived': '(আর্কাইভ করা হয়েছে)',
      'other_transactions': 'অন্যান্য লেনদেন',
      'deleteConfirm': 'আপনি কি নিশ্চিতভাবে মুছতে চান?',
      'deleteExpense': 'খরচ মুছুন',
      'ExpenseDeleted': 'খরচ মুছে ফেলা হয়েছে!',
      'archive': 'আর্কাইভ',
    },
  };

  String get(String key) {
    final currentMap = translations[_currentLanguage] ?? {};
    final englishMap = translations['en'] ?? {};

    if (currentMap.containsKey(key)) {
      return currentMap[key]!;
    }
    if (englishMap.containsKey(key)) {
      return englishMap[key]!;
    }

    final normalizedRequested = _normalizeKey(key);

    for (final entry in currentMap.entries) {
      if (_normalizeKey(entry.key) == normalizedRequested) {
        return entry.value;
      }
    }

    for (final entry in englishMap.entries) {
      if (_normalizeKey(entry.key) == normalizedRequested) {
        return entry.value;
      }
    }

    return key;
  }

  String _normalizeKey(String key) {
    return key.replaceAll(RegExp(r'\s+|_'), '').toLowerCase();
  }
}

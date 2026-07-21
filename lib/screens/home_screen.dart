import 'dart:convert';
import 'dart:async';
// import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/bazar_item.dart';
import '../models/bazar_list.dart';
import '../models/category.dart';
import '../services/database_helper.dart';
import '../widgets/bazar_item_tile.dart';
import 'archive_screen.dart';

const String _baseUrl = "https://bdapps.flicksize.com/smartlisting/api/";

enum SortOption { manual, dateAsc, dateDesc, alphaAsc, alphaDesc }

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onDarkModeToggle;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onDarkModeToggle,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _quickAddNameController = TextEditingController();
  final TextEditingController _quickAddPriceController =
      TextEditingController();
  final TextEditingController _newListController = TextEditingController();
  final FocusNode _quickAddFocusNode = FocusNode();
  Category? _quickAddCategory;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final List<Category> _defaultSeedCategories = [
    Category('সবজি (Vegetables)'),
    Category('মাছ (Fish)'),
    Category('মাংস (Meat)'),
    Category('মসলা (Spices)'),
    Category('অন্যান্য (Others)'),
  ];
  final List<Category> _categories = [];
  final List<BazarItem> _items = [];
  Category? _selectedFilterCategory;
  SortOption _currentSortOption = SortOption.manual;

  final List<BazarList> _lists = [];
  BazarList? _selectedList;
  int? _selectedListId;

  // BannerAd? _bannerAd;
  // bool _isAdLoaded = false;
  // bool _isAdLoading = false;

  // final String _adUnitId = Platform.isAndroid
  //     ? 'ca-app-pub-3867432578176290/3476561839' // Real Ad Unit ID (Production)
  //     : 'ca-app-pub-3867432578176290/3476561839'; // Real Ad Unit ID (Production)
  // ? 'ca-app-pub-3940256099942544/6300978111' // Test Ad Unit ID (Android)
  // : 'ca-app-pub-3940256099942544/2934735716'; // Test Ad Unit ID (iOS)

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   // if (!_isAdLoaded && !_isAdLoading) {
    //   //   // _loadAd();
    //   // }
    // });
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final savedFilterCategory = prefs.getString('selected_filter_category');
    final savedSortOption = prefs.getInt('current_sort_option');
    final savedListId = prefs.getInt('selected_list_id');

    setState(() {
      if (savedSortOption != null &&
          savedSortOption >= 0 &&
          savedSortOption < SortOption.values.length) {
        _currentSortOption = SortOption.values[savedSortOption];
      }
    });

    _selectedListId = savedListId;
    await _loadLists();

    // After loading lists, try setting the saved filter category if it exists in the new _categories
    setState(() {
      if (savedFilterCategory != null && savedFilterCategory.isNotEmpty) {
        try {
          _selectedFilterCategory = _categories.firstWhere(
            (cat) => cat.name == savedFilterCategory,
          );
        } catch (_) {
          _selectedFilterCategory = null;
        }
      }
    });
  }

  Future<void> _saveFilterCategory(Category? category) async {
    final prefs = await SharedPreferences.getInstance();
    if (category != null) {
      await prefs.setString('selected_filter_category', category.name);
    } else {
      await prefs.remove('selected_filter_category');
    }
  }

  Future<void> _saveSortOption(SortOption option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_sort_option', option.index);
  }

  Future<void> _showSortDialog() async {
    final result = await showDialog<SortOption>(
      context: context,
      builder: (ctx) {
        Widget buildOption(String label, SortOption option) {
          final isSelected = _currentSortOption == option;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: ListTile(
              dense: true,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              selected: isSelected,
              selectedColor: Theme.of(context).primaryColor,
              selectedTileColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.15),
              title: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () => Navigator.pop(ctx, option),
            ),
          );
        }

        return AlertDialog(
          title: const Text('সজানো (Sort)'),
          contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildOption('নিজের মতো (Manual)', SortOption.manual),
              buildOption('আগে যোগ করা (Date Asc)', SortOption.dateAsc),
              buildOption('নতুন যোগ করা (Date Desc)', SortOption.dateDesc),
              buildOption('নাম অনুযায়ী (A - Z)', SortOption.alphaAsc),
              buildOption('নাম অনুযায়ী (Z - A)', SortOption.alphaDesc),
            ],
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _currentSortOption = result;
        _saveSortOption(result);
      });
    }
  }

  Future<void> _saveSelectedListId(int? listId) async {
    final prefs = await SharedPreferences.getInstance();
    if (listId != null) {
      await prefs.setInt('selected_list_id', listId);
    } else {
      await prefs.remove('selected_list_id');
    }
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'bazar_categories_${_selectedListId ?? "default"}';
    await prefs.setStringList(key, _categories.map((c) => c.name).toList());
  }

  Future<void> _loadCategoriesForCurrentList() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'bazar_categories_${_selectedListId ?? "default"}';
    final List<String>? savedCategories = prefs.getStringList(key);

    setState(() {
      _categories.clear();
      if (savedCategories != null) {
        for (var catName in savedCategories) {
          _categories.add(Category(catName));
        }
      } else {
        bool isDefaultList =
            _selectedListId == null || _selectedList?.name == 'আমার লিস্ট';

        if (isDefaultList) {
          _categories.addAll(_defaultSeedCategories);
        } else {
          _categories.add(Category('অন্যান্য (Others)'));
        }
        _saveCategories();
      }

      // Reset currently selected filter if it's no longer in the categories list
      if (_selectedFilterCategory != null &&
          !_categories.any((c) => c.name == _selectedFilterCategory!.name)) {
        _selectedFilterCategory = null;
        _saveFilterCategory(null);
      }
    });
  }

  Future<void> _migrateFromPrefsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final String? itemsJson = prefs.getString('bazar_items');

    if (itemsJson != null) {
      final List<dynamic> decodedData = jsonDecode(itemsJson);
      final migratedItems = decodedData
          .map((e) => BazarItem.fromJson(e))
          .toList();

      for (var item in migratedItems) {
        await DatabaseHelper.instance.insertItem(item);
      }

      await prefs.remove('bazar_items');
    }
  }

  Future<void> _updateSelectedListFromLists() async {
    if (_lists.isNotEmpty) {
      if (_selectedListId != null) {
        try {
          _selectedList = _lists.firstWhere(
            (list) => list.id == _selectedListId,
          );
        } catch (_) {
          _selectedList = _lists.first;
          _selectedListId = _selectedList!.id;
          await _saveSelectedListId(_selectedListId);
        }
      } else {
        _selectedList = _lists.first;
        _selectedListId = _selectedList!.id;
        await _saveSelectedListId(_selectedListId);
      }
    } else {
      _selectedList = null;
      _selectedListId = null;
      await _saveSelectedListId(null);
    }
  }

  Future<void> _loadLists() async {
    final lists = await DatabaseHelper.instance.getAllLists();
    setState(() {
      _lists.clear();
      _lists.addAll(lists);
    });

    await _updateSelectedListFromLists();
    await _loadCategoriesForCurrentList();

    if (_selectedList != null) {
      await _loadItemsForSelectedList();
    } else {
      setState(() {
        _items.clear();
      });
    }
  }

  Future<void> _loadItemsForSelectedList() async {
    await _migrateFromPrefsIfNeeded();
    if (_selectedListId == null) {
      setState(() {
        _items.clear();
      });
      return;
    }
    final dbItems = await DatabaseHelper.instance.getAllItems(
      listId: _selectedListId,
    );
    setState(() {
      _items.clear();
      _items.addAll(dbItems.where((item) => !item.isArchived));
    });
  }

  Future<void> _loadItems() async {
    await _loadItemsForSelectedList();
  }

  Future<void> _addItem(BazarItem item) async {
    if (_selectedListId == null) {
      final newList = BazarList(name: 'আমার লিস্ট');
      final newId = await DatabaseHelper.instance.insertList(newList);
      _selectedListId = newId;
      await _saveSelectedListId(newId);
      await _loadLists();
    }

    if (_selectedListId != null) {
      item.listId = _selectedListId;
      final id = await DatabaseHelper.instance.insertItem(item);
      item.id = id;
      setState(() {
        _items.add(item);
      });
    }
  }

  Future<void> _updateItem(BazarItem item) async {
    if (item.id != null) {
      await DatabaseHelper.instance.updateItem(item);
    }
    setState(() {}); // Trigger rebuild
  }

  Future<void> _deleteItem(BazarItem item) async {
    if (item.id != null) {
      // Don't fully delete from DB if we want undo. Let's just remove from state
      // and do final delete on snackbar close, or soft delete.
      // For simplicity, delete here, re-insert on undo.
      await DatabaseHelper.instance.deleteItem(item.id!);
    }
    setState(() {
      _items.remove(item);
    });
  }

  Future<void> _undoDelete(BazarItem item) async {
    final id = await DatabaseHelper.instance.insertItem(item);
    item.id = id;
    setState(() {
      _items.add(item);
    });
  }

  Future<void> _confirmArchiveList() async {
    if (_selectedList == null) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('লিস্ট আর্কাইভ করতে চান?'),
        content: const Text(
          'এই লিস্ট এবং এর সব আইটেম আর্কাইভে চলে যাবে। আপনি কি নিশ্চিত?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('হ্যাঁ', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );

    if (result == true) {
      await DatabaseHelper.instance.archiveList(_selectedList!.id!);
      _selectedListId = null;
      await _saveSelectedListId(null);
      await _loadLists();
    }
  }

  Future<void> _createNewList() async {
    _newListController.clear();
    String? errorMessage;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('নতুন লিস্ট'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _newListController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'লিস্টের নাম',
                  errorText: errorMessage,
                ),
                onChanged: (_) {
                  if (errorMessage != null) {
                    setState(() => errorMessage = null);
                  }
                },
                onSubmitted: (_) {
                  if (_newListController.text.trim().isEmpty) {
                    setState(
                      () => errorMessage = 'লিস্টের নাম ফাঁকা রাখা যাবে না',
                    );
                  } else {
                    Navigator.of(ctx).pop(true);
                  }
                },
              ),
              const SizedBox(height: 12),
              ActionChip(
                avatar: const Icon(Icons.date_range, size: 16),
                label: const Text('আজকের তারিখ'),
                onPressed: () {
                  final now = DateTime.now();
                  final dateStr =
                      '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
                  final currentText = _newListController.text;
                  _newListController.text = currentText.isEmpty
                      ? dateStr
                      : '$currentText $dateStr';
                  _newListController.selection = TextSelection.fromPosition(
                    TextPosition(offset: _newListController.text.length),
                  );
                  if (errorMessage != null) {
                    setState(() => errorMessage = null);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('বাতিল'),
            ),
            TextButton(
              onPressed: () {
                if (_newListController.text.trim().isEmpty) {
                  setState(
                    () => errorMessage = 'লিস্টের নাম ফাঁকা রাখা যাবে না',
                  );
                } else {
                  Navigator.of(ctx).pop(true);
                }
              },
              child: const Text(
                'তৈরি করুন',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );

    final newListName = _newListController.text.trim();
    if (result == true && newListName.isNotEmpty) {
      final newList = BazarList(name: newListName);
      final id = await DatabaseHelper.instance.insertList(newList);
      _selectedListId = id;
      await _saveSelectedListId(id);
      await _loadLists();
    }
  }

  Future<void> _unsubscribe() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('userPhone') ?? '';

    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone not found!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsubscribing'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    // Hold a reference to the loader dialog so we can reliably close it.
    bool loaderOpen = true;
    final loaderContext = context;
    showDialog<void>(
      context: loaderContext,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );

    Future<void> closeLoader() async {
      if (!loaderOpen) return;
      loaderOpen = false;
      if (!mounted) return;
      // Guard against pop when no dialog actually exists on the navigator.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }

    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/unsubscribe.php'),
            body: {'user_mobile': phone},
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;
      await closeLoader();

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final dynamic decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response shape');
      }
      final data = decoded;
      final statusCode = data['statusCode']?.toString() ?? '';
      final statusDetail = data['statusDetail']?.toString() ?? '';
      final successFlag = data['success'] == true;
      final subscriptionStatus =
          (data['subscriptionStatus']?.toString() ?? '').toUpperCase();

      final success =
          successFlag ||
          statusCode == 'S1000' ||
          subscriptionStatus == 'UNREGISTERED';

      if (success) {
        // Clear auth state before navigating so the cold-start guard in
        // main.dart doesn't read a stale `isLoggedIn` flag.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', false);
        await prefs.remove('userPhone');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unsubscribing success!'),
            backgroundColor: Colors.green,
          ),
        );

        // Use the named route already registered in main.dart — this avoids
        // building a new LoginPage widget ad-hoc and bypasses history quirks
        // that triggered `_history.isNotEmpty` assertion failures.
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(statusDetail.isNotEmpty
                ? statusDetail
                : 'Unsubscribing failed'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      await closeLoader();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timeout error!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await closeLoader();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showListOptionsModal(BazarList list) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                list.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.archive, color: Colors.orange),
              title: const Text('লিস্ট আর্কাইভ করুন'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmArchiveSpecificList(list);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('লিস্ট মুছুন'),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteList(list);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmArchiveSpecificList(BazarList list) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('লিস্ট আর্কাইভ করতে চান?'),
        content: Text(
          '"${list.name}" এবং এর সব আইটেম আর্কাইভে চলে যাবে। আপনি কি নিশ্চিত?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('না'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('হ্যাঁ', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (result == true) {
      await DatabaseHelper.instance.archiveList(list.id!);
      if (_selectedListId == list.id) {
        _selectedListId = null;
        await _saveSelectedListId(null);
      }
      await _loadLists();
    }
  }

  Future<void> _confirmDeleteList(BazarList list) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('লিস্ট মুছতে চান?'),
        content: Text(
          '"${list.name}" এবং এর ভিতরের সব আইটেম চিরতরে মুছে যাবে। আপনি কি নিশ্চিত?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('মুছুন', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await DatabaseHelper.instance.deleteList(list.id!);
      if (_selectedListId == list.id) {
        _selectedListId = null;
        await _saveSelectedListId(null);
      }
      await _loadLists();
    }
  }

  Future<void> _shareList() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('শেয়ার করার জন্য কোনো আইটেম নেই')),
      );
      return;
    }

    final buffer = StringBuffer();
    final listName = _selectedList?.name ?? 'বাজার তালিকা (Bazar List)';
    buffer.writeln('$listName:');
    buffer.writeln('-------------------------------------------');

    double totalActivePrice = 0.0;
    double totalBoughtPrice = 0.0;

    Map<String, List<BazarItem>> categoryGroups = {};
    for (var item in _items) {
      final cat = item.category?.name ?? 'অন্যান্য (Others)';
      categoryGroups.putIfAbsent(cat, () => []).add(item);
    }

    final sortedCategories = categoryGroups.keys.toList()..sort();

    for (var cat in sortedCategories) {
      buffer.writeln('\n[$cat]');
      for (var item in categoryGroups[cat]!) {
        buffer.write('- ${item.name}');
        if (item.price != null && item.price! > 0) {
          buffer.write(' (৳${item.price})');
          if (item.isBought) {
            totalBoughtPrice += item.price!;
          } else {
            totalActivePrice += item.price!;
          }
        }
        if (item.isBought) {
          buffer.write(' [✓]');
        }
        buffer.writeln();
      }
    }

    if (totalActivePrice > 0 || totalBoughtPrice > 0) {
      buffer.writeln('\n-------------------------------------------');
      if (totalActivePrice > 0) {
        buffer.writeln('বাকি আছে (Remaining): ৳$totalActivePrice');
      }
      if (totalBoughtPrice > 0) {
        buffer.writeln('কেনা সম্পন্ন (Done): ৳$totalBoughtPrice');
      }
      final grandTotal = totalActivePrice + totalBoughtPrice;
      if (totalActivePrice > 0 && totalBoughtPrice > 0) {
        buffer.writeln('সর্বমোট (Total): ৳$grandTotal');
      }
    }

    await SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  // Future<void> _loadAd() async {
  //   _isAdLoading = true;
  //   final screenWidth = MediaQuery.of(context).size.width.truncate();

  //   final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(
  //     screenWidth > 0 ? screenWidth : 320,
  //   );

  //   if (size == null) {
  //     debugPrint('Unable to get adaptive banner size.');
  //     _isAdLoading = false;
  //     return;
  //   }

  //   // _bannerAd = BannerAd(
  //   //   adUnitId: _adUnitId,
  //   //   request: const AdRequest(),
  //   //   size: size,
  //   //   listener: BannerAdListener(
  //   //     onAdLoaded: (ad) {
  //   //       debugPrint('$ad loaded.');
  //   //       setState(() {
  //   //         _isAdLoaded = true;
  //   //         _isAdLoading = false;
  //   //       });
  //   //     },
  //   //     onAdFailedToLoad: (ad, err) {
  //   //       debugPrint('BannerAd failed to load: $err');
  //   //       _isAdLoading = false;
  //   //       ad.dispose();
  //   //     },
  //   //   ),
  //   // )..load();
  // }

  @override
  void dispose() {
    _quickAddNameController.dispose();
    _quickAddPriceController.dispose();
    _newListController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _quickAddFocusNode.dispose();
    // _bannerAd?.dispose();
    super.dispose();
  }

  void _handleQuickAdd() {
    final name = _quickAddNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('পণ্যের নাম প্রয়োজন')));
      return;
    }

    final priceText = _quickAddPriceController.text.trim();
    final price = priceText.isNotEmpty ? double.tryParse(priceText) : null;

    _addItem(
      BazarItem(
        name: name,
        price: price,
        category:
            _quickAddCategory ??
            (_selectedFilterCategory != null &&
                    _selectedFilterCategory!.name != 'সব (All)'
                ? _selectedFilterCategory
                : _categories.firstWhere(
                    (c) => c.name == 'অন্যান্য (Others)',
                    orElse: () => _categories.first,
                  )),
      ),
    );

    _quickAddNameController.clear();
    _quickAddPriceController.clear();
    setState(() {
      _quickAddCategory = null;
    });
    _quickAddFocusNode.requestFocus();
  }

  void _showAddCategoryDialog(Function(String) onCategoryAdded) {
    final catController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('নতুন ক্যাটাগরি তৈরি করুন'),
        content: TextField(
          controller: catController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'ক্যাটাগরির নাম'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () {
              final newCat = catController.text.trim();
              if (newCat.isNotEmpty) {
                onCategoryAdded(newCat);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('তৈরি করুন'),
          ),
        ],
      ),
    );
  }

  void _showEditPriceDialog(BazarItem item) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(
      text: item.price != null ? item.price.toString() : '',
    );
    Category? selectedCategory = item.category;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('আইটেম সম্পাদনা করুন'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  // autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'পণ্যের নাম',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'দাম (৳)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Category>(
                  decoration: const InputDecoration(
                    labelText: 'ক্যাটাগরি',
                    border: OutlineInputBorder(),
                  ),
                  initialValue: selectedCategory,
                  items: _categories.map((Category cat) {
                    return DropdownMenuItem<Category>(
                      value: cat,
                      child: Text(cat.name),
                    );
                  }).toList(),
                  onChanged: (Category? newValue) {
                    setDialogState(() {
                      selectedCategory = newValue;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('বাতিল'),
            ),
            TextButton(
              onPressed: () {
                final nameText = nameController.text.trim();
                if (nameText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('পণ্যের নাম প্রয়োজন')),
                  );
                  return;
                }

                final priceText = priceController.text.trim();
                final updatedItem = BazarItem(
                  id: item.id,
                  listId: item.listId,
                  name: nameText,
                  price: priceText.isNotEmpty
                      ? double.tryParse(priceText)
                      : null,
                  category: selectedCategory,
                  isBought: item.isBought,
                  isArchived: item.isArchived,
                  createdAt: item.createdAt,
                  originalCreatedAt: item.originalCreatedAt,
                );

                // Update the item in the list
                final index = _items.indexWhere(
                  (element) => element.id == item.id,
                );
                if (index != -1) {
                  _items[index] = updatedItem;
                }

                _updateItem(updatedItem);
                Navigator.of(ctx).pop();
                setState(() {});
              },
              child: const Text('সেভ করুন'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditOrDeleteCategoryDialog(
    Category cat, {
    VoidCallback? onDeleted,
  }) {
    if (cat.name == 'অন্যান্য (Others)') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'এই ক্যাটাগরিটি ডিফল্ট, তাই এটি এডিট বা মুছে ফেলা যাবে না।',
          ),
        ),
      );
      return;
    }

    final editController = TextEditingController(text: cat.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ক্যাটাগরি সম্পাদনা'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: editController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'ক্যাটাগরির নাম',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _categories.remove(cat);
                _saveCategories();
                if (_selectedFilterCategory == cat) {
                  _selectedFilterCategory = null;
                  _saveFilterCategory(null);
                }
                if (_quickAddCategory == cat) {
                  _quickAddCategory = null;
                }
                for (var item in _items) {
                  if (item.category == cat) {
                    item.category = null;
                    _updateItem(item);
                  }
                }
              });
              if (onDeleted != null) {
                onDeleted();
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('ডিলিট', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              final newName = editController.text.trim();
              if (newName.isNotEmpty && newName != cat.name) {
                final newCat = Category(newName);
                setState(() {
                  final index = _categories.indexOf(cat);
                  if (index != -1) {
                    _categories[index] = newCat;
                  }
                  _saveCategories();

                  if (_selectedFilterCategory == cat) {
                    _selectedFilterCategory = newCat;
                    _saveFilterCategory(newCat);
                  }
                  if (_quickAddCategory == cat) {
                    _quickAddCategory = newCat;
                  }
                  for (var item in _items) {
                    if (item.category == cat) {
                      item.category = newCat;
                      _updateItem(item);
                    }
                  }
                });
              }
              Navigator.of(ctx).pop();
            },
            child: const Text(
              'আপডেট করুন',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _items.where((item) {
      if (_selectedFilterCategory != null &&
          item.category != _selectedFilterCategory) {
        return false;
      }

      if (_isSearching && _searchController.text.isNotEmpty) {
        final searchQuery = _searchController.text.toLowerCase();
        if (!item.name.toLowerCase().contains(searchQuery)) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sorting Logic
    switch (_currentSortOption) {
      case SortOption.manual:
        // No sorting, keep as is
        break;
      case SortOption.dateAsc:
        filteredItems.sort(
          (a, b) => a.originalCreatedAt.compareTo(b.originalCreatedAt),
        );
        break;
      case SortOption.dateDesc:
        filteredItems.sort(
          (a, b) => b.originalCreatedAt.compareTo(a.originalCreatedAt),
        );
        break;
      case SortOption.alphaAsc:
        filteredItems.sort((a, b) => a.name.compareTo(b.name));
        break;
      case SortOption.alphaDesc:
        filteredItems.sort((a, b) => b.name.compareTo(a.name));
        break;
    }

    final activeItems = filteredItems.where((item) => !item.isBought).toList();
    final boughtItems = filteredItems.where((item) => item.isBought).toList();

    final double totalBoughtPrice = boughtItems.fold(
      0.0,
      (sum, item) => sum + (item.price ?? 0.0),
    );

    final double totalActivePrice = activeItems.fold(
      0.0,
      (sum, item) => sum + (item.price ?? 0.0),
    );

    final appVersion = 'v1.2.2'; // You can update this as needed

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'আইটেম খুঁজুন...',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {}); // Trigger rebuild to filter items
                  },
                ),
              )
            : PopupMenuButton<BazarList>(
                tooltip: 'লিস্ট পরিবর্তন করুন',
                initialValue: _selectedList,
                onSelected: (BazarList list) async {
                  _selectedListId = list.id;
                  await _saveSelectedListId(list.id);
                  await _loadLists();
                },
                itemBuilder: (BuildContext context) {
                  return _lists.map((BazarList list) {
                    return PopupMenuItem<BazarList>(
                      value: list,
                      child: Text(
                        list.name,
                        style: TextStyle(
                          fontWeight: list.id == _selectedListId
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _selectedList?.name ?? 'লিস্ট নেই',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
        centerTitle: false,
        actions: [
          if (_selectedList != null)
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              tooltip: _isSearching ? 'সার্চ বন্ধ করুন' : 'সার্চ করুন',
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                  } else {
                    _searchFocusNode.requestFocus();
                  }
                });
              },
            ),
          if (_selectedList != null)
            IconButton(
              icon: const Icon(Icons.archive, color: Colors.blue),
              tooltip: 'লিস্ট আর্কাইভ করুন',
              onPressed: _confirmArchiveList,
            ),
          // Sort moved into overflow menu (see _showSortDialog)

          // Overflow menu with Dark Mode toggle and Share
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert),
            onSelected: (int v) {
              if (v == 0) {
                widget.onDarkModeToggle(!widget.isDarkMode);
              } else if (v == 1) {
                _shareList();
              } else if (v == 2) {
                _showSortDialog();
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<int>>[
              PopupMenuItem<int>(
                value: 0,
                child: Row(
                  children: [
                    Icon(
                      widget.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.isDarkMode
                          ? 'ডার্ক মোড (চালু)'
                          : 'ডার্ক মোড (বন্ধ)',
                    ),
                  ],
                ),
              ),
              PopupMenuItem<int>(
                value: 1,
                enabled: _items.isNotEmpty,
                child: Row(
                  children: const [
                    Icon(Icons.share, color: Colors.green),
                    SizedBox(width: 12),
                    Text('শেয়ার করুন'),
                  ],
                ),
              ),
              PopupMenuItem<int>(
                value: 2,
                child: Row(
                  children: const [
                    Icon(Icons.sort),
                    SizedBox(width: 12),
                    Text('সজানো (Sort)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                children: [
                  // Add New Category Button
                  ActionChip(
                    avatar: const Icon(Icons.add_circle, size: 18),
                    label: const Text('ক্যাটাগরি'),
                    onPressed: () {
                      _showAddCategoryDialog((newCategoryName) {
                        setState(() {
                          final newCategory = Category(newCategoryName);
                          _categories.add(newCategory);
                          _selectedFilterCategory = newCategory;
                          _quickAddCategory = null;
                        });
                        _saveCategories();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('সব (All)'),
                    selected: _selectedFilterCategory == null,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilterCategory = null;
                          _quickAddCategory = null;
                          _saveFilterCategory(null);
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ..._categories.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onLongPress: () => _showEditOrDeleteCategoryDialog(cat),
                        child: ChoiceChip(
                          label: Text(cat.name),
                          selected: _selectedFilterCategory == cat,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFilterCategory = selected ? cat : null;
                              _quickAddCategory = null;
                              _saveFilterCategory(_selectedFilterCategory);
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _items.isEmpty
                  ? const Center(
                      child: Text(
                        'কোনো আইটেম যোগ করা হয়নি।',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : filteredItems.isEmpty
                  ? const Center(
                      child: Text(
                        'এই ক্যাটাগরিতে কোনো বাজার নেই।',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ReorderableListView(
                      onReorderItem: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }

                          // We have to account for the headers and dividers being part of the index
                          // because they are flat children of ReorderableListView.
                          // However, we want to reorder only the actual items.

                          // Convert the entire current children list as the user sees it
                          final List<dynamic> currentList = [];
                          if (activeItems.isNotEmpty) {
                            currentList.add('header_active');
                            currentList.addAll(activeItems);
                          }
                          if (activeItems.isNotEmpty &&
                              boughtItems.isNotEmpty) {
                            currentList.add('divider');
                          }
                          if (boughtItems.isNotEmpty) {
                            currentList.add('header_bought');
                            currentList.addAll(boughtItems);
                          }
                          currentList.add('spacer');

                          final removed = currentList.removeAt(oldIndex);

                          // If user tries to drag a header or divider, we do nothing or handle carefully
                          if (removed is String) {
                            // Don't reorder non-items
                            return;
                          }

                          currentList.insert(newIndex, removed);

                          // Extract only the items from the new list to maintain order
                          final List<BazarItem> newOrder = currentList
                              .whereType<BazarItem>()
                              .toList();

                          // Persist order by updating createdAt
                          final now = DateTime.now();
                          for (int i = 0; i < newOrder.length; i++) {
                            newOrder[i].createdAt = now.add(
                              Duration(milliseconds: i),
                            );
                            // Directly update DB without calling _updateItem to avoid rapid multiple setState() calls
                            DatabaseHelper.instance.updateItem(newOrder[i]);
                          }

                          // Update state by sorting _items based on the new createdAt
                          // to keep items that might be hidden by search/category filters
                          _items.sort(
                            (a, b) => a.createdAt.compareTo(b.createdAt),
                          );

                          _currentSortOption = SortOption.manual;
                        });
                      },
                      children: [
                        if (activeItems.isNotEmpty)
                          Padding(
                            key: const ValueKey('active_header'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'বাকি আছে (Remaining)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 244, 105, 54),
                                  ),
                                ),
                                Text(
                                  'মোট: ৳${totalActivePrice.toStringAsFixed(totalActivePrice.truncateToDouble() == totalActivePrice ? 0 : 2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 244, 105, 54),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (activeItems.isNotEmpty)
                          ...activeItems.asMap().entries.map((entry) {
                            final indexInList = entry.key;
                            final item = entry.value;
                            // Calculate index in ReorderableListView (header + active items)
                            final actualIndex = indexInList + 1;

                            return BazarItemTile(
                              key: ValueKey(
                                'active_${item.id ?? item.createdAt.millisecondsSinceEpoch}',
                              ),
                              item: item,
                              index: actualIndex,
                              onEditPrice: () => _showEditPriceDialog(item),
                              onDelete: () => _deleteItem(item),
                              onToggle: (val) {
                                item.isBought = val ?? false;
                                _updateItem(item);
                              },
                              onUndo: () => _undoDelete(item),
                            );
                          }),

                        if (activeItems.isNotEmpty && boughtItems.isNotEmpty)
                          const Padding(
                            key: ValueKey('divider_middle'),
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(thickness: 1, height: 32),
                          ),

                        if (boughtItems.isNotEmpty)
                          Padding(
                            key: const ValueKey('bought_header'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'কেনা সম্পন্ন (Done)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  'মোট: ৳${totalBoughtPrice.toStringAsFixed(totalBoughtPrice.truncateToDouble() == totalBoughtPrice ? 0 : 2)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (boughtItems.isNotEmpty)
                          ...boughtItems.asMap().entries.map((entry) {
                            final indexInList = entry.key;
                            final item = entry.value;
                            // Calculate index in ReorderableListView
                            int actualIndex = indexInList;
                            if (activeItems.isNotEmpty) {
                              actualIndex +=
                                  1 +
                                  activeItems.length; // header + active items
                              if (boughtItems.isNotEmpty) {
                                actualIndex += 1; // divider
                              }
                            }
                            actualIndex += 1; // bought header

                            return BazarItemTile(
                              key: ValueKey(
                                'bought_${item.id ?? item.createdAt.millisecondsSinceEpoch}',
                              ),
                              item: item,
                              index: actualIndex,
                              onEditPrice: () => _showEditPriceDialog(item),
                              onDelete: () => _deleteItem(item),
                              onToggle: (val) {
                                item.isBought = val ?? false;
                                _updateItem(item);
                              },
                              onUndo: () => _undoDelete(item),
                            );
                          }),
                        SizedBox(
                          key: const ValueKey('bottom_spacer'),
                          height: 20,
                        ),
                      ],
                    ),
            ),

            // Bottom Add Item Row
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[900]
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[700]!
                      : Colors.grey[300]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _quickAddNameController,
                      focusNode: _quickAddFocusNode,
                      textInputAction: TextInputAction.next,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'পণ্যের নাম',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    indent: 5,
                    endIndent: 5,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[600]
                        : Colors.grey[400],
                  ),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<Category>(
                      initialValue:
                          _quickAddCategory ?? _selectedFilterCategory,
                      isExpanded: true,
                      alignment: Alignment.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ক্যাটাগরি',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintStyle: const TextStyle(fontSize: 13),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem<Category>(
                          value: cat,
                          alignment: Alignment.center,
                          child: Text(
                            cat.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _quickAddCategory = val;
                        });
                      },
                    ),
                  ),
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    indent: 5,
                    endIndent: 5,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[600]
                        : Colors.grey[400],
                  ),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _quickAddPriceController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'দাম',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.transparent,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleQuickAdd(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    width: 60,
                    child: ElevatedButton(
                      onPressed: _handleQuickAdd,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? const Color.fromARGB(255, 213, 186, 255)
                            : const Color.fromARGB(255, 28, 115, 232),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_upward,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Color.fromARGB(255, 58, 54, 67)
                            : Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // if (_isAdLoaded && _bannerAd != null)
            //   SizedBox(
            //     width: MediaQuery.of(context).size.width,
            //     height: _bannerAd!.size.height.toDouble(),
            //     child: AdWidget(ad: _bannerAd!),
            //   )
            // else
            const SizedBox(height: 16),
          ],
        ),
      ),
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          FocusScope.of(context).unfocus();
        }
      },
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[850]
                    : Colors.blue.shade50,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/app_icon.png', height: 90, width: 90),
                  const SizedBox(height: 8),
                  Text(
                    'বাজার তালিকা',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : const Color.fromARGB(134, 0, 0, 0),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _createNewList();
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(
                  'লিস্ট তৈরি করুন',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  alignment: Alignment.center,
                  elevation: 1,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.white,
                  // foregroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 4),
                  ..._lists.map((list) {
                    final isSelected = list.id == _selectedListId;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        tileColor: isSelected
                            ? Theme.of(
                                context,
                              ).primaryColor.withValues(alpha: 0.1)
                            : null,
                        selectedTileColor: Theme.of(
                          context,
                        ).primaryColor.withValues(alpha: 0.1),
                        leading: Icon(
                          isSelected ? Icons.shopping_cart : Icons.list_alt,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : null,
                        ),
                        title: Text(
                          list.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                        ),
                        selected: isSelected,
                        onLongPress: () {
                          Navigator.pop(context);
                          _showListOptionsModal(list);
                        },
                        onTap: () async {
                          Navigator.pop(context);
                          if (!isSelected) {
                            _selectedListId = list.id;
                            await _saveSelectedListId(list.id);
                            await _loadLists();
                          }
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Column(
                children: [
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.archive),
                    title: const Text('আর্কাইভস (Archives)'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ArchiveScreen(isDarkMode: widget.isDarkMode),
                        ),
                      ).then((_) {
                        if (!mounted) return;
                        _loadItems();
                        // Use context-free API to unfocus to avoid async context use
                        FocusManager.instance.primaryFocus?.unfocus();
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('অ্যাপ্লিকেশন সম্পর্কে'),
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('অ্যাপ্লিকেশন সম্পর্কে'),
                          content: Text(
                            'বাজার তালিকা অ্যাপ্লিকেশন $appVersion\nএই অ্যাপটি আপনার বাজারের তালিকা পরিচালনা করতে সাহায্য করে।',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('ঠিক আছে'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('Unsubscribe', style: TextStyle(color: Colors.red),),
                    onTap: () {
                      Navigator.pop(context);
                      _unsubscribe();
                      // showDialog(
                      //   context: context,
                      //   builder: (ctx) => AlertDialog(
                      //     title: Text('Unsubscribing'),
                      //     content: Text('Are you sure?'),
                      //     actions: [
                      //       TextButton(
                      //         onPressed: () => Navigator.pop(context, false),
                      //         child: Text('Cancel'),
                      //       ),
                      //       ElevatedButton(
                      //         style: ElevatedButton.styleFrom(
                      //           backgroundColor: Colors.red,
                      //           foregroundColor: Colors.white,
                      //         ),
                      //         onPressed: () => Navigator.pop(context, true),
                      //         child: Text('Confirm'),
                      //       ),
                      //     ],
                      //   ),
                      // );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

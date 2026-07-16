import 'package:flutter/material.dart';

import '../models/bazar_item.dart';
import '../models/bazar_list.dart';
import '../services/database_helper.dart';

class ArchiveScreen extends StatefulWidget {
  final bool isDarkMode;
  const ArchiveScreen({super.key, required this.isDarkMode});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<BazarList> _archivedLists = [];
  Map<int, List<BazarItem>> _itemsByList = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchivedData();
  }

  String _formatDateTime(DateTime date) {
    final months = [
      '',
      'জানুয়ারি',
      'ফেব্রুয়ারি',
      'মার্চ',
      'এপ্রিল',
      'মে',
      'জুন',
      'জুলাই',
      'আগস্ট',
      'সেপ্টেম্বর',
      'অক্টোবর',
      'নভেম্বর',
      'ডিসেম্বর',
    ];

    int hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    String period = date.hour >= 12 ? 'PM' : 'AM';
    String minute = date.minute.toString().padLeft(2, '0');
    String time = '$hour:$minute $period';

    return '$time, ${date.day} ${months[date.month]} ${date.year}';
  }

  Future<void> _loadArchivedData() async {
    setState(() => _isLoading = true);

    final allLists = await DatabaseHelper.instance.getAllLists(
      includeArchived: true,
    );
    final archivedLists = allLists.where((l) => l.isArchived).toList();

    final allItems = await DatabaseHelper.instance.getAllItems();
    final Map<int, List<BazarItem>> itemsMap = {};

    for (var list in archivedLists) {
      final listId = list.id!;
      final listItems = allItems
          .where((item) => item.listId == listId)
          .toList();
      itemsMap[listId] = listItems;
    }

    setState(() {
      _archivedLists = archivedLists;
      _itemsByList = itemsMap;
      _isLoading = false;
    });
  }

  Future<void> _deleteListFromArchive(BazarList list) async {
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
      _loadArchivedData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('আর্কাইভস (Archives)')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _archivedLists.isEmpty
          ? const Center(
              child: Text(
                'কোনো আর্কাইভ করা লিস্ট নেই।',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _archivedLists.length,
              itemBuilder: (context, index) {
                final list = _archivedLists[index];
                final items = _itemsByList[list.id!] ?? [];

                final double total = items.fold(
                  0,
                  (sum, item) => sum + (item.price ?? 0),
                );

                return ListTile(
                  title: Text(
                    list.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${_formatDateTime(list.createdAt)} • মোট: ৳${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2)}',
                    style: const TextStyle(color: Colors.blue),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteListFromArchive(list),
                        tooltip: 'লিস্ট মুছুন',
                      ),
                      // const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ArchivedListDetailScreen(
                          list: list,
                          items: items,
                          formatDateTime: _formatDateTime,
                        ),
                      ),
                    ).then((_) => _loadArchivedData());
                  },
                );
              },
            ),
    );
  }
}

class ArchivedListDetailScreen extends StatefulWidget {
  final BazarList list;
  final List<BazarItem> items;
  final String Function(DateTime) formatDateTime;

  const ArchivedListDetailScreen({
    super.key,
    required this.list,
    required this.items,
    required this.formatDateTime,
  });

  @override
  State<ArchivedListDetailScreen> createState() =>
      _ArchivedListDetailScreenState();
}

class _ArchivedListDetailScreenState extends State<ArchivedListDetailScreen> {
  late BazarList _list;

  @override
  void initState() {
    super.initState();
    _list = widget.list;
  }

  Future<void> _renameList() async {
    String newName = _list.name;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('লিস্টের নাম পরিবর্তন'),
        content: TextFormField(
          initialValue: _list.name,
          onChanged: (val) => newName = val,
          decoration: const InputDecoration(hintText: 'নতুন নাম'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'সংরক্ষণ করুন',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );

    if (result == true && newName.trim().isNotEmpty) {
      setState(() {
        _list.name = newName.trim();
      });
      await DatabaseHelper.instance.updateList(_list);
    }
  }

  Future<void> _deleteListAndItems() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('লিস্ট মুছতে চান?'),
        content: const Text(
          'এই লিস্ট এবং এর ভিতরের সব আইটেম চিরতরে মুছে যাবে।',
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
      await DatabaseHelper.instance.deleteList(_list.id!);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  List<Widget> _buildSection(
    String title,
    Color titleColor,
    double totalPrice,
    List<BazarItem> items,
  ) {
    if (items.isEmpty) return [];

    Map<String, List<BazarItem>> categoryGroups = {};
    for (var item in items) {
      final cat = item.category?.name ?? 'অন্যান্য (Others)';
      categoryGroups.putIfAbsent(cat, () => []).add(item);
    }

    final sortedCategories = categoryGroups.keys.toList()..sort();
    List<Widget> widgets = [];

    widgets.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
            Text(
              'মোট: ৳${totalPrice.toStringAsFixed(totalPrice.truncateToDouble() == totalPrice ? 0 : 2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: titleColor,
              ),
            ),
          ],
        ),
      ),
    );

    for (var cat in sortedCategories) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 6,
            bottom: 2,
          ),
          child: Text(
            cat,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
      );
      for (var item in categoryGroups[cat]!) {
        widgets.add(
          ListTile(
            dense: true,
            minVerticalPadding: 0,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 0,
            ),
            title: Text(item.name, style: const TextStyle(fontSize: 15)),
            trailing: Text(
              item.price != null && item.price! > 0 ? '৳${item.price}' : '',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
      }
    }

    widgets.add(const Divider(height: 24));
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final activeItems = widget.items.where((item) => !item.isBought).toList();
    final boughtItems = widget.items.where((item) => item.isBought).toList();

    final totalActivePrice = activeItems.fold(
      0.0,
      (sum, item) => sum + (item.price ?? 0.0),
    );
    final totalBoughtPrice = boughtItems.fold(
      0.0,
      (sum, item) => sum + (item.price ?? 0.0),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_list.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _renameList,
            tooltip: 'নাম পরিবর্তন করুন',
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteListAndItems,
            tooltip: 'লিস্ট মুছুন',
          ),
        ],
      ),
      body: widget.items.isEmpty
          ? const Center(
              child: Text(
                'কোনো আইটেম নেই।',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView(
              children: [
                ..._buildSection(
                  'বাকি আছে (Remaining)',
                  Colors.red,
                  totalActivePrice,
                  activeItems,
                ),
                ..._buildSection(
                  'কেনা সম্পন্ন (Done)',
                  Colors.green,
                  totalBoughtPrice,
                  boughtItems,
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}

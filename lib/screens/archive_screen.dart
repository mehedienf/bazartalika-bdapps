import 'package:flutter/material.dart';

import '../models/bazar_item.dart';
import '../services/database_helper.dart';

class ArchiveScreen extends StatefulWidget {
  final bool isDarkMode;
  const ArchiveScreen({super.key, required this.isDarkMode});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  Map<String, List<BazarItem>> _groupedItems = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchivedItems();
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

    // Format Time: HH:mm (12-hour format with AM/PM)
    int hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    String period = date.hour >= 12 ? 'PM' : 'AM';
    String minute = date.minute.toString().padLeft(2, '0');
    String time = '$hour:$minute $period';

    return '$time, ${date.day} ${months[date.month]} ${date.year}';
  }

  Future<void> _loadArchivedItems() async {
    setState(() => _isLoading = true);
    final allItems = await DatabaseHelper.instance.getAllItems();
    final archived = allItems.where((item) => item.isArchived).toList();

    // Sort by original date descending
    archived.sort((a, b) => b.originalCreatedAt.compareTo(a.originalCreatedAt));

    final Map<String, List<BazarItem>> groups = {};
    for (var item in archived) {
      final dateTimeKey = _formatDateTime(item.originalCreatedAt);
      if (!groups.containsKey(dateTimeKey)) {
        groups[dateTimeKey] = [];
      }
      groups[dateTimeKey]!.add(item);
    }

    setState(() {
      _groupedItems = groups;
      _isLoading = false;
    });
  }

  Future<void> _deleteItem(BazarItem item) async {
    if (item.id != null) {
      await DatabaseHelper.instance.deleteItem(item.id!);
      _loadArchivedItems();
    }
  }

  Future<void> _confirmDeleteAll() async {
    if (_groupedItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('সব আর্কাইভ মুছুন'),
        content: const Text(
          'আপনি কি নিশ্চিত যে সব আর্কাইভ করা আইটেম চিরতরে মুছে ফেলতে চান?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () async {
              await DatabaseHelper.instance.deleteArchivedItems();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                _loadArchivedItems();
              }
            },
            child: const Text('সব মুছুন', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateKeys = _groupedItems.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('আর্কাইভস (Archives)'),
        actions: [
          if (dateKeys.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              onPressed: _confirmDeleteAll,
              tooltip: 'সব আর্কাইভ মুছুন',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : dateKeys.isEmpty
          ? const Center(
              child: Text(
                'কোনো আর্কাইভ করা ডাটা নেই।',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: dateKeys.length,
              itemBuilder: (context, index) {
                final dateKey = dateKeys[index];
                final items = _groupedItems[dateKey]!;

                final double total = items.fold(
                  0,
                  (sum, item) => sum + (item.price ?? 0),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[850]
                          : Colors.grey[200],
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            dateKey,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'মোট: ৳${total.toStringAsFixed(total.truncateToDouble() == total ? 0 : 2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...items.map(
                      (item) => ListTile(
                        title: Text(item.name),
                        subtitle: Text(
                          '${item.category?.name ?? "অন্যান্য"} • ৳${item.price ?? 0}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _deleteItem(item),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                  ],
                );
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/bazar_item.dart';

class BazarItemTile extends StatefulWidget {
  final BazarItem item;
  final int index;
  final VoidCallback onEditPrice;
  final VoidCallback onDelete;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onUndo;

  const BazarItemTile({
    required Key key,
    required this.item,
    required this.index,
    required this.onEditPrice,
    required this.onDelete,
    required this.onToggle,
    required this.onUndo,
  }) : super(key: key);

  @override
  State<BazarItemTile> createState() => _BazarItemTileState();
}

class _BazarItemTileState extends State<BazarItemTile> {
  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(widget.item.createdAt.toString()), // Using stable key
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('আইটেম মুছুন'),
              content: Text(
                'আপনি কি নিশ্চিত যে "${widget.item.name}" মুছতে চান?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('বাতিল'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'মুছুন',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        final messenger = ScaffoldMessenger.of(context);
        widget.onDelete(); // Delete the item from list

        messenger.clearSnackBars();
        final snackBarController = messenger.showSnackBar(
          SnackBar(
            content: Text('${widget.item.name} লিস্ট থেকে মুছে ফেলা হয়েছে'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: 'Undo', onPressed: widget.onUndo),
          ),
        );

        // Forcefully close SnackBar after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          try {
            snackBarController.close();
          } catch (_) {}
        });
      },
      child: Container(
        decoration: const BoxDecoration(color: Colors.transparent),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 1,
          ),
          visualDensity: const VisualDensity(vertical: -4),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReorderableDragStartListener(
                index: widget.index,
                child: const Icon(Icons.drag_handle, color: Colors.grey),
              ),
              const SizedBox(width: 2),
              Transform.translate(
                offset: const Offset(
                  0,
                  -4,
                ), // Adjusts checkbox to align with title
                child: Checkbox(
                  value: widget.item.isBought,
                  onChanged: widget.onToggle,
                ),
              ),
            ],
          ),
          title: Text(
            widget.item.name,
            style: TextStyle(
              decoration: widget.item.isBought
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              fontWeight: FontWeight.bold,
              color: widget.item.isBought
                  ? Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54
                        : Colors.black54
                  : Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color.fromARGB(255, 25, 3, 72),
            ),
          ),
          subtitle: Text(widget.item.category?.name ?? ''),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.item.price != null ? '৳${widget.item.price}' : 'দাম',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : (widget.item.price != null
                            ? const Color.fromARGB(255, 61, 37, 97)
                            : const Color.fromARGB(255, 57, 55, 55)),
                  fontWeight: FontWeight.w500,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: widget.onEditPrice,
                tooltip: 'আইটেম সম্পাদনা করুন',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

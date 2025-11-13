import 'package:flutter/material.dart';

class MedicineTimeChip extends StatefulWidget {
  final String time;
  final String status;
  final Function(String time) onSelected;

  const MedicineTimeChip({
    super.key,
    required this.time,
    required this.status,
    required this.onSelected,
  });

  @override
  State<MedicineTimeChip> createState() => _MedicineTimeChipState();
}

class _MedicineTimeChipState extends State<MedicineTimeChip> {
  bool _isSelected = false;

  Color getChipColor() {
    if (_isSelected) return Colors.orange.shade200;

    switch (widget.status) {
      case 'taken':
        return Colors.green.shade100;
      case 'missed':
        return Colors.red.shade100;
      default:
        return Colors.blue.shade100;
    }
  }

  IconData getIcon() {
    switch (widget.status) {
      case 'taken':
        return Icons.check_circle;
      case 'missed':
        return Icons.cancel;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.status == 'pending') {
          setState(() {
            _isSelected = !_isSelected;
          });
          widget.onSelected(widget.time);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("You can't select this time")),
          );
        }
      },
      child: Chip(
        backgroundColor: getChipColor(),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(getIcon(), size: 16, color: Colors.black54),
            const SizedBox(width: 4),
            Text(widget.time, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

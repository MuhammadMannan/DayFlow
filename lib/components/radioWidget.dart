import 'package:flutter/material.dart';

class radioWidget extends StatelessWidget {
  final Color categoryColor;
  final String titleRadio;
  final bool isSelected; // Selected flag
  final VoidCallback onSelected; // Callback to notify the parent

  radioWidget({
    required this.categoryColor,
    required this.titleRadio,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelected, // Call the onSelected callback when tapped
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? categoryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            titleRadio,
            style: TextStyle(
              color: isSelected ? Colors.white : categoryColor,
            ),
          ),
        ),
      ),
    );
  }
}

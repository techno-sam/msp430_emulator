import 'package:flutter/material.dart';
import 'package:msp430_emulator/utils/extensions.dart';

class TabButton extends StatelessWidget {
  const TabButton({super.key, this.onExit, this.onClick, required this.label, required this.selected});

  /// called when exit button is pressed
  final void Function()? onExit;

  /// called when tab is clicked
  final void Function()? onClick;

  /// text label
  final String label;

  /// whether this tab is actively selected
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var foreground = selected ? ColorExtension.selectedGreen : ColorExtension.unselectedGreen;
    const shape = RoundedRectangleBorder(borderRadius: BorderRadius.vertical(
        top: Radius.circular(8.0),
        bottom: Radius.circular(2.0)
    ));
    return Card(
      color: ColorExtension.deepSlateBlue.withOpacity(selected ? 1.0 : 0.75),
      margin: const EdgeInsets.only(left: 2.0, right: 2.0, top: 2.0, bottom: 0.0),
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onClick,
        child: Container(
          padding: const EdgeInsets.only(left: 5.0, right: 5.0, top: 4.0),
          child: Row(
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foreground,
                  decoration: selected ? TextDecoration.underline : null,
                  decorationColor: foreground,
                  decorationThickness: 6
                ),
              ),
              const SizedBox(width: 2.0),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 15.0),
                color: foreground.withOpacity(0.75),
                onPressed: onExit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
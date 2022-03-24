import 'package:flutter/material.dart';

/// A button that blocks input until the onPressed function resolves.
class SafeButton extends StatelessWidget {
  const SafeButton({Key? key, this.text, this.onPressed, this.blockInput})
      : super(key: key);
  final String? text;
  final Future<void> Function()? onPressed;
  final bool? blockInput;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      child: Text(text ?? 'Press Me'),
      onPressed: (blockInput ?? false) ? null : onPressed,
    );
  }
}

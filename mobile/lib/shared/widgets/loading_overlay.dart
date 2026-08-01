import 'package:flutter/material.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black26,
      child: Center(
        child: ClayCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(message),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

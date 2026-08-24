import 'package:flutter/widgets.dart';

enum MascotPose { idle, wave, point, explain, celebrate }

class CoachStep {
  const CoachStep({
    required this.id,
    required this.text,
    required this.pose,
    this.targetKey,
  });

  final String id;
  final String text;
  final MascotPose pose;
  final GlobalKey? targetKey;
}

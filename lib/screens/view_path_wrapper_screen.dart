import 'package:flutter/material.dart';
import 'view_path_screen.dart';

class ViewPathWrapperScreen extends StatelessWidget {
  final String pathId;
  
  const ViewPathWrapperScreen({
    super.key,
    required this.pathId,
  });

  @override
  Widget build(BuildContext context) {
    return ViewPathScreen(pathId: pathId);
  }
}
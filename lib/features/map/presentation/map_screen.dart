import 'package:flutter/material.dart';
import 'package:timea/common/widgets/app_bar.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: TimeAppBar(
        title: '',
      ),
      body: Center(
        child: Text('Map Screen'),
      ),
    );
  }
}

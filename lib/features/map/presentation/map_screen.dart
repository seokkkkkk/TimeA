import 'package:flutter/material.dart';
import 'package:timea/common/widgets/app_bar.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TimeAppBar(
        title: '',
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: Container(
            decoration: const BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/envelope.png',
              width: 32,
              height: 32,
            ),
          )),
      body: const Center(
        child: Text('Home Screen'),
      ),
    );
  }
}

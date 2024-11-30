import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        centerTitle: true,
        backgroundColor: Colors.transparent,
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

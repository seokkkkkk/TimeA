import 'package:flutter/material.dart';
import 'package:timea/common/widgets/app_bar.dart';
import 'package:timea/common/widgets/ball_drop_widget.dart';
import 'package:timea/features/home/presentation/envelope_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int ballCount = 0; // 공 개수

  void _addBall() {
    setState(() {
      ballCount += 1;
    });
  }

  void _showAddContentForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: EnvelopeForm(
            onSubmit: () {
              Navigator.of(context).pop();
              _addBall();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TimeAppBar(
        title: '기억 캡슐 📦',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContentForm(context),
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
        ),
      ),
      body: BallDropWidget(ballCount: ballCount),
    );
  }
}

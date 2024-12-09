import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:timea/core/model/capsule.dart';

class CardBuilder extends StatelessWidget {
  final List<Capsule> capsules;
  final String Function(DateTime) calculateDday;

  const CardBuilder({
    super.key,
    required this.capsules,
    required this.calculateDday,
  });

  void _showModal(
      BuildContext context, String imageUrl, String content, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (imageUrl.isNotEmpty)
                FutureBuilder(
                  future: precacheImage(NetworkImage(imageUrl), context),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Icon(
                          Icons.error,
                          color: Colors.red,
                        ),
                      );
                    } else {
                      return Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                      );
                    }
                  },
                ),
              if (imageUrl.isNotEmpty) const SizedBox(height: 8),
              Text(
                content,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      itemCount: capsules.length,
      controller: PageController(viewportFraction: 0.6),
      itemBuilder: (context, index) {
        final capsule = capsules[index];
        final unlockDate = capsule.canUnlockedAt;
        final isUnlocked = capsule.unlockedAt != null;
        final imageUrl = capsule.imageUrl ?? '';
        final content = capsule.content;
        final title = capsule.title;

        return GestureDetector(
          onTap: () {
            if (isUnlocked) {
              _showModal(context, imageUrl, content, title);
            } else {
              showDialog(
                context: context,
                builder: (context) => Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Icon(
                          Icons.lock,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            color: Colors.white,
            elevation: 2,
            shadowColor:
                isUnlocked ? Theme.of(context).primaryColor : Colors.grey,
            child: Stack(
              children: [
                if (!isUnlocked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        capsule.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        calculateDday(unlockDate),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('yyyy년 MM월 dd일').format(unlockDate),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                if (!isUnlocked)
                  const Center(
                    child: Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

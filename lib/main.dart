import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.green,
        body: SafeArea(child: TarotArcScroll()),
      ),
    ),
  );
}

class TarotArcScroll extends StatefulWidget {
  const TarotArcScroll({super.key});

  @override
  State<TarotArcScroll> createState() => _TarotArcScrollState();
}

class _TarotArcScrollState extends State<TarotArcScroll>
    with SingleTickerProviderStateMixin {
  double rotationOffset = 0;
  double velocity = 0;
  final double radius = 600;
  final int cardCount = 78;
  final int visibleCardCount = 10;
  int currentStartIndex = 0;
  final double anglePerCard = 2 * pi / 78;
  late final AnimationController _controller;

  int? selectedCard;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16000),
    )..addListener(() {
      setState(() {
        rotationOffset += velocity;
        velocity *= 0.96;
        if (velocity.abs() < 0.001) {
          _controller.stop();
        }
      });
    });
  }

  void _startInertia(double initialVelocity) {
    velocity = initialVelocity;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width * 2;
    final centerY = 420.0;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          rotationOffset += details.delta.dx * 0.005;
        });
      },
      onHorizontalDragEnd: (details) {
        final velocityX = details.velocity.pixelsPerSecond.dx;
        final direction = velocityX < 0 ? 1 : -1;

        setState(() {
          currentStartIndex = (currentStartIndex + direction * visibleCardCount) % cardCount;
          if (currentStartIndex < 0) currentStartIndex += cardCount;
        });

        _startInertia(velocityX * 0.00001);
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: List.generate(visibleCardCount, (i) {
                final index = (currentStartIndex + i) % cardCount;
                final angle = (i * anglePerCard) + rotationOffset;
                final normalizedAngle = angle % (2 * pi);
                if (normalizedAngle < pi / 2 || normalizedAngle > 3 * pi / 2) {
                  return const SizedBox();
                }

                final x = centerX + radius * cos(angle);
                final y = centerY + radius * sin(angle);
                final cardSize = selectedCard == index ? 280.0 : 200.0;

                return Positioned(
                  left: x - cardSize * 0.3,
                  top: y - cardSize / 2,
                  child: Transform.rotate(
                    angle: angle + pi / 2,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        selectedCard = selectedCard == index ? null : index;
                      }),
                      child: Hero(
                        tag: 'card_$index',
                        child: TarotCardWidget(
                          imagePath: selectedCard == index
                              ? 'assets/cards/card_${(index + 1).toString().padLeft(2, '0')}.jpg'
                              : 'assets/cards/back.png',
                          size: cardSize,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          if (selectedCard != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => selectedCard = null),
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Hero(
                      tag: 'card_$selectedCard',
                      child: TarotCardWidget(
                        imagePath:
                        'assets/cards/card_${(selectedCard! + 1).toString().padLeft(2, '0')}.jpg',
                        size: 240,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class TarotCardWidget extends StatelessWidget {
  final String imagePath;
  final double size;

  const TarotCardWidget({super.key, required this.imagePath, this.size = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.6,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
    );
  }
}

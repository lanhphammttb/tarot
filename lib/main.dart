import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
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
  final double anglePerCard = pi / 30; // khoảng cách giữa các lá bài
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
        velocity *= 0.95;
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
    final centerX = screenSize.width / 2.3;
    final centerY = screenSize.height * 1.8;
    const centerAngle = 3 * pi / 2;
    const visibleRange = (pi / 3) / 2;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          rotationOffset += details.delta.dx * 0.005;
        });
      },
      onHorizontalDragEnd: (details) {
        _startInertia(details.velocity.pixelsPerSecond.dx * 0.00001);
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: List.generate(cardCount, (index) {
                final angle = index * anglePerCard + rotationOffset;
                final normalizedAngle = angle % (2 * pi);

                if (normalizedAngle < centerAngle - visibleRange ||
                    normalizedAngle > centerAngle + visibleRange) {
                  return const SizedBox();
                }

                final angleDelta = (angle - centerAngle).abs();
                final scale = 1 - (angleDelta / pi).clamp(0.0, 0.5);
                final adjustedCardSize =
                    (selectedCard == index ? 280.0 : 200.0) * (0.8 + 0.4 * scale);

                final x = centerX + radius * cos(angle);
                final y = centerY + radius * sin(angle);

                return Positioned(
                  left: x - adjustedCardSize * 0.3,
                  top: y - adjustedCardSize / 2,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..rotateZ(angle + pi / 2)
                      ..rotateY((angle - centerAngle) * 0.3),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        selectedCard = selectedCard == index ? null : index;
                      }),
                      child: AnimatedOpacity(
                        opacity: 1,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        child: AnimatedScale(
                          scale: 1,
                          duration: const Duration(milliseconds: 500),
                          child: Hero(
                            tag: 'card_$index',
                            child: TarotCardWidget(
                              imagePath: selectedCard == index
                                  ? 'assets/cards/card_${(index + 1).toString().padLeft(2, '0')}.jpg'
                                  : 'assets/cards/back.png',
                              size: adjustedCardSize,
                            ),
                          ),
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
                        size: 300,
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
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
    );
  }
}

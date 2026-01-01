import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import 'package:datingapp/core/theme/app_theme.dart';
import 'package:datingapp/widgets/common/custom_button.dart';

class SpinTheBottleScreen extends StatefulWidget {
  final String eventId;

  const SpinTheBottleScreen({super.key, required this.eventId});

  @override
  State<SpinTheBottleScreen> createState() => _SpinTheBottleScreenState();
}

class _SpinTheBottleScreenState extends State<SpinTheBottleScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _rotation = 0;
  bool _isSpinning = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.decelerate);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spinBottle() {
    if (_isSpinning) return;

    setState(() {
      _isSpinning = true;
    });

    final random = math.Random();
    final double targetRotation = _rotation + (math.pi * 2 * 5) + (random.nextDouble() * math.pi * 2);

    final animation = Tween<double>(
      begin: _rotation,
      end: targetRotation,
    ).animate(_animation);

    _controller.reset();
    _controller.forward().then((_) {
      setState(() {
        _isSpinning = false;
        _rotation = targetRotation % (math.pi * 2);
      });
    });

    _controller.addListener(() {
      setState(() {
        _rotation = animation.value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spin the Bottle'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Who\'s next?',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 48),
            GestureDetector(
              onTap: _spinBottle,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Circle Background
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.5), width: 4),
                    ),
                  ),
                  // Bottle
                  Transform.rotate(
                    angle: _rotation,
                    child: Container(
                      width: 40,
                      height: 180,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryPink.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            width: 20,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: CustomButton(
                text: _isSubmitting ? 'Spinning...' : 'SPIN!',
                onPressed: _spinBottle,
                isLoading: _isSpinning,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Point the bottle and start a truth, dare, or just a conversation!',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  bool get _isSubmitting => _isSpinning;
}

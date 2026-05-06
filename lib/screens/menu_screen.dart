import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/session/session_controller.dart';
import 'package:flutter_master_app/theme/app_theme.dart';
import 'package:flutter_master_app/screens/settings_screen.dart';
import 'package:flutter_master_app/providers/language_provider.dart';
import 'dart:math';
import 'dart:async';
import 'dart:io';

class Particle {
  late Offset position;
  late Offset velocity;
  late double opacity;
  late double age;
  late double size;
  final double lifetime;
  final double maxDistance;
  final Color color;

  Particle({
    required Offset startPosition,
    required double minLifetime,
    required double maxLifetime,
    required double minSpeed,
    required double maxSpeed,
    required double minSize,
    required double maxSize,
    this.maxDistance = 150,
    required double outwardAngle, // Angle pointing away from center
    required this.color,
  }) : lifetime = minLifetime + Random().nextDouble() * (maxLifetime - minLifetime) {
    position = startPosition;
    // Add some randomness around the outward direction (±45 degrees)
    final angleVariation = (Random().nextDouble() - 0.5) * (pi / 2);
    final angle = outwardAngle + angleVariation;
    final speed = minSpeed + Random().nextDouble() * (maxSpeed - minSpeed);
    size = minSize + Random().nextDouble() * (maxSize - minSize);
    velocity = Offset(cos(angle) * speed, sin(angle) * speed);
    opacity = 1.0;
    age = 0;
  }

  void update(double deltaTime) {
    age += deltaTime;
    position += velocity * deltaTime;
    opacity = max(0, 1 - (age / lifetime));
  }

  bool get isAlive => age < lifetime;
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (var particle in particles) {
      paint.color = particle.color.withValues(alpha: particle.opacity);
      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  List<Particle> particles = [];
  late Timer _updateTimer;
  Offset? particleCenter;
  
  // Estimated text dimensions (72px font, 2 lines) with extra padding for spawn zone
  static const double titleWidth = 650;
  static const double titleHeight = 220;

  Map<String, dynamic> getRandomEdgeSpawnPoint(Offset center) {
    final halfWidth = titleWidth / 2;
    final halfHeight = titleHeight / 2;
    
    Offset spawnPoint;
    
    // Weight edge selection by perimeter length to balance spawn distribution
    // Top and bottom edges: titleWidth each
    // Left and right edges: titleHeight each
    final topBottomLength = titleWidth;
    final leftRightLength = titleHeight;
    final totalPerimeter = 2 * (topBottomLength + leftRightLength);
    
    final random = Random().nextDouble() * totalPerimeter;
    
    if (random < topBottomLength) {
      // Top edge
      spawnPoint = Offset(
        center.dx + (Random().nextDouble() - 0.5) * titleWidth,
        center.dy - halfHeight,
      );
    } else if (random < 2 * topBottomLength) {
      // Bottom edge
      spawnPoint = Offset(
        center.dx + (Random().nextDouble() - 0.5) * titleWidth,
        center.dy + halfHeight,
      );
    } else if (random < 2 * topBottomLength + leftRightLength) {
      // Left edge
      spawnPoint = Offset(
        center.dx - halfWidth,
        center.dy + (Random().nextDouble() - 0.5) * titleHeight,
      );
    } else {
      // Right edge
      spawnPoint = Offset(
        center.dx + halfWidth,
        center.dy + (Random().nextDouble() - 0.5) * titleHeight,
      );
    }
    
    // Calculate outward angle from center to spawn point
    final dx = spawnPoint.dx - center.dx;
    final dy = spawnPoint.dy - center.dy;
    final outwardAngle = atan2(dy, dx);
    
    return {'point': spawnPoint, 'angle': outwardAngle};
  }

  @override
  void initState() {
    super.initState();

    // Update particles frequently
    _updateTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (particleCenter == null) return;
      
      setState(() {
        // Spawn new particles every frame
        if (Random().nextDouble() < 0.3) {
          final spawnData = getRandomEdgeSpawnPoint(particleCenter!);
          // Alternate between primary and secondary based on particle count
          final isPrimary = particles.length % 2 == 0;
          particles.add(Particle(
            startPosition: spawnData['point'],
            outwardAngle: spawnData['angle'],
            minLifetime: 1.5,
            maxLifetime: 3.5,
            minSpeed: 20,
            maxSpeed: 80,
            minSize: 3,
            maxSize: 10,
            color: isPrimary 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
          ));
        }

        // Update existing particles
        particles.removeWhere((p) => !p.isAlive);
        for (var particle in particles) {
          particle.update(0.016);
        }
      });
    });
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    // Top 2/3 - Title section
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Title with particle effect
                            LayoutBuilder(
                              builder: (context, constraints) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  particleCenter = Offset(constraints.maxWidth / 2, 100);
                                });

                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CustomPaint(
                                      painter: ParticlePainter(particles),
                                      size: Size(constraints.maxWidth, 200),
                                    ),
                                    Text(
                                      strings.appTitle,
                                      style: TextStyle(
                                        fontSize: 120,
                                        fontWeight: FontWeight.w900,
                                        color: Theme.of(context).colorScheme.secondary,
                                        height: 1.2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Bottom 1/3 - Buttons section
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Start Test Button - Large
                            SizedBox(
                              width: 350,
                              height: 75,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                ),
                                onPressed: () {
                                  ref.read(sessionProvider.notifier).enterLibrary();
                                },
                                child: Text(
                                  strings.play,
                                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Other buttons - Normal width
                            SizedBox(
                              width: 250,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Settings Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const SettingsScreen(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        strings.settings,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Quit Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Theme.of(context).colorScheme.primary,
                                        foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(strings.exitConfirm),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: Text(strings.back),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  exit(0);
                                                },
                                                child: Text(
                                                  strings.exit,
                                                  style: const TextStyle(color: AppColors.errorRed),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: Text(
                                        strings.exit,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

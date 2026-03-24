import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class CelebrationParticle {
  final Offset position;
  final Offset velocity;
  final double life;
  final double maxLife;
  final Color color;
  final double size;

  CelebrationParticle({
    required this.position,
    required this.velocity,
    required this.life,
    required this.maxLife,
    required this.color,
    required this.size,
  });

  CelebrationParticle update(double dt) {
    final gravity = 200.0;
    final newVelocity = Offset(velocity.dx, velocity.dy + gravity * dt);

    return CelebrationParticle(
      position: position + newVelocity * dt,
      velocity: newVelocity,
      life: (life - dt).clamp(0, maxLife),
      maxLife: maxLife,
      color: color,
      size: size,
    );
  }

  double get opacity => (life / maxLife).clamp(0, 1);

  bool get isAlive => life > 0;
}

class CelebrationParticleSystem {
  final List<CelebrationParticle> _particles = [];
  final int maxParticles;

  CelebrationParticleSystem({this.maxParticles = 100});

  void burst({
    required Offset position,
    required int count,
    Duration duration = const Duration(milliseconds: 1200),
    List<Color>? colors,
  }) {
    final random = math.Random();
    final particleColors =
        colors ?? [AppColors.tropicalTeal, AppColors.crayolaBlue];

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      final speed = 100 + random.nextDouble() * 150;

      _particles.add(
        CelebrationParticle(
          position: position,
          velocity: Offset(
            math.cos(angle) * speed,
            math.sin(angle) * speed - 50,
          ),
          life: duration.inMilliseconds.toDouble() / 1000,
          maxLife: duration.inMilliseconds.toDouble() / 1000,
          color: particleColors[i % particleColors.length],
          size: 4 + random.nextDouble() * 4,
        ),
      );
    }
  }

  void update(double dt) {
    for (int i = _particles.length - 1; i >= 0; i--) {
      _particles[i] = _particles[i].update(dt);
      if (!_particles[i].isAlive) {
        _particles.removeAt(i);
      }
    }
  }

  void draw(Canvas canvas) {
    for (final particle in _particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(particle.position, particle.size, paint);
    }
  }

  bool get hasParticles => _particles.isNotEmpty;

  void clear() {
    _particles.clear();
  }
}

class CelebrationParticlesWidget extends StatefulWidget {
  final int currentIndex;
  final double animationProgress;
  final List<Offset> positions;
  final bool celebrateOnReachGoal;

  const CelebrationParticlesWidget({
    super.key,
    required this.currentIndex,
    required this.animationProgress,
    required this.positions,
    this.celebrateOnReachGoal = false,
  });

  @override
  State<CelebrationParticlesWidget> createState() =>
      _CelebrationParticlesWidgetState();
}

class _CelebrationParticlesWidgetState extends State<CelebrationParticlesWidget>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  final CelebrationParticleSystem _particleSystem = CelebrationParticleSystem();
  bool _regularTestCelebrated = false;
  bool _goalCelebrated = false;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void didUpdateWidget(CelebrationParticlesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check for regular test completion celebration (when animation starts)
    // Skip initial transition (currentIndex == -1)
    if (widget.animationProgress > 0 &&
        oldWidget.animationProgress == 0 &&
        widget.currentIndex != -1 &&
        !_regularTestCelebrated) {
      _regularTestCelebrated = true;
      // Celebrate at the current stop that was just reached
      if (widget.celebrateOnReachGoal) {
        // On final screen: celebrate the last test stop (second to last position)
        if (widget.positions.length > 1) {
          _triggerCelebration(widget.positions[widget.positions.length - 2]);
        }
      } else {
        // On regular screens: celebrate the current stop
        if (widget.currentIndex + 1 < widget.positions.length) {
          _triggerCelebration(widget.positions[widget.currentIndex + 1]);
        }
      }
    }

    // Check for goal celebration (immediately when animation reaches it)
    if (widget.celebrateOnReachGoal &&
        widget.animationProgress >= 0.90 &&
        !_goalCelebrated) {
      _goalCelebrated = true;
      final goalPosition = widget.positions.last;
      _triggerCelebration(goalPosition, isGoal: true);
    }
  }

  void _triggerCelebration(Offset position, {bool isGoal = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      AppColors.warningYellow,
    ];

    _particleSystem.burst(
      position: position,
      count: isGoal ? 50 : 30,
      duration: Duration(milliseconds: isGoal ? 1500 : 1200),
      colors: colors,
    );
  }

  @override
  void dispose() {
    _particleController.dispose();
    _particleSystem.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        // Update particle system
        _particleSystem.update(1 / 60);

        return CustomPaint(
          painter: _CelebrationParticlePainter(_particleSystem),
          size: Size.infinite,
        );
      },
    );
  }
}

class _CelebrationParticlePainter extends CustomPainter {
  final CelebrationParticleSystem particleSystem;

  const _CelebrationParticlePainter(this.particleSystem);

  @override
  void paint(Canvas canvas, Size size) {
    particleSystem.draw(canvas);
  }

  @override
  bool shouldRepaint(_CelebrationParticlePainter oldDelegate) => true;
}

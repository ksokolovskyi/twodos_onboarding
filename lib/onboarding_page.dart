import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tactile_feedback/tactile_feedback.dart';
import 'package:twodos_onboarding/helpers/helpers.dart';
import 'package:twodos_onboarding/twodos_icon.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  /// Animation controller that drives the appearance of the page parts.
  late final _appearanceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );

  late final _iconAndTitleOpacity = Tween<double>(begin: 0, end: 1)
      .chain(CurveTween(curve: const Interval(0, 0.25, curve: Curves.easeIn)))
      .animate(_appearanceController);

  late final _titlePosition = Tween<Offset>(
    begin: const Offset(0, 0.5),
    end: Offset.zero,
  )
      .chain(
        CurveTween(curve: const Interval(0, 0.75, curve: ElasticOutCurve(0.7))),
      )
      .animate(_appearanceController);

  late final _subtitleOpacity = Tween<double>(begin: 0, end: 1)
      .chain(CurveTween(curve: const Interval(0.3, 0.55, curve: Curves.easeIn)))
      .animate(_appearanceController);

  late final _subtitlePosition = Tween<Offset>(
    begin: const Offset(0, 0.5),
    end: Offset.zero,
  )
      .chain(
        CurveTween(curve: const Interval(0.3, 1, curve: ElasticOutCurve(0.7))),
      )
      .animate(_appearanceController);

  late final _slideToUnlockOpacity = Tween<double>(begin: 0, end: 1)
      .chain(CurveTween(curve: const Interval(0.9, 1, curve: Curves.easeIn)))
      .animate(_appearanceController);

  /// Spring simulation which is used to create spring effect when drag ends.
  late final _springSimulation = SpringSimulation2D(
    tickerProvider: this,
    spring: const SpringDescription(
      mass: 1,
      stiffness: 350,
      damping: 15,
    ),
  );

  late final _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );

  late final _angle = ValueNotifier<double>(0);

  /// Total distance of the current drag in pixels.
  var _dragDistance = 0.0;

  /// Whether [_playFeedback] was called after full progress was reached.
  var _didNotifyFullProgress = false;

  /// Calculates friction factor according to the [_dragDistance].
  double get _frictionFactor {
    // Maximum distance for the full friction effect.
    const maxDistance = 100.0;
    // Maximum friction factor.
    const maxFriction = 3.0;

    final normalizedDistance =
        _dragDistance.abs().clamp(0.0, maxDistance) / maxDistance;

    return (maxFriction * normalizedDistance) + 1;
  }

  @override
  void initState() {
    super.initState();

    // Starting the appearance animations.
    _appearanceController.forward();

    // Setting the initial offset for the spring simulation to create the
    // bouncy appearance animation.
    _springSimulation
      ..springPosition = const Offset(-50, 0)
      ..addListener(_maybeUpdateAngle);

    // Setting the initial angle for icon.
    _maybeUpdateAngle();

    // Setting the delayed callback for the bouncy appearance animation.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) {
        return;
      }

      _springSimulation.start();
      _playFeedback();
    });
  }

  @override
  void dispose() {
    _appearanceController.dispose();
    _springSimulation.dispose();
    _progress.dispose();
    _angle.dispose();
    super.dispose();
  }

  /// Calculates the new progress value according to the drag progress,
  /// updates [_progress] value if needed.
  void _maybeUpdateProgress() {
    final dragOffset = _springSimulation.springPosition.dx.clamp(0.0, 50.0);
    final progress =
        dragOffset.remap(fromLow: 0, fromHigh: 50, toLow: 0, toHigh: 1);

    if (_progress.value != progress) {
      _progress.value = progress;
    }

    if (_progress.value == 1 && !_didNotifyFullProgress) {
      _playFeedback();
      _didNotifyFullProgress = true;
    } else if (_progress.value != 1 && _didNotifyFullProgress) {
      _playFeedback();
      _didNotifyFullProgress = false;
    }
  }

  void _resetProgress() {
    _progress.reverse();
    _didNotifyFullProgress = false;
  }

  /// Calculates the new angle value according to the drag progress and
  /// updates [_angle] value if needed.
  void _maybeUpdateAngle() {
    final dragOffset = _springSimulation.springPosition.dx.clamp(-50.0, 200.0);
    final angle = switch (dragOffset) {
      -50 => 0.0,
      > -50 && <= 0 =>
        dragOffset.remap(fromLow: -50, fromHigh: 0, toLow: 0, toHigh: 1),
      _ => dragOffset.remap(fromLow: 0, fromHigh: 200, toLow: 1, toHigh: 4),
    };

    if (_angle.value != angle) {
      _angle.value = angle;
    }
  }

  /// Plays haptic feedback on iOS, Android, and MacOS trackpad.
  void _playFeedback() {
    TactileFeedback.impact();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (_) {
        _dragDistance = 0;
        _springSimulation.end();
      },
      onHorizontalDragUpdate: (details) {
        _dragDistance += details.delta.dx;
        _springSimulation.springPosition += details.delta / _frictionFactor;
        _maybeUpdateProgress();
      },
      onHorizontalDragEnd: (_) {
        _dragDistance = 0;
        _springSimulation.start();
        _resetProgress();
        _playFeedback();
      },
      onHorizontalDragCancel: () {
        _dragDistance = 0;
        _springSimulation.start();
        _resetProgress();
        _playFeedback();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _iconAndTitleOpacity,
                child: TwodosIcon(
                  progress: _progress,
                  angle: _angle,
                ),
              ),
              const SizedBox(height: 30),
              FadeTransition(
                opacity: _iconAndTitleOpacity,
                child: SlideTransition(
                  position: _titlePosition,
                  child: const _TitleText(),
                ),
              ),
              const SizedBox(height: 25),
              FadeTransition(
                opacity: _subtitleOpacity,
                child: SlideTransition(
                  position: _subtitlePosition,
                  child: const _SubtitleText(),
                ),
              ),
              const SizedBox(height: 25),
              RepaintBoundary(
                child: FadeTransition(
                  opacity: _slideToUnlockOpacity,
                  child: ListenableBuilder(
                    listenable: _springSimulation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: _springSimulation.springPosition,
                        child: child,
                      );
                    },
                    child: const _SlideToUnlockText(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleText extends StatelessWidget {
  const _TitleText();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Welcome to Twodos',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.black,
        fontSize: 19,
        fontFamily: 'SF Pro Rounded',
        fontWeight: FontWeight.w500,
        height: 23 / 19,
        letterSpacing: 0.57,
      ),
    );
  }
}

class _SubtitleText extends StatelessWidget {
  const _SubtitleText();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        'A delightfully simple todo app that '
        'respects your focus and privacy.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.black,
          fontSize: 17,
          fontFamily: 'SF Pro Rounded',
          fontWeight: FontWeight.w400,
          height: 20 / 17,
          letterSpacing: 0.39,
        ),
      ),
    );
  }
}

class _SlideToUnlockText extends StatelessWidget {
  const _SlideToUnlockText();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Slide to Unlock',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF8A888A),
            fontSize: 17,
            fontFamily: 'SF Pro Rounded',
            fontWeight: FontWeight.w500,
            height: 20 / 17,
            letterSpacing: 0.34,
          ),
        ),
        SizedBox(width: 8),
        Icon(
          CupertinoIcons.arrow_right,
          color: Color(0xFF8A888A),
          size: 20,
        ),
      ],
    );
  }
}

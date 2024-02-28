import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

// Copied from https://github.com/ksokolovskyi/avara_homepage/blob/main/lib/spring_simulation.dart
class SpringSimulation2D with ChangeNotifier {
  SpringSimulation2D({
    required TickerProvider tickerProvider,
    required this.spring,
    Offset anchorPosition = Offset.zero,
    Offset springPosition = Offset.zero,
  })  : _anchorPosition = anchorPosition,
        _springPosition = springPosition,
        _previousVelocity = Offset.zero {
    _ticker = tickerProvider.createTicker(_onTick);
  }

  final SpringDescription spring;

  late final Ticker _ticker;

  Offset _previousVelocity;

  SpringSimulation? _simulationX;
  SpringSimulation? _simulationY;

  Offset _anchorPosition;
  Offset get anchorPosition => _anchorPosition;
  set anchorPosition(Offset value) {
    if (value == _anchorPosition) {
      return;
    }
    end();
    _anchorPosition = value;
    notifyListeners();
  }

  Offset _springPosition;
  Offset get springPosition => _springPosition;
  set springPosition(Offset value) {
    if (value == _springPosition) {
      return;
    }
    end();
    _springPosition = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  TickerFuture start() {
    _simulationX = SpringSimulation(
      spring,
      _springPosition.dx,
      _anchorPosition.dx,
      _previousVelocity.dx,
    );

    _simulationY = SpringSimulation(
      spring,
      _springPosition.dy,
      _anchorPosition.dy,
      _previousVelocity.dy,
    );

    return _ticker.start();
  }

  void end() {
    _ticker.stop();
  }

  void _onTick(Duration elapsedTime) {
    assert(_simulationX != null && _simulationY != null, '');

    final simulationX = _simulationX!;
    final simulationY = _simulationY!;

    final elapsedSecondsFraction = elapsedTime.inMilliseconds / 1000.0;

    _springPosition = Offset(
      simulationX.x(elapsedSecondsFraction),
      simulationY.x(elapsedSecondsFraction),
    );

    _previousVelocity = Offset(
      simulationX.dx(elapsedSecondsFraction),
      simulationY.dx(elapsedSecondsFraction),
    );

    notifyListeners();

    if (simulationX.isDone(elapsedSecondsFraction) &&
        simulationY.isDone(elapsedSecondsFraction)) {
      end();
    }
  }
}

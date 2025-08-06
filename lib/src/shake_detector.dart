import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetector {
  final VoidCallback onPhoneShake;

  final double shakeThresholdGravity;

  final int minTimeBetweenShakes;

  final int shakeCountResetTime;

  final int minShakeCount;

  int shakeCount = 0;

  int lastShakeTimestamp = DateTime.now().millisecondsSinceEpoch;

  StreamSubscription? streamSubscription;
  bool _isListening = false;

  ShakeDetector({
    required this.onPhoneShake,
    this.shakeThresholdGravity = 1.25,
    this.minTimeBetweenShakes = 160,
    this.shakeCountResetTime = 1500,
    this.minShakeCount = 3,
  });

  void startListening() {
    if (_isListening) return;

    try {
      streamSubscription = userAccelerometerEvents.listen(
        (event) {
          var gX = event.x / 9.81;
          var gY = event.y / 9.81;
          var gZ = event.z / 9.81;

          var gForce = sqrt(gX * gX + gY * gY + gZ * gZ);
          if (gForce > shakeThresholdGravity) {
            var now = DateTime.now().millisecondsSinceEpoch;
            if (lastShakeTimestamp + minTimeBetweenShakes > now) {
              return;
            }

            if (lastShakeTimestamp + shakeCountResetTime < now) {
              shakeCount = 0;
            }

            lastShakeTimestamp = now;
            if (++shakeCount >= minShakeCount) {
              shakeCount = 0;
              onPhoneShake();
            }
          }
        },
        onError: (error) {
          _isListening = false;
        },
      );
      _isListening = true;
    } catch (e) {
      _isListening = false;
    }
  }

  void stopListening() {
    if (streamSubscription != null) {
      try {
        streamSubscription!.cancel();
      } catch (e) {}
      streamSubscription = null;
    }
    _isListening = false;
  }

  bool get isListening => _isListening;
}

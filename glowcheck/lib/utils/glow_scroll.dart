import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class GlowScrollBehavior extends MaterialScrollBehavior {
  const GlowScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.unknown,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    if (kIsWeb) {
      return const GlowWebScrollPhysics(parent: AlwaysScrollableScrollPhysics());
    }
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    if (kIsWeb) return child;
    return super.buildOverscrollIndicator(context, child, details);
  }

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    if (kIsWeb) return child;
    return super.buildScrollbar(context, child, details);
  }

  @override
  MultitouchDragStrategy getMultitouchDragStrategy(BuildContext context) {
    return MultitouchDragStrategy.latestPointer;
  }
}

/// Clamping (no fake iOS bounce on CanvasKit) but with a quicker fling so the
/// finger does not feel glued to the page after lift.
class GlowWebScrollPhysics extends ClampingScrollPhysics {
  const GlowWebScrollPhysics({super.parent});

  @override
  GlowWebScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return GlowWebScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 0.4,
        stiffness: 210,
        damping: 20,
      );

  @override
  double get minFlingDistance => 8;

  @override
  double get minFlingVelocity => 40;

  @override
  double get maxFlingVelocity => 12000;
}

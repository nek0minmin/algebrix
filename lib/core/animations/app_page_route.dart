import 'package:flutter/material.dart';

/// Ultra-smooth spring page route transition for Algebrix.
///
/// Features a subtle scale expansion (0.97 -> 1.0) and ease-out cubic opacity fade,
/// giving the app a fluid, native iOS/Duolingo feel.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  AppPageRoute({
    Widget? child,
    WidgetBuilder? builder,
    super.settings,
    super.transitionDuration = const Duration(milliseconds: 320),
    super.reverseTransitionDuration = const Duration(milliseconds: 240),
  })  : assert(child != null || builder != null, 'Either child or builder must be provided'),
        super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              child ?? builder!(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (MediaQuery.disableAnimationsOf(context)) {
              return child;
            }

            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        );
}

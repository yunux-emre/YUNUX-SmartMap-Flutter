import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 120,
    this.lottiePath = 'assets/map_animation.json',
  });

  final double size;
  final String lottiePath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        lottiePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Image.asset(
              'assets/app_logo.png',
              width: size,
              height: size,
            ),
          );
        },
      ),
    );
  }
}

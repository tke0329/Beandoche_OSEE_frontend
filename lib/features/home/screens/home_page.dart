import 'package:beandoche_osee_frontend/core/theme/osee_theme.dart';

import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.open});
  final ValueChanged<int> open;
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 800;
    final headline = TextStyle(
      fontFamily: 'CrimsonPro',
      fontSize: wide ? 108 : 49,
      fontWeight: FontWeight.bold,
      height: 1.06,
      color: OseePalette.primary900,
      shadows: const [
        Shadow(
          color: OseePalette.shadowDeep,
          offset: Offset(3, 4),
          blurRadius: 3,
        ),
      ],
    );
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: wide ? 64 : 24,
          top: wide ? 102 : 100,
          right: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Before you buy,', style: headline),
            SizedBox(height: wide ? 20 : 28),
            Text('OSEE', style: headline),
            Transform.translate(
              offset: Offset(wide ? 24 : 12, wide ? -24 : -7),
              child: RotatedBox(
                quarterTurns: 2,
                child: Text(
                  'OSEE',
                  style: headline.copyWith(
                    color: OseePalette.primary200,
                    shadows: const [
                      Shadow(
                        color: OseePalette.shadowStrong,
                        offset: Offset(-2, -3),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!wide) ...[
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => open(1),
                child: const Text('옷 둘러보기 →'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

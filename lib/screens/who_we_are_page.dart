import 'package:flutter/material.dart';

import '../widgets/worldscore_header.dart';

class WhoWeArePage extends StatelessWidget {
  const WhoWeArePage({super.key, required this.role});

  final WorldScoreRole role;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF031C14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WorldScoreHeader(
                subtitle: 'Who We Are',
                role: role,
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF072E21),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF165D43)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Our Inspiration',
                          style: TextStyle(
                            color: Color(0xFF3CE081),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'WorldScore AI was born from a simple question: why is scoring '
                          'in golf still stuck in the pen-and-paper era? Between '
                          'illegible handwriting, manual data entry errors, and the hours '
                          'directors spend compiling results, we knew technology could do '
                          'better.\n\n'
                          'By combining OCR-powered scorecard scanning with intelligent '
                          'data extraction, WorldScore AI lets players snap a photo of '
                          'their scorecard and have their round recorded in seconds — '
                          'accurate, fast, and hassle-free. For directors, that means '
                          'real-time leaderboards and zero data-entry headaches.\n\n'
                          'We are building the future of golf scoring — one round at a time.',
                          style: TextStyle(
                            color: Color(0xFF9AC3B7),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
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

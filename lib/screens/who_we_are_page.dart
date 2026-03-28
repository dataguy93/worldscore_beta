import 'package:flutter/material.dart';

class WhoWeArePage extends StatelessWidget {
  const WhoWeArePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF031C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF083A28),
        foregroundColor: Colors.white,
        title: const Text('Who We Are'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Meet the Founders',
              style: TextStyle(
                color: Color(0xFF3CE081),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            _FounderCard(
              name: 'Dalton Stout',
              bio:
                  'A lifelong golfer and technology enthusiast, Dalton saw firsthand '
                  'how tedious and error-prone manual scorekeeping could be — '
                  'especially during tournaments. With a background in software '
                  'development, he set out to build a smarter way to capture and '
                  'manage golf scores using the latest in AI and image recognition.',
            ),
            const SizedBox(height: 20),
            _FounderCard(
              name: 'Willis Perry',
              bio:
                  'Willis brings years of experience organizing and directing golf '
                  'tournaments at every level. Frustrated by clunky spreadsheets '
                  'and the constant back-and-forth of collecting scorecards, he '
                  'partnered with Dalton to create a tool that makes tournament '
                  'management effortless for directors and players alike.',
            ),
            const SizedBox(height: 28),
            Container(
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
          ],
        ),
      ),
    );
  }
}

class _FounderCard extends StatelessWidget {
  const _FounderCard({required this.name, required this.bio});

  final String name;
  final String bio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF072E21),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF165D43)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A4A32),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF1E8F5C)),
                ),
                child: const Icon(Icons.person, color: Color(0xFF3CE081), size: 26),
              ),
              const SizedBox(width: 14),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            bio,
            style: const TextStyle(
              color: Color(0xFF9AC3B7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class HowItWorksPage extends StatelessWidget {
  const HowItWorksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF031C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF083A28),
        foregroundColor: Colors.white,
        title: const Text('How It Works'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Scorecard Scanning with AI',
              style: TextStyle(
                color: Color(0xFF3CE081),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'WorldScore AI uses Optical Character Recognition (OCR) to turn '
              'a photo of your paper scorecard into digital data — instantly.',
              style: TextStyle(
                color: Color(0xFF9AC3B7),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            _StepCard(
              stepNumber: '1',
              title: 'Snap a Photo',
              description:
                  'Take a clear picture of your completed scorecard using your '
                  'phone camera. Make sure all holes, scores, and player names '
                  'are visible.',
            ),
            const SizedBox(height: 16),
            _StepCard(
              stepNumber: '2',
              title: 'OCR Processing',
              description:
                  'Our AI engine analyzes the image, detecting the scorecard '
                  'layout and extracting text from each cell. It identifies hole '
                  'numbers, par values, and individual scores — even from '
                  'handwritten entries.',
            ),
            const SizedBox(height: 16),
            _StepCard(
              stepNumber: '3',
              title: 'Data Extraction',
              description:
                  'The recognized text is mapped to a structured format: player '
                  'name, course, date, and hole-by-hole scores. The system '
                  'calculates totals and flags anything that looks unusual for '
                  'your review.',
            ),
            const SizedBox(height: 16),
            _StepCard(
              stepNumber: '4',
              title: 'Review & Confirm',
              description:
                  'You get a chance to review the extracted data before it is '
                  'saved. Correct any misreads, confirm the details, and submit. '
                  'Your round is now recorded and ready for leaderboards and '
                  'stats.',
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
                    'Tips for Best Results',
                    style: TextStyle(
                      color: Color(0xFF3CE081),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12),
                  _TipRow(text: 'Use good lighting — avoid shadows across the card'),
                  SizedBox(height: 8),
                  _TipRow(text: 'Keep the scorecard flat and fully in frame'),
                  SizedBox(height: 8),
                  _TipRow(text: 'Write scores clearly — large, dark numbers work best'),
                  SizedBox(height: 8),
                  _TipRow(text: 'Avoid crumpled or heavily folded scorecards'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.description,
  });

  final String stepNumber;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF072E21),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF165D43)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF0A4A32),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1E8F5C)),
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: const TextStyle(
                color: Color(0xFF3CE081),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF9AC3B7),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check_circle_outline, color: Color(0xFF3CE081), size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF9AC3B7),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

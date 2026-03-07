import 'package:flutter/material.dart';

class ValuationPage extends StatelessWidget {
  const ValuationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Why ₱99 is worth it')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comparison', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('• Less than two milk teas'),
            Text('• Less than one Jollibee meal'),
            SizedBox(height: 12),
            Text('But it gives you a daily financial coach for an entire month.'),
          ],
        ),
      ),
    );
  }
}

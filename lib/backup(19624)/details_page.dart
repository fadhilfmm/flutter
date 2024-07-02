import 'package:flutter/material.dart';

class DetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailsPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${data['name']}', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text('Time Detected: ${data['time_detected']}',
                style: const TextStyle(fontSize: 20)),
            // Tambahkan detail lainnya di sini jika ada
          ],
        ),
      ),
    );
  }
}

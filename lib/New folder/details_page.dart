import 'package:flutter/material.dart';

class DetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailsPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    String name = data['name'] ?? 'No Name';
    String timeDetected = data['time_detected'] ?? 'Unknown Time';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Name: $name',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Time Detected: $timeDetected',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            // Add more details here if needed
          ],
        ),
      ),
    );
  }
}

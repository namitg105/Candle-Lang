import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Displays the encoded string with symbol colouring and a copy button.
class EncodedStringCard extends StatelessWidget {
  final String encoded;

  const EncodedStringCard({super.key, required this.encoded});

  static const _symbolColors = {
    'U': Color(0xFF26A69A), // bullish green
    'D': Color(0xFFEF5350), // bearish red
    'F': Color(0xFF78909C), // flat grey-blue
    'G': Color(0xFFFFCA28), // gap yellow
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Encoded String',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text('Length: ${encoded.length}',
                    style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy to clipboard',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: encoded));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Encoded string copied'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    letterSpacing: 1.5,
                  ),
                  children: encoded.split('').map((ch) {
                    return TextSpan(
                      text: ch,
                      style: TextStyle(
                        color: _symbolColors[ch] ?? Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

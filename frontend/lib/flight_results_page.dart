import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

const Map<String, String> kAirlineNames = {
  'LH': 'Lufthansa',
  'RO': 'Tarom',
  'AF': 'Air France',
  'KL': 'KLM',
  'BA': 'British Airways',
  'W6': 'Wizz Air',
  'FR': 'Ryanair',
  'AZ': 'ITA Airways',
  'TK': 'Turkish Airlines',
  'OS': 'Austrian Airlines',
  'LO': 'LOT Polish Airlines',
  'SU': 'Aeroflot',
  'QR': 'Qatar Airways',
  'EK': 'Emirates',
  'UA': 'United Airlines',
  'AA': 'American Airlines',
  'DL': 'Delta Air Lines',
  'LX': 'SWISS',
  'IB': 'Iberia',
  'VY': 'Vueling',
};

class FlightResultsPage extends StatelessWidget {
  final List flights;
  const FlightResultsPage({
    super.key,
    required this.flights,
  });

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  String _formatDateTime(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      final y = dt.year.toString().padLeft(4, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$y-$m-$d $h:$min';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flight Results', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF5B85AA),
        elevation: 4,
      ),
      body: flights.isEmpty
          ? Center(
              child: Text('No flights found.', style: GoogleFonts.poppins(fontSize: 16)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: flights.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, idx) {
                final flight = flights[idx];
                final segments = flight['itineraries']?[0]['segments'] as List? ?? [];
                final firstSeg = segments.isNotEmpty ? segments.first : null;
                final lastSeg = segments.isNotEmpty ? segments.last : null;
                final carrierCode = firstSeg?['carrierCode'] as String? ?? '';
                final airlineName = flight['airline_name'] as String? ?? (kAirlineNames[carrierCode] ?? carrierCode);
                final origin = firstSeg?['departure']?['iataCode'] ?? '';
                final destination = lastSeg?['arrival']?['iataCode'] ?? '';
                final departureRaw = firstSeg?['departure']?['at']?.toString() ?? '';
                final arrivalRaw = lastSeg?['arrival']?['at']?.toString() ?? '';
                final departure = _formatDateTime(departureRaw);
                final arrival = _formatDateTime(arrivalRaw);
                final price = flight['price']?['total'];
                final currency = flight['price']?['currency'] ?? 'EUR';
                final stops = segments.length - 1;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flight, color: Color(0xFF5B85AA), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$airlineName  |  $origin → $destination',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Departure: $departure', style: GoogleFonts.poppins(fontSize: 14)),
                        Text('Arrival: $arrival', style: GoogleFonts.poppins(fontSize: 14)),
                        Text(
                          stops == 0 ? 'Non-stop' : '$stops stop${stops > 1 ? 's' : ''}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: stops == 0 ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (price != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Price: $price $currency',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF5B85AA)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Estimated price — final price on airline site',
                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                          ),
                        ],
                        const Divider(height: 20),
                        if (flight['checkin_link'] != null) ...[
                          Text('Check-in:', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          _BookButton(label: 'Check-in', onTap: () => _launchUrl(flight['checkin_link'])),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _BookButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _BookButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF5B85AA),
        side: const BorderSide(color: Color(0xFF5B85AA)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}


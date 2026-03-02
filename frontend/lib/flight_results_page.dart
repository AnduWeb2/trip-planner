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
  const FlightResultsPage({super.key, required this.flights});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
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
                final airlineName = kAirlineNames[carrierCode] ?? carrierCode;
                final origin = firstSeg?['departure']?['iataCode'] ?? '';
                final destination = lastSeg?['arrival']?['iataCode'] ?? '';
                final departure = firstSeg?['departure']?['at']?.toString().substring(0, 16) ?? '';
                final arrival = lastSeg?['arrival']?['at']?.toString().substring(0, 16) ?? '';
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
                        ],
                        const Divider(height: 20),
                        Text('Book on:', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (flight['tarom_direct_booking_link'] != null)
                              _BookButton(label: 'Tarom', onTap: () => _launchUrl(flight['tarom_direct_booking_link'])),
                            if (flight['british_airways_direct_booking_link'] != null)
                              _BookButton(label: 'British Airways', onTap: () => _launchUrl(flight['british_airways_direct_booking_link'])),
                            if (flight['airline_booking_link'] != null &&
                                flight['tarom_direct_booking_link'] == null &&
                                flight['british_airways_direct_booking_link'] == null)
                              _BookButton(label: airlineName, onTap: () => _launchUrl(flight['airline_booking_link'])),
                            if (flight['google_flights_link'] != null)
                              _BookButton(label: 'Google Flights', onTap: () => _launchUrl(flight['google_flights_link'])),
                            if (flight['skyscanner_link'] != null)
                              _BookButton(label: 'Skyscanner', onTap: () => _launchUrl(flight['skyscanner_link'])),
                            if (flight['expedia_link'] != null)
                              _BookButton(label: 'Expedia', onTap: () => _launchUrl(flight['expedia_link'])),
                          ],
                        ),
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


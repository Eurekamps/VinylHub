import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/vinyl_model.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  List<VinylPrice>? _vinylPrices;

  void _fetchPrices() async {
    final vinylName = _controller.text;
    if (vinylName.isNotEmpty) {
      try {
        final prices = await ApiService.fetchVinylPrices(vinylName);
        setState(() {
          _vinylPrices = prices;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error fetching prices: $e'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vinyl Price Comparator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Vinyl Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPrices,
              child: Text('Compare Prices'),
            ),
            Expanded(
              child: _vinylPrices == null
                  ? Center(child: Text('Enter a vinyl name to compare prices'))
                  : ListView.builder(
                itemCount: _vinylPrices!.length,
                itemBuilder: (context, index) {
                  final vinyl = _vinylPrices![index];
                  return ListTile(
                    title: Text(vinyl.store),
                    subtitle: Text('Price: \$${vinyl.price}'),
                    onTap: () => launchUrl(vinyl.url),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void launchUrl(String url) {
    // Implementa un paquete como url_launcher para abrir enlaces
  }
}

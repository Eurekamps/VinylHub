import 'package:flutter/material.dart';
import 'services/discogs_service.dart';

class SearchVinylPage extends StatefulWidget {
  @override
  _SearchVinylPageState createState() => _SearchVinylPageState();
}

class _SearchVinylPageState extends State<SearchVinylPage> {
  final DiscogsService _discogsService = DiscogsService();
  final TextEditingController _searchController = TextEditingController();

  Future<List<dynamic>>? _searchResults;

  void _search() {
    setState(() {
      _searchResults = _discogsService.searchVinyl(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Buscar Vinilos")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Buscar",
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
            ),
            Expanded(
              child: _searchResults == null
                  ? Center(child: Text("Ingresa un término para buscar"))
                  : FutureBuilder<List<dynamic>>(
                future: _searchResults,
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text(
                            "Error: ${snapshot.error.toString()}"));
                  } else if (!snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return Center(child: Text("No se encontraron datos"));
                  }

                  final results = snapshot.data!;
                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final item = results[index];
                      return ListTile(
                        leading: item['cover_image'] != null
                            ? Image.network(item['cover_image'])
                            : null,
                        title: Text(item['title'] ?? "Sin título"),
                        subtitle: Text(
                            item['year']?.toString() ?? "Año desconocido"),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

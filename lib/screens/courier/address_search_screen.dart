import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AddressSearchScreen extends StatefulWidget {
  const AddressSearchScreen({super.key});

  @override
  State<AddressSearchScreen> createState() => _AddressSearchScreenState();
}

class _AddressSearchScreenState extends State<AddressSearchScreen> {
  List results = [];
  bool isLoading = false;

  Future<void> searchAddress(String query) async {
    if (query.length < 3) return;

    setState(() => isLoading = true);

    final url =
        "https://nominatim.openstreetmap.org/search?q=$query&format=json";

    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'com.qadampayk.app'},
    );

    if (response.statusCode == 200) {
      setState(() {
        results = json.decode(response.body);
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search Address")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Search location...",
                border: OutlineInputBorder(),
              ),
              onChanged: searchAddress,
            ),
          ),
          if (isLoading) const CircularProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final place = results[index];

                return ListTile(
                  title: Text(place['display_name']),
                  onTap: () {
                    Navigator.pop(context, {
                      "lat": double.parse(place['lat']),
                      "lng": double.parse(place['lon']),
                      "address": place['display_name']
                    });
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

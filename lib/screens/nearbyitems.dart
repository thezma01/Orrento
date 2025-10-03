import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/ItemModel.dart';
// import '../models/item_model.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  List<ItemModel> nearbyItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNearbyItems();
  }

  Future<void> fetchNearbyItems() async {
    final url = Uri.parse(
      'http://10.0.2.2:5297/api/items/nearby?lat=24.8607&lng=67.0011',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          nearbyItems = jsonData
              .map((json) => ItemModel.fromJson(json))
              .toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load items');
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Items')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : nearbyItems.isEmpty
              ? const Center(child: Text('No items found nearby'))
              : ListView.builder(
                  itemCount: nearbyItems.length,
                  itemBuilder: (context, index) {
                    final item = nearbyItems[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        leading: item.imageUrls.isNotEmpty
                            ? Image.network(
                                item.imageUrls.first,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.image),
                        title: Text(item.title),
                        subtitle: Text('PKR ${item.pricePerDay}/day'),
                        trailing: Text(item.pickupLocation),
                      ),
                    );
                  },
                ),
    );
  }
}

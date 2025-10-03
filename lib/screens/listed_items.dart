import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ListedItemsScreen extends StatefulWidget {
  final int userId;

  const ListedItemsScreen({super.key, required this.userId});

  @override
  State<ListedItemsScreen> createState() => _ListedItemsScreenState();
}

class _ListedItemsScreenState extends State<ListedItemsScreen> {
  final Color primaryColor = const Color.fromARGB(255, 14, 44, 85);
  final Color lightBgColor = const Color.fromARGB(255, 248, 249, 252);

  late Future<List<dynamic>> _listedItems;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _listedItems = _fetchListedItems();
  }

  Future<List<dynamic>> _fetchListedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      throw Exception("No auth token found");
    }

    final response = await http.get(
      Uri.parse("http://10.0.2.2:5297/api/rentalrequest/received/${widget.userId}"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data.containsKey("listedItems")) return data["listedItems"];
      if (data is Map && data.containsKey("data")) return data["data"];
      return [];
    } else {
      throw Exception("Failed to load listed items: ${response.statusCode}");
    }
  }

  Future<void> _deleteItem(int itemId) async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.delete(
      Uri.parse("http://10.0.2.2:5297/api/item/$itemId"),
      headers: {"Authorization": "Bearer $token"},
    );

    setState(() => _isLoading = false);

    if (response.statusCode == 200) {
      setState(() => _listedItems = _fetchListedItems());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Item deleted successfully"),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to delete item: ${response.body}"),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showDeleteDialog(int itemId, String itemName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Delete Item",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
          content: Text(
            "Are you sure you want to delete '$itemName'?",
            style: GoogleFonts.poppins(),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "No",
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteItem(itemId);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      "Yes, Delete",
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
            ),
          ],
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "Approved":
        return Colors.green;
      case "Pending":
        return Colors.orange;
      case "Rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _buildImageUrl(dynamic imageUrls) {
    if (imageUrls == null) return "";
    if (imageUrls is List && imageUrls.isNotEmpty) {
      return "http://10.0.2.2:5297${imageUrls[0]}";
    }
    if (imageUrls is String && imageUrls.isNotEmpty) {
      final urls = imageUrls.split(RegExp(r"[;,]"));
      return "http://10.0.2.2:5297${urls.first}";
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text("My Listed Items"),
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _listedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text("⚠️ Error: ${snapshot.error}",
                  style: GoogleFonts.poppins(color: Colors.red)),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text("No listed items found",
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w500)),
            );
          }

          final items = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final request = items[index];
              final item = request["item"] ?? {};
              final status = request["status"] ?? "Pending";
              final statusColor = _getStatusColor(status);

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🔹 Thumbnail
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _buildImageUrl(item["imageUrls"]),
                              height: 50,
                              width: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                height: 50,
                                width: 50,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported,
                                    color: Colors.grey, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // 🔹 Title + Price + Renter
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item["title"] ?? "Untitled Item",
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Price: Rs. ${item["pricePerDay"] ?? "N/A"}/day",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Requested by: ${request["renter"]?["fullName"] ?? "Unknown"}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 🔹 Delete Icon
                          IconButton(
                            onPressed: () => _showDeleteDialog(
                                item["id"] ?? 0, item["title"] ?? "Untitled"),
                            icon: const Icon(Icons.delete, color: Colors.red),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 🔹 Status badge
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

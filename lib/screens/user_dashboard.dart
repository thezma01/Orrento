import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import your view all screens
import 'listed_items.dart';
import 'rental_requests.dart';
import 'received_requests.dart';

class DashboardScreen extends StatefulWidget {
  final int userId;

  const DashboardScreen({super.key, required this.userId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final Color primaryColor = const Color.fromARGB(255, 14, 44, 85);
  final Color accentColor = const Color.fromARGB(255, 255, 190, 50);
  final Color lightBgColor = const Color.fromARGB(255, 248, 249, 252);

  late Future<Map<String, dynamic>> _dashboardData;

  @override
  void initState() {
    super.initState();
    _dashboardData = fetchDashboard();
  }

  // Navigation methods to view all screens
  void _navigateToListedItems() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListedItemsScreen(userId: widget.userId),
      ),
    );
  }

  void _navigateToRentalRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RentalRequestsScreen(userId: widget.userId),
      ),
    );
  }

  void _navigateToReceivedRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReceivedRequestsScreen(userId: widget.userId),
      ),
    );
  }

  Future<Map<String, dynamic>> fetchDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse("http://10.0.2.2:5297/api/users/dashboard/${widget.userId}"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load dashboard: ${response.statusCode}");
    }
  }

  Future<void> deleteItem(int itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

final response = await http.delete(
  Uri.parse("http://10.0.2.2:5297/api/item/$itemId"),
  headers: {"Authorization": "Bearer $token"},
);

    if (response.statusCode == 200) {
      setState(() => _dashboardData = fetchDashboard());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Item deleted successfully'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete item: ${response.body}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
  
  Future<void> cancelRentalRequest(int requestId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse("http://10.0.2.2:5297/api/rentalrequest/$requestId"),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      setState(() => _dashboardData = fetchDashboard());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Rental request cancelled'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel: ${response.body}'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> updateRequestStatus(int requestId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse(
        "http://10.0.2.2:5297/api/rentalrequest/update-status/$requestId?status=$status");

    try {
      final response = await http.put(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        setState(() {
          _dashboardData = fetchDashboard();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Status updated to $status"),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        throw Exception("Failed to update request: ${response.body}");
      }
    } catch (e) {
      print("Error updating request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Something went wrong."),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBgColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Text('Dashboard'),
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromARGB(255, 14, 44, 85)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Loading your dashboard...",
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Error: ${snapshot.error}",
                    style: GoogleFonts.poppins(
                      color: Colors.grey.shade700,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _dashboardData = fetchDashboard();
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      "Try Again",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            final data = snapshot.data!;
            final listedItems = data['listedItems'] ?? [];
            final rentalRequests = data['rentalRequests'] ?? [];
            final receivedRequests = data['receivedRequests'] ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Updated to make section header tappable
                  _sectionHeader("📦 My Listed Items", listedItems.isNotEmpty,
                      _navigateToListedItems),
                  const SizedBox(height: 12),
                  if (listedItems.isEmpty)
                    _emptyState("You have not listed any items yet."),
                  ...listedItems.map<Widget>((item) {
                    final imageUrl = _buildImageUrl(item['imageUrls']);
                    return _itemCard(
                      title: item['title'] ?? 'Untitled',
                      subtitle: "Price per day: Rs. ${item['pricePerDay']}",
                      imageUrl: imageUrl,
                      status: "Active",
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteDialog(item['id']),
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 32),
                  _divider(),
                  const SizedBox(height: 24),

                  // Updated to make section header tappable
                  _sectionHeader("📝 My Rental Requests",
                      rentalRequests.isNotEmpty, _navigateToRentalRequests),
                  const SizedBox(height: 12),
                  if (rentalRequests.isEmpty)
                    _emptyState("You have not made any rental requests."),
                  ...rentalRequests.map<Widget>((req) {
                    final item = req['item'];
                    final imageUrl =
                        item != null ? _buildImageUrl(item['imageUrls']) : null;
                    return _itemCard(
                      title: item?['title'] ?? 'Unknown Item',
                      subtitle:
                          "Requested on: ${_formatDate(req['startDate'])}",
                      imageUrl: imageUrl,
                      status: req['status'],
                      trailing: req['status'] == "Pending"
                          ? IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _showCancelDialog(req['id']),
                            )
                          : null,
                    );
                  }).toList(),

                  const SizedBox(height: 32),
                  _divider(),
                  const SizedBox(height: 24),

                  // Updated to make section header tappable
                  _sectionHeader("📨 Requests for My Items",
                      receivedRequests.isNotEmpty, _navigateToReceivedRequests),
                  const SizedBox(height: 12),
                  if (receivedRequests.isEmpty)
                    _emptyState("No one has requested your items yet."),
                  ...receivedRequests.map<Widget>((req) {
                    final item = req['item'];
                    final renter = req['renter'];
                    final imageUrl =
                        item != null ? _buildImageUrl(item['imageUrls']) : null;
                    final status = req['status'];

                    return _itemCard(
                      title: item?['title'] ?? 'Unknown Item',
                      subtitle:
                          "Requested by: ${renter?['fullName'] ?? 'Unknown'}\nDate: ${_formatDate(req['startDate'])}",
                      imageUrl: imageUrl,
                      status: status,
                      trailing: status == "Pending"
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _actionButton(
                                  Icons.check_circle,
                                  Colors.green.shade700,
                                  "Approve",
                                  () => updateRequestStatus(
                                      req['id'], "Approved"),
                                ),
                                const SizedBox(width: 8),
                                _actionButton(
                                  Icons.cancel,
                                  Colors.red.shade700,
                                  "Reject",
                                  () => updateRequestStatus(
                                      req['id'], "Rejected"),
                                ),
                              ],
                            )
                          : status == "Approved"
                              ? _actionButton(
                                  Icons.chat,
                                  Colors.blue.shade700,
                                  "Chat",
                                  () {
                                    Navigator.pushNamed(context, '/chat',
                                        arguments: {
                                          "requestId": req['id'],
                                          "renterId": renter?['id'],
                                        });
                                  },
                                )
                              : null,
                    );
                  }).toList(),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // Updated _sectionHeader to accept onTap callback
  Widget _sectionHeader(String title, bool hasItems, VoidCallback? onTap) {
    return GestureDetector(
      onTap: hasItems ? onTap : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title.split(' ')[0], // Icon part
                style: GoogleFonts.poppins(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.substring(title.indexOf(' ') + 1),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (hasItems)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "View all",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_outline, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard({
    required String title,
    required String subtitle,
    required String? imageUrl,
    required String status,
    required Widget? trailing,
  }) {
    Color statusColor = Colors.grey;
    if (status == "Approved") statusColor = Colors.green;
    if (status == "Pending") statusColor = Colors.orange;
    if (status == "Rejected") statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2,
                              color: primaryColor,
                            ),
                          );
                        },
                      )
                    : Icon(
                        Icons.image_not_supported,
                        size: 30,
                        color: Colors.grey.shade400,
                      ),
              ),
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            trailing: trailing,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.transparent,
            Colors.grey.shade300,
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
      IconData icon, Color color, String tooltip, VoidCallback onPressed) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(icon, color: color, size: 20),
          onPressed: onPressed,
        ),
      ),
    );
  }

  void _showDeleteDialog(int itemId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Confirm Delete",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
          content: Text(
            "Are you sure you want to delete this item? This action cannot be undone.",
            style: GoogleFonts.poppins(),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                deleteItem(itemId);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Delete",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCancelDialog(int requestId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Cancel Request",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
          content: Text(
            "Are you sure you want to cancel this rental request?",
            style: GoogleFonts.poppins(),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                cancelRentalRequest(requestId);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Yes, Cancel",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return "Unknown date";

    try {
      final date = DateTime.parse(dateString);
      return "${date.day}/${date.month}/${date.year}";
    } catch (e) {
      return "Invalid date";
    }
  }

  String? _buildImageUrl(dynamic imageList) {
    if (imageList == null) return null;

    List<String> urls = [];

    if (imageList is List && imageList.isNotEmpty) {
      if (imageList.length == 1 &&
          imageList[0] is String &&
          (imageList[0] as String).contains(',')) {
        urls =
            (imageList[0] as String).split(',').map((s) => s.trim()).toList();
      } else {
        urls = List<String>.from(imageList);
      }
    } else if (imageList is String && imageList.isNotEmpty) {
      urls = imageList.split(',').map((s) => s.trim()).toList();
    }

    if (urls.isNotEmpty) {
      final rawPath = urls[0].replaceAll(RegExp(r'\\+'), '/');
      if (rawPath.startsWith('http')) {
        return rawPath;
      }
      return rawPath.startsWith('/')
          ? "http://10.0.2.2:5297$rawPath"
          : "http://10.0.2.2:5297/$rawPath";
    }

    return null;
  }
}

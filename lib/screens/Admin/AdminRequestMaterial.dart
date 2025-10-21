import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminRequestsPage extends StatefulWidget {
  const AdminRequestsPage({Key? key}) : super(key: key);

  @override
  _AdminRequestsPageState createState() => _AdminRequestsPageState();
}

class _AdminRequestsPageState extends State<AdminRequestsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _requestsStream;
  String _filterStatus = 'pending'; // Default filter for pending requests
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestsStream = _firestore
        .collection('material_requests')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: const Text('Manage Requests', style: TextStyle(color: Colors.white),),
    backgroundColor: Colors.blueAccent,
    elevation: 0,
    shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),),
    actions: [
    IconButton(
    icon: const Icon(Icons.search),
    onPressed: () => _showSearchDialog(context),
    ),
    ],
    ),
    body: Column(
    children: [
    _buildStatusFilterBar(),
    Expanded(
    child: StreamBuilder<QuerySnapshot>(
    stream: _requestsStream,
    builder: (context, snapshot) {
    if (snapshot.hasError) {
    return _buildErrorWidget(snapshot.error.toString());
    }

    if (snapshot.connectionState == ConnectionState.waiting) {
    return _buildLoadingWidget();
    }

    final filteredDocs = snapshot.data!.docs.where((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return _filterStatus == 'all' ||
    data['status'] == _filterStatus;
    }).toList();

    if (filteredDocs.isEmpty) {
    return _buildEmptyState();
    }

    return RefreshIndicator(
    onRefresh: () async {
    setState(() {});
    },
    child: ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: filteredDocs.length,
    separatorBuilder: (context, index) => const SizedBox(height: 12),
    itemBuilder: (context, index) {
    var request = filteredDocs[index];
    var data = request.data() as Map<String, dynamic>;
    return _buildRequestCard(request.id, data);
    },
    ),
    );
    },
    ),
    ),
    ],
    ),
    );
  }

  Widget _buildStatusFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Pending', 'pending'),
          const SizedBox(width: 8),
          _buildFilterChip('Approved', 'approved'),
          const SizedBox(width: 8),
          _buildFilterChip('Rejected', 'rejected'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _filterStatus == value,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? value : 'pending';
        });
      },
      selectedColor: Colors.blueAccent,
      labelStyle: TextStyle(
        color: _filterStatus == value ? Colors.white : Colors.blueAccent,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.blueAccent),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading requests',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading requests...',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _filterStatus == 'pending'
                ? 'No pending requests'
                : 'No ${_filterStatus} requests',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by material or requester...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    // Implement search functionality
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Implement search
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Search'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestCard(String requestId, Map<String, dynamic> data) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (data['status']) {
      case 'approved':
        statusColor = Colors.green.shade100;
        statusIcon = Icons.check_circle_outline;
        statusText = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red.shade100;
        statusIcon = Icons.cancel_outlined;
        statusText = 'Rejected';
        break;
      default:
        statusColor = Colors.orange.shade100;
        statusIcon = Icons.pending_actions;
        statusText = 'Pending';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data['materialName'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Requested by: ${data['requesterName']}',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quantity: ${data['quantityRequested']} ${data['unit']}',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM dd, yyyy - hh:mm a').format(
                (data['timestamp'] as Timestamp).toDate(),
              ),
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            if (data['notes'] != null && data['notes'].toString().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Notes: ${data['notes']}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            if (data['status'] == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _rejectRequest(requestId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _approveRequest(requestId, data),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Approve', style: TextStyle(color: Colors.white),),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _approveRequest(String requestId, Map<String, dynamic> requestData) async {
    try {
      // Create a batch to perform both operations atomically
      final batch = _firestore.batch();

      // Get references to both documents
      final requestRef = _firestore.collection('material_requests').doc(requestId);
      final materialRef = _firestore.collection('materials').doc(requestData['materialId']);

      // Update the request status
      batch.update(requestRef, {
        'status': 'approved',
        'processedAt': DateTime.now(),
        'processedBy': 'admin_user_id', // Add admin user ID if needed
      });

      // Deduct the quantity from stock
      batch.update(materialRef, {
        'quantity': FieldValue.increment(-requestData['quantityRequested']),
        'lastUpdated': DateTime.now(),
      });

      // Commit both operations together
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Request approved and stock updated!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    // Optional: Show a dialog for rejection reason
    final TextEditingController reasonController = TextEditingController();

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for rejection:'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: 'Reason for rejection...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Confirm Reject'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _firestore.collection('material_requests').doc(requestId).update({
          'status': 'rejected',
          'rejectionReason': reasonController.text,
          'processedAt': DateTime.now(),
        });

        // Restore the quantity if needed
       /* if (requestData['materialId'] != null) {
          await _firestore.collection('materials').doc(requestData['materialId']).update({
            'quantity': FieldValue.increment(requestData['quantityRequested']),
            'lastUpdated': DateTime.now(),
          });
        }*/

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Request rejected successfully!'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  Future<void> sendTestNotification(String useremail, String serviceName) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendTestNotificationMaterial');
      await callable({
        'title': 'New Booking $serviceName',
        'message': 'You have new booking request service: $serviceName orderid: $useremail',
      });
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }

  Future<void> sendTestNotification1(String useremail, String serviceName) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendTestNotificationMaterial');
      await callable({
        'title': 'New Booking $serviceName',
        'message': 'You have new booking request, Service: $serviceName, User_email: $useremail',
      });
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }
}
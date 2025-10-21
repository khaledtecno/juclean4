import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MaterialRequestsPage extends StatefulWidget {
  const MaterialRequestsPage({Key? key}) : super(key: key);

  @override
  _MaterialRequestsPageState createState() => _MaterialRequestsPageState();
}

class _MaterialRequestsPageState extends State<MaterialRequestsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> _requestsStream;
  late Stream<QuerySnapshot> _materialsStream;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestsStream = _firestore
        .collection('material_requests')
        .orderBy('timestamp', descending: true)
        .snapshots();
    _materialsStream = _firestore.collection('materials').snapshots();
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
        title: const Text('Material Requests', style: TextStyle(color: Colors.white),),
    backgroundColor: Colors.blueAccent,
    elevation: 0,
    shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),),
    actions: [
 /*   IconButton(
    icon: const Icon(Icons.search),
    onPressed: () => _showSearchDialog(context),
    ),*/
    ],
    ),
    body: Container(
    decoration: BoxDecoration(
    gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.deepPurple.shade50, Colors.white],
    ),
    ),
    child: Column(
    children: [
    Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
    children: [
    _buildFilterChip('All', () {}),
    const SizedBox(width: 8),
    _buildFilterChip('Pending', () {}),
    const SizedBox(width: 8),
    _buildFilterChip('Approved', () {}),
    ],
    ),
    ),
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

    if (snapshot.data!.docs.isEmpty) {
    return _buildEmptyState();
    }

    return RefreshIndicator(
    onRefresh: () async {
    setState(() {});
    },
    child: ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: snapshot.data!.docs.length,
    separatorBuilder: (context, index) => const SizedBox(height: 12),
    itemBuilder: (context, index) {
    var request = snapshot.data!.docs[index];
    var data = request.data() as Map<String, dynamic>;
    return _buildRequestCard(data);
    },
    ),
    );
    },
    ),
    ),
    ],
    ),
    ),
    floatingActionButton: FloatingActionButton(
    onPressed: () => _showMaterialSelectionDialog(context),
    backgroundColor: Colors.blueAccent,
    elevation: 4,
    child: const Icon(Icons.add, size: 28),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    ),
    ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onSelected) {
    return FilterChip(
      label: Text(label),
      onSelected: (bool value) => onSelected(),
      backgroundColor: Colors.white,
      selectedColor: Colors.deepPurple.shade200,
      labelStyle: TextStyle(
        color: Colors.deepPurple.shade800,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.deepPurple.shade200),
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
          Image.asset(
            'assets/images/empty_state.png', // Add your own asset
            width: 180,
            height: 180,
          ),
          const SizedBox(height: 16),
          Text(
            'No requests yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first request',
            style: TextStyle(
              color: Colors.grey.shade600,
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
                    hintText: 'Search requests...',
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
                    child: const Text('Search', style: TextStyle(color: Colors.white),),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMaterialSelectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Material',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _materialsStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var material = snapshot.data!.docs[index];
                        var data = material.data() as Map<String, dynamic>;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _showRequestDialog(context, material.id, data);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.inventory_2_outlined,
                                      color: Colors.deepPurple.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${data['quantity']} ${data['unit']} available',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey.shade400,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRequestDialog(BuildContext context, String materialId, Map<String, dynamic> materialData) {
    final _formKey = GlobalKey<FormState>();
    final _quantityController = TextEditingController();
    final _notesController = TextEditingController();
    bool _isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'New Request',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.inventory_2_outlined,
                                  color: Colors.blueAccent
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      materialData['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${materialData['quantity']} ${materialData['unit']} available',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Quantity (${materialData['unit']})',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.format_list_numbered),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter quantity';
                            }
                            if (int.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            if (int.parse(value) > materialData['quantity']) {
                              return 'Not enough stock';
                            }
                            if (int.parse(value) <= 0) {
                              return 'Quantity must be positive';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Notes (optional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.note),
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () async {
                              if (_formKey.currentState!.validate()) {
                                setModalState(() {
                                  _isSubmitting = true;
                                });
                                sendTestNotification(FirebaseAuth.instance.currentUser!.email.toString() ?? 'id', materialData['name']);
                                sendTestNotification1(FirebaseAuth.instance.currentUser!.email.toString() ?? 'id', materialData['name']);
                                final quantityRequested = int.parse(_quantityController.text);

                                try {
                                  // Start a batch write
                                  final batch = _firestore.batch();

                                  // Add the request
                                  final requestRef = _firestore.collection('material_requests').doc();
                                  batch.set(requestRef, {
                                    'materialId': materialId,
                                    'materialName': materialData['name'],
                                    'requesterName': FirebaseAuth.instance.currentUser!.email.toString(),
                                    'requesterId': FirebaseAuth.instance.currentUser!.uid.toString(),
                                    'quantityRequested': quantityRequested,
                                    'unit': materialData['unit'],
                                    'status': 'pending',
                                    'timestamp': DateTime.now(),
                                    'notes': _notesController.text,
                                  });

                                  // Update the stock quantity
                                 /* final materialRef = _firestore
                                      .collection('materials')
                                      .doc(materialId);
                                  batch.update(materialRef, {
                                    'quantity': FieldValue.increment(-quantityRequested),
                                    'lastUpdated': DateTime.now(),
                                  });*/

                                  await batch.commit();

                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Request submitted successfully!'),
                                      backgroundColor: Colors.green.shade600,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );

                                } catch (e) {
                                  setModalState(() {
                                    _isSubmitting = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to submit request: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              'Submit Request',
                              style: TextStyle(fontSize: 16,color: Colors.white,),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> sendTestNotification(String useremail, String serviceName) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendTestNotificationMaterial');
      await callable({
        'title': 'New Material Request $serviceName',
        'message': 'You have new material request material: $serviceName Useremail: $useremail',
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
        'title': 'New Material Request $serviceName',
        'message': 'You have new material request material: $serviceName Useremail: $useremail',
      });
    } catch (e) {
      debugPrint('Error sending test notification: $e');
    }
  }
  Widget _buildRequestCard(Map<String, dynamic> data) {
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

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // Show request details if needed
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      statusIcon,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['materialName'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM dd, yyyy - hh:mm a').format(
                            (data['timestamp'] as Timestamp).toDate(),
                          ),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
                        color: Colors.deepPurple.shade800,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildInfoItem(
                    Icons.format_list_numbered,
                    '${data['quantityRequested']} ${data['unit']}',
                  ),
                  const SizedBox(width: 16),
                  _buildInfoItem(
                    Icons.person_outline,
                    data['requesterName'],
                  ),
                ],
              ),
              if (data['notes'] != null && data['notes'].toString().isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Notes: ${data['notes']}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
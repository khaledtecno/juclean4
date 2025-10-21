import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:juclean/screens/Admin/OrdersScreen.dart';
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  late Stream<QuerySnapshot> _notificationsStream;

  @override
  void initState() {
    super.initState();
    _notificationsStream = _firestore
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data?.docs.isEmpty ?? true) {
            return const Center(child: Text('No notifications yet'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? false;

              return InkWell(
                onTap: () {
                  _markAsRead(doc.id);
                  // Navigate to relevant screen based on notification type
                  if (data['type'] == 'booking') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrdersScreen(),
                      ),
                    );
                  }
                },
                child: Container(
                  color: isRead ? Colors.white : Colors.grey[100],
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['imageUrl'] != null)
                        CircleAvatar(
                          backgroundImage: NetworkImage(data['imageUrl']),
                          radius: 24,
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] ?? 'Notification',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isRead ? Colors.grey : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data['message'] ?? '',
                              style: TextStyle(
                                color: isRead ? Colors.grey : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatDate(data['createdAt']?.toDate()),
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isRead)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(Icons.circle, color: Colors.blue, size: 12),
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

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
  }
}
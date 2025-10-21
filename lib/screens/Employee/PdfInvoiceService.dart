import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PdfInvoiceService {
  static Future<pw.Document> generateInvoice() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    pw.Widget _buildPdfChip(String text) {
      return pw.Container(
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius: pw.BorderRadius.circular(16),
        ),
        padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: pw.EdgeInsets.only(right: 8, bottom: 8),
        child: pw.Text(text, style: pw.TextStyle(fontSize: 10)),
      );
    }
    final employeeEmail = user.email.toString();
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    final dateFormatter = DateFormat('MMMM dd, yyyy');
    final timeFormatter = DateFormat('HH:mm a');

    // Fetch bookings for this employee
    final bookings = await FirebaseFirestore.instance
        .collection('bookings')
        .where('employeeEm', isEqualTo: employeeEmail)
        .get();

    // Create PDF document
    final pdf = pw.Document();

    // Add each booking as a page
    for (final booking in bookings.docs) {
      final data = booking.data();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Cleaning Service Invoice',
                        style: pw.TextStyle(
                            fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text('INV-${booking.id.substring(0, 8).toUpperCase()}',
                        style: pw.TextStyle(fontSize: 16)),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(),
                pw.SizedBox(height: 20),

                // Employee & Client Info
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Employee Info
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Service Provider',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold, fontSize: 16)),
                          pw.Text(data['employee']['Name'] ?? 'N/A'),
                          pw.Text(data['employeeEm'] ?? 'N/A'),
                          pw.Text(data['employee']['Phone'] ?? 'N/A'),
                          pw.SizedBox(height: 10),
                          pw.Text('Generated on: ${formatter.format(now)}'),
                        ],
                      ),
                    ),

                    // Client Info
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Client Information',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold, fontSize: 16)),
                          pw.Text(data['name'] ?? 'N/A'),
                          pw.Text(data['userEmail'] ?? 'N/A'),
                          pw.Text(data['selectedLocationAddress'] ?? 'N/A'),
                          pw.SizedBox(height: 10),
                          pw.Text('Status:'+data['status'] , style: pw.TextStyle(
                                  color: _getStatusColor(data['status']))),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 30),

                // Service Details
                pw.Text('Service Details',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 18)),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                            child: pw.Text('Service',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            padding: pw.EdgeInsets.all(8)),
                        pw.Padding(
                            child: pw.Text('Date & Time',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            padding: pw.EdgeInsets.all(8)),
                        pw.Padding(
                            child: pw.Text('Price',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                            padding: pw.EdgeInsets.all(8)),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                            child: pw.Text(data['serviceName'] ?? 'N/A'),
                            padding: pw.EdgeInsets.all(8)),
                        pw.Padding(
                            child: pw.Text(
                                '${dateFormatter.format(data['bookingDateTime'].toDate())}\n'
                                    '${timeFormatter.format(data['bookingDateTime'].toDate())}'),
                            padding: pw.EdgeInsets.all(8)),
                        pw.Padding(
                            child: pw.Text(data['servicePrice'] ?? ' '),
                            padding: pw.EdgeInsets.all(8)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Tools Required
                pw.Text('Tools Required',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.SizedBox(height: 10),
                // Corrected implementation
                pw.Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (data['employeeTools']
                  as List<dynamic>?)
                      ?.map((tool) => _buildPdfChip(tool.toString()))
                      .toList() ??
                      [pw.Text('No tools specified')],
                ),
                pw.SizedBox(height: 20),

                // Location
                pw.Text('Service Location',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.SizedBox(height: 10),
                pw.Text(data['selectedLocationAddress'] ?? 'N/A'),

                pw.SizedBox(height: 10),
                pw.UrlLink(
                  child: pw.Text('View on Google Maps',
                      style: pw.TextStyle(
                          color: PdfColors.blue,
                          decoration: pw.TextDecoration.underline)),
                  destination: data['mapLink'] ?? '',
                ),
                pw.SizedBox(height: 20),

                // Notes
                if (data['notes'] != null && data['notes'].isNotEmpty)
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Special Notes',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 16)),
                      pw.SizedBox(height: 10),
                      pw.Text(data['notes']),
                    ],
                  ),
              ],
            );
          },
        ),
      );
    }

    return pdf;
  }

  static PdfColor _getStatusColor(String? status) {
    switch (status) {
      case 'in_progress':
        return PdfColors.orange;
      case 'completed':
        return PdfColors.green;
      case 'cancelled':
        return PdfColors.red;
      default:
        return PdfColors.black;
    }
  }
}
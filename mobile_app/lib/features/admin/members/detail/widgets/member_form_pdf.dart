import 'dart:typed_data';

import 'package:fitness_care_bagerhat/features/admin/members/member.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MemberFormPdf {
  static Future<Uint8List> generate(Member member) async {
    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: await PdfGoogleFonts.interRegular(),
        bold: await PdfGoogleFonts.interBold(),
      ),
    );

    final sub = member.activeSubscription;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Container(
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.only(bottom: 20),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 2),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Text('FITNESS CARE BAGERHAT',
                        style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#1E293B'))),
                    pw.SizedBox(height: 4),
                    pw.Text('MEMBER REGISTRATION / PROFILE FORM',
                        style: pw.TextStyle(
                            fontSize: 14, color: PdfColor.fromHex('#64748B'))),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Personal Information
              _buildSectionTitle('PERSONAL INFORMATION'),
              pw.SizedBox(height: 12),
              _buildRow('Full Name', member.name, 'Phone', member.phone),
              _buildRow(
                  'Gender', member.gender, 'Join Date', _formatDate(member.joinDate)),
              _buildRow('Date of Birth', _formatDate(member.dateOfBirth),
                  'Blood Group', member.bloodGroup ?? 'N/A'),
              _buildRow('Height', _formatHeight(member.heightCm), 'Weight',
                  _formatWeight(member.currentWeight)),
              pw.SizedBox(height: 24),

              // Contact & Emergency
              _buildSectionTitle('CONTACT & IDENTIFICATION'),
              pw.SizedBox(height: 12),
              _buildFullRow(
                  'Present Address', member.presentAddress ?? 'N/A'),
              _buildFullRow(
                  'Permanent Address', member.permanentAddress ?? 'N/A'),
              _buildRow('Emergency Phone', member.emergencyPhone ?? 'N/A',
                  'NID', member.nid ?? 'N/A'),
              _buildFullRow('Occupation', member.occupation ?? 'N/A'),
              pw.SizedBox(height: 24),

              // Subscription & Billing
              _buildSectionTitle('CURRENT SUBSCRIPTION'),
              pw.SizedBox(height: 12),
              if (sub != null) ...[
                _buildRow('Plan Name', sub.planName.isNotEmpty ? sub.planName : (sub.note ?? 'Membership Plan'),
                    'Status', sub.status.toUpperCase()),
                _buildRow('Start Date', _formatDate(sub.startDate),
                    'End Date', _formatDate(sub.endDate)),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPriceBlock('Total Amount', sub.finalPrice),
                      _buildPriceBlock('Amount Paid', sub.moneyPaid),
                      _buildPriceBlock('Due Amount', sub.moneyLeft > 0 ? sub.moneyLeft : 0),
                    ],
                  ),
                ),
              ] else ...[
                pw.Text('No active subscription found.',
                    style: pw.TextStyle(color: PdfColors.grey600)),
              ],
              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _buildSignatureBlock('Member Signature & Date'),
                  _buildSignatureBlock('Authorized Signature & Date'),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      color: PdfColors.grey200,
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildRow(
      String label1, String value1, String label2, String value2) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.Expanded(child: _buildField(label1, value1)),
          pw.SizedBox(width: 16),
          pw.Expanded(child: _buildField(label2, value2)),
        ],
      ),
    );
  }

  static pw.Widget _buildFullRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: _buildField(label, value),
    );
  }

  static pw.Widget _buildField(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label,
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 11, color: PdfColors.black)),
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 4),
          height: 1,
          color: PdfColors.grey300,
        ),
      ],
    );
  }

  static pw.Widget _buildPriceBlock(String label, double amount) {
    final formatCurrency = NumberFormat.currency(symbol: 'Tk ', decimalDigits: 0);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        pw.SizedBox(height: 4),
        pw.Text(formatCurrency.format(amount),
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _buildSignatureBlock(String label) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(
          width: 150,
          height: 1,
          color: PdfColors.black,
        ),
        pw.SizedBox(height: 4),
        pw.Text(label, style: pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String _formatHeight(double? cm) {
    if (cm == null) return 'N/A';
    final totalInches = (cm / 2.54).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return '$feet\' $inches"';
  }

  static String _formatWeight(double? kg) {
    if (kg == null) return 'N/A';
    return '${kg.toStringAsFixed(1)} kg';
  }
}

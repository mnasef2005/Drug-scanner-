import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../data/models.dart';

class InvoiceGenerator {
  static Future<void> generateAndPrintInvoice(Invoice invoice) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('فاتورة ضريبية مبسطة', style: pw.TextStyle(font: boldFont, fontSize: 24)),
                    pw.Text('Invoice', style: pw.TextStyle(font: boldFont, fontSize: 24)),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Text('اسم الصيدلية', style: pw.TextStyle(font: boldFont)),
                pw.Text('العنوان ورقم الهاتف'),
                pw.Divider(height: 30),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('فاتورة إلى: ${invoice.customerName}'),
                    pw.Text('رقم الفاتورة: #${invoice.id}'),
                  ],
                ),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                        pw.Text('التاريخ: ${DateFormat('yyyy-MM-dd').format(invoice.date)}'),
                        pw.Text('الحالة: ${invoice.isPaid ? 'مدفوعة' : 'آجل'}',
                        style: pw.TextStyle(color: invoice.isPaid ? PdfColors.green : PdfColors.red)),
                    ]
                ),
                pw.SizedBox(height: 20),
                _buildInvoiceTable(invoice, boldFont),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('الإجمالي: ', style: pw.TextStyle(font: boldFont, fontSize: 16)),
                    pw.Text('${invoice.totalAmount.toStringAsFixed(2)} جنيه', style: pw.TextStyle(font: boldFont, fontSize: 16)),
                  ],
                ),
                pw.Spacer(),
                pw.Center(child: pw.Text('شكراً لتعاملكم معنا')),
              ],
            ),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  static pw.Table _buildInvoiceTable(Invoice invoice, pw.Font boldFont) {
    final headers = ['الصنف', 'الكمية', 'السعر', 'الإجمالي'];

    final data = invoice.items.map((item) {
      return [
        item.name,
        item.quantity.toString(),
        item.price.toStringAsFixed(2),
        (item.price * item.quantity).toStringAsFixed(2),
      ];
    }).toList();

    return pw.Table.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(font: boldFont, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
      cellAlignment: pw.Alignment.center,
      cellStyle: const pw.TextStyle(),
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
    );
  }
}

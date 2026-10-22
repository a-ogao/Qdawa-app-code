import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';

class InvoiceScreen extends StatefulWidget {
  final String orderId;

  InvoiceScreen({required this.orderId});

  @override
  _InvoiceScreenState createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  bool isLoading = true;
  String invoiceNumber = "";
  String invoiceDate = "";
  String customerName = "";
  String customerPhone = "";
  String customerAddress = "";
  List<Map<String, dynamic>> items = [];
  double subtotal = 0.0;
  double tax = 0.0;
  double total = 0.0;

  @override
  void initState() {
    super.initState();
    fetchInvoiceData();
  }

  Future<void> generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: pw.EdgeInsets.all(16.0),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Invoice # $invoiceNumber",
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.Text("Date: $invoiceDate",
                    style: pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 20),
                pw.Text("Bill To:",
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text(customerName, style: pw.TextStyle(fontSize: 14)),
                pw.Text(customerPhone, style: pw.TextStyle(fontSize: 14)),
                pw.Text(customerAddress, style: pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                            padding: pw.EdgeInsets.all(8.0),
                            child: pw.Text("Item",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: pw.EdgeInsets.all(8.0),
                            child: pw.Text("Qty",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: pw.EdgeInsets.all(8.0),
                            child: pw.Text("Price",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: pw.EdgeInsets.all(8.0),
                            child: pw.Text("Total",
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ...items.map((item) {
                      double qty =
                          double.tryParse(item["oit_qty"].toString()) ?? 0.0;
                      double price = double.tryParse(
                              item["oit_amount_per_unit"].toString()) ??
                          0.0;
                      return pw.TableRow(children: [
                        pw.Padding(
                            padding: pw.EdgeInsets.all(8.0),
                            child: pw.Text(item["oit_item_name"] ?? "N/A")),
                        pw.Padding(
                            padding: pw.EdgeInsets.all(8.0),
                            child: pw.Text(qty.toString())),
                        pw.Padding(
                            padding: pw.EdgeInsets.all(8.0),
                            child: pw.Text(price.toString())),
                        pw.Padding(
                            padding: pw.EdgeInsets.all(8.0),
                            child: pw.Text((qty * price).toStringAsFixed(2))),
                      ]);
                    }),
                  ],
                ),
                pw.Divider(),
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Subtotal: KSH ${subtotal.toStringAsFixed(2)}"),
                      pw.Text("Tax (0%): KSH ${tax.toStringAsFixed(2)}"),
                      pw.Divider(),
                      pw.Text("Grand Total: KSH ${total.toStringAsFixed(2)}",
                          style: pw.TextStyle(
                              fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Save PDF
    final output = await getExternalStorageDirectory();
    final file = File("${output!.path}/invoice_${invoiceNumber}.pdf");
    await file.writeAsBytes(await pdf.save());

    // Open the file
    OpenFilex.open(file.path);
  }

  Future<void> fetchInvoiceData() async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('view_invoice')),
        body: {"order_id": widget.orderId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          invoiceNumber = data["invoice_number"] ?? "N/A";
          invoiceDate = data["order"]["ord_created_dt"] ?? "N/A";
          customerName =
              data["order"]["usr_first_name"] ?? data["order"]["usr_username"];
          customerPhone = data["order"]["usr_mobile_number"] ?? "N/A";
          customerAddress = data["order"]["adr_address_1"] ?? "N/A";

          items = List<Map<String, dynamic>>.from(data["items"] ?? []);

          subtotal = items.fold(0.0, (sum, item) {
            double qty = double.tryParse(item['oit_qty'].toString()) ?? 0.0;
            double price =
                double.tryParse(item['oit_amount_per_unit'].toString()) ?? 0.0;
            return sum + (qty * price);
          });
          tax = 0;
          total = subtotal + tax;

          isLoading = false;
        });
      } else {
        throw Exception("Failed to load invoice");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching invoice: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Invoice", style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 20),
                  _buildCustomerDetails(),
                  SizedBox(height: 20),
                  _buildItemList(),
                  Divider(),
                  _buildTotals(),
                ],
              ),
            ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.all(16.0),
        child: CustomElevatedButton(
          text: "Download Invoice",
          onPressed: () {
            generatePDF(); // Function to handle PDF generation
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Invoice # $invoiceNumber",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text("Date: $invoiceDate",
            style: TextStyle(fontSize: 16, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildCustomerDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Bill To:",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Text(customerName, style: TextStyle(fontSize: 16)),
        Text(customerPhone, style: TextStyle(fontSize: 16)),
        Text(customerAddress, style: TextStyle(fontSize: 16)),
      ],
    );
  }

  Widget _buildItemList() {
    return Column(
      children: [
        Table(
          border: TableBorder.all(),
          columnWidths: {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[300]),
              children: [
                _buildTableHeader("Item"),
                _buildTableHeader("Qty"),
                _buildTableHeader("Price"),
                _buildTableHeader("Total"),
              ],
            ),
            ...items.map((item) {
              return TableRow(
                children: [
                  _buildTableCell(item["oit_item_name"] ?? "N/A"),
                  _buildTableCell(item["oit_qty"].toString()),
                  _buildTableCell("${item["oit_amount_per_unit"].toString()}"),
                  _buildTableCell(
                      "${(double.tryParse(item["oit_qty"].toString()) ?? 0.0) * (double.tryParse(item["oit_amount_per_unit"].toString()) ?? 0.0)}"),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildTableHeader(String title) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Text(title,
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Text(text, textAlign: TextAlign.center),
    );
  }

  Widget _buildTotals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text("Subtotal: KSH ${subtotal.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 16)),
        Text("Tax (0%): KSH ${tax.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 16)),
        Divider(),
        Text("Grand Total: KSH ${total.toStringAsFixed(2)}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_models/shared_models.dart';

class ExportService {
  Future<File> exportToCsv(List<Expense> expenses) async {
    final csvData = <List<String>>[
      ['Дата', 'Тип', 'Сумма', 'Валюта', 'Категория', 'Заметка'],
    ];

    final dateFormat = DateFormat('yyyy-MM-dd');
    for (final expense in expenses) {
      csvData.add([
        dateFormat.format(expense.occurredAt),
        expense.type.isIncome ? 'Доход' : 'Расход',
        (expense.amount.amount).toStringAsFixed(2),
        expense.amount.currencyCode,
        expense.categoryId ?? '',
        expense.note ?? '',
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/expenses_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvString);
    return file;
  }

  Future<File> exportToJson(List<Expense> expenses) async {
    final jsonData = expenses.map((e) => e.toJson()).toList();
    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/expenses_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonString);
    return file;
  }

  Future<void> exportToPdf(List<Expense> expenses, {String? title}) async {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final numberFormat = NumberFormat.currency(symbol: '₸');

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title ?? 'Отчёт по расходам',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Дата', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Тип', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Сумма', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Категория', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('Заметка', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...expenses.map((expense) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(dateFormat.format(expense.occurredAt)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(expense.type.isIncome ? 'Доход' : 'Расход'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(numberFormat.format(expense.amount.amount)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(expense.categoryId ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(expense.note ?? ''),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
}

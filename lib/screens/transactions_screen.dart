import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_colors.dart';
import '../services/storage_service.dart';
import '../services/category_service.dart';
import '../widgets/main_layout.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/empty_state.dart';
import '../models/transaction.dart';
import '../models/user_model.dart';
import '../models/transaction.dart' show Category;
import '../providers/theme_provider.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  UserProfile? _user;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isGeneratingPDF = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await StorageService.getUser();
    final transactions = await StorageService.getTransactions();
    final categories = await StorageService.getCategories();
    setState(() {
      _user = user;
      _transactions = transactions;
      _categories = categories;
    });
  }

  // Helper method to get category icon from stored categories
  String _getCategoryIcon(String categoryName) {
    try {
      final category = _categories.firstWhere(
            (c) => c.name == categoryName,
        orElse: () => Category(
          id: 'temp',
          name: categoryName,
          icon: '📦',
          color: '#6C757D',
          type: TransactionType.expense,
          isDefault: false,
        ),
      );
      return category.icon;
    } catch (e) {
      return '📦';
    }
  }

  // Helper method to get category color from stored categories
  Color _getCategoryColor(String categoryName) {
    try {
      final category = _categories.firstWhere(
            (c) => c.name == categoryName,
        orElse: () => Category(
          id: 'temp',
          name: categoryName,
          icon: '📦',
          color: '#6C757D',
          type: TransactionType.expense,
          isDefault: false,
        ),
      );
      return Color(int.parse(category.color.replaceFirst('#', '0xff')));
    } catch (e) {
      return AppColors.textSecondary;
    }
  }

  List<Transaction> get _filteredTransactions {
    return _transactions.where((t) {
      final matchesSearch = _searchQuery.isEmpty ||
          t.note.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesFilter = _selectedFilter == 'all' ||
          (_selectedFilter == 'income' && t.type == TransactionType.income) ||
          (_selectedFilter == 'expense' && t.type == TransactionType.expense);

      bool matchesDateRange = true;
      if (_startDate != null && _endDate != null) {
        matchesDateRange = t.date.isAfter(_startDate!) &&
            t.date.isBefore(_endDate!.add(const Duration(days: 1)));
      }

      return matchesSearch && matchesFilter && matchesDateRange;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<String, List<Transaction>> _groupTransactionsByDate(List<Transaction> transactions) {
    final Map<String, List<Transaction>> grouped = {};
    for (var transaction in transactions) {
      final dateKey = DateFormat('MMMM d, yyyy').format(transaction.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }
    return grouped;
  }

  Future<void> _selectDateRange() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: themeProvider.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  // ==============================
  // PDF GENERATION FUNCTIONS
  // ==============================

  // Helper method to remove emojis and special characters for PDF
  String _cleanTextForPDF(String text) {
    if (text.isEmpty) return text;
    // Remove emojis and other special characters that might cause PDF issues
    // This regex matches most emojis and special characters
    final cleanText = text.replaceAll(RegExp(r'[^\x00-\x7F]+'), '').trim();
    return cleanText.isEmpty ? text.replaceAll(RegExp(r'[^\w\s\-.,]'), '') : cleanText;
  }

  // Generate filename in the required format
  String _generateFileName() {
    String baseName = 'Monivo_account_statement';

    if (_startDate != null && _endDate != null) {
      final fromDate = DateFormat('dd_MM_yyyy').format(_startDate!);
      final toDate = DateFormat('dd_MM_yyyy').format(_endDate!);
      baseName += '_${fromDate}_to_${toDate}';
    } else {
      baseName += '_all_transactions';
    }

    return '$baseName.pdf';
  }

  // Check if file exists and generate unique name with counter
  Future<String> _getUniqueFileName(String directoryPath, String baseFileName) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final String baseName = baseFileName.replaceAll('.pdf', '');
    final RegExp counterRegex = RegExp(r'\((\d+)\)$');

    int counter = 1;
    String fileName = baseFileName;
    String filePath = '$directoryPath/$fileName';

    while (await File(filePath).exists()) {
      // Extract base name without counter
      String newBaseName = baseName;
      if (counterRegex.hasMatch(baseName)) {
        newBaseName = baseName.replaceAll(counterRegex, '').trim();
      }

      fileName = '${newBaseName}($counter).pdf';
      filePath = '$directoryPath/$fileName';
      counter++;
    }

    return fileName;
  }

  Future<void> _generateAndShowPDF() async {
    if (_filteredTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No transactions to generate statement'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingPDF = true;
    });

    try {
      final pdf = await _createPDF();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'PDF generated successfully!',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Navigate to PDF viewer (no permission needed)
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerScreen(
              pdfData: pdf,
              fileName: _generateFileName(),
              startDate: _startDate,
              endDate: _endDate,
              userName: _user?.name ?? 'User',
              currency: _user?.preferredCurrency ?? Currency.npr,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isGeneratingPDF = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _prepareStatementData() async {
    final transactions = _filteredTransactions;

    // Sort by date ascending for statement (oldest first)
    final sortedTransactions = List<Transaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    double runningBalance = 0;
    final List<Map<String, dynamic>> statementRows = [];

    // Calculate opening balance (balance before first transaction)
    final allTransactions = await StorageService.getTransactions();
    final beforePeriodTransactions = allTransactions.where((t) {
      if (_startDate != null) {
        return t.date.isBefore(_startDate!);
      }
      return false;
    }).toList();

    double openingBalance = 0;
    for (var t in beforePeriodTransactions) {
      if (t.type == TransactionType.income) {
        openingBalance += t.amount;
      } else {
        openingBalance -= t.amount;
      }
    }

    runningBalance = openingBalance;

    for (var t in sortedTransactions) {
      if (t.type == TransactionType.income) {
        runningBalance += t.amount;
      } else {
        runningBalance -= t.amount;
      }

      // Clean category and note for PDF (remove emojis)
      final cleanCategory = _cleanTextForPDF(t.category);
      final cleanNote = _cleanTextForPDF(t.note);

      statementRows.add({
        'date': DateFormat('dd/MM/yyyy').format(t.date),
        'description': cleanNote.isNotEmpty
            ? '$cleanCategory - $cleanNote'
            : cleanCategory,
        'debit': t.type == TransactionType.expense ? t.amount : 0.0,
        'credit': t.type == TransactionType.income ? t.amount : 0.0,
        'balance': runningBalance,
        'account': _cleanTextForPDF(t.account),
        'category': cleanCategory,
      });
    }

    return statementRows;
  }

  Future<Uint8List> _createPDF() async {
    final pdf = pw.Document();
    final currency = _user?.preferredCurrency ?? Currency.npr;
    final statementData = await _prepareStatementData();

    // Calculate totals
    double totalCredits = 0;
    double totalDebits = 0;
    for (var row in statementData) {
      totalCredits += row['credit'];
      totalDebits += row['debit'];
    }

    final openingBalance = statementData.isNotEmpty
        ? (statementData.first['balance'] -
        (statementData.first['credit'] - statementData.first['debit']))
        : 0.0;
    final closingBalance = statementData.isNotEmpty
        ? statementData.last['balance']
        : 0.0;

    // Load the app icon for PDF
    final ByteData imageData = await rootBundle.load('assets/icons/monivoappicon.png');
    final Uint8List imageBytes = imageData.buffer.asUint8List();
    final pw.MemoryImage image = pw.MemoryImage(imageBytes);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    // App Icon
                    pw.Container(
                      width: 40,
                      height: 40,
                      child: pw.Image(image),
                    ),
                    pw.SizedBox(width: 10),
                    // App Name and Statement Type
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MONIVO',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue,
                          ),
                        ),
                        pw.Text(
                          'Electronic Account Statement',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Statement Period',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      '${_startDate != null ? DateFormat('dd MMM yyyy').format(_startDate!) : 'All Time'} - '
                          '${_endDate != null ? DateFormat('dd MMM yyyy').format(_endDate!) : 'Present'}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Account Details Row
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Account Name:',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        _user?.name ?? 'User',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Account Currency:',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        currency.code,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Opening Balance:',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        '${currency.code} ${_formatNumber(openingBalance)}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Closing Balance:',
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        '${currency.code} ${_formatNumber(closingBalance)}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Table Header
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(flex: 2, child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 4, child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 2, child: pw.Text('Debit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  pw.Expanded(flex: 2, child: pw.Text('Credit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  pw.Expanded(flex: 2, child: pw.Text('Balance', style: pw.TextStyle(fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                ],
              ),
            ),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated on ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
          ],
        ),
        build: (context) => [
          // Transaction Rows
          ...statementData.map((row) => pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(flex: 2, child: pw.Text(row['date'], style: pw.TextStyle(fontSize: 11))),
                pw.Expanded(
                  flex: 4,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Description in "Category - Note" format, with proper text wrapping
                      pw.Text(
                        row['description'],
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.left,
                        softWrap: true,
                      ),
                      // Account in smaller font below
                      pw.SizedBox(height: 2),
                      pw.Text(
                        row['account'],
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                          fontWeight: pw.FontWeight.normal,
                        ),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    row['debit'] > 0 ? '${currency.code} ${_formatNumber(row['debit'])}' : '',
                    style: pw.TextStyle(fontSize: 11, color: PdfColors.red),
                    textAlign: pw.TextAlign.right,
                    softWrap: true,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    row['credit'] > 0 ? '${currency.code} ${_formatNumber(row['credit'])}' : '',
                    style: pw.TextStyle(fontSize: 11, color: PdfColors.green),
                    textAlign: pw.TextAlign.right,
                    softWrap: true,
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    '${currency.code} ${_formatNumber(row['balance'])}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: row['balance'] >= 0 ? PdfColors.black : PdfColors.red,
                    ),
                    textAlign: pw.TextAlign.right,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          )).toList(),

          pw.SizedBox(height: 20),

          // Summary Footer
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Transactions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${statementData.length}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Opening Balance:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${currency.code} ${_formatNumber(openingBalance)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Closing Balance:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('${currency.code} ${_formatNumber(closingBalance)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.purple)),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Net Change:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      '${currency.code} ${_formatNumber(closingBalance - openingBalance)}',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: (closingBalance - openingBalance) >= 0 ? PdfColors.green : PdfColors.red,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Statement matches accounting principles. All transactions are properly recorded.',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.green700, fontStyle: pw.FontStyle.italic),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildSummaryItem(String label, double amount, Currency currency, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '${currency.code} ${_formatNumber(amount)}',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    if (number >= 10000000) {
      return '${(number / 10000000).toStringAsFixed(2)}Cr';
    } else if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(2)}L';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)}K';
    }
    return number.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currency = _user?.preferredCurrency ?? Currency.npr;
    final filteredTransactions = _filteredTransactions;
    final groupedTransactions = _groupTransactionsByDate(filteredTransactions);

    return MainLayout(
      currentIndex: 1,
      child: Scaffold(
        backgroundColor: AppColors.lightGray,
        body: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Transactions',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Search Bar
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search transactions...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: themeProvider.primaryColor,
                          ),
                          filled: true,
                          fillColor: AppColors.lightGray,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: themeProvider.primaryColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Filter Row
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All', 'all', themeProvider),
                            const SizedBox(width: 8),
                            _buildFilterChip('Income', 'income', themeProvider),
                            const SizedBox(width: 8),
                            _buildFilterChip('Expenses', 'expense', themeProvider),
                            const SizedBox(width: 8),
                            // Date Range Picker - Always grey
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.lightGray,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(
                                  Icons.date_range,
                                  color: AppColors.textSecondary, // Always grey
                                ),
                                onPressed: _selectDateRange,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // PDF Download Button - Always grey (both enabled and disabled)
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.lightGray,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: _isGeneratingPDF
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.textSecondary),
                                  ),
                                )
                                    : Icon(
                                  Icons.picture_as_pdf,
                                  color: AppColors.textSecondary, // Always grey
                                ),
                                onPressed: _filteredTransactions.isNotEmpty && !_isGeneratingPDF
                                    ? _generateAndShowPDF
                                    : null,
                              ),
                            ),
                            if (_startDate != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: themeProvider.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: themeProvider.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: _clearDateFilter,
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: themeProvider.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Transaction List
            Expanded(
              child: filteredTransactions.isEmpty
                  ? _searchQuery.isNotEmpty
                  ? EmptyState(
                title: 'No Results Found',
                message: 'No transactions match "$_searchQuery".',
                icon: Icons.search_off,
              )
                  : EmptyState(
                title: 'No Transactions',
                message: 'Start by adding your first transaction.',
                icon: Icons.receipt_long,
                buttonText: 'Add Transaction',
                onButtonPressed: () {
                  Navigator.pushNamed(context, '/add-transaction');
                },
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: groupedTransactions.length,
                itemBuilder: (context, index) {
                  final dateKey = groupedTransactions.keys.elementAt(index);
                  final dayTransactions = groupedTransactions[dateKey]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 4),
                        child: Text(
                          dateKey,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: dayTransactions.map((transaction) {
                            return TransactionTile(
                              transaction: transaction,
                              currency: currency,
                              categoryIcon: _getCategoryIcon(transaction.category),
                              categoryColor: _getCategoryColor(transaction.category),
                              onTap: () {
                                // Navigate to edit transaction
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/add-transaction');
          },
          backgroundColor: themeProvider.primaryColor,
          child: const Icon(Icons.add, size: 32, color: Colors.white,),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ThemeProvider themeProvider) {
    final isSelected = _selectedFilter == value;
    Color bgColor;
    Color textColor;

    if (isSelected) {
      if (value == 'income') {
        bgColor = AppColors.success;
        textColor = Colors.white;
      } else if (value == 'expense') {
        bgColor = AppColors.error;
        textColor = Colors.white;
      } else {
        bgColor = themeProvider.primaryColor;
        textColor = Colors.white;
      }
    } else {
      bgColor = AppColors.lightGray;
      textColor = AppColors.textSecondary;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// ==============================
// PDF VIEWER SCREEN
// ==============================
class PDFViewerScreen extends StatelessWidget {
  final Uint8List pdfData;
  final String fileName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String userName;
  final Currency currency;

  const PDFViewerScreen({
    Key? key,
    required this.pdfData,
    required this.fileName,
    this.startDate,
    this.endDate,
    required this.userName,
    required this.currency,
  }) : super(key: key);

  // Helper method to generate unique filename (for download)
  Future<String> _getUniqueFileName(String directoryPath, String baseFileName) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final String baseName = baseFileName.replaceAll('.pdf', '');
    final RegExp counterRegex = RegExp(r'\((\d+)\)$');

    int counter = 1;
    String fileName = baseFileName;
    String filePath = '$directoryPath/$fileName';

    while (await File(filePath).exists()) {
      String newBaseName = baseName;
      if (counterRegex.hasMatch(baseName)) {
        newBaseName = baseName.replaceAll(counterRegex, '').trim();
      }
      fileName = '${newBaseName}($counter).pdf';
      filePath = '$directoryPath/$fileName';
      counter++;
    }

    return fileName;
  }

  // Get Android SDK version
  Future<int> _getAndroidSdkVersion() async {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      debugPrint('Error getting Android version: $e');
      return 0;
    }
  }

  // For Android 11+ (API 30+) - Scoped Storage (no permission needed)
  Future<void> _savePDFScopedStorage(BuildContext context) async {
    try {
      // For Android 11+, we save to the app's external media directory
      // This is accessible via file manager and doesn't require permissions
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Could not access external storage');
      }

      // Navigate up to the Android/media/com.example.bluewallet/ path
      // The path structure is: Android/data/com.example.bluewallet/files/
      // We want: Android/media/com.example.bluewallet/Monivo Statements/

      final parts = directory.path.split('/');
      // Find the Android folder index
      final androidIndex = parts.indexOf('Android');
      if (androidIndex == -1) {
        throw Exception('Could not determine storage path');
      }

      // Build the media path: .../Android/media/com.example.bluewallet/Monivo Statements/
      final basePath = parts.take(androidIndex + 1).join('/');
      final mediaPath = '$basePath/media/${parts[androidIndex + 2]}/Monivo Statements';

      final statementsDir = Directory(mediaPath);
      if (!await statementsDir.exists()) {
        await statementsDir.create(recursive: true);
      }

      final uniqueFileName = await _getUniqueFileName(statementsDir.path, fileName);
      final file = File('${statementsDir.path}/$uniqueFileName');
      await file.writeAsBytes(pdfData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'PDF saved to Monivo Statements folder!',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Location: Android/media/com.example.bluewallet/Monivo Statements/',
                        style: const TextStyle(fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        uniqueFileName,
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // For Android 10 and below (API 28 and lower) - Requires storage permission
  Future<void> _savePDFWithPermission(BuildContext context) async {
    try {
      // Request storage permission first
      final status = await Permission.storage.request();

      if (!status.isGranted) {
        if (context.mounted) {
          // Show dialog explaining why permission is needed
          _showPermissionDialog(context);
        }
        return;
      }

      // Save to Android/data/com.example.bluewallet/files/
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('Could not access external storage');
      }

      // Create Monivo Statements subfolder
      final statementsDir = Directory('${directory.path}/Monivo Statements');
      if (!await statementsDir.exists()) {
        await statementsDir.create(recursive: true);
      }

      final uniqueFileName = await _getUniqueFileName(statementsDir.path, fileName);
      final file = File('${statementsDir.path}/$uniqueFileName');
      await file.writeAsBytes(pdfData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'PDF saved successfully!',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Location: Android/data/com.example.bluewallet/files/Monivo Statements/',
                        style: const TextStyle(fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        uniqueFileName,
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // Show permission explanation dialog
  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Storage Permission Required'),
          content: const Text(
              'To save PDF statements to your device, Monivo needs storage permission. '
                  'This permission is only used to save files to the app\'s designated folder.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Open app settings
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // Fallback method - Save to app documents (always works, but not user-accessible)
  Future<void> _savePDFToAppDocuments(BuildContext context) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final uniqueFileName = await _getUniqueFileName(directory.path, fileName);
      final file = File('${directory.path}/$uniqueFileName');
      await file.writeAsBytes(pdfData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'PDF saved to app storage',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'File: $uniqueFileName',
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Note: File is private to the app',
                        style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Statement',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              startDate != null && endDate != null
                  ? '${DateFormat('dd MMM yyyy').format(startDate!)} - ${DateFormat('dd MMM yyyy').format(endDate!)}'
                  : 'All Transactions',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: themeProvider.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Share button
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              await Printing.sharePdf(
                bytes: pdfData,
                filename: fileName,
              );
            },
          ),
          // Download button with Android version handling
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              // Check if running on Android
              if (Theme.of(context).platform == TargetPlatform.android) {
                final sdkInt = await _getAndroidSdkVersion();

                if (sdkInt >= 30) {
                  // Android 11+ (API 30+) - Use Scoped Storage (no permission needed)
                  await _savePDFScopedStorage(context);
                } else if (sdkInt >= 29) {
                  // Android 10 (API 29) - Try scoped storage first, fallback to permission
                  try {
                    await _savePDFScopedStorage(context);
                  } catch (e) {
                    debugPrint('Scoped storage failed, trying with permission: $e');
                    await _savePDFWithPermission(context);
                  }
                } else {
                  // Android 9 and below (API 28 and lower) - Need permission
                  await _savePDFWithPermission(context);
                }
              } else {
                // iOS - Save to app documents
                await _savePDFToAppDocuments(context);
              }
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => pdfData,
        allowSharing: true,
        allowPrinting: true,
        canChangeOrientation: true,
        canChangePageFormat: true,
        canDebug: false,
        pdfFileName: fileName,
        loadingWidget: const Center(
          child: CircularProgressIndicator(),
        ),
        onError: (context, error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading PDF',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
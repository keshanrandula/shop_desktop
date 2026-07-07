import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/supplier_model.dart';
import '../models/product_model.dart';
import '../widgets/custom_button.dart';
import '../utils/theme.dart';

class RestockDialog extends StatefulWidget {
  final Supplier supplier;
  final List<Product> products;

  const RestockDialog({
    Key? key,
    required this.supplier,
    required this.products,
  }) : super(key: key);

  @override
  State<RestockDialog> createState() => _RestockDialogState();
}

class _RestockDialogState extends State<RestockDialog> {
  late TextEditingController _emailController;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.supplier.email);
    _subjectController = TextEditingController(text: 'RESTOCK ORDER - Shop POS & Inventory');

    // Compile template body text
    StringBuffer itemsBuffer = StringBuffer();
    for (var product in widget.products) {
      itemsBuffer.writeln(
        '- ${product.name} (SKU: ${product.sku})\n'
        '  Current Stock: ${product.stock} units | Requested Qty: 50 units\n'
      );
    }

    final bodyText = 'Dear ${widget.supplier.name},\n\n'
        'We would like to place a restock order for the following products:\n\n'
        '${itemsBuffer.toString()}'
        'Please reply with the delivery details, total cost, and proforma invoice.\n\n'
        'Thank you,\n'
        'Store Management\n'
        'Shop POS & Inventory';

    _bodyController = TextEditingController(text: bodyText);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _bodyController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.copy_rounded, color: AppTheme.success),
            SizedBox(width: 12),
            Text('Restock order copied to clipboard!'),
          ],
        ),
        backgroundColor: AppTheme.surfaceSecondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _simulateSend() async {
    setState(() {
      _isSending = true;
    });

    // Simulate network delay for sending email
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isSending = false;
      });
      Navigator.pop(context); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.send_rounded, color: AppTheme.success),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Restock order successfully sent to ${widget.supplier.email}!'),
              ),
            ],
          ),
          backgroundColor: AppTheme.surfaceSecondary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 550,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Draft Restock Order',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _isSending ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.border, height: 1),

            // Form Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Recipient Email field
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'To (Supplier Email)',
                      prefixIcon: Icon(Icons.email_rounded, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subject field
                  TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      prefixIcon: Icon(Icons.subject_rounded, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Message Body text area
                  TextField(
                    controller: _bodyController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Message Body',
                      alignLabelWithHint: true,
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppTheme.border, height: 1),

            // Buttons Action Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: _isSending
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppTheme.primaryLight),
                          SizedBox(height: 12),
                          Text(
                            'Sending purchase order...',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CustomButton(
                          text: 'COPY TEXT',
                          icon: Icons.copy_rounded,
                          type: ButtonType.outlined,
                          onPressed: _copyToClipboard,
                        ),
                        const SizedBox(width: 12),
                        CustomButton(
                          text: 'SEND ORDER',
                          icon: Icons.send_rounded,
                          type: ButtonType.primary,
                          onPressed: _simulateSend,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

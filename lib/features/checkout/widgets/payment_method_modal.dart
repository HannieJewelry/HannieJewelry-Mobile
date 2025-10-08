import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../screens/qr_payment_screen.dart';

class PaymentMethodModal extends StatefulWidget {
  final Function(PaymentMethod) onSelect;
  final String? orderId;
  final double? orderTotal;

  const PaymentMethodModal({
    Key? key,
    required this.onSelect,
    this.orderId,
    this.orderTotal,
  }) : super(key: key);

  @override
  State<PaymentMethodModal> createState() => _PaymentMethodModalState();
}

class _PaymentMethodModalState extends State<PaymentMethodModal> {
  PaymentMethod _selectedMethod = PaymentMethod.cod;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Method',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // COD option
          _buildPaymentOption(
            PaymentMethod.cod,
            'COD',
            'Pay on delivery',
            Icons.payments_outlined,
          ),
          const SizedBox(height: 12),
          // Bank transfer option
          _buildPaymentOption(
            PaymentMethod.bankTransfer,
            'Bank Transfer',
            'Pay via bank account',
            Icons.account_balance_outlined,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onSelect(_selectedMethod);
                Navigator.pop(context);

                // If bank transfer selected and order ID is provided, show QR screen
                if (_selectedMethod == PaymentMethod.bankTransfer && 
                    widget.orderId != null && 
                    widget.orderTotal != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QRPaymentScreen(
                        orderId: widget.orderId!,
                        orderTotal: widget.orderTotal!,
                        bankName: 'Vietcombank',
                        accountNumber: '1234567890',
                        accountName: 'HANNIE JEWELRY CO., LTD',
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
      PaymentMethod method,
      String title,
      String subtitle,
      IconData icon,
      ) {
    final isSelected = _selectedMethod == method;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.red : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.red.shade50 : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.red : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.red : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.red.shade700 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Radio<PaymentMethod>(
              value: method,
              groupValue: _selectedMethod,
              onChanged: (value) {
                setState(() {
                  _selectedMethod = value!;
                });
              },
              activeColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

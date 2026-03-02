// lib/wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  static const Color orange = Color(0xFFF5A623);
  static const String supportPhone = '0921511510';

  void _showTopUpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(14),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6E6E6),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 14),
              const Text('شحن المحفظة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 10),
              const Text('لشحن المحفظة اتصل بالدعم', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F8),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    _CopyButton(textToCopy: supportPhone),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text('الرقم', style: TextStyle(fontWeight: FontWeight.w900)),
                          SizedBox(height: 4),
                          Text(supportPhone, style: TextStyle(color: Color(0xFF666666))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('حسناً', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المحفظة', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F8),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text('رصيد المحفظة', style: TextStyle(color: Color(0xFF666666))),
                  SizedBox(height: 10),
                  Text('0 د.ل', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 26)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _showTopUpSheet(context),
                child: const Text('شحن المحفظة', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('المعاملات السابقة', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 26),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.account_balance_wallet, size: 90, color: Colors.black),
                    SizedBox(height: 12),
                    Text('لا توجد أي معاملات سابقة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                    SizedBox(height: 8),
                    Text('بمجرد إضافة رصيد، ستظهر معاملاتك هنا.', textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  final String textToCopy;
  const _CopyButton({required this.textToCopy});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: textToCopy));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم نسخ الرقم')),
          );
        }
      },
      child: const Text('COPY', style: TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

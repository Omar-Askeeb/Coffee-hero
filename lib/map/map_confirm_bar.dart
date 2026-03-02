import 'package:flutter/material.dart';

import '../auth/ui_tokens.dart';

/// Bottom confirmation bar for MapPicker (matches provided design).
class MapConfirmBar extends StatelessWidget {
  const MapConfirmBar({
    super.key,
    required this.onHere,
    required this.onConfirm,
    this.title = 'حدد موقع توصيل البضاعه',
    this.confirmLabel = 'حدد موقع توصيل البضاعه',
    this.hereLabel = 'ها',
  });

  final VoidCallback onHere;
  final VoidCallback onConfirm;
  final String title;
  final String confirmLabel;
  final String hereLabel;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    height: 44,
                    width: 64,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: UiTokens.softGreyButton,
                        foregroundColor: UiTokens.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      onPressed: onHere,
                      child: Text(hereLabel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: UiTokens.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        onPressed: onConfirm,
                        child: Text(confirmLabel),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

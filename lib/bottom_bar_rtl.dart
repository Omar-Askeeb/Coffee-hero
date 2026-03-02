// lib/bottom_bar_rtl.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

@immutable
class BottomNavAssets {
  const BottomNavAssets._();

  static const String homeActive = 'assets/icons/home (2).png';
  static const String homeInactive = 'assets/icons/home (1).png';

  static const String ordersActive = 'assets/icons/icons8-regular-document-64.png';
  static const String ordersInactive = 'assets/icons/icons8-regular-document-64 (1).png';

  static const String employeesActive = 'assets/icons/icons8-manager-64.png';
  static const String employeesInactive = 'assets/icons/icons8-employee-64.png';

  static const String searchActive = 'assets/icons/search-database.png';
  static const String searchInactive = 'assets/icons/search-database (1).png';

  static const String profileActive = 'assets/icons/user.png';
  static const String profileInactive = 'assets/icons/user (1).png';
}

class BottomBarRTL extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomBarRTL({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color orange = Color(0xFFF5A623);
  static const Color grey = Color(0xFF9AA6B2);

  @override
  Widget build(BuildContext context) {
    // نخلي البار يتأقلم مع كل الأجهزة + مع شريط النظام (gesture/navigation)
    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: Material(
        color: Colors.white,
        elevation: 10,
        child: Container(
          // بدون ارتفاع ثابت: نخليه مرن عشان ما يصيرش Overflow مع تكبير الخط
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(blurRadius: 18, offset: Offset(0, -6), color: Color(0x12000000)),
            ],
          ),
          child: Row(
            children: [
              _AssetNavItem(
                label: 'الرئيسية',
                active: currentIndex == 0,
                activeAsset: BottomNavAssets.homeActive,
                inactiveAsset: BottomNavAssets.homeInactive,
                onTap: () => onTap(0),
                activeColor: orange,
                inactiveColor: grey,
              ),
              _AssetNavItem(
                label: 'طلباتي',
                active: currentIndex == 1,
                activeAsset: BottomNavAssets.ordersActive,
                inactiveAsset: BottomNavAssets.ordersInactive,
                onTap: () => onTap(1),
                activeColor: orange,
                inactiveColor: grey,
              ),
              _AssetNavItem(
                label: 'الموظفين',
                active: currentIndex == 2,
                activeAsset: BottomNavAssets.employeesActive,
                inactiveAsset: BottomNavAssets.employeesInactive,
                onTap: () => onTap(2),
                activeColor: orange,
                inactiveColor: grey,
              ),
              _AssetNavItem(
                label: 'البحث',
                active: currentIndex == 3,
                activeAsset: BottomNavAssets.searchActive,
                inactiveAsset: BottomNavAssets.searchInactive,
                onTap: () => onTap(3),
                activeColor: orange,
                inactiveColor: grey,
              ),
              _AssetNavItem(
                label: 'صفحتي',
                active: currentIndex == 4,
                activeAsset: BottomNavAssets.profileActive,
                inactiveAsset: BottomNavAssets.profileInactive,
                onTap: () => onTap(4),
                activeColor: orange,
                inactiveColor: grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetNavItem extends StatelessWidget {
  final String label;
  final bool active;
  final String activeAsset;
  final String inactiveAsset;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveColor;

  const _AssetNavItem({
    required this.label,
    required this.active,
    required this.activeAsset,
    required this.inactiveAsset,
    required this.onTap,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final tint = active ? activeColor : inactiveColor;
    final asset = active ? activeAsset : inactiveAsset;

    // نحدد مقاسات مرنة بدل ما تكون ثابتة
    final double iconSize = active ? 26 : 24;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // مؤشر صغير تحت الأيقونة (احترافي وبسيط)
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: 3,
                width: active ? 16 : 0,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Image.asset(
                asset,
                width: iconSize,
                height: iconSize,
                fit: BoxFit.contain,
                color: tint,
                colorBlendMode: BlendMode.srcIn,
                errorBuilder: (_, __, ___) => Icon(Icons.circle_outlined, size: iconSize, color: tint),
              ),
              const SizedBox(height: 4),
              // FittedBox يمنع أي Overflow مهما كبر الخط عند المستخدم
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      color: tint,
                      fontSize: active ? 10.5 : 10,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w700,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

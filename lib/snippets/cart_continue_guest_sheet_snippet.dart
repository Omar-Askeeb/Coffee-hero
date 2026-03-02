// snippets/cart_continue_guest_sheet_snippet.dart
//
// Put this BEFORE the checkout / create order logic in your "استمرار" button handler.

import 'auth/auth_service.dart';
import 'auth/guest_cta_sheet.dart';

if (AuthService.instance.isGuest) {
  await GuestCtaSheet.show(context);
  return;
}

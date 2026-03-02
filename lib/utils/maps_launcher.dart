import 'package:url_launcher/url_launcher.dart';

class MapsLauncher {
  static Future<void> openGoogleMaps(double lat, double lng) async {
    final url =
        "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng";

    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw "لا يمكن فتح Google Maps";
    }
  }
}

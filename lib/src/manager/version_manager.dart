import 'dart:convert' show jsonDecode;
import 'dart:io' show HttpStatus;
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:i_updater/src/manager/interface_version.dart';
import 'package:i_updater/src/manager/updater_manager.dart';
import 'package:i_updater/src/model/app_info.dart';
import 'package:i_updater/src/utils/constants/i_updater_constants.dart';
import 'package:i_updater/src/utils/extensions/version_extensions.dart';

class VersionManager extends InterfaceVersion with _VersionManagerMixin {
  final String language;
  final String countryCode;

  // Constructor to initialize the VersionManager with specified language and country code.
  VersionManager({
    required this.language,
    required this.countryCode,
  });

  /// Compares the current app version with the store version.
  ///
  /// * [currentVersion] - The current version of the app.
  /// * [storeVersion] - The version of the app available on the store.
  ///
  /// Returns true if the store version is newer than the current version.
  @override
  bool compareVersions(String currentVersion, String storeVersion) {
    final List<int> currentVersionChars = currentVersion.fromStringToIntList;
    final List<int> storeVersionChars = storeVersion.fromStringToIntList;

    final int currentVersionSize = currentVersionChars.length;
    final int storeVersionSize = storeVersionChars.length;
    final int maxSize = math.max(currentVersionSize, storeVersionSize);

    for (int i = 0; i < maxSize; i++) {
      // Compare corresponding version components.
      if ((i < currentVersionSize ? currentVersionChars[i] : 0) >
          (i < storeVersionSize ? storeVersionChars[i] : 0)) {
        return false;
      } else if ((i < currentVersionSize ? currentVersionChars[i] : 0) <
          (i < storeVersionSize ? storeVersionChars[i] : 0)) {
        return true;
      }
    }
    return false;
  }

  /// Fetches app information from Google Play Store.
  ///
  /// Returns an AppInfo object containing the version and store URL if successful, otherwise null.
  @override
  Future<AppInfo?> getAndroidInfo() async {
    final String? appId = await UpdaterManager.getAppId();
    final Uri uri = Uri.https(
      IUpdaterConstants.googlePlayBaseUrl,
      IUpdaterConstants.playStoreAppsDetailsPath,
      {"id": appId},
    );
    try {
      final response = await http.get(uri);
      return AppInfo(
        version: IUpdaterConstants.googlePlayVersionPattern
            .extractFirstMatch(response.body),
        storeUrl: uri.toString(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Fetches app information from the Apple App Store.
  ///
  /// Returns an AppInfo object containing the version and store URL if successful, otherwise null.
  @override
  Future<AppInfo?> getIOSInfo() async {
    final String? appId = await UpdaterManager.getAppId();
    
    // Ensure we have a valid app ID
    if (appId == null || appId.isEmpty) {
      print('IUpdater: iOS app ID is null or empty');
      return null;
    }
    
    try {
      final String lookupUrl = IUpdaterConstants.iOSDetailsPath
          .replaceAll(
            IUpdaterConstants.language,
            countryCode,
          )
          .replaceAll(
            IUpdaterConstants.id,
            appId,
          );
      
      print('IUpdater: iOS lookup URL: $lookupUrl');
      
      final Map<String, dynamic>? response = await fetch(lookupUrl);
      
      // Debug information
      if (response == null) {
        print('IUpdater: iOS store response is null');
        return null;
      }
      
      print('IUpdater: iOS response keys: ${response.keys.toList()}');
      
      if (!response.containsKey(IUpdaterConstants.results) || 
          response[IUpdaterConstants.results] == null ||
          response[IUpdaterConstants.results].isEmpty) {
        print('IUpdater: iOS results not found or empty');
        return null;
      }
      
      final results = response[IUpdaterConstants.results];
      print('IUpdater: iOS results count: ${results.length}');
      
      if (results.isEmpty) {
        print('IUpdater: No results found for this app ID: $appId');
        return null;
      }
      
      final firstResult = results.first;
      final version = firstResult[IUpdaterConstants.version];
      final trackViewUrl = firstResult[IUpdaterConstants.trackViewUrl];
      
      print('IUpdater: iOS version found: $version');
      print('IUpdater: iOS store URL found: $trackViewUrl');
      
      return AppInfo(
        version: version,
        storeUrl: trackViewUrl,
      );
    } catch (e) {
      print('IUpdater: Error getting iOS app info: $e');
      return null;
    }
  }
}

mixin _VersionManagerMixin {
  /// Fetches JSON data from the specified URL.
  ///
  /// * [url] - The URL to fetch the data from.
  ///
  /// Returns a Map containing the JSON data if successful, otherwise null.
  Future<Map<String, dynamic>?> fetch(
    String url,
  ) async {
    try {
      final http.Response response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        print('IUpdater: Request timed out for URL: $url');
        throw Exception('Request timed out');
      });
      
      print('IUpdater: Response status code: ${response.statusCode}');
      
      if (response.statusCode == HttpStatus.ok) {
        try {
          final jsonBody = jsonDecode(response.body);
          return jsonBody;
        } catch (e) {
          print('IUpdater: JSON decode error: $e');
          print('IUpdater: Response body: ${response.body.substring(0, math.min(100, response.body.length))}...');
          return null;
        }
      } else {
        print('IUpdater: HTTP error: ${response.statusCode}, Body: ${response.body.substring(0, math.min(100, response.body.length))}...');
        return null;
      }
    } catch (e) {
      print('IUpdater: Network request error: $e');
      return null;
    }
  }
}

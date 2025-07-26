import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class EmergencyService {
  static const String _jsonFilePath =
      'kottravel-2d580-default-rtdb-export (1).json';

  // Activate emergency signal by updating the JSON data
  static Future<bool> activateEmergencySignal(String cameraId) async {
    try {
      // Read the current JSON file
      final file = File(_jsonFilePath);
      if (!await file.exists()) {
        print('JSON file not found');
        return false;
      }

      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = json.decode(jsonString);

      // Update traffic data status to Emergency
      if (data['traffic_data'] != null &&
          data['traffic_data'][cameraId] != null) {
        data['traffic_data'][cameraId]['congestion']['status'] = 'Emergency';
        data['traffic_data'][cameraId]['congestion']['level'] =
            5; // Highest level
        data['traffic_data'][cameraId]['timestamp'] =
            DateTime.now().toIso8601String();

        // Add emergency metadata
        if (data['traffic_data'][cameraId]['metadata'] == null) {
          data['traffic_data'][cameraId]['metadata'] = {};
        }
        data['traffic_data'][cameraId]['metadata']['emergency_active'] = true;
        data['traffic_data'][cameraId]['metadata']['emergency_timestamp'] =
            DateTime.now().toIso8601String();
      }

      // Add emergency alert
      final alertId = '-${DateTime.now().millisecondsSinceEpoch}';
      if (data['alerts'] == null) {
        data['alerts'] = {};
      }
      if (data['alerts'][cameraId] == null) {
        data['alerts'][cameraId] = {};
      }

      data['alerts'][cameraId][alertId] = {
        'alert_type': 'emergency_signal',
        'location_id': cameraId,
        'message': 'EMERGENCY SIGNAL ACTIVATED - Immediate response required',
        'severity': 'critical',
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Write back to file
      final updatedJsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(data);
      await file.writeAsString(updatedJsonString);

      print('Emergency signal activated for camera: $cameraId');
      return true;
    } catch (e) {
      print('Error activating emergency signal: $e');
      return false;
    }
  }

  // Deactivate emergency signal
  static Future<bool> deactivateEmergencySignal(String cameraId) async {
    try {
      final file = File(_jsonFilePath);
      if (!await file.exists()) {
        print('JSON file not found');
        return false;
      }

      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = json.decode(jsonString);

      // Reset traffic data status
      if (data['traffic_data'] != null &&
          data['traffic_data'][cameraId] != null) {
        data['traffic_data'][cameraId]['congestion']['status'] =
            'Light Traffic';
        data['traffic_data'][cameraId]['congestion']['level'] = 1;
        data['traffic_data'][cameraId]['timestamp'] =
            DateTime.now().toIso8601String();

        // Remove emergency metadata
        if (data['traffic_data'][cameraId]['metadata'] != null) {
          data['traffic_data'][cameraId]['metadata']['emergency_active'] =
              false;
          data['traffic_data'][cameraId]['metadata']['emergency_deactivated'] =
              DateTime.now().toIso8601String();
        }
      }

      // Write back to file
      final updatedJsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(data);
      await file.writeAsString(updatedJsonString);

      print('Emergency signal deactivated for camera: $cameraId');
      return true;
    } catch (e) {
      print('Error deactivating emergency signal: $e');
      return false;
    }
  }

  // Check if emergency is currently active
  static Future<bool> isEmergencyActive(String cameraId) async {
    try {
      final file = File(_jsonFilePath);
      if (!await file.exists()) return false;

      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = json.decode(jsonString);

      if (data['traffic_data'] != null &&
          data['traffic_data'][cameraId] != null &&
          data['traffic_data'][cameraId]['metadata'] != null) {
        return data['traffic_data'][cameraId]['metadata']['emergency_active'] ==
            true;
      }

      return false;
    } catch (e) {
      print('Error checking emergency status: $e');
      return false;
    }
  }
}

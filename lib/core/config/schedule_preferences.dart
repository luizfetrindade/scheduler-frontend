import 'package:shared_preferences/shared_preferences.dart';

/// Persists schedule-specific user preferences (drag-and-drop enabled, etc.).
class SchedulePreferences {
  static const _kDragEnabled = 'schedule_drag_enabled';
  static const _kAttendancePromptEnabled = 'schedule_attendance_prompt_enabled';

  const SchedulePreferences._();

  static Future<bool> isDragEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kDragEnabled) ?? true;
  }

  static Future<void> setDragEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDragEnabled, value);
  }

  static Future<bool> isAttendancePromptEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAttendancePromptEnabled) ?? true;
  }

  static Future<void> setAttendancePromptEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAttendancePromptEnabled, value);
  }
}

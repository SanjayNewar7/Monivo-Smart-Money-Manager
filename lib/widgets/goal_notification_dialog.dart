// ===================================================================
// THIS FILE IS NO LONGER USED
// Custom savings goal notifications have been replaced with
// automatic notifications. Keep this file commented for reference.
// ===================================================================

/*
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../services/notification_service.dart';
import '../services/reminder_storage_service.dart';
import '../models/budget.dart';

class GoalNotificationDialog extends StatefulWidget {
  final String goalId;
  final String goalName;
  final GoalReminder? existingReminder; // For editing

  const GoalNotificationDialog({
    Key? key,
    required this.goalId,
    required this.goalName,
    this.existingReminder,
  }) : super(key: key);

  @override
  State<GoalNotificationDialog> createState() => _GoalNotificationDialogState();
}

class _GoalNotificationDialogState extends State<GoalNotificationDialog> {
  late String _selectedFrequency;
  late TimeOfDay _selectedTime;
  late int _selectedDay;
  late int _selectedWeekday;
  final TextEditingController _messageController = TextEditingController();
  late bool _enableNotification;
  bool _isLoading = false;
  bool _deleteAfterSave = false;

  final List<String> frequencies = ['daily', 'weekly', 'monthly'];
  final List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _initializeFromExistingReminder();
    _checkPermissions();
  }

  void _initializeFromExistingReminder() {
    if (widget.existingReminder != null) {
      final reminder = widget.existingReminder!;
      _selectedFrequency = reminder.frequency;
      _selectedTime = TimeOfDay(hour: reminder.hour, minute: reminder.minute);
      _selectedDay = reminder.dayOfMonth ?? DateTime.now().day;
      _selectedWeekday = reminder.dayOfWeek ?? DateTime.now().weekday;
      _messageController.text = reminder.customMessage ?? '';
      _enableNotification = reminder.isEnabled;
    } else {
      _selectedFrequency = 'weekly';
      _selectedTime = const TimeOfDay(hour: 9, minute: 0);
      _selectedDay = DateTime.now().day;
      _selectedWeekday = DateTime.now().weekday;
      _enableNotification = true;
    }
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await NotificationService().requestPermissions();
    if (!hasPermission && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable notifications in settings'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _getFrequencyText() {
    String timeStr = _selectedTime.format(context);
    switch (_selectedFrequency) {
      case 'daily':
        return 'every day at $timeStr';
      case 'weekly':
        return 'every ${weekdays[_selectedWeekday - 1]} at $timeStr';
      case 'monthly':
        return 'on day $_selectedDay at $timeStr';
      default:
        return '';
    }
  }

  Future<void> _testNotification() async {
    await NotificationService().showTestNotification();
    _showSuccessSnackBar('Test notification sent!');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryBlue,
                        AppColors.accentTeal,
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.notifications_active,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.existingReminder != null
                                  ? 'Edit Reminder'
                                  : 'Set Reminder',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              widget.goalName,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Enable Notification Switch
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _enableNotification
                                    ? Icons.notifications_on
                                    : Icons.notifications_off,
                                color: _enableNotification
                                    ? AppColors.primaryBlue
                                    : AppColors.textLight,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Enable Reminders',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Switch(
                                value: _enableNotification,
                                onChanged: (value) {
                                  setState(() {
                                    _enableNotification = value;
                                  });
                                },
                                activeColor: AppColors.primaryBlue,
                              ),
                            ],
                          ),
                        ),

                        if (_enableNotification) ...[
                          const SizedBox(height: 20),

                          // Test Button
                          if (widget.existingReminder != null)
                            Center(
                              child: TextButton.icon(
                                onPressed: _testNotification,
                                icon: const Icon(Icons.play_arrow, size: 16),
                                label: const Text('Test Notification'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primaryBlue,
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Frequency Selection
                          const Text(
                            'Remind me',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.lightGray,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: frequencies.map((frequency) {
                                final isSelected = _selectedFrequency == frequency;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedFrequency = frequency;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        frequency[0].toUpperCase() + frequency.substring(1),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : AppColors.textSecondary,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Time Selection
                          const Text(
                            'Time',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime,
                              );
                              if (time != null) {
                                setState(() {
                                  _selectedTime = time;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.lightGray,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time, color: AppColors.textLight, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    _selectedTime.format(context),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Day Selection for Weekly
                          if (_selectedFrequency == 'weekly') ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Day of Week',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(7, (index) {
                                final isSelected = _selectedWeekday == index + 1;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedWeekday = index + 1;
                                    });
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primaryBlue : AppColors.lightGray,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        weekdays[index],
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : AppColors.textSecondary,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],

                          // Day Selection for Monthly
                          if (_selectedFrequency == 'monthly') ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Day of Month',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 120,
                              child: GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  crossAxisSpacing: 4,
                                  mainAxisSpacing: 4,
                                ),
                                itemCount: 31,
                                itemBuilder: (context, index) {
                                  final day = index + 1;
                                  final isSelected = _selectedDay == day;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedDay = day;
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.primaryBlue : AppColors.lightGray,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          day.toString(),
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : AppColors.textSecondary,
                                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Custom Message
                          const Text(
                            'Custom Message (Optional)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _messageController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'e.g., Don\'t forget to save for your goal!',
                              filled: true,
                              fillColor: AppColors.lightGray,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          // Preview Section
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryBlue.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.preview,
                                      color: AppColors.primaryBlue,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Preview',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You\'ll be reminded ${_getFrequencyText()}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (_messageController.text.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Message: "${_messageController.text}"',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  'Next notification will arrive at the scheduled time.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textLight,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Delete option for existing reminder
                          if (widget.existingReminder != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.error.withOpacity(0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Delete this reminder',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: _deleteAfterSave,
                                    onChanged: (value) {
                                      setState(() {
                                        _deleteAfterSave = value;
                                      });
                                    },
                                    activeColor: AppColors.error,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  side: BorderSide(color: Colors.grey[300]!),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveReminder,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _deleteAfterSave
                                      ? AppColors.error
                                      : AppColors.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : Text(_deleteAfterSave ? 'Delete' : 'Save'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveReminder() async {
    setState(() => _isLoading = true);

    try {
      // Handle deletion if requested
      if (_deleteAfterSave && widget.existingReminder != null) {
        await NotificationService().cancelGoalNotification(widget.goalId);
        await ReminderStorageService.deleteReminder(widget.goalId);

        if (mounted) {
          Navigator.pop(context, true);
          _showSuccessSnackBar('Reminder deleted successfully');
        }
        return;
      }

      // Handle disabling
      if (!_enableNotification) {
        await NotificationService().cancelGoalNotification(widget.goalId);
        await ReminderStorageService.deleteReminder(widget.goalId);

        if (mounted) {
          Navigator.pop(context, true);
          _showSuccessSnackBar('Reminder disabled');
        }
        return;
      }

      // Create reminder object
      final reminder = GoalReminder(
        id: widget.existingReminder?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        goalId: widget.goalId,
        frequency: _selectedFrequency,
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
        dayOfWeek: _selectedFrequency == 'weekly' ? _selectedWeekday : null,
        dayOfMonth: _selectedFrequency == 'monthly' ? _selectedDay : null,
        customMessage: _messageController.text.isNotEmpty
            ? _messageController.text
            : null,
        isEnabled: true,
      );

      // Schedule the notification
      await NotificationService().scheduleGoalReminder(reminder, widget.goalName);

      // Save to storage
      await ReminderStorageService.saveReminder(reminder);

      if (mounted) {
        Navigator.pop(context, true);
        _showSuccessSnackBar(
          widget.existingReminder != null
              ? 'Reminder updated successfully'
              : 'Reminder set successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error: $e', AppColors.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showInfoSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppColors.warning ? Icons.warning : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
*/
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

// Enum for activity selection
enum Activity {
  WakeUp,
  Gym,
  Breakfast,
  Meetings,
  Lunch,
  Nap,
  Library,
  Dinner,
  Sleep
}

// Extension for converting Activity to string
extension ActivityExtension on Activity {
  String getName() {
    switch (this) {
      case Activity.WakeUp:
        return "Wake Up";
      case Activity.Gym:
        return "Go to Gym";
      case Activity.Breakfast:
        return "Breakfast";
      case Activity.Meetings:
        return "Meetings";
      case Activity.Lunch:
        return "Lunch";
      case Activity.Nap:
        return "Quick Nap";
      case Activity.Library:
        return "Go to Library";
      case Activity.Dinner:
        return "Dinner";
      case Activity.Sleep:
        return "Go to Sleep";
    }
  }
}

class ReminderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Reminder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ReminderScreen(),
      debugShowCheckedModeBanner: false, // Remove the debug banner
    );
  }
}

class ReminderScreen extends StatefulWidget {
  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  String selectedDay = "Monday";
  TimeOfDay selectedTime = TimeOfDay.now();
  Activity selectedActivity = Activity.WakeUp;
  late AudioPlayer audioPlayer;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Reminder'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDropdownButton(
              'Day',
              <String>[
                'Monday',
                'Tuesday',
                'Wednesday',
                'Thursday',
                'Friday',
                'Saturday',
                'Sunday',
              ],
              (String? value) {
                if (value != null) {
                  setState(() {
                    selectedDay = value;
                  });
                }
              },
            ),
            SizedBox(height: 20),
            _buildTimePicker(),
            SizedBox(height: 20),
            _buildDropdownButton(
              'Activity',
              Activity.values.map((activity) => activity.getName()).toList(),
              (String? value) {
                if (value != null) {
                  setState(() {
                    selectedActivity = Activity.values
                        .firstWhere((activity) => activity.getName() == value);
                  });
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _setReminder,
              child: Text("Set Reminder"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownButton<T>(
    String label,
    List<T> items,
    void Function(T?) onChanged,
  ) {
    return DropdownButton<T>(
      hint: Text(label),
      value: items.first,
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item.toString()),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildTimePicker() {
    return ElevatedButton(
      onPressed: () {
        showTimePicker(
          context: context,
          initialTime: selectedTime,
        ).then((pickedTime) {
          if (pickedTime != null && pickedTime != selectedTime) {
            setState(() {
              selectedTime = pickedTime;
            });
          }
        });
      },
      child: Text("Select Time: ${selectedTime.format(context)}"),
    );
  }

  void _setReminder() async {
    // Schedule the reminder
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day == DateTime.monday && selectedDay == "Monday"
          ? now.day
          : now.day +
              (DateTime.parse("$selectedDay next week").weekday - now.weekday),
      selectedTime.hour,
      selectedTime.minute,
    );

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(Duration(days: 7));
    }

    final difference = scheduledTime.difference(now);
    final minutesDifference = difference.inMinutes;

    // Check if the reminder time is not too close to the current time
    if (minutesDifference < 1) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Error"),
            content: Text(
                "The selected time is too close to the current time. Please select a future time."),
            actions: <Widget>[
              TextButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    // Set up the reminder to play sound
    final scheduledTimeDuration = scheduledTime.difference(now);
    Timer(scheduledTimeDuration, () {
      _playSound();
    });

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Reminder Set"),
          content: Text(
              "Your reminder for ${selectedActivity.getName()} on $selectedDay at ${selectedTime.format(context)} has been set."),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                _showSnackBar('Reminder set successfully');
              },
            ),
          ],
        );
      },
    );
  }

  void _playSound() async {
    await audioPlayer.play("assets/sounds/chime.mp3", isLocal: true);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

void main() {
  runApp(ReminderApp());
}

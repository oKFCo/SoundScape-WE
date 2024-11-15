import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../services/provider.dart';

class DurationPicker extends StatefulWidget {
  const DurationPicker({super.key});

  @override
  DurationPickerState createState() => DurationPickerState();
}

class DurationPickerState extends State<DurationPicker> {
  int _selectedMinute = 1;
  int _selectedSecond = 0;
  late TrackProvider _trackProvider;

  @override
  void initState() {
    super.initState();
    _trackProvider = Provider.of<TrackProvider>(context, listen: false);
    _loadWaitTime();
  }

  Future<void> _loadWaitTime() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String>? waitTime = prefs.getStringList('waitTime');
      if (waitTime != null) {
        setState(() {
          _selectedMinute = int.parse(waitTime[0]);
          _selectedSecond = int.parse(waitTime[1]);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to load saved wait time.'),
      ));
    }
  }

  Future<void> _saveWaitTime() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> waitTime = [
        _selectedMinute.toString(),
        _selectedSecond.toString()
      ];
      await prefs.setStringList('waitTime', waitTime);

      _trackProvider.worker.startWallpaperTimer();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Wait time saved'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to save wait time.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.timer),
          title: const Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Wallpaper Retention Time"),
              SizedBox(width: 8),
              Tooltip(
                message:
                    'If there are multiple wallpapers associated with a track, this value will determine how long to wait before switching to the next wallpaper.',
                child: Icon(Icons.info_outline, color: Colors.grey),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveWaitTime,
          ),
          subtitle: Text("$_selectedMinute min : $_selectedSecond sec"),
        ),
        // Minutes Slider Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Minutes"),
              Expanded(
                child: Slider(
                  value: _selectedMinute.toDouble(),
                  min: 0,
                  max: 59,
                  divisions: 59,
                  label: '$_selectedMinute',
                  onChanged: (value) {
                    setState(() {
                      _selectedMinute = value.toInt();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        // Seconds Slider Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Seconds"),
              Expanded(
                child: Slider(
                  value: _selectedSecond.toDouble(),
                  min: 0,
                  max: 59,
                  divisions: 59,
                  label: '$_selectedSecond',
                  onChanged: (value) {
                    setState(() {
                      int selectedValue = value.toInt();
                      if (_selectedMinute == 0 && selectedValue < 5) {
                        _selectedSecond = 5;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Minimum wait time is 5 seconds when minutes is set to 0.'),
                          ),
                        );
                      } else {
                        _selectedSecond = selectedValue;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

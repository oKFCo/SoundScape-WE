import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/provider.dart';
import '../services/user_data.dart';

class ResetDatabaseButton extends StatefulWidget {
  const ResetDatabaseButton({super.key});

  @override
  ResetDatabaseButtonState createState() => ResetDatabaseButtonState();
}

class ResetDatabaseButtonState extends State<ResetDatabaseButton> {
  bool _isLoading = false;

  // Function to show a success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Success"),
          content: const Text('Database has been reset successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // Function to show an error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  // Confirm reset and reset database
  Future<void> _confirmResetDatabase() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Are you sure?"),
          content: const Text(
              "This will permanently delete all your SoundScape data."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Reset"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserData userData = UserData();
        await userData.clearDatabase();

        _showSuccessDialog();

        Provider.of<TrackProvider>(context, listen: false)
            .updateTrackWallpapers();
      } catch (e) {
        _showErrorDialog('Failed to reset database. Please try again.');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading
          ? null
          : _confirmResetDatabase, // Disable button if loading
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      child: _isLoading
          ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          : const Text('Reset Database'),
    );
  }
}

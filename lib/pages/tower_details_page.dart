import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tower.dart';
import 'view_issues.dart'; // Import the new screen

class TowerDetailsPage extends StatefulWidget {
  final Tower tower;

  const TowerDetailsPage({super.key, required this.tower});

  @override
  _TowerDetailsPageState createState() => _TowerDetailsPageState();
}

class _TowerDetailsPageState extends State<TowerDetailsPage> {
  String? _selectedStatus;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmittingStatus = false;
  bool _isSubmittingFeedback = false;
  List<Map<String, dynamic>> _feedbacks = [];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.tower.progress;
    _fetchFeedbacks();  // Fetch the feedbacks on init
  }

  void _fetchFeedbacks() async {
  try {
    // Get the specific tower document
    final docSnapshot = await FirebaseFirestore.instance
        .collection('towers')
        .doc(widget.tower.id)
        .get();

    // Check if the document exists and has the 'feedbacks' field
    if (docSnapshot.exists && docSnapshot.data()!.containsKey('feedbacks')) {
      // Access the feedbacks array directly from the document data
      final fetchedFeedbacks = docSnapshot.data()!['feedbacks'] as List<dynamic>;

      setState(() {
        // Cast the list of dynamic maps to the correct type for your state variable
        _feedbacks = fetchedFeedbacks.cast<Map<String, dynamic>>();
      });
    } else {
      // Handle the case where the document or feedbacks field doesn't exist
      setState(() {
        _feedbacks = [];
      });
    }
  } catch (e) {
    print("Error fetching feedbacks: $e");
    // Optionally show a snackbar or other UI feedback
  }
}

  Future<void> _updateStatus() async {
    if (_selectedStatus == null) return;

    setState(() {
      _isSubmittingStatus = true;
    });

    try {
      final updateData = <String, dynamic>{
        'progress': _selectedStatus,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('towers')
          .doc(widget.tower.id)
          .update(updateData);

      setState(() {
        widget.tower.progress = _selectedStatus!;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully!')),
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: ${e.message}')),
      );
    } finally {
      setState(() {
        _isSubmittingStatus = false;
      });
    }
  }

Future<void> _submitFeedback() async {
  if (_feedbackController.text.trim().isEmpty) return;

  setState(() {
    _isSubmittingFeedback = true;
  });

  try {
    final user = FirebaseAuth.instance.currentUser;

    // Create the new feedback map with a standard DateTime object
    final newFeedback = {
      'author': user?.displayName ?? 'Anonymous',
      'feedback': _feedbackController.text.trim(),
      'timestamp': DateTime.now(), // Use a standard DateTime object instead
    };

    // Use .update() with FieldValue.arrayUnion to add the new feedback to the array
    await FirebaseFirestore.instance
        .collection('towers')
        .doc(widget.tower.id)
        .update({
          'feedbacks': FieldValue.arrayUnion([newFeedback]),
        });

    _feedbackController.clear();
    _fetchFeedbacks(); // Refresh the list of feedbacks

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Feedback submitted successfully!')),
    );
  } on FirebaseException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error submitting feedback: ${e.message}')),
    );
  } finally {
    setState(() {
      _isSubmittingFeedback = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.tower.id)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Tower Info
            Text(widget.tower.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Latitude: ${widget.tower.latitude}'),
            Text('Longitude: ${widget.tower.longitude}'),
            const SizedBox(height: 16),

            // View Issues Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ViewIssuesPage(towerId: widget.tower.id),
                    ),
                  );
                },
                icon: const Icon(Icons.warning_amber),
                label: const Text('View Active Issues'),
              ),
            ),
            const SizedBox(height: 24),

            // Status Dropdown and Update Button
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Update Status',
                      border: OutlineInputBorder(),
                    ),
                    items: <String>['Unsurveyed', 'In Progress', 'Completed']
                        .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedStatus = val;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSubmittingStatus ? null : _updateStatus,
                  child: _isSubmittingStatus
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tower Details
            Text('Site Details', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Address: ${widget.tower.address}'),
            Text('Region: ${widget.tower.region}'),
            Text('Type: ${widget.tower.type}'),
            const SizedBox(height: 16),

            // Feedback Input and Submit Button
            const Text('Add Feedback:'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _feedbackController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Enter feedback here...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmittingFeedback ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmittingFeedback
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Feedback'),
              ),
            ),
            const SizedBox(height: 24),

            // Display Feedbacks
            Text('Feedbacks', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ..._feedbacks.map((fb) {
              DateTime? timestamp;
              if (fb['timestamp'] is Timestamp) {
                timestamp = (fb['timestamp'] as Timestamp).toDate();
              } else if (fb['timestamp'] is DateTime) {
                timestamp = fb['timestamp'] as DateTime;
              }

              return ListTile(
                title: Text(fb['feedback']?.toString() ?? 'No feedback'), // Changed from 'description'
                subtitle: Text(timestamp != null ? 'on ${timestamp.toLocal()}' : 'No timestamp'),
                trailing: Text(fb['author'] ?? 'Anonymous'), // Changed from 'authorName'
                leading: const Icon(Icons.feedback),
              );
            }), // Add .toList() to ensure the list is built
          ],
        ),
      ),
    );
  }
}

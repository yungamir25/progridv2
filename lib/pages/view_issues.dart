// view_issues.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'ticket.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import this


class ViewIssuesPage extends StatefulWidget {
  final String towerId;

  const ViewIssuesPage({super.key, required this.towerId});

  @override
  _ViewIssuesPageState createState() => _ViewIssuesPageState();
}

class _ViewIssuesPageState extends State<ViewIssuesPage> {
  // New function to update the issue status

Future<void> _resolveIssue(String issueId) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Anonymous'; // Get the user's name

    await FirebaseFirestore.instance.collection('issues').doc(issueId).update({
      'status': 'resolved',
      'resolvedBy': userName, // Store the name of the user who resolved it
      'resolvedAt': FieldValue.serverTimestamp(), // Optional: add a timestamp
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Issue $issueId resolved successfully!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error resolving issue: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Issues for ${widget.towerId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreateTicketPage(towerId: widget.towerId),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('issues')
            .where('towerId', isEqualTo: widget.towerId)
            .orderBy('dateTime', descending: true)
            
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No issues found for this tower.'));
          }

          final issues = snapshot.data!.docs;
          return ListView.builder(
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issueDoc = issues[index];
              final issue = issueDoc.data() as Map<String, dynamic>;
              final timestamp = issue['dateTime'] as Timestamp?;
              final formattedDate = timestamp?.toDate().toLocal().toString().split('.')[0];
              final status = issue['status']?.toString() ?? 'N/A';
              final description = issue['description']?.toString() ?? 'No Description';
              final tags = (issue['tags'] as List<dynamic>?)?.join(', ') ?? 'No tags';

              // Determine the icon and color based on the status
              final isResolved = status == 'resolved';
              final icon = isResolved ? Icons.check_circle_outline : Icons.pending_actions;
              final iconColor = isResolved ? Colors.green : Colors.orange;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(icon, color: iconColor), // Icon to show status
                  title: Text(issue['id'] ?? 'No ID'),
                  subtitle: Text(
                    'Status: ${status.toUpperCase()}\nDescription: $description\nTags: $tags${isResolved ? '\nResolved by: ${issue['resolvedBy'] ?? 'Anonymous'}' : ''}', // Add the new line here
                  ),
                  trailing: isResolved
                      ? null // No button for resolved issues
                      : IconButton(
                          icon: const Icon(Icons.done_all, color: Colors.blue),
                          onPressed: () => _resolveIssue(issueDoc.id),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
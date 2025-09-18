// ticket.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart'; // Add this to your pubspec.yaml

class CreateTicketPage extends StatefulWidget {
  final String towerId;

  const CreateTicketPage({super.key, required this.towerId});

  @override
  _CreateTicketPageState createState() => _CreateTicketPageState();
}

class _CreateTicketPageState extends State<CreateTicketPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedStatus = 'unresolved';
  String _selectedTag = 'Hazard';
  bool _isSaving = false;

  final List<String> _statuses = ['unresolved', 'resolved'];
  final List<String> _tags = ['Hazard', 'Network', 'Maintenance'];

  Future<void> _createTicket() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        final authorId = user?.uid ?? 'anonymous_user';
        final newTicketId = const Uuid().v4().substring(0, 4).toUpperCase();
        final documentId = '${widget.towerId}-$newTicketId';

        final newTicket = {
          'id': documentId,
          'authorId': authorId,
          'dateTime': FieldValue.serverTimestamp(),
          'description': _descriptionController.text.trim(),
          'status': _selectedStatus,
          'tags': [_selectedTag],
          'towerId': widget.towerId,
        };

        await FirebaseFirestore.instance.collection('issues').doc(documentId).set(newTicket);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket created successfully!')),
        );
        Navigator.of(context).pop(); // Go back to the previous page
      } on FirebaseException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating ticket: ${e.message}')),
        );
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Ticket for ${widget.towerId}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: _statuses
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedTag,
                decoration: const InputDecoration(
                  labelText: 'Tag',
                  border: OutlineInputBorder(),
                ),
                items: _tags
                    .map((tag) => DropdownMenuItem(
                          value: tag,
                          child: Text(tag),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTag = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _createTicket,
                      child: const Text('Save Ticket'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
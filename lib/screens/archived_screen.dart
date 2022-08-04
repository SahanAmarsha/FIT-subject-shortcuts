import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_pwa/components/subject_widget.dart';

import '../constants/paddings.dart';
import '../constants/shared_preferences_constants.dart';
import '../models/models.dart';

class ArchivedSubjectsScreen extends StatefulWidget {
  final SharedPreferences sharedPreferences;
  final ConfigModule configModule;
  final VoidCallback onUnArchived;
  final String semCode;

  const ArchivedSubjectsScreen(
      {Key? key,
      required this.sharedPreferences,
      required this.configModule,
      required this.onUnArchived,
      required this.semCode})
      : super(key: key);

  @override
  State<ArchivedSubjectsScreen> createState() => _ArchivedSubjectsScreenState();
}

class _ArchivedSubjectsScreenState extends State<ArchivedSubjectsScreen> {

  @override
  Widget build(BuildContext context) {
    final subjects = widget.sharedPreferences
        .getStringList(SharedPreferencesConstants.hiddenSubject) ??
        [];

    return Scaffold(
      appBar: AppBar(
        title: Text("Hidden Subjects"),
      ),
      body: subjects.length > 0
          ? ListView(
        padding: kDefaultPadding,
        children: (subjects).map(
              (e) {
            final subject = widget.configModule.getSubject(e);
            if (subject == null) {
              return const SizedBox.shrink();
            } else {
              return SubjectWidget(
                isArchived: true,
                onPressArchived: _onPressArchived, subject: subject,
              );
            }
          },
        ).toList(),
      )
          : const Center(child: Text("There is no hidden subject")),
    );
  }

  _onPressArchived(bool isArchived, Subject subject) async {
    final sharedPreferences = await SharedPreferences.getInstance();
    final hiddenSubject = sharedPreferences
        .getStringList(SharedPreferencesConstants.hiddenSubject) ??
        [];
    setState(() {
      hiddenSubject.remove(subject.code);
      sharedPreferences.setStringList(
          SharedPreferencesConstants.hiddenSubject, hiddenSubject);
      final ordered = sharedPreferences.getStringList(
          SharedPreferencesConstants.orderedSubjects(widget.semCode))!;
      ordered.add(subject.code);
      sharedPreferences.setStringList(
          SharedPreferencesConstants.orderedSubjects(widget.semCode), ordered);
    });
    widget.onUnArchived();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('${subject.name} unarchived')));
  }
}

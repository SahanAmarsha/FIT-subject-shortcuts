import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_pwa/components/subject_widget.dart';
import 'package:test_pwa/config/my_modules.dart';
import 'package:test_pwa/constants/constants.dart';
import 'package:test_pwa/models/models.dart';
import 'package:test_pwa/screens/archived_screen.dart';

import '../components/yes_on_alert.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final String semCode = "L4_S1";

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TempHolder>(
        future: _loadModules(),
        builder: (context, snapshot) {
          if(snapshot.hasError) {
            return Scaffold(body: Center(
              child: Text(snapshot.error.toString()),
            ));
          }
          if(!snapshot.hasData) {
            return const Scaffold(body: Center(
              child: Text('Could not load modules'),
            ));
          } else {
            final data = snapshot.data!.module;
            final sharedPreferences = snapshot.data!.sharedPreferences;
            return Scaffold(
                appBar: AppBar(
              title: const Text("L4S1 Module Shortcuts"),
               actions: [
                 IconButton(
                   onPressed: () =>
                       _onTapHiddenList(context, data, sharedPreferences),
                   icon: const Icon(Icons.archive_outlined),
                   tooltip: "Archived Subjects",
                 ),
               ],
            ),
            body: ReorderableListView(
              padding: kDefaultPadding,
              buildDefaultDragHandles: false,
              onReorder: (o, n) => _onChangeOrder(o, n, data.four.one, sharedPreferences),
              children: loadSubjects(data.four.one, sharedPreferences),
            ),);
          }
        }
    );
  }

  List<Widget> loadSubjects(
      List<Subject> subjects, SharedPreferences sharedPreferences) {
    final hiddenList = sharedPreferences
        .getStringList(SharedPreferencesConstants.hiddenSubject) ??
        [];
    final list = _loadOrderedList(subjects, sharedPreferences);
    int index = 0;
    return list
        .where((element) => !hiddenList.contains(element))
        .map((e) => subjects.singleWhere((element) => element.code == e))
        .map((e) => SubjectWidget(
      subject: e,
      key: ValueKey(e.code),
      onPressArchived: _onPressArchived,
      index: index++,
    ))
        .toList();
  }

  List<String> _loadOrderedList(
      List<Subject> subjects,
      SharedPreferences sharedPreferences,
      ) {
    var orderedList = sharedPreferences
        .getStringList(SharedPreferencesConstants.orderedSubjects(semCode));
    if (orderedList == null) {
      orderedList = subjects.map((e) => e.code).toList();
      sharedPreferences.setStringList(
          SharedPreferencesConstants.orderedSubjects(semCode), orderedList);
    }
    return orderedList;
  }

  void _onChangeOrder(
      int oldIndex,
      int newIndex,
      List<Subject> subjects,
      SharedPreferences sharedPreferences,
      ) {
    final orderedList = _loadOrderedList(subjects, sharedPreferences);
    if (oldIndex < newIndex) {
      // removing the item at oldIndex will shorten the list by 1.
      newIndex -= 1;
    }
    final element = orderedList.removeAt(oldIndex);
    orderedList.insert(newIndex, element);
    setState(() {
      sharedPreferences.setStringList(
          SharedPreferencesConstants.orderedSubjects(semCode), orderedList);
    });
  }

  _onPressArchived(bool isArchived, Subject subject) async {
    final confirm = (await showDialog<bool>(
      context: context,
      builder: (context) {
        return YesNoAlert(
          title: 'Confirm',
          message: 'Do you want to archive ${subject.name}?',
          yesOnPressed: () => Navigator.pop(context, true),
        );
      },
    )) ??
        false;
    if (confirm) {
      final sharedPreferences = await SharedPreferences.getInstance();
      final hiddenSubject = sharedPreferences
          .getStringList(SharedPreferencesConstants.hiddenSubject) ??
          [];
      setState(() {
        hiddenSubject.add(subject.code);
        sharedPreferences.setStringList(
            SharedPreferencesConstants.hiddenSubject, hiddenSubject);
        final ordered = sharedPreferences.getStringList(
          SharedPreferencesConstants.orderedSubjects(semCode),
        );
        ordered!.removeWhere((element) => element == subject.code);
        sharedPreferences.setStringList(
            SharedPreferencesConstants.orderedSubjects(semCode), ordered);
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${subject.name} archived')));
    }
  }

  void _onTapHiddenList(BuildContext context, ConfigModule configModule,
      SharedPreferences sharedPreferences) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ArchivedSubjectsScreen(
          sharedPreferences: sharedPreferences,
          configModule: configModule,
          onUnArchived: () => setState(() {}),
          semCode: semCode,
        ),
      ),
    );
  }

  Future<TempHolder> _loadModules() async {
    return TempHolder(myModules, await SharedPreferences.getInstance());
  }
}

class TempHolder {
  final ConfigModule module;
  final SharedPreferences sharedPreferences;

  const TempHolder(this.module, this.sharedPreferences);
}

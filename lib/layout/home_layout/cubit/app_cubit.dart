import 'package:bloc/bloc.dart';
import 'package:first_flutter_app/layout/home_layout/cubit/app_states.dart';
import 'package:first_flutter_app/modules/archived_task_screen/archived_task_screen.dart';
import 'package:first_flutter_app/modules/home_layout_done_task/done_task_screen.dart';
import 'package:first_flutter_app/modules/home_layout_new_task/new_task_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite/sqflite.dart';

class AppCubit extends Cubit<AppStates>{

  AppCubit() : super(AppInitialState());

  static AppCubit get(context)=> BlocProvider.of(context);

  int currentIndex = 0 ;

  List<String> titles = [
    'New Task',
    'Done Tasks',
    'Archived Tasks',
  ];

  List<Widget> screens = [
    newTask(),
    doneTask(),
    archivedTask(),
  ];

  List<Map> newTasks = [];
  List<Map> doneTasks = [];
  List<Map> archivedTasks = [];
  late Database database ;
  IconData fabIcon = Icons.edit;
  bool isBottomSheetShown = false;

  void ChangeIndex(int index){
    currentIndex = index;
    emit(AppChangeBottomNavIndexState());
  }

  void createDatabase()  {
   openDatabase(
      'todo.db',
      version: 1,
      onCreate: (database, version)
      {
        print('database created');
         database.execute('CREATE TABLE tasks (id INTEGER PRIMARY KEY, title TEXT, date TEXT, time TEXT, status TEXT, description TEXT)').then((value) {
           print('table created');
         });
      },
      onOpen: (database)
      {
        getDataFromDatabase(database);
        print('database opened');
        emit(AppGetDatabaseState());
      },
    ).then((value) {
      database = value;
      emit(AppCreateDatabaseState());
   });
  }

   insertToDatabase({
    required String title,
    required String date,
    required String time,
    required String description,
  }) async{
    await database.transaction((txn) async{
       txn.rawInsert('INSERT INTO tasks (title ,date ,time ,status ,description) VALUES("$title", "$date", "$time", "new", "$description")')
          .then((value) {
        print('$value inserted successfully');
        emit(AppInsertDatabaseState());
        getDataFromDatabase(database);
      }).catchError((error){
        print('error when inserting new row ${error.toString()}');
      });
    });
  }

  void getDataFromDatabase(database){
    newTasks = [];
    doneTasks = [];
    archivedTasks = [];
     database.rawQuery('SELECT * FROM tasks').then((value) {

       value.forEach((element){
         if (element['status'] == 'new')
           newTasks.add(element);
         else if (element['status'] == 'done')
           doneTasks.add(element);
         else
           archivedTasks.add(element);

       });
       emit(AppGetDatabaseState());
     });
  }

  void UpdateData ({
    required String status,
    required int id,
  })async
  {

    database.rawUpdate("UPDATE tasks SET status = ? WHERE id = ?",
      ['$status',id],).then((value) {

      emit(AppChangeStatus());
      getDataFromDatabase(database);
      emit(AppUpdateDatabaseState());
    });
  }

  void DeleteData ({
    required int id,
  })async
  {

    database.rawDelete('DELETE FROM tasks WHERE id = ?' ,['$id'],)
        .then((value) {

      getDataFromDatabase(database);
      emit(AppDeleteDatabaseState());
    });
  }


  void ChangeBottomSheetState({
    required bool isShow,
    required IconData icon
})
  {
    isBottomSheetShown = isShow;
    fabIcon = icon;
    emit(AppChangeBottomSheetState());
  }


}


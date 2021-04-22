import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:giftty/api/apiRepository.dart';

import 'bloc.dart';

class TestBloc extends Bloc<TestEvent, TestState> {
  
  ApiRepository repository;
  TestBloc({@required this.repository}) : super(null);


  @override
  Stream<TestState> mapEventToState(TestEvent event) async* {
    if (event is ChangeSomeValues) {
      
    }
  }
}







// class ChangeSomeValues extends MyEvent {
//   final int data;

//   ChangeSomeValues(this.data);
// }
// to dispatch it from the calling page
// BlocBuilder(
//   bloc: myBloc,
//   builder: (context, state) {
//     return ListView.builder(
//       itemCount: state.buttonList.length,
//       itemBuilder: (context, index) {
//         return MyButton(
//           label: buttonList[index].label,
//           value: buttonList[index].value,
//           onPressed: myBloc.dispatch(ChangeSomeValues()),
//         );
//       }
//     );
//   }
// ),
// dispatch it as : myBloc.dispatch(ChangeSomeValues(15))

// The bloc

// class MyBloc extends Bloc<MyEvent, MyState> {

//   @override
//   Stream<MyState> mapEventToState(MyEvent event) async* {
//     if (event is ChangeSomeValues) {
//       print("here's the data : ${event.data}");
//     }
//   }
// }
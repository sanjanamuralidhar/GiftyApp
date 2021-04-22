import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:giftty/Model/models.dart';
import 'package:giftty/api/apiRepository.dart';
import 'package:meta/meta.dart';

import 'bloc.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  ApiRepository repository;
  NotificationBloc({@required this.repository}) : super(null);

  @override
  Stream<NotificationState> mapEventToState(
      NotificationEvent event,
      ) async* {
    try {
      if (event is FetchNotificationEvent) {
        yield (NotificationLoading());
        List<Notification_Model> notifications = await repository.getNotification();
        print('......../////////........${notifications.length}');
        yield (NotificationLoaded(articles: notifications));
      }
    } catch (e) {
      yield NotificationError('notifications not found');
    }
  }
}
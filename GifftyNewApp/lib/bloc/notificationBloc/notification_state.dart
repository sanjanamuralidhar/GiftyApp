

import 'package:giftty/Model/models.dart';

abstract class NotificationState {
  const NotificationState();
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationLoaded extends NotificationState {
  List<Notification_Model> articles;

  NotificationLoaded({this.articles});

  @override
  // ignore: override_on_non_overriding_member
  List<Object> get props => [articles];
}

class NotificationError extends NotificationState {
  final String error;
  const NotificationError(this.error);
}
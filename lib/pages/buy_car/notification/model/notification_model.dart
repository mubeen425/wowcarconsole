
// To parse this JSON data, do
//
//     final notificationModel = notificationModelFromJson(jsonString);

import 'dart:convert';

NotificationModel notificationModelFromJson(String str) => NotificationModel.fromJson(json.decode(str));

String notificationModelToJson(NotificationModel data) => json.encode(data.toJson());

class NotificationModel {
  List<MessageDatum>? messages;

  NotificationModel({
    this.messages,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    messages: json["messages"] == null ? [] : List<MessageDatum>.from(json["messages"]!.map((x) => MessageDatum.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "messages": messages == null ? [] : List<dynamic>.from(messages!.map((x) => x.toJson())),
  };
}

class MessageDatum {
  String? id;
  String? lang;
  dynamic userId;
  bool? isAllUser;
  String? message;
  DateTime? createdDate;
  int? is_deleted;

  MessageDatum({
    this.id,
    this.lang,
    this.userId,
    this.isAllUser,
    this.message,
    this.createdDate,
    this.is_deleted
  });

  factory MessageDatum.fromJson(Map<String, dynamic> json) => MessageDatum(
    id: json["id"],
    lang: json["lang"],
    userId: json["user_id"],
    isAllUser: json["is_all_user"],
    message: json["message"],
    createdDate: json["created_date"] == null ? null : DateTime.parse(json["created_date"]),
    is_deleted: json["is_deleted"] ?? 0,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "lang": lang,
    "user_id": userId,
    "is_all_user": isAllUser,
    "message": message,
    "created_date": createdDate?.toIso8601String(),
    "is_deleted": is_deleted ?? 0,
  };
}


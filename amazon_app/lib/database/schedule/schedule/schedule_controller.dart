import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../riverpod.dart';
// import '/database/authentication.dart';
import 'schedule.dart';


//関数の場合は、Map型になるので、動的（dynamic）の返り値となるが、クラスの場合、それぞれの変数に型をつけることができ、返り値を必要としないため、
//データベースから値を取得する際は、クラスの方が保守性が上がる。
// //ODMを使用すればなんとかなるんじゃね？？？
// //まずは、freezedと使う。

class ScheduleController {
  static final db = FirebaseFirestore.instance;

  ///schedule path
  static const collectionPath = 'schedules';

  /// FirestoreのTimestampからDateTimeに変換
  static DateTime? convertTimestampToDateTime(dynamic timestamp) {
    return timestamp is Timestamp ? timestamp.toDate() : null;
  }

  ///Create schudule database.
  ///Return created schedule document ID.
  static Future<void> create(
    ///Named parameters
    {
      required String groupId,
      required String title,
      required Color color,
      String? place,
      String? detail,
      required DateTime startAt,
      required DateTime endAt,
    }
  ) async {
    ///Create new document ID.
    final doc = db.collection(collectionPath).doc();

    ///Change Color from String of type.
    final colorToString = color.toString();

    ///Get created server time.
    final createdAt = FieldValue.serverTimestamp();

    await doc.set({
      'group_id': groupId,
      'title': title,
      'color': colorToString,
      'place': place,
      'detail': detail,
      'start_at': startAt,
      'end_at': endAt,
      'created_at': createdAt,
    });
  }

  ///Get all schedule database.
  static Future<List<Schedule>> readAll(String groupId) async {
    final QuerySnapshot snapshot = await db.collection(collectionPath)
      .where('group_id',isEqualTo: groupId,).get();

    final schedules = snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Error: No found document data.');
      }

      ///Checked type of database variable;
      final groupId = data['group_id'] as String;
            
      // var groupId = data['group_id'];
      // if (groupId is! String) {
      //   groupId = groupId.toString();
      // }

      final documentId = doc.id;
      final title = data['title'] as String;
      final color = data['color'] as Color;
      final place = data['place'] as String?;
      final detail = data['detail'] as String?;
      final startAt = data['start_at'] as DateTime;
      final endAt = data['end_at'] as DateTime;
      final createdAt = data['created_at'] as DateTime?;
      
      return Schedule(
        groupId: groupId,
        documentId: documentId,
        title: title,
        color: color,
        place: place,
        detail: detail,
        startAt: startAt,
        endAt: endAt,
        createdAt: createdAt,
      );
    }).toList();

    return schedules;
  }

  //Get selected schedule database.
  static Future<Schedule> read(String documentId) async {
    final snapshot = await db.collection(collectionPath).doc(documentId).get();
    final data = snapshot.data();
    if (data == null) {
      throw Exception('documentId not found.');
    }

    //型が正しいかどうかチェック。
    var groupId = data['group_id'];
    if (groupId is! String) {
      groupId = groupId.toString();
    }

    var title = data['title'];
    if (title is! String) {
      title = title.toString();
    }

    var place = data['place'];
    if (place is! String) {
      place = place.toString();
    }

    var color = data['color'];
    if (color is! Color) {
      color as Color;
    }

    var detail = data['detail'];
    if (detail is! String) {
      detail = detail.toString();
    }

    var startAt = convertTimestampToDateTime(data['start_at']);
    if (startAt is! DateTime) {
      startAt = null;
      throw Exception('Error: start_at is not valid.');
    }

    var endAt = convertTimestampToDateTime(data['end_at']);
    if (endAt is! DateTime) {
      endAt = null;
      throw Exception('Error: start_at is not valid.');
    }

    final createdAt = convertTimestampToDateTime(data['created_at']);

    return Schedule(
      documentId: documentId,
      groupId: groupId,
      title: title,
      place: place,
      color: color,
      detail: detail,
      startAt: startAt,
      endAt: endAt,
      createdAt: createdAt,
    );
  }

  ///Update scheule database.
  ///Group ID can't be changed.
  static Future<void> update({
    required String groupId,
    required String documentId,
    required String title,
    required String? place,
    required Color color,
    required String? detail,
    required DateTime startAt,
    required DateTime endAt,
  }
  ) async {
    final updateData = <String, dynamic>{
      'title': title,
      'place': place,
      'color': color.toString(),
      'detail': detail,
      'start_at': Timestamp.fromDate(startAt),
      'end_at': Timestamp.fromDate(endAt),
    };

    await db.collection(collectionPath).doc(documentId).update(updateData);
  }

  static Future<void> delete(String documentId) async {
    await db.collection(collectionPath).doc(documentId).delete();
  }

  ///Watch schedule database.
  Stream<void> watch() async* {

  }

}

//StreamProvider #######################










// 以下はデータを追加する関数
// updateDocumentData(コレクション(user_info or group_info or Schedule_info),docId(user.uid or primaryGropuId),Map型のデータ)で成功したらtrueを返す。
// この関数を使う前にMap型のデータを定義する必要がある詳細は110行目あたりに書いてある。
Future<bool> updateDocumentData(String collectionName, String docId,
    Map<String, dynamic> updateData, WidgetRef ref,) async {
  final firestore = ref.watch(firestoreProvider);
  try {
    // 現在ログイン中のユーザー情報を取得しログイン済みであったらcollectionNameのdocIdのfieldにupdateDataを追加する作業
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentReference userDoc =
          firestore.collection(collectionName).doc(docId);
      await userDoc.set(updateData, SetOptions(merge: true));
      print('データのアップデート成功しました');
      return true;
    } else {
      print('ユーザーがサインインしていません');
      return false;
    }
  } catch (error) {
    print('データのアップデート中にエラーが発生しました: $error');
    return false;
  }
}

// class DatabasesPage extends ConsumerWidget {
//   const DatabasesPage({Key? key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final FirebaseAuth _auth = FirebaseAuth.instance;

//     return CupertinoApp(
//       home: CupertinoPageScaffold(
//         navigationBar: const CupertinoNavigationBar(
//           middle: Text('Firebase 操作ページ'),
//         ),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               CupertinoButton.filled(
//                 onPressed: () async {
//                   try {
//                     User? user = _auth.currentUser;

//                     if (user == null) {
//                       UserCredential userCredential =
//                           await _auth.signInWithEmailAndPassword(
//                         email: 'sample@gmail.com',
//                         password: 'aiueo12345',
//                       );
//                       print('userInfo: ${userCredential.user}');
//                       user = userCredential.user;
//                     }

//                     if (user != null) {
//                       // 以下はデータを追加する作業まず、Map型のデータ(今回はloginData)を定義する。
//                       // 次に、updataDocumentData関数を使いデータをfirestoreに追加する。()内については56行目あたりに書いてある。
//                       Map<String, dynamic> loginData = {"user_name": "test"};
//                       print(await updateDocumentData(
//                           'user_info', user.uid, loginData, ref));

//                       // 以下はデータを取得する作業まず、Map型のデータにgetDocumentData関数を使って定義する。()内については56行目あたりに書いてある。
//                       // 次に、dynamic型にMap型で取得したデータのうち使うデータ(今回はuser_name)を指定し定義する。
//                       Map<String, dynamic>? documentData =
//                           await getDocumentData('user_info', user.uid, ref);
//                       dynamic user_name = documentData!['user_name'];
//                       print(user_name);
//                     } else {
//                       print('ユーザーは認証されていません。');
//                     }
//                   } catch (e) {
//                     print('サインインでエラーが発生しました: $e');
//                   }
//                 },
//                 child: Text('アカウント情報表示'),
//               ),
//               SizedBox(height: 20),
//               CupertinoButton(
//                 onPressed: () {
//                   createAccount("sample@gmail.com", "aiueo12345");
//                 },
//                 child: Text('アカウント作成'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

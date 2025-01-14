import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/login_db.dart';

Future<String?> searchUser(String uid) async {
  print("searching user...");
  final db = FirebaseFirestore.instance;
  late String docid = '';

  try {

    await db.collection("User")
        .where("uid", isEqualTo: uid)
        .get()
        .then((value) {
      for (var element in value.docs) {
        //print(element.id);
        docid = element.id;
      }
    });
  } catch (e) {
    print(e);
  } finally {
    print('successfully finished request!');
  }
  return docid;
}

Future<String?> searchSpace(String uid, String sid) async {
  print("searching space...");
  final db = FirebaseFirestore.instance;
  late String docid = '';
  try {
    var userDoc = await db.collection("User").doc(uid).get();
    if (userDoc.exists) {
      List<dynamic> enteredSpaces = userDoc.data()?['entered'] ?? [];
      if (enteredSpaces.contains(sid)) {
        var spaceQuery = await db.collection("Space")
            .where("sid", isEqualTo: sid)
            .get();
        for (var element in spaceQuery.docs) {
          docid = element.id;
        }
      } else {
        print('User is not part of this space.');
      }
    }
  } catch (e) {
    print('Error in searchSpace: $e');
  } finally {
    print('successfully searched space: $docid!');
  }
  return docid;
}


Future<String?> searchData(String uid) async {
  print("searching data...");
  final db = FirebaseFirestore.instance;
  final sid = await getSpaceId();
  late String res = '';
  late String docid = '';
  try {
    if (sid != null) {
      final spaceId = await searchSpace(uid, sid);
      if (spaceId != null) {
        res = spaceId;
        final categoryCollection = await db.collection("Space")
            .doc(res)
            .collection('Category')
            .get();
        for (var element in categoryCollection.docs) {
          print(element.id);
        }
      } else {
        print('Space ID not found.');
      }
    } else {
      print('Space ID is null.');
    }
  } catch (e) {
    print('Error in searchData: $e');
  } finally {
    print('successfully searched data!');
  }
  return docid;
}


Future<String?> checkUserId(String uid) async {
  print("checking data...");

  final db = FirebaseFirestore.instance;
  late String docid = '';

  try {
    await db.collection("User")
        .where("uid", isEqualTo: uid)
        .get()
        .then((value) {
      for (var element in value.docs) {
        //print(element.id);
        docid = element.id;
      }
    });
  } catch (e) {
    print(e);
  } finally {
    if (docid == '') {
      print('finishing request failed!');
      print('docid is $docid.');
    } else {
      print('successfully finished request!');
    }
  }
  return docid;
}

Future<String?> getCateName(String uid) async {
  final db = FirebaseFirestore.instance;
  final sid = await getSpaceId();
  String? cname;
  print("Fetching cname data...");

  try {
    if (sid != null) {
      final spaceId = await searchSpace(uid, sid);
      if (spaceId != null) {
        DocumentSnapshot<Map<String, dynamic>> docSnapshot = await db
            .collection('Space')
            .doc(spaceId)
            .collection('Category')
            .doc('categories')
            .get();

        if (docSnapshot.exists) {
          List<dynamic>? cnameList = docSnapshot.data()?['cname'];
          if (cnameList != null && cnameList.isNotEmpty) {
            for (var name in cnameList) {
              if (name == 'event') {
                cname = name;
                break;
              }
            }
          } else {
            print('cname field is empty or does not exist.');
          }
        } else {
          print('Document does not exist.');
        }
      } else {
        print('Space ID not found.');
      }
    } else {
      print('Space ID is null.');
    }
  } catch (e) {
    print('Error fetching cname data: $e');
  } finally {
    print('Finished fetching cname data.');
  }

  return cname;
}

Future<void> loginUser(String uid, String password) async {
  final db = FirebaseFirestore.instance;
  String? udocid = '';

  try {
    // 로그인 검증
    bool isValid = await validateLogin(uid, password);

    if (isValid) {
      print("Login successful for user: $uid");

      // 사용자 문서 조회
      final userQuery = await db.collection("User").where("uid", isEqualTo: uid).get();
      await db.collection('User')
              .where('uid', isEqualTo: uid)
              .get()
              .then((value) {
                for (var element in value.docs) {
                  udocid = element.id;
                }
      });

      if (userQuery.docs.isNotEmpty) {
        final userDoc = userQuery.docs.first;
        final userData = userDoc.data();
        print("User Data: $userData"); // 디버깅 출력 추가

        if (userData.isNotEmpty) {
          // 사용자가 참여하고 있는 Space ID 목록 조회
          final uentered = await db.collection('User').doc(udocid).collection('entered').get();
          final ueData = uentered.docs.first.data();
          String spaceId = ueData['sid'];
          // List<dynamic> spaceIds = userData['spaces'];
          // print("User spaces: $spaceIds"); // 디버깅 출력 추가

          // Space 문서들 조회
          final spaceDoc = await db.collection("Space").where('sid', isEqualTo: spaceId).get();

          if (spaceDoc.docs.isNotEmpty) {
            final spaceData = spaceDoc.docs.first.data();
            print("Space ID: $spaceId, Data: $spaceData");
          } else {
            print("Space document with ID $spaceId does not exist.");
          }


          // for (var spaceId in spaceIds) {
          //   final spaceDoc = await db.collection("Space").doc(spaceId).get();
          //
          //   if (spaceDoc.exists) {
          //     final spaceData = spaceDoc.data();
          //     print("Space ID: $spaceId, Data: $spaceData");
          //   } else {
          //     print("Space document with ID $spaceId does not exist.");
          //   }
          // }
        } else {
          print("User data is null.");
        }
      } else {
        print("User document does not exist for userId: $uid"); // 디버깅 출력 추가
      }
    } else {
      print("Invalid login credentials for user: $uid");
    }
  } catch (e) {
    print("Error during login process: $e");
  }
}

// 로그인 검증 함수

Future<bool> validateLogin(String uid, String password) async {
  final db = FirebaseFirestore.instance;
  bool isValid = false;

  try {
    final querySnapshot = await db.collection("User")
        .where("uid", isEqualTo: uid)
        .where("pw", isEqualTo: password)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      isValid = true;
    }
  } catch (e) {
    print("Error validating login: $e");
  }

  return isValid;
}
Future<List<String>> getUserSpaces(String userId) async {
  final db = FirebaseFirestore.instance;
  List<String> spaceIds = [];

  try {
    // 사용자 문서 쿼리
    final userQuery = await db.collection("User").where("uid", isEqualTo: userId).get();

    if (userQuery.docs.isNotEmpty) {
      // 첫 번째 문서 가져오기
      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();

      print("User Data: $userData"); // 디버깅 출력 추가

      // 'entered' 필드가 있는지 확인하고 List<String>으로 변환
      if (userData.isNotEmpty && userData.containsKey('entered')) {
        spaceIds = List<String>.from(userData['entered']);
        print("Space IDs: $spaceIds"); // 추가 디버깅 출력
      } else {
        print("'entered' field does not exist or is not a List in user data.");
      }
    } else {
      print("User document does not exist for userId: $userId"); // 디버깅 출력 추가
    }
  } catch (e) {
    print("Error fetching user spaces: $e");
  }

  return spaceIds;
}


Future<String?> getSid(String docid) async {
  final db = FirebaseFirestore.instance;
  String? spaceId;
  print("Fetching space id...");

  try {
    DocumentSnapshot<Map<String, dynamic>> docSnapshot = await db
        .collection('Space')
        .doc(docid)
        .get();

    if (docSnapshot.exists) {
      final sid = docSnapshot.data()?['sid'];
      if (sid != null) {
        //print('cname List:');
        spaceId = sid;
        print(spaceId);

      } else {
        print('sid field is empty or does not exist.');
      }
    } else {
      print('Document does not exist.');
    }
  } catch (e) {
    print('Error fetching space id: $e');
  } finally {
    print('Finished fetching space id.');
  }

  return spaceId;
}

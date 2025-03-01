import 'package:easybudget/constant/color.dart';
import 'package:easybudget/layout/address_layout.dart';
import 'package:easybudget/layout/appbar_layout.dart';
import 'package:easybudget/layout/category_layout.dart';
import 'package:easybudget/layout/default_layout.dart';
import 'package:easybudget/layout/itmes_layout.dart';
import 'package:easybudget/layout/pdate_layout.dart';
import 'package:easybudget/layout/purchased_layout.dart';
import 'package:easybudget/layout/receipt_layout.dart';
import 'package:easybudget/layout/totalcost_layout.dart';
import 'package:easybudget/layout/writer_layout.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ExpenseDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> expense;

  const ExpenseDetailsScreen({Key? key, required this.expense}) : super(key: key);

  Future<List<Map<String, String>>> _fetchItems() async {
    final itemsSnapshot = await FirebaseFirestore.instance
        .collection('Space')
        .doc('KBpkiTfmpsg3ZI5iSpyY')
        .collection('Receipt')
        .doc(expense['id'])
        .collection('Item')
        .get();

    List<Map<String, String>> itemsList = itemsSnapshot.docs.map((doc) {
      final data = doc.data();
      if (data.containsKey('cost')) {
        data['cost'] = NumberFormat('#,##0').format(int.parse(data['cost'].toString()));
      }
      return data.map((key, value) => MapEntry(key, value.toString()));
    }).toList();

    return itemsList;
  }

  Future<Map<String, dynamic>> _fetchUserData(String uid) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    CollectionReference users = firestore.collection('User');
    QuerySnapshot querySnapshot = await users.where('uid', isEqualTo: uid).get();

    if (querySnapshot.docs.isNotEmpty) {
      var userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
      return userData;
    } else {
      throw Exception('User not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime pdate = (expense['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    String formattedPdate = '${pdate.year}-${pdate.month.toString().padLeft(2, '0')}-${pdate.day.toString().padLeft(2, '0')}';

    return DefaultLayout(
      appbar: AppbarLayout(
        title: '상세 영수증 내역 확인',
        back: true,
        action: [],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              ReceiptLayout(
                purchased: PurchasedView(perchased: '${expense['item']}',),
                address: AddressView(address: '${expense['address']}',),
                pdate: PdateView(pdate: formattedPdate,),
                category: CategoryView(category: '${expense['category']}',),
                writer: FutureBuilder<Map<String, dynamic>>(
                  future: _fetchUserData(expense['writer']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData) {
                      return Text('User not found');
                    } else {
                      var userData = snapshot.data!;
                      return WriterView(name: userData['uname'], uid: userData['uid']);
                    }
                  },
                ),
                items: FutureBuilder<List<Map<String, String>>>(
                  future: _fetchItems(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text('No items found.');
                    } else {
                      return ItemsView(items: snapshot.data!);
                    }
                  },
                ),
                totalcost: TotalCostView(totalcost: NumberFormat('#,##0').format(int.parse(expense['cost'].toString()))),
              ),
              /*SizedBox(height: 20,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blueColor,
                      foregroundColor: primaryColor,
                      textStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'NotoSansKR'
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5), // 버튼을 조금 더 각지게 만듦
                      ),
                      padding: EdgeInsets.all(15), // 높이를 5씩 늘림
                    ),
                    child: Text(
                      '사진 확인',
                    ),
                  ),
                ],
              ),*/
            ],
          ),
        ),
      ),
    );
  }
}

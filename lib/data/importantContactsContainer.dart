import 'package:instiapp/importantContacts/classes/contactcard.dart';
import 'package:instiapp/utilities/globalFunctions.dart';
import 'dart:convert';

class ImportantContactsContainer {
  List<ContactCard> contactCards;

  getData() async {
    sheet.getData('Contacts!A:E').listen((data) {
      makeContactList(data);
    });
  }

  makeContactList(List importantContactDataList) {
    importantContactDataList.removeAt(0);
    contactCards = [];
    for (List lc in importantContactDataList) {
      contactCards.add(ContactCard(
          name: lc[0], description: lc[1], contacts: jsonDecode(lc[2])));
    }
  }
}
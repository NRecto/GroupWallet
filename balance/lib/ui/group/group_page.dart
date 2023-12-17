import 'package:balance/core/database/dao/groups_dao.dart';
import 'package:balance/core/database/dao/transactions_dao.dart';
import 'package:balance/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class GroupPage extends StatefulWidget {
  final String groupId;
  const GroupPage(this.groupId, {super.key});

  @override
  State<StatefulWidget> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  late final GroupsDao _groupsDao = getIt.get<GroupsDao>();
  late final TransactionsDao _transactionsDao = getIt.get<TransactionsDao>();

  final _incomeController = TextEditingController();
  final _expenseController = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text("Group details"),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Expanded(
              child: StreamBuilder(
            stream: _groupsDao.watchGroup(widget.groupId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Text("Loading...");
              }
              return Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text(snapshot.data?.name ?? ""),
                  Text(snapshot.data?.balance.toString() ?? ""),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _incomeController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r"[0-9]"))
                        ],
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                          suffixText: "\$",
                        ),
                      ),
                    ),
                    TextButton(
                        onPressed: () {
                          final amount = int.parse(_incomeController.text);
                          final balance = snapshot.data?.balance ?? 0;

                          _transactionsDao.insert(
                              'income', amount, widget.groupId);

                          _groupsDao.adjustBalance(
                              balance + amount, widget.groupId);
                          _incomeController.text = "";
                        },
                        child: Text("Add income")),
                  ]),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expenseController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r"[0-9]"))
                        ],
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                          suffixText: "\$",
                        ),
                      ),
                    ),
                    TextButton(
                        onPressed: () {
                          final amount = int.parse(_expenseController.text);
                          final balance = snapshot.data?.balance ?? 0;

                          _transactionsDao.insert(
                              'expense', amount, widget.groupId);

                          _groupsDao.adjustBalance(
                              balance - amount, widget.groupId);
                          _expenseController.text = "";
                        },
                        child: Text("Add expense")),
                  ]),
                ],
              );
            },
          )),
          Expanded(
            child: StreamBuilder(
              stream: _transactionsDao.watch(widget.groupId),
              builder: (context, snapshot2) {
                if (!snapshot2.hasData) {
                  return Text("Loading...");
                }
                return ListView.builder(
                    itemCount: snapshot2.requireData.length,
                    itemBuilder: (context, index) => ListTile(
                          title: Text(
                            snapshot2.requireData[index].amount.toString(),
                            style: TextStyle(
                              color: snapshot2.requireData[index].type ==
                                      'income'
                                  ? Colors.green
                                  : Colors.red, // Set your desired color here
                              fontWeight: FontWeight
                                  .bold, // Set your desired font weight
                            ),
                          ),
                          subtitle: Text(DateFormat('MMM, dd, yyyy hh:mm a')
                              .format(snapshot2.requireData[index].createdAt)),
                          trailing: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) => _popUpEditor(
                                    context,
                                    snapshot2.requireData[index],
                                    widget.groupId),
                              );
                            },
                          ),
                        ));
              },
            ),
          )
        ]),
      ));
}

Widget _popUpEditor(BuildContext context, data, groupId) {
  late final GroupsDao _groupsDao = getIt.get<GroupsDao>();
  late final TransactionsDao _transactionsDao = getIt.get<TransactionsDao>();

  int balance = 0;
  int oldAmount = data.amount;
  final updateTextController =
      TextEditingController(text: oldAmount.toString());

  return AlertDialog(
    title: const Text('Edit'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StreamBuilder(
          stream: _groupsDao.watchGroup(groupId),
          builder: (context, snapshot3) {
            if (!snapshot3.hasData) {
              return Text("Loading...");
            }
            balance = snapshot3.data?.balance ?? 0;
            return TextFormField(
              controller: updateTextController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r"[0-9]"))
              ],
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                suffixText: "\$",
              ),
            );
          },
        ),
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () {
          final amount = int.parse(updateTextController.text);
          final newBalance = data.type == 'income'
              ? balance - oldAmount + amount
              : balance + oldAmount - amount;
          _transactionsDao.updateTransaction(data.id, amount);
          _groupsDao.adjustBalance(newBalance, groupId);

          Navigator.of(context).pop();
        },
        child: Text(
          "Submit",
          style: TextStyle(color: Colors.blue),
        ),
      ),
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: Text(
          "Cancel",
          style: TextStyle(color: Colors.black),
        ),
      ),
    ],
  );
}

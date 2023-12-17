import 'package:balance/core/database/database.dart';
import 'package:balance/core/database/tables/transactions.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

part 'transactions_dao.g.dart';

@lazySingleton
@DriftAccessor(tables: [Transactions])
class TransactionsDao extends DatabaseAccessor<Database>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.db);

  Future insert(String type, int amount, String groupId) {
    try {
      return into(transactions).insert(TransactionsCompanion.insert(
          id: const Uuid().v1(),
          createdAt: DateTime.now(),
          amount: Value(amount),
          type: type,
          groupId: groupId));
    } catch (e) {
      throw FormatException(e.toString());
    }
  }

  Future updateTransaction(
    String id,
    int amount,
  ) {
    try {
      return (update(transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          amount: Value(amount),
        ),
      );
    } catch (e) {
      throw FormatException(e.toString());
    }
  }

  Stream<List<Transaction>> watch(String groupId) => (select(transactions)
        ..where((t) => t.groupId.equals(groupId))
        ..orderBy([
          (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)
        ]))
      .watch();
}

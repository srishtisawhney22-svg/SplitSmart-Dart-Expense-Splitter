import 'dart:io';
class Expense {
  final String title;
  final int amount;
  final String paidBy;
  final String category;
  final List<String> participants;
  Expense({
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.category,
    required this.participants,
  });
  int get sharePerPerson => amount ~/ participants.length;
  @override
  String toString() {
    return '$title | INR $amount | Paid by: $paidBy | Category: $category | '
        'Participants: ${participants.join(', ')} | Share each: INR $sharePerPerson';
  }
}
class ExpenseGroup {
  // Keys are lowercase so names are unique even if capitalization differs.
  final Map<String, String> _members = {};
  final List<Expense> _expenses = [];
  List<String> get members => _members.values.toList();
  String _memberName(String name) {
    final cleaned = name.trim();
    return _members[cleaned.toLowerCase()] ?? '';
  }
  void addMember(String name) {
    final cleaned = name.trim();
    if (cleaned.isEmpty) {
      throw ArgumentError('Member name cannot be empty.');
    }
    if (_members.containsKey(cleaned.toLowerCase())) {
      throw ArgumentError('A member named "$cleaned" already exists.');
    }
    _members[cleaned.toLowerCase()] = cleaned;
    print('Member "$cleaned" added successfully.');
  }
  void addExpense({
    required String title,
    required int amount,
    required String paidBy,
    required String category,
    required List<String> splitBetween,
  }) {
    final cleanTitle = title.trim();
    final cleanCategory = category.trim();
    final payer = _memberName(paidBy);
    if (cleanTitle.isEmpty) {
      throw ArgumentError('Expense title cannot be empty.');
    }
    if (amount <= 0) {
      throw ArgumentError('Amount must be a positive whole-rupee value.');
    }
    if (cleanCategory.isEmpty) {
      throw ArgumentError('Category cannot be empty.');
    }
    if (payer.isEmpty) {
      throw ArgumentError('Unknown payer "$paidBy". Add the member first.');
    }
    if (splitBetween.isEmpty ||
        splitBetween.every((name) => name.trim().isEmpty)) {
      throw ArgumentError('Participant list cannot be empty.');
    }
    final cleanedParticipants = <String>[];
    final seen = <String>{};
    for (final rawName in splitBetween) {
      final name = rawName.trim();
      if (name.isEmpty) continue;
      final key = name.toLowerCase();
      if (seen.contains(key)) {
        throw ArgumentError('Participant "$name" is listed more than once.');
      }
      seen.add(key);
      final actualName = _memberName(name);
      if (actualName.isEmpty) {
        throw ArgumentError('Unknown participant "$name". Add the member first.');
      }
      cleanedParticipants.add(actualName);
    }
    if (cleanedParticipants.isEmpty) {
      throw ArgumentError('At least one participant is required.');
    }
    // The assignment's basic version uses whole-rupee equal splits.
    if (amount % cleanedParticipants.length != 0) {
      throw ArgumentError(
        'INR $amount cannot be split into equal whole rupees among '
        '${cleanedParticipants.length} participants. Change the amount '
        'or participant list.',
      );
    }
    _expenses.add(Expense(
      title: cleanTitle,
      amount: amount,
      paidBy: payer,
      category: cleanCategory,
      participants: cleanedParticipants,
    ));
    print('Expense "$cleanTitle" recorded successfully.');
  }
  void listExpenses() {
    if (_expenses.isEmpty) {
      print('No expenses have been recorded yet.');
      return;
    }
    print('\n--- All Expenses ---');
    for (var i = 0; i < _expenses.length; i++) {
      print('${i + 1}. ${_expenses[i]}');
    }
  }
  void filterByMember(String name) {
    final actualName = _memberName(name);
    if (actualName.isEmpty) {
      print('Unknown member "$name".');
      return;
    }
    final matching = _expenses.where((expense) =>
        expense.paidBy.toLowerCase() == actualName.toLowerCase() ||
        expense.participants.any(
          (person) => person.toLowerCase() == actualName.toLowerCase(),
        )).toList();
    print('\n--- Expenses involving $actualName ---');
    if (matching.isEmpty) {
      print('No expenses found for $actualName.');
      return;
    }
    for (final expense in matching) {
      print(expense);
    }
  }
  void filterByCategory(String category) {
    final cleaned = category.trim();
    if (cleaned.isEmpty) {
      print('Category cannot be empty.');
      return;
    }
    final matching = _expenses.where((expense) =>
        expense.category.toLowerCase() == cleaned.toLowerCase()).toList();
    print('\n--- Expenses in category "$cleaned" ---');
    if (matching.isEmpty) {
      print('No expenses found in this category.');
      return;
    }
    for (final expense in matching) {
      print(expense);
    }
  }
  void printBalances() {
    if (_members.isEmpty) {
      print('Add group members first.');
      return;
    }
    final paid = <String, int>{};
    final owed = <String, int>{};
    for (final member in members) {
      paid[member] = 0;
      owed[member] = 0;
    }
    for (final expense in _expenses) {
      paid[expense.paidBy] = (paid[expense.paidBy] ?? 0) + expense.amount;
      final share = expense.sharePerPerson;
      for (final participant in expense.participants) {
        owed[participant] = (owed[participant] ?? 0) + share;
      }
    }
    print('\n--- Member Balances ---');
    print('Net balance = Total paid - Total share owed.');
   print('Positive means the member should receive money; negative means they owe money.');
    for (final member in members) {
      final totalPaid = paid[member] ?? 0;
      final totalOwed = owed[member] ?? 0;
      final net = totalPaid - totalOwed;
      String status;
      if (net > 0) {
        status = 'should receive INR $net';
      } else if (net < 0) {
        status = 'owes INR ${net.abs()}';
      } else {
        status = 'is settled';
      }
      print('$member: Paid INR $totalPaid | Share owed INR $totalOwed '
          '| Net INR $net ($status)');
    }
  }
}
String readText(String prompt) {
  stdout.write(prompt);
  return stdin.readLineSync() ?? '';
}
int readAmount(String prompt) {
  final text = readText(prompt).trim();
  final amount = int.tryParse(text);
  if (amount == null || amount <= 0) {
    throw FormatException('Enter a positive whole number, for example 900.');
  }
  return amount;
}
void main() {
  final group = ExpenseGroup();
  print('================================');
  print('       SplitSmart');
  print('     Dart Expense Splitter');
  print('================================');
  while (true) {
    print('\nChoose an option:');
    print('1. Add group member');
    print('2. Record an expense');
    print('3. List all expenses');
    print('4. Filter expenses by member');
    print('5. Filter expenses by category');
    print('6. Show member balances');
    print('7. Exit');
    final choice = readText('Enter choice (1-7): ').trim();
    try {
      switch (choice) {
        case '1':
          final name = readText('Enter member name: ');
          group.addMember(name);
          break;
        case '2':
          final title = readText('Expense title: ');
          final amount = readAmount('Amount in INR (whole rupees): ');
          final payer = readText('Who paid? Enter member name: ');
          final category = readText('Category (Food, Travel, etc.): ');
          final participantText = readText(
            'Participants (separate names with commas): ',
          );
          final participants = participantText.split(',');
          group.addExpense(
            title: title,
            amount: amount,
            paidBy: payer,
            category: category,
            splitBetween: participants,
          );
          break;
        case '3':
          group.listExpenses();
          break;
        case '4':
          final name = readText('Enter member name to filter: ');
          group.filterByMember(name);
          break;
        case '5':
          final category = readText('Enter category to filter: ');
          group.filterByCategory(category);
          break;
        case '6':
          group.printBalances();
          break;
        case '7':
          print('Thank you for using SplitSmart. Goodbye!');
          return;
        default:
          print('Invalid choice. Please enter a number from 1 to 7.');
      }
    } on ArgumentError catch (error) {
      print('Error: ${error.message}');
    } on FormatException catch (error) {
      print('Invalid input: ${error.message}');
    } catch (error) {
      print('Something went wrong: $error');
    }
  }
}
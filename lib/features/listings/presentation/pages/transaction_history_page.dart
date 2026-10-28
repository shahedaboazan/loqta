import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loqta/core/localization/app_localizations.dart';
import 'package:loqta/core/widgets/loqta_app_bar.dart';
import 'package:loqta/features/listings/domain/repositories/transaction_repository.dart';
import 'package:loqta/features/listings/presentation/bloc/transaction_bloc.dart';

class TransactionHistoryPage extends StatelessWidget {
  const TransactionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TransactionBloc(context.read<TransactionRepository>())..add(LoadTransactions()),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(context.l10n.transactionHistory),
            bottom: TabBar(
              tabs: [
                Tab(text: "Incoming"), // Placeholder
                Tab(text: context.l10n.active),
                Tab(text: context.l10n.history),
              ],
            ),
          ),
          body: BlocBuilder<TransactionBloc, TransactionState>(
            builder: (context, state) {
              if (state is TransactionLoading) return const Center(child: CircularProgressIndicator());
              if (state is TransactionLoaded) {
                return TabBarView(
                  children: [
                    ListView(children: state.incoming.map((r) => ListTile(title: Text(r.id))).toList()),
                    ListView(children: state.active.map((t) => ListTile(title: Text(t.id))).toList()),
                    ListView(children: state.history.map((t) => ListTile(title: Text(t.id))).toList()),
                  ],
                );
              }
              return const Center(child: Text("Error"));
            },
          ),
        ),
      ),
    );
  }
}

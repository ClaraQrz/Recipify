import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import '../features/receitas/receitas_notifier.dart';
import '../features/compras/compras_notifier.dart';
import '../features/estoque/estoque_notifier.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ReceitasNotifier()),
        ChangeNotifierProvider(create: (_) => ComprasNotifier()),
        ChangeNotifierProvider(create: (_) => EstoqueNotifier()),
      ],
      child: MaterialApp.router(
        title: 'Minha Cozinha',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
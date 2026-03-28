import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'router.dart';
import '../features/receitas/receitas_notifier.dart';
import '../features/estoque/estoque_notifier.dart';
import '../features/compras/compras_notifier.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

@override
Widget build(BuildContext context) {
  return MultiProvider(
    provider: [
      ChangeNotifierProvider(create: (_) => ReceitasNotifier()),
      ChangeNotifierProvider(create: (_) => EstoqueNotifier()),
      ChangeNotifierProvider(create: (_) => ComprasNotifier()),
    ],
    child: MaterialApp.router(
      title: 'Cook Well',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 253, 245, 128)),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    ),
  );
}
}
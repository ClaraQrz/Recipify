import 'package:flutter/material.dart';

class Receita {
  final String id;
  final String nome;
  final String ingredientes;
  Receita({required this.id, required this.nome, required this.ingredientes});
}

class ReceitasNotifier extends ChangeNotifier {
  final List<Receita> _receitas = [];
  List<Receita> get receitas => List.unmodifiable(_receitas);

  void adicionar(Receita r) {
    _receitas.add(r);
    notifyListeners();
  }
}
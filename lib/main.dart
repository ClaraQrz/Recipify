import 'package:flutter/material.dart';

void main() {
  runApp(const RecipifyApp());
}

class RecipifyApp extends StatelessWidget {
  const RecipifyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recipify',
      theme: ThemeData(
        primaryColor: const Color(0xFFC84B2F),
        scaffoldBackgroundColor: const Color(0xFFFAF7F4),
        fontFamily: 'DM Sans',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFC84B2F)),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;
  final List<Widget> screens = const [
    HomeScreen(),
    RecipesScreen(),
    ListsScreen(),
    StockScreen(),
    ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white54,
        backgroundColor: const Color(0xFF1A1410),
        type: BottomNavigationBarType.fixed,
        onTap: (value) {
          setState(() {
            currentIndex = value;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Receitas',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Listas'),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Estoque',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFC84B2F), Color(0xFF8B2E18)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Recipify',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Suas receitas, organizadas.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'E-mail',
                          filled: true,
                          fillColor: const Color(0xFFFAF7F4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Senha',
                          filled: true,
                          fillColor: const Color(0xFFFAF7F4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC84B2F),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MainNavigation(),
                              ),
                            );
                          },
                          child: const Text(
                            'Entrar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeaderWidget(),
            const SizedBox(height: 20),
            const Text('Top da semana', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFC84B2F),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Text('🍝', style: TextStyle(fontSize: 40)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nhoque ao sugo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '45 min · 4 porções',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Rápidas para hoje',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  MiniRecipeCard(
                    icon: '🥗',
                    title: 'Salada Caesar',
                    time: '15 min',
                  ),
                  MiniRecipeCard(icon: '🍳', title: 'Omelete', time: '10 min'),
                  MiniRecipeCard(icon: '🥣', title: 'Açaí Bowl', time: '8 min'),
                  MiniRecipeCard(
                    icon: '🌯',
                    title: 'Wrap frango',
                    time: '20 min',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final recipes = [
      {'emoji': '🍝', 'name': 'Nhoque ao sugo'},
      {'emoji': '🥘', 'name': 'Feijão tropeiro'},
      {'emoji': '🍰', 'name': 'Bolo de cenoura'},
      {'emoji': '🥗', 'name': 'Salada Caesar'},
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const HeaderWidget(),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar receita...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: recipes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          recipe['emoji']!,
                          style: const TextStyle(fontSize: 42),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          recipe['name']!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});
  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  final List<Map<String, dynamic>> items = [
    {'name': 'Tomate', 'done': true},
    {'name': 'Cebola', 'done': false},
    {'name': 'Alho', 'done': false},
    {'name': 'Macarrão', 'done': false},
  ];
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeaderWidget(),
            const SizedBox(height: 20),
            const Text(
              'Compras da semana',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return CheckboxListTile(
                    value: items[index]['done'],
                    activeColor: const Color(0xFFC84B2F),
                    title: Text(items[index]['name']),
                    onChanged: (value) {
                      setState(() {
                        items[index]['done'] = value;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final stock = [
      {'emoji': '🥛', 'name': 'Leite', 'qty': '1L'},
      {'emoji': '🧀', 'name': 'Queijo', 'qty': '300g'},
      {'emoji': '🫘', 'name': 'Feijão', 'qty': '1kg'},
      {'emoji': '🫙', 'name': 'Arroz', 'qty': '2kg'},
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeaderWidget(),
            const SizedBox(height: 20),
            const Text(
              'Estoque',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                itemCount: stock.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final item = stock[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['emoji']!,
                          style: const TextStyle(fontSize: 40),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item['name']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(item['qty']!),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: const BoxDecoration(color: Color(0xFFC84B2F)),
            child: const Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white24,
                  child: Text(
                    'MG',
                    style: TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Maria Gonzalez',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'maria@email.com',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: const [
                ProfileTile(icon: Icons.notifications, label: 'Notificações'),
                ProfileTile(icon: Icons.dark_mode, label: 'Tema'),
                ProfileTile(icon: Icons.people, label: 'Compartilhar conta'),
                ProfileTile(icon: Icons.star, label: 'Avaliar app'),
                ProfileTile(icon: Icons.logout, label: 'Sair'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          'Recipify',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        Icon(Icons.favorite_border),
      ],
    );
  }
}

class MiniRecipeCard extends StatelessWidget {
  final String icon;
  final String title;
  final String time;
  const MiniRecipeCard({
    super.key,
    required this.icon,
    required this.title,
    required this.time,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 34)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(time),
        ],
      ),
    );
  }
}

class ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const ProfileTile({super.key, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFF5EDE9),
        child: Icon(icon, color: const Color(0xFFC84B2F)),
      ),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

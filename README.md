# 🍽️ Recipify

Aplicativo mobile de gerenciamento de receitas, listas de compras e estoque doméstico, desenvolvido com **Flutter** e integrado ao **Supabase** (dados remotos) e **SQLite** (dados locais).

---

## 📱 Funcionalidades

| Módulo | Descrição |
|---|---|
| **Autenticação** | Cadastro e login com senha hasheada (SHA-256) |
| **Home** | Painel com top receitas da semana, favoritos e itens próximos do vencimento |
| **Receitas** | Feed com busca, filtro por categoria, favoritos e publicação de novas receitas |
| **Listas de Compras** | Criação e gerenciamento de listas, com itens, swipe para deletar e lista favorita |
| **Estoque** | Controle de ingredientes disponíveis em casa *(em desenvolvimento)* |
| **Perfil** | Foto de perfil, estatísticas do usuário e logout |

---

## 🏗️ Arquitetura

O projeto adota uma arquitetura em camadas, separando responsabilidades de forma clara:

```
lib/
├── core/
│   └── theme/              # Tema centralizado do app (AppTheme)
├── features/               # Telas organizadas por funcionalidade
│   ├── auth/
│   ├── home/
│   ├── receitas/
│   ├── listas/
│   ├── estoque/
│   ├── perfil/
│   └── splash/
├── repositories/           # Acesso a dados (Supabase e SQLite)
│   ├── receita_repository.dart
│   ├── lista_repository.dart
│   ├── estoque_repository.dart
│   └── ingrediente_repository.dart
├── services/               # Serviços de infraestrutura
│   ├── auth_service.dart
│   ├── database_service.dart
│   └── supabase_service.dart
└── main.dart
```

### Estratégia de dados híbrida

Uma decisão central do projeto é a separação entre dados remotos e locais:

- **Supabase (remoto)** — receitas e perfis de usuários, que são compartilhados entre dispositivos e usuários diferentes.
- **SQLite (local)** — listas de compras e estoque, que são dados pessoais e precisam funcionar mesmo sem conexão com a internet.

---

## 🛠️ Tecnologias

- [Flutter](https://flutter.dev/) `SDK ^3.11.4`
- [Supabase Flutter](https://pub.dev/packages/supabase_flutter) `^2.12.4` — backend remoto (banco de dados, storage)
- [sqflite](https://pub.dev/packages/sqflite) `^2.4.2` — banco de dados local SQLite
- [crypto](https://pub.dev/packages/crypto) `^3.0.7` — hash SHA-256 de senhas
- [image_picker](https://pub.dev/packages/image_picker) `^1.2.2` — seleção de imagens da galeria/câmera
- [shared_preferences](https://pub.dev/packages/shared_preferences) `^2.3.2` — persistência de preferências locais

---

## 🚀 Como executar

### Pré-requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) instalado e configurado
- Conta e projeto criados no [Supabase](https://supabase.com/)
- Dispositivo físico ou emulador configurado

### Passos

1. Clone o repositório:
   ```bash
   git clone https://github.com/seu-usuario/recipify.git
   cd recipify
   ```

2. Instale as dependências:
   ```bash
   flutter pub get
   ```

3. Configure as credenciais do Supabase em `lib/main.dart`:
   ```dart
   await Supabase.initialize(
     url: 'SUA_SUPABASE_URL',
     anonKey: 'SUA_SUPABASE_ANON_KEY',
   );
   ```

4. Execute o app:
   ```bash
   flutter run
   ```

---

## 🗄️ Estrutura do banco de dados

### Supabase (remoto)

| Tabela | Descrição |
|---|---|
| `usuario` | Dados de perfil e credenciais dos usuários |
| `receita` | Receitas publicadas, com título, descrição, categoria e imagem |

### SQLite (local)

| Tabela | Descrição |
|---|---|
| `listas` | Listas de compras do usuário |
| `itens_lista` | Itens pertencentes a cada lista |
| `estoque` | Ingredientes disponíveis no estoque doméstico |

---

## 👥 Equipe

Alunas de Ciência da Computação: Ana Clara e Daniela Gomes.

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

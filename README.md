# 🚀 Flutter TanStack Query

<p align="center">
  <img src="https://raw.githubusercontent.com/Haraprosad/flutter_tanstack_query/refs/heads/main/assets/icons/flutter_tanstack_query_icon.png" alt="Flutter TanStack Query Logo" width="100" height="100">
</p>

<p align="center">
  <a href="https://pub.dev/packages/flutter_tanstack_query"><img src="https://img.shields.io/pub/v/flutter_tanstack_query.svg" alt="pub package"></a>
  <a href="https://pub.dev/packages/flutter_tanstack_query"><img src="https://img.shields.io/pub/points/flutter_tanstack_query" alt="pub points"></a>
  <a href="https://pub.dev/packages/flutter_tanstack_query"><img src="https://img.shields.io/pub/popularity/flutter_tanstack_query" alt="popularity"></a>
  <a href="https://pub.dev/packages/flutter_tanstack_query"><img src="https://img.shields.io/pub/likes/flutter_tanstack_query" alt="likes"></a>
</p>

<p align="center">
  <strong>A powerful, feature-rich data fetching and state management package for Flutter</strong>
</p>

<p align="center">
  <em>Inspired by TanStack Query (React Query) • Built with clean architecture principles</em>
</p>

A powerful, feature-rich data fetching and state management package for Flutter, inspired by **TanStack Query (React Query)**. Built with clean architecture principles, it provides automatic caching, background updates, offline support, and optimistic UI updates out of the box.

## ✨ Why Flutter TanStack Query?

- 🎯 **Zero Boilerplate**: Write less code, get more functionality
- 🚀 **Performance First**: Intelligent caching and background updates
- 📱 **Mobile Optimized**: Built specifically for Flutter apps
- 🔄 **Real-time Sync**: Automatic synchronization when app comes online
- 🧪 **Battle Tested**: Based on the proven TanStack Query architecture
- 🎨 **Developer Friendly**: Intuitive API with excellent error handling

## 📦 Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_tanstack_query: ^0.0.1
  connectivity_plus: ^6.1.4  # For network status monitoring
  hive: ^2.2.3               # For persistent caching
  hive_flutter: ^1.1.0       # Flutter integration for Hive
```

Then run:

```bash
flutter pub get
```

## 🏁 Quick Start

### Step 1: Initialize the Package

```dart
import 'package:flutter/material.dart';
import 'package:flutter_tanstack_query/flutter_tanstack_query.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize cache and network monitoring
  await QueryCache.instance.initialize();
  await NetworkPolicy.instance.initialize();
  AppLifecycleManager.instance.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final queryClient = QueryClient(
      cache: QueryCache.instance,
      networkPolicy: NetworkPolicy.instance,
    );

    return QueryClientProvider(
      client: queryClient,
      child: MaterialApp(
        title: 'My App',
        home: HomeScreen(),
      ),
    );
  }
}
```

### Step 2: Define Your Data Models

```dart
class User {
  final int id;
  final String name;
  final String email;
  final String avatar;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
    };
  }
}
```

### Step 3: Create Your API Service

```dart
class ApiService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  static Future<List<User>> fetchUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    }
    throw Exception('Failed to load users');
  }

  static Future<User> createUser(CreateUserRequest request) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );
    
    if (response.statusCode == 201) {
      return User.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create user');
  }
}
```

## 🎯 Core Features

### 1. 📊 Queries - Fetching Data

Queries are perfect for **GET** operations. They automatically handle caching, background updates, and error states.

```dart
class UserListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Users')),
      body: UseQuery<List<User>>(
        options: QueryOptions<List<User>>(
          queryKey: ['users'],
          queryFn: () => ApiService.fetchUsers(),
          staleTime: Duration(minutes: 5),  // Data stays fresh for 5 minutes
          cacheTime: Duration(minutes: 30), // Cache persists for 30 minutes
          refetchOnWindowFocus: true,       // Refetch when app becomes active
          refetchOnReconnect: true,         // Refetch when internet reconnects
        ),
        builder: (context, result) {
          // Loading state
          if (result.isLoading && !result.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          
          // Error state
          if (result.isError && !result.hasData) {
            return ErrorWidget(
              error: result.error.toString(),
              onRetry: result.refetch,
            );
          }
          
          // Success state with pull-to-refresh
          return RefreshIndicator(
            onRefresh: result.refetch,
            child: ListView.builder(
              itemCount: result.data?.length ?? 0,
              itemBuilder: (context, index) {
                final user = result.data![index];
                return UserCard(user: user);
              },
            ),
          );
        },
      ),
    );
  }
}
```

### 2. 🔄 Mutations - Updating Data

Mutations handle **POST**, **PUT**, **DELETE** operations with optimistic updates and automatic error handling.

```dart
class CreateUserScreen extends StatefulWidget {
  @override
  _CreateUserScreenState createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create User')),
      body: UseMutation<User, CreateUserRequest>(
        options: MutationOptions<User, CreateUserRequest>(
          mutationFn: (request) => ApiService.createUser(request),
          
          // Optimistic update - instantly show the new user
          optimisticUpdate: (variables, previousData) {
            final tempUser = User(
              id: -1, // Temporary ID
              name: variables.name,
              email: variables.email,
              avatar: '',
            );
            return previousData != null ? [...previousData, tempUser] : [tempUser];
          },
          
          // Success callback
          onSuccess: (user, variables) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('User ${user.name} created!')),
            );
            Navigator.pop(context);
          },
          
          // Error callback
          onError: (error, variables) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to create user: $error'),
                backgroundColor: Colors.red,
              ),
            );
          },
          
          // Invalidate queries after successful mutation
          invalidateQueries: [['users']], // Refetch user list
        ),
        builder: (context, mutation) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Please enter a name';
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Please enter an email';
                      return null;
                    },
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: mutation.isLoading
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              mutation.mutate(
                                CreateUserRequest(
                                  name: _nameController.text,
                                  email: _emailController.text,
                                ),
                              );
                            }
                          },
                    child: mutation.isLoading
                        ? CircularProgressIndicator()
                        : Text('Create User'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

### 3. 📄 Infinite Queries - Pagination Made Easy

Perfect for implementing pagination, load-more functionality, and infinite scrolling.

```dart
class InfiniteUserListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Infinite User List')),
      body: UseInfiniteQuery<List<User>, int>(
        options: InfiniteQueryOptions<List<User>, int>(
          queryKey: ['users', 'infinite'],
          queryFn: ({pageParam = 1}) => ApiService.fetchUsers(page: pageParam),
          getNextPageParam: (lastPage, allPages) {
            // Return next page number or null if no more pages
            return lastPage.length == 10 ? allPages.length + 1 : null;
          },
          staleTime: Duration(minutes: 5),
        ),
        builder: (context, result) {
          if (result.isLoading && !result.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          if (result.isError && !result.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${result.error}'),
                  ElevatedButton(
                    onPressed: result.refetch,
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final allUsers = result.flatData; // All users from all pages

          return ListView.builder(
            itemCount: allUsers.length + (result.hasNextPage ? 1 : 0),
            itemBuilder: (context, index) {
              // Show users
              if (index < allUsers.length) {
                return UserCard(user: allUsers[index]);
              }
              
              // Show load more button
              return Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: result.isFetchingNextPage
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: result.fetchNextPage,
                          child: Text('Load More'),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

## 🛠️ Advanced Configuration

### Global Configuration

Configure default behavior for all queries:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final queryClient = QueryClient(
      cache: QueryCache.instance,
      networkPolicy: NetworkPolicy.instance,
      defaultQueryConfig: QueryConfig(
        staleTime: Duration(minutes: 5),
        cacheTime: Duration(hours: 1),
        retryCount: 3,
        retryDelay: Duration(seconds: 2),
        refetchOnWindowFocus: true,
        refetchOnReconnect: true,
      ),
    );

    return QueryClientProvider(
      client: queryClient,
      child: MaterialApp(home: HomeScreen()),
    );
  }
}
```

### Query-Specific Configuration

Override default settings for specific queries:

```dart
UseQuery<User>(
  options: QueryOptions<User>(
    queryKey: ['user', userId],
    queryFn: () => ApiService.fetchUser(userId),
    
    // Custom configuration
    enabled: userId != null,              // Only run when userId is available
    staleTime: Duration(minutes: 10),     // Custom stale time
    retryCount: 5,                        // More retries for critical data
    retryDelay: Duration(seconds: 1),     // Faster retry
    
    // Conditional fetching
    queryFn: () {
      if (userId == null) throw Exception('User ID required');
      return ApiService.fetchUser(userId!);
    },
  ),
  builder: (context, result) {
    // Your UI logic
  },
)
```

## 🔧 State Management Patterns

### Manual Query Control

Sometimes you need manual control over queries:

```dart
class UserProfileScreen extends StatefulWidget {
  final int userId;
  
  UserProfileScreen({required this.userId});
  
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late QueryClient queryClient;
  
  @override
  void initState() {
    super.initState();
    queryClient = QueryClientProvider.of(context);
  }
  
  void refreshUserData() {
    // Manually invalidate and refetch specific query
    queryClient.invalidateQueries(['user', widget.userId]);
  }
  
  void setUserDataOptimistically(User newUserData) {
    // Manually set query data
    queryClient.setQueryData(['user', widget.userId], newUserData);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: refreshUserData,
          ),
        ],
      ),
      body: UseQuery<User>(
        options: QueryOptions<User>(
          queryKey: ['user', widget.userId],
          queryFn: () => ApiService.fetchUser(widget.userId),
        ),
        builder: (context, result) {
          if (result.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          return UserProfileWidget(
            user: result.data!,
            onUpdate: setUserDataOptimistically,
          );
        },
      ),
    );
  }
}
```

### Dependent Queries

Execute queries that depend on other queries:

```dart
class UserPostsScreen extends StatelessWidget {
  final int userId;
  
  UserPostsScreen({required this.userId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // First query - fetch user
          UseQuery<User>(
            options: QueryOptions<User>(
              queryKey: ['user', userId],
              queryFn: () => ApiService.fetchUser(userId),
            ),
            builder: (context, userResult) {
              if (userResult.isLoading) return CircularProgressIndicator();
              if (userResult.isError) return Text('Error loading user');
              
              return Column(
                children: [
                  UserHeader(user: userResult.data!),
                  
                  // Second query - depends on first query's success
                  UseQuery<List<Post>>(
                    options: QueryOptions<List<Post>>(
                      queryKey: ['posts', userId],
                      queryFn: () => ApiService.fetchUserPosts(userId),
                      enabled: userResult.isSuccess, // Only run after user loads
                    ),
                    builder: (context, postsResult) {
                      if (postsResult.isLoading) return CircularProgressIndicator();
                      if (postsResult.isError) return Text('Error loading posts');
                      
                      return PostsList(posts: postsResult.data!);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
```

## 🌐 Offline Support & Sync

The package automatically handles offline scenarios:

```dart
// Your queries automatically work offline with cached data
UseQuery<List<User>>(
  options: QueryOptions<List<User>>(
    queryKey: ['users'],
    queryFn: () => ApiService.fetchUsers(),
    
    // Configure offline behavior
    staleTime: Duration(hours: 24),     // Consider data fresh for 24 hours offline
    cacheTime: Duration(days: 7),       // Keep cached data for a week
    refetchOnReconnect: true,           // Auto-sync when back online
  ),
  builder: (context, result) {
    return Column(
      children: [
        // Show connection status
        if (result.isStale)
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.orange,
            child: Text('Showing cached data - will update when online'),
          ),
        
        // Your normal UI
        if (result.hasData)
          UserList(users: result.data!),
      ],
    );
  },
)
```

## 🎨 Custom Widgets & Utilities

### Error Widget

Create reusable error handling:

```dart
class QueryErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  
  const QueryErrorWidget({
    Key? key,
    required this.error,
    this.onRetry,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Oops! Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (onRetry != null) ...[
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }
}
```

### Loading Widget

Create consistent loading states:

```dart
class QueryLoadingWidget extends StatelessWidget {
  final String? message;
  
  const QueryLoadingWidget({Key? key, this.message}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          if (message != null) ...[
            SizedBox(height: 16),
            Text(message!),
          ],
        ],
      ),
    );
  }
}
```

## 📚 Best Practices

### 1. Query Key Patterns

Use consistent query key patterns:

```dart
// ✅ Good - Hierarchical and descriptive
['users']                           // All users
['users', userId]                   // Specific user
['users', userId, 'posts']          // User's posts
['users', 'search', searchTerm]     // User search results

// ❌ Avoid - Inconsistent patterns
['userList']
['fetchUser', userId]
['posts_for_user_' + userId.toString()]
```

### 2. Error Handling

Implement comprehensive error handling:

```dart
UseQuery<List<User>>(
  options: QueryOptions<List<User>>(
    queryKey: ['users'],
    queryFn: () async {
      try {
        return await ApiService.fetchUsers();
      } on SocketException {
        throw QueryError('No internet connection');
      } on HttpException catch (e) {
        throw QueryError('Server error: ${e.message}');
      } catch (e) {
        throw QueryError('Unknown error occurred');
      }
    },
  ),
  builder: (context, result) {
    if (result.isError) {
      final error = result.error;
      if (error is QueryError) {
        return QueryErrorWidget(
          error: error.message,
          onRetry: result.refetch,
        );
      }
    }
    
    // ... rest of your UI
  },
)
```

### 3. Performance Optimization

Optimize for better performance:

```dart
// Use appropriate stale and cache times
UseQuery<List<User>>(
  options: QueryOptions<List<User>>(
    queryKey: ['users'],
    queryFn: () => ApiService.fetchUsers(),
    
    // Frequently changing data - short stale time
    staleTime: Duration(minutes: 1),
    
    // Rarely changing data - long stale time
    staleTime: Duration(hours: 24),
    
    // Critical data - no caching
    staleTime: Duration.zero,
    cacheTime: Duration.zero,
  ),
  builder: (context, result) => UserList(users: result.data),
)
```

## 🧪 Testing

Testing widgets that use Flutter TanStack Query:

```dart
void main() {
  group('UserListScreen Tests', () {
    late MockApiService mockApiService;
    late QueryClient queryClient;
    
    setUp(() async {
      mockApiService = MockApiService();
      await QueryCache.instance.initialize();
      await NetworkPolicy.instance.initialize();
      
      queryClient = QueryClient(
        cache: QueryCache.instance,
        networkPolicy: NetworkPolicy.instance,
      );
    });
    
    testWidgets('displays users when loaded successfully', (tester) async {
      // Arrange
      final users = [
        User(id: 1, name: 'John', email: 'john@example.com', avatar: ''),
        User(id: 2, name: 'Jane', email: 'jane@example.com', avatar: ''),
      ];
      when(() => mockApiService.fetchUsers()).thenAnswer((_) async => users);
      
      // Act
      await tester.pumpWidget(
        QueryClientProvider(
          client: queryClient,
          child: MaterialApp(home: UserListScreen()),
        ),
      );
      
      // Wait for the query to complete
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('John'), findsOneWidget);
      expect(find.text('Jane'), findsOneWidget);
    });
    
    testWidgets('displays error when fetch fails', (tester) async {
      // Arrange
      when(() => mockApiService.fetchUsers())
          .thenThrow(Exception('Network error'));
      
      // Act
      await tester.pumpWidget(
        QueryClientProvider(
          client: queryClient,
          child: MaterialApp(home: UserListScreen()),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Error'), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
    });
  });
}
```

## 🏗️ Clean Architecture Integration

Flutter TanStack Query works seamlessly with clean architecture and popular state management solutions. Here's how to combine them effectively:

### 🧊 With Flutter BLoC

Perfect for separating business logic while leveraging TanStack Query for data fetching.

#### **Project Structure:**

```text
lib/
├── core/
│   ├── error/
│   │   └── failures.dart
│   └── usecases/
│       └── usecase.dart
├── data/
│   ├── datasources/
│   │   ├── user_remote_datasource.dart
│   │   └── user_local_datasource.dart
│   ├── models/
│   │   └── user_model.dart
│   └── repositories/
│       └── user_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── user.dart
│   ├── repositories/
│   │   └── user_repository.dart
│   └── usecases/
│       ├── get_users.dart
│       └── create_user.dart
└── presentation/
    ├── bloc/
    │   └── user_form_bloc.dart
    ├── pages/
    │   └── user_page.dart
    └── widgets/
        └── user_list_widget.dart
```

#### **Domain Layer:**

```dart
// domain/entities/user.dart
class User extends Equatable {
  final int id;
  final String name;
  final String email;
  final String avatar;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
  });

  @override
  List<Object> get props => [id, name, email, avatar];
}

// domain/repositories/user_repository.dart
abstract class UserRepository {
  Future<List<User>> getUsers();
  Future<User> createUser(String name, String email);
  Future<User> updateUser(int id, String name, String email);
  Future<void> deleteUser(int id);
}

// domain/usecases/get_users.dart
class GetUsers implements UseCase<List<User>, NoParams> {
  final UserRepository repository;

  GetUsers(this.repository);

  @override
  Future<List<User>> call(NoParams params) async {
    return await repository.getUsers();
  }
}
```

#### **Data Layer:**

```dart
// data/models/user_model.dart
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
    };
  }
}

// data/repositories/user_repository_impl.dart
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final UserLocalDataSource localDataSource;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<User>> getUsers() async {
    return await remoteDataSource.getUsers();
  }

  @override
  Future<User> createUser(String name, String email) async {
    return await remoteDataSource.createUser(name, email);
  }
}
```

#### **Presentation Layer - Combining BLoC + TanStack Query:**

```dart
// presentation/bloc/user_form_bloc.dart
class UserFormBloc extends Bloc<UserFormEvent, UserFormState> {
  UserFormBloc() : super(UserFormInitial()) {
    on<UserFormNameChanged>(_onNameChanged);
    on<UserFormEmailChanged>(_onEmailChanged);
    on<UserFormValidationRequested>(_onValidationRequested);
    on<UserFormReset>(_onReset);
  }

  void _onNameChanged(UserFormNameChanged event, Emitter<UserFormState> emit) {
    emit(UserFormUpdated(
      name: event.name,
      email: state is UserFormUpdated ? (state as UserFormUpdated).email : '',
      isValid: _isValid(event.name, state is UserFormUpdated ? (state as UserFormUpdated).email : ''),
    ));
  }

  void _onEmailChanged(UserFormEmailChanged event, Emitter<UserFormState> emit) {
    emit(UserFormUpdated(
      name: state is UserFormUpdated ? (state as UserFormUpdated).name : '',
      email: event.email,
      isValid: _isValid(state is UserFormUpdated ? (state as UserFormUpdated).name : '', event.email),
    ));
  }

  bool _isValid(String name, String email) {
    return name.isNotEmpty && email.isNotEmpty && email.contains('@');
  }
}

// presentation/pages/user_page.dart
class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserFormBloc(),
      child: Scaffold(
        appBar: AppBar(title: Text('Users')),
        body: Column(
          children: [
            // TanStack Query handles data fetching
            Expanded(
              flex: 2,
              child: UseQuery<List<User>>(
                options: QueryOptions<List<User>>(
                  queryKey: ['users'],
                  queryFn: () => GetIt.instance<GetUsers>()(NoParams()),
                  staleTime: Duration(minutes: 5),
                ),
                builder: (context, result) {
                  if (result.isLoading) return Center(child: CircularProgressIndicator());
                  if (result.isError) return Text('Error: ${result.error}');
                  
                  return ListView.builder(
                    itemCount: result.data?.length ?? 0,
                    itemBuilder: (context, index) {
                      final user = result.data![index];
                      return ListTile(
                        title: Text(user.name),
                        subtitle: Text(user.email),
                      );
                    },
                  );
                },
              ),
            ),
            
            // BLoC handles form state
            Expanded(
              child: BlocBuilder<UserFormBloc, UserFormState>(
                builder: (context, state) {
                  return UserFormWidget(state: state);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 🎣 With Riverpod

Excellent combination for modern reactive programming with clean architecture.

#### **Providers Setup:**

```dart
// presentation/providers/user_providers.dart
// Repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    remoteDataSource: UserRemoteDataSourceImpl(),
    localDataSource: UserLocalDataSourceImpl(),
  );
});

// Use case providers
final getUsersProvider = Provider<GetUsers>((ref) {
  return GetUsers(ref.watch(userRepositoryProvider));
});

final createUserProvider = Provider<CreateUser>((ref) {
  return CreateUser(ref.watch(userRepositoryProvider));
});

// Form state provider
final userFormProvider = StateNotifierProvider<UserFormNotifier, UserFormState>((ref) {
  return UserFormNotifier();
});

// presentation/notifiers/user_form_notifier.dart
class UserFormNotifier extends StateNotifier<UserFormState> {
  UserFormNotifier() : super(UserFormState.initial());

  void updateName(String name) {
    state = state.copyWith(
      name: name,
      isValid: _isValid(name, state.email),
    );
  }

  void updateEmail(String email) {
    state = state.copyWith(
      email: email,
      isValid: _isValid(state.name, email),
    );
  }

  void reset() {
    state = UserFormState.initial();
  }

  bool _isValid(String name, String email) {
    return name.isNotEmpty && email.isNotEmpty && email.contains('@');
  }
}

@freezed
class UserFormState with _$UserFormState {
  const factory UserFormState({
    required String name,
    required String email,
    required bool isValid,
  }) = _UserFormState;

  factory UserFormState.initial() => UserFormState(
    name: '',
    email: '',
    isValid: false,
  );
}
```

#### **Riverpod UI Implementation:**

```dart
// presentation/pages/user_page_riverpod.dart
class UserPageRiverpod extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(userFormProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('Users with Riverpod')),
      body: Column(
        children: [
          // TanStack Query for data fetching
          Expanded(
            flex: 2,
            child: UseQuery<List<User>>(
              options: QueryOptions<List<User>>(
                queryKey: ['users'],
                queryFn: () => ref.read(getUsersProvider)(NoParams()),
                staleTime: Duration(minutes: 5),
              ),
              builder: (context, result) {
                if (result.isLoading) return Center(child: CircularProgressIndicator());
                if (result.isError) return Text('Error: ${result.error}');
                
                return ListView.builder(
                  itemCount: result.data?.length ?? 0,
                  itemBuilder: (context, index) {
                    final user = result.data![index];
                    return ListTile(
                      title: Text(user.name),
                      subtitle: Text(user.email),
                    );
                  },
                );
              },
            ),
          ),
          
          // Riverpod for form state + TanStack Query for mutation
          Expanded(
            child: UseMutation<User, CreateUserRequest>(
              options: MutationOptions<User, CreateUserRequest>(
                mutationFn: (request) => ref.read(createUserProvider)(
                  CreateUserParams(name: request.name, email: request.email),
                ),
                onSuccess: (user, variables) {
                  ref.read(userFormProvider.notifier).reset();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User ${user.name} created!')),
                  );
                },
                invalidateQueries: [['users']],
              ),
              builder: (context, mutation) {
                return Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        decoration: InputDecoration(labelText: 'Name'),
                        onChanged: (value) => ref.read(userFormProvider.notifier).updateName(value),
                      ),
                      TextField(
                        decoration: InputDecoration(labelText: 'Email'),
                        onChanged: (value) => ref.read(userFormProvider.notifier).updateEmail(value),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: formState.isValid && !mutation.isLoading
                            ? () {
                                mutation.mutate(CreateUserRequest(
                                  name: formState.name,
                                  email: formState.email,
                                ));
                              }
                            : null,
                        child: mutation.isLoading 
                            ? CircularProgressIndicator()
                            : Text('Create User'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### 📱 With GetX

Great for rapid development with reactive programming and dependency injection.

#### **Controllers and Bindings:**

```dart
// presentation/controllers/user_form_controller.dart
class UserFormController extends GetxController {
  final UserRepository _userRepository = Get.find<UserRepository>();
  
  // Form state
  final name = ''.obs;
  final email = ''.obs;
  final isLoading = false.obs;
  
  // Computed properties
  bool get isValid => name.value.isNotEmpty && 
                     email.value.isNotEmpty && 
                     email.value.contains('@');

  void updateName(String value) {
    name.value = value;
  }

  void updateEmail(String value) {
    email.value = value;
  }

  void reset() {
    name.value = '';
    email.value = '';
  }
}

// presentation/bindings/user_binding.dart
class UserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserRemoteDataSource>(() => UserRemoteDataSourceImpl());
    Get.lazyPut<UserLocalDataSource>(() => UserLocalDataSourceImpl());
    Get.lazyPut<UserRepository>(() => UserRepositoryImpl(
      remoteDataSource: Get.find(),
      localDataSource: Get.find(),
    ));
    Get.lazyPut<GetUsers>(() => GetUsers(Get.find()));
    Get.lazyPut<CreateUser>(() => CreateUser(Get.find()));
    Get.lazyPut(() => UserFormController());
  }
}
```

#### **GetX UI Implementation:**

```dart
// presentation/pages/user_page_getx.dart
class UserPageGetX extends GetView<UserFormController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Users with GetX')),
      body: Column(
        children: [
          // TanStack Query for data fetching
          Expanded(
            flex: 2,
            child: UseQuery<List<User>>(
              options: QueryOptions<List<User>>(
                queryKey: ['users'],
                queryFn: () => Get.find<GetUsers>()(NoParams()),
                staleTime: Duration(minutes: 5),
              ),
              builder: (context, result) {
                if (result.isLoading) return Center(child: CircularProgressIndicator());
                if (result.isError) return Text('Error: ${result.error}');
                
                return ListView.builder(
                  itemCount: result.data?.length ?? 0,
                  itemBuilder: (context, index) {
                    final user = result.data![index];
                    return ListTile(
                      title: Text(user.name),
                      subtitle: Text(user.email),
                    );
                  },
                );
              },
            ),
          ),
          
          // GetX for form state + TanStack Query for mutation
          Expanded(
            child: UseMutation<User, CreateUserRequest>(
              options: MutationOptions<User, CreateUserRequest>(
                mutationFn: (request) => Get.find<CreateUser>()(
                  CreateUserParams(name: request.name, email: request.email),
                ),
                onSuccess: (user, variables) {
                  controller.reset();
                  Get.snackbar(
                    'Success',
                    'User ${user.name} created!',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                invalidateQueries: [['users']],
              ),
              builder: (context, mutation) {
                return Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Obx(() => TextField(
                        decoration: InputDecoration(
                          labelText: 'Name',
                          errorText: controller.name.value.isEmpty ? 'Name is required' : null,
                        ),
                        onChanged: controller.updateName,
                      )),
                      Obx(() => TextField(
                        decoration: InputDecoration(
                          labelText: 'Email',
                          errorText: !controller.email.value.contains('@') && 
                                   controller.email.value.isNotEmpty 
                              ? 'Invalid email' 
                              : null,
                        ),
                        onChanged: controller.updateEmail,
                      )),
                      SizedBox(height: 16),
                      Obx(() => ElevatedButton(
                        onPressed: controller.isValid && !mutation.isLoading
                            ? () {
                                mutation.mutate(CreateUserRequest(
                                  name: controller.name.value,
                                  email: controller.email.value,
                                ));
                              }
                            : null,
                        child: mutation.isLoading 
                            ? CircularProgressIndicator()
                            : Text('Create User'),
                      )),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

### 🎯 Architecture Best Practices

#### **1. Separation of Concerns:**

```dart
// ✅ Good - Clear separation
// TanStack Query: API calls, caching, background updates
// BLoC/Riverpod/GetX: UI state, form validation, navigation
// Repository: Business logic and data transformation

// ❌ Avoid - Mixing concerns
// Don't put form validation in TanStack Query
// Don't put API calls in BLoC/Riverpod/GetX
```

#### **2. Dependency Injection Setup:**

```dart
// Using get_it for dependency injection
void setupDependencies() {
  // Data sources
  GetIt.instance.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(),
  );
  
  // Repositories
  GetIt.instance.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDataSource: GetIt.instance(),
      localDataSource: GetIt.instance(),
    ),
  );
  
  // Use cases
  GetIt.instance.registerLazySingleton(() => GetUsers(GetIt.instance()));
  GetIt.instance.registerLazySingleton(() => CreateUser(GetIt.instance()));
}
```

#### **3. Error Handling Strategy:**

```dart
// Custom error handling that works with both systems
class AppErrorHandler {
  static void handleQueryError(Object error, {
    required BuildContext context,
    VoidCallback? onRetry,
  }) {
    if (error is NetworkException) {
      _showNetworkError(context, onRetry);
    } else if (error is ValidationException) {
      _showValidationError(context, error.message);
    } else {
      _showGenericError(context, onRetry);
    }
  }
  
  static void handleBlocError(BlocBase bloc, Object error) {
    // Handle BLoC-specific errors
    if (error is FormValidationError) {
      // Handle form validation
    }
  }
}
```

#### **4. Key Benefits of This Approach:**

- **🎯 Clear Separation**: TanStack Query handles server state, your chosen state management handles client state
- **🚀 Best of Both Worlds**: Automatic caching + reactive UI updates
- **🏗️ Scalable Architecture**: Easy to test, maintain, and extend
- **⚡ Performance**: Optimized data fetching with intelligent UI updates
- **🔄 Consistency**: Same patterns across different state management solutions

#### **5. When to Use Each Solution:**

- **BLoC**: When you need predictable state management with events and states
- **Riverpod**: For modern reactive programming with excellent provider ecosystem
- **GetX**: For rapid development with built-in dependency injection and routing

## 👨‍💻 Author

**Haraprosad Biswas** - *Creator & Maintainer*

- 🐱 **GitHub**: [@Haraprosad](https://github.com/Haraprosad)
- 💼 **LinkedIn**: [Connect with me](https://www.linkedin.com/in/haraprosadbiswas/)
- 📧 **Email**: [dev.haraprosad@gmail.com](mailto:dev.haraprosad@gmail.com)
- 🌐 **Portfolio**: [@haraprosad](https://portfolio-website-2f800.web.app/)

*"Bringing the power of TanStack Query to the Flutter ecosystem - one query at a time!"*

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Copyright (c) 2025 Haraprosad Biswas**

## 🙋‍♂️ Support

- 📚 [Documentation](https://github.com/Haraprosad/flutter_tanstack_query)
- 🐛 [Issues](https://github.com/Haraprosad/flutter_tanstack_query/issues)
- 📧 [Email Support](mailto:dev.haraprosad@gmail.com)

## 🎯 Roadmap

- [ ] DevTools integration
- [ ] GraphQL support
- [ ] WebSocket integration
- [ ] Advanced caching strategies
- [ ] Background sync
- [ ] Query batching
- [ ] More examples and tutorials

---

Made with ❤️ by **Haraprosad Biswas** for the Flutter community

Copyright (c) 2025 Haraprosad Biswas

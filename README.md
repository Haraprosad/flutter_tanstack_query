# 🚀 Flutter TanStack Query

[![pub package](https://img.shields.io/pub/v/flutter_tanstack_query.svg)](https://pub.dev/packages/flutter_tanstack_query)
[![popularity](https://badges.bar/flutter_tanstack_query/popularity)](https://pub.dev/packages/flutter_tanstack_query/score)
[![likes](https://badges.bar/flutter_tanstack_query/likes)](https://pub.dev/packages/flutter_tanstack_query/score)
[![pub points](https://badges.bar/flutter_tanstack_query/pub%20points)](https://pub.dev/packages/flutter_tanstack_query/score)

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

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♂️ Support

- 📚 [Documentation](https://github.com/your-repo/flutter_tanstack_query/wiki)
- 🐛 [Issues](https://github.com/your-repo/flutter_tanstack_query/issues)
- 💬 [Discussions](https://github.com/your-repo/flutter_tanstack_query/discussions)
- 📧 [Email Support](mailto:support@flutter-tanstack-query.dev)

## 🎯 Roadmap

- [ ] DevTools integration
- [ ] GraphQL support
- [ ] WebSocket integration
- [ ] Advanced caching strategies
- [ ] Background sync
- [ ] Query batching
- [ ] More examples and tutorials

---

Made with ❤️ for the Flutter community

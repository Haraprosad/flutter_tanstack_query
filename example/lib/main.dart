import 'package:flutter/material.dart';
import 'package:flutter_tanstack_query/flutter_tanstack_query.dart';

// Example models
class User {
  final int id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(id: json['id'], name: json['name'], email: json['email']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email};
  }
}

class CreateUserRequest {
  final String name;
  final String email;

  CreateUserRequest({required this.name, required this.email});

  Map<String, dynamic> toJson() {
    return {'name': name, 'email': email};
  }
}

// Example API service
class ApiService {
  static Future<List<User>> fetchUsers() async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    return [
      User(id: 1, name: 'John Doe', email: 'john@example.com'),
      User(id: 2, name: 'Jane Smith', email: 'jane@example.com'),
    ];
  }

  static Future<User> createUser(CreateUserRequest request) async {
    // Simulate API call
    await Future.delayed(Duration(milliseconds: 500));
    return User(
      id: DateTime.now().millisecondsSinceEpoch,
      name: request.name,
      email: request.email,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize cache and network policy
  await QueryCache.instance.initialize();
  await NetworkPolicy.instance.initialize();

  // Initialize app lifecycle manager
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
        title: 'Flutter TanStack Query Example',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: HomeScreen(),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CreateUserScreen()),
              );
            },
          ),
        ],
      ),
      body: UseQuery<List<User>>(
        options: QueryOptions<List<User>>(
          queryKey: ['users'],
          queryFn: () => ApiService.fetchUsers(),
          staleTime: Duration(minutes: 5),
          cacheTime: Duration(minutes: 30),
        ),
        builder: (context, result) {
          if (result.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (result.isError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: ${result.error}'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: result.refetch,
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: result.refetch,
            child: ListView.builder(
              itemCount: result.data?.length ?? 0,
              itemBuilder: (context, index) {
                final user = result.data![index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(user.name[0].toUpperCase()),
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: IconButton(
                    icon: Icon(Icons.info),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserDetailScreen(user: user),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class CreateUserScreen extends StatefulWidget {
  @override
  _CreateUserScreenState createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create User')),
      body: UseMutation<User, CreateUserRequest>(
        options: MutationOptions<User, CreateUserRequest>(
          mutationFn: (request) => ApiService.createUser(request),
          onSuccess: (user, variables) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('User ${user.name} created successfully!'),
              ),
            );
            Navigator.pop(context);
          },
          onError: (error, variables) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error creating user: $error'),
                backgroundColor: Colors.red,
              ),
            );
          },
          invalidateQueries: [
            ['users'],
          ], // Refresh users list
        ),
        builder: (context, mutation) {
          return Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: mutation.isLoading
                        ? null
                        : () {
                            if (_formKey.currentState?.validate() ?? false) {
                              final request = CreateUserRequest(
                                name: _nameController.text,
                                email: _emailController.text,
                              );
                              mutation.mutate(request);
                            }
                          },
                    child: mutation.isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Creating...'),
                            ],
                          )
                        : Text('Create User'),
                  ),
                  if (mutation.isError) ...[
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Text(
                        'Error: ${mutation.error}',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class UserDetailScreen extends StatelessWidget {
  final User user;

  const UserDetailScreen({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(user.name)),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Details',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.person),
                      title: Text('Name'),
                      subtitle: Text(user.name),
                    ),
                    ListTile(
                      leading: Icon(Icons.email),
                      title: Text('Email'),
                      subtitle: Text(user.email),
                    ),
                    ListTile(
                      leading: Icon(Icons.tag),
                      title: Text('ID'),
                      subtitle: Text(user.id.toString()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

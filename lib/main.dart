import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'login_page.dart';
import 'opciones_page.dart';
import 'planeaciones_list_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plantcher',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'ComicNeue', // Fuente amigable
      ),
      // Configuración de localización en español
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
      ],
      locale: const Locale('es', 'ES'), // Forzar español
      home: const AuthWrapper(),
    );
  }
}

// Widget que maneja la autenticación
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mostrar pantalla de carga mientras verifica autenticación
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Si hay un usuario autenticado, verificar si tiene proyectos
        if (snapshot.hasData) {
          print('Usuario autenticado: ${snapshot.data!.uid}');
          
          return FutureBuilder<bool>(
            future: _hasUserCreatedProjects(snapshot.data!.uid),
            builder: (context, projectSnapshot) {
              if (projectSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              
              print('¿Usuario tiene proyectos? ${projectSnapshot.data}');
              
              // Si el usuario ha creado al menos un proyecto, mostrar la lista de planeaciones
              if (projectSnapshot.data == true) {
                print('Mostrando PlaneacionesListPage');
                return const PlaneacionesListPage();
              }
              
              // Si no ha creado proyectos, mostrar la página principal (primera vez)
              print('Mostrando MyHomePage');
              return const MyHomePage();
            },
          );
        }
        
        // Si no hay usuario, mostrar login
        print('No hay usuario, mostrando LoginPage');
        return const LoginPage();
      },
    );
  }

  Future<bool> _hasUserCreatedProjects(String userId) async {
    try {
      print('Verificando proyectos para usuario: $userId');
      
      // Verificar en todas las colecciones de proyectos si el usuario ha creado algo
      final collections = [
        'detalles_proyecto',
        'detalles_unidad', 
        'detalles_taller',
        'detalles_rincones',
        'detalles_centros_interes',
        'detalles_abj',
        'planeaciones' // Incluir planeaciones
      ];
      
      for (String collection in collections) {
        QuerySnapshot querySnapshot;
        
        // Para la colección 'planeaciones' usar 'userId', para las demás usar 'user_id'
        if (collection == 'planeaciones') {
          querySnapshot = await FirebaseFirestore.instance
              .collection(collection)
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();
        } else {
          querySnapshot = await FirebaseFirestore.instance
              .collection(collection)
              .where('user_id', isEqualTo: userId)
              .limit(1)
              .get();
        }
        
        print('Colección $collection: ${querySnapshot.docs.length} documentos');
          
        if (querySnapshot.docs.isNotEmpty) {
          print('✅ Usuario tiene proyectos en: $collection');
          return true;
        }
      }
      
      print('❌ Usuario NO tiene proyectos en ninguna colección');
      return false;
    } catch (e) {
      print('❌ Error verificando proyectos del usuario: $e');
      return false;
    }
  }
}

// Página principal después del login (solo para usuarios sin proyectos - primera vez)
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plantcher'),
        backgroundColor: const Color(0xFF6A4C93),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              // No necesitamos Navigator.pushReplacement porque AuthWrapper se encarga automáticamente
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(bottom: 32.0),
              child: Text(
                'Crear nueva planeación',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                  fontFamily: 'ComicNeue',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OpcionesPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(32),
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                elevation: 8,
              ),
              child: const Icon(
                Icons.add,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

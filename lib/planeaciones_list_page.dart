import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'opciones_page.dart';
import 'detallar_abj_page.dart';
import 'detallar_centros_page.dart';
import 'detallar_taller.dart';
import 'detallar_proyecto.dart';
import 'detallar_unidad.dart';
import 'detallar_rincones.dart';

class PlaneacionesListPage extends StatefulWidget {
  const PlaneacionesListPage({super.key});

  @override
  State<PlaneacionesListPage> createState() => _PlaneacionesListPageState();
}

class _PlaneacionesListPageState extends State<PlaneacionesListPage> 
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _buttonAnimationController; // ✅ AGREGADO - Para animación del botón
  late Animation<double> _fadeAnimation;
  late Animation<double> _buttonScaleAnimation; // ✅ AGREGADO
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // ✅ AGREGADO - Controlador para animación del botón
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // ✅ AGREGADO - Animación de escala para el botón
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _buttonAnimationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
    
    // Debug: Verificar datos del usuario
    if (currentUser != null) {
      _debugUserPlaneaciones();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _buttonAnimationController.dispose(); // ✅ AGREGADO
    super.dispose();
  }

  // Método de debug para verificar las planeaciones del usuario
  Future<void> _debugUserPlaneaciones() async {
    try {
      print('=== DEBUG PLANEACIONES ===');
      print('Usuario actual: ${currentUser?.uid}');
      
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('planeaciones')
          .where('userId', isEqualTo: currentUser!.uid)
          .get();
      
      print('Planeaciones encontradas: ${snapshot.docs.length}');
      
      for (var doc in snapshot.docs) {
        print('Documento ID: ${doc.id}');
        print('Datos: ${doc.data()}');
      }
      
      print('=== FIN DEBUG ===');
    } catch (e) {
      print('Error en debug: $e');
    }
  }

  Future<void> _eliminarPlaneacion(String planeacionId, String titulo) async {
    // Mostrar diálogo de confirmación
    bool confirmar = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text(
            '¿Eliminar planeación?',
            style: TextStyle(
              color: Color(0xFF6A4C93),
              fontWeight: FontWeight.bold,
              fontFamily: 'ComicNeue',
            ),
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar la planeación "$titulo"? Esta acción no se puede deshacer.',
            style: const TextStyle(fontFamily: 'ComicNeue'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey, fontFamily: 'ComicNeue'),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.white, fontFamily: 'ComicNeue'),
              ),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmar) {
      try {
        await FirebaseFirestore.instance
            .collection('planeaciones')
            .doc(planeacionId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Planeación eliminada exitosamente',
                style: TextStyle(fontFamily: 'ComicNeue'),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error al eliminar: $e',
                style: const TextStyle(fontFamily: 'ComicNeue'),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  void _editarPlaneacion(Map<String, dynamic> planeacionData, String planeacionId) {
    // Extraer datos de la planeación
    final String titulo = planeacionData['titulo'] ?? '';
    final String modalidad = planeacionData['modalidad'] ?? '';
    final List<String> campus = List<String>.from(planeacionData['campus'] ?? []);
    final List<Map<String, dynamic>> contenidos = List<Map<String, dynamic>>.from(planeacionData['contenidos'] ?? []);
    final List<Map<String, dynamic>> seleccionGrados = List<Map<String, dynamic>>.from(planeacionData['seleccionGrados'] ?? []);

    // Navegar a la pantalla correspondiente según la modalidad
    switch (modalidad) {
      case "Aprendizaje basado en el juego":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetallarABJPage(
              titulo: titulo,
              campus: campus,
              contenidos: contenidos,
              seleccionGrados: seleccionGrados,
              isEditing: true,
              planeacionId: planeacionId,
            ),
          ),
        );
        break;
        
      case "Centros de interés":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetallarCentrosInteresPage(
              titulo: titulo,
              campus: campus,
              contenidos: contenidos,
              seleccionGrados: seleccionGrados,
              isEditing: true,
              planeacionId: planeacionId,
            ),
          ),
        );
        break;
        
      case "Taller crítico":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetallarTallerPage(
              titulo: titulo,
              campus: campus,
              contenidos: contenidos,
              seleccionGrados: seleccionGrados,
              isEditing: true,
              planeacionId: planeacionId,
            ),
          ),
        );
        break;
        
      case "Proyecto":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetallarProyectoPage(
              titulo: titulo,
              campus: campus,
              contenidos: contenidos,
              seleccionGrados: seleccionGrados,
              isEditing: true,
              planeacionId: planeacionId,
            ),
          ),
        );
        break;
        
      case "Unidad didáctica":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetallarUnidadPage(
              titulo: titulo,
              campus: campus,
              contenidos: contenidos,
              seleccionGrados: seleccionGrados,
              isEditing: true,
              planeacionId: planeacionId,
            ),
          ),
        );
        break;
        
      case "Rincones de aprendizaje":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetallarRinconesPage(
              titulo: titulo,
              campus: campus,
              contenidos: contenidos,
              seleccionGrados: seleccionGrados,
              isEditing: true,
              planeacionId: planeacionId,
            ),
          ),
        );
        break;
        
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Modalidad no reconocida para edición',
              style: TextStyle(fontFamily: 'ComicNeue'),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
    }
  }

  // ✅ MODIFICADO - Función con animación al presionar
  void _crearNuevaPlaneacion() async {
    // Animación al presionar
    await _buttonAnimationController.forward();
    await _buttonAnimationController.reverse();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OpcionesPage(),
      ),
    );
  }

  Future<void> _cerrarSesion() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF6A4C93), // Morado profundo
                  Color(0xFF9C89B8), // Morado medio
                  Color(0xFFB8A9C9), // Morado claro
                ],
              ),
            ),
            child: SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Header con título y botón de cerrar sesión
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mis Planeaciones',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'ComicNeue',
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Hola, ${currentUser?.email?.split('@')[0] ?? 'Usuario'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  fontFamily: 'ComicNeue',
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: _cerrarSesion,
                            icon: const Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 28,
                            ),
                            tooltip: 'Cerrar sesión',
                          ),
                        ],
                      ),
                    ),

                    // Lista de planeaciones
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            
                            // Título de la sección
                            const Text(
                              'Tus Planeaciones Educativas',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6A4C93),
                                fontFamily: 'ComicNeue',
                              ),
                            ),
                            
                            const SizedBox(height: 20),

                            // Lista de planeaciones
                            Expanded(
                              child: currentUser == null
                                  ? const Center(
                                      child: Text(
                                        'No has iniciado sesión',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey,
                                          fontFamily: 'ComicNeue',
                                        ),
                                      ),
                                    )
                                  : StreamBuilder<QuerySnapshot>(
                                      stream: FirebaseFirestore.instance
                                          .collection('planeaciones')
                                          .where('userId', isEqualTo: currentUser!.uid)
                                          .orderBy('fecha_creacion', descending: true)
                                          .snapshots(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError) {
                                          print('StreamBuilder - Error: ${snapshot.error}');
                                        }

                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A4C93)),
                                            ),
                                          );
                                        }

                                        if (snapshot.hasError) {
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons.error_outline,
                                                  size: 64,
                                                  color: Colors.red,
                                                ),
                                                const SizedBox(height: 16),
                                                Text(
                                                  'Error: ${snapshot.error}',
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                    fontFamily: 'ComicNeue',
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                          return Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.school_outlined,
                                                  size: 80,
                                                  color: Colors.grey[300],
                                                ),
                                                const SizedBox(height: 16),
                                                const Text(
                                                  '¡Comienza tu primera planeación!',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF6A4C93),
                                                    fontFamily: 'ComicNeue',
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                const Text(
                                                  'Aún no has creado ninguna planeación.\nPresiona el botón + para comenzar.',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color: Colors.grey,
                                                    fontFamily: 'ComicNeue',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        return ListView.builder(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          itemCount: snapshot.data!.docs.length,
                                          itemBuilder: (context, index) {
                                            DocumentSnapshot doc = snapshot.data!.docs[index];
                                            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                                            
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 16),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.08),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                                border: Border.all(
                                                  color: const Color(0xFF6A4C93).withOpacity(0.2),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(16),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    // Título y fecha
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            data['titulo'] ?? 'Planeación sin título',
                                                            style: const TextStyle(
                                                              fontSize: 18,
                                                              fontWeight: FontWeight.bold,
                                                              color: Color(0xFF6A4C93),
                                                              fontFamily: 'ComicNeue',
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          _formatearFecha(data['fecha_creacion']),
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey[600],
                                                            fontFamily: 'ComicNeue',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    
                                                    const SizedBox(height: 8),
                                                    
                                                    // Información básica
                                                    if (data['modalidad'] != null)
                                                      _buildInfoChip('Modalidad', data['modalidad'], Icons.school),
                                                    if (data['campus'] != null && (data['campus'] as List).isNotEmpty)
                                                      _buildInfoChip('Campos', (data['campus'] as List).join(', '), Icons.category),
                                                    
                                                    const SizedBox(height: 16),
                                                    
                                                    // Botones de acción
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        // Botón Editar
                                                        ElevatedButton.icon(
                                                          onPressed: () => _editarPlaneacion(data, doc.id),
                                                          icon: const Icon(Icons.edit, size: 16),
                                                          label: const Text(
                                                            'Editar',
                                                            style: TextStyle(fontFamily: 'ComicNeue'),
                                                          ),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: const Color(0xFF6A4C93),
                                                            foregroundColor: Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                          ),
                                                        ),
                                                        
                                                        const SizedBox(width: 8),
                                                        
                                                        // Botón Eliminar
                                                        ElevatedButton.icon(
                                                          onPressed: () => _eliminarPlaneacion(
                                                            doc.id,
                                                            data['titulo'] ?? 'Planeación sin título',
                                                          ),
                                                          icon: const Icon(Icons.delete, size: 16),
                                                          label: const Text(
                                                            'Eliminar',
                                                            style: TextStyle(fontFamily: 'ComicNeue'),
                                                          ),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.red[400],
                                                            foregroundColor: Colors.white,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(8),
                                                            ),
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 8,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // ✅ NUEVO - Botón flotante fijo con tooltip
          Positioned(
            bottom: 20,
            right: 20,
            child: AnimatedBuilder(
              animation: _buttonScaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _buttonScaleAnimation.value,
                  child: Tooltip(
                    message: 'Nueva Planeación',
                    textStyle: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'ComicNeue',
                      fontSize: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A4C93),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A4C93),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6A4C93).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: FloatingActionButton(
                        onPressed: _crearNuevaPlaneacion,
                        backgroundColor: const Color(0xFF6A4C93),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        child: const Icon(
                          Icons.add,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF6A4C93),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A4C93),
              fontSize: 14,
              fontFamily: 'ComicNeue',
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontFamily: 'ComicNeue',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return '';
    
    try {
      if (fecha is Timestamp) {
        DateTime dateTime = fecha.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
      return '';
    } catch (e) {
      return '';
    }
  }
}
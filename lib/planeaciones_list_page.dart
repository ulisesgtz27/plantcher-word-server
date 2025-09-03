import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/draft_service.dart';
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
  late AnimationController _buttonAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _buttonScaleAnimation;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _buttonAnimationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
    
    // Verificar borradores al cargar la página
    if (currentUser != null) {
      _checkForDraftsImproved();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  // ✅ FUNCIÓN MEJORADA: Verificar borradores con logs detallados
  Future<void> _checkForDraftsImproved() async {
    print('🔍 Iniciando verificación de borradores...');
    
    try {
      // Esperar un poco para que la UI se cargue completamente
      await Future.delayed(const Duration(milliseconds: 1000));
      
      print('📋 Buscando borradores en Firestore...');
      final draft = await DraftService.getLatestDraft();
      
      if (draft != null) {
        print('✅ Borrador encontrado: $draft');
        
        if (mounted) {
          print('📱 Widget está montado, mostrando diálogo...');
          _showDraftDialog(draft);
        } else {
          print('❌ Widget no está montado');
        }
      } else {
        print('❌ No se encontraron borradores');
      }
    } catch (e) {
      print('❌ Error verificando borradores: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // ✅ FUNCIÓN MEJORADA: Mostrar diálogo con más logs
  void _showDraftDialog(Map<String, dynamic> draft) {
    print('🎯 Intentando mostrar diálogo de borrador...');
    
    final modalidad = draft['modalidad'] as String;
    final data = draft['data'] as Map<String, dynamic>;
    final draftId = draft['id'] as String;
    
    print('📝 Datos del borrador:');
    print('   - Modalidad: $modalidad');
    print('   - ID: $draftId');
    print('   - Título: ${data['titulo']}');
    
    // ✅ AGREGADO: Verificar si ya hay un diálogo abierto
    if (ModalRoute.of(context)?.isCurrent != true) {
      print('❌ Ya hay un diálogo o ruta abierta');
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        print('🎨 Construyendo diálogo...');
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.drafts,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Borrador Encontrado',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                    fontFamily: 'ComicNeue',
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¿Quieres continuar con la planeación que estabas haciendo?',
                style: TextStyle(
                  fontFamily: 'ComicNeue',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modalidad: $modalidad',
                      style: const TextStyle(
                        fontFamily: 'ComicNeue',
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    if (data['titulo'] != null && data['titulo'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Título: ${data['titulo']}',
                        style: const TextStyle(fontFamily: 'ComicNeue'),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Progreso: ${_calculateProgress(data)}% completado',
                      style: TextStyle(
                        fontFamily: 'ComicNeue',
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                print('🗑️ Usuario eligió eliminar borrador');
                try {
                  await DraftService.deleteDraft(draftId);
                  print('✅ Borrador eliminado exitosamente');
                } catch (e) {
                  print('❌ Error eliminando borrador: $e');
                }
                Navigator.of(context).pop();
              },
              child: const Text(
                'No, empezar nuevo',
                style: TextStyle(
                  color: Colors.grey,
                  fontFamily: 'ComicNeue',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                print('✅ Usuario eligió continuar con borrador');
                Navigator.of(context).pop();
                _navigateToDraft(modalidad, data, draftId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontFamily: 'ComicNeue'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Sí, continuar'),
            ),
          ],
        );
      },
    ).then((value) {
      print('📱 Diálogo cerrado');
    }).catchError((error) {
      print('❌ Error mostrando diálogo: $error');
    });
  }

  // ✅ FUNCIÓN MEJORADA: Navegar al borrador con logs
  void _navigateToDraft(String modalidad, Map<String, dynamic> data, String draftId) {
    print('🚀 Navegando a borrador...');
    print('   - Paso actual: ${data['paso']}');
    
    // Determinar si es opciones_page o detallar
    if (data['paso'] != null && data['paso'] != 'detallar') {
      print('📝 Navegando a OpcionesPage');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OpcionesPage(
            draftData: data,
            draftId: draftId,
          ),
        ),
      );
    } else {
      print('🎯 Navegando a página de detallar');
      _navigateToDetailPage(modalidad, data, draftId);
    }
  }

  // ✅ FUNCIÓN MEJORADA: Navegar a página de detallar con logs
  void _navigateToDetailPage(String modalidad, Map<String, dynamic> data, String draftId) {
    print('🎯 Determinando página de detallar para modalidad: $modalidad');
    
    final titulo = data['titulo']?.toString() ?? '';
    final campus = data['campus'] != null ? List<String>.from(data['campus']) : <String>[];
    final contenidos = data['contenidos'] != null ? List<Map<String, dynamic>>.from(data['contenidos']) : <Map<String, dynamic>>[];
    final seleccionGrados = data['seleccionGrados'] != null ? List<Map<String, dynamic>>.from(data['seleccionGrados']) : <Map<String, dynamic>>[];
    
    print('📊 Datos extraídos:');
    print('   - Título: $titulo');
    print('   - Campus: ${campus.length} elementos');
    print('   - Contenidos: ${contenidos.length} elementos');
    print('   - Grados: ${seleccionGrados.length} elementos');
    
    switch (modalidad.toLowerCase()) {
      case 'aprendizaje basado en el juego':
      case 'abj':
        print('🎮 Navegando a DetallarABJPage');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetallarABJPage(
              titulo: titulo,
              campus: campus,
              contenidos: contenidos,
              seleccionGrados: seleccionGrados,
              draftData: data,
              draftId: draftId,
            ),
          ),
        );
        break;
      
      case 'centros de interés':
        print('🏛️ Navegando a DetallarCentrosInteresPage');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetallarCentrosInteresPage(
              titulo: titulo,
              campus: campus,
              contenidos: contenidos,
              seleccionGrados: seleccionGrados,
              draftData: data,
              draftId: draftId,
            ),
          ),
        );
        break;
      
      case 'taller crítico':
        print('🔧 Navegando a DetallarTallerPage');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetallarTallerPage(
              titulo: titulo,
              campus: campus,
              contenidos: contenidos,
              seleccionGrados: seleccionGrados,
              draftData: data,
              draftId: draftId,
            ),
          ),
        );
        break;
      
      case 'proyecto':
        print('📚 Navegando a DetallarProyectoPage');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetallarProyectoPage(
              titulo: titulo,
              campus: campus,
              contenidos: contenidos,
              seleccionGrados: seleccionGrados,
              draftData: data,
              draftId: draftId,
            ),
          ),
        );
        break;
      
      case 'unidad didáctica':
        print('📖 Navegando a DetallarUnidadPage');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetallarUnidadPage(
              titulo: titulo,
              campus: campus,
              contenidos: contenidos,
              seleccionGrados: seleccionGrados,
              draftData: data,
              draftId: draftId,
            ),
          ),
        );
        break;
      
      case 'rincones de aprendizaje':
        print('🏠 Navegando a DetallarRinconesPage');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetallarRinconesPage(
              titulo: titulo,
              campus: campus,
              contenidos: contenidos,
              seleccionGrados: seleccionGrados,
              draftData: data,
              draftId: draftId,
            ),
          ),
        );
        break;
      
      default:
        print('❌ Modalidad no reconocida: $modalidad');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Modalidad no reconocida para continuar borrador: $modalidad',
              style: const TextStyle(fontFamily: 'ComicNeue'),
            ),
            backgroundColor: Colors.orange,
          ),
        );
    }
  }

  // ✅ FUNCIÓN MEJORADA: Calcular progreso con más campos
  int _calculateProgress(Map<String, dynamic> data) {
    int completedFields = 0;
    int totalFields = 12; // Aumentamos los campos totales
    
    if (data['titulo']?.toString().isNotEmpty == true) completedFields++;
    if (data['modalidad']?.toString().isNotEmpty == true) completedFields++;
    if (data['campus']?.isNotEmpty == true) completedFields++;
    if (data['contenidos']?.isNotEmpty == true) completedFields++;
    if (data['seleccionGrados']?.isNotEmpty == true) completedFields++;
    if (data['proposito']?.toString().isNotEmpty == true) completedFields++;
    if (data['relevancia_social']?.toString().isNotEmpty == true) completedFields++;
    if (data['eje_articulador']?.toString().isNotEmpty == true) completedFields++;
    if (data['fecha_inicio'] != null) completedFields++;
    if (data['fecha_fin'] != null) completedFields++;
    if (data['materiales']?.isNotEmpty == true) completedFields++;
    if (data['espacios']?.isNotEmpty == true) completedFields++;
    
    final progress = ((completedFields / totalFields) * 100).round();
    print('📊 Progreso calculado: $completedFields/$totalFields = $progress%');
    return progress;
  }

  Future<void> _eliminarPlaneacion(String planeacionId, String titulo) async {
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
    final String titulo = planeacionData['titulo'] ?? '';
    final String modalidad = planeacionData['modalidad'] ?? '';
    final List<String> campus = List<String>.from(planeacionData['campus'] ?? []);
    final List<Map<String, dynamic>> contenidos = List<Map<String, dynamic>>.from(planeacionData['contenidos'] ?? []);
    final List<Map<String, dynamic>> seleccionGrados = List<Map<String, dynamic>>.from(planeacionData['seleccionGrados'] ?? []);

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
                  Color(0xFF6A4C93),
                  Color(0xFF9C89B8),
                  Color(0xFFB8A9C9),
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
                          // ✅ LIMPIADO: Solo botón de cerrar sesión
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
          
          // Botón flotante fijo con tooltip
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
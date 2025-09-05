import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/draft_service.dart';
import 'detallar_abj_page.dart';
import 'detallar_centros_page.dart';
import 'detallar_taller.dart';
import 'detallar_proyecto.dart';
import 'detallar_unidad.dart';
import 'detallar_rincones.dart';
import 'detallar_situacion.dart'; 

class OpcionesPage extends StatefulWidget {
  final Map<String, dynamic>? draftData;
  final String? draftId;

  const OpcionesPage({
    super.key,
    this.draftData,
    this.draftId,
  });

  @override
  State<OpcionesPage> createState() => _OpcionesPageState();
}

class _OpcionesPageState extends State<OpcionesPage>
    with TickerProviderStateMixin {
  int paso = 0;

  final TextEditingController nombreController = TextEditingController();
  String? modalidadSeleccionada;
  List<String> campusSeleccionados = [];

  Map<String, List<Map<String, dynamic>>> procesosPorCampo = {};
  Map<String, List<String>> contenidosSeleccionadosPorCampo = {};
  Map<String, Map<String, Set<String>>> gradosSeleccionadosPorCampo = {};
  Map<String, Map<String, Map<String, List<String>>>> seleccionGradosPorCampo =
      {};

  List<String> modalidades = [];
  List<String> campus = [];
  bool cargando = true;

  String? currentDraftId;
  bool isDraftLoaded = false;

  final Duration animDuration = const Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    currentDraftId = widget.draftId;
    cargarOpciones();
  }

  Future<void> cargarOpciones() async {
    final modalidadSnap =
        await FirebaseFirestore.instance.collection('modalidad').get();
    modalidades =
        modalidadSnap.docs.map((doc) => doc['nombre'] as String).toList();

    final campusSnap =
        await FirebaseFirestore.instance.collection('campos').get();
    campus = campusSnap.docs.map((doc) => doc['nombre'] as String).toList();

    if (modalidades.isNotEmpty && modalidadSeleccionada == null) {
      modalidadSeleccionada = modalidades.first;
    }

    if (widget.draftData != null && !isDraftLoaded) {
      _loadDraftData();
    }

    setState(() {
      cargando = false;
    });
  }

  // ✅ FUNCIÓN CORREGIDA: _loadDraftData sin errores de tipos
  void _loadDraftData() {
    try {
      print('📋 Cargando datos del borrador...');
      final data = widget.draftData!;
      
      nombreController.text = data['titulo'] ?? '';
      modalidadSeleccionada = data['modalidad'];
      campusSeleccionados = List<String>.from(data['campus'] ?? []);
      
      if (data['contenidos'] != null) {
        final contenidos = List<Map<String, dynamic>>.from(data['contenidos']);
        for (var contenido in contenidos) {
          final campo = contenido['campo'] as String;
          final lista = List<String>.from(contenido['contenidos'] ?? []);
          contenidosSeleccionadosPorCampo[campo] = lista;
        }
      }
      
      if (data['seleccionGrados'] != null) {
        final seleccionGrados = List<Map<String, dynamic>>.from(data['seleccionGrados']);
        for (var seleccion in seleccionGrados) {
          final campo = seleccion['campo'] as String;
          final gradosPorContenido = Map<String, dynamic>.from(seleccion['gradosPorContenido'] ?? {});
          
          seleccionGradosPorCampo[campo] = {};
          gradosSeleccionadosPorCampo[campo] = {};
          
          for (var contenidoEntry in gradosPorContenido.entries) {
            final contenido = contenidoEntry.key;
            final gradosData = Map<String, dynamic>.from(contenidoEntry.value);
            
            seleccionGradosPorCampo[campo]![contenido] = {};
            gradosSeleccionadosPorCampo[campo]![contenido] = <String>{};
            
            for (var gradoEntry in gradosData.entries) {
              final grado = gradoEntry.key;
              final elementos = List<String>.from(gradoEntry.value ?? []);
              
              if (elementos.isNotEmpty) {
                seleccionGradosPorCampo[campo]![contenido]![grado] = elementos;
                gradosSeleccionadosPorCampo[campo]![contenido]!.add(grado);
              }
            }
          }
        }
      }
      
      // ✅ MANEJO SEGURO DEL PASO - Soporta tanto int como string
      final pasoData = data['paso'];
      if (pasoData is int) {
        paso = pasoData;
        print('✅ Paso cargado como int: $paso');
      } else if (pasoData is String) {
        // Convertir string a int basado en el paso
        switch (pasoData.toLowerCase()) {
          case 'nombre':
          case 'titulo':
            paso = 0;
            break;
          case 'modalidad':
            paso = 1;
            break;
          case 'campus':
            paso = 2;
            break;
          case 'contenidos':
            paso = 3;
            break;
          case 'detallar':
            paso = 4;
            break;
          default:
            paso = _calculateCurrentStep();
        }
        print('✅ Paso convertido de string "$pasoData" a int: $paso');
      } else {
        paso = _calculateCurrentStep();
        print('✅ Paso calculado automáticamente: $paso');
      }
      
      // Cargar procesos si hay campus seleccionados
      if (campusSeleccionados.isNotEmpty) {
        cargarContenidosYProcesos(campusSeleccionados);
      }
      
      isDraftLoaded = true;
      print('✅ Datos del borrador cargados exitosamente');
      
    } catch (e) {
      print('❌ Error cargando datos del borrador: $e');
      paso = _calculateCurrentStep();
      isDraftLoaded = true;
    }
  }

  int _calculateCurrentStep() {
    if (nombreController.text.isEmpty) return 0;
    if (modalidadSeleccionada == null) return 1;
    if (campusSeleccionados.isEmpty) return 2;
    if (contenidosSeleccionadosPorCampo.isEmpty) return 3;
    return 4;
  }

  Future<void> _saveDraft() async {
    if (nombreController.text.isEmpty && 
        modalidadSeleccionada == null && 
        campusSeleccionados.isEmpty) {
      return;
    }

    final draftData = {
      'titulo': nombreController.text,
      'modalidad': modalidadSeleccionada,
      'campus': campusSeleccionados,
      'contenidos': contenidosSeleccionadosPorCampo.entries.map((entry) => {
        "campo": entry.key,
        "contenidos": entry.value,
      }).toList(),
      'seleccionGrados': seleccionGradosPorCampo.entries.map((campoEntry) => {
        "campo": campoEntry.key,
        "gradosPorContenido": campoEntry.value,
      }).toList(),
      'paso': paso, // ✅ Siempre será int
    };

    try {
      final savedDraftId = await DraftService.saveDraft(
        modalidad: modalidadSeleccionada ?? 'Sin modalidad',
        data: draftData,
        draftId: currentDraftId,
      );
      
      if (savedDraftId != null && currentDraftId == null) {
        currentDraftId = savedDraftId;
      }
    } catch (e) {
      print('Error guardando borrador: $e');
    }
  }

  void _mostrarTextoCompleto(String titulo, String texto) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            titulo,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cerrar',
                style: TextStyle(color: Colors.deepPurple),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> cargarContenidosYProcesos(
      List<String> campusSeleccionados) async {
    setState(() {
      cargando = true;
    });

    procesosPorCampo = {};
    if (campusSeleccionados.isNotEmpty) {
      final campusSnap = await FirebaseFirestore.instance
          .collection('campos')
          .where('nombre', whereIn: campusSeleccionados)
          .get();

      for (var doc in campusSnap.docs) {
        final data = doc.data();
        final nombreCampo = data['nombre'] as String;
        if (data['procesos_desarrollo'] != null &&
            data['procesos_desarrollo'] is List) {
          procesosPorCampo[nombreCampo] = List<Map<String, dynamic>>.from(
            data['procesos_desarrollo']
                .map((p) => Map<String, dynamic>.from(p)),
          );
        }
      }
    }

    setState(() {
      cargando = false;
    });
  }

  Future<void> guardarPlaneacion() async {
    final List<Map<String, dynamic>> contenidosList =
        contenidosSeleccionadosPorCampo.entries.map((entry) {
      return {
        "campo": entry.key,
        "contenidos": entry.value,
      };
    }).toList();

    final List<Map<String, dynamic>> seleccionGradosList =
        seleccionGradosPorCampo.entries.map((campoEntry) {
      return {
        "campo": campoEntry.key,
        "gradosPorContenido": campoEntry.value,
      };
    }).toList();

    final Map<String, dynamic> data = {
      "titulo": nombreController.text,
      "campus": campusSeleccionados,
      "modalidad": modalidadSeleccionada,
      "contenidos": contenidosList,
      "seleccionGrados": seleccionGradosList,
      "userId": FirebaseAuth.instance.currentUser?.uid,
      "fecha_creacion": FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('planeaciones').add(data);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Planeación guardada!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Column(
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Nueva Planeación',
                                style: TextStyle(
                                  fontSize: 28,
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
                              if (widget.draftData != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'BORRADOR',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'ComicNeue',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Configura tu planeación paso a paso',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontFamily: 'ComicNeue',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Cerrar',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    AnimatedSize(
                      duration: animDuration,
                      curve: Curves.easeInOut,
                      child: paso >= 0
                          ? OptionInputBlock(
                              label: 'Nombre de la planeación',
                              controller: nombreController,
                              hintText: 'Escribe el nombre...',
                              enabled: paso == 0,
                              onContinue: () {
                                if (nombreController.text.isNotEmpty) {
                                  setState(() => paso = 1);
                                  _saveDraft();
                                }
                              },
                              onBack: null,
                              onChanged: () => _saveDraft(),
                            )
                          : const SizedBox.shrink(),
                    ),
                    AnimatedSize(
                      duration: animDuration,
                      curve: Curves.easeInOut,
                      child: paso >= 1
                          ? OptionDropdownBlock(
                              label: 'Modalidad',
                              value: modalidadSeleccionada != null &&
                                      modalidades.contains(modalidadSeleccionada)
                                  ? modalidadSeleccionada
                                  : (modalidades.isNotEmpty
                                      ? modalidades.first
                                      : null),
                              items: modalidades,
                              enabled: paso == 1,
                              onChanged: (value) {
                                setState(() {
                                  modalidadSeleccionada = value;
                                });
                                _saveDraft();
                              },
                              onContinue: () {
                                if (modalidadSeleccionada == null &&
                                    modalidades.isNotEmpty) {
                                  setState(() {
                                    modalidadSeleccionada = modalidades.first;
                                    paso = 2;
                                  });
                                } else if (modalidadSeleccionada != null) {
                                  setState(() => paso = 2);
                                }
                                _saveDraft();
                              },
                              onBack: () {
                                setState(() => paso = 0);
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                    AnimatedSize(
                      duration: animDuration,
                      curve: Curves.easeInOut,
                      child: paso >= 2
                          ? OptionCampusMultiBlock(
                              campus: campus,
                              campusSeleccionados: campusSeleccionados,
                              enabled: paso == 2,
                              onCampusChanged: (value) async {
                                setState(() {
                                  campusSeleccionados = value;
                                  contenidosSeleccionadosPorCampo.clear();
                                  gradosSeleccionadosPorCampo.clear();
                                  seleccionGradosPorCampo.clear();
                                });
                                await cargarContenidosYProcesos(value);
                                _saveDraft();
                              },
                              onContinue: () {
                                if (campusSeleccionados.isNotEmpty) {
                                  setState(() => paso = 3);
                                  _saveDraft();
                                }
                              },
                              onBack: () {
                                setState(() => paso = 1);
                              },
                            )
                          : const SizedBox.shrink(),
                    ),
                    AnimatedSize(
                      duration: animDuration,
                      curve: Curves.easeInOut,
                      child: paso >= 3
                          ? OptionContenidoMultiBlock(
                              procesosPorCampo: procesosPorCampo,
                              contenidosSeleccionadosPorCampo:
                                  contenidosSeleccionadosPorCampo,
                              seleccionGradosPorCampo: seleccionGradosPorCampo,
                              gradosSeleccionadosPorCampo:
                                  gradosSeleccionadosPorCampo,
                              enabled: paso == 3,
                              onContenidoChanged: (campo, lista) {
                                setState(() {
                                  contenidosSeleccionadosPorCampo[campo] = lista;
                                  gradosSeleccionadosPorCampo[campo]
                                      ?.removeWhere((k, v) => !lista.contains(k));
                                  seleccionGradosPorCampo[campo]
                                      ?.removeWhere((k, v) => !lista.contains(k));
                                });
                                _saveDraft();
                              },
                              onGradosChanged: (campo, contenido, grados) {
                                setState(() {
                                  gradosSeleccionadosPorCampo.putIfAbsent(
                                      campo, () => {});
                                  gradosSeleccionadosPorCampo[campo]![contenido] =
                                      grados;
                                  seleccionGradosPorCampo.putIfAbsent(
                                      campo, () => {});
                                  seleccionGradosPorCampo[campo]!
                                      .putIfAbsent(contenido, () => {});
                                  seleccionGradosPorCampo[campo]![contenido]!
                                      .removeWhere((g, v) => !grados.contains(g));
                                });
                                _saveDraft();
                              },
                              onGradoChanged: (campo, contenido, grado, elementos) {
                                setState(() {
                                  seleccionGradosPorCampo.putIfAbsent(
                                      campo, () => {});
                                  seleccionGradosPorCampo[campo]!
                                      .putIfAbsent(contenido, () => {});
                                  seleccionGradosPorCampo[campo]![contenido]![grado] =
                                      elementos;
                                });
                                _saveDraft();
                              },
                              onContinue: () {
                                setState(() => paso = 4);
                                _saveDraft();
                              },
                              onBack: () {
                                setState(() => paso = 2);
                              },
                              onMostrarTextoCompleto: _mostrarTextoCompleto,
                            )
                          : const SizedBox.shrink(),
                    ),
                    AnimatedSize(
                      duration: animDuration,
                      curve: Curves.easeInOut,
                      child: paso >= 4
                          ? Padding(
                              padding: const EdgeInsets.only(top: 40.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() => paso = 3);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade300,
                                      foregroundColor: Colors.deepPurple,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 16),
                                      textStyle: const TextStyle(
                                        fontFamily: 'ComicNeue',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    child: const Text('Atrás'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      await guardarPlaneacion();
                                      
                                      // ✅ LÍNEA CORREGIDA: 
                                      if (currentDraftId != null) {
                                        await DraftService.markAsCompleted(currentDraftId!);
                                      }
                                      
                                      final List<Map<String, dynamic>>
                                          contenidosList =
                                          contenidosSeleccionadosPorCampo.entries
                                              .map((entry) {
                                        return {
                                          "campo": entry.key,
                                          "contenidos": entry.value,
                                        };
                                      }).toList();

                                      final List<Map<String, dynamic>>
                                          seleccionGradosList =
                                          seleccionGradosPorCampo.entries
                                              .map((campoEntry) {
                                        return {
                                          "campo": campoEntry.key,
                                          "gradosPorContenido": campoEntry.value,
                                        };
                                      }).toList();

                                      if (modalidadSeleccionada ==
                                          "Aprendizaje basado en el juego") {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DetallarABJPage(
                                              titulo: nombreController.text,
                                              campus: campusSeleccionados,
                                              contenidos: contenidosList,
                                              seleccionGrados: seleccionGradosList,
                                            ),
                                          ),
                                        );
                                      } else if (modalidadSeleccionada ==
                                          "Centros de interés") {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                DetallarCentrosInteresPage(
                                              titulo: nombreController.text,
                                              campus: campusSeleccionados,
                                              contenidos: contenidosList,
                                              seleccionGrados: seleccionGradosList,
                                            ),
                                          ),
                                        );
                                      } else if (modalidadSeleccionada ==
                                          "Taller crítico") {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DetallarTallerPage(
                                              titulo: nombreController.text,
                                              campus: campusSeleccionados,
                                              contenidos: contenidosList,
                                              seleccionGrados: seleccionGradosList,
                                            ),
                                          ),
                                        );
                                      } else if (modalidadSeleccionada ==
                                          "Proyecto") {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DetallarProyectoPage(
                                              titulo: nombreController.text,
                                              campus: campusSeleccionados,
                                              contenidos: contenidosList,
                                              seleccionGrados: seleccionGradosList,
                                            ),
                                          ),
                                        );
                                      } else if (modalidadSeleccionada ==
                                          "Unidad didáctica") {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DetallarUnidadPage(
                                              titulo: nombreController.text,
                                              campus: campusSeleccionados,
                                              contenidos: contenidosList,
                                              seleccionGrados: seleccionGradosList,
                                            ),
                                          ),
                                        );
                                      } else if (modalidadSeleccionada ==
                                          "Rincones de aprendizaje") {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DetallarRinconesPage(
                                              titulo: nombreController.text,
                                              campus: campusSeleccionados,
                                              contenidos: contenidosList,
                                              seleccionGrados: seleccionGradosList,
                                            ),
                                          ),
                                        );
                                      } else if (modalidadSeleccionada ==
                                          "Situacion Didactica") { // ✅ NUEVO CASE
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => DetallarSituacionPage(
                                              titulo: nombreController.text,
                                              campus: campusSeleccionados,
                                              contenidos: contenidosList,
                                              seleccionGrados: seleccionGradosList,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 16),
                                      textStyle: const TextStyle(
                                        fontFamily: 'ComicNeue',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    child: const Text('Detallar planeación'),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OptionInputBlock extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final VoidCallback? onChanged;

  const OptionInputBlock({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    required this.enabled,
    required this.onContinue,
    this.onBack,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
        opacity: enabled ? 1 : 0.6,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'ComicNeue',
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                enabled: enabled,
                onChanged: (value) => onChanged?.call(),
                decoration: InputDecoration(
                  hintText: hintText,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (onBack != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: enabled ? onBack : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.deepPurple,
                        ),
                        child: const Text('Atrás'),
                      ),
                    ),
                  if (onBack != null) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: enabled ? onContinue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Continuar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}

class OptionCampusMultiBlock extends StatelessWidget {
  final List<String> campus;
  final List<String> campusSeleccionados;
  final bool enabled;
  final ValueChanged<List<String>> onCampusChanged;
  final VoidCallback onContinue;
  final VoidCallback? onBack;

  const OptionCampusMultiBlock({
    super.key,
    required this.campus,
    required this.campusSeleccionados,
    required this.enabled,
    required this.onCampusChanged,
    required this.onContinue,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Campus',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'ComicNeue',
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: campus.map((c) {
                return CheckboxListTile(
                  title: Text(c),
                  value: campusSeleccionados.contains(c),
                  onChanged: (selected) {
                    final nuevaLista = List<String>.from(campusSeleccionados);
                    if (selected == true) {
                      nuevaLista.add(c);
                    } else {
                      nuevaLista.remove(c);
                    }
                    onCampusChanged(nuevaLista);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onBack != null)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: enabled ? onBack : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade300,
                        foregroundColor: Colors.deepPurple,
                      ),
                      child: const Text('Atrás'),
                    ),
                  ),
                if (onBack != null) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: enabled && campusSeleccionados.isNotEmpty
                        ? onContinue
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Continuar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class OptionContenidoMultiBlock extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> procesosPorCampo;
  final Map<String, List<String>> contenidosSeleccionadosPorCampo;
  final Map<String, Map<String, Map<String, List<String>>>>
      seleccionGradosPorCampo;
  final Map<String, Map<String, Set<String>>> gradosSeleccionadosPorCampo;
  final bool enabled;
  final void Function(String campo, List<String> contenidos) onContenidoChanged;
  final void Function(String campo, String contenido, Set<String> grados)
      onGradosChanged;
  final void Function(
          String campo, String contenido, String grado, List<String> elementos)
      onGradoChanged;
  final VoidCallback onContinue;
  final VoidCallback? onBack;
  final void Function(String titulo, String texto)? onMostrarTextoCompleto;

  const OptionContenidoMultiBlock({
    super.key,
    required this.procesosPorCampo,
    required this.contenidosSeleccionadosPorCampo,
    required this.seleccionGradosPorCampo,
    required this.gradosSeleccionadosPorCampo,
    required this.enabled,
    required this.onContenidoChanged,
    required this.onGradosChanged,
    required this.onGradoChanged,
    required this.onContinue,
    this.onBack,
    this.onMostrarTextoCompleto,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
        opacity: enabled ? 1 : 0.6,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...procesosPorCampo.entries.map((campoEntry) {
                final campo = campoEntry.key;
                final procesos = campoEntry.value;
                final contenidosSeleccionados =
                    contenidosSeleccionadosPorCampo[campo] ?? [];
                final seleccionGrados = seleccionGradosPorCampo[campo] ?? {};

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: procesos.map((proceso) {
                        final cont = proceso['contenido'] as String;
                        
                        return CheckboxListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(cont,
                                    maxLines: 2, overflow: TextOverflow.ellipsis),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, 
                                    color: Colors.deepPurple, size: 20),
                                onPressed: () => onMostrarTextoCompleto?.call('Contenido Completo', cont),
                                tooltip: 'Ver texto completo',
                              ),
                            ],
                          ),
                          value: contenidosSeleccionados.contains(cont),
                          onChanged: (selected) {
                            final nuevaLista =
                                List<String>.from(contenidosSeleccionados);
                            if (selected == true) {
                              nuevaLista.add(cont);
                            } else {
                              nuevaLista.remove(cont);
                            }
                            onContenidoChanged(campo, nuevaLista);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    ...contenidosSeleccionados.map((cont) {
                      final proceso = procesos.firstWhere(
                        (p) =>
                            (p['contenido'] as String)
                                .substring(0, 20)
                                .toLowerCase()
                                .trim() ==
                            cont.substring(0, 20).toLowerCase().trim(),
                        orElse: () => <String, dynamic>{
                          'grados': <String, List<String>>{}
                        },
                      );
                      final grados = Map<String, List<String>>.from(
                        (proceso['grados'] as Map).map(
                          (k, v) =>
                              MapEntry(k.toString(), List<String>.from(v)),
                        ),
                      );
                      final gradosSeleccionados =
                          gradosSeleccionadosPorCampo[campo]?[cont] ??
                              <String>{};
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cont,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                              fontSize: 16,
                            ),
                          ),
                          Wrap(
                            children: grados.keys.map((grado) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: gradosSeleccionados.contains(grado),
                                    onChanged: (selected) {
                                      final nuevos =
                                          Set<String>.from(gradosSeleccionados);
                                      if (selected == true) {
                                        nuevos.add(grado);
                                      } else {
                                        nuevos.remove(grado);
                                      }
                                      onGradosChanged(campo, cont, nuevos);
                                    },
                                  ),
                                  Text('Grado $grado'),
                                ],
                              );
                            }).toList(),
                          ),
                          ...grados.entries
                              .where((e) => gradosSeleccionados.contains(e.key))
                              .map((gradoEntry) {
                            final grado = gradoEntry.key;
                            final elementos = gradoEntry.value;
                            final seleccionados =
                                seleccionGrados[cont]?[grado] ?? [];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 8.0, bottom: 4.0),
                                  child: Text(
                                    'Elementos de Grado $grado',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple,
                                    ),
                                  ),
                                ),
                                ...elementos.map((el) {
                                  return CheckboxListTile(
                                    title: Text(el,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                    value: seleccionados.contains(el),
                                    onChanged: (selected) {
                                      final nuevaLista =
                                          List<String>.from(seleccionados);
                                      if (selected == true) {
                                        nuevaLista.add(el);
                                      } else {
                                        nuevaLista.remove(el);
                                      }
                                      onGradoChanged(
                                          campo, cont, grado, nuevaLista);
                                    },
                                  );
                                }).toList(),
                              ],
                            );
                          }).toList(),
                          const Divider(),
                        ],
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                  ],
                );
              }).toList(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (onBack != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: enabled ? onBack : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.deepPurple,
                        ),
                        child: const Text('Atrás'),
                      ),
                    ),
                  if (onBack != null) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: enabled &&
                              procesosPorCampo.keys.any((campo) =>
                                  (contenidosSeleccionadosPorCampo[campo] ?? [])
                                      .isNotEmpty)
                          ? onContinue
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Continuar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}

class OptionDropdownBlock extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final bool enabled;
  final ValueChanged<String?> onChanged;
  final VoidCallback onContinue;
  final VoidCallback? onBack;

  const OptionDropdownBlock({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.enabled,
    required this.onChanged,
    required this.onContinue,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
        opacity: enabled ? 1 : 0.6,
        child: IgnorePointer(
          ignoring: !enabled,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'ComicNeue',
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: value,
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: onChanged,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (onBack != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: enabled ? onBack : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.deepPurple,
                        ),
                        child: const Text('Atrás'),
                      ),
                    ),
                  if (onBack != null) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: enabled ? onContinue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Continuar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}

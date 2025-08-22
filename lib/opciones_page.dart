import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'detallar_abj_page.dart';
import 'detallar_centros_page.dart';
import 'detallar_taller.dart';
import 'detallar_proyecto.dart';
import 'detallar_unidad.dart';
import 'detallar_rincones.dart';

class OpcionesPage extends StatefulWidget {
  const OpcionesPage({super.key});

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

  final Duration animDuration = const Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
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

    setState(() {
      cargando = false;
    });
  }

  // Función para mostrar texto completo en un diálogo
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
          // ✅ HEADER CON DEGRADADO CORREGIDO
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0), // ✅ REDUCIDO EL PADDING
                child: Row(
                  children: [
                    // ✅ EXPANDIDO PARA EVITAR OVERFLOW
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nueva Planeación',
                            style: TextStyle(
                              fontSize: 28, // ✅ REDUCIDO DE 32 A 28
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
                          const SizedBox(height: 4), // ✅ ESPACIO PEQUEÑO
                          const Text(
                            'Configura tu planeación paso a paso',
                            style: TextStyle(
                              fontSize: 14, // ✅ REDUCIDO DE 16 A 14
                              color: Colors.white70,
                              fontFamily: 'ComicNeue',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ✅ ICONO X MÁS PEQUEÑO Y SIN PADDING EXTRA
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20, // ✅ REDUCIDO DE 28 A 20
                      ),
                      tooltip: 'Cerrar',
                      padding: EdgeInsets.zero, // ✅ ELIMINADO EL PADDING
                      constraints: const BoxConstraints(), // ✅ SIN RESTRICCIONES DE TAMAÑO
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ✅ RESTO DEL CONTENIDO SIN CONTENEDOR
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
                                }
                              },
                              onBack: null,
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
                              },
                              onContinue: () {
                                if (campusSeleccionados.isNotEmpty) {
                                  setState(() => paso = 3);
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
                              },
                              onContinue: () {
                                setState(() => paso = 4);
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
                                      }else if (modalidadSeleccionada ==
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

// Bloque para seleccionar campus
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

// Bloque para seleccionar contenidos, grados y elementos agrupado por campo
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

// Bloque para ingresar texto
class OptionInputBlock extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final VoidCallback onContinue;
  final VoidCallback? onBack;

  const OptionInputBlock({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    required this.enabled,
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
              TextField(
                controller: controller,
                enabled: enabled,
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

// Bloque para seleccionar modalidad
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

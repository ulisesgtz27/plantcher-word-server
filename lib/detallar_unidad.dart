import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/draft_service.dart';
import 'pages/visualizar_pdf_page.dart';

class DetallarUnidadPage extends StatefulWidget {
  final String titulo;
  final List<String> campus;
  final List<Map<String, dynamic>> contenidos;
  final List<Map<String, dynamic>> seleccionGrados;
  final bool isEditing;
  final String? planeacionId;
  final Map<String, dynamic>? draftData;
  final String? draftId;
  final Map<String, dynamic>? existingData; // ✅ NUEVO PARÁMETRO

  const DetallarUnidadPage({
    super.key,
    required this.titulo,
    required this.campus,
    required this.contenidos,
    required this.seleccionGrados,
    this.isEditing = false,
    this.planeacionId,
    this.draftData,
    this.draftId,
    this.existingData, // ✅ NUEVO PARÁMETRO
  });

  @override
  State<DetallarUnidadPage> createState() => _DetallarUnidadPageState();
}

class _DetallarUnidadPageState extends State<DetallarUnidadPage>
    with TickerProviderStateMixin {
  final TextEditingController propositoController = TextEditingController();
  final TextEditingController relevanciaController = TextEditingController();
  final TextEditingController lecturaRealidadController = TextEditingController();
  final TextEditingController identificacionTramaController = TextEditingController();
  final TextEditingController planificacionController = TextEditingController();
  final TextEditingController exploracionController = TextEditingController();
  final TextEditingController participacionController = TextEditingController();
  final TextEditingController conclusionController = TextEditingController();
  final TextEditingController variantesController = TextEditingController();

  DateTime? fechaInicio;
  DateTime? fechaFin;

  final List<String> materiales = [];
  final List<String> espacios = [];
  final List<String> produccion = [];

  final TextEditingController materialInput = TextEditingController();
  final TextEditingController espacioInput = TextEditingController();
  final TextEditingController produccionInput = TextEditingController();

  String? ejeSeleccionado;
  final List<String> ejes = [
    "Inclusión",
    "Pensamiento crítico",
    "Interculturalidad crítica",
    "Igualdad de género",
    "Vida saludable",
    "Apropiación de las culturas a través de la lectura y la escritura",
    "Artes y experiencias estéticas"
  ];

  final Map<String, TextEditingController> relacionPorCampo = {};

  String? currentDraftId;
  bool isDraftLoaded = false;

  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    currentDraftId = widget.draftId;
    
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeInOut),
    );
    
    _fadeAnimationController.forward();
    
    for (final campo in widget.campus) {
      relacionPorCampo[campo] = TextEditingController();
    }
    
    // ✅ MODIFICADO: Priorizar existingData sobre draftData
    if (widget.existingData != null) {
      _loadExistingData();
    } else if (widget.draftData != null && !isDraftLoaded) {
      _loadDraftData();
    } else if (widget.isEditing && widget.planeacionId != null) {
      _cargarDatosExistentes();
    }
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    propositoController.dispose();
    relevanciaController.dispose();
    lecturaRealidadController.dispose();
    identificacionTramaController.dispose();
    planificacionController.dispose();
    exploracionController.dispose();
    participacionController.dispose();
    conclusionController.dispose();
    variantesController.dispose();
    materialInput.dispose();
    espacioInput.dispose();
    produccionInput.dispose();
    for (final controller in relacionPorCampo.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // ✅ NUEVA FUNCIÓN: Cargar datos existentes pasados desde planeaciones_list_page
  void _loadExistingData() {
    try {
      print('📋 Cargando datos existentes en Unidad...');
      final data = widget.existingData!;
      
      setState(() {
        // Cargar datos básicos
        propositoController.text = data['proposito'] ?? '';
        relevanciaController.text = data['relevancia_social'] ?? '';
        ejeSeleccionado = data['eje_articulador'];
        
        // Cargar fechas desde periodo_aplicacion si existe
        if (data['periodo_aplicacion'] != null) {
          String periodo = data['periodo_aplicacion'].toString();
          _parseFechasFromPeriodo(periodo);
        }
        
        // Cargar momentos específicos de Unidad Didáctica
        if (data['momentos'] != null) {
          final momentos = Map<String, dynamic>.from(data['momentos']);
          lecturaRealidadController.text = momentos['lectura_realidad'] ?? '';
          identificacionTramaController.text = momentos['identificacion_trama'] ?? '';
          planificacionController.text = momentos['planificacion'] ?? '';
          exploracionController.text = momentos['exploracion'] ?? '';
          participacionController.text = momentos['participacion'] ?? '';
          conclusionController.text = momentos['conclusion'] ?? '';
          variantesController.text = momentos['posibles_variantes'] ?? '';
        }
        
        // Cargar listas
        if (data['materiales'] != null) {
          materiales.clear();
          materiales.addAll(List<String>.from(data['materiales']));
        }
        if (data['espacios'] != null) {
          espacios.clear();
          espacios.addAll(List<String>.from(data['espacios']));
        }
        if (data['produccion_sugerida'] != null) {
          produccion.clear();
          produccion.addAll(List<String>.from(data['produccion_sugerida']));
        }
        
        // Cargar relación de contenidos
        if (data['relacion_contenidos'] != null) {
          final relaciones = Map<String, dynamic>.from(data['relacion_contenidos']);
          relaciones.forEach((campo, texto) {
            if (relacionPorCampo[campo] != null) {
              relacionPorCampo[campo]!.text = texto ?? '';
            }
          });
        }
      });
      
      isDraftLoaded = true;
      print('✅ Datos existentes cargados en Unidad');
      
    } catch (e) {
      print('❌ Error cargando datos existentes en Unidad: $e');
      isDraftLoaded = true;
    }
  }

  // ✅ FUNCIÓN AUXILIAR: Parsear fechas desde el texto del periodo
  void _parseFechasFromPeriodo(String periodo) {
    try {
      // Ejemplo de periodo: "15 de marzo de 2024 - 30 de abril de 2024"
      final partes = periodo.split(' - ');
      if (partes.length == 2) {
        fechaInicio = _parseFechaTexto(partes[0].trim());
        fechaFin = _parseFechaTexto(partes[1].trim());
      }
    } catch (e) {
      print('Error parseando fechas del periodo: $e');
    }
  }

  // ✅ FUNCIÓN AUXILIAR: Parsear una fecha individual
  DateTime? _parseFechaTexto(String fechaTexto) {
    try {
      // Ejemplo: "15 de marzo de 2024"
      final meses = {
        'enero': 1, 'febrero': 2, 'marzo': 3, 'abril': 4,
        'mayo': 5, 'junio': 6, 'julio': 7, 'agosto': 8,
        'septiembre': 9, 'octubre': 10, 'noviembre': 11, 'diciembre': 12
      };
      
      final partes = fechaTexto.split(' de ');
      if (partes.length == 3) {
        final dia = int.tryParse(partes[0]);
        final mesNombre = partes[1].toLowerCase();
        final anio = int.tryParse(partes[2]);
        
        if (dia != null && anio != null && meses.containsKey(mesNombre)) {
          return DateTime(anio, meses[mesNombre]!, dia);
        }
      }
    } catch (e) {
      print('Error parseando fecha individual: $e');
    }
    return null;
  }

  // ✅ FUNCIÓN EXISTENTE: Cargar datos del borrador
  void _loadDraftData() {
    try {
      print('📋 Cargando datos del borrador en Unidad...');
      final data = widget.draftData!;
      
      setState(() {
        // Cargar datos básicos
        propositoController.text = data['proposito'] ?? '';
        relevanciaController.text = data['relevancia_social'] ?? '';
        ejeSeleccionado = data['eje_articulador'];
        
        // Cargar fechas si existen
        if (data['fecha_inicio'] != null) {
          if (data['fecha_inicio'] is String) {
            fechaInicio = DateTime.tryParse(data['fecha_inicio']);
          } else if (data['fecha_inicio'] is Timestamp) {
            fechaInicio = (data['fecha_inicio'] as Timestamp).toDate();
          }
        }
        if (data['fecha_fin'] != null) {
          if (data['fecha_fin'] is String) {
            fechaFin = DateTime.tryParse(data['fecha_fin']);
          } else if (data['fecha_fin'] is Timestamp) {
            fechaFin = (data['fecha_fin'] as Timestamp).toDate();
          }
        }
        
        // Cargar momentos específicos de Unidad Didáctica
        if (data['momentos'] != null) {
          final momentos = Map<String, dynamic>.from(data['momentos']);
          lecturaRealidadController.text = momentos['lectura_realidad'] ?? '';
          identificacionTramaController.text = momentos['identificacion_trama'] ?? '';
          planificacionController.text = momentos['planificacion'] ?? '';
          exploracionController.text = momentos['exploracion'] ?? '';
          participacionController.text = momentos['participacion'] ?? '';
          conclusionController.text = momentos['conclusion'] ?? '';
          variantesController.text = momentos['posibles_variantes'] ?? '';
        }
        
        // Cargar listas
        if (data['materiales'] != null) {
          materiales.clear();
          materiales.addAll(List<String>.from(data['materiales']));
        }
        if (data['espacios'] != null) {
          espacios.clear();
          espacios.addAll(List<String>.from(data['espacios']));
        }
        if (data['produccion_sugerida'] != null) {
          produccion.clear();
          produccion.addAll(List<String>.from(data['produccion_sugerida']));
        }
        
        // Cargar relación de contenidos
        if (data['relacion_contenidos'] != null) {
          final relaciones = Map<String, dynamic>.from(data['relacion_contenidos']);
          relaciones.forEach((campo, texto) {
            if (relacionPorCampo[campo] != null) {
              relacionPorCampo[campo]!.text = texto ?? '';
            }
          });
        }
      });
      
      isDraftLoaded = true;
      print('✅ Datos del borrador cargados en Unidad');
      
    } catch (e) {
      print('❌ Error cargando datos del borrador en Unidad: $e');
      isDraftLoaded = true;
    }
  }

  // ✅ FUNCIÓN EXISTENTE: Guardar borrador
  Future<void> _saveDraft() async {
    final draftData = {
      'titulo': widget.titulo,
      'modalidad': 'Unidad Didáctica',
      'campus': widget.campus,
      'contenidos': widget.contenidos,
      'seleccionGrados': widget.seleccionGrados,
      // Campos específicos de Unidad Didáctica
      'proposito': propositoController.text,
      'relevancia_social': relevanciaController.text,
      'eje_articulador': ejeSeleccionado,
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'momentos': {
        'lectura_realidad': lecturaRealidadController.text,
        'identificacion_trama': identificacionTramaController.text,
        'planificacion': planificacionController.text,
        'exploracion': exploracionController.text,
        'participacion': participacionController.text,
        'conclusion': conclusionController.text,
        'posibles_variantes': variantesController.text,
      },
      'materiales': materiales,
      'espacios': espacios,
      'produccion_sugerida': produccion,
      'relacion_contenidos': {
        for (final campo in widget.campus)
          campo: relacionPorCampo[campo]?.text ?? ""
      },
    };

    try {
      final savedDraftId = await DraftService.saveDraft(
        modalidad: 'Unidad Didáctica',
        data: draftData,
        draftId: currentDraftId,
        tipoPagina: 'modalidad',
      );
      
      if (savedDraftId != null && currentDraftId == null) {
        currentDraftId = savedDraftId;
      }
    } catch (e) {
      print('Error guardando borrador Unidad: $e');
    }
  }

  Future<void> _cargarDatosExistentes() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('detalles_unidad')
          .doc(widget.planeacionId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        setState(() {
          propositoController.text = data['proposito'] ?? '';
          relevanciaController.text = data['relevancia_social'] ?? '';
          ejeSeleccionado = data['eje_articulador'];
          
          // Cargar fechas desde periodo_aplicacion si existe
          if (data['periodo_aplicacion'] != null) {
            String periodo = data['periodo_aplicacion'].toString();
            _parseFechasFromPeriodo(periodo);
          }
          
          if (data['momentos'] != null) {
            final momentos = data['momentos'] as Map<String, dynamic>;
            lecturaRealidadController.text = momentos['lectura_realidad'] ?? '';
            identificacionTramaController.text = momentos['identificacion_trama'] ?? '';
            planificacionController.text = momentos['planificacion'] ?? '';
            exploracionController.text = momentos['exploracion'] ?? '';
            participacionController.text = momentos['participacion'] ?? '';
            conclusionController.text = momentos['conclusion'] ?? '';
            variantesController.text = momentos['posibles_variantes'] ?? '';
          }
          
          if (data['materiales'] != null) {
            materiales.clear();
            materiales.addAll(List<String>.from(data['materiales']));
          }
          if (data['espacios'] != null) {
            espacios.clear();
            espacios.addAll(List<String>.from(data['espacios']));
          }
          if (data['produccion_sugerida'] != null) {
            produccion.clear();
            produccion.addAll(List<String>.from(data['produccion_sugerida']));
          }
          
          if (data['relacion_contenidos'] != null) {
            final relaciones = data['relacion_contenidos'] as Map<String, dynamic>;
            relaciones.forEach((campo, texto) {
              if (relacionPorCampo[campo] != null) {
                relacionPorCampo[campo]!.text = texto ?? '';
              }
            });
          }
        });
      }
    } catch (e) {
      print('Error al cargar datos existentes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos: $e'),
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  String get periodoAplicacionTexto {
    if (fechaInicio == null || fechaFin == null) return '';
    final meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    String format(DateTime d) =>
        '${d.day} de ${meses[d.month - 1]} de ${d.year}';
    return '${format(fechaInicio!)} - ${format(fechaFin!)}';
  }

  // ✅ FUNCIÓN MODIFICADA: Mejorar guardarDetalleUnidad
  Future<void> guardarDetalleUnidad() async {
    final Map<String, dynamic> data = {
      "titulo": widget.titulo,
      "campos_formativos": widget.campus,
      "contenidos": _getContenidos(),
      "procesos_desarrollo": widget.seleccionGrados,
      "proposito": propositoController.text,
      "relevancia_social": relevanciaController.text,
      "relacion_contenidos": {
        for (final campo in widget.campus)
          campo: relacionPorCampo[campo]?.text ?? ""
      },
      "eje_articulador": ejeSeleccionado,
      "periodo_aplicacion": periodoAplicacionTexto,
      "momentos": {
        "lectura_realidad": lecturaRealidadController.text,
        "identificacion_trama": identificacionTramaController.text,
        "planificacion": planificacionController.text,
        "exploracion": exploracionController.text,
        "participacion": participacionController.text,
        "conclusion": conclusionController.text,
        "posibles_variantes": variantesController.text,
      },
      "materiales": materiales,
      "espacios": espacios,
      "produccion_sugerida": produccion,
      "fecha_creacion": FieldValue.serverTimestamp(),
    };

    try {
      if (widget.isEditing && widget.planeacionId != null) {
        // ✅ MODO EDICIÓN: Actualizar documento existente
        await FirebaseFirestore.instance
            .collection('detalles_unidad')
            .doc(widget.planeacionId)
            .set(data, SetOptions(merge: false));
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '¡Detalle actualizado correctamente!',
              style: TextStyle(fontFamily: 'ComicNeue'),
            ),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } else {
        // ✅ MODO CREACIÓN: Crear nuevo documento
        DocumentReference docRef = await FirebaseFirestore.instance
            .collection('detalles_unidad')
            .add(data);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '¡Detalle guardado correctamente!',
              style: TextStyle(fontFamily: 'ComicNeue'),
            ),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        print('✅ Nuevo documento creado con ID: ${docRef.id}');
      }

      // ✅ MARCAR BORRADOR COMO COMPLETADO
      if (currentDraftId != null) {
        await DraftService.markAsCompleted(currentDraftId!);
      }
    } catch (e) {
      print('❌ Error guardando detalle de unidad: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al guardar: $e',
            style: const TextStyle(fontFamily: 'ComicNeue'),
          ),
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _visualizarPDF() {
    final momentos = {
      'lectura_realidad': lecturaRealidadController.text,
      'identificacion_trama': identificacionTramaController.text,
      'planificacion': planificacionController.text,
      'exploracion': exploracionController.text,
      'participacion': participacionController.text,
      'conclusion': conclusionController.text,
    };

    final Map<String, String> relacionContenidos = {
      for (final campo in widget.campus)
        campo: relacionPorCampo[campo]?.text ?? ""
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisualizarPDFPage(
          modalidad: 'Unidad Didáctica',
          pdfFileName: 'planeacion_unidad.pdf',
          wordFileName: 'planeacion_unidad.docx',
          titulo: widget.titulo,
          periodoAplicacion: periodoAplicacionTexto,
          proposito: propositoController.text,
          relevanciaSocial: relevanciaController.text,
          produccionSugerida: produccion,
          camposFormativos: widget.campus,
          contenidos: _getContenidos(),
          procesosDesarrollo: widget.seleccionGrados,
          relacionContenidos: relacionContenidos,
          ejeArticulador: ejeSeleccionado ?? '',
          momentos: momentos,
          posiblesVariantes: variantesController.text,
          materiales: materiales,
          espacios: espacios,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4A148C),
                  Color(0xFF6A1B9A),
                  Color(0xFF8E24AA),
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
                              Text(
                                widget.isEditing 
                                    ? 'Editar Unidad' 
                                    : 'Unidad Didáctica',
                                style: const TextStyle(
                                  fontSize: 26,
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
                              // ✅ NUEVO: Indicador de borrador
                              if (widget.draftData != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'BORRADOR',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 7,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'ComicNeue',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.titulo,
                            style: const TextStyle(
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
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _seccionContenedor([
                        _titulo('Periodo de Aplicación'),
                        Row(
                          children: [
                            Expanded(
                              child: _fechaSelector(
                                'Selecciona fecha de inicio',
                                fechaInicio,
                                (picked) {
                                  setState(() => fechaInicio = picked);
                                  _saveDraft();
                                },
                                'Inicio',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _fechaSelector(
                                'Selecciona fecha de cierre',
                                fechaFin,
                                (picked) {
                                  setState(() => fechaFin = picked);
                                  _saveDraft();
                                },
                                'Cierre',
                              ),
                            ),
                          ],
                        ),
                        if (fechaInicio != null && fechaFin != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              periodoAplicacionTexto,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF4A148C),
                              ),
                            ),
                          ),
                      ]),
                      
                      _seccionContenedor([
                        _titulo('Propósito'),
                        _input(propositoController, 'Escribe el propósito...'),
                      ]),
                      
                      _seccionContenedor([
                        _titulo('Relevancia Social'),
                        _input(relevanciaController, 'Describe la relevancia social...'),
                      ]),
                      
                      _seccionContenedor([
                        _titulo('Campos Formativos'),
                        _infoList(widget.campus),
                      ]),
                      
                      _seccionContenedor([
                        _titulo('Contenidos'),
                        _infoList(_getContenidos()),
                      ]),
                      
                      _seccionContenedor([
                        _titulo('Procesos de Desarrollo y Aprendizaje'),
                        _procesosDesarrollo(),
                      ]),
                      
                      _seccionContenedor([
                        _titulo('Relación entre los contenidos curriculares'),
                        ...widget.campus.map((campo) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                campo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A148C),
                                  fontFamily: 'ComicNeue',
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: relacionPorCampo[campo],
                                minLines: 1,
                                maxLines: 4,
                                style: const TextStyle(fontFamily: 'ComicNeue'),
                                onChanged: (value) => _saveDraft(),
                                decoration: InputDecoration(
                                  hintText: 'Describe la relación para $campo...',
                                  hintStyle: const TextStyle(fontFamily: 'ComicNeue'),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: const Color(0xFF4A148C).withOpacity(0.3)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: const Color(0xFF4A148C).withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF4A148C), width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ]),
                      
                      _seccionContenedor([
                        _titulo('Eje articulador'),
                        DropdownButtonFormField<String>(
                          value: ejeSeleccionado,
                          hint: const Text(
                            'Selecciona un eje articulador',
                            style: TextStyle(
                              fontFamily: 'ComicNeue',
                              color: Colors.grey,
                            ),
                          ),
                          isExpanded: true,
                          items: ejes
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(
                                    e,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: const TextStyle(
                                      fontFamily: 'ComicNeue',
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() => ejeSeleccionado = v);
                            _saveDraft();
                          },
                          style: const TextStyle(
                            fontFamily: 'ComicNeue',
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Selecciona un eje articulador',
                            hintStyle: const TextStyle(
                              fontFamily: 'ComicNeue',
                              color: Colors.grey,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: const Color(0xFF4A148C).withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: const Color(0xFF4A148C).withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF4A148C), width: 2),
                            ),
                          ),
                          dropdownColor: Colors.white,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF4A148C),
                          ),
                        ),
                      ]),
                      
                      _seccionContenedor([
                        _titulo('Momentos'),
                        _subtitulo('1. Lectura de la realidad'),
                        _input(lecturaRealidadController, 'Describe la lectura de la realidad...'),
                        _subtitulo('2. Identificación de la trama y complejidad'),
                        _input(identificacionTramaController, 'Describe la identificación de la trama y complejidad...'),
                        _subtitulo('3. Planificación y organización del trabajo'),
                        _input(planificacionController, 'Describe la planificación y organización del trabajo...'),
                        _subtitulo('4. Exploración y descubrimiento'),
                        _input(exploracionController, 'Describe la exploración y descubrimiento...'),
                        _subtitulo('5. Participación activa y horizontal'),
                        _input(participacionController, 'Describe la participación activa y horizontal...'),
                        _subtitulo('6. Conclusión de la experiencia (Valoración)'),
                        _input(conclusionController, 'Describe la conclusión de la experiencia...'),
                        _subtitulo('Posibles variantes'),
                        _input(variantesController, 'Describe posibles variantes...'),
                      ]),
                      
                      _seccionContenedor([
                        _titulo('Materiales'),
                        _listaEditable(materiales, materialInput, 'Agregar material'),
                      ]),
                      
                      _seccionContenedor([
                        _titulo('Espacios'),
                        _listaEditable(espacios, espacioInput, 'Agregar espacio'),
                      ]),
                      
                      _seccionContenedor([
                        _titulo('Producción sugerida'),
                        _listaEditable(produccion, produccionInput, 'Agregar producción'),
                      ]),
                      
                      const SizedBox(height: 32),
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            final result = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                title: Text(
                                  widget.isEditing 
                                      ? '¿Deseas actualizar la planeación?' 
                                      : '¿Deseas guardar la planeación?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4A148C),
                                    fontFamily: 'ComicNeue',
                                  ),
                                ),
                                content: Text(
                                  widget.isEditing 
                                      ? 'Se actualizarán todos los cambios realizados.'
                                      : 'Una vez dado al botón de Sí no podrás cambiar nada.',
                                  style: const TextStyle(fontFamily: 'ComicNeue'),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text(
                                      'No',
                                      style: TextStyle(
                                        color: Color(0xFF4A148C),
                                        fontFamily: 'ComicNeue',
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4A148C),
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(fontFamily: 'ComicNeue'),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    child: const Text('Sí'),
                                  ),
                                ],
                              ),
                            );
                            if (result == true) {
                              await guardarDetalleUnidad();
                              _visualizarPDF();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A148C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            textStyle: const TextStyle(
                              fontFamily: 'ComicNeue',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(widget.isEditing 
                              ? 'Actualizar y Visualizar PDF' 
                              : 'Visualizar PDF'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccionContenedor(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
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
          color: const Color(0xFF4A148C).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _fechaSelector(String hint, DateTime? fecha, Function(DateTime) onSelected, String prefix) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: fecha ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          onSelected(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF4A148C).withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          fecha == null
              ? hint
              : '$prefix: ${fecha.day} de ${_mes(fecha.month)} de ${fecha.year}',
          style: TextStyle(
            fontSize: 14,
            color: fecha == null ? Colors.grey : Colors.black,
            fontFamily: 'ComicNeue',
          ),
        ),
      ),
    );
  }

  String _mes(int mes) {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return meses[mes - 1];
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          t,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color(0xFF4A148C),
            fontFamily: 'ComicNeue',
          ),
        ),
      );

  Widget _subtitulo(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          t,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'ComicNeue',
          ),
        ),
      );

  Widget _input(TextEditingController c, String hint) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: c,
          minLines: 1,
          maxLines: 4,
          style: const TextStyle(fontFamily: 'ComicNeue'),
          onChanged: (value) => _saveDraft(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontFamily: 'ComicNeue'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFF4A148C).withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFF4A148C).withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4A148C), width: 2),
            ),
          ),
        ),
      );

  Widget _infoList(List<String> items) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(
                            fontSize: 18,
                            color: Color(0xFF4A148C),
                            fontFamily: 'ComicNeue',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e,
                            style: const TextStyle(fontFamily: 'ComicNeue'),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      );

  Widget _procesosDesarrollo() {
    List<Widget> widgets = [];
    for (final campo in widget.seleccionGrados) {
      final campoNombre = campo['campo'];
      final gradosPorContenido = campo['gradosPorContenido'] as Map<String, dynamic>;
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(
          campoNombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A148C),
            fontFamily: 'ComicNeue',
          ),
        ),
      ));
      gradosPorContenido.forEach((contenido, grados) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, top: 2),
          child: Text(
            contenido,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'ComicNeue',
            ),
          ),
        ));
        (grados as Map<String, dynamic>).forEach((grado, elementos) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(left: 24, top: 2),
            child: Text(
              'Grado $grado:',
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                fontFamily: 'ComicNeue',
              ),
            ),
          ));
          for (final el in (elementos as List)) {
            widgets.add(Padding(
              padding: const EdgeInsets.only(left: 36, top: 1),
              child: Text(
                '• $el',
                style: const TextStyle(fontFamily: 'ComicNeue'),
              ),
            ));
          }
        });
      });
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets),
    );
  }

  Widget _listaEditable(List<String> lista, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...lista.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF4A148C),
                      fontFamily: 'ComicNeue',
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e,
                      style: const TextStyle(fontFamily: 'ComicNeue'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      size: 18,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      setState(() => lista.remove(e));
                      _saveDraft();
                    },
                  )
                ],
              ),
            )),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(fontFamily: 'ComicNeue'),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(fontFamily: 'ComicNeue'),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF4A148C).withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF4A148C).withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF4A148C), width: 2),
                  ),
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    setState(() {
                      lista.add(v.trim());
                      controller.clear();
                    });
                    _saveDraft();
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.add_circle,
                color: Color(0xFF4A148C),
              ),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    lista.add(controller.text.trim());
                    controller.clear();
                  });
                  _saveDraft();
                }
              },
            )
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  List<String> _getContenidos() {
    List<String> result = [];
    for (final c in widget.contenidos) {
      if (c['contenidos'] != null && c['contenidos'] is List) {
        result.addAll(List<String>.from(c['contenidos']));
      }
    }
    return result;
  }
}
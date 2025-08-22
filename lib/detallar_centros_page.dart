import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/visualizar_pdf_page.dart';

class DetallarCentrosInteresPage extends StatefulWidget {
  final String titulo;
  final List<String> campus;
  final List<Map<String, dynamic>> contenidos;
  final List<Map<String, dynamic>> seleccionGrados;
  final bool isEditing;
  final String? planeacionId;

  const DetallarCentrosInteresPage({
    super.key,
    required this.titulo,
    required this.campus,
    required this.contenidos,
    required this.seleccionGrados,
    this.isEditing = false,
    this.planeacionId,
  });

  @override
  State<DetallarCentrosInteresPage> createState() =>
      _DetallarCentrosInteresPageState();
}

class _DetallarCentrosInteresPageState extends State<DetallarCentrosInteresPage>
    with TickerProviderStateMixin {
  final TextEditingController propositoController = TextEditingController();
  final TextEditingController relevanciaController = TextEditingController();
  final TextEditingController planteamientoController = TextEditingController();
  final TextEditingController contactoRealidadController = TextEditingController();
  final TextEditingController identificacionIntegracionController = TextEditingController();
  final TextEditingController expresionController = TextEditingController();
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
  // ✅ CORREGIDO - Lista de ejes con acentos y sin errores tipográficos
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

  // ✅ AGREGADO - Controladores de animación
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // ✅ AGREGADO - Inicializar animación
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
    
    if (widget.isEditing && widget.planeacionId != null) {
      _cargarDatosExistentes();
    }
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosExistentes() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('detalles_centros_interes')
          .doc(widget.planeacionId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        setState(() {
          propositoController.text = data['proposito'] ?? '';
          relevanciaController.text = data['relevancia_social'] ?? '';
          ejeSeleccionado = data['eje_articulador'];
          
          if (data['momentos'] != null) {
            final momentos = data['momentos'] as Map<String, dynamic>;
            contactoRealidadController.text = momentos['contacto_realidad'] ?? '';
            identificacionIntegracionController.text = momentos['identificacion_integracion'] ?? '';
            expresionController.text = momentos['expresion'] ?? '';
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

  Future<void> guardarDetalleCentrosInteres() async {
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
        "contacto_realidad": contactoRealidadController.text,
        "identificacion_integracion": identificacionIntegracionController.text,
        "expresion": expresionController.text,
        "posibles_variantes": variantesController.text,
      },
      "materiales": materiales,
      "espacios": espacios,
      "produccion_sugerida": produccion,
      "fecha_creacion": FieldValue.serverTimestamp(),
    };

    if (widget.isEditing && widget.planeacionId != null) {
      await FirebaseFirestore.instance
          .collection('detalles_centros_interes')
          .doc(widget.planeacionId)
          .update(data);
      
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
      await FirebaseFirestore.instance
          .collection('detalles_centros_interes')
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
    }
  }

  void _visualizarPDF() {
    final momentos = {
      'contacto_realidad': contactoRealidadController.text,
      'identificacion_integracion': identificacionIntegracionController.text,
      'expresion': expresionController.text,
    };

    final Map<String, String> relacionContenidos = {
      for (final campo in widget.campus)
        campo: relacionPorCampo[campo]?.text ?? ""
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisualizarPDFPage(
          modalidad: 'Centros de Interés',
          pdfFileName: 'planeacion_centros_interes.pdf',
          wordFileName: 'planeacion_centros_interes.docx',
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
          // ✅ HEADER CON DEGRADADO VERDE
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1B5E20), // Verde profundo
                  Color(0xFF2E7D32), // Verde medio
                  Color(0xFF4CAF50), // Verde claro
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
                          Text(
                            widget.isEditing 
                                ? 'Editar Centros de Interés' 
                                : 'Centros de Interés',
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

          // ✅ CONTENIDO PRINCIPAL CON ANIMACIÓN
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
                                (picked) => setState(() => fechaInicio = picked),
                                'Inicio',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _fechaSelector(
                                'Selecciona fecha de cierre',
                                fechaFin,
                                (picked) => setState(() => fechaFin = picked),
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
                                color: Color(0xFF1B5E20),
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
                                  color: Color(0xFF1B5E20),
                                  fontFamily: 'ComicNeue',
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: relacionPorCampo[campo],
                                minLines: 1,
                                maxLines: 4,
                                style: const TextStyle(fontFamily: 'ComicNeue'),
                                decoration: InputDecoration(
                                  hintText: 'Describe la relación para $campo...',
                                  hintStyle: const TextStyle(fontFamily: 'ComicNeue'),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: const Color(0xFF1B5E20).withOpacity(0.3)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: const Color(0xFF1B5E20).withOpacity(0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ]),
                      
                      // ✅ CORREGIDO - Dropdown del Eje articulador
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
                                    maxLines: 2, // ✅ CAMBIADO - Permitir más líneas
                                    style: const TextStyle(
                                      fontFamily: 'ComicNeue',
                                      fontSize: 14, // ✅ AGREGADO - Tamaño específico
                                      color: Colors.black87, // ✅ AGREGADO - Color específico
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => ejeSeleccionado = v),
                          style: const TextStyle(
                            fontFamily: 'ComicNeue',
                            color: Colors.black87, // ✅ AGREGADO - Color del texto seleccionado
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Selecciona un eje articulador', // ✅ AGREGADO - Hint en decoration
                            hintStyle: const TextStyle(
                              fontFamily: 'ComicNeue',
                              color: Colors.grey,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // ✅ AGREGADO - Padding interno
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: const Color(0xFF1B5E20).withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: const Color(0xFF1B5E20).withOpacity(0.3)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2),
                            ),
                          ),
                          dropdownColor: Colors.white, // ✅ AGREGADO - Color de fondo del dropdown
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF1B5E20),
                          ), // ✅ AGREGADO - Icono personalizado con color verde
                        ),
                      ]),
                      
                      _seccionContenedor([
                        _titulo('Momentos'),
                        _subtitulo('1. En contacto de la realidad'),
                        _input(contactoRealidadController, 'Describe el contacto de la realidad...'),
                        _subtitulo('2. Identificación e integración'),
                        _input(identificacionIntegracionController, 'Describe la identificación e integración...'),
                        _subtitulo('3. Expresión'),
                        _input(expresionController, 'Describe la expresión...'),
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
                                    color: Color(0xFF1B5E20),
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
                                        color: Color(0xFF1B5E20),
                                        fontFamily: 'ComicNeue',
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B5E20),
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
                              await guardarDetalleCentrosInteres();
                              _visualizarPDF();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B5E20),
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
          color: const Color(0xFF1B5E20).withOpacity(0.2),
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
          border: Border.all(color: const Color(0xFF1B5E20).withOpacity(0.3)),
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
            color: Color(0xFF1B5E20),
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
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontFamily: 'ComicNeue'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFF1B5E20).withOpacity(0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFF1B5E20).withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2),
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
                            color: Color(0xFF1B5E20),
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
            color: Color(0xFF1B5E20),
            fontFamily: 'ComicNeue',
            fontSize: 16,
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
                      color: Color(0xFF1B5E20),
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
                    borderSide: BorderSide(color: const Color(0xFF1B5E20).withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFF1B5E20).withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 2),
                  ),
                ),
                onSubmitted: (v) {
                  if (v.trim().isNotEmpty) {
                    setState(() {
                      lista.add(v.trim());
                      controller.clear();
                    });
                  }
                },
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.add_circle,
                color: Color(0xFF1B5E20),
              ),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    lista.add(controller.text.trim());
                    controller.clear();
                  });
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
      final List<dynamic> lista = c['contenidos'];
      result.addAll(lista.map((e) => e.toString()));
    }
    return result;
  }
}

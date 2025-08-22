import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/visualizar_pdf_page.dart';

class DetallarProyectoPage extends StatefulWidget {
  final String titulo;
  final List<String> campus;
  final List<Map<String, dynamic>> contenidos;
  final List<Map<String, dynamic>> seleccionGrados;
  final bool isEditing;
  final String? planeacionId;

  const DetallarProyectoPage({
    super.key,
    required this.titulo,
    required this.campus,
    required this.contenidos,
    required this.seleccionGrados,
    this.isEditing = false,
    this.planeacionId,
  });

  @override
  State<DetallarProyectoPage> createState() => _DetallarProyectoPageState();
}

class _DetallarProyectoPageState extends State<DetallarProyectoPage> {
  final TextEditingController propositoController = TextEditingController();
  final TextEditingController relevanciaController = TextEditingController();
  final TextEditingController puntoPartidaController = TextEditingController();
  final TextEditingController planeacionController = TextEditingController();
  final TextEditingController trabajarController = TextEditingController();
  final TextEditingController comunicarLogrosController = TextEditingController();
  final TextEditingController reflexionController = TextEditingController();
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
    "Inclusion",
    "Pensamiento critico",
    "Interculturalidad critica",
    "Igualdad de genero",
    "Vida saludable",
    "Apropiacion de las culturas a traves de la lectura y la escritura",
    "Artes y experiencias esteticas"
  ];

  final Map<String, TextEditingController> relacionPorCampo = {};

  @override
  void initState() {
    super.initState();
    for (final campo in widget.campus) {
      relacionPorCampo[campo] = TextEditingController();
    }
    
    if (widget.isEditing && widget.planeacionId != null) {
      _cargarDatosExistentes();
    }
  }

  Future<void> _cargarDatosExistentes() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('detalles_proyecto')
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
            puntoPartidaController.text = momentos['punto_partida'] ?? '';
            planeacionController.text = momentos['planeacion'] ?? '';
            trabajarController.text = momentos['a_trabajar'] ?? '';
            comunicarLogrosController.text = momentos['comunicamos_logros'] ?? '';
            reflexionController.text = momentos['reflexion_aprendizaje'] ?? '';
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

  Future<void> guardarDetalleProyecto() async {
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
        "punto_partida": puntoPartidaController.text,
        "planeacion": planeacionController.text,
        "a_trabajar": trabajarController.text,
        "comunicamos_logros": comunicarLogrosController.text,
        "reflexion_aprendizaje": reflexionController.text,
        "posibles_variantes": variantesController.text,
      },
      "materiales": materiales,
      "espacios": espacios,
      "produccion_sugerida": produccion,
      "fecha_creacion": FieldValue.serverTimestamp(),
    };

    if (widget.isEditing && widget.planeacionId != null) {
      await FirebaseFirestore.instance
          .collection('detalles_proyecto')
          .doc(widget.planeacionId)
          .update(data);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Detalle actualizado correctamente!')),
      );
    } else {
      await FirebaseFirestore.instance.collection('detalles_proyecto').add(data);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Detalle guardado correctamente!')),
      );
    }
  }

  void _visualizarPDF() {
    final momentos = {
      'punto_partida': puntoPartidaController.text,
      'planeacion': planeacionController.text,
      'a_trabajar': trabajarController.text,
      'comunicamos_logros': comunicarLogrosController.text,
      'reflexion_aprendizaje': reflexionController.text,
    };

    final Map<String, String> relacionContenidos = {
      for (final campo in widget.campus)
        campo: relacionPorCampo[campo]?.text ?? ""
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisualizarPDFPage(
          modalidad: 'Proyecto',
          pdfFileName: 'planeacion_proyecto.pdf',
          wordFileName: 'planeacion_proyecto.docx',
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

  String _mes(int mes) {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return meses[mes - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing 
            ? 'Editar: Proyecto' 
            : 'Detallar: Proyecto'),
        backgroundColor: const Color(0xFF001F54),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _titulo('Periodo de Aplicación'),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fechaInicio ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => fechaInicio = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        fechaInicio == null
                            ? 'Selecciona fecha de inicio'
                            : 'Inicio: ${fechaInicio!.day} de ${_mes(fechaInicio!.month)} de ${fechaInicio!.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: fechaFin ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => fechaFin = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        fechaFin == null
                            ? 'Selecciona fecha de cierre'
                            : 'Cierre: ${fechaFin!.day} de ${_mes(fechaFin!.month)} de ${fechaFin!.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (fechaInicio != null && fechaFin != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  periodoAplicacionTexto,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF001F54)),
                ),
              ),
            _titulo('Propósito'),
            _input(propositoController, 'Escribe el propósito...'),
            _titulo('Relevancia Social'),
            _input(relevanciaController, 'Describe la relevancia social...'),
            _titulo('Campos Formativos'),
            _infoList(widget.campus),
            _titulo('Contenidos'),
            _infoList(_getContenidos()),
            _titulo('Procesos de Desarrollo y Aprendizaje'),
            _procesosDesarrollo(),
            _titulo('Relación entre los contenidos curriculares en la propuesta'),
            ...widget.campus.map((campo) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campo,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001F54)),
                  ),
                  TextField(
                    controller: relacionPorCampo[campo],
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Describe la relación para $campo...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            )),
            _titulo('Eje articulador'),
            DropdownButtonFormField<String>(
              value: ejeSeleccionado,
              isExpanded: true,
              items: ejes
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => ejeSeleccionado = v),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            _titulo('Momentos'),
            _subtitulo('1. Punto de partida'),
            _input(puntoPartidaController, 'Describe el punto de partida...'),
            _subtitulo('2. Planeación'),
            _input(planeacionController, 'Describe la planeación...'),
            _subtitulo('3. ¡A trabajar!'),
            _input(trabajarController, 'Describe el trabajo...'),
            _subtitulo('4. Comunicamos nuestros logros'),
            _input(comunicarLogrosController, 'Describe cómo comunicarán los logros...'),
            _subtitulo('5. Reflexión sobre el aprendizaje'),
            _input(reflexionController, 'Describe la reflexión sobre el aprendizaje...'),
            _subtitulo('Posibles variantes'),
            _input(variantesController, 'Describe posibles variantes...'),
            const SizedBox(height: 24),
            _titulo('Materiales'),
            _listaEditable(materiales, materialInput, 'Agregar material'),
            _titulo('Espacios'),
            _listaEditable(espacios, espacioInput, 'Agregar espacio'),
            _titulo('Producción sugerida'),
            _listaEditable(produccion, produccionInput, 'Agregar producción'),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('¿Deseas guardar la planeación?'),
                      content: const Text('Una vez dado al botón de Sí no podrás cambiar nada.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('No'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF001F54),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Sí'),
                        ),
                      ],
                    ),
                  );
                  if (result == true) {
                    await guardarDetalleProyecto();
                    _visualizarPDF();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001F54),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Visualizar PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: Text(
          t,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF001F54)),
        ),
      );

  Widget _subtitulo(String t) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(
          t,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      );

  Widget _input(TextEditingController c, String hint) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          minLines: 1,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );

  Widget _infoList(List<String> items) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items
              .map((e) => Row(
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 18)),
                      Expanded(child: Text(e)),
                    ],
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
          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001F54)),
        ),
      ));
      gradosPorContenido.forEach((contenido, grados) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, top: 2),
          child: Text(contenido, style: const TextStyle(fontWeight: FontWeight.bold)),
        ));
        (grados as Map<String, dynamic>).forEach((grado, elementos) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(left: 24, top: 2),
            child: Text('Grado $grado:', style: const TextStyle(fontStyle: FontStyle.italic)),
          ));
          for (final el in (elementos as List)) {
            widgets.add(Padding(
              padding: const EdgeInsets.only(left: 36, top: 1),
              child: Text('• $el'),
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
        ...lista.map((e) => Row(
              children: [
                const Text('• ', style: TextStyle(fontSize: 18)),
                Expanded(child: Text(e)),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () {
                    setState(() => lista.remove(e));
                  },
                )
              ],
            )),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
              icon: const Icon(Icons.add_circle, color: Color(0xFF001F54)),
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
      if (c['contenidos'] != null && c['contenidos'] is List) {
        result.addAll(List<String>.from(c['contenidos']));
      }
    }
    return result;
  }
}
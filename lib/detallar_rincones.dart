import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pages/visualizar_pdf_page.dart'; // ✅ Agregar importación

class DetallarRinconesPage extends StatefulWidget {
  final String titulo;
  final List<String> campus;
  final List<Map<String, dynamic>> contenidos;
  final List<Map<String, dynamic>> seleccionGrados;

  const DetallarRinconesPage({
    super.key,
    required this.titulo,
    required this.campus,
    required this.contenidos,
    required this.seleccionGrados,
  });

  @override
  State<DetallarRinconesPage> createState() => _DetallarRinconesPageState();
}

class _DetallarRinconesPageState extends State<DetallarRinconesPage> {
  final TextEditingController propositoController = TextEditingController();
  final TextEditingController relevanciaController = TextEditingController();
  final TextEditingController puntoPartidaController = TextEditingController();
  final TextEditingController asambleaInicialController =
      TextEditingController();
  final TextEditingController exploracionRinconesController =
      TextEditingController();
  final TextEditingController exploracionDescubrimientoController =
      TextEditingController();
  final TextEditingController compartimosAprendidoController =
      TextEditingController();
  final TextEditingController evaluamosExperienciaController =
      TextEditingController();
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
  }

  String get periodoAplicacionTexto {
    if (fechaInicio == null || fechaFin == null) return '';
    final meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    String format(DateTime d) =>
        '${d.day} de ${meses[d.month - 1]} de ${d.year}';
    return '${format(fechaInicio!)} - ${format(fechaFin!)}';
  }

  Future<void> guardarDetalleRincones() async {
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
        "asamblea_inicial": asambleaInicialController.text,
        "exploracion_rincones": exploracionRinconesController.text,
        "exploracion_descubrimiento": exploracionDescubrimientoController.text,
        "compartimos_aprendido": compartimosAprendidoController.text,
        "evaluamos_experiencia": evaluamosExperienciaController.text,
        "posibles_variantes": variantesController.text,
      },
      "materiales": materiales,
      "espacios": espacios,
      "produccion_sugerida": produccion,
      "fecha_creacion": FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('detalles_rincones').add(data);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Detalle guardado correctamente!')),
    );
  }

  // ✅ Agregar función _visualizarPDF()
  void _visualizarPDF() {
    final momentos = {
      'punto_partida': puntoPartidaController.text,
      'asamblea_inicial': asambleaInicialController.text,
      'exploracion_rincones': exploracionRinconesController.text,
      'exploracion_descubrimiento': exploracionDescubrimientoController.text,
      'compartimos_aprendido': compartimosAprendidoController.text,
      'evaluamos_experiencia': evaluamosExperienciaController.text,
    };

    final Map<String, String> relacionContenidos = {
      for (final campo in widget.campus)
        campo: relacionPorCampo[campo]?.text ?? ""
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VisualizarPDFPage(
          modalidad: 'Rincones de Aprendizaje', // ✅ Modalidad específica
          pdfFileName: 'planeacion_rincones.pdf',
          wordFileName: 'planeacion_rincones.docx',
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
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    return meses[mes - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detallar: Rincones de Aprendizaje'),
        backgroundColor: Colors.pink[800], // Rosa fuerte
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
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
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
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
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
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.pink),
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
            _titulo(
                'Relación entre los contenidos curriculares en la propuesta'),
            ...widget.campus.map((campo) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campo,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.pink),
                      ),
                      TextField(
                        controller: relacionPorCampo[campo],
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Describe la relación para $campo...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
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
            _subtitulo('1. Punto de partida (Saberes previos)'),
            _input(puntoPartidaController, 'Describe el punto de partida...'),
            _subtitulo('2. Asamblea inicial y planeación'),
            _input(asambleaInicialController,
                'Describe la asamblea inicial y planeación...'),
            _subtitulo('3. Exploración de los rincones'),
            _input(exploracionRinconesController,
                'Describe la exploración de los rincones...'),
            _subtitulo('4. Exploración y descubrimiento'),
            _input(exploracionDescubrimientoController,
                'Describe la exploración y descubrimiento...'),
            _subtitulo('5. Compartimos lo aprendido'),
            _input(compartimosAprendidoController,
                'Describe cómo comparten lo aprendido...'),
            _subtitulo(
                '6. Evaluamos la experiencia (Reflexión sobre el aprendizaje)'),
            _input(evaluamosExperienciaController,
                'Describe la evaluación/reflexión...'),
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
                      content: const Text(
                          'Una vez dado al botón de Sí no podrás cambiar nada.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('No'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink[800],
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Sí'),
                        ),
                      ],
                    ),
                  );
                  if (result == true) {
                    await guardarDetalleRincones();
                    _visualizarPDF(); // ✅ Agregar llamada a visualizar PDF
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[800],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.pink),
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
      final gradosPorContenido =
          campo['gradosPorContenido'] as Map<String, dynamic>;
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(
          campoNombre,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
        ),
      ));
      gradosPorContenido.forEach((contenido, grados) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, top: 2),
          child: Text(contenido,
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ));
        (grados as Map<String, dynamic>).forEach((grado, elementos) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(left: 24, top: 2),
            child: Text('Grado $grado:',
                style: const TextStyle(fontStyle: FontStyle.italic)),
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
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: widgets),
    );
  }

  Widget _listaEditable(
      List<String> lista, TextEditingController controller, String hint) {
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
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
              icon: const Icon(Icons.add_circle, color: Colors.pink),
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

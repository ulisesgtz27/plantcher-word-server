import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;

// Importar todos los formatos PDF con nombres corregidos
import '../pdf_formats/pdf_format_abj.dart';
import '../pdf_formats/pdf_format_centros.dart';
import '../pdf_formats/pdf_format_proyecto.dart';
import '../pdf_formats/pdf_format_rincones.dart';
import '../pdf_formats/pdf_format_taller.dart';
import '../pdf_formats/pdf_format_unidad.dart';

class VisualizarPDFPage extends StatefulWidget {
  final String modalidad;
  final String pdfFileName;
  final String wordFileName;

  final String titulo;
  final String periodoAplicacion;
  final String proposito;
  final String relevanciaSocial;
  final List<String> produccionSugerida;
  final List<String> camposFormativos;
  final List<String> contenidos;
  final List<Map<String, dynamic>> procesosDesarrollo;
  final Map<String, String> relacionContenidos;
  final String ejeArticulador;
  final Map<String, String> momentos;
  final String posiblesVariantes;
  final List<String> materiales;
  final List<String> espacios;

  const VisualizarPDFPage({
    super.key,
    required this.modalidad,
    required this.pdfFileName,
    required this.wordFileName,
    required this.titulo,
    required this.periodoAplicacion,
    required this.proposito,
    required this.relevanciaSocial,
    required this.produccionSugerida,
    required this.camposFormativos,
    required this.contenidos,
    required this.procesosDesarrollo,
    required this.relacionContenidos,
    required this.ejeArticulador,
    required this.momentos,
    required this.posiblesVariantes,
    required this.materiales,
    required this.espacios,
  });

  @override
  State<VisualizarPDFPage> createState() => _VisualizarPDFPageState();
}

class _VisualizarPDFPageState extends State<VisualizarPDFPage> {
  Uint8List? _pdfBytes;
  pw.Document? _pdfDoc;

  @override
  void initState() {
    super.initState();
    _generatePdfByModalidad();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Haz doble tap para hacer zoom en el PDF.'),
          backgroundColor: Colors.black87.withOpacity(0.85),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  // Función para generar el PDF según la modalidad
  Future<void> _generatePdfByModalidad() async {
    pw.Document pdfDoc;

    switch (widget.modalidad.toLowerCase()) {
      case 'abj':
      case 'aprendizaje basado en juegos':
        pdfDoc = buildAbjPDF(
          // Corregido: buildAbjPDF (no buildABJPDF)
          titulo: widget.titulo,
          periodoAplicacion: widget.periodoAplicacion,
          proposito: widget.proposito,
          relevanciaSocial: widget.relevanciaSocial,
          produccionSugerida: widget.produccionSugerida,
          camposFormativos: widget.camposFormativos,
          contenidos: widget.contenidos,
          procesosDesarrollo: widget.procesosDesarrollo,
          relacionContenidos: widget.relacionContenidos,
          ejeArticulador: widget.ejeArticulador,
          momentos: widget.momentos,
          posiblesVariantes: widget.posiblesVariantes,
          materiales: widget.materiales,
          espacios: widget.espacios,
        );
        break;

      case 'centros de interés':
        pdfDoc = buildCentrosInteresPDF(
          titulo: widget.titulo,
          periodoAplicacion: widget.periodoAplicacion,
          proposito: widget.proposito,
          relevanciaSocial: widget.relevanciaSocial,
          produccionSugerida: widget.produccionSugerida,
          camposFormativos: widget.camposFormativos,
          contenidos: widget.contenidos,
          procesosDesarrollo: widget.procesosDesarrollo,
          relacionContenidos: widget.relacionContenidos,
          ejeArticulador: widget.ejeArticulador,
          momentos: widget.momentos,
          posiblesVariantes: widget.posiblesVariantes,
          materiales: widget.materiales,
          espacios: widget.espacios,
        );
        break;

      case 'proyecto':
        pdfDoc = buildProyectoPDF(
          titulo: widget.titulo,
          periodoAplicacion: widget.periodoAplicacion,
          proposito: widget.proposito,
          relevanciaSocial: widget.relevanciaSocial,
          produccionSugerida: widget.produccionSugerida,
          camposFormativos: widget.camposFormativos,
          contenidos: widget.contenidos,
          procesosDesarrollo: widget.procesosDesarrollo,
          relacionContenidos: widget.relacionContenidos,
          ejeArticulador: widget.ejeArticulador,
          momentos: widget.momentos,
          posiblesVariantes: widget.posiblesVariantes,
          materiales: widget.materiales,
          espacios: widget.espacios,
        );
        break;

      case 'rincones de aprendizaje':
        pdfDoc = buildRinconesPDF(
          titulo: widget.titulo,
          periodoAplicacion: widget.periodoAplicacion,
          proposito: widget.proposito,
          relevanciaSocial: widget.relevanciaSocial,
          produccionSugerida: widget.produccionSugerida,
          camposFormativos: widget.camposFormativos,
          contenidos: widget.contenidos,
          procesosDesarrollo: widget.procesosDesarrollo,
          relacionContenidos: widget.relacionContenidos,
          ejeArticulador: widget.ejeArticulador,
          momentos: widget.momentos,
          posiblesVariantes: widget.posiblesVariantes,
          materiales: widget.materiales,
          espacios: widget.espacios,
        );
        break;

      case 'taller crítico':
        pdfDoc = buildTallerPDF(
          titulo: widget.titulo,
          periodoAplicacion: widget.periodoAplicacion,
          proposito: widget.proposito,
          relevanciaSocial: widget.relevanciaSocial,
          produccionSugerida: widget.produccionSugerida,
          camposFormativos: widget.camposFormativos,
          contenidos: widget.contenidos,
          procesosDesarrollo: widget.procesosDesarrollo,
          relacionContenidos: widget.relacionContenidos,
          ejeArticulador: widget.ejeArticulador,
          momentos: widget.momentos,
          posiblesVariantes: widget.posiblesVariantes,
          materiales: widget.materiales,
          espacios: widget.espacios,
        );
        break;

      case 'unidad didáctica':
        pdfDoc = buildUnidadPDF(
          titulo: widget.titulo,
          periodoAplicacion: widget.periodoAplicacion,
          proposito: widget.proposito,
          relevanciaSocial: widget.relevanciaSocial,
          produccionSugerida: widget.produccionSugerida,
          camposFormativos: widget.camposFormativos,
          contenidos: widget.contenidos,
          procesosDesarrollo: widget.procesosDesarrollo,
          relacionContenidos: widget.relacionContenidos,
          ejeArticulador: widget.ejeArticulador,
          momentos: widget.momentos,
          posiblesVariantes: widget.posiblesVariantes,
          materiales: widget.materiales,
          espacios: widget.espacios,
        );
        break;

      default:
        // Por defecto usar ABJ
        pdfDoc = buildAbjPDF(
          // Corregido: buildAbjPDF (no buildABJPDF)
          titulo: widget.titulo,
          periodoAplicacion: widget.periodoAplicacion,
          proposito: widget.proposito,
          relevanciaSocial: widget.relevanciaSocial,
          produccionSugerida: widget.produccionSugerida,
          camposFormativos: widget.camposFormativos,
          contenidos: widget.contenidos,
          procesosDesarrollo: widget.procesosDesarrollo,
          relacionContenidos: widget.relacionContenidos,
          ejeArticulador: widget.ejeArticulador,
          momentos: widget.momentos,
          posiblesVariantes: widget.posiblesVariantes,
          materiales: widget.materiales,
          espacios: widget.espacios,
        );
        break;
    }

    _pdfDoc = pdfDoc;
    await _loadPdf();
  }

  Future<void> _loadPdf() async {
    if (_pdfDoc == null) return;
    final bytes = await _pdfDoc!.save();
    setState(() {
      _pdfBytes = bytes;
    });
  }

  Future<void> _descargarPDF(BuildContext context) async {
    if (_pdfBytes == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${widget.pdfFileName}');
    await file.writeAsBytes(_pdfBytes!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF guardado en ${file.path}')),
    );
  }

  Future<void> _abrirPDF(BuildContext context) async {
    if (_pdfBytes == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${widget.pdfFileName}');
    if (!await file.exists()) {
      await file.writeAsBytes(_pdfBytes!);
    }
    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el PDF.')),
      );
    }
  }

  // --- FUNCIÓN PARA ENVIAR AL BACKEND PYTHON Y GENERAR WORD ---
  Future<void> generarWordConPython(BuildContext context) async {
    final Map<String, dynamic> data = {
      "modalidad": widget.modalidad, // Agregamos la modalidad
      "titulo": widget.titulo,
      "periodoAplicacion": widget.periodoAplicacion,
      "proposito": widget.proposito,
      "relevanciaSocial": widget.relevanciaSocial,
      "produccionSugerida": widget.produccionSugerida,
      "camposFormativos": widget.camposFormativos,
      "contenidos": widget.contenidos,
      "procesosDesarrollo": widget.procesosDesarrollo,
      "relacionContenidos": widget.relacionContenidos,
      "ejeArticulador": widget.ejeArticulador,
      "momentos": widget.momentos,
      "posiblesVariantes": widget.posiblesVariantes,
      "materiales": widget.materiales,
      "espacios": widget.espacios,
    };

    try {
      final response = await http.post(
        Uri.parse('https://web-production-29414.up.railway.app/generar-word'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final modalidadLimpia =
            widget.modalidad.replaceAll(' ', '_').toLowerCase();
        final file = File('${dir.path}/planeacion_${modalidadLimpia}.docx');
        await file.writeAsBytes(response.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Word generado en ${file.path}')),
        );
        // Abrir automáticamente el archivo
        await OpenFile.open(file.path);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al generar el Word')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }
  // --- FIN DE LA FUNCIÓN ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('PDF - ${widget.modalidad}'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (_pdfBytes != null)
            Positioned.fill(
              child: SfPdfViewer.memory(
                _pdfBytes!,
                canShowScrollHead: true,
                canShowScrollStatus: true,
                enableDoubleTapZooming: true,
              ),
            )
          else
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SpeedDial(
        icon: Icons.menu,
        activeIcon: Icons.close,
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        spacing: 16,
        spaceBetweenChildren: 16,
        direction: SpeedDialDirection.up,
        childrenButtonSize: const Size(60, 60),
        children: [
          SpeedDialChild(
            child:
                const Icon(Icons.picture_as_pdf, color: Colors.green, size: 32),
            backgroundColor: Colors.white,
            label: 'Abrir PDF',
            onTap: () => _abrirPDF(context),
          ),
          SpeedDialChild(
            child: const Icon(Icons.download, color: Colors.red, size: 32),
            backgroundColor: Colors.white,
            label: 'Descargar PDF',
            onTap: () => _descargarPDF(context),
          ),
          SpeedDialChild(
            child: const Icon(Icons.description, color: Colors.blue, size: 32),
            backgroundColor: Colors.white,
            label: 'Generar Word',
            onTap: () async {
              await generarWordConPython(context);
            },
          ),
        ],
      ),
    );
  }
}

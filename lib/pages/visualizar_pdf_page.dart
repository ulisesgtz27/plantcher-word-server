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
import '../planeaciones_list_page.dart';

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

class _VisualizarPDFPageState extends State<VisualizarPDFPage>
    with TickerProviderStateMixin {
  Uint8List? _pdfBytes;
  pw.Document? _pdfDoc;
  bool _isLoading = true;

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
    
    _generatePdfByModalidad();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Haz doble tap para hacer zoom en el PDF.',
            style: TextStyle(fontFamily: 'ComicNeue'),
          ),
          backgroundColor: const Color(0xFF4A148C).withOpacity(0.9),
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    super.dispose();
  }

  // ✅ FUNCIÓN PARA NAVEGAR A PLANEACIONES
  void _navegarAPlaneaciones() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const PlaneacionesListPage()),
      (route) => false,
    );
  }

  // Función para generar el PDF según la modalidad
  Future<void> _generatePdfByModalidad() async {
    setState(() {
      _isLoading = true;
    });

    pw.Document pdfDoc;

    switch (widget.modalidad.toLowerCase()) {
      case 'abj':
      case 'aprendizaje basado en juegos':
        pdfDoc = buildAbjPDF(
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
        pdfDoc = buildAbjPDF(
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
      _isLoading = false;
    });
    
    // ✅ INICIAR ANIMACIÓN CUANDO EL PDF ESTÉ LISTO
    _fadeAnimationController.forward();
  }

  // ✅ MODIFICADO - Abrir PDF y navegar a planeaciones
  Future<void> _abrirPDF(BuildContext context) async {
    if (_pdfBytes == null) return;
    
    // ✅ MOSTRAR DIÁLOGO DE CONFIRMACIÓN CON TEMA MORADO
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Abrir PDF',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A148C),
            fontFamily: 'ComicNeue',
          ),
        ),
        content: const Text(
          'Se abrirá el PDF en tu aplicación predeterminada y regresarás a la lista de planeaciones.',
          style: TextStyle(fontFamily: 'ComicNeue'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
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
            child: const Text('Abrir'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${widget.pdfFileName}');
    if (!await file.exists()) {
      await file.writeAsBytes(_pdfBytes!);
    }
    final openResult = await OpenFile.open(file.path);
    if (openResult.type == ResultType.done) {
      _navegarAPlaneaciones();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No se pudo abrir el PDF.',
            style: TextStyle(fontFamily: 'ComicNeue'),
          ),
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ✅ MODIFICADO - Generar Word y navegar a planeaciones
  Future<void> generarWordConPython(BuildContext context) async {
    // ✅ MOSTRAR DIÁLOGO DE CONFIRMACIÓN CON TEMA MORADO
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Text(
          'Generar Word',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A148C),
            fontFamily: 'ComicNeue',
          ),
        ),
        content: const Text(
          'Se generará el documento Word y se abrirá automáticamente. Luego regresarás a la lista de planeaciones.',
          style: TextStyle(fontFamily: 'ComicNeue'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
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
            child: const Text('Generar'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final Map<String, dynamic> data = {
      "modalidad": widget.modalidad,
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

    // ✅ MOSTRAR INDICADOR DE CARGA
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A148C)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Generando documento Word...',
              style: TextStyle(
                fontFamily: 'ComicNeue',
                color: Color(0xFF4A148C),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final response = await http.post(
        Uri.parse('https://web-production-29414.up.railway.app/generar-word'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      Navigator.of(context).pop(); // Cerrar diálogo de carga

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final modalidadLimpia =
            widget.modalidad.replaceAll(' ', '_').toLowerCase();
        final file = File('${dir.path}/planeacion_${modalidadLimpia}.docx');
        await file.writeAsBytes(response.bodyBytes);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Word generado en ${file.path}',
              style: const TextStyle(fontFamily: 'ComicNeue'),
            ),
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        
        // Abrir automáticamente el archivo
        await OpenFile.open(file.path);
        _navegarAPlaneaciones();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Error al generar el Word',
              style: TextStyle(fontFamily: 'ComicNeue'),
            ),
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Cerrar diálogo de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error de conexión: $e',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ✅ HEADER CON DEGRADADO MORADO
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF4A148C), // Morado profundo
                  Color(0xFF6A1B9A), // Morado medio
                  Color(0xFF8E24AA), // Morado claro
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
                            'PDF - ${widget.modalidad}',
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
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
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
            child: _isLoading
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.grey[50]!,
                          Colors.grey[100]!,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A148C)),
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Generando PDF...',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A148C),
                              fontFamily: 'ComicNeue',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Por favor espera un momento',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'ComicNeue',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.grey[50]!,
                            Colors.grey[100]!,
                          ],
                        ),
                      ),
                      child: _pdfBytes != null
                          ? Container(
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SfPdfViewer.memory(
                                  _pdfBytes!,
                                  canShowScrollHead: true,
                                  canShowScrollStatus: true,
                                  enableDoubleTapZooming: true,
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                'Error al cargar el PDF',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF4A148C),
                                  fontFamily: 'ComicNeue',
                                ),
                              ),
                            ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: !_isLoading && _pdfBytes != null
          ? SpeedDial(
              icon: Icons.menu,
              activeIcon: Icons.close,
              backgroundColor: const Color(0xFF4A148C),
              foregroundColor: Colors.white,
              spacing: 16,
              spaceBetweenChildren: 16,
              direction: SpeedDialDirection.up,
              childrenButtonSize: const Size(60, 60),
              buttonSize: const Size(56, 56),
              children: [
                SpeedDialChild(
                  child: const Icon(Icons.picture_as_pdf, color: Colors.green, size: 32),
                  backgroundColor: Colors.white,
                  label: 'Abrir PDF',
                  labelStyle: const TextStyle(
                    fontFamily: 'ComicNeue',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A148C),
                  ),
                  onTap: () => _abrirPDF(context),
                ),
                SpeedDialChild(
                  child: const Icon(Icons.description, color: Colors.blue, size: 32),
                  backgroundColor: Colors.white,
                  label: 'Generar Word',
                  labelStyle: const TextStyle(
                    fontFamily: 'ComicNeue',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A148C),
                  ),
                  onTap: () async {
                    await generarWordConPython(context);
                  },
                ),
              ],
            )
          : null,
    );
  }
}

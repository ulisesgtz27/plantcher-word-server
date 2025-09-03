import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

pw.Document buildSituacionPDF({
  required String titulo,
  required String periodoAplicacion,
  required String proposito,
  required String relevanciaSocial,
  required List<String> produccionSugerida,
  required List<String> camposFormativos,
  required List<String> contenidos,
  required List<Map<String, dynamic>> procesosDesarrollo,
  required Map<String, String> momentos,
  required String posiblesVariantes,
  required List<String> materiales,
  required List<String> espacios,
}) {
  final pdf = pw.Document();

  String joinList(List<String> list) {
    if (list.isEmpty) {
      return 'Sin elementos agregados';
    }
    return list.map((e) => '* $e').join('\n');
  }

  // Construir filas para la tabla principal
  List<List<String>> tablaPrincipal = [];
  for (int i = 0; i < camposFormativos.length; i++) {
    final campo = camposFormativos[i];
    final contenido = i < contenidos.length ? contenidos[i] : '';
    String procesos = '';
    if (procesosDesarrollo.isNotEmpty && i < procesosDesarrollo.length) {
      final gradosPorContenido = procesosDesarrollo[i]['gradosPorContenido'] as Map<String, dynamic>? ?? {};
      gradosPorContenido.forEach((cont, grados) {
        (grados as Map<String, dynamic>).forEach((grado, elementos) {
          procesos += 'Grado $grado:\n';
          for (final el in (elementos as List)) {
            procesos += '* $el\n';
          }
        });
      });
    }
    tablaPrincipal.add([
      campo,
      contenido,
      procesos.trim(),
    ]);
  }

  // Si alguna lista es muy grande, separamos en dos hojas
  final bool usarSegundaHoja = materiales.length > 15 || espacios.length > 15 || produccionSugerida.length > 15;

  // PRIMERA HOJA: Planeación Situación Didáctica
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text('Situación Didáctica: $titulo',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
          // Información básica
          pw.Table.fromTextArray(
            headers: [
              'Periodo de Aplicación',
              'Propósito',
              'Relevancia Social',
            ],
            data: [
              [
                periodoAplicacion,
                proposito,
                relevanciaSocial,
              ]
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.topLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(4),
              2: const pw.FlexColumnWidth(2),
            },
          ),
          pw.SizedBox(height: 12),
          // Tabla principal de campos formativos y contenidos
          pw.Table.fromTextArray(
            headers: [
              'Campos Formativos',
              'Contenidos',
              'Procesos de Desarrollo y Aprendizaje',
            ],
            data: tablaPrincipal,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.topLeft,
            cellStyle: pw.TextStyle(fontSize: 10),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(3),
              2: const pw.FlexColumnWidth(3),
            },
          ),
          pw.SizedBox(height: 12),
          // Momentos específicos de Situación Didáctica
          pw.Table.fromTextArray(
            headers: ['Momentos', 'Descripción'],
            data: [
              ['1. Inicio', momentos['inicio'] ?? ''],
              ['2. Desarrollo', momentos['desarrollo'] ?? ''],
              ['3. Cierre', momentos['cierre'] ?? ''],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.topLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(6),
            },
          ),
          pw.SizedBox(height: 8),
          // Posibles variantes
          pw.Table.fromTextArray(
            headers: ['Posibles Variantes'],
            data: [
              [posiblesVariantes.isNotEmpty ? posiblesVariantes : 'Sin variantes especificadas']
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.topLeft,
          ),
          pw.SizedBox(height: 8),
          // Recursos (solo si no se necesita segunda hoja)
          if (!usarSegundaHoja)
            pw.Table.fromTextArray(
              headers: ['Materiales', 'Espacios', 'Producción Sugerida'],
              data: [
                [
                  joinList(materiales),
                  joinList(espacios),
                  joinList(produccionSugerida),
                ]
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.topLeft,
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(3),
              },
            ),
        ],
      ),
    ),
  );

  // SEGUNDA HOJA SOLO SI ES NECESARIO
  if (usarSegundaHoja) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Recursos y Producción - Situación Didáctica',
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['Materiales', 'Espacios', 'Producción Sugerida'],
              data: [
                [
                  joinList(materiales),
                  joinList(espacios),
                  joinList(produccionSugerida),
                ]
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.topLeft,
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(3),
              },
            ),
          ],
        ),
      ),
    );
  }

  return pdf;
}
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

pw.Document buildRinconesPDF({
  required String titulo,
  required String periodoAplicacion,
  required String proposito,
  required String relevanciaSocial,
  required List<String> produccionSugerida,
  required List<String> camposFormativos,
  required List<String> contenidos,
  required List<Map<String, dynamic>> procesosDesarrollo,
  required Map<String, String> relacionContenidos,
  required String ejeArticulador,
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
      final gradosPorContenido = procesosDesarrollo[i]['gradosPorContenido']
              as Map<String, dynamic>? ??
          {};
      gradosPorContenido.forEach((cont, grados) {
        (grados as Map<String, dynamic>).forEach((grado, elementos) {
          procesos += 'Grado $grado:\n';
          for (final el in (elementos as List)) {
            procesos += '* $el\n';
          }
        });
      });
    }
    final relacion = relacionContenidos[campo] ?? '';
    tablaPrincipal.add([
      campo,
      contenido,
      procesos.trim(),
      relacion,
      ejeArticulador,
    ]);
  }

  // PRIMERA HOJA: Planeación general
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Center(
            child: pw.Text(
              'Planeación Rincones de Aprendizaje: $titulo',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
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
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.topLeft,
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: [
              'Campos Formativos',
              'Contenidos',
              'Procesos de Desarrollo y Aprendizaje',
              'Relación entre los contenidos curriculares en la propuesta',
              'Eje articulador'
            ],
            data: tablaPrincipal,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.topLeft,
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Momentos', 'Descripción'],
            data: [
              ['1. Punto de partida (Saberes previos)', momentos['punto_partida'] ?? ''],
              ['2. Asamblea inicial y planeación', momentos['asamblea_inicial'] ?? ''],
              ['3. Exploración de los rincones', momentos['exploracion_rincones'] ?? ''],
              ['4. Exploración y descubrimiento', momentos['exploracion_descubrimiento'] ?? ''],
              ['5. Compartimos lo aprendido', momentos['compartimos_aprendido'] ?? ''],
              ['6. Evaluamos la experiencia', momentos['evaluamos_experiencia'] ?? ''],
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.topLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(4),
            },
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Posibles Variantes'],
            data: [
              [posiblesVariantes]
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.topLeft,
          ),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: ['Materiales', 'Espacios', 'Producción Sugerida'],
            data: [
              [
                joinList(materiales),
                joinList(espacios),
                joinList(produccionSugerida),
              ]
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.topLeft,
          ),
        ],
      ),
    ),
  );

  return pdf;
}

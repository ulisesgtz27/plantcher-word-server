String buildAbjWordHtml({
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
  String joinList(List<String> list) =>
      list.isEmpty ? '' : list.map((e) => '<li>$e</li>').join();

  String buildTablaPrincipal() {
    int maxRows = [
      camposFormativos.length,
      contenidos.length,
      procesosDesarrollo.length,
      relacionContenidos.length
    ].reduce((a, b) => a > b ? a : b);

    String rows = '';
    for (int i = 0; i < maxRows; i++) {
      String procesosStr = '';
      if (procesosDesarrollo.isNotEmpty && i < procesosDesarrollo.length) {
        final gradosPorContenido = procesosDesarrollo[i]['gradosPorContenido'] as Map<String, dynamic>? ?? {};
        gradosPorContenido.forEach((cont, grados) {
          (grados as Map<String, dynamic>).forEach((grado, elementos) {
            procesosStr += 'Grado $grado:<br>';
            for (final el in (elementos as List)) {
              procesosStr += '&bull; $el<br>';
            }
          });
        });
      }
      rows += '''
      <tr>
        <td>${i < camposFormativos.length ? camposFormativos[i] : ''}</td>
        <td>${i < contenidos.length ? contenidos[i] : ''}</td>
        <td>${procesosStr.trim()}</td>
        <td>${i < camposFormativos.length ? (relacionContenidos[camposFormativos[i]] ?? '') : ''}</td>
        <td>${i == 0 ? ejeArticulador : ''}</td>
      </tr>
      ''';
    }
    return rows;
  }

  String buildMomentos() {
    return '''
      <tr><td>1. Planteamiento del Juego</td><td>${momentos['Planteamiento del Juego'] ?? ''}</td></tr>
      <tr><td>2. Desarrollo de las Actividades</td><td>${momentos['Desarrollo de las Actividades'] ?? ''}</td></tr>
      <tr><td>3. Compartamos la Experiencia</td><td>${momentos['Compartamos la Experiencia'] ?? ''}</td></tr>
      <tr><td>4. Comunidad de Juego</td><td>${momentos['Comunidad de Juego'] ?? ''}</td></tr>
    ''';
  }

  return '''
  <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: Arial, sans-serif; }
        h2 { text-align: center; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 16px; }
        th, td { border: 1px solid #222; padding: 6px; vertical-align: top; font-size: 12px; }
        th { background-color: #f2f2f2; }
        ul { margin: 0; padding-left: 18px; }
      </style>
    </head>
    <body>
      <h2>Planeación ABJ: $titulo</h2>
      <table>
        <tr>
          <th>Periodo de Aplicación</th>
          <th>Propósito</th>
          <th>Relevancia Social</th>
        </tr>
        <tr>
          <td>$periodoAplicacion</td>
          <td>$proposito</td>
          <td>$relevanciaSocial</td>
        </tr>
      </table>
      <table>
        <tr>
          <th>Campos Formativos</th>
          <th>Contenidos</th>
          <th>Procesos de Desarrollo y Aprendizaje</th>
          <th>Relación entre los contenidos curriculares en la propuesta</th>
          <th>Eje articulador</th>
        </tr>
        ${buildTablaPrincipal()}
      </table>
      <table>
        <tr>
          <th>Momentos</th>
          <th>Descripción</th>
        </tr>
        ${buildMomentos()}
      </table>
      <table>
        <tr>
          <th>Posibles Variantes</th>
        </tr>
        <tr>
          <td>$posiblesVariantes</td>
        </tr>
      </table>
      <table>
        <tr>
          <th>Materiales</th>
          <th>Espacios</th>
          <th>Producción Sugerida</th>
        </tr>
        <tr>
          <td><ul>${joinList(materiales)}</ul></td>
          <td><ul>${joinList(espacios)}</ul></td>
          <td><ul>${joinList(produccionSugerida)}</ul></td>
        </tr>
      </table>
    </body>
  </html>
  ''';
}
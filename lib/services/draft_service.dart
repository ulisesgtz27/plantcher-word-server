import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DraftService {
  static const String _collection = 'drafts';
  
  static User? get currentUser => FirebaseAuth.instance.currentUser;
  
  // ✅ CONSULTA SIMPLIFICADA
  static Future<Map<String, dynamic>?> getLatestDraft() async {
    try {
      print('🔍 DraftService: Buscando borradores...');
      
      if (currentUser == null) {
        print('❌ Usuario no autenticado');
        return null;
      }
      
      print('👤 Usuario: ${currentUser!.uid}');
      
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('user_id', isEqualTo: currentUser!.uid)
          .where('completado', isEqualTo: false)
          .get();
      
      print('📊 Documentos encontrados: ${snapshot.docs.length}');
      
      if (snapshot.docs.isNotEmpty) {
        // Obtener el más reciente manualmente
        DocumentSnapshot? latestDoc;
        DateTime? latestDate;
        
        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final timestamp = data['fecha_actualizacion'] as Timestamp?;
          
          if (timestamp != null) {
            final date = timestamp.toDate();
            if (latestDate == null || date.isAfter(latestDate)) {
              latestDate = date;
              latestDoc = doc;
            }
          }
        }
        
        if (latestDoc != null) {
          final data = latestDoc.data() as Map<String, dynamic>;
          
          print('✅ Borrador encontrado: ${latestDoc.id}');
          print('📝 Modalidad: ${data['modalidad']}');
          print('📝 Tipo de página: ${data['tipo_pagina'] ?? 'opciones'}');
          print('📅 Última actualización: ${data['fecha_actualizacion']}');
          
          return {
            'id': latestDoc.id,
            'modalidad': data['modalidad'],
            'tipo_pagina': data['tipo_pagina'] ?? 'opciones', // ✅ NUEVO
            'data': data,
          };
        }
      }
      
      print('❌ No se encontraron borradores activos');
      return null;
      
    } catch (e) {
      print('❌ Error obteniendo borrador: $e');
      return null;
    }
  }
  
  // ✅ NUEVA FUNCIÓN: Eliminar borradores anteriores antes de crear uno nuevo
  static Future<void> _deleteExistingDrafts() async {
    try {
      if (currentUser == null) return;
      
      print('🧹 Eliminando borradores anteriores...');
      
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('user_id', isEqualTo: currentUser!.uid)
          .where('completado', isEqualTo: false)
          .get();
      
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
        print('🗑️ Borrador anterior eliminado: ${doc.id}');
      }
      
    } catch (e) {
      print('❌ Error eliminando borradores anteriores: $e');
    }
  }
  
  static Future<String?> saveDraft({
    required String modalidad,
    required Map<String, dynamic> data,
    String? draftId,
    String tipoPagina = 'opciones', // ✅ NUEVO PARÁMETRO
  }) async {
    try {
      print('💾 Guardando borrador...');
      
      if (currentUser == null) {
        print('❌ Usuario no autenticado para guardar borrador');
        return null;
      }
      
      final draftData = {
        'modalidad': modalidad,
        'user_id': currentUser!.uid,
        'completado': false,
        'tipo_pagina': tipoPagina, // ✅ NUEVO
        'fecha_actualizacion': FieldValue.serverTimestamp(),
        ...data,
      };
      
      if (draftId != null) {
        // Actualizar borrador existente
        await FirebaseFirestore.instance
            .collection(_collection)
            .doc(draftId)
            .update(draftData);
        print('✅ Borrador actualizado: $draftId');
        return draftId;
      } else {
        // ✅ ELIMINAR BORRADORES ANTERIORES ANTES DE CREAR UNO NUEVO
        await _deleteExistingDrafts();
        
        // Crear nuevo borrador
        draftData['fecha_creacion'] = FieldValue.serverTimestamp();
        final docRef = await FirebaseFirestore.instance
            .collection(_collection)
            .add(draftData);
        print('✅ Nuevo borrador creado: ${docRef.id}');
        return docRef.id;
      }
      
    } catch (e) {
      print('❌ Error guardando borrador: $e');
      return null;
    }
  }
  
  static Future<void> deleteDraft(String draftId) async {
    try {
      print('🗑️ Eliminando borrador: $draftId');
      
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(draftId)
          .delete();
      
      print('✅ Borrador eliminado exitosamente');
      
    } catch (e) {
      print('❌ Error eliminando borrador: $e');
    }
  }
  
  static Future<void> markAsCompleted(String draftId) async {
    try {
      print('✅ Marcando borrador como completado: $draftId');
      
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(draftId)
          .update({
            'completado': true,
            'fecha_completado': FieldValue.serverTimestamp(),
          });
      
      print('✅ Borrador marcado como completado');
      
    } catch (e) {
      print('❌ Error marcando borrador como completado: $e');
    }
  }
  
  static Future<void> markDraftAsCompleted(String draftId) async {
    await markAsCompleted(draftId);
  }
  
  // ✅ FUNCIÓN CORREGIDA: Solo crear un borrador de prueba después de limpiar
  static Future<void> createTestDraft() async {
    try {
      print('🧪 Creando borrador de prueba...');
      
      if (currentUser == null) {
        print('❌ Usuario no autenticado');
        return;
      }
      
      // ✅ ELIMINAR BORRADORES ANTERIORES PRIMERO
      await _deleteExistingDrafts();
      
      final testData = {
        'modalidad': 'Proyecto',
        'user_id': currentUser!.uid,
        'completado': false,
        'tipo_pagina': 'opciones', // ✅ NUEVO
        'fecha_creacion': FieldValue.serverTimestamp(),
        'fecha_actualizacion': FieldValue.serverTimestamp(),
        'titulo': 'Borrador de Prueba',
        'paso': 1,
        'campus': ['Lenguajes'],
        'contenidos': [],
        'seleccionGrados': [],
        'proposito': 'Este es un borrador de prueba',
      };
      
      final docRef = await FirebaseFirestore.instance
          .collection(_collection)
          .add(testData);
      
      print('✅ Borrador de prueba creado: ${docRef.id}');
      
    } catch (e) {
      print('❌ Error creando borrador de prueba: $e');
    }
  }
  
  static Future<void> cleanupOldDrafts() async {
    try {
      print('🧹 Limpiando borradores antiguos...');
      
      if (currentUser == null) return;
      
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      
      final snapshot = await FirebaseFirestore.instance
          .collection(_collection)
          .where('user_id', isEqualTo: currentUser!.uid)
          .where('completado', isEqualTo: true)
          .get();
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final fechaCompletado = data['fecha_completado'] as Timestamp?;
        
        if (fechaCompletado != null && 
            fechaCompletado.toDate().isBefore(cutoffDate)) {
          await doc.reference.delete();
          print('🗑️ Borrador antiguo eliminado: ${doc.id}');
        }
      }
      
    } catch (e) {
      print('❌ Error limpiando borradores: $e');
    }
  }
}

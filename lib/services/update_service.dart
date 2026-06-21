import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class UpdateService {
  /// Verifica se há atualização disponível na Play Store e exibe o
  /// fluxo nativo de atualização flexível (o usuário pode continuar
  /// usando o app enquanto baixa e atualiza quando quiser).
  static Future<void> checkForUpdate() async {
    // In-app updates só funciona no Android; ignora em outros ambientes.
    if (kIsWeb) return;

    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        // Tenta atualização flexível (não interrompe o usuário)
        if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          // Após o download completo, aplica a atualização
          await InAppUpdate.completeFlexibleUpdate();
        }
        // Se apenas atualização imediata estiver disponível (ex: update obrigatório)
        else if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        }
      }
    } catch (e) {
      // Silencia erros silenciosamente em debug; em produção o app continua normal.
      debugPrint('[UpdateService] Erro ao verificar atualização: $e');
    }
  }
}

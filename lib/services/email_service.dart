import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class EmailService {
  // ATENÇÃO: Para que o envio funcione, você deve criar uma conta em emailjs.com
  // e substituir os valores abaixo pelos seus IDs.
  static const String _serviceId = 'service_ozisqwa'; // PLACEHOLDER
  static const String _templateId = 'template_v2q7scu'; // PLACEHOLDER
  static const String _publicKey = 'user_XXXXXX'; // PLACEHOLDER

  static Future<bool> sendOTP({
    required String userName,
    required String userEmail,
    required String otpCode,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: json.encode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'user_name': userName,
            'user_email': userEmail,
            'otp_code': otpCode,
            'app_name': 'ProVê',
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('EmailJS: E-mail enviado com sucesso para $userEmail');
        return true;
      } else {
        debugPrint('EmailJS: Falha ao enviar e-mail. Status: ${response.statusCode}');
        debugPrint('Resposta: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('EmailJS: Erro na requisição: $e');
      return false;
    }
  }
}

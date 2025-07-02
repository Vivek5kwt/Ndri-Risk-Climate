import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendOtpToEmail(String email, String otp) async {
  const serviceId = 'service_74cm0md';
  const templateId = 'template_k96q86f';
  const userId = 'vAG0yL_06YauuLAN6';

  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': userId,
      'template_params': {
        'to_email': email,
        'otp': otp,
      },
    }
    ),

  );

  if (response.statusCode == 200) {
    print('✅ OTP sent successfully!');
  } else {
    print('❌ Failed to send OTP: ${response.body}');
  }
}
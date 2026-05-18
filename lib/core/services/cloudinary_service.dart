import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class CloudinaryService {
  static const String _cloudName = 'dl4qmorch'; 
  static const String _cloudinaryUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  final ImagePicker _picker = ImagePicker();

  Future<String?> uploadImage(XFile imageFile) async {
    try {
      final uri = Uri.parse(_cloudinaryUrl);
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final mimeSplit = mimeType.split('/');

      final request = http.MultipartRequest('POST', uri);

      request.fields['upload_preset'] = 'ecobocado';
      request.fields['folder'] = 'productos';

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType(mimeSplit[0], mimeSplit[1]),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['secure_url'] as String;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['error']?['message'] ?? 'Error ${response.statusCode}');
      }
    } catch (e) {
      print("Error en CloudinaryService: $e");
      return null;
    }
  }

  // Métodos de captura de imagen optimizados
  Future<XFile?> pickImage(ImageSource source) async {
    return await _picker.pickImage(
      source: source,
      maxWidth: 1000, // Un poco más de resolución para evitar que se pixele
      imageQuality: 85,
    );
  }
}
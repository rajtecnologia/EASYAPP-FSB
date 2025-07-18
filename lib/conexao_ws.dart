import 'dart:io';

import 'package:dio/dio.dart';

class EnvioRastreioWS {
  static Future<Response?> enviaRastreioRomaneioWS({
    String? codigoRegional,
    String? codigoUsuario,
    String? codigoUnidade,
    String? codigoClientePmobile,
    String? latitudeUsuario,
    String? longitudeUsuario,
    String? velocidade,
    String? rumo
  }) async {
    final dio = Dio();
    //  String webservice = 'https://www.rajsolucoes.com.br/easyapplication/topmixerp/webservices/webservice.php'
      String webservice = 'https://rajtecnologiaws.com.br/rajerp/frisaborerp/webservices/webservice.php';
     
    try {
      // return await dio.get('', options: Options(headers: {
      return await dio.get(webservice,
          options: Options(headers: {
            HttpHeaders.acceptHeader: 'json/application/json',
          }),
          queryParameters: {
            'metodo': 'RecebeRastreioNovo',
            'latitude': latitudeUsuario,
            'longitude': longitudeUsuario,
            'velocidade': velocidade,
            'rumo': rumo,
            'codigo_regional': codigoRegional,
            'codigo_usuario': codigoUsuario,
            'codigo_unidade': 1,
            'codigo_cliente_pmobile': 1
          });
    } on DioException catch (e) {
      print("Erro na requisição: $e");
      return null;
    }
  }
}

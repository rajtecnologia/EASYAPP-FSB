import 'dart:async'; // Para usar Timer
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:dio/dio.dart';
import 'package:easy_fsb/conexao_ws.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:permission_handler/permission_handler.dart' as per;
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart'; // Para obter a localização

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyApplication ERP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: const MyHomePage(title: 'EasyApplication ERP'),
      home: SplashScreen(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  InAppWebViewController? _webViewController;

  bool temInternet = true;
  bool carregando = true;
  Location location = Location();
  int usuarioLogado = 0;
  String codigo_usuario = "";
  String codigo_cliente = "";

  // Função para obter a localização usando o pacote 'location'
  Future<void> getLocation() async {
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          print('Serviço de localização não está ativado');
          return;
        }
      }

      // Obter a localização atual
      LocationData currentLocation = await location.getLocation();
      await location.enableBackgroundMode(enable: true);

      print(
          'LatitudeApp: ${currentLocation.latitude}, LongitudeApp: ${currentLocation.longitude}');

      if (usuarioLogado == 1) {
        await sendLocation(
            currentLocation.latitude!,
            currentLocation.longitude!,
            currentLocation.speed!,
            currentLocation.heading!);
      }
    } catch (e) {
      print("Erro ao obter a localização: $e");
    }
  }

  Future<bool> enviaRastreioRomaneio(
      String latitudeUsuario,
      String longitudeUsuario,
      String velocidade,
      String rumo,
      String codigoUsuario) async {
    dio.Response<dynamic>? res = await EnvioRastreioWS.enviaRastreioRomaneioWS(
      codigoRegional: "1",
      codigoUsuario: codigoUsuario,
      codigoUnidade: "1",
      codigoClientePmobile: "1",
      latitudeUsuario: latitudeUsuario,
      longitudeUsuario: longitudeUsuario,
      velocidade: velocidade,
      rumo: rumo,
    );

    if (res != null) {
      Map<String, dynamic> json = jsonDecode(res.data);

      if (json.containsKey('valido')) {
        return true;
      } else {
        return false;
      }
    } else {}

    setState(() {});
    return false;
  }

  bool retorno = false;

  Future<void> sendLocation(
      double latitude, double longitude, double velocidade, double rumo) async {
    retorno = await enviaRastreioRomaneio(
        latitude.toString(),
        longitude.toString(),
        velocidade.toString(),
        rumo.toString(),
        codigo_usuario);

    if (retorno) {
      print("Localização enviada");
    } else {
      print("Falha ao enviar localização do usuário");
    }

    // print("Enviando localização: Latitude = $latitude, Longitude = $longitude");
  }

  Future<void> downloadFile(String url, String savePath) async {
    try {
      final dio.Dio client = dio.Dio();
      final response = await client.get(
        url,
        options: dio.Options(
          responseType: dio.ResponseType.bytes,
          followRedirects: true,
          headers: {
            'Accept': 'application/pdf',
          },
        ),
      );

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.data);

        if (await file.exists()) {
          await OpenFile.open(savePath);
        } else {
          print("Arquivo não encontrado");
        }
      } else {
        throw Exception('Erro ao baixar o arquivo: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro no download: $e');
    }
  }

  @override
  void didChangeDependencies() async {
    try {
      temInternet = await InternetConnection().hasInternetAccess;
      setState(() {
        carregando = false;
      });

      // Configurar o Timer para obter a localização a cada 120 segundos
      //Timer.periodic(Duration(seconds: 120), (Timer t) => getLocation());
    } catch (e) {
      setState(() {
        carregando = false;
      });
    }

    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (carregando) {
      return Scaffold(
        body: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: const Row(
            children: [
              Spacer(),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Spacer(),
                  CircularProgressIndicator(),
                  Spacer(),
                ],
              ),
              Spacer(),
            ],
          ),
        ),
      );
    }

    if (!temInternet) {
      return Scaffold(
        body: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: const Row(
            children: [
              Spacer(),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Spacer(),
                  Text(
                    'Ops! Erro ao carregar página:\n\nPor favor verifique sua internet.',
                    textAlign: TextAlign.center,
                  ),
                  Spacer(),
                ],
              ),
              Spacer(),
            ],
          ),
        ),
      );
    }
    String ambiente = '';
    if (Platform.isAndroid) {
      ambiente = 'android';
    } else if (Platform.isIOS) {
      ambiente = 'ios';
    }

    return PopScope(
      canPop: false,
      child: SafeArea(
        child: Scaffold(
          body: InAppWebView(
            onGeolocationPermissionsShowPrompt: (controller, origin) async {
              return GeolocationPermissionShowPromptResponse(
                  allow: true, origin: origin, retain: true);
            },
            initialUrlRequest: URLRequest(
              url: WebUri.uri(Uri.tryParse(
                      'https://www.rajsolucoes.com.br/easyapplication/frisaborerp/app_easy_wv/login.php?ambiente=$ambiente') ??
                  Uri()),
            ),
            onDownloadStartRequest: (controller, downloadStartRequest) async {
              final url = downloadStartRequest.url.toString();
              final filename =
                  downloadStartRequest.suggestedFilename ?? 'file.pdf';

              // Pedir permissão de armazenamento, se necessário
              if (await Permission.storage.request().isGranted) {
                Directory? directory;
                if (Platform.isAndroid) {
                  directory = Directory('/storage/emulated/0/Download');
                } else if (Platform.isIOS) {
                  directory = await getApplicationDocumentsDirectory();
                }

                if (directory != null) {
                  final filePath = '${directory.path}/$filename';

                  // Baixar o arquivo
                  await downloadFile(url, filePath);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Download concluído: $filePath')),
                  );
                  //PARA ABRIR O ARQUIVO
                  final result = await OpenFile.open(filePath);
                  if (result.type == ResultType.error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text('Erro ao abrir o arquivo: ${result.message}'),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Erro ao acessar o armazenamento.')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Permissão de armazenamento negada.')),
                );
              }
            },
            initialSettings: InAppWebViewSettings(
              mediaPlaybackRequiresUserGesture: false,
            ),
            onWebViewCreated: (InAppWebViewController controller) {
              _webViewController = controller;
            },
            onPermissionRequest: (controller, request) async {
              // Concede a permissão automaticamente se o sistema já concedeu
              if (request.resources.contains(PermissionResourceType.CAMERA) &&
                  await Permission.camera.isGranted) {
                return PermissionResponse(
                    resources: [PermissionResourceType.CAMERA],
                    action: PermissionResponseAction.GRANT);
              }

              if (request.resources
                      .contains(PermissionResourceType.MICROPHONE) &&
                  await Permission.microphone.isGranted) {
                return PermissionResponse(
                    resources: [PermissionResourceType.MICROPHONE],
                    action: PermissionResponseAction.GRANT);
              }

              if (request.resources
                      .contains(PermissionResourceType.GEOLOCATION) &&
                  await Permission.location.isGranted) {
                return PermissionResponse(
                    resources: [PermissionResourceType.GEOLOCATION],
                    action: PermissionResponseAction.GRANT);
              }

              if (request.resources
                      .contains(PermissionResourceType.FILE_READ_WRITE) &&
                  await Permission.location.isGranted) {
                return PermissionResponse(
                    resources: [PermissionResourceType.FILE_READ_WRITE],
                    action: PermissionResponseAction.GRANT);
              }

              return PermissionResponse(action: PermissionResponseAction.DENY);
            },
            onConsoleMessage: (controller, consoleMessage) {
              if (consoleMessage.messageLevel == ConsoleMessageLevel.LOG) {
                final message = consoleMessage.message;

                try {
                  final data = jsonDecode(message);
                  // codigo_cliente = data['codigo_cliente'];

                  if (data is Map<String, dynamic> && data['valido'] == 1) {
                    codigo_usuario = data['codigo_usuario'];
                    usuarioLogado = 1;

                    print("Usuário válido, código: ${data['codigo_usuario']}");
                  }
                } catch (e) {
                  print("Mensagem de console não é um JSON válido: $message");
                }
              }
            },
          ),
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Exibe o diálogo após o layout ser carregado
      _showPermissionDialog();
    });
  }

  static bool permissoesAceita = false;

  Future<void> _showPermissionDialog() async {
    if (permissoesAceita) {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 500));

    var status = await Permission.locationWhenInUse.request();

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Permissões de localizacao durante o uso nao aceita. Por favor feche o app reabra e tente novamente.')),
      );

      return;
    }
    await Future.delayed(const Duration(milliseconds: 300));
    var status2 = await Permission.location.request();

    if (!status2.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Permissões de localizacao nao aceita. Por favor feche o app reabra e tente novamente.')),
      );

      return;
    }

    if (status2.isGranted) {
      await Future.delayed(const Duration(milliseconds: 300));
      //o await no ios nao funciona. Entao chamar de novo abaixo para ter certeza.
      await Permission.locationAlways.request();
    }

    await Future.delayed(const Duration(milliseconds: 300));

    Map<Permission, per.PermissionStatus> statuses = await [
      Permission.camera,
      Permission.storage,
    ].request();

    // Verifica se as permissões foram concedidas
    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (allGranted) {
      // Redireciona para a próxima tela se tudo foi concedido
      permissoesAceita = true;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) => MyHomePage(
                  title: "A",
                )),
      );
    } else {
      showDialog(
        context: context,
        barrierDismissible: false, // Não fecha o diálogo ao tocar fora dele
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Permissões Necessárias'),
            content: const Text(
                "O Easyapplication faz a coleta e transmite os dados da localização(geolocalização) exata do seu aparelho mesmo mesmo quando o app não esta aberto (em background). Estes dados são armazenados em nosso sistema para extração de relatórios pelo seu gestor."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fecha o diálogo
                  _requestPermissions(); // Solicita as permissões
                },
                child: Text('Concordar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fecha o diálogo
                  // Você pode redirecionar ou encerrar o app se necessário
                },
                child: Text('Sair'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _requestPermissions() async {
    try {
      var status = await Permission.locationWhenInUse.request();

      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Permissões de localizacao durante o uso nao aceita. Por favor feche o app reabra e tente novamente.')),
        );

        return;
      }
      await Future.delayed(const Duration(milliseconds: 300));
      var status2 = await Permission.location.request();

      if (!status2.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Permissões de localizacao nao aceita. Por favor feche o app reabra e tente novamente.')),
        );

        return;
      }

      if (status2.isGranted) {
        await Permission.locationAlways.request();
      }

      await Future.delayed(const Duration(milliseconds: 300));

      Map<Permission, per.PermissionStatus> statuses = await [
        Permission.camera,
        Permission.storage,
      ].request();

      // Verifica se as permissões foram concedidas
      bool allGranted = statuses.values.every((status) {
        return status.isGranted;
      });

      if (allGranted) {
        permissoesAceita = true;

        // Redireciona para a próxima tela se tudo foi concedido
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => const MyHomePage(
                    title: "EasyApplication",
                  )),
        );
      } else {
        // Exibe mensagem ou executa alguma ação se as permissões forem negadas
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Permissões necessárias não foram concedidas.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!permissoesAceita) {
      return const Scaffold(
        body: Center(
          child: Text('Validando permissoes...'),
        ),
      );
    }

    return const Scaffold(
      body: Center(
        child: MyHomePage(
            title: "EasyApplication"), // Tela de carregamento inicial
      ),
    );
  }
}

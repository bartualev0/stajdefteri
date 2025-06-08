import 'dart:async';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';

// --- WorkManager Ayarları ---
const simpleTaskKey = "simpleTask";
const simplePeriodicTaskKey = "simplePeriodicTask";

// Bu fonksiyon en üst seviyede olmalı (bir sınıfın içinde değil)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    print("Native WorkManager task: $task"); // Görevin adını yazdır
    if (task == simpleTaskKey) {
      print("Tek seferlik görev çalıştı: $inputData");
      // Burada bildirim gönderme gibi işlemler yapılabilir
      FlutterLocalNotificationsPlugin().show(
        888,
        'WorkManager Görevi',
        'Tek seferlik görev tamamlandı!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'workmanager_channel',
            'WorkManager Bildirimleri',
            channelDescription: 'WorkManager tarafından tetiklenen bildirimler',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher', // Android projenizdeki launcher ikonunu kullanın
          ),
        ),
      );
    } else if (task == simplePeriodicTaskKey) {
      print("Periyodik görev çalıştı: $inputData");
    }
    return Future.value(true);
  });
}

// --- Flutter Background Service Ayarları ---
@pragma('vm:entry-point')
Future<void> onStart(ServiceInstance service) async {
  // Dart isolate'i için gerekli başlatmalar
  DartPluginRegistrant.ensureInitialized();

  print('Background Service BAŞLADI');
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Periyodik bir görev simülasyonu
  Timer.periodic(const Duration(seconds: 5), (timer) async {
    // DÜZELTME: isForegroundService() metodu artık ServiceInstance içinde yok.
    // Bu kod bloğu zaten servis ön planda çalıştığı için tetiklenir.
    // Bu yüzden 'if' kontrolü kaldırıldı.
    print('Background Service çalışıyor...');
    FlutterLocalNotificationsPlugin().show(
      12345, // Benzersiz ID
      'Arkaplan Servisi',
      'Servis aktif: ${DateTime.now()}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'my_foreground',
          'MY FOREGROUND SERVICE',
          icon: '@mipmap/ic_launcher',
          ongoing: true, // Servis bildirimini kaydırılamaz yapar
        ),
      ),
    );
  });
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // İzinleri iste
  await _requestPermissions();

  // WorkManager'ı başlat
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Geliştirme sırasında logları görmek için true
  );

  // Flutter Background Service'i başlat
  await initializeService();


  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
}


Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  const notificationChannelId = 'my_foreground';

  // Android için bildirim kanalı oluştur (Android 8.0+)
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    notificationChannelId,
    'MY FOREGROUND SERVICE', // title
    description: 'This channel is used for important notifications.', // description
    importance: Importance.low, // Foreground servisler için genellikle low veya default
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false, // Uygulama açıldığında otomatik başlama
      isForegroundMode: true,
      notificationChannelId: notificationChannelId,
      initialNotificationTitle: 'Arkaplan Servisi',
      initialNotificationContent: 'Başlatılıyor...',
      foregroundServiceNotificationId: 888, // Bildirim ID'si
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Kapsamlı Demo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // connectivity_plus paketi artık List<ConnectivityResult> döndürüyor.
  List<ConnectivityResult> _connectivityResult = [ConnectivityResult.none];
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;


  // Bildirimler için
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Sensör verileri için
  String _accelerometerData = "Veri bekleniyor...";
  String _gyroscopeData = "Veri bekleniyor...";
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gyroscopeSubscription;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
    _initNotifications();
    _initSensors();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _accelerometerSubscription?.cancel();
    _gyroscopeSubscription?.cancel();
    super.dispose();
  }

  // Yayın Algılayıcıları (Bağlantı Durumu)
  Future<void> _initConnectivity() async {
    // Dinleyici, tek bir sonuç yerine bir liste alır.
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Gelen listeyi state'e ata
      setState(() {
        _connectivityResult = results;
      });
      // SnackBar'da göstermek için listeyi bir string'e çevir.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bağlantı durumu: ${results.map((r) => r.toString().split('.').last).join(', ')}')),
      );
    });
    // İlk durumu alırken de bir liste döner.
    final results = await Connectivity().checkConnectivity();
    setState(() {
      _connectivityResult = results;
    });
  }

  // 2. SMS ve İleti İşlemleri
  Future<void> _sendSms() async {
    const phoneNumber = "5551234567"; // Test için bir numara
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber, queryParameters: {'body': Uri.encodeComponent('Merhaba')});
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      _showErrorSnackBar('SMS uygulaması açılamadı.');
    }
  }

  Future<void> _sendEmail() async {
    const email = "test@example.com";
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: Uri.encodeComponent('subject=Flutter Test Email&body=Merhaba Flutter ile gönderilen e-posta!'),
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showErrorSnackBar('E-posta uygulaması açılamadı.');
    }
  }

  // 3. Bildirimlerle İlgili Temel İşlemler
  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _flutterLocalNotificationsPlugin.show(
      0,
      'Basit Bildirim',
      'Bu bir Flutter bildirimidir!',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  // 4. Farklı Uygulamalar ile Etkileşim
  Future<void> _openWebPage() async {
    final Uri url = Uri.parse('https://flutter.dev');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showErrorSnackBar('Web sayfası açılamadı: $url');
    }
  }

  Future<void> _openMap() async {
    final Uri mapUri = Uri.parse('geo:37.4220,-122.0841?q=Googleplex');
    if (await canLaunchUrl(mapUri)) {
      await launchUrl(mapUri);
    } else {
      _showErrorSnackBar('Harita uygulaması açılamadı.');
    }
  }

  // 5. Servislerle İlgili Temel İşlemler (Foreground Service)
  void _startBackgroundService() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (isRunning) {
      print("Servis zaten çalışıyor.");
      return;
    }
    service.startService();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Arkaplan servisi başlatıldı.')),
    );
  }

  void _stopBackgroundService() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (isRunning) {
      service.invoke("stopService");
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arkaplan servisi durduruldu.')),
      );
    } else {
      print("Servis zaten durdurulmuş.");
    }
  }


  // 6. WorkManager ile Zamanlanmış Görevler
  void _scheduleOneTimeTask() {
    Workmanager().registerOneOffTask(
      "1",
      simpleTaskKey,
      initialDelay: const Duration(seconds: 10),
      inputData: <String, dynamic>{'mesaj': 'Tek seferlik görev verisi'},
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('10 saniye sonra tek seferlik görev zamanlandı.')),
    );
  }

  void _schedulePeriodicTask() {
    Workmanager().registerPeriodicTask(
      "2",
      simplePeriodicTaskKey,
      frequency: const Duration(minutes: 15),
      inputData: <String, dynamic>{'mesaj': 'Periyodik görev verisi'},
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresCharging: true,
      ),
    );
     ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Periyodik görev (15 dk aralıklarla) zamanlandı.')),
    );
  }

  void _cancelAllTasks() {
    Workmanager().cancelAll();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tüm WorkManager görevleri iptal edildi.')),
    );
  }

  // 7. Sensörleri Kullanarak Uygulama Geliştirme
  void _initSensors() {
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          _accelerometerData =
              "İvmeölçer:\nX: ${event.x.toStringAsFixed(2)}\nY: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}";
        });
      }
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      if (mounted) {
        setState(() {
          _gyroscopeData =
              "Jiroskop:\nX: ${event.x.toStringAsFixed(2)}\nY: ${event.y.toStringAsFixed(2)}\nZ: ${event.z.toStringAsFixed(2)}";
        });
      }
    });
  }

  void _toggleSensorListening(bool start) {
    if (start) {
      _accelerometerSubscription?.resume();
      _gyroscopeSubscription?.resume();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sensörler dinleniyor.')),
      );
    } else {
      _accelerometerSubscription?.pause();
      _gyroscopeSubscription?.pause();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sensör dinlemesi duraklatıldı.')),
      );
    }
  }


  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Kapsamlı Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildSectionTitle('1. Yayın Algılayıcıları'),
            Text('Bağlantı Durumu: ${_connectivityResult.map((e) => e.toString().split('.').last).join(', ')}'),
            const SizedBox(height: 20),

            _buildSectionTitle('2. SMS ve İleti İşlemleri'),
            ElevatedButton(onPressed: _sendSms, child: const Text('SMS Gönder (Uygulamayı Aç)')),
            ElevatedButton(onPressed: _sendEmail, child: const Text('E-posta Gönder (Uygulamayı Aç)')),
            const SizedBox(height: 20),

            _buildSectionTitle('3. Bildirimler'),
            ElevatedButton(onPressed: _showNotification, child: const Text('Basit Bildirim Göster')),
            const SizedBox(height: 20),

            _buildSectionTitle('4. Farklı Uygulamalarla Etkileşim'),
            ElevatedButton(onPressed: _openWebPage, child: const Text('Web Sayfası Aç (flutter.dev)')),
            ElevatedButton(onPressed: _openMap, child: const Text('Harita Uygulamasını Aç')),
            const SizedBox(height: 20),

            _buildSectionTitle('5. Servisler (Foreground Service)'),
            ElevatedButton(onPressed: _startBackgroundService, child: const Text('Arkaplan Servisini Başlat')),
            ElevatedButton(onPressed: _stopBackgroundService, child: const Text('Arkaplan Servisini Durdur')),
            const SizedBox(height: 20),

            _buildSectionTitle('6. WorkManager ile Zamanlanmış Görevler'),
            ElevatedButton(onPressed: _scheduleOneTimeTask, child: const Text('Tek Seferlik Görev Zamanla')),
            ElevatedButton(onPressed: _schedulePeriodicTask, child: const Text('Periyodik Görev Zamanla')),
            ElevatedButton(onPressed: _cancelAllTasks, child: const Text('Tüm Görevleri İptal Et')),
            const SizedBox(height: 20),

            _buildSectionTitle('7. Sensörler'),
            Text(_accelerometerData, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(_gyroscopeData, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: () => _toggleSensorListening(true), child: const Text('Sensörleri Dinle')),
                ElevatedButton(onPressed: () => _toggleSensorListening(false), child: const Text('Dinlemeyi Durdur')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
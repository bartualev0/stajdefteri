## 📸 Ekran Görüntüleri

| Uygulama Ekranı 1 | Uygulama Ekranı 2 | İzin Talebi |
| :------------------------------------------------------: | :----------------------------------------------------------------------: | :----------------------------------------------------: |
| ![Uygulama Ana Ekranı](https://github.com/user-attachments/assets/93092606-b417-4a0d-affa-dfff53142981) | ![Arka Plan Servisi ve Bildirimler](https://github.com/user-attachments/assets/88d966b8-4dd1-4ccc-bf3f-905c593ac16d) | ![Uygulama İzin Talebi](https://github.com/user-attachments/assets/2744a9a6-6eb5-4a5e-96ee-f42693e8bda6) |

## 🚀 Özellikler

Bu uygulama aşağıdakileri içerir:

-   **🌐 Yayın Algılayıcıları (Broadcast Receivers):** Cihazın internet bağlantı durumunu (`Wi-Fi`, `Mobil Veri`, `Bağlantı Yok`) anlık olarak dinler ve arayüzde gösterir.
-   **💬 İleti ve Uygulama Etkileşimi:** `url_launcher` kullanarak cihazdaki varsayılan SMS, e-posta, web tarayıcısı ve harita uygulamalarını açar.
-   **🔔 Yerel Bildirimler (Local Notifications):** `flutter_local_notifications` ile anında veya zamanlanmış bildirimler gönderir.
-   **⚙️ Arka Plan Servisleri (Foreground Services):** `flutter_background_service` kullanarak uygulama kapalıyken bile çalışan, kalıcı bir bildirimle kullanıcıyı bilgilendiren servisler oluşturur.
-   **🕒 Zamanlanmış Görevler (Scheduled Tasks):** `workmanager` ile cihazın şarj durumu veya internet bağlantısı gibi koşullara bağlı, ertelenebilir ve periyodik arka plan görevleri planlar.
-   **🔬 Cihaz Sensörleri:** `sensors_plus` paketi ile cihazın ivmeölçer (accelerometer) ve jiroskop (gyroscope) verilerini okur ve ekranda gösterir.
-   **🛡️ İzin Yönetimi (Permission Handling):** `permission_handler` ile bildirim gibi kritik izinleri uygulama başlangıcında kullanıcıdan talep eder.

## 📦 Kullanılan Paketler

Bu projede aşağıdaki temel Flutter paketleri kullanılmıştır:

| Paket                                                                                              | Amaç                                |
| -------------------------------------------------------------------------------------------------- | ----------------------------------- |
| [`connectivity_plus`](https://pub.dev/packages/connectivity_plus)                                  | Ağ bağlantı durumunu dinleme        |
| [`url_launcher`](https://pub.dev/packages/url_launcher)                                            | Harici uygulamaları başlatma        |
| [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications)              | Yerel bildirimler oluşturma         |
| [`workmanager`](https://pub.dev/packages/workmanager)                                              | Ertelenebilir arka plan görevleri   |
| [`sensors_plus`](https://pub.dev/packages/sensors_plus)                                            | Cihaz sensörlerini okuma            |
| [`flutter_background_service`](https://pub.dev/packages/flutter_background_service)                | Ön plan servisleri oluşturma        |
| [`permission_handler`](https://pub.dev/packages/permission_handler)                                | Çalışma zamanı izinlerini yönetme   |

# Clima

Ứng dụng thời tiết sử dụng OpenWeatherMap, http và geolocator.

Dự án Flutter độc lập, dùng Flutter 3.38.6 / Dart 3.10.7.

## Chức năng

- Tìm thời tiết theo thành phố hoặc tọa độ thiết bị khi được cấp quyền.
- Hiển thị nhiệt độ, mô tả, biểu tượng, độ ẩm và tốc độ gió.
- Xử lý loading, lỗi mạng, quyền vị trí, thành phố không tồn tại và lỗi API.
- Tách riêng logic vị trí, networking và weather model.

## Chạy và kiểm tra

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --dart-define-from-file=config.local.json
```

Tạo file cấu hình theo hướng dẫn bên dưới trước khi chạy.

## Cấu hình API key

1. Sao chép `config.example.json` thành `config.local.json`.
2. Điền key của bạn vào giá trị `OPENWEATHER_API_KEY`.
3. Chạy ứng dụng bằng lệnh:

```powershell
flutter run -d chrome --dart-define-from-file=config.local.json
```

Khi build web, truyền cùng file cấu hình:

```powershell
flutter build web --dart-define-from-file=config.local.json
```

`config.local.json` đã được gitignore. Không commit key thật. Sau khi đổi key, hãy dừng và chạy lại ứng dụng.

Android đã khai báo quyền Internet và vị trí. iOS có mô tả quyền vị trí khi sử dụng và Podfile. Trên web, dùng localhost hoặc HTTPS và cho phép Location trong trình duyệt. Khi không cấp quyền vị trí, vẫn có thể tìm theo tên thành phố.

15 unit/widget test kiểm tra các trường hợp thành công và lỗi bằng HTTP/location được kiểm soát. Lần kiểm tra API trực tiếp gần nhất nhận HTTP 401; chưa xác nhận lấy thời tiết thành công với key cục bộ hoặc GPS trên thiết bị thật.


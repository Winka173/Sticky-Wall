// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Sticky Wall';

  @override
  String get addNote => 'Thêm ghi chú';

  @override
  String get search => 'Tìm kiếm';

  @override
  String get type => 'Loại';

  @override
  String get typeAll => 'Tất cả';

  @override
  String get typeNormal => 'Thường';

  @override
  String get typeLink => 'Liên kết';

  @override
  String get createNote => 'Tạo ghi chú';

  @override
  String get editNote => 'Sửa ghi chú';

  @override
  String get content => 'Nội dung';

  @override
  String get contentHint => 'Ghi gì đó...';

  @override
  String get link => 'Liên kết';

  @override
  String get cancel => 'Hủy';

  @override
  String get add => 'Thêm';

  @override
  String get update => 'Cập nhật';

  @override
  String get contentRequired => 'Vui lòng nhập nội dung';

  @override
  String get linkRequired => 'Vui lòng nhập liên kết';

  @override
  String get duplicateExists => 'Nội dung hoặc liên kết đã tồn tại';

  @override
  String get addSuccess => 'Đã thêm thành công';

  @override
  String get updateSuccess => 'Đã cập nhật thành công';

  @override
  String get deleteSuccess => 'Đã xóa thành công';

  @override
  String get deleteConfirm => 'Xóa ghi chú này?';

  @override
  String get yes => 'Có';

  @override
  String get emptyState =>
      'Chưa có ghi chú nào.\nNhấn “Thêm ghi chú” để dán lên tường!';

  @override
  String couldNotOpen(String url) {
    return 'Không mở được $url';
  }

  @override
  String get customize => 'Tùy chỉnh';

  @override
  String get wallSection => 'Tường';

  @override
  String get fontSection => 'Phông chữ';

  @override
  String get languageSection => 'Ngôn ngữ';

  @override
  String get langSystem => 'Theo hệ thống';

  @override
  String get sortTooltip => 'Sắp xếp';

  @override
  String get listView => 'Dạng danh sách';

  @override
  String get gridView => 'Dạng lưới';

  @override
  String get wallCork => 'Bảng gỗ bần';

  @override
  String get wallChalkGreen => 'Bảng phấn xanh';

  @override
  String get wallChalkBlack => 'Bảng phấn đen';

  @override
  String get wallPlaster => 'Tường sơn';

  @override
  String get wallBrick => 'Tường gạch';

  @override
  String get wallWood => 'Tường gỗ';

  @override
  String get fontPreview => 'Xin chào! Ghi chú nhanh lên tường.';
}

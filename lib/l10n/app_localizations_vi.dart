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
  String get typeChecklist => 'Danh sách';

  @override
  String get createNote => 'Tạo ghi chú';

  @override
  String get editNote => 'Sửa ghi chú';

  @override
  String get content => 'Nội dung';

  @override
  String get title => 'Tiêu đề';

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
  String get save => 'Lưu';

  @override
  String get delete => 'Xóa';

  @override
  String get rename => 'Đổi tên';

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
  String get noteDeleted => 'Đã xóa ghi chú';

  @override
  String get undo => 'Hoàn tác';

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
  String get viewWall => 'Tường';

  @override
  String get viewGrid => 'Lưới';

  @override
  String get viewList => 'Danh sách';

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

  @override
  String get emote => 'Emote';

  @override
  String get wallDecor => 'Vết bẩn trên tường';

  @override
  String get color => 'Màu giấy';

  @override
  String get colorAuto => 'Tự động';

  @override
  String get pin => 'Ghim lên đầu';

  @override
  String get reminder => 'Nhắc nhở';

  @override
  String get noReminder => 'Không nhắc';

  @override
  String get setReminder => 'Đặt nhắc nhở';

  @override
  String get clearReminder => 'Xóa';

  @override
  String get checklistItems => 'Mục';

  @override
  String get addItem => 'Thêm mục';

  @override
  String get sortByCreated => 'Mới nhất trước';

  @override
  String get sortByName => 'Theo tên';

  @override
  String get boards => 'Bảng';

  @override
  String get newBoard => 'Bảng mới';

  @override
  String get boardName => 'Tên bảng';

  @override
  String get defaultBoardName => 'Tường của tôi';

  @override
  String get deleteBoard => 'Xóa bảng';

  @override
  String deleteBoardConfirm(String name) {
    return 'Xóa “$name” và toàn bộ ghi chú của nó?';
  }

  @override
  String get dataSection => 'Sao lưu';

  @override
  String get exportData => 'Xuất ghi chú';

  @override
  String get importData => 'Nhập ghi chú';

  @override
  String get importHint => 'Dán bản sao lưu vào đây';

  @override
  String get importSuccess => 'Đã nhập thành công';

  @override
  String get importFailed => 'Không đọc được bản sao lưu';

  @override
  String get importReplaceWarning =>
      'Nhập sẽ thay thế toàn bộ bảng và ghi chú hiện tại.';
}

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
  String get typeNormal => 'Văn bản';

  @override
  String get typeLink => 'Liên kết';

  @override
  String get typeChecklist => 'Việc cần làm';

  @override
  String get typeDrawing => 'Vẽ tay';

  @override
  String get title => 'Tiêu đề';

  @override
  String get contentHint => 'Viết gì đó lên đây…';

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
  String get edit => 'Sửa';

  @override
  String get rename => 'Đổi tên';

  @override
  String get clear => 'Xóa hết';

  @override
  String get contentRequired => 'Viết gì đó trước nhé';

  @override
  String get linkRequired => 'Thêm liên kết trước nhé';

  @override
  String get noteEmpty => 'Ghi chú vẫn đang trống';

  @override
  String get duplicateExists => 'Liên kết này đã có trên tường';

  @override
  String get noteDeleted => 'Đã xóa ghi chú';

  @override
  String get undo => 'Hoàn tác';

  @override
  String get emptyState =>
      'Chưa có ghi chú nào.\nChạm vào đây để dán tờ đầu tiên lên tường!';

  @override
  String get wallCreateHint =>
      'Mẹo: chạm giữ vào chỗ trống trên tường để dán ghi chú ngay tại đó.';

  @override
  String get noMatches => 'Không có ghi chú nào khớp';

  @override
  String couldNotOpen(String url) {
    return 'Không mở được $url';
  }

  @override
  String get customize => 'Tùy chỉnh';

  @override
  String get wallSection => 'Chất liệu tường';

  @override
  String get fontSection => 'Phông chữ';

  @override
  String get languageSection => 'Ngôn ngữ';

  @override
  String get langSystem => 'Theo hệ thống';

  @override
  String get sortTooltip => 'Sắp xếp';

  @override
  String get sortNewest => 'Mới nhất';

  @override
  String get sortOldest => 'Cũ nhất';

  @override
  String get sortAZ => 'A → Z';

  @override
  String get sortZA => 'Z → A';

  @override
  String get layout => 'Bố cục';

  @override
  String get viewWall => 'Dán tự do';

  @override
  String get viewGrid => 'Lưới';

  @override
  String get viewList => 'Danh sách';

  @override
  String get wallCork => 'Bảng ghim';

  @override
  String get wallChalkGreen => 'Bảng xanh';

  @override
  String get wallChalkBlack => 'Bảng đen';

  @override
  String get wallPlaster => 'Tường vôi';

  @override
  String get wallBrick => 'Tường gạch';

  @override
  String get wallWood => 'Ván gỗ';

  @override
  String get fontPreview => 'Xin chào! Ghi chú nhanh lên tường.';

  @override
  String get photo => 'Ảnh';

  @override
  String get fromGallery => 'Chọn từ thư viện';

  @override
  String get takePhoto => 'Chụp ảnh';

  @override
  String get shareAsImage => 'Chia sẻ ảnh';

  @override
  String get saveImage => 'Lưu ảnh';

  @override
  String get imageSaved => 'Đã lưu vào thư viện';

  @override
  String get imageSaveFailed => 'Không lưu được ảnh';

  @override
  String get resetZoom => 'Về cỡ gốc';

  @override
  String get wallDecor => 'Vết bẩn trên tường';

  @override
  String get pin => 'Ghim lên đầu';

  @override
  String get unpin => 'Bỏ ghim';

  @override
  String get reminder => 'Nhắc nhở';

  @override
  String get addItem => 'Thêm mục';

  @override
  String get penSize => 'Cỡ bút';

  @override
  String get emote => 'Biểu tượng';

  @override
  String get color => 'Màu giấy';

  @override
  String get newBoard => 'Tường mới';

  @override
  String get boardName => 'Tên tường';

  @override
  String get defaultBoardName => 'Tường của tôi';

  @override
  String get deleteBoard => 'Xóa tường';

  @override
  String deleteBoardConfirm(String name) {
    return 'Xóa “$name” và toàn bộ ghi chú trên đó?';
  }

  @override
  String get moveToBoard => 'Chuyển sang tường khác';

  @override
  String movedToBoard(String name) {
    return 'Đã chuyển sang “$name”';
  }

  @override
  String get dataSection => 'Sao lưu';

  @override
  String get exportData => 'Sao lưu ghi chú';

  @override
  String get importData => 'Khôi phục bản sao lưu';

  @override
  String get importHint => 'Dán bản sao lưu vào đây';

  @override
  String get importSuccess => 'Đã khôi phục thành công';

  @override
  String get importFailed => 'Không đọc được bản sao lưu';

  @override
  String get importReplaceWarning =>
      'Khôi phục sẽ thay thế toàn bộ tường và ghi chú hiện tại.';
}

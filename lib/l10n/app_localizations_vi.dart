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
  String get noteDeleted => 'Đã chuyển vào thùng rác';

  @override
  String notesDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã chuyển $count ghi chú vào thùng rác',
    );
    return '$_temp0';
  }

  @override
  String get undo => 'Hoàn tác';

  @override
  String get dropToDelete => 'Thả vào đây để xóa';

  @override
  String get trash => 'Thùng rác';

  @override
  String get trashEmpty => 'Thùng rác trống';

  @override
  String get trashHint => 'Ghi chú ở đây sẽ tự xóa hẳn sau 30 ngày.';

  @override
  String get restore => 'Khôi phục';

  @override
  String get restored => 'Đã khôi phục ghi chú';

  @override
  String get deleteForever => 'Xóa vĩnh viễn';

  @override
  String get emptyTrash => 'Dọn sạch thùng rác';

  @override
  String emptyTrashConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Xóa hẳn $count ghi chú trong thùng rác?',
    );
    return '$_temp0';
  }

  @override
  String daysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Còn $count ngày',
      zero: 'Hết hạn hôm nay',
    );
    return '$_temp0';
  }

  @override
  String deletedOn(String date) {
    return 'Đã xóa $date';
  }

  @override
  String get repeat => 'Lặp lại';

  @override
  String get repeatNone => 'Một lần';

  @override
  String get repeatDaily => 'Hằng ngày';

  @override
  String get repeatWeekly => 'Hằng tuần';

  @override
  String get repeatMonthly => 'Hằng tháng';

  @override
  String get select => 'Chọn nhiều ghi chú';

  @override
  String selectedCount(int count) {
    return 'Đã chọn $count';
  }

  @override
  String get selectAll => 'Chọn tất cả';

  @override
  String get move => 'Chuyển';

  @override
  String get tidy => 'Xếp lại cho gọn';

  @override
  String get tidyByColor => 'Xếp theo màu';

  @override
  String get moreActions => 'Thêm';

  @override
  String get threadCut => 'Đã cắt dây';

  @override
  String get threadTied => 'Đã nối dây';

  @override
  String get threadTip => 'Kéo từ ghim sang tờ khác để nối dây.';

  @override
  String get nightSection => 'Đèn';

  @override
  String get nightModeOff => 'Luôn sáng';

  @override
  String get nightModeOn => 'Luôn tắt đèn';

  @override
  String get nightModeSystem => 'Theo hệ thống';

  @override
  String get nightModeSchedule => 'Theo giờ';

  @override
  String get lightsOff => 'Tắt đèn';

  @override
  String get lightsOn => 'Bật đèn';

  @override
  String nightSchedule(String start, String end) {
    return 'Từ $start đến $end';
  }

  @override
  String get nightStart => 'Tắt đèn lúc';

  @override
  String get nightEnd => 'Bật đèn lúc';

  @override
  String get customWall => 'Ảnh của bạn';

  @override
  String get changePhoto => 'Đổi ảnh';

  @override
  String get removePhoto => 'Bỏ ảnh';

  @override
  String get autoTrashDone => 'Tự dọn việc đã xong';

  @override
  String get autoTrashDoneHint =>
      'Danh sách đã tích hết sẽ vào thùng rác sau 1 ngày.';

  @override
  String resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ghi chú',
      zero: 'Không có',
    );
    return '$_temp0';
  }

  @override
  String get boardIcon => 'Biểu tượng tường';

  @override
  String get none => 'Không có';

  @override
  String get sampleDrag =>
      'Kéo tôi đi khắp tường 👉\nChạm giữ chỗ trống để dán tờ mới ngay đó.';

  @override
  String get sampleLongPress =>
      'Nhấn giữ vào tôi để xem thêm: chuyển tường, chia sẻ, xóa…';

  @override
  String get sampleChecklistTitle => 'Thử tích vào đây ✅';

  @override
  String get sampleChecklist1 => 'Chạm vào ghim đỏ để cố định lên đầu';

  @override
  String get sampleChecklist2 => 'Kéo góc để phóng to / thu nhỏ';

  @override
  String get sampleChecklist3 => 'Xóa chúng tôi khi đã quen tay';

  @override
  String get sampleThread => 'Kéo từ ghim của tôi sang tờ khác để nối dây 🧵';

  @override
  String get sampleDrawing => 'Vẽ vời cũng được ✏️';

  @override
  String get emptyState =>
      'Chưa có ghi chú nào.\nChạm vào đây để dán tờ đầu tiên lên tường!';

  @override
  String get wallCreateHint =>
      'Mẹo: chạm giữ vào chỗ trống trên tường để dán ghi chú hoặc ảnh ngay tại đó.';

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
  String get wallKraft => 'Giấy kraft';

  @override
  String get wallMarble => 'Đá hoa';

  @override
  String get wallTerrazzo => 'Đá mài';

  @override
  String get wallDenim => 'Vải bò';

  @override
  String get wallFelt => 'Bảng nỉ';

  @override
  String get wallLinen => 'Vải lanh tối';

  @override
  String get fontPreview => 'Xin chào! Ghi chú nhanh lên tường.';

  @override
  String get fromGallery => 'Chọn từ thư viện';

  @override
  String get takePhoto => 'Chụp ảnh';

  @override
  String get typePhoto => 'Ảnh';

  @override
  String get typeLabel => 'Nhãn';

  @override
  String get labelHint => 'Tên cột hoặc khu vực…';

  @override
  String get lockInPlace => 'Khóa vị trí';

  @override
  String get unlock => 'Mở khóa';

  @override
  String get thread => 'Dây';

  @override
  String get yarnColor => 'Màu len';

  @override
  String get threadLabelHint => 'Ghi lên dây…';

  @override
  String get threadArrow => 'Mũi tên';

  @override
  String get cutThread => 'Cắt dây';

  @override
  String get drawOnWall => 'Vẽ lên tường';

  @override
  String get done => 'Xong';

  @override
  String get caption => 'Chú thích';

  @override
  String get addPhoto => 'Thêm ảnh';

  @override
  String get replacePhoto => 'Thay ảnh';

  @override
  String get photoRequired => 'Hãy thêm một ảnh';

  @override
  String get pinPhotos => 'Ghim ảnh lên tường';

  @override
  String get noteHere => 'Ghi chú mới tại đây';

  @override
  String get photosHere => 'Ghim ảnh tại đây';

  @override
  String get viewPhoto => 'Xem ảnh';

  @override
  String get rotate => 'Xoay';

  @override
  String photosPinned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã ghim $count ảnh lên tường',
    );
    return '$_temp0';
  }

  @override
  String get shareAsImage => 'Chia sẻ ảnh';

  @override
  String get saveImage => 'Lưu ảnh';

  @override
  String get exportBoard => 'Xuất tường thành ảnh';

  @override
  String get exportHint =>
      'Chỉ có tường, ghi chú và dây — không có thanh công cụ. Chia sẻ, hoặc lưu vào thư viện ảnh.';

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
  String get eraser => 'Tẩy';

  @override
  String get redo => 'Làm lại';

  @override
  String get canvasSection => 'Nền vẽ';

  @override
  String get patternPlain => 'Trơn';

  @override
  String get patternRuled => 'Kẻ ngang';

  @override
  String get patternGrid => 'Kẻ ô';

  @override
  String get patternDots => 'Chấm';

  @override
  String get emote => 'Biểu tượng';

  @override
  String get color => 'Màu giấy';

  @override
  String get newBoard => 'Tường mới';

  @override
  String get boardName => 'Tên tường';

  @override
  String get editBoard => 'Chỉnh sửa tường';

  @override
  String get nameStyle => 'Kiểu chữ tên';

  @override
  String get bold => 'In đậm';

  @override
  String get italic => 'In nghiêng';

  @override
  String get underline => 'Gạch chân';

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

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
  String get duplicateExists => 'Liên kết này đã có trên bảng này';

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
      other: 'Xóa vĩnh viễn $count mục trong Thùng rác? Không thể lấy lại.',
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
  String get repeatNone => 'Không lặp lại';

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
  String get tidy => 'Xếp gọn';

  @override
  String get tidyByColor => 'Xếp theo màu';

  @override
  String get arrange => 'Sắp xếp lại…';

  @override
  String get tidyHint => 'Thành hàng gọn, không chồng lên nhau';

  @override
  String get tidyByColorHint => 'Gom các ghi chú cùng màu giấy lại với nhau';

  @override
  String get moreActions => 'Khác';

  @override
  String get threadCut => 'Đã cắt dây';

  @override
  String get threadTied => 'Đã nối dây';

  @override
  String get nightSection => 'Đèn';

  @override
  String get nightModeOff => 'Luôn bật đèn';

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
  String resultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ghi chú',
      zero: 'Không có kết quả',
    );
    return '$_temp0';
  }

  @override
  String get boardIcon => 'Biểu tượng bảng';

  @override
  String get none => 'Không có';

  @override
  String get sampleDrag =>
      'Kéo tôi đi khắp tường 👉\nNhấn giữ chỗ trống để dán tờ mới ngay đó.';

  @override
  String get sampleLongPress =>
      'Nhấn giữ vào tôi để xem thêm: chuyển bảng, chia sẻ, xóa…';

  @override
  String get sampleChecklistTitle => 'Thử tích vào đây ✅';

  @override
  String get sampleChecklist1 => 'Chạm vào ghim đỏ để cố định lên đầu';

  @override
  String get sampleChecklist2 => 'Kéo góc để phóng to / thu nhỏ';

  @override
  String get sampleChecklist3 => 'Quen tay rồi thì xóa tụi mình đi nhé';

  @override
  String get sampleThread => 'Kéo từ ghim của tôi sang tờ khác để nối dây 🧵';

  @override
  String get sampleDrawing => 'Vẽ vời cũng được ✏️';

  @override
  String get emptyState =>
      'Chưa có ghi chú nào.\nChạm vào đây để dán tờ đầu tiên lên tường!';

  @override
  String get wallCreateHint =>
      'Mẹo: nhấn giữ chỗ trống trên tường để dán ghi chú hoặc ảnh ngay tại đó.';

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
  String get viewWall => 'Tường';

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
  String get wallMarble => 'Đá cẩm thạch';

  @override
  String get wallTerrazzo => 'Đá mài';

  @override
  String get wallDenim => 'Vải bò';

  @override
  String get wallFelt => 'Bảng nỉ';

  @override
  String get wallLinen => 'Vải lanh tối';

  @override
  String get wallCardboard => 'Bìa các-tông';

  @override
  String get wallCement => 'Tường xi măng';

  @override
  String get wallCotton => 'Vải cotton trắng';

  @override
  String get wallPaper => 'Giấy trắng';

  @override
  String get wallMoss => 'Rêu cỏ';

  @override
  String get wallLeather => 'Da đỏ';

  @override
  String get wallDarkMarble => 'Đá cẩm thạch đen';

  @override
  String get wallDarkWood => 'Ván gỗ tối';

  @override
  String get wallTiles => 'Gạch ca-rô';

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
  String get yarnColor => 'Màu dây';

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
  String get saveImage => 'Lưu ảnh';

  @override
  String get exportBoard => 'Xuất bảng thành ảnh';

  @override
  String get exportWholeWall => 'Cả tường';

  @override
  String get exportVisible => 'Phần đang xem';

  @override
  String get exportAllNotes => 'Mọi ghi chú';

  @override
  String exportSelectedNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã chọn $count',
    );
    return '$_temp0';
  }

  @override
  String get exportPdf => 'Xuất PDF';

  @override
  String get exportMore => 'Thêm tùy chọn';

  @override
  String get exportFewer => 'Ẩn tùy chọn';

  @override
  String get cropImage => 'Cắt bớt';

  @override
  String get cropHint =>
      'Kéo các góc hoặc cạnh để cắt bớt phần thừa; kéo bên trong để dời khung.';

  @override
  String get cropReset => 'Cả ảnh';

  @override
  String get putOnHomeScreen => 'Đưa lên widget màn hình chính';

  @override
  String get widgetUpdated => 'Đã cập nhật widget màn hình chính';

  @override
  String get widgetUpdateFailed => 'Không cập nhật được widget';

  @override
  String get bullets => 'Gạch đầu dòng';

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
  String get wallDecor => 'Vết ố & dấu vết trên tường';

  @override
  String get pin => 'Ghim lên đầu';

  @override
  String get unpin => 'Bỏ ghim';

  @override
  String get reminder => 'Lời nhắc';

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
  String get patternRuled => 'Kẻ dòng';

  @override
  String get patternGrid => 'Kẻ ô';

  @override
  String get patternDots => 'Chấm bi';

  @override
  String get emote => 'Biểu tượng cảm xúc';

  @override
  String get color => 'Màu giấy';

  @override
  String get newBoard => 'Bảng mới';

  @override
  String get boardName => 'Tên bảng';

  @override
  String get editBoard => 'Sửa bảng';

  @override
  String get bold => 'In đậm';

  @override
  String get italic => 'In nghiêng';

  @override
  String get defaultBoardName => 'Tường của tôi';

  @override
  String get deleteBoard => 'Xóa bảng';

  @override
  String deleteBoardConfirm(String name) {
    return 'Xóa “$name”?';
  }

  @override
  String boardTrashed(String name) {
    return 'Đã chuyển “$name” vào Thùng rác';
  }

  @override
  String get trashNotes => 'Ghi chú';

  @override
  String get trashBoards => 'Bảng';

  @override
  String boardInTrash(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ghi chú',
      zero: 'Bảng trống',
    );
    return '$_temp0';
  }

  @override
  String boardRestored(String name) {
    return 'Đã khôi phục “$name”';
  }

  @override
  String deleteBoardForeverConfirm(String name) {
    return 'Xóa vĩnh viễn “$name” và mọi thứ trên đó? Không thể lấy lại.';
  }

  @override
  String get moveToBoard => 'Chuyển sang bảng khác';

  @override
  String get duplicate => 'Nhân bản';

  @override
  String get copy => 'Sao chép';

  @override
  String get copyToBoard => 'Sao chép sang bảng khác';

  @override
  String copiedToBoard(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã sao chép $count ghi chú sang “$name”',
    );
    return '$_temp0';
  }

  @override
  String get fitAll => 'Xem toàn cảnh';

  @override
  String get gestureTips => 'Mẹo cử chỉ';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsGeneral => 'Chung';

  @override
  String get settingsData => 'Dữ liệu';

  @override
  String get settingsHelp => 'Trợ giúp';

  @override
  String get settingsAbout => 'Giới thiệu';

  @override
  String get backupRestore => 'Sao lưu & khôi phục';

  @override
  String get comingSoon => 'Sắp có';

  @override
  String get sendFeedback => 'Gửi góp ý';

  @override
  String get feedbackSubject => 'Góp ý cho Sticky Wall';

  @override
  String feedbackNoMail(String email) {
    return 'Không tìm thấy ứng dụng email. Hãy viết tới $email';
  }

  @override
  String get termsOfService => 'Điều khoản dịch vụ';

  @override
  String get deleteAllData => 'Xóa toàn bộ dữ liệu';

  @override
  String get deleteAllDataHint =>
      'Mọi bảng, ghi chú, ảnh và ghi âm trên điện thoại này';

  @override
  String get deleteAllTitle => 'Xóa toàn bộ dữ liệu?';

  @override
  String get deleteAllBody =>
      'Thao tác này xóa mọi bảng và ghi chú trên điện thoại này, Thùng rác, ảnh, ghi âm và các bản sao lưu tự động. Cài đặt và Sticky Wall Pro vẫn giữ nguyên. Nếu đang bật đồng bộ, đồng bộ sẽ được tắt trước để các máy khác vẫn giữ bản của chúng. Hãy sao lưu trước nếu bạn có thể cần lấy lại.';

  @override
  String get deleteAllContinue => 'Tiếp tục';

  @override
  String get deleteAllSureTitle => 'Bạn chắc chứ?';

  @override
  String get deleteAllSureBody => 'Không thể hoàn tác.';

  @override
  String get deleteAllDone => 'Đã xóa toàn bộ dữ liệu';

  @override
  String get wallSemantics =>
      'Tường. Nhấn giữ chỗ trống để dán ghi chú vào đó.';

  @override
  String get gotIt => 'Đã hiểu';

  @override
  String get tipDragTitle => 'Kéo, xoay, đổi cỡ';

  @override
  String get tipDragBody =>
      'Kéo ghi chú bằng một ngón. Đặt hai ngón lên ghi chú để xoay và chụm lại để đổi cỡ, hoặc dùng hai nút nắm ở góc dưới: bên phải để đổi cỡ, bên trái để xoay (chạm vào nút đó để đặt thẳng lại).';

  @override
  String get tipPinTitle => 'Ghim và dây';

  @override
  String get tipPinBody =>
      'Chạm vào ghim để giữ ghi chú ở trên cùng. Kéo từ ghim sang ghi chú khác để nối dây; chạm vào dây để đổi màu, ghi chữ, thêm mũi tên hoặc cắt.';

  @override
  String get tipWallTitle => 'Tường';

  @override
  String get tipWallBody =>
      'Nhấn giữ chỗ trống để dán ghi chú hoặc ảnh tại đó. Chụm hai ngón để phóng to, thu nhỏ; kéo ra tận lề tường để đặt ghi chú ở đó. Chạm hai lần vào ghi chú để phóng to nó; nút khung hiện toàn cảnh.';

  @override
  String get tipDropTitle => 'Chuyển sang bảng khác';

  @override
  String get tipDropBody =>
      'Thả ghi chú đang kéo lên thẻ tên của một bảng để chuyển sang bảng đó. Muốn xóa ghi chú, hãy nhấn giữ rồi chọn Xóa; ghi chú nằm trong Thùng rác 30 ngày.';

  @override
  String get tipSelectTitle => 'Chọn nhiều';

  @override
  String get tipSelectBody =>
      'Nhấn giữ ghi chú → Chọn. Bắt đầu từ chỗ trống, khoanh một vòng quanh các ghi chú để chọn thêm; kéo một ghi chú đang chọn là cả nhóm đi theo.';

  @override
  String get tipDrawTitle => 'Vẽ lên tường';

  @override
  String get tipDrawBody =>
      'Nút bút trên thanh công cụ mở chế độ vẽ: một ngón vẽ phía sau các ghi chú, hai ngón vẫn phóng to, thu nhỏ. Cục tẩy xóa từng nét một; nút Hoàn tác và Xong nằm ở thanh dưới.';

  @override
  String get tipUndoTitle => 'Hoàn tác';

  @override
  String get tipUndoBody =>
      'Nút Hoàn tác hiện vài giây sau mỗi lần kéo, xoay, đổi cỡ, xếp gọn hay chuyển bảng.';

  @override
  String movedToBoard(String name) {
    return 'Đã chuyển sang “$name”';
  }

  @override
  String get dataSection => 'Sao lưu';

  @override
  String get exportData => 'Sao lưu ghi chú';

  @override
  String get importData => 'Khôi phục';

  @override
  String get importHint => 'Dán bản sao lưu vào đây';

  @override
  String get importSuccess => 'Đã khôi phục bản sao lưu';

  @override
  String get importFailed => 'Không đọc được bản sao lưu';

  @override
  String get importReplaceWarning =>
      'Sau đó bạn chọn: gộp bản sao lưu vào dữ liệu hiện có, hoặc thay thế toàn bộ.';

  @override
  String get typeAudio => 'Ghi âm';

  @override
  String get recordHint => 'Chạm để ghi âm, hoặc giữ rồi thả ra';

  @override
  String get recordStart => 'Bắt đầu ghi âm';

  @override
  String get recordStop => 'Dừng ghi âm';

  @override
  String get recordingNow => 'Đang ghi âm';

  @override
  String get recordAgain => 'Ghi lại';

  @override
  String get deleteRecording => 'Xóa bản ghi âm';

  @override
  String get playVoice => 'Phát ghi âm';

  @override
  String get pauseVoice => 'Tạm dừng ghi âm';

  @override
  String get recordingRequired => 'Hãy ghi âm trước đã';

  @override
  String get micDenied =>
      'Sticky Wall chưa được dùng micrô. Hãy cho phép trong phần cài đặt của máy để ghi âm.';

  @override
  String get recordFailed => 'Không ghi âm được. Hãy thử lại.';

  @override
  String get recordingMissing => 'Bản ghi này không còn trên máy';

  @override
  String get autoBackup => 'Tự động sao lưu hằng tuần';

  @override
  String get autoBackupHint => 'Giữ 4 bản gần nhất ngay trên máy';

  @override
  String autoBackupLast(String date) {
    return 'Lần sao lưu tự động gần nhất: $date';
  }

  @override
  String get autoBackupNone => 'Chưa có bản sao lưu tự động nào';

  @override
  String get autoBackupRestore => 'Khôi phục bản này';

  @override
  String get autoBackupMissing =>
      'Không tìm thấy bản sao lưu tự động nào trên máy';

  @override
  String get importChooseFile => 'Chọn tệp';

  @override
  String get importNotJson =>
      'Đây không phải tệp sao lưu, hoặc bị thiếu một phần. Hãy dán trọn cả tệp, không thiếu đoạn nào.';

  @override
  String get importNotBackup => 'Đây không phải bản sao lưu của Sticky Wall.';

  @override
  String get importNewerVersion =>
      'Bản sao lưu này được tạo bởi phiên bản Sticky Wall mới hơn. Hãy cập nhật ứng dụng rồi thử lại.';

  @override
  String get importTooLarge =>
      'Bản sao lưu quá lớn để mở trên điện thoại này (trên 300 MB). Hãy sao lưu nhỏ hơn trên máy kia, hoặc chuyển ít ảnh hơn mỗi lần.';

  @override
  String get syncTitle => 'Đồng bộ giữa các thiết bị';

  @override
  String get syncOffHint => 'Tắt: mọi thứ chỉ nằm trên điện thoại này';

  @override
  String get syncReady => 'Đang bật';

  @override
  String syncDone(String when) {
    return 'Đã đồng bộ $when';
  }

  @override
  String get syncSyncing => 'Đang đồng bộ…';

  @override
  String get syncOffline => 'Mất mạng: sẽ đồng bộ khi có mạng lại';

  @override
  String get syncAuthNeeded =>
      'Google cần bạn cho phép lại: hãy tắt rồi bật đồng bộ';

  @override
  String get syncQuota =>
      'Google Drive của bạn đã đầy, nên chưa gửi được gì mới';

  @override
  String get syncFailed =>
      'Lần này chưa đồng bộ được. Ghi chú trên máy vẫn nguyên.';

  @override
  String get syncExplain =>
      'Giữ bảng, ghi chú, dây nối, ảnh, ghi âm và Thùng rác giống nhau trên mọi máy Android đăng nhập cùng tài khoản Google. Dùng một thư mục ẩn của Sticky Wall trong Google Drive của bạn; các tệp Drive khác không bao giờ bị đọc. Vẫn dùng được khi mất mạng và tự đồng bộ sau. Không thay cho sao lưu: thao tác xóa cũng được đồng bộ, nên vẫn hãy sao lưu.';

  @override
  String get syncWithDrive => 'Đồng bộ với Google Drive';

  @override
  String get syncIncludeLocked => 'Gồm cả bảng có khóa';

  @override
  String get syncIncludeLockedHint =>
      'Bảng có khóa chỉ khóa trong app, không mã hóa: khi bật, ghi chú của bảng đó được lưu trong Google Drive như các bảng khác.';

  @override
  String get syncNow => 'Đồng bộ ngay';

  @override
  String syncConflicts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count ghi chú bị sửa trên hai máy cùng lúc: cả hai bản đều được giữ.',
    );
    return '$_temp0';
  }

  @override
  String syncMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ảnh hoặc ghi âm từ máy khác chưa về tới.',
    );
    return '$_temp0';
  }

  @override
  String get syncOffNote =>
      'Tắt đồng bộ vẫn giữ mọi thứ trên điện thoại này. Bản trong Google Drive vẫn còn cho các máy khác; muốn xóa thì vào cài đặt Google Drive → Quản lý ứng dụng.';

  @override
  String get syncPrivacy =>
      'Sticky Wall không có máy chủ: dữ liệu chỉ đi tới Google Drive của chính bạn. iPhone và Android không đồng bộ với nhau; chuyển giữa hai bên bằng tệp sao lưu.';

  @override
  String get syncConnectFailed =>
      'Không kết nối được Google Drive. Kiểm tra mạng hoặc thử lại sau.';

  @override
  String get backupFailed => 'Không tạo được bản sao lưu';

  @override
  String get backupShareSubject => 'Bản sao lưu Sticky Wall';

  @override
  String restoredTo(String board) {
    return 'Đã khôi phục vào “$board”';
  }

  @override
  String get shareFailed => 'Không chia sẻ được';

  @override
  String get share => 'Chia sẻ';

  @override
  String get cropDone => 'Cắt xong';

  @override
  String get penThin => 'Bút nét mảnh';

  @override
  String get penMedium => 'Bút nét vừa';

  @override
  String get penThick => 'Bút nét đậm';

  @override
  String get colorInk => 'Mực';

  @override
  String get colorChalk => 'Phấn trắng';

  @override
  String get colorRed => 'Đỏ';

  @override
  String get colorOrange => 'Cam';

  @override
  String get colorAmber => 'Vàng nghệ';

  @override
  String get colorGreen => 'Xanh lá';

  @override
  String get colorBlue => 'Xanh dương';

  @override
  String get colorViolet => 'Tím';

  @override
  String get colorPink => 'Hồng';

  @override
  String get toneWhite => 'Giấy trắng';

  @override
  String get toneCream => 'Giấy kem';

  @override
  String get toneBlush => 'Giấy hồng phấn';

  @override
  String get toneSky => 'Giấy xanh trời';

  @override
  String get toneMint => 'Giấy bạc hà';

  @override
  String get toneKraft => 'Giấy kraft';

  @override
  String get toneChalkboard => 'Bảng đen';

  @override
  String get discardChangesTitle => 'Bỏ các thay đổi?';

  @override
  String get saveChangesTitle => 'Lưu các thay đổi cho ghi chú này?';

  @override
  String get keepEditing => 'Sửa tiếp';

  @override
  String get discard => 'Bỏ';

  @override
  String get deleteForeverConfirm =>
      'Xóa hẳn ghi chú này? Sẽ không lấy lại được nữa.';

  @override
  String deleteBoardWithNotes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count ghi chú trên bảng sẽ vào Thùng rác cùng bảng. Bạn có thể khôi phục bảng trong 30 ngày.',
    );
    return '$_temp0';
  }

  @override
  String get reminderInPast => 'Giờ đó đã qua — hãy chọn giờ muộn hơn.';

  @override
  String get notificationsOff =>
      'Thông báo của Sticky Wall đang tắt nên lời nhắc này sẽ không reo. Hãy bật lại trong cài đặt của máy.';

  @override
  String get removeReminder => 'Bỏ lời nhắc';

  @override
  String get remindInHour => 'Một tiếng nữa';

  @override
  String get remindTonight => 'Tối nay';

  @override
  String get remindTomorrow => 'Sáng mai';

  @override
  String get remindPick => 'Chọn ngày và giờ';

  @override
  String get pinShort => 'Ghim';

  @override
  String get toolFilter => 'Lọc';

  @override
  String get toolPen => 'Bút';

  @override
  String get toolSort => 'Sắp xếp';

  @override
  String get toolLayout => 'Bố cục';

  @override
  String get toolMore => 'Khác';

  @override
  String get addOtherKinds => 'Thêm loại ghi chú khác';

  @override
  String get addOtherKindsShort => 'Loại khác';

  @override
  String get colorShort => 'Màu';

  @override
  String typeChangeDrops(String type) {
    return 'Lưu thành “$type”? Hình vẽ hoặc địa chỉ liên kết sẽ không được giữ lại.';
  }

  @override
  String get saveAnyway => 'Vẫn lưu';

  @override
  String get paperAuto => 'Màu tự động';

  @override
  String get paperYellow => 'Vàng';

  @override
  String get paperPink => 'Hồng';

  @override
  String get paperMint => 'Xanh bạc hà';

  @override
  String get paperBlue => 'Xanh dương';

  @override
  String get paperOrange => 'Cam';

  @override
  String get paperLilac => 'Tím nhạt';

  @override
  String get swatchRed => 'Đỏ';

  @override
  String get swatchOrange => 'Cam';

  @override
  String get swatchGold => 'Vàng kim';

  @override
  String get swatchGreen => 'Xanh lá';

  @override
  String get swatchBlue => 'Xanh dương';

  @override
  String get swatchPurple => 'Tím';

  @override
  String get swatchInk => 'Mực';

  @override
  String get swatchChalk => 'Phấn trắng';

  @override
  String get locked => 'Đã khóa';

  @override
  String get selectHint => 'Chạm vào ghi chú, hoặc khoanh một vòng quanh chúng';

  @override
  String filterShowing(String what) {
    return 'Đang lọc: $what';
  }

  @override
  String get clearFilter => 'Bỏ lọc';

  @override
  String get undoMove => 'Hoàn tác di chuyển';

  @override
  String get undoResize => 'Hoàn tác đổi cỡ';

  @override
  String get undoRotate => 'Hoàn tác xoay';

  @override
  String get undoTidy => 'Hoàn tác xếp gọn';

  @override
  String get undoMoveBoard => 'Hoàn tác chuyển bảng';

  @override
  String get clearInkConfirm => 'Xóa hết nét vẽ trên tường này?';

  @override
  String get photoMissing => 'Không tìm thấy ảnh trên máy này';

  @override
  String get photoPickFailed => 'Không mở được ảnh đó';

  @override
  String get sizeAndTurn => 'Cỡ và góc xoay';

  @override
  String get smaller => 'Nhỏ lại';

  @override
  String get larger => 'To lên';

  @override
  String get turnLeft => 'Xoay trái';

  @override
  String get turnRight => 'Xoay phải';

  @override
  String get straighten => 'Để thẳng';

  @override
  String get tieThreadTo => 'Nối dây tới…';

  @override
  String get threadsOfNote => 'Dây nối';

  @override
  String get noOtherNotes => 'Bảng này không còn ghi chú nào khác để nối';

  @override
  String get moveBoardLeft => 'Chuyển sang trái';

  @override
  String get moveBoardRight => 'Chuyển sang phải';

  @override
  String get resize => 'Đổi cỡ';

  @override
  String get untitledNote => 'Ghi chú không tên';

  @override
  String get remindersChannel => 'Lời nhắc';

  @override
  String get remindersChannelDescription => 'Lời nhắc bạn đặt trên ghi chú';

  @override
  String get stackNotes => 'Xếp chồng với…';

  @override
  String get stackSelected => 'Xếp chồng';

  @override
  String stackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ghi chú trong chồng này',
    );
    return '$_temp0';
  }

  @override
  String get unstack => 'Trải ra';

  @override
  String otherBoardsMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Thêm $count ở bảng khác',
    );
    return '$_temp0';
  }

  @override
  String get onOtherBoards => 'Ở bảng khác';

  @override
  String get proTitle => 'Sticky Wall Pro';

  @override
  String get proPitch =>
      'Trả một lần, dùng mãi mãi. Mọi thứ bạn đang có vẫn miễn phí.';

  @override
  String get proPerkPapers => 'Thêm 6 màu giấy';

  @override
  String get proPerkWalls => 'Thêm 5 kiểu tường';

  @override
  String get proPerkFonts => 'Thêm 5 phông chữ';

  @override
  String get proPerkPins =>
      'Thêm 5 kiểu ghim ghi chú: ghim nhiều màu, đinh bấm, băng dính washi, kẹp giấy và nam châm';

  @override
  String proBuy(String price) {
    return 'Mở khóa với giá $price';
  }

  @override
  String get proBuyNoPrice => 'Mở khóa Pro';

  @override
  String get proRestore => 'Khôi phục giao dịch';

  @override
  String get proRestored => 'Đã khôi phục Pro. Chào mừng bạn trở lại!';

  @override
  String get proRestoreNone =>
      'Không tìm thấy giao dịch nào trước đây với tài khoản này.';

  @override
  String get proUnlocked => 'Đã mở khóa Pro. Cảm ơn bạn!';

  @override
  String get proPending =>
      'Đang chờ thanh toán. Pro sẽ mở ngay khi cửa hàng ứng dụng xác nhận.';

  @override
  String get proFailed => 'Giao dịch chưa thành công. Bạn thử lại nhé.';

  @override
  String get proUnavailable =>
      'Hiện chưa mua được. Hãy kiểm tra kết nối mạng và tài khoản cửa hàng ứng dụng rồi thử lại.';

  @override
  String get proKeepsLook =>
      'Ghi chú vẫn giữ giấy và kiểu Pro dù bạn chuyển đi đâu.';

  @override
  String proLocked(String name) {
    return '$name, Pro';
  }

  @override
  String get proSettingsHint =>
      'Sticker, kiểu giấy, tường, phông chữ, kiểu ghim và nhiều thứ khác';

  @override
  String get proSettingsThanks => 'Đã mở khóa. Cảm ơn bạn!';

  @override
  String get paperLime => 'Xanh chanh';

  @override
  String get paperCoral => 'San hô';

  @override
  String get paperPeriwinkle => 'Tím xanh';

  @override
  String get paperSage => 'Xanh xám';

  @override
  String get paperKraft => 'Giấy kraft';

  @override
  String get paperWhite => 'Trắng';

  @override
  String get wallChalkNavy => 'Bảng xanh navy';

  @override
  String get wallChalkWine => 'Bảng đỏ rượu';

  @override
  String get wallBlush => 'Vữa hồng';

  @override
  String get wallSage => 'Vữa xanh xám';

  @override
  String get wallSky => 'Vải xanh trời';

  @override
  String get pinSection => 'Kiểu ghim';

  @override
  String get pinClassic => 'Ghim đỏ';

  @override
  String get pinColorful => 'Ghim nhiều màu';

  @override
  String get pinTack => 'Đinh bấm';

  @override
  String get pinWashi => 'Băng dính washi';

  @override
  String get pinClip => 'Kẹp giấy';

  @override
  String get pinMagnet => 'Nam châm';

  @override
  String get privacySection => 'Riêng tư';

  @override
  String get privacyPolicy => 'Chính sách quyền riêng tư';

  @override
  String get privacyPolicyHint =>
      'Sticky Wall lưu gì và lưu ở đâu. Mở trong trình duyệt.';

  @override
  String get appLock => 'Khóa ứng dụng';

  @override
  String get appLockHint =>
      'Hỏi vân tay, khuôn mặt hoặc khóa màn hình khi mở Sticky Wall, và khi quay lại sau hơn một phút.';

  @override
  String get appLockReason => 'Mở khóa Sticky Wall';

  @override
  String get appLockLocked => 'Sticky Wall đang khóa';

  @override
  String get appLockUnlock => 'Mở khóa';

  @override
  String get appLockNoLock => 'Hãy đặt khóa màn hình cho điện thoại trước.';

  @override
  String get widgetSection => 'Widget màn hình chính';

  @override
  String get widgetSettingsHint => 'Bảng nào, hiện gì, màu và cỡ chữ';

  @override
  String get widgetBoardLabel => 'Bảng';

  @override
  String get widgetBoardCurrent => 'Bảng đang mở';

  @override
  String get widgetContentLabel => 'Hiển thị';

  @override
  String get widgetContentPinned => 'Ghi chú đã ghim';

  @override
  String get widgetContentNewest => 'Ghi chú mới nhất';

  @override
  String get widgetContentPicture => 'Ảnh của bảng';

  @override
  String get widgetLookLabel => 'Màu';

  @override
  String get widgetLookWall => 'Nâu tường';

  @override
  String get widgetLookPaper => 'Giấy';

  @override
  String get widgetLookInk => 'Mực';

  @override
  String get widgetTextSizeLabel => 'Cỡ chữ';

  @override
  String get widgetTextSmall => 'Nhỏ';

  @override
  String get widgetTextNormal => 'Vừa';

  @override
  String get widgetTextLarge => 'Lớn';

  @override
  String get widgetEmptyPinned => 'Chưa ghim ghi chú nào';

  @override
  String get widgetEmptyNewest => 'Chưa có ghi chú nào';

  @override
  String get widgetAddHint =>
      'Cách thêm: nhấn giữ chỗ trống trên màn hình chính, thêm tiện ích rồi chọn Sticky Wall.';

  @override
  String get swatchPink => 'Hồng';

  @override
  String get swatchTeal => 'Xanh mòng két';

  @override
  String get swatchBrown => 'Nâu';

  @override
  String get swatchWhite => 'Trắng';

  @override
  String get swatchYellow => 'Vàng';

  @override
  String get paperPlain => 'Trơn';

  @override
  String get paperLined => 'Kẻ dòng';

  @override
  String get paperGrid => 'Kẻ ô';

  @override
  String get paperDots => 'Chấm bi';

  @override
  String get paperIndex => 'Thẻ ghi chú';

  @override
  String get paperNotebook => 'Trang vở';

  @override
  String get typeSticker => 'Sticker';

  @override
  String get stickerHere => 'Dán sticker ở đây';

  @override
  String get stickerPick => 'Chọn sticker';

  @override
  String get stampUrgent => 'Gấp';

  @override
  String get stampDone => 'Xong';

  @override
  String get stampImportant => 'Quan trọng';

  @override
  String get stampLater => 'Để sau';

  @override
  String get stickerArrow => 'Mũi tên';

  @override
  String get stickerCircle => 'Khoanh tròn';

  @override
  String get stickerUnderline => 'Gạch chân';

  @override
  String get stickerRing => 'Vết cà phê';

  @override
  String get highlighter => 'Bút dạ quang';

  @override
  String get threadStyle => 'Loại dây';

  @override
  String get threadYarn => 'Len';

  @override
  String get threadTwine => 'Dây đay';

  @override
  String get threadRibbon => 'Ruy băng';

  @override
  String get threadDashed => 'Nét đứt';

  @override
  String get threadBeads => 'Chuỗi hạt';

  @override
  String get tryingOn =>
      'Đang thử: trông sẽ như thế này. Mở khóa Pro để giữ lại.';

  @override
  String get tryOnStop => 'Trả lại như cũ';

  @override
  String get tryOnKeep => 'Giữ lại';

  @override
  String get proNudge =>
      'Bạn thích Sticky Wall? Bản Pro có thêm sticker, kiểu giấy, tường, phông chữ và nhiều thứ khác, chỉ trả một lần.';

  @override
  String get proNudgeAction => 'Xem Pro';

  @override
  String get proPerkPaperStyles =>
      '5 kiểu giấy: kẻ dòng, kẻ ô, chấm bi, thẻ ghi chú, trang vở';

  @override
  String get proPerkStickers =>
      'Trọn bộ sticker: con dấu, hình vẽ tay và các gói minh họa';

  @override
  String get proPerkMarkers => 'Thêm 5 màu bút và bút dạ quang để vẽ lên tường';

  @override
  String get proPerkThreads =>
      '4 loại dây (dây đay, ruy băng, nét đứt, chuỗi hạt) và thêm 4 màu';

  @override
  String get proTryHint =>
      'Chạm vào tường, phông chữ hoặc kiểu ghim có nhãn PRO trong Tùy chỉnh để thử ngay trên tường của bạn.';

  @override
  String get paperCustom => 'Màu của bạn';

  @override
  String get paperCustomTitle => 'Pha màu giấy';

  @override
  String get inkCustomTitle => 'Pha màu bút';

  @override
  String get inkCustom => 'Màu tùy chọn';

  @override
  String get paperCustomHue => 'Màu';

  @override
  String get paperCustomStrength => 'Độ đậm';

  @override
  String get paperCustomLightness => 'Độ sáng';

  @override
  String get boardMakePrivate => 'Khóa bảng này';

  @override
  String get boardMakePublic => 'Bỏ khóa bảng';

  @override
  String get boardPrivateHint =>
      'Mở bằng vân tay hoặc khóa màn hình; không hiện trên widget, khi tìm kiếm và trong nội dung lời nhắc. Đây là khóa trong ứng dụng, không phải mã hóa.';

  @override
  String get boardPrivate => 'Bảng có khóa';

  @override
  String get boardShutHint =>
      'Ghi chú trong bảng được ẩn cho tới khi bạn mở khóa.';

  @override
  String get boardUnlockReason => 'Mở bảng có khóa';

  @override
  String get reminderPrivate => 'Lời nhắc trong một bảng có khóa';

  @override
  String get widgetPrivate => 'Bảng có khóa';

  @override
  String get packEveryday => 'Thường ngày';

  @override
  String get packTet => 'Tết';

  @override
  String get packChristmas => 'Giáng Sinh';

  @override
  String get packMidAutumn => 'Trung Thu';

  @override
  String get packValentine => 'Valentine';

  @override
  String get stampNewYear => 'Chúc mừng năm mới';

  @override
  String get stampMerry => 'Giáng Sinh an lành';

  @override
  String get stampMidAutumn => 'Trung Thu';

  @override
  String get stampLove => 'Thương nhiều';

  @override
  String get stickerMai => 'Hoa mai';

  @override
  String get stickerDao => 'Hoa đào';

  @override
  String get stickerStarLantern => 'Đèn ông sao';

  @override
  String get wallTet => 'Tết · hoa mai';

  @override
  String get wallTetDao => 'Tết · hoa đào';

  @override
  String get wallXmas => 'Xanh Giáng Sinh';

  @override
  String get wallMoon => 'Đêm Trung Thu';

  @override
  String get wallLove => 'Hồng Valentine';

  @override
  String get proPerkSeasons =>
      'Gói theo mùa: tường và sticker Tết, Giáng Sinh, Trung Thu, Valentine';

  @override
  String get proPerkPrivate => 'Khóa bảng bằng vân tay hoặc khóa màn hình';

  @override
  String get proPerkCustomColor => 'Tự pha màu giấy theo ý thích';

  @override
  String seasonUntil(String date) {
    return 'đến $date';
  }

  @override
  String get confirmItsYou => 'Xác nhận là bạn';

  @override
  String get galleryTitle => 'Mẫu & chủ đề';

  @override
  String get galleryTemplates => 'Mẫu bảng';

  @override
  String get galleryThemes => 'Chủ đề';

  @override
  String get gallerySearch => 'Tìm mẫu';

  @override
  String get galleryAll => 'Tất cả';

  @override
  String get galleryFree => 'Miễn phí';

  @override
  String get galleryNothing => 'Không có mẫu nào khớp.';

  @override
  String get catProductivity => 'Kế hoạch & danh sách';

  @override
  String get catStudy => 'Học tập';

  @override
  String get catCreative => 'Sáng tạo';

  @override
  String get catPersonal => 'Cá nhân';

  @override
  String get catFamily => 'Gia đình';

  @override
  String get catSeasonal => 'Theo mùa';

  @override
  String get catClassic => 'Cổ điển';

  @override
  String get useTemplate => 'Dùng mẫu này';

  @override
  String templateLook(String name) {
    return 'Chủ đề: $name';
  }

  @override
  String templateFreeLook(String name) {
    return 'Không có Pro, bảng này dùng giao diện “$name” như ảnh trên. Pro mở giao diện gốc của mẫu.';
  }

  @override
  String templateUsed(String name) {
    return '“$name” đã sẵn sàng. Sửa ghi chú nào cũng được, hoặc xóa nội dung mẫu trong menu của bảng.';
  }

  @override
  String applyTheme(String board) {
    return 'Áp dụng cho bảng này';
  }

  @override
  String themeApplied(String name) {
    return 'Đã áp dụng “$name”';
  }

  @override
  String get themeKeepsContent =>
      'Đổi tường, màu giấy và dòng kẻ, ghim, phông chữ và dây nối của bảng này. Chữ bạn viết và vị trí ghi chú giữ nguyên.';

  @override
  String get proUnlock => 'Mở khóa bằng Pro';

  @override
  String get previewNoteA => 'Gọi tiệm bánh';

  @override
  String get previewNoteB => 'Dã ngoại Chủ Nhật';

  @override
  String get previewItemA => 'Vé';

  @override
  String get previewItemB => 'Đồ ăn vặt';

  @override
  String get newBoardBlank => 'Bảng trống';

  @override
  String get newBoardFromTemplate => 'Từ một mẫu';

  @override
  String get newBoardFromTemplateHint =>
      '45 bảng để bắt đầu: kế hoạch, học tập, gia đình, cảm hứng…';

  @override
  String get clearSamples => 'Xóa nội dung mẫu';

  @override
  String get clearSamplesHint => 'Giữ tiêu đề, sticker và tường';

  @override
  String get samplesCleared => 'Đã xóa nội dung mẫu';

  @override
  String get changeTheme => 'Đổi chủ đề';

  @override
  String get welcomeTemplate => 'Chọn một mẫu';

  @override
  String get welcomeTemplateHint =>
      'Kế hoạch, bảng học, bảng cảm hứng và nhiều nữa, sửa được ngay';

  @override
  String get welcomeBlank => 'Bắt đầu với tường trống';

  @override
  String get welcomeBlankHint => 'Các ghi chú mẫu sẽ được xóa';

  @override
  String get welcomeExplore => 'Khám phá tường mẫu';

  @override
  String get welcomeExploreHint =>
      'Vài ghi chú chỉ cách dùng; xóa lúc nào cũng được';

  @override
  String get memoryWall => 'Tường kỷ niệm';

  @override
  String get memoryWallHint =>
      'Nhiều ảnh một lúc, tự xếp sẵn, sửa được từng tấm';

  @override
  String memoryPhotoCount(int count) {
    return '$count ảnh';
  }

  @override
  String memoryTooMany(int max) {
    return 'Mỗi tường kỷ niệm giữ tối đa $max ảnh; sẽ dùng $max ảnh đầu tiên.';
  }

  @override
  String get memoryLayout => 'Bố cục';

  @override
  String get memoryPreview => 'Xem trước tường kỷ niệm với ảnh của bạn';

  @override
  String get layoutCollage => 'Cắt dán';

  @override
  String get layoutPrints => 'Xếp hàng';

  @override
  String get layoutFilm => 'Dải phim';

  @override
  String get layoutTimeline => 'Dòng thời gian';

  @override
  String get memoryLook => 'Chủ đề';

  @override
  String get memoryCreate => 'Tạo tường';

  @override
  String get memoryAddPhotos => 'Thêm ảnh';

  @override
  String memoryAddPhotosHint(int max) {
    return 'Chọn nhiều ảnh rồi xác nhận. Bạn có thể thêm tối đa $max ảnh tại đây.';
  }

  @override
  String memoryDuplicates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ảnh đã được chọn rồi nên được bỏ qua.',
    );
    return '$_temp0';
  }

  @override
  String memoryRemovePhoto(int n) {
    return 'Bỏ ảnh $n';
  }

  @override
  String get memoryTitle => 'Kỷ niệm';

  @override
  String memoryMade(int count) {
    return 'Đã dán $count ảnh lên tường kỷ niệm. Chạm vào ảnh để thêm chú thích.';
  }

  @override
  String get allBoards => 'Tất cả bảng';

  @override
  String boardNoteCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ghi chú',
      zero: 'Chưa có ghi chú',
    );
    return '$_temp0';
  }

  @override
  String get duplicateBoard => 'Nhân bản bảng';

  @override
  String boardCopyName(String name) {
    return '$name (bản sao)';
  }

  @override
  String get boardDuplicated => 'Đã nhân bản bảng';

  @override
  String get shareWhere => 'Lưu vào bảng nào?';

  @override
  String sharedPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã nhận $count ảnh',
    );
    return '$_temp0';
  }

  @override
  String get sharePinPhotos => 'Ghim lên một bảng';

  @override
  String get sharePinPhotosHint => 'Mỗi ảnh thành một tấm in riêng';

  @override
  String sharedSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count ảnh không dùng được: quá lớn, không đọc được, hoặc vượt quá 20 ảnh mỗi lần chia sẻ.',
    );
    return '$_temp0';
  }

  @override
  String sharedSaved(String board) {
    return 'Đã lưu vào “$board”';
  }

  @override
  String get openNote => 'Mở';

  @override
  String get restoreTitle => 'Khôi phục bản sao lưu';

  @override
  String restoreMade(String date) {
    return 'Tạo lúc $date';
  }

  @override
  String get restoreUnknownDate => 'Không rõ ngày tạo';

  @override
  String restoreSize(String size) {
    return '$size MB';
  }

  @override
  String get restoreBoards => 'Bảng';

  @override
  String get restoreNotes => 'Ghi chú';

  @override
  String restoreInTrash(int count) {
    return '$count trong thùng rác';
  }

  @override
  String get restorePhotos => 'Ảnh';

  @override
  String get restoreRecordings => 'Ghi âm';

  @override
  String get restoreThreads => 'Dây nối';

  @override
  String get restoreStickers => 'Sticker';

  @override
  String get restoreLocked => 'Bảng có khóa';

  @override
  String get restoreBoardsInTrash => 'Bảng trong Thùng rác';

  @override
  String get restoreOmitted => 'Tệp không đọc được (bị bỏ qua)';

  @override
  String restoreConflicts(int boards, int notes) {
    return '$boards bảng và $notes ghi chú trong bản này đã có trên máy.';
  }

  @override
  String get restoreMerge => 'Gộp vào dữ liệu hiện có';

  @override
  String get restoreMergeHint =>
      'Mọi thứ đang có được giữ nguyên. Bảng và ghi chú trong bản sao lưu được thêm vào; thứ đã có sẽ không bị chép đôi.';

  @override
  String get restoreReplace => 'Thay thế toàn bộ';

  @override
  String get restoreReplaceHint =>
      'Dữ liệu hiện có được thay bằng bản sao lưu. Có Hoàn tác ngay sau đó.';

  @override
  String get restoreMerged => 'Đã gộp bản sao lưu';

  @override
  String get packFeelings => 'Cảm xúc';

  @override
  String get packStudy => 'Học tập & bàn làm việc';

  @override
  String get packHome => 'Nhà cửa';

  @override
  String get packPlanner => 'Kế hoạch';

  @override
  String get packNature => 'Thiên nhiên';

  @override
  String get packFood => 'Đồ ăn';

  @override
  String get packTravel => 'Du lịch';

  @override
  String get packVietnam => 'Việt Nam';

  @override
  String get packTapes => 'Băng dính washi';

  @override
  String get framePrint => 'Ảnh in trơn';

  @override
  String get framePolaroid => 'Polaroid';

  @override
  String get frameFilm => 'Dải phim';

  @override
  String get frameVintage => 'Cổ điển';

  @override
  String get frameTorn => 'Giấy xé';

  @override
  String get frameRounded => 'Bo tròn';

  @override
  String get frameScrapbook => 'Sổ lưu niệm';

  @override
  String get photoFrame => 'Khung ảnh';

  @override
  String get memoryCaption => 'Chú thích';

  @override
  String get captionNone => 'Không';

  @override
  String get captionNumbers => 'Đánh số';

  @override
  String get captionDate => 'Ngày hôm nay';

  @override
  String get layoutHero => 'Ảnh chính';

  @override
  String get shufflePhotos => 'Xáo vị trí ảnh';

  @override
  String get framesAll => 'Một khung cho mọi ảnh';

  @override
  String get photosShuffled => 'Đã xáo ảnh';

  @override
  String get framesApplied => 'Đã đổi khung ảnh';

  @override
  String get makeHero => 'Đặt làm ảnh chính';

  @override
  String get heroSet => 'Đã đặt ảnh chính';

  @override
  String get pinBoard => 'Ghim lên đầu';

  @override
  String get unpinBoard => 'Bỏ ghim';

  @override
  String get editedToday => 'sửa hôm nay';

  @override
  String get editedYesterday => 'sửa hôm qua';

  @override
  String editedOn(String date) {
    return 'sửa $date';
  }

  @override
  String get archiveNote => 'Lưu trữ';

  @override
  String get archiveDoneHint => 'Đã xong hết: cất đi cho gọn';

  @override
  String get archiveBoard => 'Lưu trữ';

  @override
  String get archived => 'Đã chuyển vào bảng Lưu trữ';

  @override
  String get editorReadable => 'Chữ dễ đọc';

  @override
  String get editorHandwriting => 'Chữ viết tay';

  @override
  String get wallSoften => 'Làm dịu tường phía sau ghi chú';

  @override
  String get packMarks => 'Ký hiệu ghi chú';

  @override
  String get packAnimals => 'Động vật';

  @override
  String get packGarden => 'Vườn';

  @override
  String get packOcean => 'Biển';

  @override
  String get packCozy => 'Góc ấm cúng';

  @override
  String get packHobbies => 'Sở thích';

  @override
  String get packOffice => 'Văn phòng';

  @override
  String get packLove => 'Tình yêu & tiệc';

  @override
  String get packFestiveVn => 'Tết & Trung Thu';

  @override
  String get packHolidays => 'Giáng Sinh & Halloween';

  @override
  String get addToWall => 'Thêm lên tường';

  @override
  String get addToWallHint => 'Một ý tưởng, kế hoạch hay kỷ niệm nhỏ.';

  @override
  String get addTextHint => 'Ghi lại một ý tưởng';

  @override
  String get addChecklistHint => 'Từng việc nhỏ một';

  @override
  String get addPhotoHint => 'Ghim khoảnh khắc yêu thích';

  @override
  String get addLinkHint => 'Giữ lại điều đáng xem';

  @override
  String get addVoiceHint => 'Nói ngay điều cần nhớ';

  @override
  String get addDrawingHint => 'Phác vài nét theo ý bạn';

  @override
  String get editorOptions => 'Tùy chọn ghi chú';

  @override
  String get changeNoteType => 'Đổi loại ghi chú';

  @override
  String get galleryFeatured => 'Vài gợi ý để bắt đầu';

  @override
  String get previewOnYourWall => 'Xem thử trên bảng của bạn';

  @override
  String get previewOnlyHint =>
      'Chỉ là xem thử. Bảng chỉ thay đổi khi bạn áp dụng.';

  @override
  String get memoryPreviewPro =>
      'Đang xem thử Pro. Mở khóa để tạo với giao diện này.';

  @override
  String get guideReplay => 'Xem lại hướng dẫn';

  @override
  String get guideReplayHint =>
      'Bức tường trong một phút, có tường tập. Bảng của bạn không đổi gì.';

  @override
  String guideStepOf(int step, int total) {
    return 'Bước $step trên $total';
  }

  @override
  String get guideBack => 'Quay lại';

  @override
  String get guideSkip => 'Bỏ qua';

  @override
  String get guideNext => 'Tiếp';

  @override
  String get guideDoItForMe => 'Làm giúp tôi';

  @override
  String get guideScatterTop => 'Ghi chú khắp nơi.';

  @override
  String get guideScatterKey => 'Tìm chẳng thấy.';

  @override
  String get guideScatterBody =>
      'Trên hóa đơn, mẩu giấy nhớ, điện thoại, cả tờ khăn giấy…';

  @override
  String get guideScatterAction => 'Dán hết lên tường';

  @override
  String get guideWallBefore => 'Một bức tường cho ';

  @override
  String get guideWallKey => 'tất cả';

  @override
  String get guideWallBody =>
      'Ngay trên điện thoại. Không tài khoản, không quảng cáo.';

  @override
  String get guideWallAction => 'Chỉ tôi cách dùng';

  @override
  String get guidePracticeBefore => 'Thử trên ';

  @override
  String get guidePracticeKey => 'bức tường tập';

  @override
  String get guidePracticeBody =>
      'Làm theo chỗ đang sáng. Đây chỉ là bản tập, không lưu gì cả.';

  @override
  String get guidePracticeDoneBefore => 'Vậy là ';

  @override
  String get guidePracticeDoneKey => 'xong rồi';

  @override
  String get guidePracticeDoneBody =>
      'Tờ giấy vàng để thêm ghi chú, kéo bằng một ngón để di chuyển, kéo ghim đỏ để nối dây. Chỉ là bản tập: chưa có gì được lưu.';

  @override
  String get guideTaskAdd => 'Bức tường tập. Ở đây không lưu gì.';

  @override
  String get guideTaskMove => 'Ghi chú đã lên tường.';

  @override
  String get guideTaskTie => 'Nối nó với ngày cần làm.';

  @override
  String get guideLitAdd => 'Chạm vào tờ giấy vàng';

  @override
  String get guideLitMove => 'Kéo ghi chú vào ô nét đứt';

  @override
  String get guideLitTie => 'Kéo ghim đỏ sang tờ “Thứ Bảy”';

  @override
  String get guideNoteWater => 'Tưới cây';

  @override
  String get guideNoteSaturday => 'Thứ Bảy';

  @override
  String get guideNoteMum => 'Gọi cho mẹ';

  @override
  String get guideSpot => 'Đặt ở đây';

  @override
  String get guideNothingSaved => 'Xong. Không có gì được lưu.';

  @override
  String get guideScrapPlumber => 'Gọi thợ sửa ống nước';

  @override
  String get guideScrapBirthday => 'Sinh nhật mẹ, thứ Bảy';

  @override
  String get guideScrapWifi => 'Wi-Fi: vuon2026';

  @override
  String get guideScrapFlowers => 'Mua hoa';

  @override
  String get guideChooseBefore => 'Làm theo ';

  @override
  String get guideChooseKey => 'cách của bạn';

  @override
  String get guideChooseBody =>
      'Bạn muốn bắt đầu thế nào? Mẫu và bảng mới luôn có trong menu.';

  @override
  String get guideChooseReplayBody =>
      'Mẫu & chủ đề nằm trong menu Khác, còn thẻ + mở một bảng mới, lúc nào cũng được.';

  @override
  String get guideStart => 'Bắt đầu';

  @override
  String get guideDone => 'Xong';

  @override
  String get howToUse => 'Cách dùng';

  @override
  String get howToUseHint => 'Xem lại hướng dẫn, hoặc đọc theo từng chủ đề';

  @override
  String get howToUseTopics => 'Chủ đề';

  @override
  String howToUseTopicOf(int n, int total) {
    return 'Chủ đề $n trên $total';
  }

  @override
  String get howToUsePrevious => 'Trước';

  @override
  String get manualFirstTitle => 'Ghi chú đầu tiên';

  @override
  String get manualFirstSummary =>
      'Thêm ghi chú, viết lên, sửa lúc nào cũng được.';

  @override
  String get manualFirstStep1 =>
      'Chạm vào tờ giấy vàng ở góc dưới bên phải bức tường.';

  @override
  String get manualFirstStep2 =>
      'Chọn thứ cần thêm: ghi chú, danh sách, ảnh, liên kết, ghi âm hay hình vẽ.';

  @override
  String get manualFirstStep3 =>
      'Viết xong, bấm dấu tích để dán lên. Chạm vào ghi chú để sửa; nhấn giữ để mở menu của nó.';

  @override
  String get manualMoveTitle => 'Di chuyển và sắp xếp';

  @override
  String get manualMoveSummary => 'Kéo, xoay, đổi cỡ và dọn gọn.';

  @override
  String get manualMoveStep1 => 'Kéo ghi chú bằng một ngón để di chuyển.';

  @override
  String get manualMoveStep2 =>
      'Tay nắm ở hai góc dưới để đổi cỡ (bên phải) và xoay (bên trái; chạm để dựng thẳng lại). Hai ngón cũng xoay và phóng to, thu nhỏ được.';

  @override
  String get manualMoveStep3 =>
      'Chụm hai ngón trên tường để phóng to, thu nhỏ. Mục Sắp xếp lại… trong menu Khác xếp ghi chú thành hàng gọn gàng.';

  @override
  String get manualMoveStep4 =>
      'Sau mỗi thay đổi, nút Hoàn tác hiện ra vài giây.';

  @override
  String get manualThreadTitle => 'Nối dây giữa các ghi chú';

  @override
  String get manualThreadSummary => 'Nối những ghi chú liên quan với nhau.';

  @override
  String get manualThreadStep1 =>
      'Kéo ghim đỏ của một ghi chú sang ghi chú khác: một sợi dây nối hai tờ lại.';

  @override
  String get manualThreadStep2 =>
      'Chạm vào sợi dây để đổi màu, ghi chữ, thêm mũi tên hoặc cắt dây.';

  @override
  String get manualThreadStep3 => 'Chạm vào ghim để giữ ghi chú ở trên cùng.';

  @override
  String get manualDrawTitle => 'Vẽ lên tường';

  @override
  String get manualDrawSummary => 'Bút, bút dạ quang và cục tẩy.';

  @override
  String get manualDrawStep1 =>
      'Chạm vào cây bút trên thanh công cụ để bắt đầu vẽ.';

  @override
  String get manualDrawStep2 =>
      'Một ngón để vẽ phía sau ghi chú; hai ngón vẫn kéo và phóng to tường.';

  @override
  String get manualDrawStep3 =>
      'Cục tẩy xóa từng nét một. Hoàn tác để lấy lại; Xong để thôi vẽ.';

  @override
  String get manualBoardsTitle => 'Bảng và Thùng rác';

  @override
  String get manualBoardsSummary =>
      'Nhiều bức tường, và một thùng rác an toàn.';

  @override
  String get manualBoardsStep1 =>
      'Các thẻ ở trên cùng là các bảng của bạn. Thẻ + tạo bảng mới, để trống hoặc từ mẫu.';

  @override
  String get manualBoardsStep2 =>
      'Kéo ghi chú thả vào một thẻ để chuyển sang bảng đó.';

  @override
  String get manualBoardsStep3 =>
      'Ghi chú đã xóa nằm trong Thùng rác (ở menu Khác) 30 ngày.';

  @override
  String get manualPhotosTitle => 'Ảnh và tường kỷ niệm';

  @override
  String get manualPhotosSummary => 'Ghim ảnh; làm một bức tường kỷ niệm.';

  @override
  String get manualPhotosStep1 =>
      'Nhấn giữ một chỗ trống trên tường để dán ghi chú hoặc ảnh ngay chỗ đó.';

  @override
  String get manualPhotosStep2 =>
      'Mục Ghim ảnh lên tường trong menu Khác thêm nhiều ảnh một lúc.';

  @override
  String get manualPhotosStep3 =>
      'Tường kỷ niệm tự bày nhiều ảnh giúp bạn: chạm tờ giấy vàng rồi chọn Tường kỷ niệm.';

  @override
  String get manualFindTitle => 'Tìm kiếm và chế độ xem';

  @override
  String get manualFindSummary =>
      'Tìm mọi ghi chú; xem dạng tường, lưới hoặc danh sách.';

  @override
  String get manualFindStep1 =>
      'Tìm kiếm không cần dấu: gõ “tuoi” vẫn ra “Tưới cây”.';

  @override
  String get manualFindStep2 =>
      'Chuyển giữa Tường, Lưới và Danh sách ở thanh công cụ góc dưới bên trái.';

  @override
  String get manualFindStep3 =>
      'Để làm việc với nhiều ghi chú, nhấn giữ một tờ rồi chọn Chọn nhiều ghi chú, hoặc khoanh một vòng quanh chúng từ chỗ trống.';

  @override
  String get manualKindsTitle => 'Các loại ghi chú và lời nhắc';

  @override
  String get manualKindsSummary =>
      'Danh sách, ghi âm, nhãn, sticker, và lời nhắc khi đến giờ.';

  @override
  String get manualKindsStep1 =>
      'Tờ giấy vàng có ghi chú, việc cần làm, ảnh, liên kết, ghi âm và hình vẽ; kéo xuống còn có nhãn, sticker và tường kỷ niệm.';

  @override
  String get manualKindsStep2 =>
      'Ghi âm: chạm vào micro để thu, hoặc giữ rồi thả. Bấm phát ngay trên tường.';

  @override
  String get manualKindsStep3 =>
      'Lời nhắc, trong ghi chú: sau một giờ, tối nay, sáng mai hoặc ngày giờ bất kỳ, một lần hay lặp lại hằng ngày, hằng tuần, hằng tháng.';

  @override
  String get manualKindsStep4 =>
      'Nhấn giữ ghi chú rồi chọn Khóa vị trí để không lỡ tay kéo đi.';

  @override
  String get manualLooksTitle => 'Mẫu và chủ đề';

  @override
  String get manualLooksSummary =>
      'Một bảng dựng sẵn chỉ với một chạm, và một phong cách cho nó.';

  @override
  String get manualLooksStep1 =>
      'Mục Mẫu & chủ đề trong menu Khác (hoặc thẻ +) có các mẫu bảng: kế hoạch, học tập, moodboard và nhiều nữa.';

  @override
  String get manualLooksStep2 =>
      'Mẫu tạo một bảng mới với ghi chú thật để sửa. Xóa nội dung mẫu, trong menu của bảng, chỉ giữ lại tiêu đề và bức tường.';

  @override
  String get manualLooksStep3 =>
      'Chủ đề thay áo cho bảng đang mở: tường, giấy, ghim và nét chữ. Nội dung ghi chú giữ nguyên, Hoàn tác trả lại kiểu cũ.';

  @override
  String get manualLooksStep4 =>
      'Chạm lại vào thẻ của bảng đang mở để mở menu: sửa, đổi chủ đề, khóa hoặc xóa bảng. Bảng đã xóa cũng nằm trong Thùng rác.';

  @override
  String get manualShareTitle => 'Chia sẻ và xuất';

  @override
  String get manualShareSummary =>
      'Gửi một ghi chú, cả bảng, hoặc nhận nội dung từ ứng dụng khác.';

  @override
  String get manualShareStep1 =>
      'Nhấn giữ ghi chú: Chia sẻ gửi nó thành ảnh, Lưu ảnh cất vào thư viện ảnh.';

  @override
  String get manualShareStep2 =>
      'Xuất bảng thành ảnh, trong menu Khác: cả tường hoặc phần đang xem, thành ảnh hoặc PDF.';

  @override
  String get manualShareStep3 =>
      'Ở ứng dụng khác, chia sẻ chữ, liên kết hoặc ảnh sang Sticky Wall: chọn một bảng là nó nằm ngay đó.';

  @override
  String get manualSafeTitle => 'Giữ an toàn';

  @override
  String get manualSafeSummary =>
      'Sao lưu, chuyển sang điện thoại mới, và khóa.';

  @override
  String get manualSafeStep1 =>
      'Trong Cài đặt mục Dữ liệu, Sao lưu ghi chú tạo một tệp chứa mọi bảng, ảnh và ghi âm. Mỗi tuần app cũng tự sao lưu và giữ 4 bản gần nhất trên máy.';

  @override
  String get manualSafeStep2 =>
      'Đổi điện thoại: sao lưu trên máy cũ rồi gửi tệp cho chính mình, sang máy mới bấm Khôi phục ở cùng chỗ đó. Bạn xem trước tệp có gì rồi mới thay đổi, và Hoàn tác được.';

  @override
  String get manualSafeSync =>
      'Đồng bộ giữa các thiết bị, cũng ở mục Dữ liệu, giữ các máy giống nhau qua Google Drive của chính bạn. Mặc định tắt cho đến khi bạn bật.';

  @override
  String get manualSafeStep3 =>
      'Khóa ứng dụng, trong Cài đặt mục Riêng tư, hỏi vân tay hoặc khóa màn hình khi mở app. Từng bảng cũng khóa được từ menu của bảng.';

  @override
  String get manualYoursTitle => 'Làm theo ý bạn';

  @override
  String get manualYoursSummary => 'Tường, nét chữ, Tắt đèn và widget.';

  @override
  String get manualYoursStep1 =>
      'Tùy chỉnh (bảng màu ở trên cùng) đổi tường, nét chữ và kiểu ghim. Loại Pro được thử trước.';

  @override
  String get manualYoursStep2 =>
      'Tắt đèn, trong menu Khác, làm dịu bức tường buổi tối; Tùy chỉnh có thể bật theo giờ.';

  @override
  String get manualYoursStep3 =>
      'Widget màn hình chính, trong Cài đặt mục Chung: chọn bảng và nội dung hiển thị, rồi thêm widget từ màn hình chính.';

  @override
  String get manualYoursStep4 => 'Ngôn ngữ cũng nằm trong Cài đặt mục Chung.';

  @override
  String get manualTabHome => 'Nhà';

  @override
  String get manualTabWork => 'Việc';

  @override
  String get manualSearchQuery => 'tuoi';

  @override
  String get manualPhotoCaption => 'Hè 2026';
}

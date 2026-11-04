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
  String get moreActions => 'Khác';

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
  String get dragToDelete => 'Kéo xuống chân tường để xóa';

  @override
  String get dragToDeleteHint =>
      'Một khay hiện ra ở chân tường; thả ghi chú vào đó để xóa (có Hoàn tác).';

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
  String get wallDarkMarble => 'Đá hoa đen';

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
      other: '$count đã chọn',
    );
    return '$_temp0';
  }

  @override
  String get exportPdf => 'Xuất PDF';

  @override
  String get exportMore => 'Tùy chọn nâng cao';

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
  String get bold => 'In đậm';

  @override
  String get italic => 'In nghiêng';

  @override
  String get defaultBoardName => 'Tường của tôi';

  @override
  String get deleteBoard => 'Xóa tường';

  @override
  String deleteBoardConfirm(String name) {
    return 'Xóa “$name”?';
  }

  @override
  String get moveToBoard => 'Chuyển sang tường khác';

  @override
  String get duplicate => 'Nhân đôi';

  @override
  String get copy => 'Sao chép';

  @override
  String get copyToBoard => 'Sao chép sang tường khác';

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
  String get gotIt => 'Đã hiểu';

  @override
  String get tipDragTitle => 'Kéo, xoay, đổi cỡ';

  @override
  String get tipDragBody =>
      'Kéo note bằng một ngón. Đặt hai ngón lên note để xoay và chụm phóng, hoặc dùng hai tay nắm ở góc dưới: bên phải để đổi cỡ, bên trái để xoay (chạm vào đó để thẳng lại).';

  @override
  String get tipPinTitle => 'Ghim và dây';

  @override
  String get tipPinBody =>
      'Chạm ghim để giữ note lên đầu. Kéo từ ghim sang tờ khác để nối dây; chạm vào dây để đổi màu, ghi nhãn, thêm mũi tên hoặc cắt.';

  @override
  String get tipWallTitle => 'Tường';

  @override
  String get tipWallBody =>
      'Nhấn giữ chỗ trống để dán note hoặc ảnh tại đó. Chụm để zoom, pan ra lề tường và đặt note ở đó. Chạm hai lần vào note để zoom vào; nút khung hiện toàn cảnh.';

  @override
  String get tipDropTitle => 'Chuyển sang tường khác';

  @override
  String get tipDropBody =>
      'Thả ghi chú đang kéo lên một tab tường để chuyển sang tường đó. Muốn kéo xuống khay ở chân tường để xóa thì bật trong Tùy chỉnh.';

  @override
  String get tipSelectTitle => 'Chọn nhiều';

  @override
  String get tipSelectBody =>
      'Nhấn giữ note → Chọn. Khoanh một vòng quanh các note trên chỗ trống để chọn thêm; kéo một tờ đang chọn là cả nhóm đi theo.';

  @override
  String get tipDrawTitle => 'Vẽ lên tường';

  @override
  String get tipDrawBody =>
      'Nút bút trên thanh công cụ mở chế độ vẽ: một ngón vẽ phía sau các note, hai ngón vẫn zoom. Hoàn tác, xóa hết và xong nằm ở thanh dưới.';

  @override
  String get tipUndoTitle => 'Hoàn tác';

  @override
  String get tipUndoBody =>
      'Viên Hoàn tác hiện vài giây sau mỗi lần kéo, xoay, đổi cỡ, xếp gọn hay chuyển tường.';

  @override
  String movedToBoard(String name) {
    return 'Đã chuyển sang “$name”';
  }

  @override
  String get dataSection => 'Sao lưu';

  @override
  String get exportData => 'Sao lưu ghi chú';

  @override
  String get importData => 'Nạp bản sao lưu';

  @override
  String get importHint => 'Dán bản sao lưu vào đây';

  @override
  String get importSuccess => 'Đã nạp bản sao lưu';

  @override
  String get importFailed => 'Không đọc được bản sao lưu';

  @override
  String get importReplaceWarning =>
      'Nạp bản sao lưu sẽ thay thế toàn bộ tường và ghi chú hiện tại.';

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
  String get deleteRecording => 'Xoá bản ghi';

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
  String autoBackupRestoreTitle(String date) {
    return 'Khôi phục bản sao lưu ngày $date?';
  }

  @override
  String get autoBackupMissing =>
      'Không tìm thấy bản sao lưu tự động nào trên máy';

  @override
  String get importChooseFile => 'Chọn tệp';

  @override
  String get importNotJson =>
      'Đây không phải tệp sao lưu: nội dung không đúng định dạng JSON. Hãy dán trọn cả tệp, không thiếu đoạn nào.';

  @override
  String get importNotBackup => 'Đây không phải bản sao lưu của Sticky Wall.';

  @override
  String get importNewerVersion =>
      'Bản sao lưu này được tạo bởi phiên bản Sticky Wall mới hơn. Hãy cập nhật ứng dụng rồi thử lại.';

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
      other: '$count ghi chú trên đó sẽ bị xóa hẳn, không vào thùng rác.',
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
  String get colorShort => 'Màu';

  @override
  String typeChangeDrops(String type) {
    return 'Lưu thành “$type”? Hình vẽ hoặc địa chỉ link sẽ không được giữ lại.';
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
  String get swatchGold => 'Vàng';

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
  String get undoTidy => 'Hoàn tác sắp xếp';

  @override
  String get undoMoveBoard => 'Hoàn tác chuyển tường';

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
  String get noOtherNotes => 'Trên tường này không còn ghi chú nào khác để nối';

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
  String get boardTemplate => 'Bắt đầu từ';

  @override
  String get templateBlank => 'Trống';

  @override
  String get templateKanban => 'Kanban';

  @override
  String get templateWeek => 'Kế hoạch tuần';

  @override
  String get templateBrainstorm => 'Động não';

  @override
  String get kanbanTodo => 'Cần làm';

  @override
  String get kanbanDoing => 'Đang làm';

  @override
  String get kanbanDone => 'Xong';

  @override
  String get brainstormCenter => 'Ý tưởng chính';

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
  String get stackOpen => 'Mở chồng';

  @override
  String otherBoardsMatches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Thêm $count ở tường khác',
    );
    return '$_temp0';
  }

  @override
  String get onOtherBoards => 'Ở tường khác';

  @override
  String get dayMonday => 'Thứ Hai';

  @override
  String get dayTuesday => 'Thứ Ba';

  @override
  String get dayWednesday => 'Thứ Tư';

  @override
  String get dayThursday => 'Thứ Năm';

  @override
  String get dayFriday => 'Thứ Sáu';

  @override
  String get daySaturday => 'Thứ Bảy';

  @override
  String get daySunday => 'Chủ Nhật';

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
      'Đang chờ thanh toán. Pro sẽ mở ngay khi Google Play xác nhận.';

  @override
  String get proFailed => 'Giao dịch chưa thành công. Bạn thử lại nhé.';

  @override
  String get proUnavailable =>
      'Hiện chưa mua được. Hãy kiểm tra kết nối mạng và Google Play rồi thử lại.';

  @override
  String get proKeepsLook =>
      'Ghi chú vẫn giữ màu giấy và tường Pro dù được chuyển đi đâu.';

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
      'Cách thêm: nhấn giữ màn hình chính, chọn Tiện ích → Sticky Wall.';

  @override
  String get swatchPink => 'Hồng';

  @override
  String get swatchTeal => 'Xanh mòng két';

  @override
  String get swatchBrown => 'Nâu';

  @override
  String get swatchWhite => 'Trắng';

  @override
  String get swatchYellow => 'Vàng chanh';

  @override
  String get paperPlain => 'Trơn';

  @override
  String get paperLined => 'Kẻ dòng';

  @override
  String get paperGrid => 'Ô vuông';

  @override
  String get paperDots => 'Chấm';

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
      '5 kiểu giấy: kẻ dòng, ô vuông, chấm, thẻ ghi chú, trang vở';

  @override
  String get proPerkStickers =>
      'Thêm 15 sticker: con dấu, emoji và hình vẽ tay';

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
  String get paperCustomHue => 'Màu';

  @override
  String get paperCustomStrength => 'Độ đậm';

  @override
  String get paperCustomLightness => 'Độ sáng';

  @override
  String get boardMakePrivate => 'Đặt làm riêng tư';

  @override
  String get boardMakePublic => 'Bỏ riêng tư';

  @override
  String get boardPrivateHint =>
      'Mở bằng vân tay hoặc khóa màn hình; không hiện trên widget, khi tìm kiếm và trong nội dung lời nhắc';

  @override
  String get boardPrivate => 'Bảng riêng tư';

  @override
  String get boardShutHint =>
      'Ghi chú trong bảng được ẩn cho tới khi bạn mở khóa.';

  @override
  String get boardUnlockReason => 'Mở bảng riêng tư';

  @override
  String get reminderPrivate => 'Lời nhắc trong một bảng riêng tư';

  @override
  String get widgetPrivate => 'Bảng riêng tư';

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
  String get proPerkPrivate => 'Bảng riêng tư, mở bằng vân tay';

  @override
  String get proPerkCustomColor => 'Tự pha màu giấy theo ý thích';

  @override
  String seasonUntil(String date) {
    return 'đến $date';
  }

  @override
  String get confirmItsYou => 'Xác nhận là bạn';
}

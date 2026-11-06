"""Build one portable review document; all screenshots embedded, no network."""
from pathlib import Path
import base64
import html
import io
import json
import re
import subprocess

import markdown
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/review/STICKY_WALL_FULL_REVIEW_VI.html'

BODY = r'''
# Sticky Wall — Tổng quan sản phẩm, tính năng và UI

**Bản dùng để review · ngày 06/11/2026 · mã nguồn 1.4.2+10**

Tài liệu này phục vụ review sản phẩm, thiết kế, trải nghiệm, câu chữ và độ sẵn sàng phát hành. Phạm vi bao gồm màn hình chính, các dialog/bottom sheet, mọi loại ghi chú, công cụ trên tường, quản lý bảng, cá nhân hóa, nhập/xuất, quyền hệ thống, Free/Pro và trạng thái lỗi. Các phụ lục liệt kê toàn bộ 45 mẫu bảng, 37 chủ đề, 197 asset minh họa và toàn bộ chuỗi giao diện Anh–Việt hiện có trong mã nguồn.

**Cách đọc trạng thái:** “Có trong mã nguồn” mô tả triển khai; “đã quay trên giả lập” chỉ áp dụng cho hành vi ghi nhận cụ thể; “theo QA cũ” là kết quả lịch sử, không phải kiểm thử lại hôm nay. Không suy ra rằng mọi tính năng đã được kiểm chứng trên máy thật hay iOS.

## 1. Sản phẩm và đối tượng sử dụng

Sticky Wall là ứng dụng ghi chú trực quan trên bảng ghim: những tờ giấy pastel có chữ viết tay, bóng đổ, góc gấp và ghim, đặt trên tường có chất liệu. Người dùng tự bố trí không gian, nối ý bằng dây, ghim ảnh, ghi âm, vẽ, chia thành nhiều bảng và chuyển giữa Tường / Lưới / Danh sách.

Các tình huống chính: ghi nhanh việc cần nhớ; kế hoạch ngày/tuần; học tập và ôn thi; brainstorm; việc nhà và mua sắm trên một thiết bị; moodboard/vision board; lưu ảnh kỷ niệm. Không có tài khoản, backend đồng bộ hay cộng tác thời gian thực trong dự án này.

| Hạng mục | Hiện trạng |
|---|---|
| Tên | Sticky Wall; bản listing đề xuất: Sticky Wall: Notes on a Wall |
| Phiên bản | `pubspec.yaml`: 1.4.2+10; tên release notes còn ghi 1.4.1 |
| Công nghệ | Flutter / Dart; Android là nền tảng chính |
| Ngôn ngữ | English / Tiếng Việt / theo ngôn ngữ hệ thống |
| Lưu trữ | JSON cục bộ; ảnh và ghi âm nằm trong thư mục app |
| Mô hình kinh doanh | Chức năng cơ bản miễn phí; Pro mua một lần, không thuê bao |
| Quảng cáo / tracking | Không tích hợp quảng cáo hay analytics theo tài liệu và mã nguồn đã đọc |
| Ngoại tuyến | Ghi chú và bảng cục bộ dùng offline; mua hàng, link ngoài và dịch vụ chia sẻ online có thể cần mạng |
| Phát hành công khai | Chưa xác nhận từ store trực tiếp; không coi draft closed testing là đã lên production |

## 2. Sơ đồ toàn bộ bề mặt UI

```text
Khởi động → Nạp dữ liệu → Khóa app (nếu bật) → Home
Lần đầu → Bảng ví dụ + Chọn mẫu / Bảng trống / Khám phá ví dụ
Home
 ├─ Header: tên app / tìm kiếm / Tùy chỉnh
 ├─ Hàng bảng: Tất cả bảng / tab từng bảng / dấu +
 ├─ Nội dung: Tường / Lưới / Danh sách
 ├─ Công cụ: lọc loại / vẽ hoặc sắp xếp / bố cục / menu Khác
 ├─ Thêm ghi chú / Loại khác / menu nhấn giữ tường
 ├─ Editor: text, link, checklist, drawing, photo, label, audio
 ├─ Sticker picker / photo viewer / frame picker / color mixer
 ├─ Sheet ghi chú / chọn nhiều / chồng giấy / dây nối / kích thước & xoay
 ├─ Sheet bảng / sửa tên-icon / chọn bảng đích / xác nhận xóa
 ├─ Tất cả bảng / Mẫu & chủ đề / xem trước / Tường kỷ niệm
 ├─ Vẽ trên tường / Xuất bảng / cắt ảnh
 ├─ Thùng rác / lưu trữ qua bảng Archive
 └─ Tùy chỉnh
     ├─ Tường / phông / ghim / ngôn ngữ / tắt đèn
     ├─ Quyền riêng tư / widget / chính sách
     ├─ Sao lưu / nhập file hoặc JSON / xem trước khôi phục
     └─ Pro / thử giao diện / mua / khôi phục giao dịch
```

Các màn hình và sheet phụ có thể được mở từ nhiều vị trí. Menu thay đổi theo loại ghi chú, số bảng, số ảnh, chế độ xem, trạng thái khóa và quyền Pro; không phải tất cả hành động luôn xuất hiện cùng lúc.

## 3. Khởi động và trải nghiệm lần đầu

- Khởi tạo lưu trữ, dịch vụ ảnh, nhắc nhở, điều khiển ghi chú/cài đặt; khôi phục trạng thái mua Pro ở nền.
- Lần đầu tạo năm ghi chú ví dụ, có checklist, nét vẽ và dây nối để minh họa thao tác; vị trí điều chỉnh theo kích thước màn hình.
- Mở mặc định ở chế độ Tường. Welcome đưa ba hướng: chọn mẫu có sẵn, bắt đầu bảng trống, hoặc khám phá ví dụ.
- Bắt đầu bảng trống bỏ dữ liệu ví dụ; template tạo các đối tượng thực sự chỉnh sửa được.
- Hướng dẫn cử chỉ có thể mở lại từ menu Khác; các hàng gồm kéo/ghim/điều hướng tường/xóa/chọn/vẽ/hoàn tác.
- Reviewer cần kiểm tra: nội dung chào mừng không che thao tác thiết yếu; ví dụ không chồng chữ hoặc tràn trên màn hình nhỏ/ngang/tablet; phân biệt dữ liệu ví dụ với ghi chú người dùng.

## 4. Home: cấu trúc và điều hướng

| Vùng | UI và hành vi |
|---|---|
| Nền | Chất liệu tường, lớp sáng/tối, vignette và vết trang trí; chạy dưới phần chrome |
| Header | Tiêu đề Sticky Wall viết tay; icon tìm kiếm; icon bảng màu mở Tùy chỉnh |
| Hàng bảng | Nút Tất cả bảng; tab tên + emoji; dấu + sau các tab; tự cuộn tab đang chọn vào vùng nhìn |
| Thanh công cụ dưới trái | Lọc loại; Bút ở Tường hoặc Sắp xếp ở Lưới/Danh sách; Bố cục; Khác |
| Dưới phải | Nút giấy vàng có bút; có thể mở rộng nhãn Ghi chú mới tùy chế độ/trạng thái rỗng |
| Loại khác | Pill mở các loại nội dung khác, giảm phụ thuộc vào việc biết nhấn giữ |
| Camera tường | Show everything / Reset tùy việc ghi chú nằm ngoài khung và camera đã di chuyển |
| Phản hồi | Snackbar, nút Undo tạm thời, hướng dẫn trạng thái rỗng, số kết quả tìm kiếm |
| Chế độ chọn | Header/toolbar đổi sang số mục chọn và tác vụ nhóm |

**Menu Khác:** Mẫu & chủ đề; Ghim ảnh lên tường; Vẽ trên tường khi đang ở view khác; Chọn nhiều; Dọn gọn; Dọn theo màu; Hiện tất cả; Xuất bảng; Thùng rác kèm số lượng; Bật/tắt đèn; Hướng dẫn cử chỉ. Một số mục chỉ hiện khi có dữ liệu hoặc ở Tường.

## 5. Ba chế độ xem cùng dữ liệu

| Chế độ | Bố cục | Thao tác và khác biệt |
|---|---|---|
| Tường | Canvas tự do; giấy có góc nghiêng, ghim, dây và nét bút | Kéo, xoay, resize, pan/zoom, chọn nhóm, chồng giấy, căn lề, xuất bố cục |
| Lưới | Masonry theo chiều cao thực của thẻ | 2 cột trên điện thoại, tối đa 6 theo độ rộng; giấy thẳng; có sắp xếp |
| Danh sách | Hàng gọn cho từng ghi chú | Xem nhanh, phát ghi âm, vuốt xóa, tìm kiếm/sắp xếp |

Chuyển view giữ cùng ghi chú, không tạo bản sao. Ở Lưới/Danh sách có thể vuốt ngang chuyển bảng. Các công cụ không phù hợp view được ẩn hoặc đưa người dùng về Tường.

## 6. Danh mục nội dung: 7 loại ghi chú + sticker

`NoteType` có **8 giá trị**; cách nói “7 loại ghi chú” trong tài liệu/marketing là bảy loại nội dung biên tập được, cộng sticker có picker riêng.

| Loại | Hình thức UI | Nội dung / thao tác | Điều kiện lưu |
|---|---|---|---|
| Văn bản | Tờ giấy pastel | Nhiều dòng; định dạng nhẹ bold/italic/bullet | Nội dung không rỗng |
| Liên kết | Giấy có nhãn và URL | Mở URL ngoài; phát hiện liên kết trùng theo khóa chuẩn hóa | URL không rỗng; không trùng danh sách kiểm tra |
| Checklist | Tiêu đề + hàng có checkbox | Thêm/sửa/xóa mục, tích trực tiếp trên tường, đếm hoàn thành | Có tiêu đề hoặc ít nhất một mục có chữ |
| Vẽ tay | Canvas phủ hết thẻ; nhãn nhỏ bên dưới nếu có | Bút màu/kích cỡ, tẩy; chọn tông giấy và nền plain/ruled/grid/dots | Có tiêu đề hoặc nét vẽ |
| Ảnh in | Ảnh theo tỉ lệ thật, khung, caption | Chọn ảnh, thay ảnh, xem zoom, xoay/resize/nối dây | Phải có ảnh |
| Nhãn | Dải băng dính chữ, không ghim/không thân giấy | Đặt tiêu đề cột, khu vực kế hoạch | Nội dung không rỗng |
| Ghi âm | Cassette màu giấy, tên và thời lượng | Ghi, ghi lại, xóa recording, phát/tạm dừng | Phải có recording |
| Sticker | Minh họa/emoji/stamp/doodle/washi, không giấy/ghim | Chạm để đổi sticker; kéo/xoay/resize như một đối tượng | Tạo qua picker, không qua editor thông thường |

Ảnh đính kèm trên một ghi chú khác là tính năng riêng với “ghi chú ảnh in”. Đính ảnh không biến mọi loại nội dung thành ảnh in. Những lựa chọn không áp dụng cho loại đang mở được UI ẩn/giới hạn.

### 6.1 Checklist hoàn thành

Tích ô hoạt động trực tiếp ở thẻ; không cần mở editor. Khi xong hết, giấy mờ đi và có dấu tích lớn; ghi chú vẫn còn. Có thể chủ động Archive. Tùy chọn tự dọn checklist xong sau một ngày mặc định tắt; nếu bật thì đưa vào thùng rác, không đồng nghĩa Archive. Ba lần tích và trạng thái hoàn thành đã được quay trên Android giả lập API 35 cho video review.

### 6.2 Ghi âm cassette

Quyền micro chỉ hỏi khi người dùng bắt đầu ghi. Có thể chạm nút micro hoặc giữ rồi thả; editor cho ghi lại/xóa bản ghi. Chỉ một recording phát tại một thời điểm; thẻ, danh sách và editor có thao tác phát. Cuộn băng quay khi phát và giữ yên khi hệ thống yêu cầu giảm chuyển động. Không mô tả là ghi âm nền không giới hạn, chuyển giọng thành chữ hay đồng bộ âm thanh.

## 7. Editor: UI, lưu và hủy

- Dialog là chính tờ giấy: màu/phông nhất quán với thẻ; các nút lưu/hủy đặt trên dải đầu giấy để không bị bàn phím che.
- Chọn loại nội dung và nhập trường tương ứng; phần checklist/vẽ/ghi âm có công cụ riêng.
- Có điều khiển ghim, nhắc nhở, sticker cảm xúc, màu giấy; ảnh có nút thay/gỡ/xem nếu phù hợp loại.
- Chuyển giữa chữ viết tay và phông dễ đọc Be Vietnam Pro khi nhập dài; lựa chọn được nhớ.
- Bold/italic/bullet chèn markup nhẹ (`**đậm**`, `*nghiêng*`, `- mục`) và thẻ hiển thị định dạng; tìm kiếm/widget/thùng rác đọc chữ đã bỏ ký hiệu.
- Nút lưu, Back hoặc chạm ngoài giữ thay đổi khi dữ liệu hợp lệ; nút × là bỏ chỉnh sửa và hỏi xác nhận nếu có thay đổi. Dữ liệu không lưu được có xử lý xác nhận khi rời.
- Ghi chú hiện hữu có nút thùng rác trong editor. Lỗi inline trên giấy và có hiệu ứng rung giấy; không dựa riêng vào toast.
- Chuyển loại có nguy cơ làm mất sketch/link/ghi âm cần xác nhận; checklist sang text giữ các mục thành bullet.
- Mục đang gõ trong ô thêm checklist được tính khi lưu, kể cả chưa nhấn Enter.
- Các trạng thái cần review: giấy rỗng, URL thiếu/trùng, thiếu ảnh/recording, bàn phím mở, nhập dài, hủy với thay đổi, lưu khi đang ghi, chuyển loại có dữ liệu.

### 7.1 Nhắc nhở

Preset “một tiếng nữa”, “tối nay”, “sáng mai”; hoặc chọn ngày/giờ. Lặp: không / hằng ngày / hằng tuần / hằng tháng. Nhắc bằng notification cục bộ. UI báo giờ quá khứ hoặc notification bị tắt. Ghi chú thuộc bảng khóa dùng nội dung nhắc ẩn. Cần kiểm tra quyền thông báo/exact alarm và hành vi hệ điều hành trên máy thật.

### 7.2 Ảnh và trình xem

Chọn từ thư viện hoặc camera; ảnh được sao chép vào thư mục app. Trên thẻ ảnh đính kèm nằm trên nội dung, editor hiện rộng và có nút thay/gỡ. Trình xem toàn màn hình hỗ trợ pinch/double-tap zoom. Ghim nhiều ảnh tạo nhiều print riêng; luồng nhận share ảnh hiện chỉ dùng ảnh đầu tiên trong payload.

## 8. Thao tác trên tường và cử chỉ

| Tác động | Kết quả / UI phản hồi |
|---|---|
| Chạm thẻ | Mở editor; sticker mở đổi sticker; checkbox/play/link có tác vụ riêng |
| Nhấn giữ thẻ | Sheet tác vụ theo ngữ cảnh; trong chế độ chọn thì đổi trạng thái chọn |
| Kéo một ngón trên thẻ | Di chuyển ghi chú; ghi chú đang khóa vị trí không kéo được |
| Tay nắm dưới phải | Resize thẻ đang hoạt động |
| Tay nắm dưới trái | Xoay quanh tâm; chạm tay nắm để thẳng lại |
| Xoay gần hướng chuẩn | Bắt góc thẳng/quarter turn và rung phản hồi |
| Hai ngón trên cùng thẻ | Pinch đổi kích cỡ và twist đổi góc, tác động vào thẻ |
| Pinch/pan trên tường | Di chuyển/zoom camera; texture đi cùng nội dung |
| Double-tap ghi chú | Camera tiến vào ghi chú; lặp lại để lùi ra |
| Nhấn giữ nền trống | Tạo ghi chú hoặc ghim ảnh tại vị trí đó |
| Kéo lên tab bảng khác | Chuyển ghi chú sang bảng đang sáng lên |
| Kéo xuống khay xóa | Xóa khi tùy chọn này bật; mặc định tắt |
| Kéo gần thẻ khác | Guide nét đứt căn cạnh/tâm, snap và haptic |
| Chọn nhóm và kéo | Di chuyển cả nhóm, Undo theo một thao tác |
| Fit all / reset | Đưa tất cả vào khung hoặc khôi phục camera |

Tường mở rộng **1000 logical px mỗi cạnh** ngoài vùng màn hình; đây là canvas có giới hạn, không mô tả là vô hạn. Grips chỉ hiện ở ghi chú đang hoạt động. Đường hướng dẫn và phản hồi cảm ứng giúp căn mà không ép mọi thẻ vào lưới.

### 8.1 Ghim và khóa vị trí

Ghim ưu tiên khiến thẻ thẳng và ghim vàng; chạm ghim để đổi. “Khóa tại chỗ” giữ vị trí/góc/kích thước và hiện ổ khóa nhỏ. Hai khái niệm này khác với “khóa bảng” dùng xác thực; cần đọc rõ nhãn để người dùng không hiểu lầm.

### 8.2 Dọn gọn, chồng giấy, chọn nhiều

- Dọn gọn đưa thẻ về lưới bằng animation, làm thẳng góc xoay; dọn theo màu nhóm giấy theo màu. Tính hàng theo chiều cao render thực; giữ thẻ khóa vị trí.
- Chọn nhiều qua sheet/menu hoặc lasso trên tường; có chọn tất cả và thanh tác vụ nhóm.
- Tác vụ nhóm: ghim/bỏ ghim, đổi màu, stack khi đủ mục, di chuyển/sao chép sang bảng khác khi có bảng đích, xóa; một số hành động phụ qua menu.
- Stack qua “Xếp với…” hoặc chọn nhiều: tờ trên cùng hiện, mép giấy dưới và số lượng; chạm số mở danh sách, chọn thẻ để sửa hoặc “Tách ra”. Cả chồng di chuyển/dọn/Undo như đơn vị.
- Undo bố cục lưu tối đa 40 bước; các lần dịch một thẻ liên tiếp có thể gộp một bước. Không suy ra mọi thao tác trong app đều có lịch sử vĩnh viễn.

## 9. Dây nối ý tưởng

Kéo từ ghim thẻ này sang ghim thẻ khác để buộc dây; hoặc dùng sheet “Nối dây tới…” và chọn ghi chú đích. Ảnh in cũng tham gia. Dây bám ghim khi thẻ di chuyển/xoay.

Chạm dây để mở sheet: chọn màu len, thêm nhãn giấy ở giữa, mũi tên cho hướng phụ thuộc/luồng và cắt dây. Cắt có Undo. Sheet ghi chú có thể liệt kê các dây của nó. Free có 7 màu len và kiểu yarn; Pro thêm 4 màu và 4 kiểu dây twine/ribbon/dashed/beads. Đây là nối tay, không phải AI tự liên kết hay mind-map tự sinh.

## 10. Vẽ trực tiếp lên tường

Nút Bút mở marker mode; từ view khác chọn menu tương ứng sẽ chuyển sang Tường. Thanh riêng có màu, độ dày, highlighter Pro, tẩy, Undo nét, xóa toàn bộ và hoàn tất. Có 5 màu cơ bản và 3 độ dày; nét nằm **sau ghi chú**. Hai ngón vẫn dùng zoom. Nét lưu theo bảng và đi cùng export. Vẽ trên tường khác với ghi chú Drawing có canvas riêng; không có bộ layer minh họa chuyên nghiệp.

## 11. Quản lý bảng

| Bề mặt | Chức năng |
|---|---|
| Dấu + | Tạo bảng trống / từ template / tường kỷ niệm |
| Dialog tên bảng | Tên plain text tối đa 40 ký tự, trim khoảng trắng; emoji tùy chọn, có bỏ icon; tạo mới cần tên hợp lệ |
| Tab hiện tại / sheet bảng | Đổi tên/icon, giao diện bảng, mẫu/chủ đề và các thao tác quản lý theo ngữ cảnh |
| Kéo tab | Đổi thứ tự; không làm đổi nội dung bảng |
| Tất cả bảng | Thumbnail vẽ từ ghi chú thật, số mục, lần sửa; mở, ghim ưu tiên, nhân bản có Undo, xóa |
| Thứ tự gallery | Bảng ghim trước, sau đó theo lần chỉnh gần nhất |
| Bảng khóa | Khóa bằng xác thực thiết bị, mở theo phiên; preview/nội dung nhạy cảm được che khi đóng |
| Bảng Archive | Nơi cất ghi chú; không phải thùng rác, không tự xóa sau 30 ngày |

Mỗi bảng nhớ chất liệu/ảnh nền riêng; theme có thể đặt phông và kiểu ghim riêng. Di chuyển khác với sao chép: bản sao có danh tính mới. Nhân bản bảng có lưu cả bố cục và quan hệ cần thiết theo controller. Xóa bảng cần xác nhận số ghi chú bị ảnh hưởng; ghi chú đi cùng bị xóa trực tiếp, không vào thùng rác. Đây là điểm review cần chú ý hơn xóa một note.

## 12. Mẫu bảng và chủ đề

Gallery “Mẫu & chủ đề” có hai tab; tìm kiếm, bộ lọc nhóm, preview và CTA phù hợp. Preview vẽ bằng renderer của tường, không chỉ là ảnh poster.

| Mẫu bảng / Templates | Chủ đề / Themes |
|---|---|
| 45 mẫu, 6 nhóm: kế hoạch, học tập, sáng tạo, cá nhân, gia đình, mùa lễ | 37 gói; 17 free theo tài liệu kiểm kê |
| Tạo bảng mới với note/checklist/label/sticker/thread sửa được | Đổi tường, giấy, ruling, ghim, chữ và dây trên bảng đang mở |
| Nội dung ví dụ đánh dấu sample; sửa thì thành nội dung của người dùng | Giữ lời ghi chú, vị trí, ngày và các quan hệ nội dung |
| Có xóa ví dụ nhưng giữ các thành phần bố cục | Có Undo áp dụng theme |
| Mẫu dùng look Pro có bản free tương ứng và báo/preview trước khi dùng | Theme Pro mở màn mua khi chưa có quyền |

Nhóm mùa lễ dùng được quanh năm; thứ tự ưu tiên theo dịp gần. Không tự tải nội dung lịch/sự kiện từ máy chủ. Danh mục chính xác nằm ở phụ lục trong file này.

## 13. Tường kỷ niệm / Memory Wall

Luồng: chọn ảnh → sheet số lượng/bố cục/look/khung/caption → tạo bảng mới → tiếp tục thao tác như các note ảnh thông thường.

- Tối đa **20 ảnh** mỗi lần tạo; UI thông báo khi vượt mức.
- 5 bố cục: collage, ảnh theo hàng, film strip, timeline có dây nối và hero photo.
- Chọn look gợi ý; không có Pro thì lựa chọn ban đầu phù hợp free.
- 7 khung: plain print, Polaroid, film, vintage, torn, rounded, scrapbook. Plain/Polaroid/rounded free; bốn kiểu còn lại Pro.
- Caption preset: không, đánh số, ngày hôm nay; có thể sửa từng caption.
- Sau tạo: shuffle ảnh có seed; chọn một khung cho mọi ảnh; đặt một ảnh làm hero khi đủ ảnh và đúng ngữ cảnh; có Undo.
- Ảnh vẫn kéo/xoay/resize/nối dây/chuyển bảng được. Không có mạng xã hội ảnh hay album cộng tác.

## 14. Sticker, băng washi và giấy

- 161 sticker minh họa vẽ tay; 45 free. 36 băng washi, toàn bộ Pro. Tổng 197 WebP có alpha, khoảng 2 MB theo manifest/QA cũ.
- Picker chia kệ theo chủ đề, có tiếng Anh/Việt; sticker và tape là đối tượng trên tường. Ngoài nhóm ảnh này còn các emoji/stamp/doodle được vẽ bằng code; không cộng lẫn để quảng bá số sticker minh họa.
- 12 màu giấy có sẵn: 6 free, 6 Pro; mặc định tự chọn từ palette free. Pro có pha màu bằng hue/strength/lightness, giữ khả năng đọc.
- 6 kiểu giấy tổng: plain free; lined/grid/dots/index card/notebook Pro. Ruling theo dòng chỉ áp dụng cho loại hỗ trợ; sketch có chọn canvas riêng.
- 6 kiểu ghim tổng; classic free, các kiểu khác Pro. Note đã mang hình thức Pro vẫn được render khi quyền Pro không còn.
- Các catalog chi tiết minh họa và phân loại Free/Pro được lấy trực tiếp từ manifest ở phụ lục.

## 15. Tìm kiếm, lọc và sắp xếp

Tìm theo thời gian thực, bỏ phân biệt dấu tiếng Việt: “tuoi” tìm “Tưới”. Có số kết quả, xóa truy vấn và thông báo kết quả ở bảng khác; chọn kết quả sẽ mở đúng bảng. Bảng khóa đang đóng bị loại khỏi kết quả xuyên bảng.

Bộ lọc: tất cả / văn bản / link / checklist / vẽ / ảnh / label / ghi âm. Sticker có trong mô hình nhưng không có lựa chọn filter riêng trong toolbar hiện tại. Tường làm mờ ghi chú không khớp tại chỗ; Lưới/Danh sách hiển thị tập phù hợp. Pill “Đang hiện…” và Clear giúp tránh quên đang lọc. Lưới/Danh sách sắp theo mới nhất, cũ nhất, A–Z, Z–A.

## 16. Sheet ghi chú và thao tác nhóm

Nhấn giữ thẻ mở sheet. Hàng đầu gồm swatch màu nếu loại cho phép; ghim; di chuyển nếu có bảng khác, nếu không có thì nhân bản; chia sẻ; xóa. Bên dưới có sửa, Archive, xem ảnh khi có, đổi khung cho print, làm hero khi đủ ảnh, khóa vị trí, kích thước/xoay, nối dây, xếp chồng/tách, danh sách dây, chọn, nhân bản, sao chép sang bảng khác, lưu ảnh và tác vụ tường phù hợp.

Ảnh in/sticker không có màu giấy thông thường. Note khóa vị trí không có menu chỉnh kích thước tương tự note mở khóa. Chia sẻ ghi chú render thành ảnh; lưu đưa ảnh vào thư viện. Không hiểu “Share” là cộng tác hay gửi dữ liệu tự động lên server.

## 17. Xóa, thùng rác và lưu trữ

- Xóa note dùng animation bóc giấy, đưa vào Trash, snackbar có Undo; Danh sách có swipe xóa.
- Trash giữ 30 ngày; có danh sách preview, tên bảng, số ngày còn lại, khôi phục, xóa vĩnh viễn có xác nhận, dọn sạch toàn bộ. Không có ô tìm kiếm riêng trong TrashScreen hiện tại. Nội dung bảng khóa đóng không lộ qua Trash.
- Khi khôi phục, ghi chú về bảng phù hợp theo logic controller; reviewer cần thử trường hợp bảng gốc không còn và media được tham chiếu.
- Archive chuyển note sang bảng lưu trữ, giữ nội dung và có Undo; không phải xóa. Có hint riêng cho checklist đã xong.
- Dọn tự động checklist và kéo xuống khay xóa đều mặc định tắt.
- Xóa cả bảng bỏ qua Trash; UI phải truyền đạt rõ hậu quả trước khi đồng ý.

## 18. Xuất, lưu và chia sẻ

Export có màn preview riêng, bỏ header/toolbar/tay nắm của màn chính khỏi hình xuất. Renderer dùng cùng card/tường/dây/nét vẽ nên giữ bố cục, góc và mức làm dịu tường.

| Điều khiển | Lựa chọn |
|---|---|
| Tác vụ chính | Lưu ảnh / Xuất PDF / Chia sẻ |
| Phạm vi | Toàn tường hoặc phần đang nhìn khi camera phù hợp |
| Tập ghi chú | Tất cả hoặc các mục đang chọn |
| Độ phân giải | 2× / 3× / 4× |
| Cắt | Kéo góc/cạnh khung crop; hoàn tất/reset |
| Nâng cao | More options / ít tùy chọn hơn |
| Widget | Đưa ảnh bảng lên widget màn hình chính |

PDF một trang có kích thước theo hình; không phải xuất dữ liệu note có thể sửa. Export PNG/PDF khác với backup JSON. UI có trạng thái bận/thất bại/thành công; ảnh xoay sát mép cần được chừa margin, không bị cắt mất.

## 19. Nhận chia sẻ từ ứng dụng khác

Android có intent SEND/SEND_MULTIPLE và xử lý khi app khởi động hoặc đang chạy. Parser nhận text, URL http(s), ảnh; dùng ảnh đầu tiên nếu có nhiều ảnh trong payload; bỏ loại video/file không hỗ trợ. Chọn bảng đích rồi ghi nội dung trực tiếp lên bảng, có Open và Undo theo luồng hiện tại 1.4+. Một đoạn README cũ vẫn mô tả mở editor điền sẵn: không dùng đoạn đó làm chuẩn khi review bản hiện tại.

Không mở bảng đang khóa mà bỏ qua xác thực. iOS cần Share Extension tích hợp và kiểm chứng native; chưa quảng bá tương đương Android.

## 20. Tùy chỉnh: toàn bộ nhóm điều khiển

| Nhóm | UI và lựa chọn |
|---|---|
| Sticky Wall Pro | Mở sheet quyền lợi, trạng thái mua, giá từ store, Unlock / Restore |
| Chất liệu tường | Carousel preview, lựa chọn đang dùng/Pro; ảnh cá nhân từ thư viện; gỡ ảnh nền |
| Trang trí | Bật/tắt stains/vết nước/vết sơn/vết xước |
| Làm dịu tường | Slider mức soften giúp tách chữ khỏi nền; ảnh hưởng cả export |
| Tắt đèn | Off / On / Theo hệ thống / Theo lịch; chọn giờ bắt đầu-kết thúc |
| Phông chữ | Preview trên giấy, lựa chọn hiện tại và Pro; 16 phông note tổng, 11 free + 5 Pro |
| Kiểu ghim | Preview và chọn trong 6 kiểu; thử Pro khi chưa mua |
| Ngôn ngữ | English / Tiếng Việt / hệ thống |
| Quyền riêng tư | Khóa app; link chính sách mở ngoài |
| Widget | Chọn bảng, nội dung, màu, cỡ chữ, live preview |
| Thùng rác | Đi tới Trash và badge số ghi chú |
| Dọn checklist | Tự đưa checklist hoàn thành lâu vào Trash; mặc định tắt |
| Khay xóa | Kéo xuống chân tường để xóa; mặc định tắt |
| Sao lưu | Xuất backup; nhập file hoặc JSON; tự sao lưu tuần; lần gần nhất; khôi phục/chia sẻ bản gần nhất |

“Tắt đèn” là ánh sáng ấm, làm tối cả giấy/ảnh/nét vẽ; không chỉ đổi nền thành màu xám. 31 wall surfaces gồm các nền cơ bản, biến thể Pro và mùa lễ theo kiểm kê dự án; không coi tất cả 31 là free. Pacifico dành cho nhận diện tiêu đề, không cộng thêm vào 16 phông note.

## 21. Widget màn hình chính

Android có native provider và cấu hình UI: chọn bảng cố định hoặc bảng đang mở; pinned/newest; mode picture sau khi gửi ảnh từ export; màu wall/paper/ink; text size small/normal/large. Preview phản ánh các lựa chọn. Tap widget mở app. Widget không hiện note của bảng khóa; ảnh widget phải được xử lý khi bảng thành riêng tư.

iOS có mã Swift và đường đẩy dữ liệu, nhưng còn cần target WidgetKit/App Groups tích hợp và test. Web không phải môi trường xác minh widget/native.

## 22. Sao lưu, nhập và độ bền dữ liệu

- Backup JSON bao gồm bảng, note, dây nối, media ảnh và ghi âm. Có chia sẻ file; nhập từ file hoặc dán JSON.
- Trước restore, preview phiên bản, ngày, kích thước, số lượng bảng/note/trash/ảnh/voice/thread/sticker/bảng khóa và phần trùng với dữ liệu đang có.
- Hai lựa chọn rõ ràng: **Gộp vào hiện có** hoặc **Thay thế tất cả**. Chưa chọn thì chưa sửa dữ liệu. Có Undo sau khi áp dụng.
- Gộp không ghi đè note cùng ID; nhập cùng backup hai lần không tạo thêm bản sao cùng ID. Dây chỉ thêm nếu hai đầu có mặt.
- Ghi media trước khi thay đổi data; lỗi ghi file không để nửa trạng thái. Không chấp nhận backup version mới hơn khả năng đọc. Chỉ lấy tên file cuối để hạn chế path traversal.
- File JSON lớn hiện đọc toàn bộ và chưa có cap kích thước theo audit; không tuyên bố hỗ trợ backup vô hạn.
- Tự sao lưu mặc định bật; kiểm tra khi app mở, nếu đủ một tuần tạo bản mới và giữ bốn bản gần nhất. Không phải lịch chạy nền bảo đảm đúng giờ mỗi tuần.
- NoteStorage đọc từng bản ghi, bỏ bản lỗi thay vì làm hỏng toàn bộ lần load; media chỉ xóa khi không còn note sống/trash tham chiếu.
- Android backup/phone transfer và iCloud có thể sao chép dữ liệu theo cơ chế hệ điều hành; bản weekly nội bộ không thay thế backup ra vị trí độc lập.

## 23. Khóa app, khóa bảng và quyền riêng tư

| Cơ chế | Ý nghĩa thực tế |
|---|---|
| Khóa app | Tùy chọn free; xác thực bằng fingerprint/face/screen lock thiết bị; bật yêu cầu thử xác thực |
| Khi trở lại app | Yêu cầu xác thực theo thời gian rời nền khoảng một phút; cover cả dialog |
| Không có khóa thiết bị | Có phản hồi; trường hợp khóa thiết bị bị gỡ có đường tránh tự khóa người dùng vĩnh viễn |
| Khóa bảng | Pro để đặt khóa; bỏ khóa luôn free; đóng theo phiên/background |
| Bảng khóa đóng | Che nội dung, bỏ khỏi tìm kiếm xuyên bảng/Trash, ẩn nội dung notification; widget không liệt kê |
| Android Recents | Có code che thumbnail khi khóa app bật hoặc bảng riêng tư đang mở; cần kiểm tra thực tế |
| Lưu trữ | Note JSON không được mã hóa riêng bởi app; khóa UI không phải encrypted vault |

Không nói “không bao giờ rời điện thoại” vì backup hệ điều hành và thao tác export/share do người dùng thực hiện có thể chuyển dữ liệu. Cách diễn đạt phù hợp: app lưu ghi chú cục bộ và không có backend gửi note của riêng app; backup của điện thoại có thể bao gồm dữ liệu đó.

**Quyền/tích hợp cần review:** thông báo và exact alarm cho nhắc nhở; micro cho ghi âm; camera/thư viện và lưu gallery; local authentication/khóa thiết bị; store billing cho Pro; chia sẻ/mở link ngoài. Trạng thái từ chối quyền phải có hướng dẫn và không khiến mất nội dung đang nhập.

## 24. Bảng Free / Pro và UI mua hàng

| Nhóm | Free | Pro bổ sung |
|---|---|---|
| Ghi chú | 7 loại nội dung, thao tác cơ bản, bảng, nhắc nhở, tìm kiếm, export/backup | Không khóa toàn bộ note cơ bản sau một thời gian |
| Templates | 45 template sửa được, có free look cho mẫu dùng Pro | Look Pro khi có quyền |
| Themes | 17 trong tổng 37 theo kiểm kê | 20 theme còn lại |
| Giấy | 6 màu, plain | 6 màu thêm, 5 ruling thêm, mixer |
| Fonts | 11 | 5 thêm |
| Ghim | Classic | 5 kiểu thêm |
| Minh họa | 45 sticker ảnh trong tổng 161 | 116 sticker ảnh còn lại |
| Washi ảnh | 0 trong bộ 36 | 36 |
| Khung ảnh | Plain, Polaroid, rounded | Film, vintage, torn, scrapbook |
| Marker | 5 màu và công cụ cơ bản | 5 màu thêm, highlighter |
| Dây | Yarn, 7 màu | 4 style và 4 màu thêm |
| Khóa | Khóa app | Khóa từng bảng |
| Tường | Nhiều chất liệu cơ bản và ảnh của người dùng | Biến thể Pro và gói mùa lễ |

Pro là sản phẩm non-consumable `sticky_wall_pro`. UI có giá do store trả về, loading, pending, failed, unavailable, unlocked và Restore. Không ghi cứng giá đề xuất vào quảng cáo/app.

Thử Pro wall/font/pin trên bảng thật qua Tùy chỉnh; chưa mua thì đây là preview tạm. Đóng sheet bỏ thử; mua thành công có thể giữ. Không chặn render note từng có hình thức Pro. Cache quyền dùng offline; khi Google Play trả lời rõ là không còn sở hữu sau refund/revoke thì gỡ quyền chọn Pro. Không có phản hồi do mất mạng thì giữ cache. Các hành vi mua cần test bằng license tester, không suy từ unit test là thanh toán thật đã đạt.

## 25. Trạng thái UI, accessibility và responsive cần review

| Nhóm | Trường hợp |
|---|---|
| Rỗng | Bảng chưa có note; không có kết quả; không có bảng đích/ghi chú khác; Trash rỗng; gallery không khớp |
| Lỗi nhập | Thiếu nội dung/URL/ảnh/audio; link trùng; đổi loại mất dữ liệu; JSON sai/newer version |
| Lỗi hệ thống | Micro/notification/gallery/camera bị từ chối; không có khóa màn hình; share/save/export lỗi; store vắng mặt |
| Tiến trình | Load thư viện, ghi/phát audio, xuất ảnh/PDF, mua pending, restore đang chạy |
| Phản hồi | Inline hint, toast/snackbar, Undo, disabled actions, xác nhận bỏ/xóa, rung cảm ứng |
| Màn hình nhỏ | Editor với bàn phím, sheet cao có scroll, toolbar không tràn, tab dài ellipsis |
| Màn hình rộng | Số cột lưới thích ứng, welcome/sample layout không giãn rỗng quá mức |
| Keyboard | Tab focus, Enter/Space kích hoạt, Shift+F10/menu key mở tác vụ qua KeyboardTappable |
| Semantics | Checkbox có text + checked chung một node, nút có nhãn/tooltip; kiểm tra screen reader thực tế |
| Chuyển động | Reduced motion cho animation phù hợp, đặc biệt cuộn cassette; kiểm tra contrast ở night mode |
| Tiếng Việt | Đủ dấu, không vỡ font, không wrap mất ý ở heading nhỏ; text scale lớn và dòng dài |

Các chuỗi trong phụ lục là toàn bộ catalog l10n, bao gồm hint/lỗi/tooltip/nhãn động; không đảm bảo mỗi chuỗi còn có đường UI được gọi. Placeholder `{count}`/ICU cần thử với dữ liệu thực, không đọc như văn bản cuối cùng.

## 26. Hình ảnh thật và mức độ đại diện

Ảnh dưới đây được nhúng trực tiếp để tài liệu mở offline. Bộ `screenshots/` là preview được render từ app bằng test/golden, không phải ảnh chụp điện thoại thật và không phải bằng chứng mọi tính năng đã chạy trên device. Chúng có thể cũ hơn một số UI 1.4.2. Bộ ảnh checklist từ phiên quay quảng cáo là screencap thật trên Android giả lập, dùng dữ liệu giả lập dành riêng cho demo. Không dùng ảnh AI để mô phỏng UI.

<!-- SCREENSHOTS -->

## 27. Mức độ kiểm chứng và giới hạn hiện tại

| Hạng mục | Bằng chứng và giới hạn |
|---|---|
| Đọc source | Đối chiếu models, screens, widgets, services, localizations, template JSON, asset manifest và tài liệu release |
| Analyze/tests | QA matrix lịch sử báo analyze sạch; 261 tests pass, 53 skip là generator. Chưa chạy lại toàn suite cho tài liệu này |
| Android build | Trong phiên làm video đã build debug 1.4.2+10 thành công |
| Android giả lập | Đã seed bảng demo, quay ba checkbox và completion state trên API 35. QA cũ có kiểm tra first-run BlueStacks Android 11 |
| Android máy thật | Chưa có xác minh đầy đủ trong phiên này: gestures, FPS/RAM, nhắc nhở, mua/restore/refund, recents, share và export lớn |
| iOS | Chưa xác minh build/native widget/share/StoreKit; cần macOS/Xcode và target cấu hình |
| Web | Dùng xem UI; nhiều native plugin không hoạt động; không suy ngang năng lực Android |
| Hiệu năng | QA VM cũ: 500 notes mở khoảng 1.3s, search khoảng 0.3s; không phải số đo máy thật |
| Giới hạn backup | Chưa có cap kích thước; không có mã hóa backup/app note riêng |
| Layout template | Audit từng ghi nhận heading ba cột tiếng Việt có thể wrap ở scale nhỏ; cần nhìn từng mẫu |
| Tài liệu cũ | README có đoạn share cũ; QA có dòng “chưa compile” tồn tại cạnh bảng build mới hơn. Ưu tiên bằng chứng cụ thể theo phiên bản, không coi mọi dòng đồng thời đúng |

Build debug phiên video có warning plugin `receive_sharing_intent` đòi compileSdk cao hơn cấu hình dự án và cảnh báo Kotlin plugin/tooling. Build vẫn thành công; đây là việc cần review tương thích trước release, không tự khẳng định release bị lỗi.

## 28. Kịch bản review thực hành toàn app

Mỗi hàng nên được ghi Pass / Fail / Chưa thử, kèm nền tảng, build, ảnh/video và mức độ nghiêm trọng. Checklist này là đề xuất review, không phải danh sách đã test đạt.

| ID | Luồng kiểm tra | Kết quả cần quan sát |
|---|---|---|
| R01 | Cài mới, lần lượt thử ba hướng welcome | Không kẹt onboarding; dữ liệu ví dụ xử lý đúng |
| R02 | Tạo/sửa/lưu/hủy từng loại trong 7 loại | UI và validation đúng; Back không làm mất bản hợp lệ |
| R03 | Bold/italic/bullet + tiếng Việt dài | Editor/card/search/widget không lộ markup ngoài ý định |
| R04 | Checklist tạo/xóa mục, tích hết trên wall | Không mở editor ngoài ý muốn; giấy vẫn còn và có completed state |
| R05 | Ghi âm từ chối quyền rồi cấp lại, ghi lại, phát đổi note | Một audio phát; trạng thái không kẹt; không mất nội dung |
| R06 | Ảnh gallery/camera, thay/gỡ, viewer zoom | Giữ đúng tỉ lệ; media không mất sau restart |
| R07 | Kéo/xoay/resize/hai ngón/khóa tại chỗ | Phân biệt camera và card; hit target dễ dùng |
| R08 | Căn lề, tidy, tidy by color, stack/tách | Không chồng chữ; Undo khôi phục cả nhóm |
| R09 | Nối dây, nhãn, mũi tên, đổi style/màu, cắt/Undo | Dây bám đúng ghim, không tự nối sai |
| R10 | Vẽ wall, tẩy/Undo/clear, đổi bảng/restart | Nét ở sau note, lưu theo bảng |
| R11 | Chuyển Wall/Grid/List; lọc/sort/search không dấu | Cùng dữ liệu; clear filter dễ tìm; kết quả xuyên bảng đúng |
| R12 | Tạo/đổi tên/reorder/duplicate/delete bảng | Phản hồi và cảnh báo đúng, không nhầm với Trash |
| R13 | Mở 45 template; xóa ví dụ; sửa một note | Mọi đối tượng sửa được; free preview đúng trước Use |
| R14 | Apply theme rồi Undo với ảnh/drawing/audio | Nội dung và vị trí giữ nguyên; đối tượng phù hợp đổi look |
| R15 | Memory Wall 1/20/>20 ảnh, 5 layouts, 7 frames | Giới hạn và Pro đúng; shuffle/hero/frame-all Undo đúng |
| R16 | Xóa note/restore/xóa hẳn/dọn Trash/Archive | Khác biệt rõ; không xóa media còn được dùng |
| R17 | Export 2×/3×/4×, crop, selected, viewport, PDF | Không chrome; không cắt note xoay; xử lý lỗi/busy |
| R18 | Share Android cold/warm start, text/link/ảnh | Lưu đúng board, không nhân payload sau restart |
| R19 | Backup; xem preview; merge hai lần; replace rồi Undo | Đúng count/conflict; không nhân ID, không nửa trạng thái |
| R20 | JSON sai/phiên bản mới/file lớn/lỗi ghi media | Báo hiểu được, dữ liệu cũ không bị phá |
| R21 | Khóa app/bảng, background, search/Trash/notification/recents | Không rò chữ; có đường xử lý thiếu khóa thiết bị |
| R22 | Widget pinned/newest/picture; xóa/khóa board nguồn | Preview và native khớp; không lộ board khóa |
| R23 | Pro: thử rồi đóng; mua/pending/offline/restore/refund | Giá store đúng; preview không tự lưu; note cũ giữ look |
| R24 | Ngôn ngữ EN/VI/system, night schedule, restart | Cài đặt nhớ và hiển thị nhất quán |
| R25 | Font lớn/screen reader/keyboard/màn nhỏ & ngang | Không che nút lưu; focus/labels/contrast phù hợp |
| R26 | Nhiều note/ảnh/threads + export lớn trên máy thật | Ghi nhận FPS, RAM, thời gian, crash và nhiệt thay vì chỉ cảm giác |

## 29. Mẫu ghi nhận review

```text
Build / nền tảng / thiết bị:
ID luồng hoặc màn hình:
Mức độ: blocker / major / minor / đề xuất
Các bước tái hiện:
Kết quả thực tế:
Kết quả mong đợi:
Ảnh hoặc video:
Free hay Pro / ngôn ngữ / view / quyền hệ thống:
```

Ưu tiên quyết định: tính đúng đắn và dữ liệu; đường thao tác chính; khả năng đọc và khám phá công cụ; phân biệt Free/Pro và kiểu khóa; độ mượt trên thiết bị; sau đó polish hình ảnh và marketing.

## 30. Bản đồ mã nguồn và nguồn tham chiếu

| Khu vực | File chính trong repository |
|---|---|
| Boot và liên kết dịch vụ | `lib/main.dart` |
| Model | `lib/models/note.dart`, `board.dart`, `draw_stroke.dart`, `view_mode.dart` |
| Điều khiển dữ liệu | `lib/services/notes_controller.dart`, `note_storage.dart`, `settings_controller.dart` |
| Home và menu | `lib/screens/home_screen.dart`, `home_screen_chrome.dart`, `home_screen_actions.dart`, `home_screen_widgets.dart` |
| Wall | `lib/widgets/wall_view.dart`, `wall_view_parts.dart`, `wall_background.dart`, `wall_decor.dart` |
| Note/editor | `lib/widgets/note_views.dart`, `note_dialog.dart`, `note_dialog_pieces.dart`, `drawing_canvas.dart`, `audio_note.dart` |
| Bảng/gallery | `board_bar.dart`, `board_dialog.dart`, `board_picker.dart`, `lib/screens/gallery_screen.dart` |
| Templates/themes | `assets/templates/templates.json`, `lib/services/template_library.dart`, `theme_packs.dart` |
| Memory/frames/sticker | `memory_wall.dart`, `memory_wall_sheet.dart`, `photo_frames.dart`, `stickers.dart`, `sticker_assets.g.dart` |
| Export và media | `board_poster.dart`, `photo_viewer.dart`, `image_service.dart`, `share_service.dart` |
| Cài đặt/quyền/Pro | `settings_sheet.dart`, `widget_settings_sheet.dart`, `pro_sheet.dart`, `pro_controller.dart`, `app_lock.dart`, `lock_gate.dart`, `recents_privacy.dart` |
| Backup/notification/widget | `backup_service.dart`, `auto_backup.dart`, `reminder_service.dart`, `widget_service.dart`; native Android/iOS tương ứng |
| Ngôn ngữ, look | `lib/l10n/app_en.arb`, `app_vi.arb`, `lib/theme.dart` |
| Tài liệu đối chiếu | `README.md`, `PRIVACY.md`, `docs/release/RELEASE_NOTES_1_4_1.md`, `PLAY_LISTING_1_4_1.md`, `STICKY_WALL_1_4_1_QA_MATRIX.md`, `docs/implementation/STICKY_WALL_1_4_1_AUDIT.md` |

Các đường dẫn trên là tham chiếu để tìm source, không cần các file đó để đọc tài liệu HTML này. Phụ lục bên dưới được sinh trực tiếp từ dữ liệu hiện tại trong repository.
'''

def esc(value):
    return html.escape(str(value)).replace('\n', '<br>')

def table(headers, rows):
    return '<div class="table-wrap"><table><thead><tr>'+''.join('<th>'+esc(h)+'</th>' for h in headers)+'</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+esc(c)+'</td>' for c in row)+'</tr>' for row in rows)+'</tbody></table></div>'

def img(path, title, max_width=1050):
    path=ROOT/path
    if not path.exists(): return ''
    image=Image.open(path).convert('RGB')
    image.thumbnail((max_width,1600))
    buffer=io.BytesIO();image.save(buffer,format='JPEG',quality=80,optimize=True)
    encoded=base64.b64encode(buffer.getvalue()).decode()
    return f'<figure><img loading="lazy" src="data:image/jpeg;base64,{encoded}" alt="{esc(title)}"><figcaption>{esc(title)}</figcaption></figure>'

def build():
    template=json.loads((ROOT/'assets/templates/templates.json').read_text(encoding='utf-8'))['templates']
    assets=json.loads((ROOT/'docs/design/STICKY_VISUAL_ASSET_MANIFEST.json').read_text(encoding='utf-8'))['assets']
    vi=json.loads((ROOT/'lib/l10n/app_vi.arb').read_text(encoding='utf-8'))
    en=json.loads((ROOT/'lib/l10n/app_en.arb').read_text(encoding='utf-8'))
    source=(ROOT/'lib/services/theme_packs.dart').read_text(encoding='utf-8')
    packs=re.findall(r'(?:const )?ThemePack\(\s*id: \'([^\']+)\',\s*nameEn: \'([^\']+)\',\s*nameVi: \'([^\']+)\',\s*category: ThemeCategory\.(\w+)',source)
    assert len(template)==45 and len(packs)==37 and len(assets)==197
    pictures='<div class="gallery">'
    for path,title in [
        ('screenshots/mode_wall.png','Preview render từ app: Tường và công cụ kéo/xoay/nối dây'),
        ('screenshots/mode_grid.png','Preview render từ app: Lưới'),
        ('screenshots/mode_list.png','Preview render từ app: Danh sách'),
        ('screenshots/editor.png','Preview render từ app: Editor giấy'),
        ('screenshots/drawing.png','Preview render từ app: Drawing'),
        ('screenshots/photo_editor.png','Preview render từ app: Ảnh trong editor'),
        ('screenshots/settings.png','Preview render từ app: Tùy chỉnh'),
        ('screenshots/export.png','Preview render từ app: Export'),
        ('screenshots/trash.png','Preview render từ app: Trash'),
        ('screenshots/night.png','Preview render từ app: Tắt đèn'),
        ('output/ads/06-checklist-vi/footage/recording_ready.png','Screencap Android giả lập API 35: checklist trước khi tích'),
        ('output/ads/06-checklist-vi/footage/completed.png','Screencap Android giả lập API 35: checklist hoàn thành'),
    ]: pictures+=img(Path(path),title,650)
    pictures+='</div>'
    content=markdown.markdown(BODY,extensions=['tables','fenced_code','toc'])
    content=content.replace('<!-- SCREENSHOTS -->',pictures)
    content+='<h2 id="templates">Phụ lục A — Toàn bộ 45 mẫu bảng</h2>'
    content+=table(['ID','Nhóm','Tên Việt','Tên Anh','Mô tả Việt','Theme gợi ý','Đối tượng / dây'],[
        [t['id'],t['category'],t['name']['vi'],t['name']['en'],t['description']['vi'],t['theme'],f"{len(t['items'])} / {len(t.get('threads',[]))}"] for t in template])
    content+='<h2 id="themes">Phụ lục B — Toàn bộ 37 chủ đề</h2><p>Danh mục tên/nhóm lấy từ source; quyền Pro được app tính từ wall, giấy, font, pin, thread và mùa lễ. Bảng Free/Pro tổng ở mục 24; không suy quyền chỉ từ tên chủ đề.</p>'
    content+=table(['ID','Tên Việt','Tên Anh','Nhóm'],[[p[0],p[2],p[1],p[3]] for p in packs])
    content+='<h2 id="art">Phụ lục C — Toàn bộ sticker ảnh và washi</h2>'
    tapes=[a for a in assets if a['category']=='tape']
    content+=f'<p>{len(assets)-len(tapes)} sticker minh họa; {len(tapes)} băng washi; {sum(a["free"] for a in assets)} asset free. Không bao gồm sticker vẽ bằng code.</p>'
    content+=table(['ID','Nhóm','Tên Việt','Tên Anh','Quyền'],[[a['id'],a['category'],a['vi'],a['en'],'Free' if a['free'] else 'Pro'] for a in assets])
    content+='<h2 id="copy">Phụ lục D — Toàn bộ nội dung UI Anh–Việt</h2><p>Dùng ô tìm kiếm của trình duyệt (Ctrl+F) để tìm nhãn, lỗi hoặc khóa. Placeholder và cấu trúc ICU được giữ nguyên để review logic số nhiều/tham số. Một chuỗi trong catalog chưa chứng minh đang được dùng trong UI.</p>'
    keys=[k for k in en if not k.startswith('@')]
    content+=f'<p>{len(keys)} chuỗi từ app_en.arb; {sum(not k.startswith("@") for k in vi)} chuỗi từ app_vi.arb.</p>'
    content+=table(['Khóa','Tiếng Việt','English'],[[k,vi.get(k,'[THIẾU]'),en[k]] for k in keys])
    # Add ids consistently, including appendices, so navigation is fully offline.
    headings=[]
    def ids(match):
        tag,attrs,text=match.groups()
        old=re.search(r'id="([^"]+)"',attrs)
        identifier=old.group(1) if old else 'section-'+str(len(headings)+1)
        headings.append((identifier,re.sub('<[^>]+>','',text)))
        return f'<{tag} id="{identifier}">{text}</{tag}>'
    content=re.sub(r'<(h2)([^>]*)>(.*?)</h2>',ids,content)
    nav=''.join(f'<a href="#{identifier}">{title}</a>' for identifier,title in headings)
    commit=subprocess.check_output(['git','rev-parse','--short','HEAD'],cwd=ROOT,text=True).strip()
    page='''<!doctype html><html lang="vi"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Sticky Wall — Tổng quan toàn bộ chức năng và UI</title><style>
    :root{color-scheme:light}*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#faf8f2;color:#302d26;font:16px/1.75 system-ui,-apple-system,"Segoe UI",sans-serif}aside{position:fixed;inset:0 auto 0 0;width:275px;background:#eee8db;padding:24px 18px;overflow:auto;border-right:1px solid #d8d0c0}aside strong{display:block;font-size:22px;margin-bottom:10px}aside a{display:block;color:#4c463b;text-decoration:none;font-size:13px;line-height:1.5;padding:6px 4px}aside a:hover{background:#fff7dc}main{max-width:1300px;margin-left:275px;padding:48px 55px 100px}h1{font-size:37px;line-height:1.25}h2{font-size:27px;margin-top:60px;border-top:1px solid #d8cfbd;padding-top:25px;scroll-margin-top:20px}h3{font-size:20px;margin-top:30px}p,li{max-width:1050px}table{width:100%;border-collapse:collapse;font-size:14px;line-height:1.6;margin:20px 0;overflow-wrap:anywhere}th,td{text-align:left;vertical-align:top;padding:12px;border:1px solid #ddd5c8}th{background:#eee7d6}tr:nth-child(even){background:#fffdf8}.table-wrap{overflow-x:auto}code{background:#eee8dd;border-radius:4px;padding:2px 5px;font-size:13px}pre{background:#eee8dd;padding:20px;overflow:auto;line-height:1.6}pre code{padding:0}.gallery{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:20px}figure{margin:0 0 20px}figure img{display:block;width:100%;height:auto;border-radius:12px;border:1px solid #ddd}figcaption{font-size:12px;line-height:1.5;color:#6a6154;padding-top:8px}.stamp{padding:16px 20px;border-left:5px solid #b18a41;background:#f0e6cf;font-size:14px}footer{font-size:13px;color:#6a6154;border-top:1px solid #ddd;margin-top:40px;padding-top:20px}button{padding:9px 14px;background:#38332a;color:white;border:0;border-radius:8px;cursor:pointer}a{color:#705020}@media(max-width:1000px){aside{position:relative;width:auto;max-height:260px}main{margin:0;padding:25px}.gallery{grid-template-columns:repeat(2,minmax(0,1fr))}}@media print{aside,button{display:none}main{margin:0;padding:0;max-width:none}body{background:white;font-size:11px}h1{font-size:27px}h2{font-size:21px;break-after:avoid;margin-top:30px}h3{break-after:avoid}table{font-size:9px}th,td{padding:6px}figure{break-inside:avoid}a{color:inherit;text-decoration:none}.gallery{grid-template-columns:repeat(3,minmax(0,1fr))}pre{white-space:pre-wrap}tr{break-inside:avoid}}</style></head><body>'''
    page+=f'<aside><strong>Sticky Wall</strong><p>Tổng quan để review<br>1.4.2+10 · 06/11/2026</p><button onclick="window.print()">In / Lưu PDF</button>{nav}</aside><main><div class="stamp">Snapshot mã nguồn: <code>{commit}</code> · Một file HTML tự chứa ảnh và dữ liệu · Mở offline · Không gửi dữ liệu đi khi xem.</div>{content}<footer>Biên soạn từ repository Sticky-Wall ngày 06/11/2026. Tài liệu mô tả và checklist review, không thay thế báo cáo test phát hành. Ảnh minh họa phân loại rõ theo nguồn render hoặc giả lập.</footer></main></body></html>'
    OUT.parent.mkdir(parents=True,exist_ok=True)
    OUT.write_text(page,encoding='utf-8')
    print(json.dumps(dict(file=str(OUT),bytes=OUT.stat().st_size,sections=len(headings),templates=len(template),themes=len(packs),assets=len(assets),ui_strings=len(keys),embedded_images=page.count('data:image/jpeg;base64,')),ensure_ascii=False))

if __name__=='__main__': build()

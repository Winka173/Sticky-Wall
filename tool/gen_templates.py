"""Writes assets/templates/templates.json, the board template library.

Each template is real board content: tape headings, notes, to-do lists,
stickers and threads, laid out as fractions of the wall like every note, in
English and Vietnamese. Run from the repo root:

    python tool/gen_templates.py

and check the result with `flutter test test/template_library_test.dart`.
"""
import json
import os

TEMPLATES = []


def L(en, vi, x, y, c=0, scale=1.0):
    d = {'kind': 'label', 'text': {'en': en, 'vi': vi}, 'x': x, 'y': y, 'color': c}
    if scale != 1.0:
        d['scale'] = scale
    return d


def N(en, vi, x, y, c=0, scale=1.0, rot=None, paper=None):
    d = {'kind': 'note', 'text': {'en': en, 'vi': vi}, 'x': x, 'y': y, 'color': c}
    if scale != 1.0:
        d['scale'] = scale
    if rot is not None:
        d['rotation'] = rot
    if paper:
        d['paper'] = paper
    return d


def C(en, vi, items, x, y, c=0, scale=1.0):
    d = {'kind': 'checklist', 'text': {'en': en, 'vi': vi},
         'items': [{'en': a, 'vi': b} for a, b in items], 'x': x, 'y': y, 'color': c}
    if scale != 1.0:
        d['scale'] = scale
    return d


def S(sticker, x, y, scale=1.0):
    d = {'kind': 'sticker', 'sticker': sticker, 'x': x, 'y': y}
    if scale != 1.0:
        d['scale'] = scale
    return d


def T(id, category, theme, name, desc, tags, items, threads=(), orientation='portrait'):
    TEMPLATES.append({
        'id': id,
        'category': category,
        'theme': theme,
        'orientation': orientation,
        'tags': tags,
        'name': {'en': name[0], 'vi': name[1]},
        'description': {'en': desc[0], 'vi': desc[1]},
        'items': items,
        'threads': [
            {'from': t[0], 'to': t[1], 'arrow': t[2] if len(t) > 2 else False,
             **({'label': {'en': t[3][0], 'vi': t[3][1]}} if len(t) > 3 else {})}
            for t in threads
        ],
    })


S3 = 0.72  # a note in a three-column board

# --- Productivity --------------------------------------------------------
T('daily_notes', 'productivity', 'cork_classic',
  ('Daily Notes', 'Ghi chú trong ngày'),
  ('Morning, afternoon and evening, with a to-do list for today.',
   'Sáng, chiều, tối và một danh sách việc hôm nay.'),
  ['daily', 'planning'],
  [L('Morning', 'Buổi sáng', 0.0, 0.0, 0), L('Afternoon', 'Buổi chiều', 1.0, 0.0, 3),
   N('Reply to emails', 'Trả lời email', 0.0, 0.12, 0), N('Lunch with Mai', 'Ăn trưa với Mai', 1.0, 0.12, 3),
   L('Evening', 'Buổi tối', 0.0, 0.45, 5),
   N('Call home', 'Gọi về nhà', 0.0, 0.57, 5),
   C('Today', 'Hôm nay', [('Water the plants', 'Tưới cây'), ('Pay the bill', 'Đóng tiền điện'), ('Walk 20 minutes', 'Đi bộ 20 phút')], 1.0, 0.45, 2)])

T('weekly_planner', 'productivity', 'clean_office',
  ('Weekly Planner', 'Kế hoạch tuần'),
  ('Seven days down the wall, a note beside each.',
   'Bảy ngày dọc bức tường, mỗi ngày một ghi chú.'),
  ['weekly', 'planning'],
  [L('Monday', 'Thứ Hai', 0.0, 0.0, 0), N('Team meeting 9:00', 'Họp nhóm 9:00', 1.0, 0.0, 0, scale=0.8),
   L('Tuesday', 'Thứ Ba', 0.0, 0.15, 1), N('Gym', 'Đi tập', 1.0, 0.15, 1, scale=0.8),
   L('Wednesday', 'Thứ Tư', 0.0, 0.3, 2), N('Dentist 17:30', 'Nha sĩ 17:30', 1.0, 0.3, 2, scale=0.8),
   L('Thursday', 'Thứ Năm', 0.0, 0.45, 3),
   L('Friday', 'Thứ Sáu', 0.0, 0.6, 4), N('Movie night', 'Tối xem phim', 1.0, 0.6, 4, scale=0.8),
   L('Saturday', 'Thứ Bảy', 0.0, 0.75, 5),
   L('Sunday', 'Chủ Nhật', 0.0, 0.9, 0), N('Family lunch', 'Ăn trưa cả nhà', 1.0, 0.9, 0, scale=0.8)])

T('kanban_lite', 'productivity', 'clean_office',
  ('Kanban Lite', 'Kanban gọn'),
  ('To do, doing, done: move each note along as it gets done.',
   'Cần làm, đang làm, xong: kéo ghi chú sang cột kế tiếp khi làm xong.'),
  ['work', 'project'],
  [L('To do', 'Cần làm', 0.0, 0.0, 0, scale=S3), L('Doing', 'Đang làm', 0.5, 0.0, 3, scale=S3), L('Done', 'Xong', 1.0, 0.0, 2, scale=S3),
   N('Draft the plan', 'Viết bản nháp kế hoạch', 0.0, 0.12, 0, scale=S3),
   N('Ask for feedback', 'Xin góp ý', 0.0, 0.34, 0, scale=S3),
   N('Design the cover', 'Thiết kế bìa', 0.5, 0.12, 3, scale=S3),
   N('Book the room', 'Đặt phòng họp', 1.0, 0.12, 2, scale=S3), S('check', 1.0, 0.36, 0.8)])

T('urgent_important', 'productivity', 'minimal_cream',
  ('Urgent / Important', 'Gấp / Quan trọng'),
  ('Four corners: do now, plan, hand over, drop.',
   'Bốn góc: làm ngay, lên lịch, nhờ người khác, bỏ qua.'),
  ['priorities', 'work'],
  [L('Do now', 'Làm ngay', 0.0, 0.0, 1), L('Plan it', 'Lên lịch', 1.0, 0.0, 3),
   N('Tax form due Friday', 'Tờ khai thuế hạn thứ Sáu', 0.0, 0.1, 1, scale=0.85),
   N('Learn to swim', 'Học bơi', 1.0, 0.1, 3, scale=0.85),
   L('Hand over', 'Giao việc', 0.0, 0.5, 0), L('Drop', 'Bỏ qua', 1.0, 0.5, 5),
   N('Pick up the parcel', 'Lấy bưu kiện', 0.0, 0.6, 0, scale=0.85),
   N('Scrolling at night', 'Lướt điện thoại khuya', 1.0, 0.6, 5, scale=0.85)])

T('brain_dump', 'productivity', 'kraft_workshop',
  ('Brain Dump', 'Xả đầu óc'),
  ('Everything on your mind, anywhere on the wall. Sort it later.',
   'Mọi thứ trong đầu, dán đâu cũng được. Sắp xếp sau.'),
  ['thinking', 'quick'],
  [N('Buy a birthday card', 'Mua thiệp sinh nhật', 0.0, 0.0, 0, rot=-0.06),
   N('Fix the bike light', 'Sửa đèn xe đạp', 1.0, 0.05, 1, rot=0.05),
   N('Idea: weekend market stall', 'Ý tưởng: bán hàng chợ cuối tuần', 0.45, 0.3, 4, rot=0.02),
   N('Renew the passport', 'Gia hạn hộ chiếu', 0.0, 0.55, 2, rot=0.04),
   N('Read that book Lan lent me', 'Đọc cuốn sách Lan cho mượn', 1.0, 0.6, 3, rot=-0.04),
   S('star', 0.5, 0.82)])

T('meal_plan', 'productivity', 'warm_wood',
  ('Meal Plan', 'Thực đơn tuần'),
  ('What to cook this week and what to buy for it.',
   'Tuần này nấu gì và cần mua gì.'),
  ['food', 'home'],
  [L('This week', 'Tuần này', 0.0, 0.0, 4),
   N('Mon · Pho', 'T2 · Phở bò', 0.0, 0.1, 4, scale=0.8), N('Tue · Fried rice', 'T3 · Cơm chiên', 1.0, 0.1, 0, scale=0.8),
   N('Wed · Fish soup', 'T4 · Canh cá', 0.0, 0.3, 2, scale=0.8), N('Thu · Spring rolls', 'T5 · Gỏi cuốn', 1.0, 0.3, 1, scale=0.8),
   N('Fri · Eat out', 'T6 · Ăn ngoài', 0.0, 0.5, 3, scale=0.8),
   C('Shopping', 'Đi chợ', [('Rice noodles', 'Bánh phở'), ('Herbs', 'Rau thơm'), ('Eggs', 'Trứng'), ('Fish', 'Cá')], 1.0, 0.55, 0)])

T('shopping_board', 'productivity', 'minimal_cream',
  ('Shopping Board', 'Danh sách mua sắm'),
  ('One list per shop, ticked off in the aisle.',
   'Mỗi cửa hàng một danh sách, tích ngay khi mua.'),
  ['lists', 'home'],
  [C('Market', 'Chợ', [('Tomatoes', 'Cà chua'), ('Garlic', 'Tỏi'), ('Bananas', 'Chuối')], 0.0, 0.0, 2),
   C('Supermarket', 'Siêu thị', [('Dish soap', 'Nước rửa chén'), ('Rice 5 kg', 'Gạo 5 kg'), ('Milk', 'Sữa')], 1.0, 0.0, 3),
   C('Pharmacy', 'Nhà thuốc', [('Plasters', 'Băng cá nhân'), ('Vitamin C', 'Vitamin C')], 0.0, 0.5, 1),
   N('Return the jacket', 'Đổi áo khoác', 1.0, 0.55, 4)])

T('cleaning_day', 'productivity', 'felt_board',
  ('Cleaning Day', 'Ngày dọn nhà'),
  ('Room by room, with who does what.',
   'Từng phòng một, ai làm việc gì.'),
  ['home', 'family'],
  [C('Kitchen', 'Bếp', [('Wipe the hob', 'Lau bếp'), ('Empty the fridge', 'Dọn tủ lạnh')], 0.0, 0.0, 0),
   C('Living room', 'Phòng khách', [('Vacuum', 'Hút bụi'), ('Dust shelves', 'Lau kệ')], 1.0, 0.0, 3),
   C('Bathroom', 'Phòng tắm', [('Scrub the tiles', 'Cọ gạch'), ('New towels', 'Thay khăn')], 0.0, 0.5, 2),
   N('Donate old clothes', 'Quyên góp quần áo cũ', 1.0, 0.55, 4), S('star', 0.5, 0.85)])

T('habit_reminder', 'productivity', 'moss_garden',
  ('Habit Reminders', 'Nhắc thói quen'),
  ('A few small habits to see every day.',
   'Vài thói quen nhỏ để nhìn thấy mỗi ngày.'),
  ['habits', 'health'],
  [L('Every day', 'Mỗi ngày', 0.5, 0.0, 2),
   N('Drink 8 glasses of water', 'Uống 8 cốc nước', 0.0, 0.12, 3),
   N('Stretch for 5 minutes', 'Giãn cơ 5 phút', 1.0, 0.12, 2),
   N('Phone away by 23:00', 'Cất điện thoại trước 23:00', 0.0, 0.42, 5),
   N('Write one good thing', 'Viết một điều tốt', 1.0, 0.42, 0), S('heart', 0.5, 0.75)])

T('meeting_notes', 'productivity', 'clean_office',
  ('Meeting Notes', 'Ghi chú cuộc họp'),
  ('Agenda, decisions and who follows up.',
   'Nội dung họp, quyết định và ai phụ trách.'),
  ['work'],
  [L('Agenda', 'Nội dung', 0.0, 0.0, 3), L('Decisions', 'Quyết định', 1.0, 0.0, 2),
   C('Points', 'Các ý', [('Budget', 'Ngân sách'), ('Launch date', 'Ngày ra mắt'), ('Hiring', 'Tuyển người')], 0.0, 0.1, 3),
   N('Launch moves to May 12', 'Dời ra mắt sang 12/5', 1.0, 0.1, 2),
   L('Follow up', 'Việc tiếp theo', 0.0, 0.55, 0),
   N('Linh: new budget by Fri', 'Linh: gửi ngân sách mới trước T6', 0.0, 0.65, 0),
   N('Tuan: book the venue', 'Tuấn: đặt địa điểm', 1.0, 0.65, 4)],
  [(2, 3, True)])

T('budget_month', 'productivity', 'minimal_cream',
  ('Monthly Budget', 'Ngân sách tháng'),
  ('Money in, money out, and what to save.',
   'Tiền vào, tiền ra và khoản để dành.'),
  ['money', 'home'],
  [L('Income', 'Thu', 0.0, 0.0, 2), L('Spending', 'Chi', 1.0, 0.0, 1),
   N('Salary', 'Lương', 0.0, 0.1, 2, scale=0.85),
   C('Bills', 'Hóa đơn', [('Rent', 'Tiền nhà'), ('Electricity', 'Tiền điện'), ('Internet', 'Internet')], 1.0, 0.1, 1),
   L('Saving for', 'Để dành cho', 0.0, 0.5, 4),
   N('Trip to Da Lat', 'Chuyến đi Đà Lạt', 0.0, 0.6, 4), S('star', 1.0, 0.65)])

# --- Study --------------------------------------------------------------
T('four_subjects', 'study', 'green_classroom',
  ('4-Subject Study Board', 'Bảng học 4 môn'),
  ('A corner for each subject: what is due and what to revise.',
   'Mỗi môn một góc: bài cần nộp và phần cần ôn.'),
  ['school', 'subjects'],
  [L('Maths', 'Toán', 0.0, 0.0, 0), L('Literature', 'Ngữ văn', 1.0, 0.0, 1),
   N('Exercises p. 42', 'Bài tập trang 42', 0.0, 0.1, 0, scale=0.85),
   N('Essay outline', 'Dàn ý bài văn', 1.0, 0.1, 1, scale=0.85),
   L('English', 'Tiếng Anh', 0.0, 0.45, 3), L('Physics', 'Vật lý', 1.0, 0.45, 2),
   N('20 new words', '20 từ mới', 0.0, 0.55, 3, scale=0.85),
   N('Lab report Thu', 'Báo cáo thí nghiệm T5', 1.0, 0.55, 2, scale=0.85)])

T('class_timetable', 'study', 'dark_chalk',
  ('Class Timetable', 'Thời khóa biểu'),
  ('The week at school, a day per row.',
   'Tuần học ở trường, mỗi ngày một hàng.'),
  ['school', 'weekly'],
  [L('Mon', 'Thứ 2', 0.0, 0.0, 0), N('Maths · English · PE', 'Toán · Anh · Thể dục', 1.0, 0.0, 0, scale=0.8),
   L('Tue', 'Thứ 3', 0.0, 0.18, 1), N('Literature · History', 'Văn · Sử', 1.0, 0.18, 1, scale=0.8),
   L('Wed', 'Thứ 4', 0.0, 0.36, 2), N('Physics · Chemistry', 'Lý · Hóa', 1.0, 0.36, 2, scale=0.8),
   L('Thu', 'Thứ 5', 0.0, 0.54, 3), N('Maths · Biology', 'Toán · Sinh', 1.0, 0.54, 3, scale=0.8),
   L('Fri', 'Thứ 6', 0.0, 0.72, 4), N('Art · English', 'Mỹ thuật · Anh', 1.0, 0.72, 4, scale=0.8)])

T('homework_wall', 'study', 'green_classroom',
  ('Homework Wall', 'Bảng bài tập'),
  ('What is due, sorted by date.',
   'Bài cần nộp, xếp theo ngày.'),
  ['school'],
  [L('Due this week', 'Hạn tuần này', 0.0, 0.0, 1),
   C('Maths', 'Toán', [('Ex. 3, 4, 5', 'Bài 3, 4, 5'), ('Check answers', 'Dò đáp án')], 0.0, 0.1, 0),
   C('English', 'Tiếng Anh', [('Unit 6 reading', 'Đọc hiểu bài 6'), ('Write 100 words', 'Viết 100 chữ')], 1.0, 0.1, 3),
   L('Next week', 'Tuần sau', 0.0, 0.55, 2),
   N('History project', 'Dự án lịch sử', 0.0, 0.65, 2), S('check', 1.0, 0.65)])

T('exam_countdown', 'study', 'dark_academia',
  ('Exam Countdown', 'Đếm ngược ngày thi'),
  ('The exam day, the weeks before it and what to cover each week.',
   'Ngày thi, các tuần trước đó và phần cần ôn mỗi tuần.'),
  ['exam', 'school'],
  [N('EXAM · June 20', 'NGÀY THI · 20/6', 0.5, 0.0, 1, scale=1.1),
   L('4 weeks', 'Còn 4 tuần', 0.0, 0.25, 0), N('Algebra and geometry', 'Đại số và hình học', 1.0, 0.25, 0, scale=0.8),
   L('3 weeks', 'Còn 3 tuần', 0.0, 0.42, 3), N('Past papers 2023', 'Đề thi năm 2023', 1.0, 0.42, 3, scale=0.8),
   L('2 weeks', 'Còn 2 tuần', 0.0, 0.59, 2), N('Mock exam', 'Thi thử', 1.0, 0.59, 2, scale=0.8),
   L('Last week', 'Tuần cuối', 0.0, 0.76, 4), N('Rest and review', 'Nghỉ ngơi, xem lại', 1.0, 0.76, 4, scale=0.8)],
  [(2, 0, True)])

T('revision_plan', 'study', 'clean_office',
  ('Revision Plan', 'Kế hoạch ôn tập'),
  ('Topics to revise, how sure you are about each.',
   'Các chủ đề cần ôn và mức độ tự tin với từng phần.'),
  ['exam', 'school'],
  [L('Not yet', 'Chưa chắc', 0.0, 0.0, 1, scale=S3), L('Getting there', 'Tạm ổn', 0.5, 0.0, 4, scale=S3), L('Got it', 'Nắm chắc', 1.0, 0.0, 2, scale=S3),
   N('Quadratics', 'Phương trình bậc hai', 0.0, 0.12, 1, scale=S3),
   N('Poetry terms', 'Thuật ngữ thơ', 0.0, 0.34, 1, scale=S3),
   N('Past tenses', 'Các thì quá khứ', 0.5, 0.12, 4, scale=S3),
   N('Cell structure', 'Cấu tạo tế bào', 1.0, 0.12, 2, scale=S3)])

T('language_notes', 'study', 'linen_lilac',
  ('Language Notes', 'Sổ tay ngoại ngữ'),
  ('New words, a phrase of the day and a grammar rule.',
   'Từ mới, câu nói mỗi ngày và một điểm ngữ pháp.'),
  ['language', 'school'],
  [L('New words', 'Từ mới', 0.0, 0.0, 5),
   N('serendipity · a lucky find', 'serendipity · tình cờ may mắn', 0.0, 0.1, 5, scale=0.85),
   N('wander · to walk with no plan', 'wander · đi lang thang', 1.0, 0.1, 3, scale=0.85),
   L('Phrase of the day', 'Câu nói hôm nay', 0.0, 0.45, 0),
   N('Better late than never', 'Muộn còn hơn không', 0.0, 0.55, 0),
   N('Rule: since + a point in time', 'Ngữ pháp: since + mốc thời gian', 1.0, 0.55, 2)])

T('reading_list', 'study', 'dark_academia',
  ('Reading List', 'Danh sách đọc'),
  ('Reading now, up next, finished.',
   'Đang đọc, sẽ đọc, đã đọc xong.'),
  ['books'],
  [L('Reading now', 'Đang đọc', 0.0, 0.0, 4), N('The Little Prince', 'Hoàng tử bé', 0.0, 0.1, 4),
   L('Up next', 'Sẽ đọc', 1.0, 0.0, 3),
   C('Next', 'Tiếp theo', [('Norwegian Wood', 'Rừng Na Uy'), ('Sapiens', 'Sapiens')], 1.0, 0.1, 3),
   L('Finished', 'Đã đọc', 0.0, 0.55, 2), N('Tuesdays with Morrie', 'Những ngày thứ Ba với thầy Morrie', 0.0, 0.65, 2),
   S('heart', 1.0, 0.65)])

# --- Creative -----------------------------------------------------------
T('moodboard', 'creative', 'brick_loft',
  ('Moodboard', 'Bảng cảm hứng'),
  ('Words, colours and feelings for a project. Add photos as you go.',
   'Từ khóa, màu sắc và cảm xúc cho một dự án. Thêm ảnh dần.'),
  ['design', 'inspiration'],
  [N('Calm', 'Bình yên', 0.0, 0.0, 2, rot=-0.05), N('Morning light', 'Nắng sớm', 1.0, 0.02, 0, rot=0.04),
   N('Linen, wood, clay', 'Vải lanh, gỗ, gốm', 0.45, 0.28, 4, rot=0.02),
   N('Soft greens', 'Xanh lá dịu', 0.0, 0.55, 2, rot=0.05), N('Handwritten', 'Chữ viết tay', 1.0, 0.58, 5, rot=-0.03),
   S('star', 0.5, 0.82)])

T('brainstorm', 'creative', 'kraft_workshop',
  ('Brainstorm', 'Động não'),
  ('One question in the middle, ideas tied to it.',
   'Một câu hỏi ở giữa, các ý tưởng nối dây vào đó.'),
  ['ideas', 'thinking'],
  [N('How do we get more readers?', 'Làm sao có thêm người đọc?', 0.5, 0.35, 0, scale=1.1),
   N('Short videos', 'Video ngắn', 0.0, 0.0, 1, scale=0.85), N('Newsletter', 'Bản tin email', 1.0, 0.02, 3, scale=0.85),
   N('Guest writers', 'Mời viết bài', 0.0, 0.72, 2, scale=0.85), N('Weekly quiz', 'Câu đố hằng tuần', 1.0, 0.74, 4, scale=0.85)],
  [(1, 0), (2, 0), (3, 0), (4, 0)])

T('storyboard', 'creative', 'polaroid_studio',
  ('Storyboard Frames', 'Phân cảnh'),
  ('Six frames in order; sketch or write each one.',
   'Sáu khung theo thứ tự; vẽ hoặc viết từng cảnh.'),
  ['film', 'story'],
  [N('1 · Wide shot of the street', '1 · Toàn cảnh con phố', 0.0, 0.0, 5, scale=0.85),
   N('2 · She opens the shop', '2 · Cô mở cửa tiệm', 1.0, 0.0, 5, scale=0.85),
   N('3 · Close-up: the old clock', '3 · Cận cảnh: chiếc đồng hồ cũ', 0.0, 0.33, 5, scale=0.85),
   N('4 · A customer walks in', '4 · Một vị khách bước vào', 1.0, 0.33, 5, scale=0.85),
   N('5 · They talk; rain starts', '5 · Họ trò chuyện, trời đổ mưa', 0.0, 0.66, 5, scale=0.85),
   N('6 · Lights off, title', '6 · Tắt đèn, hiện tên phim', 1.0, 0.66, 5, scale=0.85)],
  [(0, 1, True), (1, 2, True), (2, 3, True), (3, 4, True), (4, 5, True)])

T('character_map', 'creative', 'vintage_paper',
  ('Character Connections', 'Sơ đồ nhân vật'),
  ('Who knows whom, and how.',
   'Ai quen ai, và quan hệ thế nào.'),
  ['story', 'writing'],
  [N('Minh · the lead', 'Minh · nhân vật chính', 0.5, 0.0, 0),
   N('Hoa · his sister', 'Hoa · em gái', 0.0, 0.4, 1, scale=0.85),
   N('Mr Nam · the teacher', 'Thầy Nam · giáo viên', 1.0, 0.4, 3, scale=0.85),
   N('Lan · the rival', 'Lan · đối thủ', 0.5, 0.75, 4, scale=0.85)],
  [(0, 1, False, ('family', 'gia đình')), (0, 2, False, ('mentor', 'thầy trò')), (0, 3, True, ('rivals', 'đối thủ')), (1, 3, False, ('friends', 'bạn thân'))])

T('creative_project', 'creative', 'terrazzo_pop',
  ('Creative Project', 'Dự án sáng tạo'),
  ('From idea to finished piece, step by step.',
   'Từ ý tưởng tới thành phẩm, từng bước một.'),
  ['project', 'art'],
  [N('Idea', 'Ý tưởng', 0.0, 0.0, 0, scale=0.8), N('Sketches', 'Phác thảo', 1.0, 0.15, 1, scale=0.8),
   N('Materials', 'Vật liệu', 0.0, 0.35, 4, scale=0.8), N('Make it', 'Thực hiện', 1.0, 0.5, 3, scale=0.8),
   N('Share it', 'Chia sẻ', 0.0, 0.7, 2, scale=0.8),
   C('Materials', 'Cần chuẩn bị', [('Watercolour paper', 'Giấy màu nước'), ('Brushes', 'Cọ vẽ')], 1.0, 0.8, 5, scale=0.8)],
  [(0, 1, True), (1, 2, True), (2, 3, True), (3, 4, True)])

T('color_palette', 'creative', 'minimal_cream',
  ('Colour Palette Board', 'Bảng phối màu'),
  ('Papers in a row to try a palette; rename each with its use.',
   'Các tờ giấy thành một dải màu; ghi công dụng của từng màu.'),
  ['design', 'colour'],
  [L('Palette', 'Bảng màu', 0.5, 0.0, 0),
   N('Background', 'Nền', 0.0, 0.12, 0, scale=0.75), N('Headings', 'Tiêu đề', 0.5, 0.12, 1, scale=0.75),
   N('Buttons', 'Nút bấm', 1.0, 0.12, 2, scale=0.75), N('Links', 'Liên kết', 0.0, 0.4, 3, scale=0.75),
   N('Warnings', 'Cảnh báo', 0.5, 0.4, 4, scale=0.75), N('Accents', 'Điểm nhấn', 1.0, 0.4, 5, scale=0.75)])

# --- Personal -----------------------------------------------------------
T('vision_board', 'personal', 'marble_desk',
  ('Vision Board', 'Bảng ước mơ'),
  ('What this year should feel like, in a few words.',
   'Năm nay bạn muốn thế nào, gói trong vài chữ.'),
  ['goals', 'year'],
  [L('This year', 'Năm nay', 0.5, 0.0, 5),
   N('Travel somewhere new', 'Đi một nơi mới', 0.0, 0.12, 3, rot=-0.04),
   N('Run 10 km', 'Chạy 10 km', 1.0, 0.14, 2, rot=0.05),
   N('Save for a home', 'Để dành mua nhà', 0.45, 0.42, 4, rot=0.02),
   N('Learn the guitar', 'Học đàn guitar', 0.0, 0.68, 1, rot=0.04), S('star', 1.0, 0.7), S('heart', 0.5, 0.85)])

T('gratitude', 'personal', 'linen_lilac',
  ('Gratitude Board', 'Bảng biết ơn'),
  ('One small good thing a day.',
   'Mỗi ngày một điều nhỏ đáng biết ơn.'),
  ['mindful', 'daily'],
  [L('Thankful for', 'Biết ơn vì', 0.5, 0.0, 1),
   N('Warm soup on a rainy day', 'Bát canh nóng ngày mưa', 0.0, 0.12, 1, rot=-0.03),
   N('A friend who listened', 'Một người bạn chịu lắng nghe', 1.0, 0.16, 5, rot=0.04),
   N('Sunlight on the desk', 'Nắng chiếu lên bàn', 0.0, 0.45, 0, rot=0.03),
   N('Mum\'s message', 'Tin nhắn của mẹ', 1.0, 0.5, 2, rot=-0.03), S('heart', 0.5, 0.78)])

T('goal_wall', 'personal', 'cork_classic',
  ('Goal Wall', 'Bảng mục tiêu'),
  ('One goal, the steps to it and the first one to do.',
   'Một mục tiêu, các bước để đạt và bước đầu tiên.'),
  ['goals'],
  [N('Run a half marathon', 'Chạy bán marathon', 0.5, 0.0, 1, scale=1.1),
   C('Steps', 'Các bước', [('Run 3 times a week', 'Chạy 3 buổi mỗi tuần'), ('Sign up for a race', 'Đăng ký giải'), ('Buy good shoes', 'Mua giày tốt')], 0.0, 0.35, 2),
   N('First: 5 km on Saturday', 'Trước tiên: 5 km sáng thứ Bảy', 1.0, 0.4, 0), S('star', 0.5, 0.8)],
  [(1, 0, True), (2, 0, True)])

T('bucket_list', 'personal', 'travel_journal',
  ('Bucket List', 'Những điều muốn làm'),
  ('Things to do one day, ticked off as they happen.',
   'Những việc muốn làm một lần trong đời, tích khi đã làm.'),
  ['dreams', 'travel'],
  [C('One day', 'Một ngày nào đó', [('See the northern lights', 'Ngắm cực quang'), ('Ha Giang loop by bike', 'Đi phượt Hà Giang'), ('Learn to dive', 'Học lặn'), ('Write a short story', 'Viết một truyện ngắn')], 0.0, 0.0, 3),
   N('Next up: Ha Giang in October', 'Sắp tới: Hà Giang tháng 10', 1.0, 0.1, 4),
   S('star', 1.0, 0.5), S('heart', 0.0, 0.6)])

T('memories', 'personal', 'polaroid_studio',
  ('Personal Memories', 'Kỷ niệm riêng'),
  ('Moments worth keeping; add photos beside the words.',
   'Những khoảnh khắc đáng nhớ; thêm ảnh bên cạnh.'),
  ['memories', 'photos'],
  [N('First day at the new job', 'Ngày đầu đi làm chỗ mới', 0.0, 0.0, 0, rot=-0.04),
   N('Night swim at Nha Trang', 'Tắm biển đêm ở Nha Trang', 1.0, 0.1, 3, rot=0.05),
   N('Grandma\'s 80th birthday', 'Sinh nhật 80 tuổi của bà', 0.0, 0.42, 1, rot=0.03),
   N('Our first tiny flat', 'Căn hộ nhỏ đầu tiên', 1.0, 0.52, 4, rot=-0.04), S('heart', 0.5, 0.82)])

T('milestones', 'personal', 'marble_desk',
  ('Relationship Milestones', 'Cột mốc của hai đứa'),
  ('The dates that mattered, in order.',
   'Những ngày đáng nhớ, theo thứ tự.'),
  ['love', 'memories'],
  [N('First coffee · 2019', 'Ly cà phê đầu tiên · 2019', 0.0, 0.0, 1, scale=0.85),
   N('First trip · Hoi An', 'Chuyến đi đầu · Hội An', 1.0, 0.18, 0, scale=0.85),
   N('Moved in together', 'Dọn về ở chung', 0.0, 0.38, 3, scale=0.85),
   N('Adopted Miu the cat', 'Nhận nuôi mèo Miu', 1.0, 0.56, 4, scale=0.85),
   N('What next?', 'Tiếp theo là gì?', 0.0, 0.76, 5, scale=0.85), S('heart', 1.0, 0.82)],
  [(0, 1, True), (1, 2, True), (2, 3, True), (3, 4, True)])

T('workout_week', 'personal', 'clean_office',
  ('Workout Week', 'Lịch tập tuần'),
  ('Training days and rest days, ticked as you go.',
   'Ngày tập và ngày nghỉ, tích khi hoàn thành.'),
  ['health', 'weekly'],
  [C('This week', 'Tuần này', [('Mon · run 5 km', 'T2 · chạy 5 km'), ('Wed · yoga', 'T4 · yoga'), ('Fri · strength', 'T6 · tập sức mạnh'), ('Sun · long walk', 'CN · đi bộ dài')], 0.0, 0.0, 2),
   N('Rest is training too', 'Nghỉ ngơi cũng là tập', 1.0, 0.1, 0), S('check', 1.0, 0.45)])

# --- Family -------------------------------------------------------------
T('chores', 'family', 'rainbow_school',
  ('Family Chores', 'Việc nhà'),
  ('Who does what this week.',
   'Tuần này ai làm việc gì.'),
  ['family', 'home'],
  [L('Mum', 'Mẹ', 0.0, 0.0, 1, scale=S3), L('Dad', 'Bố', 0.5, 0.0, 3, scale=S3), L('Kids', 'Các con', 1.0, 0.0, 0, scale=S3),
   N('Cooking', 'Nấu ăn', 0.0, 0.12, 1, scale=S3), N('Laundry', 'Giặt đồ', 0.5, 0.12, 3, scale=S3),
   N('Dishes', 'Rửa chén', 1.0, 0.12, 0, scale=S3), N('Feed the cat', 'Cho mèo ăn', 1.0, 0.34, 0, scale=S3),
   S('star', 0.5, 0.6)])

T('family_reminders', 'family', 'felt_board',
  ('Family Reminders', 'Nhắc nhở gia đình'),
  ('Appointments, school notes and things not to forget.',
   'Lịch hẹn, giấy báo của trường và những việc đừng quên.'),
  ['family'],
  [N('Parent meeting · Sat 8:00', 'Họp phụ huynh · T7 8:00', 0.0, 0.0, 3),
   N('Vaccine for Bin · 15th', 'Tiêm phòng cho Bin · ngày 15', 1.0, 0.05, 1),
   N('Grandpa visits Sunday', 'Ông sang chơi Chủ Nhật', 0.0, 0.38, 2),
   C('Bring to school', 'Mang tới trường', [('Art kit', 'Hộp màu'), ('Signed form', 'Giấy có chữ ký')], 1.0, 0.42, 0)])

T('birthday_ideas', 'family', 'pastel_kawaii',
  ('Birthday Ideas', 'Ý tưởng sinh nhật'),
  ('Gift ideas, the plan for the day and the guest list.',
   'Ý tưởng quà, kế hoạch trong ngày và danh sách khách.'),
  ['birthday', 'party'],
  [N('Bé Na turns 6!', 'Bé Na tròn 6 tuổi!', 0.5, 0.0, 1, scale=1.1),
   C('Gift ideas', 'Ý tưởng quà', [('Drawing set', 'Bộ màu vẽ'), ('Picture books', 'Truyện tranh')], 0.0, 0.3, 5),
   C('Guests', 'Khách mời', [('Classmates', 'Bạn cùng lớp'), ('Cousins', 'Anh chị họ')], 1.0, 0.3, 3),
   N('Cake: strawberry', 'Bánh kem: dâu', 0.0, 0.7, 0), S('heart', 1.0, 0.72), S('star', 0.5, 0.88)])

T('wedding_lite', 'family', 'soft_lavender',
  ('Wedding Planning Lite', 'Chuẩn bị đám cưới'),
  ('The big pieces and who is handling each.',
   'Các việc lớn và ai lo việc nào.'),
  ['wedding', 'planning'],
  [L('Before', 'Trước cưới', 0.0, 0.0, 5), L('On the day', 'Ngày cưới', 1.0, 0.0, 1),
   C('To book', 'Cần đặt', [('Venue', 'Nhà hàng'), ('Photographer', 'Thợ ảnh'), ('Áo dài', 'Áo dài')], 0.0, 0.1, 5),
   N('Ceremony 9:00 · lunch 11:30', 'Lễ 9:00 · tiệc 11:30', 1.0, 0.1, 1),
   N('Guest list: 120', 'Danh sách khách: 120', 0.0, 0.6, 0), S('heart', 1.0, 0.6)])

T('travel_ideas', 'family', 'travel_journal',
  ('Travel Idea Wall', 'Ý tưởng du lịch'),
  ('Places, what to see there and what to pack.',
   'Điểm đến, nên xem gì và cần mang gì.'),
  ['travel'],
  [N('Da Lat · 3 days', 'Đà Lạt · 3 ngày', 0.0, 0.0, 3, rot=-0.04),
   N('Flower farms, night market', 'Vườn hoa, chợ đêm', 1.0, 0.14, 2, rot=0.03),
   N('Phu Quoc · beach week', 'Phú Quốc · tuần lễ biển', 0.0, 0.45, 0, rot=0.04),
   C('Pack', 'Đồ mang theo', [('Jacket', 'Áo khoác'), ('Sunscreen', 'Kem chống nắng'), ('Chargers', 'Sạc')], 1.0, 0.52, 4),
   S('heart', 0.5, 0.86)],
  [(0, 1)])

T('baby_memories', 'family', 'pastel_kawaii',
  ('Baby Memories', 'Kỷ niệm của bé'),
  ('Firsts worth remembering; add a photo to each.',
   'Những lần đầu tiên đáng nhớ; thêm ảnh cho từng mốc.'),
  ['baby', 'memories'],
  [N('First smile', 'Nụ cười đầu tiên', 0.0, 0.0, 1, rot=-0.04),
   N('First word: "mẹ"', 'Tiếng nói đầu tiên: "mẹ"', 1.0, 0.1, 0, rot=0.04),
   N('First steps', 'Những bước đi đầu', 0.0, 0.42, 3, rot=0.03),
   N('First tooth', 'Chiếc răng đầu tiên', 1.0, 0.5, 5, rot=-0.03), S('heart', 0.5, 0.8)])

T('recipe_board', 'family', 'warm_wood',
  ('Recipe Board', 'Bảng công thức'),
  ('A recipe card with what you need and the steps.',
   'Một tấm thẻ công thức: nguyên liệu và các bước.'),
  ['food', 'home'],
  [N('Grandma\'s braised pork', 'Thịt kho của bà', 0.5, 0.0, 4, scale=1.1),
   C('You need', 'Nguyên liệu', [('Pork belly', 'Thịt ba chỉ'), ('Eggs', 'Trứng'), ('Coconut water', 'Nước dừa'), ('Fish sauce', 'Nước mắm')], 0.0, 0.3, 0),
   N('Brown the pork, add coconut water, simmer 1 hour', 'Xào thịt săn, thêm nước dừa, kho 1 tiếng', 1.0, 0.35, 2)])

T('garden_plan', 'family', 'moss_garden',
  ('Garden Plan', 'Kế hoạch vườn'),
  ('What grows where, and when to water.',
   'Trồng gì ở đâu và khi nào tưới.'),
  ['garden', 'home'],
  [L('Balcony', 'Ban công', 0.0, 0.0, 2), L('Kitchen window', 'Cửa sổ bếp', 1.0, 0.0, 0),
   N('Basil, mint', 'Húng quế, bạc hà', 0.0, 0.1, 2, scale=0.85), N('Chilli, spring onion', 'Ớt, hành lá', 1.0, 0.1, 0, scale=0.85),
   C('Water', 'Tưới cây', [('Morning, every day', 'Sáng, mỗi ngày'), ('Fertilise on Sundays', 'Bón phân Chủ Nhật')], 0.0, 0.5, 3)])

# --- Seasonal -----------------------------------------------------------
T('tet_wishes', 'seasonal', 'lunar_new_year',
  ('Lunar New Year Wishes', 'Lời chúc Tết'),
  ('Wishes for the new year, the Tết to-do list and who to visit.',
   'Lời chúc năm mới, việc cần làm ngày Tết và nhà cần đi chúc.'),
  ['tet', 'family'],
  [N('Happy New Year!', 'Chúc mừng năm mới!', 0.5, 0.0, 0, scale=1.1),
   C('Before Tết', 'Trước Tết', [('Clean the house', 'Dọn nhà'), ('Buy apricot blossom', 'Mua cành mai'), ('Wrap bánh chưng', 'Gói bánh chưng')], 0.0, 0.3, 1),
   N('Visit: grandparents, Uncle Hai', 'Đi chúc Tết: ông bà, bác Hai', 1.0, 0.32, 4),
   N('Wish: health for everyone', 'Ước: cả nhà mạnh khỏe', 1.0, 0.65, 0), S('heart', 0.0, 0.75)])

T('valentine_memories', 'seasonal', 'valentine',
  ('Valentine Memories', 'Kỷ niệm Valentine'),
  ('Little notes to each other and a plan for the evening.',
   'Những lời nhắn cho nhau và kế hoạch buổi tối.'),
  ['love'],
  [N('Dinner at 19:00', 'Ăn tối lúc 19:00', 0.0, 0.0, 1),
   N('Thank you for the coffee every morning', 'Cảm ơn ly cà phê mỗi sáng', 1.0, 0.08, 0, rot=0.04),
   N('Our song: "Em gái mưa"', 'Bài hát của hai đứa: "Em gái mưa"', 0.0, 0.42, 5, rot=-0.03),
   S('heart', 1.0, 0.45, 1.2), S('heart', 0.5, 0.78)])

T('mid_autumn_board', 'seasonal', 'mid_autumn',
  ('Mid-Autumn', 'Trung thu'),
  ('Lanterns, mooncakes and the evening plan.',
   'Đèn lồng, bánh trung thu và kế hoạch buổi tối.'),
  ['family', 'kids'],
  [N('Full moon · 15th', 'Rằm tháng Tám', 0.5, 0.0, 4, scale=1.1),
   C('To get', 'Cần chuẩn bị', [('Mooncakes', 'Bánh trung thu'), ('Star lantern', 'Đèn ông sao'), ('Pomelo', 'Bưởi')], 0.0, 0.3, 0),
   N('Lantern walk 19:30', 'Rước đèn 19:30', 1.0, 0.35, 3), S('star', 0.5, 0.75)])

T('christmas_wishes', 'seasonal', 'christmas',
  ('Christmas Wishes', 'Điều ước Giáng sinh'),
  ('Gifts, cards and the Christmas Eve plan.',
   'Quà tặng, thiệp và kế hoạch đêm Noel.'),
  ['gifts', 'family'],
  [L('Gifts', 'Quà tặng', 0.0, 0.0, 1),
   C('For', 'Tặng ai', [('Mum · scarf', 'Mẹ · khăn quàng'), ('Dad · book', 'Bố · sách'), ('Bin · lego', 'Bin · lego')], 0.0, 0.1, 1),
   N('Eve: church at 21:00', 'Đêm Noel: đi lễ 21:00', 1.0, 0.1, 2),
   N('Send cards by the 20th', 'Gửi thiệp trước ngày 20', 1.0, 0.45, 0), S('star', 0.5, 0.78)])

T('halloween_moodboard', 'seasonal', 'warm_autumn',
  ('Halloween Moodboard', 'Ý tưởng Halloween'),
  ('Costume ideas, the party plan and the snack list.',
   'Ý tưởng hóa trang, kế hoạch tiệc và đồ ăn vặt.'),
  ['party', 'costume'],
  [N('Costume: a friendly ghost', 'Hóa trang: con ma hiền', 0.0, 0.0, 4, rot=-0.04),
   N('Carve pumpkins Fri', 'Khắc bí ngô tối T6', 1.0, 0.08, 0, rot=0.03),
   C('Snacks', 'Đồ ăn vặt', [('Candy', 'Kẹo'), ('Popcorn', 'Bỏng ngô'), ('Pumpkin soup', 'Súp bí')], 0.0, 0.42, 1),
   S('star', 1.0, 0.5)])

T('back_to_school', 'seasonal', 'rainbow_school',
  ('Back to School', 'Năm học mới'),
  ('What to buy, forms to sign and the first-week plan.',
   'Đồ cần mua, giấy tờ cần ký và kế hoạch tuần đầu.'),
  ['school', 'kids'],
  [C('To buy', 'Cần mua', [('Notebooks', 'Vở'), ('Pens', 'Bút'), ('Backpack', 'Ba lô'), ('Uniform', 'Đồng phục')], 0.0, 0.0, 0),
   C('Forms', 'Giấy tờ', [('Health form', 'Phiếu sức khỏe'), ('Bus card', 'Thẻ xe buýt')], 1.0, 0.0, 3),
   N('First day: Sept 5, 7:00', 'Khai giảng: 5/9, 7:00', 0.0, 0.55, 1), S('star', 1.0, 0.6)])

if __name__ == '__main__':
    ids = [t['id'] for t in TEMPLATES]
    assert len(ids) == len(set(ids)), 'duplicate ids'
    out = os.path.join('assets', 'templates', 'templates.json')
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, 'w', encoding='utf-8') as f:
        json.dump({'version': 1, 'templates': TEMPLATES}, f, ensure_ascii=False, indent=1)
        f.write('\n')
    print(len(TEMPLATES), 'templates ->', out)

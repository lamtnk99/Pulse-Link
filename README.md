# Pulse Link

## Giới thiệu dự án

**PULSE LINK — MẠCH SỐNG** là nền tảng điều phối hiến máu cấp cứu ứng dụng **Generative AI** và **dữ liệu thời gian thực** nhằm giải quyết bài toán kết nối người hiến máu với bệnh viện và bệnh nhân trong các tình huống khẩn cấp.

Khác với các nền tảng hiến máu hiện nay chủ yếu dừng lại ở việc đăng ký hoặc cung cấp thông tin, **Pulse Link** xây dựng một quy trình điều phối thông minh, tự động và xuyên suốt: từ dự báo nhu cầu máu, phát hiện nguy cơ thiếu hụt, huy động người hiến phù hợp, theo dõi hành trình máu, ghi nhận đóng góp, đến chăm sóc người hiến sau khi hoàn tất.

Hệ thống hiện tập trung vào các nhóm tính năng chính:

- **Điều phối hiến máu khẩn cấp SOS**: bệnh viện có thể phát lệnh báo động đỏ theo nhóm máu, số đơn vị cần huy động, vị trí và mức độ khẩn cấp. Backend tự động lọc người hiến tương thích theo nhóm máu, khoảng cách địa lý và trạng thái sẵn sàng, sau đó mở rộng phạm vi theo từng wave để tăng tốc độ tìm người phù hợp.
- **Theo dõi realtime cho bệnh viện và điều phối viên**: Web Admin hiển thị ca SOS đang hoạt động, danh sách người đã được thông báo, người đã cam kết, người đang di chuyển và người đã đến nơi. Trạng thái được cập nhật realtime để đội điều phối ra quyết định nhanh trong từng phút.
- **Ứng dụng Mobile cho người hiến máu**: người dùng có Hero Pass cá nhân, thông tin nhóm máu, điểm cống hiến, lịch sử hiến máu, lịch đã đặt, bộ đếm thời gian hồi phục sức khỏe và khả năng nhận lời kêu gọi SOS ngay trên điện thoại.
- **Xác nhận cam kết an toàn bằng hold-to-confirm**: với các ca cấp cứu, Mobile yêu cầu người hiến giữ xác nhận trong 3 giây để giảm thao tác nhầm, đồng thời gửi trạng thái cam kết về hệ thống điều phối.
- **Lập tuyến đường đến bệnh viện**: sau khi cam kết SOS, hệ thống có thể trả về kế hoạch di chuyển, khoảng cách và thời gian dự kiến để người hiến nhanh chóng đến đúng điểm tiếp nhận.
- **Quản lý sự kiện hiến máu thường quy**: Admin tạo, chỉnh sửa, phân trang, tìm kiếm và quản lý các sự kiện hiến máu; người dùng Mobile xem sự kiện, đọc chi tiết, đặt lịch và hủy lịch qua API.
- **Bản tin cộng đồng và truyền thông hiến máu**: Admin quản lý bài viết cộng đồng, lưu nháp hoặc xuất bản, lựa chọn đối tượng nhận tin theo nhóm máu, cấp Hero hoặc địa phương; Mobile hiển thị tin tức để duy trì kết nối với cộng đồng người hiến.
- **Kho máu và dự báo nhu cầu bằng AI**: hệ thống Admin có module theo dõi tồn kho máu, ngưỡng an toàn, cảnh báo thiếu hụt và dự báo nhu cầu trong tương lai bằng AI dựa trên dữ liệu vận hành, kịch bản dịch bệnh, thời tiết hoặc ngày lễ.
- **Đề xuất chiến dịch từ AI**: khi phát hiện nguy cơ thiếu máu, hệ thống có thể gợi ý đợt hiến máu hoặc nội dung kêu gọi phù hợp để điều phối viên nhanh chóng phát động chiến dịch bổ sung nguồn máu.
- **Hành trình máu sau hiến**: với các ca SOS và lượt hiến đã ghi nhận, Pulse Link theo dõi quá trình máu được tiếp nhận, xử lý, lưu trữ hoặc truyền cho bệnh nhân. Người hiến có thể nhìn thấy tác động thực tế từ đóng góp của mình thay vì chỉ dừng ở một lần đăng ký.
- **Chứng nhận, ghi nhận và chăm sóc sau hiến**: hệ thống tạo chứng nhận hiến máu, cập nhật điểm/cấp Hero, gửi thông báo chăm sóc sau hiến và tạo thư cảm ơn cá nhân hóa để tăng động lực quay lại của người hiến.
- **Trợ lý sức khỏe AI**: Mobile tích hợp chatbot sức khỏe để hỗ trợ người hiến hỏi đáp về điều kiện hiến máu, phục hồi sau hiến và các lưu ý cá nhân hóa dựa trên ngữ cảnh hồ sơ.
- **Quyên góp và chiến dịch hỗ trợ**: Pulse Link có luồng quản lý chiến dịch quyên góp, giao dịch demo và bảng xếp hạng đóng góp nhằm mở rộng tinh thần hỗ trợ cộng đồng bên cạnh hoạt động hiến máu.
- **Quản trị bệnh viện, nhân sự và phân quyền**: Web Admin hỗ trợ dashboard vận hành, quản lý bệnh viện, nhân sự, quyền truy cập theo vai trò và phạm vi bệnh viện, giúp hệ thống phù hợp với mô hình nhiều đơn vị y tế.
- **Dữ liệu địa phương Việt Nam**: backend seed dữ liệu tỉnh/thành, phường/xã, bệnh viện, người hiến, sự kiện, bài viết và các kịch bản SOS mẫu để demo sát thực tế vận hành tại Việt Nam.

Nền tảng giúp:

- Dự báo nhu cầu máu bằng dữ liệu thời gian thực.
- Ghép nối nhanh người hiến phù hợp theo nhóm máu, vị trí và khả năng đáp ứng.
- Nâng cao khả năng cứu sống người bệnh trong thời điểm nguy cấp.
- Theo dõi, ghi nhận và chăm sóc người hiến, góp phần duy trì một cộng đồng hiến máu bền vững.

> **Pulse Link không chỉ là một nền tảng công nghệ.  
> Pulse Link là cầu nối giữa dữ liệu, trí tuệ nhân tạo và lòng nhân ái.**

## Thông điệp dự án

**Mỗi giọt máu trao đi là một mạch sống được tiếp nối.**

Pulse Link được xây dựng với niềm tin rằng trong cấp cứu, thời gian, dữ liệu và sự sẵn lòng của cộng đồng đều có thể trở thành cơ hội sống cho người bệnh. Nền tảng không chỉ giúp tìm người hiến máu nhanh hơn, mà còn giúp mỗi hành động hiến máu được ghi nhận, theo dõi và lan tỏa thành một vòng kết nối nhân ái bền vững.

## Vì sao Pulse Link xứng đáng được lựa chọn?

- **Giải quyết đúng bài toán cấp thiết**: thiếu máu trong tình huống khẩn cấp đòi hỏi tốc độ phản ứng cao, dữ liệu chính xác và khả năng điều phối tức thời giữa bệnh viện, người hiến và đội vận hành.
- **Khác biệt so với nền tảng đăng ký hiến máu truyền thống**: Pulse Link không dừng ở việc lưu thông tin người hiến, mà xây dựng một quy trình khép kín từ dự báo nhu cầu, kích hoạt SOS, ghép nối, xác nhận cam kết, theo dõi di chuyển đến ghi nhận kết quả.
- **Kết hợp AI và realtime một cách thực tiễn**: AI được dùng để hỗ trợ dự báo nhu cầu máu, phân tích thiếu hụt, gợi ý chiến dịch; realtime giúp điều phối viên theo dõi diễn biến ca SOS ngay khi người hiến phản hồi.
- **Lấy người hiến làm trung tâm**: Mobile app có Hero Pass, lịch sử hiến máu, chứng nhận, thư cảm ơn, hành trình máu và chăm sóc sau hiến để người hiến thấy rõ ý nghĩa đóng góp của mình.
- **Phù hợp với bối cảnh Việt Nam**: hệ thống sử dụng dữ liệu địa phương, bệnh viện, tỉnh/thành, phường/xã và các kịch bản vận hành gần với thực tế triển khai trong nước.
- **Có khả năng mở rộng**: kiến trúc gồm Mobile Flutter, Backend Laravel và Web Admin Vue có thể tiếp tục mở rộng sang xác thực thật, tích hợp FCM, bản đồ, hệ thống bệnh viện và dữ liệu kho máu thực tế.

## Tầm nhìn phát triển

Trong giai đoạn tiếp theo, Pulse Link hướng tới trở thành một hạ tầng điều phối hiến máu thông minh, có thể kết nối nhiều bệnh viện, trung tâm truyền máu, tổ chức tình nguyện và cộng đồng người hiến trên cùng một mạng lưới dữ liệu.

Các định hướng phát triển chính:

- Tích hợp xác thực người dùng, hồ sơ y tế cơ bản và quy trình xác minh danh tính người hiến.
- Kết nối dữ liệu kho máu thật từ bệnh viện và trung tâm truyền máu để nâng cao độ chính xác của dự báo AI.
- Duy trì FCM push notification cho Android/iOS; tiếp tục mở rộng sang SMS, email hoặc các nền tảng nhắn tin phổ biến khi vận hành chính thức.
- Tối ưu thuật toán ghép nối người hiến dựa trên nhóm máu, khoảng cách, lịch sử hiến, thời gian hồi phục và khả năng đáp ứng.
- Xây dựng bản đồ điều phối vùng, giúp theo dõi năng lực đáp ứng máu theo khu vực và hỗ trợ quyết định trong thiên tai, dịch bệnh hoặc sự cố hàng loạt.
- Phát triển hệ thống tri ân, chứng nhận số và báo cáo tác động để duy trì cộng đồng người hiến lâu dài.

## Các nhóm người dùng chính

- **Người hiến máu**: đăng ký hồ sơ, xem Hero Pass, theo dõi lịch sử hiến máu, nhận lời kêu gọi SOS, đặt lịch hiến máu thường quy và nhận chứng nhận sau hiến.
- **Bệnh viện và trung tâm truyền máu**: tạo yêu cầu SOS, theo dõi người hiến theo thời gian thực, quản lý sự kiện hiến máu, ghi nhận lượt hiến và cập nhật hành trình máu.
- **Điều phối viên/Admin**: giám sát dashboard, quản lý ca khẩn cấp, quản lý bài viết cộng đồng, sự kiện, kho máu, dự báo AI, nhân sự và phân quyền.
- **Bệnh nhân/người nhận máu**: là nhóm hưởng lợi trực tiếp khi hệ thống giúp rút ngắn thời gian tìm nguồn máu phù hợp trong tình huống nguy cấp.
- **Tổ chức cộng đồng và nhà tài trợ**: có thể tham gia các chiến dịch vận động hiến máu, quyên góp và truyền thông để mở rộng mạng lưới hỗ trợ.

## Đội ngũ phát triển

| Vai trò | Thành viên |
| --- | --- |
| Project Lead | Bùi Ngọc Minh |
| Backend Developer | Nguyễn Văn Dân |
| Frontend Developer | Đào Minh Quân |
| AI Engineer | Phùng Văn Đại |
| UI/UX Designer | Bùi Đức Đại |

## License

Dự án được phát triển phục vụ mục đích học tập, nghiên cứu và tham gia cuộc thi.

## Tổng quan kỹ thuật

Pulse Link là hệ sinh thái hiến máu gồm Mobile Flutter, Backend Laravel 11 và Web Admin Vue 3. Dự án đang ưu tiên demo vận hành thật cho hai luồng chính:

- **Daily Mode**: Hero Pass, tin cộng đồng, sự kiện hiến máu, đặt/hủy lịch, lịch đã đặt, lịch sử hiến máu và health tracker.
- **SOS Mode**: bệnh viện phát báo động đỏ, backend điều phối tình nguyện viên theo wave địa lý, Admin theo dõi realtime, Mobile nhận SOS và xác nhận bằng hold-to-confirm.

## Kiến Trúc Hiện Tại

### Mobile Flutter

Thư mục chính:

- `lib/app`: bootstrap, config `dart-define`, Firebase/FCM và điều phối state toàn ứng dụng.
- `lib/features/daily`: Daily Mode, Hero Pass, sự kiện, bài viết, lịch đặt, lịch sử.
- `lib/features/sos`: SOS Mode, hold-to-confirm, route plan, trạng thái khẩn cấp.
- `lib/shared`: theme, widgets, models/repositories dùng chung.
- `assets/audio`: âm thanh nhịp tim.
- `assets/images`: ảnh demo.

Mobile có hai chế độ:

- `USE_MOCK_SERVICES=true`: chạy demo offline bằng mock data.
- `USE_MOCK_SERVICES=false`: gọi Laravel thật qua `LARAVEL_API_BASE_URL`.

### Backend Laravel 11

Thư mục chính:

- `backend/routes/api.php`: toàn bộ API mobile/admin/location.
- `backend/app/Http/Controllers/Api/Mobile`: API cho Flutter.
- `backend/app/Http/Controllers/Api/Admin`: dashboard, SOS, event/post CRUD, upload, staff.
- `backend/app/Services/Admin/AdminUserResolver.php`: demo resolver cho quyền admin.
- `backend/app/Services/Emergency`: điều phối SOS.
- `backend/app/Repositories`: repository pattern cho donor, alert, location.
- `backend/database/migrations`: schema dữ liệu.
- `backend/database/seeders`: dữ liệu Việt Nam, bệnh viện, donor, event, post, SOS.
- `backend/tests/Feature`: contract/API tests.

Backend hiện chưa có đăng nhập thật. Admin API dùng demo identity:

- Nếu truyền `admin_user_id` query hoặc header `X-Admin-User-Id`, backend dùng user đó.
- Nếu không truyền, backend tự chọn `system_admin` đầu tiên trong seed.

### Admin Vue 3 + Tailwind CSS

Thư mục chính:

- `admin/src/App.vue`: shell layout, sidebar, header, tab navigation.
- `admin/src/composables/useEmergencyDashboard.ts`: nguồn dữ liệu duy nhất cho SOS realtime.
- `admin/src/views/Dashboard.vue`: dashboard vận hành Pulse Link.
- `admin/src/views/SosAlerts.vue`: live-tracking SOS + Leaflet map.
- `admin/src/views/DonationEvents.vue`: quản lý sự kiện hiến máu.
- `admin/src/views/CommunityPosts.vue`: quản lý bài viết cộng đồng.
- `admin/src/views/RbacManagement.vue`: nhân sự và quyền.
- `admin/src/components/SosModal.vue`: modal phát lệnh SOS.

## Tính Năng Đã Có

### Daily Mode Mobile

- Hero Pass hiển thị nhóm máu, cấp Hero, điểm/cống hiến, QR.
- Health Tracker đếm thời gian hồi phục 3 tháng trước lần hiến tiếp theo.
- Trang chủ có sự kiện hiến máu và tin cộng đồng từ Laravel.
- Tap sự kiện mở màn chi tiết sự kiện.
- Tap bài viết mở màn chi tiết bài viết.
- Đặt lịch và hủy lịch hiến máu qua API Laravel.
- Tab **Lịch đặt** hiển thị các appointment đang `booked`.
- Tab **Lịch sử** hiển thị donation histories.
- Mock mode cũng có posts/events/appointments để demo không cần backend.

### SOS Mode

- Admin phát lệnh SOS từ bệnh viện.
- Backend lọc donor tương thích nhóm máu và điều phối theo wave:
  - Level 1: bán kính 5 km.
  - Level 2: bán kính 30 km trong tỉnh.
  - Level 3: mở rộng liên tỉnh trên 50 km.
- Admin dashboard nhận alert/commitment realtime qua Laravel Reverb.
- Mobile có hold-to-confirm 3 giây cho cam kết hiến máu khẩn cấp.
- Route planner trả polyline, khoảng cách và thời gian dự kiến.
- Firebase Web config là optional; nếu thiếu, Daily Mode vẫn chạy và app sẽ tắt Firebase SOS listener.
- **Quản lý ca SOS đã hoàn thành**:
  - Giao diện Admin Vue 3 hỗ trợ Modal lịch sử ca SOS hoàn thành. Xem chi tiết từng ca hoàn thành (lồng ghép trực tiếp bên trong Modal) kèm nút "Quay lại", đảm bảo trang giám sát chính (Dashboard) hoạt động độc lập và không bị ảnh hưởng. Hỗ trợ ghi nhận hiến máu thành công ("Đã hiến") cho các cam kết cũ hoặc cam kết ở trạng thái "Ca đã đủ" (`not_needed`).
  - **Cho phép hiến vượt chỉ tiêu**: Khi ca SOS đạt chỉ tiêu (ví dụ 4/4 đơn vị máu), trạng thái ca chuyển sang `fulfilled` nhưng hệ thống không tự động hủy ngang các cam kết đang di chuyển. Những người hiến đang trên đường đi vẫn giữ nguyên trạng thái cam kết để tiếp tục hiến máu (cho phép vượt chỉ tiêu 5, 6 người). Chỉ hủy các cam kết còn lại sang `not_needed` khi Admin kết thúc ca thủ công hoặc ca hết hạn.
  - **Kiểm soát hành trình máu**: Các bước của hành trình máu chỉ có thể tăng tiến đi lên (không cho phép cập nhật lùi bước) cả ở Web và Mobile. Chỉ phát sóng broadcast cập nhật hành trình máu ở bước cuối cùng (`willComplete`) để tối ưu hiệu năng.
  - **Mobile Flutter (Banner hành trình)**: Banner hành trình máu có nút tắt ẩn "x", lưu trữ offline trạng thái ẩn theo ID hành trình và chỉ hiển thị tối đa trong vòng 3 ngày kể từ khi bắt đầu.

### Admin Daily Mode

- Dashboard đã bỏ phần quản lý kho máu tồn kho nội bộ bệnh viện.
- Dashboard hiện theo dõi số liệu Pulse Link:
  - SOS đang hoạt động.
  - Lịch hiến sắp tới.
  - Lượt đặt lịch.
  - Lượt hoàn tất.
  - Tổng ml máu đã ghi nhận từ hệ thống.
  - Donor đã thông báo/cam kết/đến nơi.
- Sự kiện hiến máu:
  - Server-side pagination.
  - Search/filter trạng thái.
  - Tạo mới.
  - Sửa sự kiện.
  - Upload ảnh từ máy qua Laravel Storage.
  - Preview ảnh và fallback nhập URL thủ công.
  - Label đầy đủ cho ngày, giờ, tỉnh/xã, vĩ độ, kinh độ, chỉ tiêu.
  - Nếu sự kiện đã có booking: khóa bệnh viện, thời gian, địa điểm, tỉnh/xã, vĩ độ, kinh độ.
  - Vẫn cho sửa tiêu đề, đơn vị tổ chức, mô tả, ảnh, mức ưu tiên, trạng thái, chỉ tiêu.
  - Không cho giảm `capacity` thấp hơn `booked_count`.
- Bài viết cộng đồng:
  - Server-side pagination.
  - Search/filter trạng thái.
  - Tạo mới.
  - Sửa bài đã viết.
  - Lưu nháp hoặc xuất bản.
  - Upload ảnh từ máy, preview, fallback URL.
  - Chọn đối tượng nhận tin: tất cả, nhóm máu, cấp Hero, tỉnh/thành.
- RBAC:
  - `system_admin`: xem toàn bộ bệnh viện, dashboard, nhân sự và cấu hình.
  - `hospital_staff`: chỉ xem dữ liệu theo `hospital_id`.
  - Permission flags hiện có:
    - `dashboard.view`
    - `sos.activate`
    - `events.manage`
    - `posts.manage`
    - `staff.manage`

## Dữ Liệu Seed

Seeder hiện tạo dữ liệu tiếng Việt có dấu, gồm:

- 34 tỉnh/thành và 3321 xã/phường/đặc khu theo dataset hành chính Việt Nam.
- Alias địa danh cũ sang tỉnh/thành hiện hành.
- Bệnh viện Việt Nam:
  - Bệnh viện Chợ Rẫy.
  - Bệnh viện Truyền máu Huyết học TP.HCM.
  - Bệnh viện Bạch Mai.
  - Bệnh viện Trung ương Huế.
  - Bệnh viện Đà Nẵng.
  - Bệnh viện Đa khoa Trung ương Cần Thơ.
- Donor giả lập người Việt, có nhóm máu, GPS, Hero level, lịch sử hiến máu.
- Sự kiện hiến máu thường quy.
- Appointment demo để Mobile có dữ liệu trong tab **Lịch đặt**.
- Bài viết cộng đồng tiếng Việt.
- SOS scenario level 1, level 2, level 3, recipients và commitments.

Tài khoản seed quan trọng:

| Email | Mật khẩu | Vai trò | Ghi chú |
| --- | --- | --- | --- |
| `system@pulselink.test` | `password` | `system_admin` | Toàn quyền toàn hệ thống |
| `admin@pulselink.test` | `password` | `hospital_staff` | Nhân viên Bệnh viện Chợ Rẫy, có đủ permissions demo |
| `dieuphoi@pulselink.test` | `password` | `hospital_staff` | Nhân viên Trung tâm Hiến máu, quyền event/post |
| `sos.bachmai@pulselink.test` | `password` | `hospital_staff` | Nhân viên Bạch Mai, quyền dashboard/SOS |

## API Contract Chính

Tất cả response chính vẫn bọc trong `{ data: ... }`. List phân trang của Admin trả thêm `links` và `meta`.

### Location API

- `GET /api/locations/provinces`
- `GET /api/locations/provinces/{code}/wards`
- `POST /api/locations/normalize`

### Mobile API

- `GET /api/mobile/me/hero-pass`
- `POST /api/mobile/me/hero-pass`
- `GET /api/mobile/me/donations`
- `POST /api/mobile/me/donations`
- `GET /api/mobile/me/appointments`
- `GET /api/mobile/donation-events`
- `GET /api/mobile/donation-events/{event}`
- `POST /api/mobile/donation-events/{event}/book`
- `POST /api/mobile/donation-events/{event}/cancel`
- `GET /api/mobile/community-posts`
- `GET /api/mobile/community-posts/{post:slug}`
- `POST /api/mobile/routes/plan`
- `POST /api/mobile/sos-alerts/{alert:public_id}/commit`
- `POST /api/mobile/sos-alerts/{alert:public_id}/location`

### Admin API

- `GET /api/admin/dashboard`
- `POST /api/admin/uploads`
- `GET /api/admin/donation-events?page=1&per_page=10&status=&q=`
- `POST /api/admin/donation-events`
- `PUT /api/admin/donation-events/{event}`
- `DELETE /api/admin/donation-events/{event}`
- `GET /api/admin/community-posts?page=1&per_page=10&status=&q=`
- `POST /api/admin/community-posts`
- `PUT /api/admin/community-posts/{post}`
- `DELETE /api/admin/community-posts/{post}`
- `GET /api/admin/staff`
- `POST /api/admin/staff`
- `PUT /api/admin/staff/{staff}`
- `DELETE /api/admin/staff/{staff}`
- `POST /api/admin/emergency-alerts`
- `GET /api/admin/emergency-alerts/{alert:public_id}`
- `POST /api/admin/emergency-alerts/{alert:public_id}/cancel`

Upload ảnh:

- Endpoint: `POST /api/admin/uploads`
- Content-Type: `multipart/form-data`
- Field: `file`
- Allowed: `jpg`, `jpeg`, `png`, `webp`
- Max size: `5MB`
- Response: `{ data: { url, path } }`

## Chạy nhanh full local stack

Sau khi đã cài dependency cho `backend`, `admin` và Flutter, có thể chạy toàn bộ local bằng một lệnh:

```powershell
cd backend
composer run dev
```

Lệnh này chạy cùng lúc:

- Laravel API: `http://127.0.0.1:8000`
- Laravel Reverb: `ws://127.0.0.1:8080`
- Admin Vue: `http://127.0.0.1:5173`
- Mobile Flutter Web với Laravel thật

Các biến thể hữu ích:

```powershell
cd backend
composer run dev:backend   # chỉ chạy API + Reverb
composer run dev:no-mobile # chạy API + Reverb + Admin, không mở Flutter
```

Nếu muốn gọi trực tiếp script root:

```powershell
.\scripts\dev.ps1
.\scripts\dev.ps1 -NoMobile
.\scripts\dev.ps1 -ApiBaseUrl http://127.0.0.1:8000 -FlutterDevice chrome
```

## Chạy Backend Laravel

Yêu cầu:

- PHP `>= 8.2`
- Composer
- SQLite hoặc MySQL/MariaDB

Chạy nhanh với SQLite:

```powershell
cd backend
Copy-Item .env.example .env
composer install
php artisan key:generate
New-Item -ItemType File -Force database/database.sqlite
php artisan storage:link
php artisan migrate:fresh --seed
php artisan serve --host=127.0.0.1 --port=8000
```

Nếu đã có `.env`, kiểm tra các dòng chính:

```env
APP_URL=http://127.0.0.1:8000
DB_CONNECTION=sqlite
BROADCAST_CONNECTION=reverb
REVERB_APP_KEY=pulse-link-key
REVERB_HOST=127.0.0.1
REVERB_PORT=8080
REVERB_SCHEME=http
```

Nếu dùng MySQL/MariaDB, thay phần DB trong `.env`, rồi chạy:

```powershell
php artisan migrate:fresh --seed
```

Lưu ý: đã có migration `2026_07_01_000480_update_user_roles_for_hospital_staff.php` để database cũ nhận role `hospital_staff`.

## Chạy Laravel Reverb

Mở terminal riêng:

```powershell
cd backend
php artisan reverb:start --host=0.0.0.0 --port=8080
```

Reverb phục vụ realtime cho Admin dashboard. Nếu Reverb chưa chạy, Admin vẫn gọi REST API được nhưng realtime event/commitment sẽ không live.

## Chạy Admin Vue

Yêu cầu:

- Node.js
- npm

```powershell
cd admin
Copy-Item .env.example .env
npm install
npm run dev
```

`admin/.env` mặc định:

```env
VITE_API_BASE_URL=http://127.0.0.1:8000
VITE_REVERB_APP_KEY=pulse-link-key
VITE_REVERB_HOST=127.0.0.1
VITE_REVERB_PORT=8080
VITE_REVERB_SCHEME=http
```

Build production:

```powershell
cd admin
npm run build
```

## Chạy Mobile Flutter

Yêu cầu:

- Flutter SDK
- Chrome hoặc emulator/device

### Mock mode

Không cần backend:

```powershell
flutter pub get
flutter run -d chrome --dart-define=USE_MOCK_SERVICES=true
```

### Flutter Web với Laravel thật

Đảm bảo backend đang chạy ở `http://127.0.0.1:8000`.

```powershell
flutter pub get
flutter run -d chrome --dart-define=USE_MOCK_SERVICES=false --dart-define=LARAVEL_API_BASE_URL=http://127.0.0.1:8000
```

`MOBILE_API_TOKEN` hiện chưa bắt buộc vì backend đang dùng demo donor resolver. Nếu sau này thêm auth thật, truyền thêm:

```powershell
--dart-define=MOBILE_API_TOKEN=token-cua-ban
```

### Android Emulator với Laravel thật

Android emulator không gọi được `127.0.0.1` của máy host. Dùng `10.0.2.2`:

```powershell
flutter run -d emulator --dart-define=USE_MOCK_SERVICES=false --dart-define=LARAVEL_API_BASE_URL=http://10.0.2.2:8000
```

Nếu device id khác:

```powershell
flutter devices
flutter run -d <device-id> --dart-define=USE_MOCK_SERVICES=false --dart-define=LARAVEL_API_BASE_URL=http://10.0.2.2:8000
```

### Điện thoại thật

Lấy IP LAN của máy chạy backend, ví dụ `192.168.1.20`.

Backend:

```powershell
cd backend
php artisan serve --host=0.0.0.0 --port=8000
```

Mobile:

```powershell
flutter run -d <device-id> --dart-define=USE_MOCK_SERVICES=false --dart-define=LARAVEL_API_BASE_URL=http://192.168.1.20:8000
```

Máy tính và điện thoại cần cùng mạng Wi-Fi.

## Firebase SOS Trên Flutter Web

Firebase Web config là optional. Nếu không truyền config, app vẫn chạy Daily Mode với Laravel thật, nhưng realtime SOS listener qua Firebase sẽ tắt và console có thể hiện:

```text
Pulse Link: Firebase web config missing, disabling realtime SOS listener.
```

Đây không phải lỗi Daily Mode.

Khi cần bật Firebase Web:

```powershell
flutter run -d chrome `
  --dart-define=USE_MOCK_SERVICES=false `
  --dart-define=LARAVEL_API_BASE_URL=http://127.0.0.1:8000 `
  --dart-define=FIREBASE_WEB_API_KEY=your-api-key `
  --dart-define=FIREBASE_WEB_APP_ID=your-app-id `
  --dart-define=FIREBASE_WEB_MESSAGING_SENDER_ID=your-sender-id `
  --dart-define=FIREBASE_WEB_PROJECT_ID=your-project-id `
  --dart-define=FIREBASE_WEB_AUTH_DOMAIN=your-project.firebaseapp.com `
  --dart-define=FIREBASE_WEB_STORAGE_BUCKET=your-project.appspot.com `
  --dart-define=FIREBASE_WEB_MEASUREMENT_ID=your-measurement-id
```

## Kiểm Thử

Backend:

```powershell
cd backend
vendor\bin\pint --test
php artisan test
```

Kết quả gần nhất sau batch Admin upgrade:

```text
16 passed, 186 assertions
```

Admin:

```powershell
cd admin
npm run build
```

Kết quả gần nhất:

```text
vue-tsc -b && vite build: passed
```

Mobile:

```powershell
flutter test
```

Ghi chú: trong phiên Codex gần nhất, môi trường agent không có `flutter`/`dart` trong PATH nên chưa chạy Flutter test trực tiếp tại đó. Backend và Admin đã test/build thành công.

## Lỗi/Log Thường Gặp

### DDC logs trên Flutter Web

Các dòng kiểu sau là log debug của Flutter Web khi chạy dev:

```text
ddc_module_loader.js:1015 DDC is about to load ...
Starting application from main method ...
```

Đây thường không phải lỗi.

### Firebase web config missing

Nếu chưa cấu hình Firebase Web, dòng này là expected:

```text
Pulse Link: Firebase web config missing, disabling realtime SOS listener.
```

Daily Mode vẫn dùng Laravel bình thường.

### Ảnh upload không hiển thị

Chạy:

```powershell
cd backend
php artisan storage:link
```

Đảm bảo backend đang chạy bằng host mà Admin truy cập được, ví dụ `http://127.0.0.1:8000`.

### Android gọi backend không được

Dùng `10.0.2.2` thay cho `127.0.0.1` khi chạy emulator.

## Trạng Thái Gần Nhất

Đã hoàn tất các batch chính:

1. Import dữ liệu hành chính Việt Nam nội bộ, không phụ thuộc package Laravel cũ.
2. Đồng bộ Daily Mode full sync Backend/Admin/Mobile.
3. Mobile có bài viết, chi tiết bài viết, chi tiết sự kiện, lịch đặt.
4. Admin refactor theo UI mới từ `Admin-AI/`.
5. Admin upgrade:
   - upload ảnh từ máy,
   - sửa bài viết/sự kiện,
   - phân trang server-side,
   - label form đầy đủ,
   - RBAC `system_admin` + `hospital_staff`,
   - bỏ dashboard kho máu nội bộ.
6. Backend tests và Admin build đã pass.

Các giả định vẫn đang giữ:

- Chưa có login/auth thật.
- Demo identity dùng `admin_user_id`, `X-Admin-User-Id`, hoặc resolver mặc định.
- Mobile donor identity vẫn dùng `user_id` optional hoặc donor mặc định.
- Firebase Cloud Messaging đã có luồng thiết bị, gửi thử và gửi nền cho mobile. Local demo có thể tắt FCM, nhưng môi trường production cần service account Firebase hợp lệ.
- SOS realtime Admin/Mobile dùng Reverb độc lập; lỗi FCM không được làm gián đoạn broadcast realtime.

## Handoff Cho Agent Mới

Nếu chuyển sang agent/account mới, có thể dùng đoạn này làm prompt tóm tắt:

```text
Dự án Pulse Link nằm tại C:\Users\laoxo\Documents\Project\Pulse-Link.

Stack:
- Mobile Flutter ở root/lib.
- Backend Laravel 11 ở backend/.
- Admin Vue 3 + Tailwind ở admin/.

Trạng thái hiện tại:
- Backend có API mobile/admin/location, Reverb realtime SOS, wave-dispatch SOS, upload ảnh, staff RBAC.
- Admin đã refactor UI mới: Dashboard, SOS Alerts, Donation Events, Community Posts, RBAC.
- Daily Mode đã full sync: Mobile lấy events/posts/appointments từ Laravel.
- Dữ liệu Việt Nam đã seed: 34 tỉnh/thành, 3321 xã/phường, bệnh viện, donor, appointments, posts, SOS scenarios.
- Dashboard Admin đã bỏ quản lý kho máu tồn kho nội bộ; chỉ hiển thị số liệu Pulse Link.
- RBAC đang dùng system_admin toàn hệ thống và hospital_staff scoped theo hospital_id.
- Chưa có auth thật; demo identity qua admin_user_id hoặc X-Admin-User-Id. Nếu không truyền thì backend chọn system_admin seed đầu tiên.

Tài khoản seed:
- system@pulselink.test / password: system_admin.
- admin@pulselink.test / password: hospital_staff Chợ Rẫy, full permissions demo.
- dieuphoi@pulselink.test / password: hospital_staff quyền event/post.
- sos.bachmai@pulselink.test / password: hospital_staff quyền dashboard/SOS.

Lệnh kiểm tra đã pass gần nhất:
cd backend && vendor\bin\pint --test && php artisan test
cd admin && npm run build

Lệnh chạy local:
Backend:
cd backend
composer install
Copy-Item .env.example .env
php artisan key:generate
New-Item -ItemType File -Force database/database.sqlite
php artisan storage:link
php artisan migrate:fresh --seed
php artisan serve --host=127.0.0.1 --port=8000

Reverb:
cd backend
php artisan reverb:start --host=0.0.0.0 --port=8080

Admin:
cd admin
npm install
Copy-Item .env.example .env
npm run dev

Mobile Flutter Web với Laravel thật:
flutter pub get
flutter run -d chrome --dart-define=USE_MOCK_SERVICES=false --dart-define=LARAVEL_API_BASE_URL=http://127.0.0.1:8000

Mobile mock:
flutter run -d chrome --dart-define=USE_MOCK_SERVICES=true

Lưu ý:
- Firebase Web config optional. Nếu thiếu, warning "Firebase web config missing" là expected.
- DDC module loader logs của Flutter Web không phải lỗi.
- Android emulator phải dùng LARAVEL_API_BASE_URL=http://10.0.2.2:8000.
- Không revert các thay đổi dirty nếu không được yêu cầu; workspace đang có nhiều file đã chỉnh cho các batch trước.
```
## Handoff 2026-07-04 - SOS Fulfillment & Blood Journey

Trang thai trien khai gan nhat:

- Backend da them vong doi SOS dua tren `donated` that su, khong tinh nguoi chi moi cam ket.
- `emergency_commitments.status` co them `not_needed` de danh dau nguoi da cam ket/di chuyen nhung ca da du mau.
- Khi so commitment `donated` dat `emergency_alerts.units_needed`, backend tu chuyen alert sang `fulfilled`, broadcast realtime va tao notification mem cho nguoi chua hien:
  - "Cam on ban, ca hien mau nay da nhan du don vi mau can thiet. He thong da luu ghi nhan va xin hen ban o luot tiep theo nhe!"
- Them DB/model/resource cho:
  - `blood_journeys`
  - `blood_journey_steps`
  - `mobile_notifications`
- Khi admin xac nhan commitment `donated`, backend tao/cap nhat `DonationHistory` nhu cu va tao `BloodJourney` mac dinh.
- Them API:
  - `GET /api/blood-journeys/{publicId}`
  - `GET /api/mobile/me/notifications`
  - `POST /api/mobile/me/notifications/{notification}/read`
  - `POST /api/admin/emergency-alerts/{alert:public_id}/commitments/{commitment}/journey`
  - `GET /journeys/{publicId}` public web page cho QR/fallback.
- Certificate API payload da co them `blood_journey` neu donation history co journey.
- Mobile parse them `BloodJourney`, `MobileNotification`, `EmergencyCommitmentStatus.notNeeded`.
- Mobile home nut chuong da doi sang mo bottom sheet notification; long-press debug SOS can duoc tinh lai neu van can giu shortcut test.
- Mobile donation history card co panel "Hanh trinh giot mau" khi `PastDonation.bloodJourney != null`.
- Admin SOS da co:
  - ty le `Da hien / Can` tren card ca SOS.
  - badge `Da du mau` cho alert `fulfilled`.
  - label `not_needed` trong SOS table/timeline/map.
  - modal "Hanh trinh giot mau" cho commitment da `donated`, chon `patient`/`reserve`, step hien tai, location label va publish notification.

Da kiem tra:

- `cd backend && php artisan test --filter=DonationApiTest`: pass 7 tests.
- `cd backend && php artisan test`: pass 48 tests, 422 assertions (100% Passed).
- `cd admin && npm run build`: build thành công 100% không cảnh báo/lỗi typescript.
- `flutter analyze --no-fatal-infos --no-fatal-warnings`: phân tích mã tĩnh thành công 100% không phát sinh lỗi biên dịch.

## Handoff 2026-07-05 - Quyên góp Tài chính & Điểm tích lũy (Hero Points)

Trạng thái triển khai:

- **Laravel Backend**:
  - Tạo bảng migration lưu thông tin chiến dịch quyên góp `donation_campaigns` và lịch sử quyên góp `campaign_donations`.
  - Tạo cổng thanh toán giả lập (Mock Payment Gateway) qua `MockPaymentController` trả về giao diện xác nhận/hủy thanh toán.
  - Bắn sự kiện realtime `CampaignProgressUpdated` qua Reverb khi quyên góp thành công.
  - Xây dựng seeder mẫu `DonationCampaignSeeder` nạp sẵn 3 dự án quyên góp thực tế kèm danh sách Tri ân.
  - Bộ API đầy đủ gồm: lấy danh sách chiến dịch, chi tiết kèm BXH Top Donors, quyên góp tiền mặt, quyên góp điểm Hero, và xử lý webhook.
- **Mobile Flutter (MoMo Style)**:
  - Tích hợp thẻ banner `_DonationPromoCard` đẹp mắt trên Trang chủ di động dẫn sang phân hệ quyên góp.
  - Trang danh sách chiến dịch chia tab (Tiền mặt/Điểm Hero) với giao diện mượt mà và thanh phần trăm tiến trình.
  - Trang chi tiết chiến dịch tích hợp thanh tiến độ Glassmorphic, Bảng Vàng Tri Ân Top 10 kèm lời chúc ẩn sau.
  - Tự động gọi API polling cập nhật UI realtime và gọi browser bên ngoài thanh toán giả lập qua `url_launcher`.
- **Admin Vue 3 Dashboard**:
  - Tích hợp tab **Quản lý Quyên góp** trên sidebar admin sử dụng biểu tượng `HeartHandshake`.
  - Hiển thị thống kê tổng dòng tiền mặt VND và điểm Hero đã thu nhận toàn hệ thống.
  - Form CRUD đầy đủ cho chiến dịch và cửa sổ xem chi tiết lịch sử giao dịch quyên góp từ donors.

## Cập nhật vận hành 2026-07-11

### Thông báo mobile và realtime

- Mobile đăng ký FCM token qua `POST /api/mobile/me/notification-devices`; thiết bị có thể được gỡ đăng ký khi logout hoặc token không còn hợp lệ.
- API `POST /api/mobile/me/notifications/test` cho phép người dùng tự kiểm tra push notification sau khi cấp quyền thông báo.
- Backend lưu notification, phát event Reverb trước, rồi đưa FCM sang queue `DispatchMobilePushNotification`. Khi Firebase lỗi hoặc service account không đọc được, Reverb/SOS vẫn tiếp tục hoạt động.
- Production cần cấu hình `FIREBASE_PROJECT_ID` và `FIREBASE_SERVICE_ACCOUNT_PATH` trỏ tới JSON service account mà user chạy PHP/queue có quyền đọc. Không đưa JSON service account vào Git.
- Queue worker và scheduler phải chạy liên tục trên VPS để gửi push theo lịch chăm sóc sau hiến, SOS và các thông báo hệ thống.

### App Store, quyền riêng tư và tài khoản

- Mobile có màn **Tài khoản & quyền riêng tư**, mở được chính sách quyền riêng tư, điều khoản sử dụng, hỗ trợ và hướng dẫn xóa tài khoản.
- Laravel cung cấp các URL public không yêu cầu đăng nhập: `/legal/privacy`, `/legal/terms`, `/legal/delete-account` và `/support`.
- `DELETE /api/mobile/me/account` xóa dữ liệu cá nhân/tokens/thiết bị liên quan và ẩn danh các bản ghi cần giữ để thống kê hoặc đối soát.
- Bản iOS hiện dùng bundle identifier `com.pulselinkvn.app`. Cần dùng đúng `GoogleService-Info.plist` của Firebase app có bundle identifier này; Android vẫn dùng `asia.pulselink.app`.

### Thư tri ân và hành trình giọt máu

- Thư cảm ơn ngay sau khi hiến được gửi từ Pulse Link; khi hành trình SOS hoàn tất, thư chuyển thành lời cảm ơn từ người nhà bệnh nhân hoặc bệnh viện tùy kịch bản truyền máu/dự trữ.
- Nội dung và giao diện thư được chọn từ nhiều mẫu có sẵn trong hệ thống, không phụ thuộc lời gọi AI bên ngoài. Thư đã đọc vẫn có thể mở lại từ Sổ hiến.
- Người hiến có thể lưu thiệp thành ảnh và chia sẻ qua ứng dụng có sẵn trên thiết bị.

### Quyên góp mô phỏng

- Luồng quyên góp tiền mặt là **cổng thanh toán mô phỏng**, không thu hoặc chuyển tiền thật. Backend điều khiển bằng `CASH_DONATION_ENABLED`; điểm Hero vẫn là một luồng riêng.
- Bản test Android/iOS có thể bật giao diện mô phỏng. Khi đóng trang chi tiết chiến dịch, card ở Trang chủ và danh sách chiến dịch tự tải lại tiến độ; chiến dịch mới `0%` hiển thị thanh trống ổn định, không dùng animation loading.
- Nếu phát hành public trên App Store trước khi có mô hình quyên góp hợp lệ, build iOS có thể tắt tab tiền mặt bằng `--dart-define=APP_STORE_CASH_DONATION_ENABLED=false`.

### Lệnh build APK production

```powershell
flutter build apk --release `
  --dart-define=USE_MOCK_SERVICES=false `
  --dart-define=LARAVEL_API_BASE_URL=https://api.pulselink.asia `
  --dart-define=FIREBASE_PUSH_ENABLED=true
```

<x-legal.layout
    title="Chính sách quyền riêng tư"
    summary="Chính sách này mô tả dữ liệu Pulse Link thu thập, mục đích sử dụng, bên thứ ba liên quan và cách người dùng yêu cầu xóa dữ liệu."
>
    <p class="legal-callout">Bạn có thể quản lý hồ sơ, từ chối quyền vị trí hoặc xóa tài khoản ngay trong ứng dụng. Pulse Link không bán dữ liệu cá nhân.</p>
    <section>
        <h2>Dữ liệu chúng tôi thu thập</h2>
        <ul>
            <li>Thông tin tài khoản: họ tên, email, số điện thoại, mật khẩu đã băm.</li>
            <li>Hồ sơ người hiến: nhóm máu, lịch sử hiến máu, điểm Hero, cấp bậc, ngày sinh, giới tính, địa chỉ, tỉnh/phường.</li>
            <li>Dữ liệu xác minh: số CCCD và ảnh hai mặt CCCD khi người dùng chủ động gửi để xác minh.</li>
            <li>Vị trí: tọa độ gần đúng/chính xác khi người dùng cho phép để gợi ý sự kiện và điều phối SOS.</li>
            <li>Thông báo và thiết bị: FCM/device token, trạng thái đã đọc thông báo.</li>
            <li>Nội dung người dùng: tin nhắn chat chăm sóc, lời nhắn quyên góp, tương tác cộng đồng nếu có.</li>
            <li>Dữ liệu kỹ thuật: log lỗi, trạng thái API, thông tin giao dịch demo nếu tính năng quyên góp được bật.</li>
        </ul>
    </section>

    <section>
        <h2>Mục đích sử dụng</h2>
        <p>Dữ liệu được dùng để tạo tài khoản, điều phối hiến máu, ghép SOS, xác minh hồ sơ, gửi thông báo, chăm sóc sau hiến, cấp chứng nhận, thống kê tác động cộng đồng và cải thiện độ ổn định hệ thống.</p>
    </section>

    <section>
        <h2>Bên thứ ba</h2>
        <p>Pulse Link có thể sử dụng dịch vụ hosting backend, Firebase Cloud Messaging, nhà cung cấp bản đồ/tuyến đường, nhà cung cấp AI cho trợ lý sức khỏe và nhà cung cấp thanh toán nếu tính năng quyên góp tiền được bật. Các bên này chỉ được nhận dữ liệu cần thiết cho chức năng tương ứng.</p>
    </section>

    <section>
        <h2>Lưu trữ và xóa dữ liệu</h2>
        <p>Người dùng có thể xóa tài khoản trong app tại Hồ sơ -> Tài khoản & quyền riêng tư -> Xóa tài khoản. Khi xóa, Pulse Link xóa tài khoản, token, FCM, thông báo, chat, vị trí và dữ liệu định danh/CCCD. Một số bản ghi cần đối soát y tế, SOS, lịch sử hiến hoặc thống kê chiến dịch được giữ ở dạng ẩn danh, không còn liên kết trực tiếp với tài khoản.</p>
    </section>

    <section>
        <h2>Liên hệ</h2>
        <p>Nếu cần rút đồng ý, sửa hồ sơ, yêu cầu xóa dữ liệu hoặc hỏi về quyền riêng tư, vui lòng liên hệ qua trang <a href="{{ route('support') }}">Hỗ trợ</a>.</p>
    </section>
</x-legal.layout>

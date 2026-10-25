# Website quảng bá sản phẩm WordPress

## Bắt đầu trên Windows
1. Cài Docker Desktop, bật WSL 2 và chế độ Linux containers. Dành khoảng 4 GB RAM trở lên cho Docker.
2. Giải nén cả thư mục vào `D:\WordPress_Docker`. Mở VS Code > File > Open Folder > chọn thư mục đó (hoặc mở WordPress_Docker.code-workspace).
3. Bấm CHAY_HE_THONG.bat. Lần đầu tải image và khởi tạo DB có thể mất vài phút. Không chạy chung bộ Compose WordPress cũ nếu đang chiếm cổng 8080/8081/9090/3000; dừng bộ cũ trước, không xóa volume.
4. Mở http://localhost:8080 để chọn tiếng Việt, đặt tên website và tự tạo tài khoản quản trị WordPress. Tài khoản WordPress do bạn tạo, không phải tài khoản DB.
5. phpMyAdmin: http://localhost:8081 — user `wpuser`, password lấy từ MYSQL_PASSWORD trong .env, database `wpdb`.
6. Grafana: http://localhost:3000 — user `admin`, password lấy từ GRAFANA_PASSWORD trong .env. Dashboard đã được cấp sẵn trong Dashboards > WordPress Lab.
7. Prometheus: http://localhost:9090/targets — chờ các target UP; mở website vài lần và chờ 1–2 phút để có biểu đồ tốc độ.

Bộ này tạo dữ liệu mới riêng với project name wordpress-lab, KHÔNG nhập dữ liệu WordPress cũ. Muốn dùng dữ liệu cũ cần backup/import đúng trước.

## Hoàn thiện nội dung website
Vào /wp-admin, chọn giao diện trong Giao diện > Thêm mới. Tạo các trang Trang chủ, Sản phẩm, Giới thiệu, Liên hệ. Thêm ít nhất 3 sản phẩm mẫu với tên, ảnh, mô tả và giá. Trong Cài đặt > Đọc, chọn trang chủ tĩnh. Đây là WordPress nền tảng, chưa có nội dung sản phẩm của bạn.

## Kiến trúc
Trình duyệt → localhost:8080 → Nginx → WordPress → MySQL.
phpMyAdmin kết nối MySQL. Prometheus lấy số liệu cAdvisor, Nginx exporter, MySQL exporter. Grafana hiển thị Prometheus và Loki. Promtail đọc access/error log Nginx trên volume dùng chung rồi đẩy vào Loki. Loki không mở cổng ra máy host.

## Truy vấn log
Truy cập website và http://localhost:8080/trang-khong-ton-tai để sinh log. Grafana > Explore > chọn Loki, thời gian Last 15 minutes, chạy từng truy vấn:
```logql
{job="nginx"}
```
```logql
{job="nginx"} |= "GET"
```
```logql
{job="nginx"} |~ " 404 | 500 | 502 "
```
Chỉ có log lỗi nếu thực tế có yêu cầu lỗi. Thu thập hiện tại tập trung access/error log Nginx; log dịch vụ khác xem bằng docker compose logs.

## Kiểm tra và minh chứng
```powershell
docker compose ps -a
docker compose logs --tail=80 mysql wordpress nginx
docker compose logs --tail=80 prometheus mysql-exporter cadvisor
docker compose logs --tail=80 loki promtail
curl.exe -I http://localhost:8080
```
Chụp: website; phpMyAdmin có bảng wp_; security headers X-Frame-Options/X-Content-Type-Options; targets UP; dashboard có dữ liệu container/web/DB; 3 query Loki; cấu hình bảo mật; lịch sử GitHub.

cAdvisor cần quyền privileged và mount hệ thống để đọc metric. Trên Docker Desktop, số liệu phản ánh máy ảo Linux của Docker; một số thống kê có thể không có tùy backend. Nếu cAdvisor lỗi /dev/kmsg, kiểm tra log và cấu hình WSL2; không coi dashboard rỗng là đã đạt.

## Bảo mật đã cấu hình
- Network database internal, MySQL không publish cổng host.
- Các giao diện chỉ bind 127.0.0.1.
- Mật khẩu ngẫu nhiên mỗi bộ cài, .env và runtime bị loại khỏi Git.
- Nginx chạy user không phải root; MySQL user 999; các image giám sát dùng user mặc định của image.
- Security headers Nginx, ẩn phiên bản; nhiều dịch vụ drop ALL capabilities; no-new-privileges.
- WordPress dùng user DB riêng chỉ trên wpdb; exporter có quyền giám sát riêng (SELECT toàn cục cần cho exporter, không dùng cho website).
Ngoại lệ: Apache/PHP WordPress và phpMyAdmin cần entrypoint mặc định; cAdvisor có privileged; Promtail chạy root nhưng drop capabilities để đọc log. Không tuyên bố toàn bộ container đều non-root.

Promtail đã hết hỗ trợ từ 02/03/2026. Bản thực hành vẫn dùng Promtail đúng đề; triển khai thực tế cần chuyển sang Grafana Alloy và rà soát cập nhật image. Các phiên bản được cố định cho cấu hình bài thực hành, không phải cam kết bản vá bảo mật mới nhất. Không mở bộ này trực tiếp ra Internet.

## GitHub — thực hiện thật theo từng giai đoạn
Tạo tài khoản theo mã SV nếu giảng viên yêu cầu, tạo repo rồi dùng terminal VS Code:
```powershell
git init
git branch -M main
git add .gitignore README.md WordPress_Docker.code-workspace *.bat KHOI_TAO.ps1 docker-compose.yml nginx
git commit -m "Trien khai WordPress MySQL phpMyAdmin va Nginx"
git add prometheus grafana
git commit -m "Them Prometheus va Grafana giam sat"
git add loki promtail
git commit -m "Them Loki Promtail va truy van log"
git remote add origin https://github.com/TAI_KHOAN/TEN_REPO.git
git push -u origin main
```
Lưu ý Compose hoàn chỉnh tham chiếu tất cả thành phần ngay từ commit đầu. Nếu cần mỗi commit đều tự chạy độc lập, hãy tách thay đổi Compose theo đúng giai đoạn trước khi commit. Chưa có repo hay commit nào được tạo hoặc đẩy thay bạn. Kiểm tra git status trước khi push, không push .env/runtime.

## Dừng và chạy lại
DUNG_HE_THONG.bat giữ dữ liệu. Chạy lại CHAY_HE_THONG.bat để bật, giữ nguyên mật khẩu. Không xóa .env/runtime sau khi MySQL đã khởi tạo vì sẽ làm lệch mật khẩu với dữ liệu cũ. Không dùng docker compose down -v nếu cần giữ dữ liệu.

## Báo cáo tối thiểu 10 trang
1. Bìa: thông tin sinh viên, mã SV, lớp, đề tài.
2. Mục tiêu và yêu cầu.
3. Công nghệ, môi trường.
4. Kiến trúc, network, volume.
5. WordPress/MySQL/phpMyAdmin và nội dung sản phẩm.
6. Nginx reverse proxy, headers.
7. Prometheus/exporters, targets.
8. Grafana dashboard.
9. Loki/Promtail và 3 query LogQL.
10. Hardening, kiểm thử, ảnh minh chứng, kết luận và tài liệu tham khảo.
Đây là đề cương, chưa phải báo cáo hoàn chỉnh.

## Tình trạng kiểm tra gói
Đã kiểm tra cú pháp YAML, JSON, liên kết file và cấu trúc ZIP. Môi trường tạo gói không có Docker nên CHƯA chạy container thực tế. Cần xác nhận trên Docker Desktop của bạn.

#!/bin/bash

# Update hệ thống
sudo dnf update -y

# Cài đặt EPEL repository nếu chưa có
sudo dnf install -y epel-release

# Cài đặt ClamAV và các gói liên quan
sudo dnf install -y clamav clamav-update clamav-filesystem clamav-lib clamav-data

# Cấu hình ghi log cho ClamAV
echo "Cấu hình ghi log cho ClamAV..."

# Cấu hình file /etc/clamd.d/scan.conf
sudo sed -i 's/^Example/#Example/' /etc/clamd.d/scan.conf
sudo sed -i 's/^#LocalSocket/LocalSocket/' /etc/clamd.d/scan.conf
echo "LogFile /var/log/clamd.log" | sudo tee -a /etc/clamd.d/scan.conf
echo "LogFileMaxSize 10M" | sudo tee -a /etc/clamd.d/scan.conf
echo "LogTime yes" | sudo tee -a /etc/clamd.d/scan.conf
echo "LogSyslog yes" | sudo tee -a /etc/clamd.d/scan.conf
echo "LogFacility LOG_LOCAL0" | sudo tee -a /etc/clamd.d/scan.conf

# Cấu hình file /etc/freshclam.conf
sudo sed -i 's/^Example/#Example/' /etc/freshclam.conf
echo "LogFile /var/log/freshclam.log" | sudo tee -a /etc/freshclam.conf
echo "LogFileMaxSize 2M" | sudo tee -a /etc/freshclam.conf
echo "LogTime yes" | sudo tee -a /etc/freshclam.conf

# Cập nhật cơ sở dữ liệu virus
sudo freshclam

# Khởi động lại dịch vụ ClamAV và Freshclam
sudo systemctl restart clamd
sudo systemctl restart freshclam

# Cấu hình dịch vụ clamd như systemd service
sudo tee /etc/systemd/system/clamd.service <<EOF
[Unit]
Description=Clam AntiVirus userspace daemon
Documentation=man:clamd(8) man:clamd.conf(5) https://www.clamav.net/documents/
After=network.target

[Service]
ExecStart=/usr/sbin/clamd --foreground=true
Restart=on-failure
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd và kích hoạt dịch vụ
sudo systemctl daemon-reload
sudo systemctl enable --now clamd

# Kiểm tra trạng thái dịch vụ
sudo systemctl status clamd

# Quét thử thư mục /home và lưu kết quả log vào file
echo "ClamAV đã được cài đặt và cấu hình xong. Đang thực hiện scan thử thư mục /home..."
sudo clamscan -r /home --log=/var/log/clamscan.log

echo "Cài đặt hoàn tất."

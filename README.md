<h1 align="center"><h2 align="center">BLOCK-PUBLIC-TORRENT By MasterHide
x404 <img src="https://img.shields.io/badge/Version-2.0.5-blue.svg"></h2>
        <h3 align="center"><img src="https://img.shields.io/static/v1?style=for-the-badge&logo=ubuntu&label=Ubuntu%2018&message=20.04 LTS&color=blue"> <img src="https://img.shields.io/static/v1?style=for-the-badge&logo=ubuntu&label=Ubuntu%2020&message=22.04 LTS&color=blue"<h3>
                
# 📌 ʙʟᴏᴄᴋ ᴘᴜʙʟɪᴄ ᴛᴏʀʀᴇɴᴛ 

##### **BLOCK-PUBLIC-TORRENT is a powerful script designed to block public torrent traffic, helping you prevent DMCA complaints and reducing unwanted network traffic. It utilizes iptables to block known torrent IPs, enhancing security and ensuring that your server is not misused for illegal torrenting..**
![photo_2025-01-16_11-44-15](https://github.com/user-attachments/assets/fd58a309-5896-45b8-83ab-1f9c7854c30d)


### 📌 Install & Upgrade (ANY)
```
sudo wget https://github.com/MasterHide/block-publictorrent-iptables/raw/main/bt.sh && sudo chmod +x bt.sh && sudo bash bt.sh
```

### 📌 Remove Script (X-UI)
```
wget -q -O uninstall_all.sh https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/uninstall_all.sh && chmod +x uninstall_all.sh && sudo ./uninstall_all.sh && rm -f uninstall_all.sh bt.sh hostsTrackers cleanup_hosts.sh.save /home/ubuntu/bmenu.sh
```

### 📌 /etc/hosts Cleanup (For hiddify Users / 3X-Ui also working)
```
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/cleanup_hosts.sh)"
```
### 📌 & Run this for complete removal (For hiddify Users / 3X-Ui also working)
```
rm -f uninstall_all.sh && rm -f bt.sh && rm -f hostsTrackers && rm -f cleanup_hosts.sh.save && rm -f bmenu.sh
```

<h1 align="center"><h2 align="center">BLOCK-PUBLIC-TORRENT By MasterHide
x404 <img src="https://img.shields.io/badge/Version-2.0.5-blue.svg"></h2>
        <h3 align="center"><img src="https://img.shields.io/static/v1?style=for-the-badge&logo=ubuntu&label=Ubuntu%2018&message=20.04 PLUS&color=blue">
                
# 📌 ʙʟᴏᴄᴋ ᴘᴜʙʟɪᴄ ᴛᴏʀʀᴇɴᴛ 

##### **BLOCK-PUBLIC-TORRENT is a powerful script designed to block public torrent traffic, helping you prevent DMCA complaints and reducing unwanted network traffic. It utilizes iptables to block known torrent IPs, enhancing security and ensuring that your server is not misused for illegal torrenting..**
![Screenshot (1376)](https://github.com/user-attachments/assets/0beaebbd-1945-4569-b939-59d475196221)





### 📌 Install & Upgrade (ANY)
```
sudo wget https://github.com/MasterHide/block-publictorrent-iptables/raw/main/bt.sh && sudo chmod +x bt.sh && sudo bash bt.sh
```

### 📌 Remove Script (X-UI)
```
wget -q -O uninstall_all.sh https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/uninstall_all.sh && chmod +x uninstall_all.sh && sudo ./uninstall_all.sh && rm -f uninstall_all.sh bt.sh hostsTrackers cleanup_hosts.sh.save /home/ubuntu/bmenu.sh
```

### 📌 /etc/hosts Cleanup (For hiddify Users)
```
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/cleanup_hosts.sh)"
```
### 📌 & Run this for complete removal (For hiddify Users)
```
rm -f uninstall_all.sh && rm -f bt.sh && rm -f hostsTrackers && rm -f cleanup_hosts.sh.save && rm -f bmenu.sh
```

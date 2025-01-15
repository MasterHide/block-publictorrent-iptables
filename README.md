<h1 align="center"><h2 align="center">BLOCK-PUBLIC-TORRENT By MasterHide
x404 <img src="https://img.shields.io/badge/Version-1.0-blue.svg"></h2>
        <h3 align="center"><img src="https://img.shields.io/static/v1?style=for-the-badge&logo=ubuntu&label=Ubuntu%2018&message=20.04 LTS&color=blue"> <img src="https://img.shields.io/static/v1?style=for-the-badge&logo=ubuntu&label=Ubuntu%2020&message=22.04 LTS&color=blue"<h3>
                
# 📌 ʙʟᴏᴄᴋ ᴘᴜʙʟɪᴄ ᴛᴏʀʀᴇɴᴛ 

##### **Maintain the tracker's blacklists. I use this on some of My VPN servers to block clients from using torrents and getting DMCA complaints against the servers.**


### 📌 Install & Upgrade (ANY)
```
sudo wget https://github.com/MasterHide/block-publictorrent-iptables/raw/main/bt.sh && sudo chmod +x bt.sh && sudo bash bt.sh
```

### 📌 Remove Script (X-UI)
```
wget -q -O uninstall_all.sh https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/uninstall_all.sh && chmod +x uninstall_all.sh && sudo ./uninstall_all.sh && rm -f uninstall_all.sh && rm -f bt.sh && rm -f hostsTrackers && rm -f cleanup_hosts.sh.save
```

### 📌 /etc/hosts Cleanup (For hiddify Users / 3X-Ui also working)
```
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/MasterHide/block-publictorrent-iptables/main/cleanup_hosts.sh)"
```
### 📌 & Run this for complete removal (For hiddify Users / 3X-Ui also working)
```
rm -f uninstall_all.sh && rm -f bt.sh && rm -f hostsTrackers && rm -f cleanup_hosts.sh.save && sudo reboot
```

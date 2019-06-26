#!/bin/bash
# zabbix inf
token='534834893:AAHrIlaxNEWti1E9vXgtANwigIjsuvpzgzc'
chat='-277889075'
subj='subj'
message='message3'
text=${subj}\n${message}

# socks5 proxy settings
socks5_user='crypt_user'
socks5_pass='vOhYtkOv'
socks5_host='165.22.30.75'
socks5_port='1080'

#echo -e ${text}
curl --socks5 ${socks5_user}:${socks5_pass}@${socks5_host}:${socks5_port}-s -X POST https://api.telegram.org/bot${token}/sendMessage -F chat_id=${chat} -F text=${text}

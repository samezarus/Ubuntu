#!/bin/bash
# zabbix inf
# UTM
token='000000000000000000000000000000'
chat='1111111'

subj='subject'
message='message'

# socks5 proxy settings
socks5_user='asd'
socks5_pass='123'
socks5_host='127.0,0.1'
socks5_port='1080'
socks5_params=${socks5_user}:${socks5_pass}@${socks5_host}:${socks5_port}

curl --socks5 ${socks5_params} -s -X POST https://api.telegram.org/bot${token}/sendMessage -F chat_id=${chat} -F text=${subj}$'\n'${message}

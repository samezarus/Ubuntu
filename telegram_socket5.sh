#!/bin/bash
# zabbix inf

clear

adrr="$1" # token=chat exmp: 534834893:AAHrIlaxNEWti1E9vXgtANwigIjsuvpzgzc=-277889075
subj="$2"
message="$3"

token=''
chat=''

fl=0
for((i=0; $i<${#adrr}; i++)) 
do 
	if [ ${adrr:$i:1} = "=" ] 
	then
		fl+=1
	fi
	
	if [[ "$fl" -eq 0 ]]
	then
		token+=${adrr:$i:1}
	else
		chat+=${adrr:$i+1:1}
	fi
done

# UTM
#token='534834893:AAHrIlaxNEWti1E9vXgtANwigIjsuvpzgzc'
#chat='-277889075'

#subj='subject'
#message='message'

# socks5 proxy settings
socks5_user='asd'
socks5_pass='123'
socks5_host='127.0.0.1'
socks5_port='1080'
socks5_params=${socks5_user}:${socks5_pass}@${socks5_host}:${socks5_port}

curl --socks5 ${socks5_params} -s -X POST https://api.telegram.org/bot${token}/sendMessage -F chat_id=${chat} -F text=${subj}$'\n'${message}

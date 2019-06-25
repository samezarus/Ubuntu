#!/bin/bash
token='534834893:AAHrIlaxNEWti1E9vXgtANwigIjsuvpzgzc'
chat='-277889075'
subj='subj'
message='message3'
text=${subj}\n${message}

#echo -e ${text}
curl --socks5 crypt_user:vOhYtkOv@165.22.30.75:1080 -s -X POST https://api.telegram.org/bot${token}/sendMessage -F chat_id=${chat} -F text=${text}

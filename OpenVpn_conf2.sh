# НЕДОДЕЛАН !!!

# По мотивам статьи
# https://www.digitalocean.com/community/tutorials/openvpn-ubuntu-16-04-ru#%D1%88%D0%B0%D0%B3-5-%D1%81%D0%BE%D0%B7%D0%B4%D0%B0%D0%BD%D0%B8%D0%B5-%D1%81%D0%B5%D1%80%D1%82%D0%B8%D1%84%D0%B8%D0%BA%D0%B0%D1%82%D0%B0,-%D0%BA%D0%BB%D1%8E%D1%87%D0%B0-%D0%B8-%D1%84%D0%B0%D0%B9%D0%BB%D0%BE%D0%B2-%D1%88%D0%B8%D1%84%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8F-%D0%B4%D0%BB%D1%8F-%D1%81%D0%B5%D1%80%D0%B2%D0%B5%D1%80%D0%B0 
#
# СКРИПТ ДОЛЖЕН ЗАПУСКАТЬСЯ С ПАРАМЕТРОМ - это количество клиентских ключей
#
# Все действия под рутом
# 1. создать файл для этого скрипта nano conf.sh
# 2. Вставить данный текст
# 3. CTRL+X
# 4. Y + Enter
# 5. bash conf.sh
# 6. Клиентские конф. файлы будит лежать в папке /root/client-configs/files
#
# combine sameza - samezarus@gmail.com
# git - https://github.com/samezarus



apt update

apt install openvpn easy-rsa -y

apt install mc -y

make-cadir ~/openvpn-ca

# Количество создаваемых клиентов для сервера
clientCount=$@
if [[ "$clientCount" == "" ]]; then
	clientCount=10
fi

# Переходим в /root/openvpn-ca/
cd ~/openvpn-ca

# Меняем значение параметра KEY_NAME с EasyRSA на server
old_s='export KEY_NAME="EasyRSA"'
new_s='export KEY_NAME="server"'
sed -i -e "s/$old_s/$new_s/g" vars

# Удаляем запросы на Enter и Y
old_s='--interact'
new_s=''
sed -i -e "s/$old_s/$new_s/g" ./build-ca
sed -i -e "s/$old_s/$new_s/g" ./build-key-server
sed -i -e "s/$old_s/$new_s/g" ./build-dh
sed -i -e "s/$old_s/$new_s/g" ./build-key

# Переименовываем файл
cp openssl-1.0.0.cnf openssl.cnf # !!! В последующих версиях openssl-1.0.0.cnf может быть более поздней версией

source vars

# Очищаем среду
./clean-all

# Создаём корневой центр сертификации
./build-ca

# Создание сертификата, ключа и файлов шифрования для сервера
./build-key-server server

# Генерируем сильные ключи протокола Диффи-Хеллмана, используемые при обмене ключами
./build-dh

# Генерируем подпись HMAC для усиления способности сервера проверять целостность TSL
openvpn --genkey --secret keys/ta.key

# Создание сертификатов и пар ключей для клиентов
#./build-key client1
for (( i=1; i<=$clientCount; i++ )) do
	#echo "number is $i"
	./build-key client$i
	echo "client$i - key create !"
done

# Переходим в папку /root/openvpn-ca/keys/
cd ~/openvpn-ca/keys

# Копирование файлов в директорию OpenVPN
cp ca.crt ca.key server.crt server.key ta.key dh2048.pem /etc/openvpn

# Копируем и распаковываем файл-пример конфигурации OpenVPN в конфигурационную директорию
gunzip -c /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz | sudo tee /etc/openvpn/server.conf

# Настройка конфигурационного файла сервера
var_file=/etc/openvpn/server.conf
echo ''                                         >> $var_file #
echo 'tls-auth ta.key 0'                        >> $var_file # секция HMAC 
echo 'key-direction 0'                          >> $var_file #
echo 'cipher AES-128-CBC'                       >> $var_file # секция шифрования
echo 'auth SHA256'                              >> $var_file # алгоритм HMAC
echo 'user nobody'                              >> $var_file #
echo 'group nogroup'                            >> $var_file #
echo 'push "redirect-gateway def1 bypass-dhcp"' >> $var_file # Проталкивание изменений DNS для перенаправления всего трафика через VPN
echo 'push "dhcp-option DNS 4.2.2.2"'           >> $var_file #
echo 'push "dhcp-option DNS 8.8.8.8"'           >> $var_file #

# Настройка перенаправления IP
var_file=/etc/sysctl.conf
echo 'net.ipv4.ip_forward=1' >> $var_file #

# Применение настроек к текущей сессии
sysctl -p

# Цепочка POSTROUTING в таблице nat будет скрывать весь трафик от VPN
# пишем её в начало /etc/ufw/before.rules
#   *nat
#   :POSTROUTING ACCEPT [0:0] 
#   -A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE
#   COMMIT
var_file=/etc/ufw/before.rules
var_str='*nat'
sed -i -e "1 s/^/$var_str\n/;" $var_file
var_str=':POSTROUTING ACCEPT [0:0]'
sed -i -e "2 s/^/$var_str\n/;" $var_file
var_str='-A POSTROUTING -s 10.8.0.0\/8 -o eth0 -j MASQUERADE' # !!! экранирование "/"
sed -i -e "3 s/^/$var_str\n/;" $var_file
var_str='COMMIT'
sed -i -e "4 s/^/$var_str\n/;" $var_file

# Разрешаем перенаправление пакетов по умолчанию
old_s='DEFAULT_FORWARD_POLICY="DROP"'
new_s='DEFAULT_FORWARD_POLICY="ACCEPT"'
sed -i -e "s/$old_s/$new_s/g" /etc/default/ufw

# Открытие порта OpenVPN и SSH
ufw allow 1194/udp
ufw allow OpenSSH
ufw disable
ufw --force enable

# Запускаем сервер OpenVPN
systemctl start openvpn@server

# Автоматическое включение OpenVPN при загрузке сервера
systemctl enable openvpn@server

# Каталог для создания коиентского конфиг. файла
mkdir -p ~/client-configs/files

# Копируем дефолтный клиентский конфиг
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/base.conf

# Правим /root/client-configs/base.conf
ip=$(hostname -I)
ip1=`echo $ip | awk '{ print $1 }'`
var_file=~/client-configs/base.conf
echo "remote $ip1 1194"     >> $var_file
echo "proto udp"            >> $var_file
echo "cipher AES-128-CBC"   >> $var_file
echo "auth SHA256"          >> $var_file
echo "key-direction 1"      >> $var_file
# Удаляем пути к ключам, т.к. в дальнейшем они будут вшиты в тело конф. файла
old_s='ca ca.crt'
new_s=''
sed -i -e "s/$old_s/$new_s/g" $var_file
old_s='cert client.crt'
new_s=''
sed -i -e "s/$old_s/$new_s/g" $var_file
old_s='key client.key'
new_s=''
sed -i -e "s/$old_s/$new_s/g" $var_file
old_s='tls-auth ta.key 1'
new_s=''
sed -i -e "s/$old_s/$new_s/g" $var_file
old_s='tls-auth ta.key 0' # т.к. эта инструкция может быть как с 1, так и с 0, то перестраховываемся
new_s=''
sed -i -e "s/$old_s/$new_s/g" $var_file

# Создание скрипта генерации файлов конфигурации клиентов /root/client-configs/make_config.sh
for (( i=1; i<=$clientCount; i++ )) do
	# Пересоздаём файл
	> ~/client-configs/make_config.sh

	# Формируеем тело скрипта
	var_file=~/client-configs/make_config.sh
	echo "#!/bin/bash"                            >> $var_file
	echo "KEY_DIR=~/openvpn-ca/keys"              >> $var_file
	echo "OUTPUT_DIR=~/client-configs/files"      >> $var_file
	echo "BASE_CONFIG=~/client-configs/base.conf" >> $var_file
	echo "cat \${BASE_CONFIG} \\"                 >> $var_file
	echo "<(echo -e '<ca>') \\"                   >> $var_file
	echo "\${KEY_DIR}/ca.crt \\"                  >> $var_file
	echo "<(echo -e '</ca>\n<cert>') \\"          >> $var_file
	echo "\${KEY_DIR}/\${1}.crt \\"               >> $var_file
	echo "<(echo -e '</cert>\n<key>') \\"         >> $var_file
	echo "\${KEY_DIR}/\${1}.key \\"               >> $var_file
	echo "<(echo -e '</key>\n<tls-auth>') \\"     >> $var_file
	echo "\${KEY_DIR}/ta.key \\"                  >> $var_file
	echo "<(echo -e '</tls-auth>') \\"            >> $var_file
	echo "> \${OUTPUT_DIR}/client$i.ovpn"         >> $var_file

	# Формируем очередной коиентский конф. файл
	bash ~/client-configs/make_config.sh client$i
	
	echo "client$i - config file create !"
done

# Готово
echo "Done"
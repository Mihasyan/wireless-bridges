# Первое и основное. Сбрасываем устройство в состоянии пусто абсолютно. Подтверждаем выполнение через Y.

/system reset-configuration no-defaults=yes skip-backup=yes

# Создаем бридж для наших интерфейсов. Прибиваем mac адрес. Включаем работу с vlan. Замените mac адрес на любой свой.
# Прибивать mac на всех устройствах обязательно. В противном случае при dhcp может сменится IP и како нибудь ваш мониторинг свалит в бесконечность.
# Например тут мы это сделаем используя скрипт по поиску настоящего mac адреса нашего единственного порта eth1.
# Можно так же взять макадрес из wlan1.

/interface bridge
add admin-mac= [:put [/interface ethernet get [/interface ethernet find default-name=ether1] mac-address ]] auto-mac=no name=bridge-lan protocol-mode=none vlan-filtering=yes

# ИЛИ

/interface bridge
add admin-mac= [:put [/interface wireless get [/interface wireless find default-name=wlan1] mac-address ]] auto-mac=no name=bridge-lan protocol-mode=none vlan-filtering=yes

# Добавим интерфейсы в бридж

/interface bridge port
add bridge=bridge-lan interface= [:put [/interface ethernet get [/interface ethernet find default-name=ether1] name]]
add bridge=bridge-lan interface= [:put [/interface wireless get [/interface wireless find default-name=wlan1] name]]

# Создаем те vlan интерфесы куда хотим подключить интерфесы SXT. Для примера я взял vlan2.

/interface vlan
add interface=bridge-lan name=vlan2 vlan-id=2

# Настраиваем работу vlan на конкретном bridge какие куда откуда, тэгом или не тэгом. Можно заметить, тут не только vlan2.

/interface bridge vlan
add bridge=bridge-lan tagged=bridge-lan,wlan1,ether1 vlan-ids=2
add bridge=bridge-lan tagged=bridge-lan,wlan1,ether1 vlan-ids=3
add bridge=bridge-lan tagged=bridge-lan,wlan1,ether1 vlan-ids=4
add bridge=bridge-lan tagged=bridge-lan,wlan1,ether1 vlan-ids=5
add bridge=bridge-lan tagged=bridge-lan,wlan1,ether1 vlan-ids=6
add bridge=bridge-lan tagged=bridge-lan,wlan1,ether1 vlan-ids=7

# Назначем DHCP Client на необходимы нам интерфейс. С которого хотим осущетсвлять менеджмент.
# Можно указать дополнительные параметры хотим ли мы получить DNS и NTP этой сети или быть может на этом устройстве мы укажем свои.
# Так же есть возможность создать маршрут динамически и указать его приоритет.

/ip dhcp-client
add disabled=no interface=bridge-lan

# Или так

/ip dhcp-client
add add-default-route=no disabled=no interface=vlan2 use-peer-dns=no use-peer-ntp=no

# Добавляем те интерфейс листы с которыми мы собираемся выстраивать менеджмент. Для примера.

/interface list
add name=WAN
add name=LAN
add name=MANAGEMENT
add name=PUBLIC
add name=VPN

# Добавляем интерфейсы в необходимые нам списки интерфейсов.

/interface list member
add interface=bridge-lan list=LAN

# Создаем профиль безопасности для wlan1 интерфейса на дефолтном, что не советую делать.

/interface wireless security-profiles
set [ find default=yes ] authentication-types=wpa2-psk mode=dynamic-keys wpa2-pre-shared-key=PASSWORD

# Или создаем отдельный профиль, так куда более правильно.

/interface wireless security-profiles
add authentication-types=wpa2-psk mode=dynamic-keys name=security-profile wpa2-pre-shared-key=PASSWORD

# Кофигурируем имеющийся wlan1 интерфейс. Из имеющихся на SXT 5nD бэндов максимально выбираем a/n, 802.11ac отсутствует. Страна я выбрал russia4.
# Самое важное грамотно выбирать частоту и ширину вашего канала, а так же то как и в какую сторону он будет расширяться.
# Можно воспользоваться утилитой. Покажет список поддерживаемых и разрешенных каналов.

/interface wireless info allowed-channels wlan1

/interface wireless info country-info russia4

# Для 5ГГц я взял начальный 36 канал 5180Гц, при ширине в 40 и расширении Ce это будет 38 канал, который займет 40 канал 5200Гц.
# Обязательно включим полезную функцию WMM support. Задаем любое имя сети которое может понравится. SSID так же можно сделать скрытым.

/interface wireless
set [ find default-name=wlan1 ] band=5ghz-a/n channel-width=20/40mhz-Ce country=russia4 disabled=no frequency=5180 mode=bridge security-profile=security-profile ssid=WIFIMOST wds-mode=dynamic wireless-protocol=802.11 wmm-support=enabled wps-mode=disabled

# Я использую 802.11, другие протоколы мне не надо.

/interface wireless nstreme
set wlan1 enable-polling=no

# Ограничиваем интерфейсы где будем светится всякими LLDP и пр. То собственно почему мы видим MikroTik в Winbox и не только.

/ip neighbor discovery-settings
set discover-interface-list=LAN
/tool mac-server
set allowed-interface-list=LAN
/tool mac-server mac-winbox
set allowed-interface-list=LAN

# Это чисто приколюшка чтобы в мобильном приложении MikroTik показывало графики красивые.

/interface detect-internet
set detect-interface-list=LAN internet-interface-list=LAN lan-interface-list=LAN

# Добавим часовой пояс

/system clock
set time-zone-name=Europe/Moscow

# Укажем hostname

/system identity
set name=ap-1-mt-sxt

# Просто включим NTP клиент для синхронизации времени.

/system ntp client
set enabled=yes

# Можно так же указать свои NTP сервера к примеру. Работает как буквами так цифрами.

/system ntp client
set enabled=yes primary-ntp=194.190.168.1 server-dns-names=0.ru.pool.ntp.org,1.ru.pool.ntp.org,2.ru.pool.ntp.org,3.ru.pool.ntp.org

# Лучше включить эту галочку, она позволит вам автоматически загрузить прошивку в RouterBOARD после обновления и перезагрузки роутера чтобы 

/system routerboard settings
set auto-upgrade=yes

# Обновляемся. Настоятельно рекомендую использовать только long-term ветку обновлений, меньше багов больше надежность.
# Команды выполняем поочередно

/system package update
set channel=long-term
check-for-updates
download
install

# Обязательно перезагружаемся два раза

/system reboot

# Активируем утилиту RoMON. Если необходимо

/tool romon
set enabled=yes id= [:put [/interface bridge get bridge-lan admin-mac]]

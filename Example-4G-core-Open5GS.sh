#!/bin/bash
## Comandos de instalación para máquina "4G-core-Open5GS"


##### IMPRESCINDIBLE: Poñer CPU da máquina virtual de tipo [host]
# Hardware > Processors > Type > host > OK


##### Permite ssh como root (cómodo pero inseguro)
echo -e "PermitRootLogin yes\n" | cat - /etc/ssh/sshd_config | sudo tee /etc/ssh/sshd_config
sudo systemctl restart sshd.service
sudo echo -e "rootroot\nrootroot" | sudo passwd root  # Fixa o contrasinal do usuario root


##### OPCIONAL: axusta unha IP estática no netplan
# ip address show
# nano /etc/netplan/00-installer-config.yaml
# Exemplo IP estática:
# https://netplan.readthedocs.io/en/stable/examples/#how-to-configure-a-static-ip-address-on-an-interface
# Exemplo IP dinámica:
# https://netplan.readthedocs.io/en/stable/examples/#how-to-enable-dhcp-on-an-interface
# Exemplo dúas interfaces de rede, unha de cada tipo:
#network:
#  ethernets:
#    ens18:
#      dhcp4: true
#    ens19:
#      addresses:
#        - 192.168.200.160/24
#      routes:
#        - to: default
#          via: 192.168.200.1
#      nameservers:
#        addresses:
#          - 8.8.8.8
#  version: 2

## Gardamos e aplicamos cambios
# netplan try
# netplan apply


##### IMPRESCINDIBLE: Coñece a IP da máquina (a que vaia contactar coa celda eNB/gNB):
ip address show




##### OPCIONAL: Permitir porto serie para acceder a terminal sen SSH cando esteamos sen conectividade
# Dentro de Proxmox vai a Hardware > Add > Serial Port > 0 > Add (require apagar e reiniciar VM)
# Se perdes conectividade na VM pero a mantés con Proxmox, podes acceder á VM co comando "qm terminal vmid", sendo "vmid" o número identificador de VM. 
echo 'GRUB_CMDLINE_LINUX="quiet console=tty0 console=ttyS0,115200"' | sudo tee /etc/default/grub
sudo update-grub
# Exemplo (desde Proxmox):
# qm terminal 501


##### INSTALACIÓN Open5GS
ping -c2 www.google.es # Comproba a conectividade a Internet
echo -e "\$nrconf{restart} = 'a';" | cat - /etc/needrestart/needrestart.conf | sudo tee /etc/needrestart/needrestart.conf  # reduce as preguntas durante as instalacións

sudo timedatectl set-timezone Europe/Madrid && date
sudo apt update && sudo apt upgrade -y
sudo apt install -y nmap wireshark   # Ferramentas diagnostico de rede
#  Should non-superusers be able to capture packets?  Yes                                   
## Instalación de xestor de base de datos
sudo apt install wget gnupg -y
wget -qO - y https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt update
wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2_amd64.deb
sudo dpkg -i libssl1.1_1.1.1f-1ubuntu2_amd64.deb
sudo apt install -y mongodb-org
mongod --version
sudo systemctl enable mongod
sudo systemctl start mongod
sudo systemctl status mongod --no-pager
## Instalación de Open5GS
# apt install software-properties-common -y # En LXC
sudo add-apt-repository -y ppa:open5gs/latest
sudo apt install -y open5gs
sudo systemctl status open5gs-* --no-pager   #ver todos os servizos de Open5GS co asterisco
## Interfaz web para a base de datos das SIM
sudo apt update && sudo apt install curl -y
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs  #npm
curl -fsSL https://open5gs.org/open5gs/assets/webui/install | sudo -E bash -
sudo systemctl status mongod --no-pager
sudo systemctl status open5gs-webui.service --no-pager
sed '10 i\Environment=HOSTNAME=0.0.0.0' /lib/systemd/system/open5gs-webui.service | sudo tee /lib/systemd/system/open5gs-webui.service
sed '11 i\Environment=PORT=3000' /lib/systemd/system/open5gs-webui.service | sudo tee /lib/systemd/system/open5gs-webui.service  # Cambiar polo porto que prefiras, por exemplo 80
sudo systemctl daemon-reload
## Configuración de rede para permitir packet forwarding (enrutamento) e NAT na subrede 4G/5G. Úsase rc.local para que se execute en cada inicio xa que non é persistente
wget -P /etc/systemd/system/ https://raw.githubusercontent.com/catinello/rc-local.service/master/rc-local.service
sudo chmod +x /etc/systemd/system/rc-local.service
touch /etc/rc.local
sudo chmod +x /etc/rc.local
echo -e '#!/bin/bash' | cat - /etc/rc.local | sudo tee /etc/rc.local
echo -e 'sudo sysctl -w net.ipv4.ip_forward=1' | sudo tee -a /etc/rc.local
echo -e 'sudo sysctl -w net.ipv6.conf.all.forwarding=1' | sudo tee -a /etc/rc.local
echo -e 'sudo iptables -I INPUT -p tcp --dport 3000 -j ACCEPT' | sudo tee -a /etc/rc.local
echo -e 'sudo iptables -t nat -A POSTROUTING -s 10.45.0.0/16 ! -o ogstun -j MASQUERADE' | sudo tee -a /etc/rc.local
echo -e 'sudo ip6tables -t nat -A POSTROUTING -s 2001:db8:cafe::/48 ! -o ogstun -j MASQUERADE' | sudo tee -a /etc/rc.local
echo -e 'sudo iptables -I INPUT -i ogstun -j ACCEPT' | sudo tee -a /etc/rc.local
sudo systemctl enable rc-local.service
sudo systemctl status rc-local.service --no-pager

##DIAGNÓSTICO
sudo tail -f /var/log/open5gs/amf.log       # 5G SA
sudo tail -f /var/log/open5gs/mme.log       # 4G e 5G NSA
sudo tail -f /var/log/open5gs/*             # Todo o core
ssh -Y root@x.y.z.w "wireshark" &           # Sniffing da interface S1 (core-eNB), usar filtro "sctp"
sudo tcpdump port 36412	                    # Sniffing S1, pero na terminal
sudo systemctl status open5gs-* --no-pager  # ver o estado de todos os servizos Open5GS
sysctl net.ipv4.ip_forward
sysctl net.ipv6.conf.all.forwarding
sudo iptables -L                            # Firewall
sudo iptables -t nat -L                     # NAT de masquerade na rede 4G/5G
mongosh open5gs --eval "db.subscribers.find().pretty()"


ls /etc/open5gs/








## Restaurar configuración predeterminada
mv /etc/open5gs/amf.yaml /etc/open5gs/amf.yaml.old && wget -O /etc/open5gs/amf.yaml https://raw.githubusercontent.com/open5gs/open5gs/main/configs/open5gs/amf.yaml.in
mv /etc/open5gs/upf.yaml /etc/open5gs/upf.yaml.old && wget -O /etc/open5gs/upf.yaml https://github.com/open5gs/open5gs/blob/main/configs/open5gs/upf.yaml.in
mv /etc/open5gs/mme.yaml /etc/open5gs/mme.yaml.old && wget -O /etc/open5gs/mme.yaml https://raw.githubusercontent.com/open5gs/open5gs/main/configs/open5gs/mme.yaml.in
mv /etc/open5gs/sgwu.yaml /etc/open5gs/sgwu.yaml.old && wget -O /etc/open5gs/sgwu.yaml https://raw.githubusercontent.com/open5gs/open5gs/main/configs/open5gs/sgwu.yaml.in


## Editar configuracións
wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq

yq eval '.mme.s1ap[0].addr' /etc/open5gs/mme.yaml
yq eval -i '.mme.s1ap[0].addr="10.0.0.158"' /etc/open5gs/mme.yaml

yq eval '.sgwu.gtpu[0].addr' /etc/open5gs/sgwu.yaml
yq eval -i '.sgwu.gtpu[0].addr = "10.0.0.158"' /etc/open5gs/sgwu.yaml


## Consultar base de datos
## Direccións loopback de todo



#!/bin/bash
set LANG C
set LC_CTYPE "iso_8859_1"

echo
echo "Script de instalación de Asterisk - executar como administrador"
echo "Adaptado de rosehosting.com e computingforgeeks.com/"
echo
echo "Cando chegue o momento \(pantalla azul\), introduce o codigo de pais, 34 para Espana"

apt update -y && apt upgrade -y
apt install -y build-essential 
apt install -y git-core subversion libjansson-dev sqlite autoconf automake libxml2-dev libncurses5-dev libtool curl figlet
#el -y responde automaticamente yes a todas las preguntas

cd /usr/src/
sudo curl -O http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-18-current.tar.gz
tar -zxvf asterisk-18-current.tar.gz
rm  asterisk-18-current.tar.gz
cd asterisk*
#como el nombre de la carpeta cambia con el número de versión, le pongo asterisco

./contrib/scripts/install_prereq install
./configure --with-jansson-bundled
make
make install
make samples
locale-gen --purge es_ES.UTF-8
make config
make install-logrotate
systemctl start asterisk
systemctl enable asterisk
systemctl status asterisk --no-pager

echo 'Se o texto anterior pon \"active \(running\)\"...'
figlet -c ...instalacion terminada
figlet -c -f banner yeah!

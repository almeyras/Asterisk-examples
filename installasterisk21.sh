#!/bin/bash
# Instalación de Asterisk 21 (PJSIP) en Ubuntu 22.04 LTS (usuario root) seguindo os pasos de <https://docs.asterisk.org/Getting-Started/Installing-Asterisk/>


# Requerimentos previos
apt update && DEBIAN_FRONTEND=noninteractive apt upgrade -y     # actualiza listaxe e paquetes vellos instalados sen pedi>
apt install -y build-essential unzip                            # Ferramentas de compilacion: gcc, make...

# Descarga Asterisk 21
cd ~
wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-21-current.tar.gz
tar -zxvf asterisk-21-current.tar.gz
cd asterisk-21.1.0/

# Prepara ficheiros, instala prerrequerimentos (SQlite 3, pjsip), compilacion e instalacion
contrib/scripts/install_prereq install
./configure --with-pjproject-bundled --with-jansson-bundled
#./configure
make && make install

# Detalles finais
make samples            # ficheiros de demostracion
make config             # script de inicializacion automatica

systemctl start asterisk.service	# inicio manual
systemctl status asterisk.service
echo "Instalacion completa. Revisa que o status apareza en verde e diga: 'active (running)'"


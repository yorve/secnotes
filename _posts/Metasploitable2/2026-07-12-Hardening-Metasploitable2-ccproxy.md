---
layout: post
title: "Metasploitable 2 - Hardening ccproxy-ftp"
date: 2026-07-12
img: /assets/img/metasploitable2/banner.png
tags: [Vuln, Linux, Hardening, ccproxy, ftp, root, Metasploitable 2 ]
---

Esta puerto está asociado a **CCProxy-FTP**, es un puerto de red alternativo utilizado para transferir archivos a través del protocolo **FTP**, Mientras que el FTP tradicional usa por defecto el puerto 21, la herramienta de software **CCProxy** utiliza el puerto 2121 de manera predeterminada para habilitar el servicio de proxy y transferencia de archivos.

El servicio Proxy permite a los usuarios de red local conectarse a través de CCProxy para acceder a servidores FTP de forma gestionada.

# Reconocimiento.

Dado a que es un servidor FTP, por definición utiliza el protocolo TPC y se comunica inicialmente en Texto Plano. Esto significa que podemos usar nuestra herramienta Netcat para interrogar al puerto y que ser que esconde detrás de él.


![](/secnotes/assets/img/metasploitable2/2121/8bd764ea71ce020f76ffe1bac9873f55_MD5.jpg)

Dado a que tenemos las credenciales `msfadmin`, podemos establecer conexión con el servidor. Desde aquí, como tenemos una conexión, podríamos subir archivos a la máquina víctima para ejecutar algún script malicioso con una reverse shell o que nos permita tener mayor control desde nuestra máquina atacante.

# Hardening

Para eliminar este vector de ataque secundario, debemos identificar qué proceso está levantando el puerto 2121 para apagarlo de raíz. Este segundo servidor ProFTPD se está ejecutando como un daemon independiente (en modo _standalone_) o está amarrado directamente a la configuración global de ProFTPD.

Vamos a detener el servicio, y romper el arranque automático para que no se levante cada vez que encienda el servidor.

`netstat -lnpt | grep 2121`

`/etc/init.d/proftpd stop`  

`update-rc.d -f proftpd remove`

Este último comando nos ayuda a eliminar el servicio del arranque automático del sistema. 

![](/secnotes/assets/img/metasploitable2/2121/c765044e564cf1a50e0ba89bc1f11b73_MD5.jpg)

![](/secnotes/assets/img/metasploitable2/2121/abce5287a8a45c3fa5ebc438d3c49b71_MD5.jpg)

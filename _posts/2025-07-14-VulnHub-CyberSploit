---
layout: post
title: "CyberSploit1 – VULNHUB - Linux - Fácil"
date: 2025-07-14
---
![banner](/secnotes/assets/img/cybersploit/banner.png)


Identificar nuestra ip y buscar la máquina objetivo en la red con netdiscover.

![img1](/secnotes/assets/img/cybersploit/1.png)
 
Con el comando `nmap -O <ip>` encontraremos la máquina objetivo.
 
![img2](/secnotes/assets/img/cybersploit/2.png)

Nos encontramos que la máquina tiene el puerto 22 y 80 abiertos, vamos a usar un script básico de enumeración de directorios que tiene integrado nmap para hacer un escaneo rápido al servicio web en el puerto 80

 ![img3](/secnotes/assets/img/cybersploit/3.png)

 Nos encontramos un documento llamado _robots.txt_, y que al acceder a él nos muestra un código.

 ![img4](/secnotes/assets/img/cybersploit/4.png)
									visión herramienta curl
 ![img5](/secnotes/assets/img/cybersploit/5.png)
									visión navegador web

Este código que nos muestra es un texto codificado. A simple vista es ilegible, sin embargo, podemos usar una página web para descifrarlo.
https://gchq.github.io/CyberChef/  

En esta página ponemos el texto encriptado en el input, y presionamos la varita del output.

![img6](/secnotes/assets/img/cybersploit/6.png)

Y con eso automáticamente descifrará el texto encriptado obteniendo la primera flag.

![img7](/secnotes/assets/img/cybersploit/7.png)

 
Al acceder al servicio web de la maquina objetivo no tendremos más información. Es por esto que una buena practica es inspeccionar la página web en búsqueda de comentarios o alguna información relevante. 

 ![img8](/secnotes/assets/img/cybersploit/8.png)

Y es aquí donde encontramos un posible usuario llamado **itsskv**
 
Como la página web no tienen ningún panel de login probaremos el puerto 22 abierto. Este puerto corresponde al servicio ssh.

 ![img9](/secnotes/assets/img/cybersploit/9.png)
 
Para conectarse al servicio debemos usar el siguiente formato.

![img10](/secnotes/assets/img/cybersploit/10.png)
 
Al intentar ingresar por el servicio ssh, este nos pide un password valido. Luego de intentos fallidos con contraseñas básicas (admin, root, etc) y al no tener más información intentamos con la flag como contraseña cybersploit{youtube.com/c/cybersploit}.
Así pudimos acceder al servicio.

![img11](/secnotes/assets/img/cybersploit/11.png)
 
Listamos los archivos y directorios del servicio y nos encontramos con la flag2.txt que al leerla vemos un código. Al igual que el paso anterior, usaremos cybershef para descifrarla.

Esta vez el texto está en binario.

![img12](/secnotes/assets/img/cybersploit/12.png)

Ya con una sesión activa en la máquina comprometida, podemos usar el comando `uname -a` para obtener información sobre el sistema operativo.

 ![img13](/secnotes/assets/img/cybersploit/13.png)
 
Ya sabemos que tenemos la versión 3.13.0 de Linux, el siguiente paso será buscar vulnerabilidades sobre esta versión.

![img14](/secnotes/assets/img/cybersploit/14.png)
 
En exploit database encontramos un exploit que nos ayudará a escalar privilegios.
Una vez descargado lo transferiremos 

![img15](/secnotes/assets/img/cybersploit/15.png)
 
Para esto abriremos un servidor web en el puerto 8080

![img16](/secnotes/assets/img/cybersploit/16.png)
 
Desde la sesión de la máquina comprometida descargaremos el exploit descargado en la máquina atacante.

![img17](/secnotes/assets/img/cybersploit/17.png)
 
Usamos gcc para compilar el **exploit.c**, y este nos dará un nuevo archivo llamado **a.out**

![img18](/secnotes/assets/img/cybersploit/18.png)

Y ejecutamos el exploit **a.out**

![img19](/secnotes/assets/img/cybersploit/19.png) 

Una vez ejecutado el script nos convertimos en usuario root. Ya solo nos queda encontrar la última flag, que normalmente se encuentra en la ruta /root

![img20](/secnotes/assets/img/cybersploit/20.png)

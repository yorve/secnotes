---
layout: post
title: "CyberSploit1 – VULNHUB - Linux - Fácil"
date: 2025-07-14
img: /assets/img/cybersploit/banner.png
---
Cybersploit es una máquina de tipo CTF diseñada para reforzar conocimientos en pentesting web, enumeración y explotación básica. Inspirada en escenarios del mundo real, esta máquina simula un entorno vulnerable donde es necesario aplicar técnicas comunes como fuzzing, análisis de código y posibles vectores de ejecución remota.

Nuestro primer paso será identificar nuestra ip y buscar la máquina objetivo en la red con la herramienta **netdiscover**.

![img1](/secnotes/assets/img/cybersploit/1.png)
 
Con la ip de la máquina objetivo identificada, realizaremos un escaneo con nmap para descubrir que puertos y servicios tiene habilitado.
 
![img2](/secnotes/assets/img/cybersploit/2.png)

Encontramos que el objetivo tiene los puertos 22 y 80 abiertos, Nmap tiene un script básico de enumeración de directorios que utilizaremos para escanear el servicio web (puerto 80)

 ![img3](/secnotes/assets/img/cybersploit/3.png)

Una vez terminado el escane0, nos encontramos un documento llamado _robots.txt_, y, que al acceder a él nos muestra un texto aparentemente codificado.

 ![img4](/secnotes/assets/img/cybersploit/4.png)
vista herramienta curl

 ![img5](/secnotes/assets/img/cybersploit/5.png)
vista navegador web

este texto a simple vista es ilegible, sin embargo, podemos usar una aplicacion web para descifrarlo.

https://gchq.github.io/CyberChef/  

En esta página ponemos el texto cifrado en el input.

![img6](/secnotes/assets/img/cybersploit/6.png)

al presionar la varita automáticamente descifrará el texto cifrado obteniendo la primera flag.

![img7](/secnotes/assets/img/cybersploit/7.png)

Al acceder por un navegador web a la máquina objetivo no tendremos más información. Una buena practica es inspeccionar la página web en búsqueda de comentarios o algun tipo de  información. 

 ![img8](/secnotes/assets/img/cybersploit/8.png)

Aquí encontramos un posible usuario llamado **itsskv**
 
Como la página web no tienen ningún panel de login probaremos ingresar por el servicio SSH (puerto 22) que nos encontramos disponible en el escaneo inicial.

 ![img9](/secnotes/assets/img/cybersploit/9.png)
 
Para conectarse al servicio debemos usar el siguiente formato.

![img10](/secnotes/assets/img/cybersploit/10.png)
 
Luego de intentos fallidos con contraseñas básicas (admin, root, etc) y al no tener más información intentamos ingresar la flag como contraseña **cybersploit{youtube.com/c/cybersploit}**.

![img11](/secnotes/assets/img/cybersploit/11.png)
 
Listamos los archivos y directorios del servicio y nos encontramos con la flag2.txt que al leerla vemos otro texto cifrado. Al igual que el paso anterior, usaremos cyberchef para descifrarla.

Esta vez el texto descubierto está en binario.

![img12](/secnotes/assets/img/cybersploit/12.png)

Con una sesión activa (SSH) en la máquina víctima, podemos usar el comando `uname -a` para obtener información sobre el sistema operativo.

 ![img13](/secnotes/assets/img/cybersploit/13.png)
 
Con esta informacion sabemos que tenemos la versión 3.13.0 de Linux, asi que nuestro siguiente paso será buscar vulnerabilidades sobre esta versión.

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

![img21](/secnotes/assets/img/cybersploit/21.png)

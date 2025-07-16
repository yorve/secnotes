---
layout: post
title: "CyberSploit2 – VULNHUB - Linux - Fácil"
date: 2025-07-16
img: /assets/img/cybersploit2/banner.png
---

Cybersploit 2 es una máquina de tipo Boot2Root diseñada para poner a prueba habilidades de enumeración, explotación y escalada de privilegios en un entorno controlado.

Nuestro primer paso será identificar la máquina objetivo en la red. Con el comando `ip a` nos mostrará nuestra ip, y desde ahí iniciaremos la búsqueda de la máquina objetivo.
Utilizaremos el comando `nmap <ip>/24` para hacer un escaneo a toda la red.

![img1](/secnotes/assets/img/cybersploit2/1.png)
 
Luego del escaneo encontramos el siguiente host.

![img2](/secnotes/assets/img/cybersploit2/2.png) 

Ya identificada la ip de la máquina objetivo, iniciaremos un reconocimiento a estos puertos y sus versiones de servicios.

 ![img3](/secnotes/assets/img/cybersploit2/3.png)

Este escaneo nos entregó información que podríamos utilizar para encontrar vulnerabilidades del sistema operativo.
Ya que tenemos el puerto 80 abierto, revisaremos el contenido del servicio web.

 ![img4](/secnotes/assets/img/cybersploit2/4.png)

La página nos muestra tres columnas con datos (username y password) y hay una en particular con caracteres extraños. Vamos a copiarlos y en la página **cyberchef** intentaremos de descifrarlos.

![img5](/secnotes/assets/img/cybersploit2/5.png)
 
Al inspeccionar la página podemos ver una pista.

![img6](/secnotes/assets/img/cybersploit2/6.png)
 
Teniendo estas credenciales, intentaremos iniciar sesión por el servicio ssh (puerto 22) con el usuario _shailendra_ y la contraseña _cybersploit1_

![img7](/secnotes/assets/img/cybersploit2/7.png)
 
Al listar los archivos encontramos con **hint.txt**, y que al leerlo nos da como pista **Docker**. Podemos suponer que esta máquina está montada sobre esta plataforma.

![img8](/secnotes/assets/img/cybersploit2/8.png)
 
Esto podemos confirmarlo con el comando `ps aux | grep dockerd`

![img9](/secnotes/assets/img/cybersploit2/9.png)
 
*este comando no es 100% infalible para detectar Docker, es un buen primer indicador.

https://gtfobins.github.io/gtfobins/docker/

Buscando en la red podemos ver que existe una forma de escalar privilegios cuando se trabaja con contenedores de Docker, para hacer esto podemos usar el comando:
 
`docker run -v /:/mnt --rm -it alpine chroot /mnt sh`

El propósito de ejecutar este comando es obtener una Shell como un usuario root dentro del contenedor, permitiendo la modificación directa de los archivos críticos del sistema. 

Ejecutamos el comando y obtenemos una sesión como root

![img10](/secnotes/assets/img/cybersploit2/10.png) 

Accedemos a la carpeta root, listamos y obtendremos la flag.

![img11](/secnotes/assets/img/cybersploit2/11.png)


 




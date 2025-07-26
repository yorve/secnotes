---
layout: post
title: "Grillo – TheHackerLabs - Linux - Fácil"
date: 2025-07-26
img: /assets/img/grillo/banner.png
![banner](/secnotes/assets/img/grillo/banner.png)
---

Esta es una máquina Linux de nivel facil, diseñada para fortalecer la enumeración de aplicación web: Exploración de contenido web visible y oculto para detectar puntos de entrada.
Enumeración de servicios: Identificación de los servicios que corren en los puertos abiertos, incluyendo versiones.
Escaneo de puertos TCP: Detección de puertos abiertos en la máquina objetivo mediante escaneo TCP.

**Reconocimiento**

Iniciamos con un escaneo para descubrir los hosts activos e identificar la máquina objetivo. 

![img1](/secnotes/assets/img/grillo/1.png)

![img2](/secnotes/assets/img/grillo/2.png)

![img3](/secnotes/assets/img/grillo/3.png)

**Enumeración**

![img4](/secnotes/assets/img/grillo/4.png)
 

Al escanear el objetivo nos encontramos con alguna información necesaria para enumerar directorios.

![img5](/secnotes/assets/img/grillo/5.png)
 
Al revisar el servicio web nos encontramos con este mensaje y un posible usuario.


**Explotación**

Con el usuario encontrado, usaremos la herramienta **hydra** para hacer un ataque de fuerza bruta con el objetivo de encontrar la contraseña del usuario _Melanie_.

![img6](/secnotes/assets/img/grillo/6.png)
  
Finalizado el ataque, nos encontramos la contraseña de _Melanie_. Con estas credenciales accedemos por servicio SSH. Al listar nos encontramos con la user flag.

![img7](/secnotes/assets/img/grillo/7.png)
 
Con el comando ´sudo -l´ podemos listar los comandos que podemos utilizar con este usuario.

![img8](/secnotes/assets/img/grillo/8.png) 

En este caso podemos ejecutar **puttygen**, la función de este es generar pares de claves publicas y privadas ssh, que son utilizadas para la autenticación en conexiones ssh seguras sin necesidad de contraseñas.

**Elevación de privilegios.**

Vamos a crear un nuevo par de claves SSH que utilizaremos para elevar nuestros privilegios. Estas claves quedarán guardadas en el directorio _/home/Melanie/.ssh_

![img9](/secnotes/assets/img/grillo/9.png)

![img10](/secnotes/assets/img/grillo/10.png)

Luego:
´sudo /usr/bin/puttygen id_rsa.pub -O public-openssh -o /root/.ssh/authorized_keys´

este comando convierte la clave publica en formato OpenSSH y lo guarda como un archivo _authorized_keys_ en el directorio .ssh del usuario root.

Este nuevo archivo autoriza el acceso sin contraseña a la cuenta root, permitiendo que cualquier cliente que tenga la clave privada correspondiente a alguna de las claves publicas listadas en ese archivo pueda conectarse directamente.

Entonces solo nos queda conectarnos como root por ssh y obtendremos el acceso.

![img11](/secnotes/assets/img/grillo/11.png)





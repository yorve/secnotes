---
layout: post
title: "Santa Logs - Hackerlabs - Windows"
date: 2026-06-12
img: /assets/img/santa/banner.png
tags: [Logs, Visor de Eventos, Windows, BlueTeam]
---

![banner]({{ site.baseurl }}/assets/img/santa/banner.png)

![img1]({{ site.baseurl }}/assets/img/santa/intro.png)

Nuevo reto de Blue Team!
Hoy nos toca ensuciarnos las manos con el Visor de Eventos de Windows resolviendo Santa Logs de The Hackers Labs.

Los logs del sistema a veces pueden parecer un laberinto indescifrable, pero en este laboratorio veremos cómo ordenarlos, qué IDs rastrear y cómo aislar el ruido para encontrar exactamente lo que buscas. Desde detectar un ataque de fuerza bruta hasta ejecutar comandos en la CMD para romper el cifrado de un script sospechoso de Python, veremos paso a paso cómo resolver este laboratorio sin morir en el intento.

![img2]({{ site.baseurl }}/assets/img/santa/preguntas1.png)
![img3]({{ site.baseurl }}/assets/img/santa/pregunta2.png)

Comenzamos. 

![img4]({{ site.baseurl }}/assets/img/santa/visordeeventos.png)
![img5]({{ site.baseurl }}/assets/img/santa/visor.png)

Una vez abierto el Visor de eventos, podemos ver que tenemos un apartado de logs con el nombre del equipo (santalogs) ahí encontraremos todos los logs relacionados con él. Trabajar en estos logs nos ayudará a no confundirnos con los logs propios del sistema.

Podemos ordenar los logs por "Origen" lo que nos permite juntar todos los datos y realizar búsquedas de forma mas fácil.

![img6]({{ site.baseurl }}/assets/img/santa/ssh.png)

Teniendo todo ordenado, solo nos queda búscar el dato concreto de inicio de sesión exitoso y responder la primera pregunta.

![img7]({{ site.baseurl }}/assets/img/santa/ssh1.png)

Del mismo modo buscaremos información sobre intentos fallidos de acceso FTP para responder la segunda pregunta.

![img8]({{ site.baseurl }}/assets/img/santa/ftpfail.png)

![img9]({{ site.baseurl }}/assets/img/santa/ftp.png)

Como podemos ver, el ID de _failed FTP login attemp for user_ es el 1002. Podemos filtrar este ID para que el visor solo nos muestre este dato.

![img10]({{ site.baseurl }}/assets/img/santa/ftpfilter.png)

![img11]({{ site.baseurl }}/assets/img/santa/ftpfilter1.png)

Para la tercera pregunta, debemos encontrar una alerta relacionada con el almacenamiento. Esta vez filtraremos por advertencia.

![img12]({{ site.baseurl }}/assets/img/santa/disk.png)

y encontramos el mensaje _Low disk space_

![img12]({{ site.baseurl }}/assets/img/santa/lowdisk.png)

Para la cuarta pregunta, debemos buscar información relacionada con un script malicioso.

![img13]({{ site.baseurl }}/assets/img/santa/script.png)

Ya tenemos la ruta donde esta alojado este escript de python. _C:\tmp_, ahora debemos buscar la clave para desencriptarlo.

![img14]({{ site.baseurl }}/assets/img/santa/key.png)

Bucando en los demás logs, la unica información que encontramos fue esta. Asi que vamos a probar esta clave. 

Ya sabemos la ruta del script y que es de Python. Para ejecutarlo vamos utilizar CMD, navegar hasta el directorio donde se encuentra el script y ejecutarlo.

![img14]({{ site.baseurl }}/assets/img/santa/cmd.png)
![img15]({{ site.baseurl }}/assets/img/santa/decript.png)

Efectivamente era la clave para desencriptar. Con eso respondemos todas las preguntas y termianr el laboratorio. 
















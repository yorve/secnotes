---
layout: post
title: "Trust - Dockerlabs - Linux - Fácil"
date: 2025-09-28
img: /assets/img/trust/banner.png
---

La máquina Trust de DockerLabs es un desafío de nivel muy fácil diseñado para practicar habilidades básicas de enumeración y elevación de privilegios. 
el objetivo es obtener acceso inicial mediante enumeración web sencilla y fuerza bruta, para luego escalar a root explotando configuraciones comunes como permisos sudo o binarios SUID. 
Ideal para principiantes, esta máquina fomenta el aprendizaje de técnicas esenciales en un entorno Debian.

**Enumeración**

Comenzamos con un escaneo activo con nmap para identificar los puertos y servicios de la máquina objetivo, seguido con la enumeración de la versión de estos servicios y si existe alguna vulnerabilidad conocida de estas versiones 

![img1](/secnotes/assets/img/trust/1.png)

![img2](/secnotes/assets/img/trust/2.png)

Al acceder al servicio web (puerto 80) este nos mostrará la página por defecto de Apache

![img3](/secnotes/assets/img/trust/3.png)

Si inspeccionamos la página no encontraremos comentarios ni nada de interés.

Seguimos con la busqueda con `searchsploit` de sploits conocidos para estas versiones.

![img4](/secnotes/assets/img/trust/4.png)

ya que no tenemos nada, continuaremos con un escaneo básico de directorios con la herramienta `dirb`sobre el servicio web.

![img5](/secnotes/assets/img/trust/5.png)

Este escaneo no nos encontró nada de información.

Ya que las pruebas de enumeración básicas no nos muestra información, harémos un escaneo más especifico al servicio web, nos centraremos en escanear este, ya que para acceder por SSH necesitamos almenos un usuario.
Utilizaremos la herramienta `gobuster` con el argumento `-x php, html, txt` para que realice una búsqueda de estas extensiones.

![img6](/secnotes/assets/img/trust/6.png)

Con este escaneo tenemos éxito, encontramos la ruta _/index.html_ y _/secret.php_

al acceder al segundo nos encontramos con lo siguiente

![img7](/secnotes/assets/img/trust/7.png)

Esta simple página nos da un dato valioso. Un posible usuario llamado *mario*, ya con este intentaremos descubrir la contraseña con la herramienta `hydra`

**Explotación**

con el comando:

`hydra -l mario -p /usr/share/wordlist/rockyou.txt 172.18.0.2 ssh -t 64 -I`

le indicaremos quye utilizaremos el diccionario _rockyou_ para descubrir la contraseña de _mario_ por el servicio _ssh_. El argumento -t 64 es para que hydra intente hasta 64 conexiones a la vez al servicio.
(esto lo realizamos solo en laboratios en favor del tiempo, ya que un escaneo con ese parametro en un entorno real lo detectarían de inmetiado)

![img8](/secnotes/assets/img/trust/8.png)

Este ataque resutó exitoso, descubriendo que la contraseña de **mario** es **chocolate**. Ahora podremos acceder porshh con estas credenciales.

![img9](/secnotes/assets/img/trust/9.png)

Ya dentro de la máquina de mario, debemos verificar si podemos ajecutar alguna herramienta como root sin necesidad de ingresar una contraseña.
Para esto utilizamos el comando `sudo -l`

![img10](/secnotes/assets/img/trust/10.png)

Este nos indica que podemos ejecutar vim con permisos elevados

**Eleveción de Privilegios**

Sabiendo esto, buscaremos en la página https://gtfobins.github.io/ , aquí buscaremos la herramienta que podemos ejecutar. Al buscar por vim, encontramos que al ejecutar un comando podemos abrir una shell como root

![img11](/secnotes/assets/img/trust/11.png)

al ejecutarla obtendremos la shell 

![img12](/secnotes/assets/img/trust/12.png)






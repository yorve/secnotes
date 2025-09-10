---
layout: post
title: "FirstHacking – TheHackerLabs - Linux - Fácil"
date: 2025-09-09
img: /assets/img/firsthacking/banner.png
---

La máquina First Hacking es un laboratorio básico de Docker Labs que sirve como punto de partida en el mundo del pentesting.
El objetivo principal es detectar y aprovechar la vulnerabilidad para conseguir acceso al sistema.
Esta práctica ayuda a entender cómo un servicio desactualizado puede convertirse en una puerta de entrada para un atacante y muestra la importancia de mantener los sistemas siempre actualizados.

**Reconocimiento** 

Empezamos con la fase de reconocimiento, para descubrir que puertos y servicios tiene disponible el objetivo.

![img1](/secnotes/assets/img/firsthacking/1.png)

Este escaneo nos mostró que el objetivo cuenta con el puerto 21 (FTP) abierto. Continuamos con verificar que versión del servicio corre en el.

![img2](/secnotes/assets/img/firsthacking/2.png)

Esta revisión nos muestra que tiene la ver *vsftpd 2.3.4*

Con la herramienta *searchsploit* buscaremos si existe alguna vulnerabilidad sobre este servicio.

![img3](/secnotes/assets/img/firsthacking/3.png)

Esta busqueda nos mostró que existe un *Backdoor Command Execution*.
Esta es una tecnica de ejecución de comandos a través de una puerta trasera, se utiliza para tomar el control de un sistema informático de forma oculta.

**Cómo funciona?**

El atacante introduce un código malicioso o un programa en un sistema. Esta código actua como una puerta trasera que permite al atacante acceder al sistema cuando quiera.

**Ejecucion de comandos**

Una vez que el atacante tiene acceso a través del backdoor, puede enviar comandos al sistema. Por ejemplo, podría ordenar que se borren archivos, se robe información o se instalen más programas maliciosos.

Todo esto ocurre sin que el usuario o administrador del sistema se dé cuenta, ya que el backdoor está diseñado para ser secreto.

Ya que tenemos un exploit para esta versión, lo vamos a descargar en nuestra máquina.

![img4](/secnotes/assets/img/firsthacking/4.png)

Al revisar de que se trata el script podemos ver que exporta las librerias de *Telnet*, este es un problema, ya que las versiones actuales de Python ya no traen estas librerías.

![img11](/secnotes/assets/img/firsthacking/11.png)

Una opcion válida para poder ejecutar este script es posible ejecutar una versión de python que contenga estas librerias. 
Para esto debemos crear un entorno virtual de python con siguientes comandos:

`python3 -m venv ~/venv`

y lo activamos con:

`source ~/venv/bin/activate` 

![img5](/secnotes/assets/img/firsthacking/5.png)

![img6](/secnotes/assets/img/firsthacking/6.png)

con esto creamos un entorno virtual lo que nos permitirá trabajar con las librerías de python sin interferir con las librerías que tenemos en nuestro sistema base.

Ahora debemos ejecutar python con la version que nos permita usar las librerías de Telnet

`sudo docker run -it --rm -v "$PWD":/work -w /work python:3.11 bash` 

Este comando nos ejecutará python en su version 3.11

![img7](/secnotes/assets/img/firsthacking/7.png)

Solo nos queda ejecutar el script descargado y ganaremos acceso como root

![img8](/secnotes/assets/img/firsthacking/8.png)

Otra alternativa es usar *Metasploit*

Aquí debemos buscar la version del servicio y seleccionar el módulo adecuado.

![img9](/secnotes/assets/img/firsthacking/9.png)

Una vez seleccionado, configuramos con los datos requeridos y ejecutamos.

![img10](/secnotes/assets/img/firsthacking/10.png)










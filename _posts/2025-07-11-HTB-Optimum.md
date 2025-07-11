---
layout: post
title: "Optimum – HTB - Windows (A.D) - Fácil"
date: 2025-07-11
---
![banner](/secnotes/assets/img/optimun/banner.png)


**Reconocimiento**

Con nmap comenzaremos a escanear el objetivo y así
descubrir sus puertos abiertos, servicios que corren en
ellos y las versiones de estos servicios.

![img1](/secnotes/assets/img/optimun/1.png

 ![img2](/secnotes/assets/img/optimun/2.png

 ![img3](/secnotes/assets/img/optimun/3.png
 
Con esta info ya sabemos que nos enfrentamos a una máquina Windows. Esta solo nos muestra el servicio web. 

**Enumeración**

![img4](/secnotes/assets/img/optimun/4.png
 
_HFS_ es un programa que permite a los usuarios compartir archivos a través de HTTP, convirtiendo un computador en un servidor web simple. Este funciona sin necesidad de configuraciones complicadas o instalación de software adicional en el cliente, permitiendo el acceso a los archivos desde cualquier navegador.

![img5](/secnotes/assets/img/optimun/5.png
 
Navegando un poco por la red encontramos que esta aplicación es vulnerable a RCE.

Con metasploit vamos a buscar el nombre de la aplicación 

![img6](/secnotes/assets/img/optimun/6.png
 
Configuramos los parámetros necesarios

![img7](/secnotes/assets/img/optimun/7.png

 ![img8](/secnotes/assets/img/optimun/8.png
 
Y así obtenemos una sesión de meterpreter.
Usamos el comando `Shell` para abrir una sesion con una Shell interactiva y navegando por los directorios encontramos la flag de usuario.

![img9](/secnotes/assets/img/optimun/9.png
 
Validaremos la versión del sistema operativo con el comando `sysinfo`

![img10](/secnotes/assets/img/optimun/10.png
 
Tenemos un _Windows server 2012_

**Explotación**

Para tener una sesión más estable y evitar problemas a navegar vamos a migrar la ejecución del payload a otro proceso.
Para esto utilizaremos el comando `ps` y del listado de los procesos, en este caso migraremos al de explorer.exe. debemos recordar el numero de **PID.**

![img11](/secnotes/assets/img/optimun/11.png
![img12](/secnotes/assets/img/optimun/12.png
  

**Escalada de privilegios**

Buscando información sobre el sistema operativo, vemos que existe una vulnerabilidad sobre esta versión. 

![img13](/secnotes/assets/img/optimun/13.png
 
Nuevamente en metasploit vamos a buscarla, esta vez desde la sesión que tenemos abierta en meterpreter.
 
 ![img14](/secnotes/assets/img/optimun/14.png
 ![img15](/secnotes/assets/img/optimun/15.png
 ![img16](/secnotes/assets/img/optimun/16.png
 
Es importante configurar la sesión que teníamos abierta con meterpreter

 ![img17](/secnotes/assets/img/optimun/17.png
 
Iniciamos metasploit

![img18](/secnotes/assets/img/optimun/18.png
 
Y ganamos el acceso como administrador

![img19](/secnotes/assets/img/optimun/19.png
 

Ahora solo buscamos la flag de admin por los directorios

![img20](/secnotes/assets/img/optimun/20.png

 


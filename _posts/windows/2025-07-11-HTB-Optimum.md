---
layout: post
title: "HackTheBox: Optimum - Writeup y Solución Paso a Paso"
date: 2025-07-11
img: /assets/img/optimun/banner.png
tags: [HackTheBox, Windows, RCE, Metasploit]
description: "Optimum es una máquina para principiantes que se centra principalmente en la enumeración de servicios con exploits conocidos. Ambos exploits son fáciles de o..."
---
Optimum es una máquina para principiantes que se centra principalmente en la enumeración de servicios con exploits conocidos. Ambos exploits son fáciles de obtener y cuentan con módulos de Metasploit asociados, lo que hace que esta máquina sea bastante sencilla de completar.

**Reconocimiento**

Con nmap comenzaremos a escanear el objetivo y así
descubrir sus puertos abiertos, servicios que corren en
ellos y las versiones de estos servicios.

![img1]({{ site.baseurl }}/assets/img/optimun/1.png)

 ![img2]({{ site.baseurl }}/assets/img/optimun/2.png)

 ![img3]({{ site.baseurl }}/assets/img/optimun/3.png)
 
Con esta info ya sabemos que nos enfrentamos a una máquina Windows. Esta solo nos muestra el servicio web. 

**Enumeración**

![img4]({{ site.baseurl }}/assets/img/optimun/4.png)
 
_HFS_ es un programa que permite a los usuarios compartir archivos a través de HTTP, convirtiendo un computador en un servidor web simple. Este funciona sin necesidad de configuraciones complicadas o instalación de software adicional en el cliente, permitiendo el acceso a los archivos desde cualquier navegador.

![img5]({{ site.baseurl }}/assets/img/optimun/5.png)
 
Navegando un poco por la red encontramos que esta aplicación es vulnerable a RCE.

Con metasploit vamos a buscar el nombre de la aplicación 

![img6]({{ site.baseurl }}/assets/img/optimun/6.png)
 
Configuramos los parámetros necesarios

![img7]({{ site.baseurl }}/assets/img/optimun/7.png)

 ![img8]({{ site.baseurl }}/assets/img/optimun/8.png)
 
Y así obtenemos una sesión de meterpreter.
Usamos el comando `Shell` para abrir una sesion con una Shell interactiva y navegando por los directorios encontramos la flag de usuario.

![img9]({{ site.baseurl }}/assets/img/optimun/9.png)
 
Validaremos la versión del sistema operativo con el comando `sysinfo`

![img10]({{ site.baseurl }}/assets/img/optimun/10.png)
 
Tenemos un _Windows server 2012_

**Explotación**

Para tener una sesión más estable y evitar problemas a navegar vamos a migrar la ejecución del payload a otro proceso.
Para esto utilizaremos el comando `ps` y del listado de los procesos, en este caso migraremos al de explorer.exe. debemos recordar el numero de **PID.**

![img11]({{ site.baseurl }}/assets/img/optimun/11.png)

![img12]({{ site.baseurl }}/assets/img/optimun/12.png)
  

**Escalada de privilegios**

Buscando información sobre el sistema operativo, vemos que existe una vulnerabilidad sobre esta versión. 

![img13]({{ site.baseurl }}/assets/img/optimun/13.png)
 
Nuevamente en metasploit vamos a buscarla, esta vez desde la sesión que tenemos abierta en meterpreter.
 
 ![img14]({{ site.baseurl }}/assets/img/optimun/14.png)
 ![img15]({{ site.baseurl }}/assets/img/optimun/15.png)
 ![img16]({{ site.baseurl }}/assets/img/optimun/16.png)
 
Es importante configurar la sesión que teníamos abierta con meterpreter

 ![img17]({{ site.baseurl }}/assets/img/optimun/17.png)
 
Iniciamos metasploit

![img18]({{ site.baseurl }}/assets/img/optimun/18.png)
 
Y ganamos el acceso como administrador

![img19]({{ site.baseurl }}/assets/img/optimun/19.png)
 

Ahora solo buscamos la flag de admin por los directorios

![img20]({{ site.baseurl }}/assets/img/optimun/20.png)

☕ ¿Te sirvió el Write-up?
Si este contenido te ayudó a rootear la máquina o a aprender algo nuevo, ¡puedes invitarme un café! Todo el apoyo se va directo a mejorar el blog y seguir subiendo retos de DockerLabs.

---

### 🛡️ Otros Laboratorios y Writeups Relacionados
- [TheHackerLabs: Kaboom - Walkthrough y Writeup](/secnotes/2026/10/24/TheHackerLabs-Kaboom.html)
- [DockerLabs: Los 40 Ladrones - Writeup y Solución](/secnotes/2026/10/18/DockerLabs-Los40ladrones.html)
- [TheHackerLabs: Rockstar - Writeup y Explotación](/secnotes/2026/10/29/TheHackerLabs-Rockstar.html)
- [DockerLabs: Showtime - Explotación SQLi y Privesc](/secnotes/2026/09/11/DockerLabs-Showtime.html)
- [Serie Completa de Hardening en Metasploitable 2](/secnotes/metasploitable2)


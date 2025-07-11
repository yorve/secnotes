---
layout: post
title: "Optimun – HTB - Windows (A.D) - Fácil"
date: 2025-07-11
---

**Reconocimiento**

Con nmap comenzaremos el proceso de reconocimiento básico, esto para descubrir los puertos abiertos, servicios que corren en esos puertos y las versiones de estos del host objetivo.
 
 
 
Con esta info ya sabemos que nos enfrentamos a una máquina Windows. Esta solo nos muestra el servicio web. 

**Enumeración**
 
_HFS_ es un programa que permite a los usuarios compartir archivos a través de HTTP, convirtiendo un computador en un servidor web simple. Este funciona sin necesidad de configuraciones complicadas o instalación de software adicional en el cliente, permitiendo el acceso a los archivos desde cualquier navegador.
 
Navegando un poco por la red encontramos que esta aplicación es vulnerable a RCE
Con metasploit vamos a buscar el nombre de la aplicación 
 
Configuramos los parámetros necesarios
 
 
Y así obtenemos una sesión de meterpreter.
Usamos el comando `Shell` para abrir una sesion con una Shell interactiva y navegando por los directorios encontramos la flag de usuario.
 
Validaremos la versión del sistema operativo con el comando `sysinfo`
 
Tenemos un _Windows server 2012_

**Explotación**

Para tener una sesión más estable y evitar problemas a navegar vamos a migrar la ejecución del payload a otro proceso.
Para esto utilizaremos el comando `ps` y del listado de los procesos, en este caso migraremos al de explorer.exe. debemos recordar el numero de **PID.**
 
  

**Escalada de privilegios**

Buscando información sobre el sistema operativo, vemos que existe una vulnerabilidad sobre esta versión. 
 
Nuevamente en metasploit vamos a buscarla, esta vez desde la sesión que tenemos abierta en meterpreter.
 
 
 
Es importante configurar la sesión que teníamos abierta con meterpreter
 
Iniciamos metasploit
 
Y ganamos el acceso como administrador
 

Ahora solo buscamos la flag de admin por los directorios

 


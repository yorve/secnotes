---
layout: post
title: "Metasploitable 2 - Hardening Ingreslock"
date: 2026-07-10
img: /assets/img/metasploitable2/banner.png
tags: [Vuln, Linux, Hardening, FTP, Backdoor, root, Metasploitable 2]
---
# Puerto 1524 - Ingreslock #

Originalmente, el puerto 1524 estaba reservado para un servicio de bases de datos antiguo, llamado _Ingres Lock_. Pero los creadores de Metasploitable introdujeron intencionalmente una vulnerabilidad critica aquí...

Hicieron modificaciones en el servidor, para que cada vez que alguien toque el puerto 1524 el sistema operativo le regale una shell con los privilegios máximos del sistema sin pedir ningún tipo de credencial.

A esto se le conoce como **Bindshell**. El servidor amarra (bind) una consola a un puerto TCP y se queda esperando a que cualquiera llegue a tomarla.

**Como sabemos si podemos interactuar con un puerto en una máquina?**

Al realizar un escaneo de puertos detallado (-sV) Nmap nos dirá que tiene el sufijo `/tcp` o  `/udp`. 

**Como interpretamos esto?**

Netcat es una herramienta que lee y escribe datos a través de conexiones de red utilizando los protocolos vistos (`/tcp`  `/udp`).  Transmite texto plano de forma directa, por lo tanto, podríamos usar Netcat sobre un puerto si cumple dos condiciones:

 1. Usa TCP o UDP como protocolo de transporte: En la salida de Nmap lo veremos claro.
 2. Es un servicio basado en texto Plano (ASCII) o interactivo: Los servicios como FTP, SMTP, HTTP, o una Shell se comunican enviando y recibiendo texto que podemos leer. (Texto Plano).

**Pruebas 

Si vemos un puerto abierto TCP y sospechamos que puede ser interactivo o de texto plano, la forma de confirmar es hablando con él usando Netcat es lanzando un comando de conexión básica.

`nc -vn <IP_DE_SERVIDOR> <PUERTO>`

Al presionar Enter, pueden ocurrir 3 cosas que nos dirán a que nos enfrentamos.

1. Si vamos algo como `220 (vsFTPd 2.3.4)` o un prompt de comandos, El diagnostico es que el puerto es 100% interactivo. Podemos lanzar comandos de inmediato.
2. El puerto se queda en silencio. El puerto establece una conexión, pero la terminal se queda parpadeando esperando que hablemos primero. Esto es típico de servidores HTTP o de algunas bindshells silenciosas
	1. Digitamos algo genérico como `HELP`, `whoami`, si el servidor nos responde (como código HTML o un mensaje de error del sistema), confirmamos que podemos seguir usando Netcat para interactuar con el servidor.
3. Nos responde con caracteres extraños y se corta. El puerto no es apto para Netcat directo. Podría ser un servicio binario (como java RMI, MySQL o un puerto SSL/TLS cifrado) que requiere un cliente especializado para entender la estructura de sus bytes.


## Explotación.

Sabiendo esto, vamos a aplicarlo.

![](/secnotes/assets/img/1524/d58acbe52ae2773427c4c20e375edb36_MD5.jpg)

_no mas preguntas señor juez..._

## Hardening 

Para eliminar este backdoor procedemos a cerrar el puerto y así  mitigar esta vulnerabilidad. Nos vamos a nuestro archivo `inetd.conf` y comentamos la línea con el servicio expuesto.

![](/secnotes/assets/img/1524/309a30c09ac25d7c4ba337320974a485_MD5.jpg)

reiniciamos el servicio y ya no tendremos acceso desde la máquina atacante.

![](/secnotes/assets/img/1524/34c6e298fe8fcfe35ff7426491134dcb_MD5.jpg)

![](/secnotes/assets/img/1524/f09c0f2f255e51599ca705ef84809516_MD5.jpg)



---
layout: metasploitable2-post
title: "Metasploitable 2 - Hardening irc - irc-u"
date: 2026-07-14 09:20:00 -0400  
img: /assets/img/metasploitable2/banner.png
tags: [Metasploitable 2, irc, irc-u, CVE-2010-2075]
---

En este puerto encontramos el canal de comunicación utilizado por el protocolo **IRC** (Internet Relay Chat). Este protocolo es uno de los sistemas de chat de texto y mensajería instantánea más antiguos de internet, diseñado principalmente para la comunicación en grupo mediante canales de conversación.

Este utiliza un protocolo de transporte TCP, para garantizar que los mensajes de texto lleguen completos, en el orden correcto y sin pérdida de caracteres.

También transmite toda la información en texto plano, esto significa que todos los mensajes, contraseñas y nicks pueden ser interceptados fácilmente por cualquiera que espíe la red (ataques Man-in-the-middle), y que la dirección IP suele quedar expuesta ante otros usuarios del servidor si el nodo no la enmascara.

## Reconocimiento 

![](/secnotes/assets/img/metasploitable2/6667/607059c7cdef20a369fdd290856ff07d_MD5.jpg)

Esta versión de `unrealiRCd 3.2.8.1` contiene una vulnerabilidad asociada al **CVE-2010-2075**, se trata de un backdoor que permitía a los atacantes a ejecutar comandos arbitrarios en el sistema.

Al enviar una cadena especifica (como `AB;`) al conectarse, el servidor ejecutaba el comando arbitrario sin necesidad de autenticación.

## Explotación 

Crearemos un script en Python con ayuda de la IA que nos permita abusar de esta vulnerabilidad.

![](/secnotes/assets/img/metasploitable2/6667/48ef34cc90108284191b33368abbc310_MD5.jpg)

![](/secnotes/assets/img/metasploitable2/6667/9ac1025d039892196fb294ed8aa26587_MD5.jpg)

![](/secnotes/assets/img/metasploitable2/6667/1df8c3a0a402e364689105bcfdb8dc1c_MD5.jpg)

Como PoC utilizamos un comando inofensivo (`id`) en la máquina víctima, y redirigimos su respuesta hacia nosotros utilizando Netcat.

## Hardening

Esta versión se encuentra obsoleta y fuera de soporte, Se recomienda migrar todas las redes IRC a conexiones modernas y cifradas.

El estándar de seguridad actual para IRC es el puerto 6697. Este utiliza SSL/TSL para cifrar todo el tráfico entre el cliente del chat y el servidor, protegiendo la privacidad de la misma forma que el protocolo HTTPS protege a las páginas web.

Entonces nuestra misión será cerrar el puerto y seguir disminuyendo la superficie de ataque.

`killall -9 unrealircd`

`killall -9 ircoz unrealircd 2>/dev/null`

Este segundo comando es por que el script intentó levantar otro proceso hijo antes de morir, con este barremos con cualquier rastro. 

![](/secnotes/assets/img/metasploitable2/6667/4d88b12c7bc6b87a32b459444d3bb5a5_MD5.jpg)

## Puerto 6697 

**Efecto Colateral de Hardening:** Como ejecutamos el comando de limpieza y matamos al proceso padre que mantenía el servicio levantado, cerramos ambos puertos de un solo golpe. 

![](/secnotes/assets/img/metasploitable2/6667/f38890f49b34124709858e5187d3c399_MD5.jpg)


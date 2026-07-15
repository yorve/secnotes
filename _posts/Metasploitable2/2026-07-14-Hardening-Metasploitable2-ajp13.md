---
layout: metasploitable2-post
title: "ajp13"
date: 2026-07-14 09:25:00 -0400  # 
img: /assets/img/metasploitable2/banner.png
tags: [Metasploitable 2, ajp13, CVE-2020-1938]
---


En este puerto se aloja **AJP13** (Apache JServ Protocol versión 1.3)

Este es un protocolo binario diseñado por rendimiento para comunicar un servidor web frontal (como Apache HTTP Server) con un servidor de aplicaciones Java Backend (como Apache Tomcat)

En lugar de usar HTTP normal, que es texto plano y consume más recursos procesando cabeceras, el servidor web traduce la petición a este protocolo binario rápido y la envía al puerto 8009 del Tomcat.

## Reconocimiento 

![](/secnotes/assets/img/metasploitable2/8009/f5755cf85c0b424ad110497512185dde_MD5.jpg)

Las versiones antiguas de Tomcat es que el conector AJP tiene una confianza ciega en quien se conecta. Esto da lugar a una vulnerabilidad famosa llamada **Ghostcat** y está asociada al **CVE-2020-1938.**

Si el puerto está expuesto directamente a la red, cualquier atacante puede enviarle peticiones AJP modificadas para:
- Leer archivos arbitrarios del servidor web (incluyendo archivos de configuración, código fuente de aplicaciones Java y credenciales en texto plano de `/WEB-INF/web.xml`).
- Ejecución remota de código (RCE) si el atacante logra subir previamente un archivo de texto o imagen con un código malicioso al servidor (por ejemplo, a través de otra vulnerabilidad o formulario de subida).

## Hardening

Dado a que Tomcat está configurado para un entorno web integrado (donde no necesitamos un servidor apache frontal que hable AJP para despachar las páginas en el puerto 8180), la mejor práctica es deshabilitar por completo el conector AJP en los archivos de configuración de Tomcat.

Primero debemos localizar el archivo de configuración principal.

`find / -name "server.xml" 2>/dev/null`

editamos el archivo 

`nano /var/lib/tomcat5.5/conf/server.xml`

y buscamos la sección que define el conector AJP en el puerto 8009

![](/secnotes/assets/img/metasploitable2/8009/69c6a55ce1bb04080e53fa783566a9d1_MD5.jpg)

que hicimos:

![](/secnotes/assets/img/metasploitable2/8009/3f347f7efad7150aebeda205dfdbe34d_MD5.jpg)

quitamos el comentario (-->) de la primera línea y lo movimos al final.

luego reiniciamos el servicio para que aplique el cambio

`/etc/init.d/tomcat5.5 restart`

![](/secnotes/assets/img/metasploitable2/8009/75b5406f99939912308beabb35d252df_MD5.jpg)

![](/secnotes/assets/img/metasploitable2/8009/60cb4dcc33cb78025b78f591be5a5d03_MD5.jpg)

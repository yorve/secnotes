---
layout: metasploitable2-post
title: "Tomcat"
date: 2026-07-14 09:30:00 -0400  # 
img: /assets/img/metasploitable2/banner.png
tags: [Metasploitable 2, Tomcat, RCE]
---

![](/secnotes/assets/img/metasploitable2/8180/c8fa5e8b41dfe022a3a9f0fc0d86e010_MD5.jpg)

Mientras que el puerto 8009 gestiona el protocolo AJP, el puerto 8180 aloja la interfaz de cara al usuario: El servidor **HTTP de Apache Tomcat**. Es el puerto alternativo que utiliza Metasploitable2 para que no choque con el servidor web Apache principal que corre en el puerto 80.

Tomcat es un servidor web y contenedor de servlets de código abierto, su función principal es ejecutar aplicaciones web escritas en el lenguaje de programación Java.

## Reconocimiento

![](/secnotes/assets/img/metasploitable2/8180/17899dd25c8037e77cc6d83d0647cfd3_MD5.jpg)

![](/secnotes/assets/img/metasploitable2/8180/d51556cc7cfd7c9608de6790cbae17e5_MD5.jpg)

Con las credenciales por defecto, pudimos ingresar al panel de administración de tomcat, con acceso a este panel existen 3 riesgos críticos
 1. Ejecución remota de código (RCE) mediante el despliegue de archivos `.war`. Este es el peligro más destructivo de todos. Un atacante puede crear un archivo comprimido que contenga una Webshell en Java (JSP) y que al subirlo tomcat descomprime y ejecuta la aplicación automáticamente en el servidor.
 2. Robo de información sensible. Muchas de las aplicaciones desplegabas en tomcat se comunican con bases de datos internas. Al explorar las aplicaciones activas, un atacante puede extraer rutas de directorios, nombre de bases de datos y a menudo, configuraciones que contienen contraseñas en texto plano.
 3. Denegación de servicios. La consola de administración nos da control directo sobre el ciclo de vida de los servicios del servidor. Al lado de cada aplicación listada, hay un boton de Stop, Reload y Undeploy (Desinstalar)

## Hardening

Esta vez vamos a tomar el camino B, el blindaje Tomcat antes de la eliminación. En esta ocasión, pudimos ingresar al panel de administración con las credenciales por defecto. Cambiaremos estas credenciales y restringiremos el acceso a la consola para que solo se pueda ingresar desde una dirección IP autorizada.

**Buscamos el archivo de configuración

`find / -name "tomcat-users.xml" 2>/dev/null`

y abrimos el archivo con el editor

![](/secnotes/assets/img/metasploitable2/8180/72c5ad213b2bcb85e93c5793c8e25c3b_MD5.jpg)

cambiamos las credenciales 

![](/secnotes/assets/img/metasploitable2/8180/5ddfc6b8a54b48e6410f02b2e1d290c1_MD5.jpg)

Dentro del archivo `context.xml` agregamos una regla para permitir solo el acceso a locahost o una ip de confianza.

![](/secnotes/assets/img/metasploitable2/8180/c571504441dec7241567b56e4415f662_MD5.jpg)

**Nota** : `RemoteAddrValve`, es la encargada de filtrar coexiones basándose en la dirección IP del cliente.

Terminamos reiniciando el servicio

`/etc/init.d/tomcat5.5 restart`

![](/secnotes/assets/img/metasploitable2/8180/d6770b5ddcfbbf2b5bd560ac09e9ee76_MD5.jpg)

Como nuestra dirección IP no está en la regla, nos rechazara la conexión.


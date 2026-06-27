---
layout: post
title: "La Corporación - Hackerlabs"
date: 2026-06-11
img: /assets/img/corporacion/banner.png
tags: [Wireshark, BlueTeam, CVE-2021-41773, SSH, FTP]
---
![banner]({{ site.baseurl }}/assets/img/corporacion/banner.png)

Hoy toca auditoría de red con **La Corporación**, un laboratorio diseñado para entrenar el ojo del Blue Team.

Nos han entregado tres archivos de registro **.pcap** cargados de actividad sospechosa. En este lab, vamos a destripar esos paquetes usando Wireshark para descubrir qué información confidencial se filtró, qué tácticas usó el atacante y cómo un simple vistazo a los headers de red puede delatar un ataque avanzado.

Comenzamos con este desafío

![img1]({{ site.baseurl }}/assets/img/corporacion/intro.png)

Nos entregan 3 archivos de registro _.pcap_, para leerlos podemos utilizar la herramienta **WireShark**, esta es un analizador de protocolos de red de código abierto que captura e inspecciona en tiempo real el tráfico que fluye a través de la red.
Este funciona como una especie de radiografia o escaner, desglosando los paquetes de datos mostrando que información se está mandando y recibiendo en la red.

![img2]({{ site.baseurl }}/assets/img/corporacion/wireshark.png)

Teniendo nuestra aplicación abierta, procedemos a cargar los archivos _.pcap_ para comenzar nuestra búsqueda.

![img3]({{ site.baseurl }}/assets/img/corporacion/pcap.png)

Al cargar los logs, a simple vista se ve abrumador, pero aquí podemos sacar varios datos.

1 - En la parte inferior nos dice que existen 80 capturas en este archivo.
2 - Uso de protocolos inseguros y credenciales en texto plano (paquetes 51, 52, 53) El protocolo FTP no cifra el tráfico, En la imagen podemos ver claramente que un usuario está interactuando con el servidor sin ningun tipo de seguridad. 
3 - En el paquete 57, observamos `Request: RETR backup_config.txt`. Esto significa que alguien está descargando un archivo de configuración de respaldo.
4 - En los paquetes 53, 59, 60 y 61 se ve `Request_ STOR important_data.zip`. El comando `STOR` se utiliza para subir archivos al servidor. 

![img4]({{ site.baseurl }}/assets/img/corporacion/pcapssh.png)

![img5]({{ site.baseurl }}/assets/img/corporacion/invalid-login.png)

En el siguiente archivo de logs, podemos ver que la _Source ip 192.168.1.100_ intentó acceder via SSH a distintos destinos sin éxito. Si seguimos mirando los paquetes, nos encontramos con otra solicitud.

![img6]({{ site.baseurl }}/assets/img/corporacion/cve.png)

![img7]({{ site.baseurl }}/assets/img/corporacion/cve-2021.png)

Aqui tenemos un hallazgo interesante. Que significa todo esto?

El atacante está intentando solicitar o ejecutar un script de shell (.sh) asociado a la vulnerabilidad **CVE-2021-41773**. Esta vulnerabilidad es la famosa **Path Traversal** y **RCE (Ejecución Remota de Código)** en servidores web apache (versión 2.4.49) El atacante claramente está buscando explotar este fallo en el servidor víctima para tomar el control.

**Nota**

En un ataque real en producción contra esta vulnerabilidad, el _URI_ de la petición no debería llamarse así. Un atacante real intentaría ocultar caracteres saltando directorios usando una codificación URL, ejemplo _GET /cgi-bin/.%2e/.%2e/.%2e/.%2e/bin/sh._
Que el recurso se llame _/CVE-2021-41773.sh_ demuestra que el laboratorio nos dedjo una pista para identificar la firma exacta de la amenaza en el tráfico de red.

Ahora que tenemos toda la info podemos contestar las preguntas sin problemas.

![img8]({{ site.baseurl }}/assets/img/corporacion/preguntas1.png)

![img9]({{ site.baseurl }}/assets/img/corporacion/preguntas2.png)




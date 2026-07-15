---
layout: metasploitable2-post
title: "X11"
date: 2026-07-14 09:15:00 -0400  
img: /assets/img/metasploitable2/banner.png
tags: [Metasploitable 2, X11]
---

Aquí nos encontramos con otro canal de comunicación predeterminado para el Servidor x11, también conocido como **X Windows System**. Este sistema es la arquitectura fundamental que permite mostrar interfaces gráficas en sistemas operativos tipo Unix,  como Linux y BSD.

A diferencia de otros protocolos, c11 funciona con una lógica que suele confundir. 

 - El servidor X es la pantalla: El programa que dibuja las ventanas corre en la máquina del usuario que está mirando el monitor.
 - El cliente X es la aplicación: El programa corre en un servidor remoto.
 - La conexión: El servidor remoto (cliente) envía las instrucciones de dibujo a través del puerto 6000 hacia el servidor para que veamos la interfaz en la pantalla.

Al igual que **VNC**, si un equipo tiene múltiples pantallas o servidores X corriendo en paralelo, los puertos aumentan de forma correlativa.

Este protocolo original fue diseñado hace décadas y no incluye el cifrado de datos ni mecanismos de seguridad modernos. SI dejamos el puerto 6000 abierto y expuesto a internet o a una red publica cualquier atacante podría capturar lo que escribimos (keylogging), podrían tomar capturas de pantalla de lo que estamos viendo, podrían inyectar ventanas o ejecutar comandos visuales en nuestra sesión activa.  

## Hardening 

El servidor gráfico de Metasploitable2 (`Xtightvnc`) es justamente el que levanta e inicia el puerto 6000 (X11) para gestionar la pantalla remota. Al matar el proceso de TightVNC en la auditoría anterior, botamos de forma colateral el puerto 6000.

Hoy en día, nunca se be abrir el puerto 6000. En su lugar, el tráfico se encapsula de forma 100% segura a través de SSH.

Para abrir una aplicación gráfica de forma segura, simplemente usamos el parámetro `-X` o `-Y` al conectarse por la terminal.


![](/secnotes/assets/img/metasploitable2/6000/42ba5b5718a65d1f94e9186776836c4d_MD5.jpg)

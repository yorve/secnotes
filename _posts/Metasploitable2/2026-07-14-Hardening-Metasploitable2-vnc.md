---
layout: post
title: "Metasploitable 2 - Hardening vnc"
date: 2026-07-14 09:10:00 -0400  # 
img: /assets/img/metasploitable2/banner.png
tags: [Metasploitable 2]
---

En el puerto 5900 nos encontramos con el protocolo `vnc` (Virtual Network Computing) para permitir el control remoto de pantallas. A través de este puerto, un usuario puede ver el escritorio de otro equipo a distancia y controlar su mouse y teclado en tiempo real.

Su protocolo de transporte es TCP, para asegurar que cada movimiento del mouse y actualización de la pantalla se transmita sin errores. Si un servidor VNC maneja más de una sesión de escritorio, este utilizará puertos correlativos. La pantalla `:0` usa el puerto `5900`, la pantalla `:1` utilizará el puerto `5901` y así sucesivamente.

El grave peligro de seguridad de este puerto es que este no cifra el trafico de forma nativa y es un blanco constante de ataques automatizados en internet.

## Reconocimiento

Para interactuar con VNC, necesitamos una herramienta que hable su protocolo. Usaremos `vncviewer`. 

![](/secnotes/assets/img/metasploitable2/5900/2891c8c690123e98e8071657f1a000f3_MD5.jpg)
![](/secnotes/assets/img/metasploitable2/5900/6cf58edf572a270e77d9cfee88be29ea_MD5.jpg)

 **Nota:** En la auditoría de los servicios anteriores, pudimos recolectar un botín de credenciales, y por lo visto se reutilizan las contraseñas. Para este servicio utilizamos la contraseña `password` que obtuvimos de la base de datos de **MySQL.** Luego de una búsqueda en internet, pudimos descubrir que históricamente VNC limita las contraseñas a un máximo de 8 caracteres, facilitando enormemente los ataques de fuerza bruta. 

![](/secnotes/assets/img/metasploitable2/5900/c7c600c316b386e41c786cc54cda4496_MD5.jpg)

Esto nos abre directamente una shell como usuario root.

## Análisis de riesgo 

El VNC corre bajo los permisos de usuario root, esto significa que un atacante no solo verá la pantalla,. sino que también tendrá control absoluto del sistema operativo.

El protocolo RFB clásico de VNC no cifra el tráfico por defecto. Cualquier contraseña digitada o imagen transmitida viaja en texto plano por la red, permitiendo al atacante realizar un análisis de tráfico (sniffing) y robar las credenciales.

## Hardening

Como en este es un laboratorio y no necesitamos un entorno de escritorio (ya que todo lo gestionamos por SSH), la medida de hardening más eficiente y segura es apagar el servicio de raíz y bloquear su inicio.

`killall Xtightvnc`

![](/secnotes/assets/img/metasploitable2/5900/31449d394d4d066e6f11c547a542d9ec_MD5.jpg)

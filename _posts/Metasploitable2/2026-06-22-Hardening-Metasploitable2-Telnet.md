---
layout: post
title: "Metasploitable 2 - Hardening Servicio Telnet"
date: 2026-06-22
img: /assets/img/metasploitable2/banner.png
tags: [Vuln, Linux, Hardening, Telnet, root, ]
---
![Banner]({{ site.baseurl }}/assets/img/metasploitable2/banner.png)

Este es un nuevo proyecto de Hardening para el laboratorio Metasploitable2. Este es conocido por tener múltiples vulnerabilidades que como atacante podemos sacar provecho y comprometer la máquina. Pero esta vez nos pondrémos en los zapatos del equipo defensivo y aplicaremos configuraciones correctas para volver Metasploitable 2 una máquina segura.

**Los objetivos del proyecto serán:**

reducir la superficie de ataque.
Corregir fallas de configuración.
Implementar contramedidas.
Validar la postura de seguridad.

**Metodología:**

Inspección y validación de la vulnerabilidad.
Remediación (Hardening).
Validación de seguridad.
Esta máquina tiene multiples puertos y vulnerabilidades habilitados. Es por eso que iremos resolviendolas por servicios por separado.

![TELNET]({{ site.baseurl }}/assets/img/metasploitable2/20260619161500.png)

El protocolo Telnet es históricamente inseguro, ya que transmite todo en texto plano (incluyendo usuarios y contraseñas), aquí qualquier atacante que este haciendo un análisis de tráfico en la red como por ejemplo sniffing podría robarse las credenciales fácilmente. 

En esta máquina además de ser inseguro por naturaleza, tiene una vulnerabilidad **critica** de configuración que veremos a continuación.

![TELNET]({{ site.baseurl }}/assets/img/metasploitable2/20260621152546.png)

Como podemos observar, al conectarnos a este servicio con el usuario `msfadmin` y misma contraseña tenemos acceso a ejecutar todo por privilegios de administrador.

# Hardening de Telnet #

Para la ciberseguridad, dejar Telnet abierto es inaceptable. La recomendación oficial es sustituirlo por **SSH** (que cifra todo el tráfico) y apagar Telnet para siempre.

Para realizar esto, primero debemos localizar el archivo de configuración y luego de una búsqueda encontramos que este servicio se encuentra configurado en el archivo _inetd.conf_ 

![TELNET]({{ site.baseurl }}/assets/img/metasploitable2/20260621162029.png)

Para deshabilitarlo basta con comentar (#) la línea donde esta la configuración de telnet y posteriormente reiniciamos el servicio para aplicar los cambios.

![TELNET]({{ site.baseurl }}/assets/img/metasploitable2/20260621173519.png)

`/etc/init.d/xinetd restart`

Con esto ejecutado, intentamos acceder desde nuestra máquina atacante resultando en una conexión fallida.

![TELNET]({{ site.baseurl }}/assets/img/metasploitable2/20260621174019.png)

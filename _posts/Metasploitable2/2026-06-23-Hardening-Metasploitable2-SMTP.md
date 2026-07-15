---
layout:metasploitable2-post
title: "Metasploitable 2 - Hardening SMTP"
date: 2026-06-23 10:00:00 -0400
img: /assets/img/metasploitable2/banner.png
tags: [Vuln, Linux, Hardening, SMTP, Enumerate, root, Metasploitable 2 ]
---

![banner]({{ site.baseurl }}/assets/img/metasploitable2/banner.png)

Este es un nuevo proyecto de Hardening para el laboratorio **Metasploitable2**. Este laboratorio es conocido por tener múltiples vulnerabilidades que como atacante podemos sacar provecho y comprometer la máquina. Pero esta vez nos pondrémos en los zapatos del equipo defensivo y aplicaremos configuraciones correctas para volver Metasploitable 2 una máquina segura.

**Los objetivos del proyecto serán:**

- Reducir la superficie de ataque. 
- Corregir fallas de configuración. 
- Implementar contramedidas.
- Validar la postura de seguridad.

**Metodología:**

- Inspección y validación de la vulnerabilidad. Remediación (Hardening).
- Validación de seguridad.
- Esta máquina tiene multiples puertos y vulnerabilidades habilitados.
- Es por eso que iremos resolviendolas por servicios por separado.

![smtp]({{ site.baseurl }}/assets/img/metasploitable2/20260619161525.png)


El servicio **SMTP** se encarga del intercambio de correos electrónicos entre servidores. En este laboratorio en este puerto está corriendo **Postfix**.

El peligro de este servicio radica en una mala configuración que permite la enumeración de usuarios y el Open Relay. Cualquier atacante que tenga acceso a este puerto lo podrá usar para descubrir usuarios legítimos del sistema y eventualmente realizar ataques de fuerza bruta.

Una vez conectados desde nuestra máquina atacante al puerto 25, con el comando `vrfy` podremos preguntarle al servidor si existe el usuario en el sistema.

![smtp]({{ site.baseurl }}/assets/img/metasploitable2/20260621174702.png)

# Simulación de ataque #

Hay una herramienta preinstalada en kali llamada _smtp-user-enum_, que su función es enviar ráfagas de comandos utilizando un diccionario de nombres para identificar cuáles existen en el servidor. 

![smtp]({{ site.baseurl }}/assets/img/metasploitable2/20260621175029.png)

Los resultados dependerán del diccionario que carguemos para el proceso de búsqueda.

## Hardening ##

El proceso para hardenizar este servicio es deshabilitar el comando `vrfy`, así la herramienta de automatización ya no recibirá las respuestas correctas del servidor y será incapaz de adivinar si los usuarios existen o no, frustrando por completo los planes del atacante.

Para esto, debemos buscar el archivo de configuración de Postfix y deshabilitar en él el comando agregando una nueva regla.

![smtp]({{ site.baseurl }}/assets/img/metasploitable2/20260621175751.png)

agregamos la regla `disable_vrfy_command = yes`

![smtp]({{ site.baseurl }}/assets/img/metasploitable2/20260621175820.png)

reiniciamos el servicio para aplicar los cambios.

`/etc/init.d/postfix restart`

![smtp]({{ site.baseurl }}/assets/img/metasploitable2/20260621180025.png)

Ahora desde nuestra máquina atacante ya no podemos enumerar usuarios.

![smtp]({{ site.baseurl }}/assets/img/metasploitable2/20260621180053.png)

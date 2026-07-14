---
layout: post
title: "Metasploitable 2 - Hardening Servicio RCPBIND"
date: 2026-06-28
img: /assets/img/metasploitable2/banner.png
tags: [Linux, Hardening, RCPBIND, Mountd, Metasploitable 2]
---

![banner](/secnotes/assets/img/metasploitable2/banner.png)


Este es un nuevo proyecto de Hardening para el laboratorio Metasploitable2. Este laboratorio es conocido por tener múltiples vulnerabilidades que como atacante podemos sacar provecho y comprometer la máquina. Pero esta vez nos pondrémos en los zapatos del equipo defensivo y aplicaremos configuraciones correctas para volver Metasploitable 2 una máquina segura.

**Los objetivos del proyecto serán:**

- Reducir la superficie de ataque.
- Corregir fallas de configuración.
- Implementar contramedidas.
- Validar la postura de seguridad.

**Metodología:**

- Inspección y validación de la vulnerabilidad. Remediación (Hardening).
- Validación de seguridad.
- Esta máquina tiene múltiples puertos y vulnerabilidades habilitados.
- Es por eso que iremos resolviéndolas por servicios por separado.

# 111 - rcpbind #

![1](/secnotes/assets/img/metasploitable2/20260619161725.png)

El puerto 111 (TCP / UPD) está reservado para **rcpbind** (anteriormente conocido como `portmap`). Su función principal es asignar servicios RPC (Llamada de Procedimientos Remotos) a los puertos dinámicos correctos. Cuando un cliente necesita conectarse a un servicio como NFS (Network File System), le pregunta a `rpcbind` en qué puerto exacto está escuchando dicho servicio.

[¿Qué es el puerto 111?](https://www.cbtnuggets.com/common-ports/what-is-port-111)

## Reconocimiento ##

Con la herramienta `rpcinfo` podemos "preguntarle" al puerto 111 qué servicios tiene asignados. Esta servicio nos responderá sin pedir credenciales.

![](/secnotes/assets/img/metasploitable2/fcee87d7eb14ee7982c18339a872567b_MD5.jpg)

Los resultados nos muestra que `nfs` y `mountd` están expuestos. Ya que tenemos el servicio de `mountd` usaremos la herramienta `showmount` para consultar qué directorios están expuestos al exterior.

![](/secnotes/assets/img/metasploitable2/8ce050589c3d7fa7ffac75a827219959_MD5.jpg)

Esto significa que **todo el sistema de archivos raíz** ( / )está exportado y disponible para cualquier máquina en la red ( * )

## Explotación ##

Dado a que tenemos acceso a los archivos de la máquina víctima, podemos crear un directorio local en nuestra máquina atacante, y "pegar" el disco duro de la máquina víctima en ella.

![](/secnotes/assets/img/metasploitable2/c584fbae8e3d4e3d3f42b5c622efbd12_MD5.jpg)

![](/secnotes/assets/img/metasploitable2/e1b391e1314f53842c3acab565199259_MD5.jpg)

ahora tenemos todos los archivos de la máquina víctima en nuestra máquina atacante. Eso nos deja a disposición el archivo **shadow**, robar llaves SSH o ver cualquier archivo del sistema.

![](/secnotes/assets/img/metasploitable2/37d1a0a7446b0101d0f08e10db7d0eb5_MD5.jpg)

![](/secnotes/assets/img/metasploitable2/c7354f4121e258597b02435cbd260c43_MD5.jpg)

## Mitigación ##

### Servicio NFS ###
Ya sabemos lo peligroso que esto puede ser, para mitigar este problema vamos a permitir que solo una IP de confianza tenga permiso para interactuar con este puerto/servicio.

Para esto, debemos modificar el archivo de configuración que se encuentra en: `/etc/exports`

Aquí debemos modificar la última línea, borramos el asterisco ( * ) y agregamos la IP de confianza, en este caso vamos a poner la del localhost, también debemos cambiar `no_root_squash` por `root_squash`

![](/secnotes/assets/img/metasploitable2/05ca865dc7b39370cfed03d7e4f0d5b3_MD5.jpg)

Cambiamos la línea.

![](/secnotes/assets/img/metasploitable2/941ee3d978eb5e04edfe51e77ad13134_MD5.jpg)

Estos dos cambios eliminan por completo el peligro más crítico de este servicio. Al cambiar el asterisco ( * ) y poner una IP especifica, establecemos una lista blanca a nivel de red. El servidor NFS ahora inspecciona la IP de origen de cada paquete de petición. Si un atacante quisiera montar el disco desde otra IP, el sistema operativo rechará la conexión. Y cambiar `no_root_squash` creamos una directiva defensiva que mapea identidades. Si un usuario intenta crear, leer o modificar un archivo en el recurso compartido, la máquina intercepta esa acción y de forma transparente degrada los privilegios al usuario anónimo del sistema.

Con los cambios realizados, debemos reiniciar el servicio para aplicar las nuevas directivas.

```
sudo exportfs -a
sudo /etc/init.d/nfs-kernel-server restart
```
![](/secnotes/assets/img/metasploitable2/26e5513a618310aef7e5ba0cb6cf9ce7_MD5.jpg)

### Servicio Portmap ###

Ahora que el servicio NFS quedo protegido, el servicio de `portmap` sigue totalmente abierto al público. Para realizar el hardening a este debemos bloquear el acceso externo a portmap.

Vamos a usar los TCP Wrappers para prohibir que cualquier IP externa le haga preguntas a este puerto.

Abrimos el archivo de  denegación en Metasploitable2 que se encuentra en la ruta: `/etc/hosts.deny`, y agregamos una línea al final del archivo para denegar el acceso total.

![](/secnotes/assets/img/metasploitable2/2dedd7f76d96575443ca9598ad5eb835_MD5.jpg)

 Ahora abrimos el archivo de permitidos, comentamos con (#)la linea de `ALL:ALL` y ponemos nuestra IP de confianza.

![](/secnotes/assets/img/metasploitable2/c8096f56b1599b117bbc3168d4f8d09c_MD5.jpg)

Reiniciamos el servicio para aplicar los cambios.

`sudo /etc/init.d/portmap restart`

Ahora desde nuestra máquina atacante no tendremos acceso a este servicio.

![](/secnotes/assets/img/metasploitable2/a0367e91eba38b33b907e07b00cfaef6_MD5.jpg)

## Nota ##

Dado a que parchamos NFS y restringimos el montaje a localhost, el puerto 111 ya no cumple con ninguna función útil hacia el exterior. En un buen trabajo de hardening, el servicio que no se usa debería apagarse... Pero.. para que hacer las cosas fáciles si  podemos hacerlas difíciles... 😉

## Estado de la máquina ##

| Puerto | Servicio | Estado Inicial                                     | Estado Actual                         | Acción de Hardening                                                                                                                  |
| ------ | -------- | -------------------------------------------------- | ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| 21     | FTP      | Abierto `vsftdp 2.3.4` (Acceso anónimo)            | Cerrado                               | Servicio deshabilitado en `xinetd`                                                                                                   |
| 22     | SSH      | Abierto                                            | Usado para gestionar Metasploitable 2 |                                                                                                                                      |
| 23     | Telnet   | Abierto (acceso en texto plano)                    | Cerrado                               | Línea comentada en `inet.conf` y memoria purgada                                                                                     |
| 25     | SMTP     | Abierto (Enumeración de usuarios `vrfy`)           | Bllindado                             | Directiva `disable_vrfy_command = yes`.                                                                                              |
| 53     | DNS      | Abierto (Versión expuesta `bind 9.4.2`)            | Blindado y Ofuscado                   | ACLs restrictivas y ocultamiento de banner con `version`.                                                                            |
| 80     | HTTP     | Abierto (Cargado con aplicaciones web vulnerables) | Blindado                              | Aplicación de configuraciones de seguridad (Ocultar banner, desactivar listado de directorios, deshabilitar métodos HTTP inseguros). |
| 111    | RCPBIND  | Abierto (`portmap` y `nfs` Vulnerables)            | Blindado                              | Aplicación de configuraciones de seguridad sobre NFS y controlar el acceso por Red con TPC Wrappers.                                 |

---
layout: post
title: "Metasploitable 2 - Hardening RServices Suite"
date: 2026-07-08
img: /assets/img/metasploitable2/banner.png
tags: [Vuln, Linux, Hardening, root, EXEC, RLOGIND, RSHD]
---
Este es un nuevo proyecto de Hardening para el laboratorio **Metasploitable2**. Este laboratorio es conocido por tener múltiples vulnerabilidades que como atacante podemos sacar provecho y comprometer la máquina. Pero esta vez nos pondrémos en los zapatos del equipo defensivo y aplicaremos configuraciones correctas para volver Metasploitable 2 una máquina segura.

**Los objetivos del proyecto serán:**

* Reducir la superficie de ataque.
* Corregir fallas de configuración.
* Implementar contramedidas.
* Validar la postura de seguridad.

**Metodología:**

* Inspección y validación de la vulnerabilidad. Remediación (Hardening).
* Validación de seguridad.
* Esta máquina tiene múltiples puertos y vulnerabilidades habilitados.
* Es por eso que iremos resolviéndolas por servicios por separado.

  
[](/secnotes/assets/img/metasploitable2/banner.png)

Este es un protocolo de la suite de servicios heredados de Unix (R-Services). Este permite a un usuario ejecutar de forma remota un comando de la consola en una máquina servidora desde un cliente externo, sin necesidad de iniciar una sesión interactiva completa (como lo haríamos con Telnet o SSH.)

Cuando el cliente envía un nombre de usuario, una contraseña y el comando que desea ejecutar, el demonio `rexecd`, en el servidor valida las credenciales y, si son correctas levanta una shell interna, ejecuta el comando y le devuelve el resultado en texto plano al cliente.

### Nota 

Como metasploitable 2 es una máquina antigua, hay muchas herramientas de Debian que Kali purgó debido a su obsolescencia, por esto al intentar instalar nos darán un mensaje que no se puede instalar. 

![](/secnotes/assets/img/metasploitable2/9576f6f5f8389bc37ccc6c536c469a92_MD5.jpg)

Tampoco se puede explotar este servicio, ya que como este protocolo esta obsoleto en entornos modernos (Kali atacante).

## Hardening

Dado que el puerto ha demostrado ser inestable e inseguro, además de estar obsoleto, aplicaremos la eliminación de este servicio del sistema.

Para esto, modificamos su archivo de configuración ubicado en:

`/etc/inetd.conf`

Aquí debemos comentar la línea donde esta el servicio `exec`

![](/secnotes/assets/img/metasploitable2/616be48a3ab582467a4cac0c420c99b3_MD5.jpg)

![](/secnotes/assets/img/metasploitable2/d42f9b1c21bedd60896f44c4b685b283_MD5.jpg)

y reiniciamos el servicio para aplicar los cambios

`sudo /etc/init.d/xinetd restart`

![](/secnotes/assets/img/metasploitable2/4f5f281ee27881b025b44e0a6888d849_MD5.jpg)

# Puerto 513 - Rlogin

El servicio corriendo en este puerto es el más peligroso y fácil de explotar, la vulnerabilidad aplicaba en que en Metasploitable 2 viene configurado de fabrica con un archivo llamado `hosts.equiv` que contiene el símbolo `+`. Ese símbolo significa "Confía en absolutamente todas  las direcciones IPs del mundo y déjala entrar sin pedirle contraseña". Pero igual que el servicio anterior, al ejecutar un comando como `rlogin -l root <IP_DE_MAQUINA_VICTIMA>` y obteníamos una shell como root.

## Hardening

Al igual que el servicio anterior, debemos deshabilitarlo desde su archivo de configuración y cerrar el puerto expuesto.

![](/secnotes/assets/img/metasploitable2/e866563dcb5578a3d09b9b76ea66ec7f_MD5.jpg)
![](/secnotes/assets/img/metasploitable2/54ddfa3c0e694ed43958c8642603bd70_MD5.jpg)

# Puerto 514 - rsh

El demonio `is.rshd` maneja el protocolo `rsh` (Remote Shell). A diferencia de `rlogin` (que nos daba una terminal interactiva completa donde podíamos correr comandos), `rsh` está diseñado para enviar un comando único desde el cliente, ejecutarlo en el servidor y recibir el resultado de vuelta.

Este también viaja en texto plano a nivel de red (Vulnerable a Sniffing) y al igual que `rlogin`, si el archivo contiene el comodín `+`, el servidor confía ciegamente en la IP del cliente.

## Hardening

Mismo procedimiento de los servicios anteriores.

![](/secnotes/assets/img/metasploitable2/a12b53bf4ae5478d2cd53f0e4da9b6fe_MD5.jpg)

y luego de reiniciar los servicios ya no tendremos desde nuestra máquina atacante. 

![](/secnotes/assets/img/metasploitable2/6dad93ae2f8a8b8caa3cfb65a0958bbb_MD5.jpg)

Con estos procedimientos, la suite completa de los R-Services ha sido erradicada del servidor de forma definitiva, forzando a que cualquier interacción legítima de administración se haga obligatoriamente cifrada por el puerto 22 (SSH).

                                                                                                               
---------------------------------------------------------------------------------------------------------------------------------------------------------
| 512 | EXEC    | Abierto (Protocolo obsoleto sin cifrar)                                             | Cerrado | Línea comentada en `/etc/inetd.conf` |
| 513 | RLOGIND | Abierto (Autenticación laxa eludible mediante abuso de directivas en `hosts.equiv`) | Cerrado | Línea comentada en `/etc/inetd.conf` |
| 514 | RSHD    | Abierto (Ejecución remota de comandos en texto plano sin mecanismos de cifrado)     | Cerrado | Línea comentada en `/etc/inetd.conf` |

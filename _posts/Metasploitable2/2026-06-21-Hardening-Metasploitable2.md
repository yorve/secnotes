---
layout: post
title: "Metasploitable 2 - Hardening FTP"
date: 2026-06-21
img: /assets/img/metasploitable2/banner.png
tags: [Vuln, Linux, Hardening, FTP, Backdoor, root, Metasploitable 2]
---
![BANNER]({{ site.baseurl }}/assets/img/metasploitable2/banner.png)

Este es un nuevo proyecto de **Hardening** para el laboratorio **Metasploitable2**. Este es conocido por tener múltiples vulnerabilidades que como atacante podemos sacar provecho y comprometer la máquina. Pero esta vez nos pondrémos en los zapatos del equipo defensivo y aplicaremos configuraciones correctas para volver Metasploitable 2 una máquina segura. 

Los objetivos del proyecto serán:
 - reducir la superficie de ataque.
 - Corregir fallas de configuración
 - Implementar contramedidas.
 - Validar la postura de seguridad.

Metodología:
  - Inspección y validación de la vulnerabilidad.
  - Remediación (Hardening)
  - Validación de seguridad.

Esta máquina tiene multiples puertos y vulnerabilidades habilitados. Es por eso que iremos resolviendolas por servicios por separado.

# FTP - vsftpd Explotación de Backdoor #

El primer servicio que encontramos es el de FTP en el puerto 21. Este tiene habilitado el acceso anonimo, lo que nos indica que podemos acceder a el con el usuario `anonymous` y sin contraseña. Con este acceso podemos navegar por algunos directorios y recopilar información en el servidor.

![FTP]({{ site.baseurl }}/assets/img/metasploitable2/20260619161350.png)

Esta versión del servicio tiene un backdoor particular. Cuando se introduce un usuario acompañado de una carita feliz `:)` el servicio automáticamente abre una shell interactiva en el puerto 6200.

nos conectamos con netcat al puerto 6200 

`nc -nv 192.168.1.37 6200`

y obtenemos una shell root

![FTP1]({{ site.baseurl }}/assets/img/metasploitable2/20260619164414.png)
como ya tenemos una sesión como root, usamos el comando `passwd root` y cambiamos la contraseña por la que nosotros queramos y asi tener control total de esta máquina. 

![FTP2]({{ site.baseurl }}/assets/img/metasploitable2/20260619203004.png)

Al intentar una conexión por ssh, esta nos mostrará un error debido a que la versiones modernas de Kali Linux tiene desactivado por defecto los algoritmos de intercambio de claves antiguos. (ssh-rsa y ssh-dss) por motivos de seguridad, ya que hoy en día se consideran vulnerables.

Para saltarnos esta restricción de seguridad temporalmente de forma manual y forzar la conexión lanzaremos el siguiente comando.

```
ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa root@IP-DE-METASPLOITABLE
```

Ahora que tenemos acceso como root a la máquina, nuestro primer paso será eliminar el backdoor del puerto 21 que nos permitió entrar. Como metasploitable2 es un laboratorio antiguo, no podemos actualizar paquetes de forma normal desde internet, así que tenemos dos opciones:

- **Desactivar el servicio por completo (Mitigación rápida).**
- **Reemplazarlo por una alternativa segura**.

Si no es necesario un servidor FTP, la mejor práctica es reducir la superficie de ataque apagándolo.
En Linux, lo correcto para transferir archivos de forma segura es usar **SFTP** (que funciona protegido dentro de **SSH** en el puerto 22) y desinstalar el protocolo FTP inseguro. 

Luego de un poco de investigación descubrimos que en esta máquina, el servicio esta gestionado por `xinetd`. Dentro del directorio de configuración `/etc/xinetd.d/` encontramos el archivo del servicio FTP, que suele llamarse `proftpd`, `vsftpd` o `ftp`.

**Modificación del archivo**

Abrimos el archivo de configuración y cambiamos el valor de `disable` de `no` a  `yes`

![FTP3]({{ site.baseurl }}/assets/img/metasploitable2/20260619211627.png)

Luego reiniciamos el servicio de xinetd para aplicar los cambios.

`/etc/init.d/xinetd restart`

Intentamos la conexión a FTP desde nuestra máquina atacante.

![FTP4]({{ site.baseurl }}/assets/img/metasploitable2/20260619211901.png)



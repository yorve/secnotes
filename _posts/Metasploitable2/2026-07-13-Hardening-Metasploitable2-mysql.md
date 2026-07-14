---
layout: post
title: "Metasploitable 2 - Hardening MySQL"
date: 2026-07-13
img: /assets/img/metasploitable2/banner.png
tags: [Vuln, Linux, Hardening, mysql, root, Metasploitable 2 ]
---


Este puerto contiene el canal de comunicación predeterminado que utiliza el motor de bases de datos **MySQL** para establecer conexiones  de red. Permite que las aplicaciones, interfaces y herramientas externas se comuniquen con el servidor para leer, escribir y administrar datos.

MySQL es el sistema de gestión de bases de datos relacionales más popular y utilziado del mundo. Es un software Open Source que sirve para almacenar, organizar, proteger y recuperar grandes volúmenes de datos mediante el lenguaje SQL (Structure Query Language).

Este es el motor oculto detrás de la mayoría de los sitios web modernos. Se utiliza principalmente en plataformas de comercio electrónico, sistemas de gestión de contenidos y aplicaciones web de gran escala.

![](/secnotes/assets/img/metasploitable2/3306/02d56c019449c85f23faf38f45aee8ca_MD5.jpg)


# Reconocimiento

Por definición, el servicio SQL corre sobre TCP y utiliza un protocolo binario para comunicarse. Para interactuar con él, necesitaremos usar herramientas que entiendan el lenguaje de MySQL.

# Explotación

Para comprobar si podemos ingresar, utilizaremos el cliente nativo de MySQL `mysql`

![](/secnotes/assets/img/metasploitable2/3306/32c07692e754bf5680f0778a7910eeea_MD5.jpg)

Como era de esperar, el cliente actualizado de `mysql` intenta por defecto cifrar la conexión usando protocolos modernos de seguridad (TLS/SSL). Pero el servidor MySQL de Metasploitable es tan antiguo que no soporta cifrado SSL o maneja una versión tan obsoleta que nuestra máquina la rechaza de inmediato.

![](/secnotes/assets/img/metasploitable2/3306/749ea299f2e4be1ecaea31767c3f6934_MD5.jpg)

Por suerte pudimos desactivar el SSL con el argumento `--skip-ssl`, además pudimos ingresar sin necesitad de poner la contraseña de `root`. Una vez dentro podemos encontrar información en la base de datos.

![](/secnotes/assets/img/metasploitable2/3306/94f8ca460b847125c03eaccb9ef950be_MD5.jpg)

![](/secnotes/assets/img/metasploitable2/3306/9bb984c5e3a5f295c14e909bedfc3b41_MD5.jpg)

![](/secnotes/assets/img/metasploitable2/3306/234b056ca3dc521d4f0e6e5df05442cb_MD5.jpg)

y encontrar contraseñas de usuarios...

# Hardening

Para que este puerto deje de ser un peligro, vamos a aplicar la remediación de forma radical.

Detendremos el motor de base de datos en memoria.

`/etc/init.d/mysql stop`

Luego lo eliminaremos del inicio automático con el arranque del sistema.

`update-rc.d -f mysql remove`

![](/secnotes/assets/img/metasploitable2/3306/a04521883394fadc1a99bf526ba994d0_MD5.jpg)

y con esto cerramos el puerto del servicio y reducimos la superficie de ataque.

![](/secnotes/assets/img/metasploitable2/3306/067fdfe525d5aa3e1188e497a11432e4_MD5.jpg)

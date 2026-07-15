---
layout: metasploitable2-post
title: "nfs"
date: 2026-07-11
img: /assets/img/metasploitable2/banner.png
tags: [Vuln, Linux, Hardening, Metasploitable 2, root, NFS ]
---
![](/secnotes/assets/img/metasploitable2/2049/87b897fb1772f92a70d2cea4c7425216_MD5.jpg)

**NFS (Network File System)**, en un protocolo que permite a diferentes equipos en una red compartir archivos y carpetas. Este permite que los directorios remotos compartidos aparezcan u se comporten como si estuvieran montados directamente en el disco duro local del usuario. Es la tecnología de almacenamiento en red predeterminada en entornos UNIX y Linux.

**Nota**: NFS depende del protocolo RPC (Puerto 111) para que el cliente descubra los servicios del servidor antes de establecer en el puerto 2049.


Al realizar el hardening del servicio **rpcbind** en el puerto 111 y  apagamos Portmap, la herramienta `showmount` se queda completamente ciega, ya que nadie le puede decir cómo comunicarse con el servicio **NFS**, arrojando un error.

![](/secnotes/assets/img/metasploitable2/2049/f03129775d516fbffd8710ba9c70d89f_MD5.jpg)

Sin embargo, el protocolo NFS podría seguir abierto y escuchando en segundo plano esperando conexiones directas de alguien que ya conozca la ruta de montaje. Para cerrar el circulo de seguridad de forma definitiva y tachar el puerto 2049, vamos a deshabilitar el servidor NFS.

## Hardening

El primer paso será apagar el servicio NFS de la memoria.

`sudo /etc/init.d/nfs-kernel-server stop`

![](/secnotes/assets/img/metasploitable2/2049/ff5ac9ce5d1db12feb0779030fa7f995_MD5.jpg)

y terminamos con la eliminación del arranque automático.

`sudo update-rc.d -f nfs-kernel-server remove`

![](/secnotes/assets/img/metasploitable2/2049/6489bdc62368a2ceb0e8a62a0ef65920_MD5.jpg)

Con esto ya no tendremos acceso como atacantes.

![](/secnotes/assets/img/metasploitable2/2049/bf0e237d224be7f84f77de4668f5141c_MD5.jpg)

Como ya habíamos aplicado el hardening sobre el servicio **rpcbind - Portmap**, mitigamos de forma indirecta la fase de reconocimiento de NFS.

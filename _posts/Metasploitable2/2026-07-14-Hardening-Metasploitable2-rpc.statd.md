---
layout: post
title: "Metasploitable 2 - Hardening rpc.statd"
date: 2026-07-14 09:40:00 -0400  # 
img: /assets/img/metasploitable2/banner.png
tags: [Metasploitable 2, rpc.statd, NFC]
---

Análisis de `rpc.statd`  

![](/secnotes/assets/img/metasploitable2/56417/ed2b2c9c24093c326e8779e47f181fa3_MD5.jpg)

El servicio esta expuesto a la red externa sin controles de acceso. Al ser un puerto dinámico de rango alto, su ubicación cambia en cada reinicio, lo que dificulta su defensa perimetral si no se configuran puertos estáticos.

### Recomendación de Hardening

Si el uso de **NFC** no es requerido en el servidor, se debe deshabilitar por completo el servicio para cerrar tanto el puerto base 111 como los puertos dinámicos asociados:

```
/etc/init.d/portmap stop 
/etc/init.d/nfs-common stop 
update-rc.d -f portmap remove 
update-rc.d -f nfs-common remove
```



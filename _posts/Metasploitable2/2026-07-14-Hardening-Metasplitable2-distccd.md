---
layout: post
title: "Metasploitable 2 - Hardening distccd"
date: 2026-07-14 09:00:00 -0400
img: /assets/img/metasploitable2/banner.png
tags: [Vuln, Linux, Hardening, distccd, C, C++, root, Metasploitable 2 ]
---


En este puerto vive `distccd`, fue diseñado para la compilación distribuida de código C/C++. Su funcionamiento básico consiste en recibir código fuente de clientes de la red. compilarlo localmente en la máquina servidor utilizando compiladores como `gcc`, y devolver el binario resultante.

![](/secnotes/assets/img/metasploitable2/3632/ba3e4a2925576673fab24c776ead5da3_MD5.jpg)

Hay una vulnerabilidad crítica asociada al **CVE-2004-2687** proveniente de su diseño y configuración por defecto.

- El demonio no tienen ningún mecanismo de autenticación o cifrado nativo.
- Confía ciegamente en las instrucciones de compilación que recibe.
- Permite a los clientes definir qué compilador o herramienta del sistema quieren invocar. Un atacante puede manipular los argumentos de la compilación para inyectar comandos del sistema e indicar al servidor que los ejecute en su lugar.

## Explotación 


![](/secnotes/assets/img/metasploitable2/3632/27db6c4d2453702dd6ba637e2131b42e_MD5.jpg)


Utilizamos un script de Nmap para realizar la explotación.

`--script distcc-cve2004-2687:` Carga el script oficial de Nmap que emula una solicitud de compilación legítima de `distcc`.

`--script-args="cmd=id"`: Le indicamos al script que intente inyectar el comando `id`. 

La respuesta nos mostró la salida del comando enviado. Con esto un atacante podría aprovecharse y generar una reverse shell para tomar control del servidor o lanzar algún comando del sistema que lo ayude a ganar acceso. 

## Hardening

Esta servicio es extremadamente peligroso por que, por diseño confía en cualquiera que pueda enviarle paquetes TCP. Entonces tendremos dos opciones:
1. Deshabilitar si no se usa.
2. Restringir quién pueda usarlo.

Tomaremos la primera opción, primero detendremos el demonio que está escuchando en el puerto 3632 de forma inmediata.

`/etc/init.d/distcc stop`

Matamos todos los procesos

`killall distccd` 

Deshabilitamos el arranque automático

`nano /etc/default/distcc`

Debemos cambiar el valor a `false`

![](/secnotes/assets/img/metasploitable2/3632/47c22b559c913025653bf55bc2132061_MD5.jpg)

![](/secnotes/assets/img/metasploitable2/3632/3ab33a7fb53e36a0f3620fe4c03be832_MD5.jpg)

Al cambiar `START_DISTCC` a `false`, neutralizamos el servicio por completo.

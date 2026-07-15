---
layout: metasploitable2-post
title: "Metasploitable 2 - Hardening drb"
date: 2026-07-14 09:35:00 -0400  # 
img: /assets/img/metasploitable2/banner.png
tags: [Metasploitable 2, drb, Ruby, RCE]
---

![](/secnotes/assets/img/metasploitable2/8787/1f4fe21abd65df65e538c2b7a88feb15_MD5.jpg)

En el puerto 8787 nos encontramos con el servicio `drb` (Distributed Ruby), este es un sistema de comunicación remota que permite a múltiples programas escritos en Ruby interactuar entre sí a través de la red, como si estuvieran corriendo en la misma máquina. Permite la llamada a métodos remotos (RMI - Remote Method Invocation).

## Explotación

El gran problema de DRb es que no requiere contraseñas, tokens ni certificados para conectarse. Un atacante puede conectarse a este puerto y enviar un objeto de ruby serializado malicioso. Cuando el servidor recibe este objeto y lo reconstruye (deserializa), ejecuta el código que lleva dentro de forma automática. El resultado es la ejecución remota de código (RCE) instantánea con los privilegios del servicio que lo levantó, por lo general `root`.

![](/secnotes/assets/img/metasploitable2/8787/9a3e0c6c4436bbae03442a6daeae08fd_MD5.jpg)

![](/secnotes/assets/img/metasploitable2/8787/6ddb6fb1364b7e2bd7631097de08e6b7_MD5.jpg)

![](/secnotes/assets/img/metasploitable2/8787/19051f58858677290356fa8de9e84fca_MD5.jpg)

![](/secnotes/assets/img/metasploitable2/8787/4f46266725ed41c085ac229ecc60356b_MD5.jpg)

El objeto remoto del servidor nos está respondiendo directamente con un arreglo de símbolos que representan los métodos que tiene cargado en la memoria. Este resultado es la fuga de información técnica y nos muestra las "llaves" del reino...

`method_missing`: Este método es un comodín en Ruby. Si intentamos llamar a un método que supuestamente no existe en el objeto remoto, en lugar de lanzar un error y cerrar la conexión, el flujo car en `:method_missing`. Un atacante puede usar eso para enviar payloads personalizados que fuercen al servidor a buscar otras librerías del sistema y ejecutarlas.

`:instance_eval` y `instance_exec`: Estos métodos permiten evaluar strings como si fueran código de Ruby vivo dentro del contexto del objeto. Si le pasamos un string con comandos del sistema (como un `system('whoami')`, el servidor lo procesará y lo ejecutará localmente

`:public_send` y `:send`: Permiten invocar de forma dinámica cualquier otro método interno de las clases de Ruby instaladas en la víctima, saltándose las restricciones de visibilidad estándar del código.

## Hardening

El riesgo es alto teniendo este servicio expuesto (el cuál no debería estar abierto en ningún entorno de producción real), la recomendación prioritaria es dehabilitar el servicio por completo o restringir su visibilidad a nivel de red.

Si por alguna razón de negocio el servicio debiera seguir ejecutándose pero de manera aislada, podemos configurar reglas de firewall para denegar cualquier conexión entrante que no provenga de la propia máquina.

`iptables -A INPUT -p tcp --dport 8787 ! -s 127.0.0.1 -j DROP`

![](/secnotes/assets/img/metasploitable2/8787/70e1b83fa7ca17a59ee8c6221d8cb29b_MD5.jpg)

Los paquetes ahora son bloqueados o ignorados antes de ser procesados. El atacante no recibirá ninguna respuesta, no sabe si el puerto está ocultando algo o si hay algún firewall en el medio. 

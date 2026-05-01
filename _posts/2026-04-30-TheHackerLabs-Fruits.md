---
layout: post
title: "Fruits - HackerLabs - Linux"
date: 2026-04-30
img: /assets/img/fruits/banner.png
tags: [Linux, Enumeration, Web, LFI, SUID, ffuf, hydra, GTFObins]
---

![banner](/secnotes/assets/img/fruits/banner.png)

El compromiso de la máquina Fruits destaca la importancia de la enumeración de parámetros y el análisis de binarios con permisos especiales. Aqui detallamos el proceso de descubrimiento de un archivo y cómo la identificación del parámetro vulnerable mediante el filtrado de respuestas por longitud de líneas (-fl) permitió el acceso inicial. Finalmente, explotamos el bit SUID en el binario find para completar la escalada de privilegios.

Como es de costumbre, comenzamos con un escaneo de puertos, servicios y directorios con nuestra herramienta automatizada llamada **Auto-Recon**

![img1](/secnotes/assets/img/fruits/reconocimiento.png)

![img2](/secnotes/assets/img/fruits/recon.png)

Detectamos puerto 22 (SSH) y 80 (WEB) disponibles. Como ya sabemos, al no tener un usuario descartamos el servicio SSH de momento y nuestro enfoque será sobre el servicio web.

![img3](/secnotes/assets/img/fruits/web.png)

Al ingresar a la web, nos encontramos con una página y un buscador de frutas.

![img4](/secnotes/assets/img/fruits/buscador.png)

Al buscar algo en él el servidor nos mostraba que la URL no existe. Al analizar el código de la página, podemos identificar un formulario que apuntaba a un archivo inexistente.

![img5](/secnotes/assets/img/fruits/codigo.png)

Procedemos con un escaneo de directorios mas focalizado con **gobuster** en búsqueda de algo mas de información con el argumento `-x html,php,txt,py,sh,log`. Encontrando un archivo llamado _fruits.php_

![img6](/secnotes/assets/img/fruits/gobuster.png)

Pero que al acceder a él, no tenemos nada... 

![img7](/secnotes/assets/img/fruits/fuzz.png)

Ya con este archivo identificado, el siguiente paso es encontrar el parámetro exacto que aceptaba la aplicación, ya que los intentos comunes nos fallaron. Aquí nuestro aliado será la herramienta **ffuf**. 

![img8](/secnotes/assets/img/fruits/ffuf.png)

Para evitar que ffuf nos muestre todo el ruido en pantalla cuando esta haciendo la búsqueda del parámetro, utilizaremos el argumento `-fl 2` (Filter Lines) En este caso le decimos a la herramienta que no muestre nada que tenga exactamente esa cantidad de líneas. De esta manera, la herramienta solo se detendrá y nos mostrará un resultado cuando encuentre una respuesta con una cantidad de líneas diferente.

![img8.1](/secnotes/assets/img/fruits/ffuf-filtro.png)


**Un punto importante**

>Se utiliza la ruta _/etc/passwd_ ya que es el estándar de oro para verificar que un **LFI** es real. Al ser un archivo que existe en prácticamente todos los sistemas operativos basados en Linux y Unix, y que además tiene permiso de lectura para todos los usuarios es el objetivo perfecto para conformar que el servidor está procesando y devolviendo archivos del sistema.

![img9](/secnotes/assets/img/fruits/LFI.png)

Confirmamos el LFI y obtenemos un usuario llamado **bananaman**. Ya tenemos un usuario y un servicio SSH habilitado. Nuestro siguiente paso será descubrir la contraseña con un ataque de diccionario.

![img10](/secnotes/assets/img/fruits/hydra.png)

Ataque exitoso, tenemos la contraseña del usuario bananaman. Ya con sus credenciales podremos ingresar al servidor con estos datos.

**Nota**

>El laboratorios es común encontrar las contraseñas en estos ataques de manera rápida y con el diccionario Rockyou, ya que estos están enfocados en los procedimientos y técnicas de cada paso. En la vida real hay que tener mucha paciencia.

Una vez conectados al servidor, hacemos la comprobación básica de permisos para así identificar la escalada de privilegios.

![img11](/secnotes/assets/img/fruits/find.png)

Tenemos el bit de SUID en la herramienta **find**, este bit nos permite ejecutar un archivo con los privilegios del propietario (root)

>https://gtfobins.org/gtfobins/find/

![img12](/secnotes/assets/img/fruits/gtfobins.png)

Según **GTFObins** tenemos un método de lanzar una Shell como usuario root con el comando:

`find . -exec /bin/sh -p \; -quit`, 

![img13](/secnotes/assets/img/fruits/root.png)

Y con este paso completamos la máquina, solo nos quedaría leer las flags de ambos usuarios.











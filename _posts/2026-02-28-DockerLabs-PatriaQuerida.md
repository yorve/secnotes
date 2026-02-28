---
layout: post
title: "Patria Querida - Dockerlabs - Linux - Fácil"
date: 2026-02-28
img: /assets/img/patriaquerida/1.png
tags: [DockerLabs, Linux, Easy, LFI, SUDI, SSH, Python; Enumeration, Path-Traversal, Web-Security, PrivEsc]
---

"Resolución de Patria Querida: Explotación de un Local File Inclusion (LFI) en index.php para descubrir credenciales ocultas y escalada de privilegios mediante el abuso del bit SUID en Python 3.8."

Como ya es costumbre iniciaremos la fase de reconocimiento con el script **Auto-Recon** (Disponible en mi perfil) el cúal nos ayudará con los escaneos iniciales de los objetivos de manera automatizada.

![img1](/secnotes/assets/img/patriaquerida/incio.png)

![img2](/secnotes/assets/img/patriaquerida/incio1.png)

Los resultados nos muestra que tenemos servicio SSH y WEB. Sabemos que sin un usuario almenos no podemos hacer nada sobre el servicio SSH. En el servicio web tenemos una ruta a *index.html* y *index.php*

![img3](/secnotes/assets/img/patriaquerida/web1.png)

Al ingresar a */index.html* no tenemos nada, solo la página de inicio de Ubuntu.

![img3](/secnotes/assets/img/patriaquerida/web1.png)

La ruta a */index.php* nos muestra una pista..

![img4](/secnotes/assets/img/patriaquerida/web2.png)

tenemos una nueva ruta hacia */var/www/html/.hidden_pass*.

Aquí tenemos algo importante.. la pista nos dice que no olvidemos leer el archivo oculto en la ruta señalada. Eso nos indica que el servidor puede ser vulnerable a LFI. Esta vulnerabilidad nace de una mala validación de las entradas del usuario. El servidor utiliza una funcion (como *include()* en PHP) para cargar contenido. y que no limpia el parámetro que recibe la ruta de los archivos.
Entonces el archivo index.php utiliza una variable llamada *page* para determinar que contenido mostrar. El problema es que el servidor confía en los que el usuario escribe despues del signo *=*. En lugar de recibir un nombre de sección (como contacto o inicio), el servidor acepta rutas del sistema de archivos.

Como sabemos que el servidor utiliza *page*?

![img5](/secnotes/assets/img/patriaquerida/nikto.png)

Nuestro script automatizado nos dijo. **Nikto** realiza fuzzing de paranetros comunes, ya que tiene una base de datos con miles de nombre de variables que suelen ser vulnerables. 
por otra parte nos dice que el servidor es vulnerable a file traversal, permitiendo que los atacantes puedan ver archivos en el host.

`/index.php?page=../../../../../../../../../../etc/passwd`

cada *../* le dice al sistema que suba un nivel en la jeranquía de directorios. Al poner muchos nos aseguramos de llegar a la raiz (/) para luego dirigirse a carpetas sensibles como */etc/* o */var/*

tambien nos facilita la ruta hacia un archivo del servidor.

![img6](/secnotes/assets/img/patriaquerida/nikto2.png)

Juntamos toda la información. Tenemos dos usuarios **pinguino** y **mario**, además la ruta hacia el achivo *.hidden_pass* nos entrega un texto **balu**

![img7](/secnotes/assets/img/patriaquerida/web3.png)

El siguiente paso será comprobar si **balu** es una contraseña.

![img8](/secnotes/assets/img/patriaquerida/ssh.png)

Efectivamente era, y ganamos el acceso por ssh al servidor. Sin embargo y como era de esperar el usuario **pinguino** no tiene permisos de sudo. Así que seguiremos con la búsqueda de permisos especiales.

`find / -perm -4000 -type f 2>/dev/null`

![img9](/secnotes/assets/img/patriaquerida/ssh.png)

Ya tenemos asegurada la escalada de privilegios. Como vimos en un laboratorio anterior, contamos con el SUID de Python. Esto quiere decir que podemos covertirnos en usuario root gracias a los permisos heredados de python.

pero antes... buscando en los directorios, nos encontramos un archivo .txt con una nota...

![img10](/secnotes/assets/img/patriaquerida/mario.png)

repetimos procedimientos y tenemos la misma info..

![img11](/secnotes/assets/img/patriaquerida/mario1.png)

A lo que vinimos... 

`/usr/bin/python3.8 -c 'import os; os.execl("/bin/sh", "sh", "-p")'`

Vamos a desglozar el comando.

`/usr/bin/python3.8` - Aquí llamamos a la ruta absoluta del binario que contramos con find. Al tener el bit **SUID** activo, este archivo se ejecuta con los privilegios del dueño (root) 

`-c` - le indica a python que el codigo que se ejecute entre comillas debe ejecutarse inmediatamente como un comando.

`os.execl("/bin/sh", "sh", "-p")` - Aqui esta la magia

os.execl - reemplaza el proceso actual por un nuevo proceso

"/bin/sh" - es la ruta del ejecutable que queremos lanzar

"sh" - en el nombre del proceso

"-p" - Privileged mode - el le ordena a la shell no descartar los permisos heredados del SUID, permitiendo mantener la identidad de root

![img12](/secnotes/assets/img/patriaquerida/root.png)

Les comparto el laboratorio donde explicamos los permisos heredados. 

https://yorve.github.io/secnotes/DockerLabs-PingCTF/





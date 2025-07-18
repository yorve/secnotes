---
layout: post
title: "Deloitte – CyberAcademy - Linux"
date: 2025-07-17
img: /assets/img/deloitte/banner.png
---

Deloitte es una máquina CTF Linux en la que tenemos que encontrar las 10 Flags ocultas.


**Reconocimiento**

identificación la máquina en la red.

![img1](/secnotes/assets/img/deloitte/1.png)

**Escaneo y enumeración del objetivo**

![img2](/secnotes/assets/img/deloitte/2.png)

![img3](/secnotes/assets/img/deloitte/3.png)
 
**Obtención de acceso**

![img4](/secnotes/assets/img/deloitte/4.png)
 
Despues de la enumeración nos encontramos con el servicio FTP habilitado (puerto 21) este tiene acceso como  **Anonymous** disponible, al acceder encontramos la primera flag.
 
![img5](/secnotes/assets/img/deloitte/5.png)

Inspeccionando el servicio web (puerto 80) nos encontramos con una flag.

![img6](/secnotes/assets/img/deloitte/6.png) 

Usamos el script que nmap tiene para enumerar los directorios en el servicio web.

![img7](/secnotes/assets/img/deloitte/7.png)

Aqui encontramos el archivo _robots.txt_, al revisar la ruta de este archivo, nos da otra posible ruta
_/cyberacademy_ . Al acceder a esta encontraremos otra flag.

![img8](/secnotes/assets/img/deloitte/8.png) 
 
Otra ruta que nos encontro nmap fue: _/uploads_ , al acceder a esta encontramos una flag. 

![img9](/secnotes/assets/img/deloitte/9.png) 

Accedemos a **login_1**, al inspeccionar esta página encontramos lo siguiente:

![img10](/secnotes/assets/img/deloitte/10.png)
 
Esta función toma la entrada que el usuario puso en el _login_, y lo compara con las credenciales de acceso (admin – supersecret). Si no corresponde arroja el mensaje “usuario y/o contraseña incorrectos”  

Al ingresar el usuario y contraseña que objuvimos en la función obtenemos la flag.

![img11](/secnotes/assets/img/deloitte/11.png)
 
En la ruta de  _/ping/_ podemos ejecutar comandos desde la url.

![img12](/secnotes/assets/img/deloitte/12.png)
 
Sabiendo que podemos inyectar comandos en listamos directorios, así encontramos la flag.

![img13](/secnotes/assets/img/deloitte/13.png)

![img14](/secnotes/assets/img/deloitte/14.png)
  
La próxima flag esta ubicada en la ruta 192.168.1.25/login_2/index.php

para llegar a ella tuvimos que modificar la cabecera de la petición GET a FAIL. Con esto hicimos un bypass de la autenticación (use las credenciales del login_1  admin:supersecret)

![img15](/secnotes/assets/img/deloitte/15.png) 

![img16](/secnotes/assets/img/deloitte/16.png)

Ya que podemos ejecutar comando en el navegador nos crearemos una sesión con meterpreter con una reverse Shell y asi subir un exploit que nos dará el acceso como root al sistema aprovechando una vulnerabilidad del sistema operativo.
 
https://www.exploit-db.com/exploits/41458

![img17](/secnotes/assets/img/deloitte/17.png)

subiremos el exploit con el comando `upload <ruta del exploit> <ruta del destino>`
en este caso _/temp_

daremos permisos al archivo subido con `chmod +x exp`

y ejecutamos el exploit con  `./exp`

![img18](/secnotes/assets/img/deloitte/18.png)

![img19](/secnotes/assets/img/deloitte/19.png)

Con este exploit ya ganamos acceso como root, ahora solo nos queda navegar por los directorios y encontras la flag de root.

![img20](/secnotes/assets/img/deloitte/20.png)

Listado de las flags encontradas

![img21](/secnotes/assets/img/deloitte/21.png)
 
 
 
 


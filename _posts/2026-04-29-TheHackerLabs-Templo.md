---
layout: post
title: "Templo - Hackerlabs - Linux"
date: 2026-04-29
img: /assets/img/templo/banner.png
tags: [HackerLabs, Linux, Enumeration, LFI, PHP-Wrappers, RCE, ROT13, Zip-Cracking, JohnTheRipper, LXC, LXD, Container-Escape, Medium]
---
![banner](/secnotes/assets/img/templo/banner.png)

En este laboratorio, exploraremos cómo un parámetro de inclusión de archivos (LFI) aparentemente inofensivo puede ser la llave maestra para extraer el código fuente del servidor mediante PHP Wrappers. El análisis del código nos revelará un mecanismo de ofuscación basado en ROT13 diseñado para ocultar archivos subidos, el cual saltaremos para obtener ejecución remota de comandos (RCE).

Comenzamos con la fase de reconocimiento inicial con nuestra herramienta **Auto_recon** (Disponible en mi perfil)

![img1](/secnotes/assets/img/templo/reconocimiento.png)

![img2](/secnotes/assets/img/templo/reconocimiento_servicios.png)

![img3](/secnotes/assets/img/templo/reconocimiento_directorios.png)

Podemos detectar que tenemos servicio **SSH** y **WEB** disponibles, ya que no tenemos ningún nombre de usuario o pista disponible para el servicio SSH, centraremos la recopilación de información sobre el servicio web. En el escaneo de directorios encontramos un par de rutas que podrían darnos datos de interés.

![img4](/secnotes/assets/img/templo/web.png)

Revisando los directorios web encontrados en la fase de reconocimiento, encontramos que en la ruta  _/wow/_ tenemos una pista que nos podría servir a futuro

![img5](/secnotes/assets/img/templo/wow.png)

![img6](/secnotes/assets/img/templo/opt.png)

No hay nada mas de interés en el resto de directorios web, sin embargo nos llama la atención un texto en particular de la página principal...

![img7](/secnotes/assets/img/templo/namari.png)

**NAMARI** podría ser un nombre de usuario, ruta, contraseña o algo que nos sea de utilidad.. 

Efectivamente, NAMARI era una ruta que nos envía a una página donde nos permiten subir archivos

![img8](/secnotes/assets/img/templo/web-namari.png)

Al subir el archivo aparentemente no tenemos respuesta, pero si podemos ver algo interesante.. 

![img9](/secnotes/assets/img/templo/lfi.png)

Tenemos _index.php?page=_ con este parámetro podemos sospechar que el servidor es vulnerable a LFI, pero no podemos confirmar si no probamos... 

![img10](/secnotes/assets/img/templo/lfi1.png)

Éxito! tenemos un usuario válido llamado **rodgar**, lo guardaremos para después.

Luego de intentar de leer el archivo **index.php** notamos que la página entra en un bucle, no podemos ver el código fuente porque el servidor ejecuta el PHP en lugar de mostrarlo. Después mu mucha investigación e intentos llegamos a una solución llamada **PHP WRAPPER** esta es básicamente una técnica para evadir la ejecución del servidor.

`php://filter/convert.base64-encode/resource=index.php`

que hace esto??

php://filter : Es un flujo de acceso que permite aplicar filtros a un archivo.
convert.base64-encode : Obliga al servidor a convertír el código PHP en una cadena de texto Base64.

El truco es que al estar codificado, el motor de PHP no reconoce las etiquetas _<?php_ y no las ejecuta. El servidor nos entrega el archivo (index.php) como si fuera texto plano. 

 https://blog.deephacking.tech/en/posts/exploiting-php-wrappers/

![img11](/secnotes/assets/img/templo/phpwrapper.png)

![img12](/secnotes/assets/img/templo/wrapper.png)

Ya que tenemos el texto codificado en Base64, nos queda decodificarlo y ver que encontramos.

![img13](/secnotes/assets/img/templo/decode.png)

![img14](/secnotes/assets/img/templo/index.png)

Al leer el archivo podemos ver varias cosas. El servidor envía los archivos que subimos a la ruta _/uploads_ ($target_dir = "uploads/";) 
Extrae el nombre y la extensión original de los archivos que subimos.

$rot13_encoded_name = str_rot13($file_name_without_extension);  El servidor aplica un cifrado ROT13 al nombre del archivo.
Se reconstruye el nombre con el cifrado ROT13 + la extensión original
Mueve el archivo a la ruta especificada

el último bloque (_$sile = $_GET['page'];_) es peligroso, ya que toma cualquier valor que pongamos en la url después de **?page=**.
_include($file);_. esta función en PHP no solo lee los archivos, sino que ejecuta cualquier código PHP que encuentre dentro de ellos, sin importar la extensión de los archivos.

Sabiendo esto, vamos a validad si funciona.. Para esto nos crearemos un archivo .php con el siguiente código:

`<?php system($_GET['cmd']); ?>`

![img15](/secnotes/assets/img/templo/test.png)

hacemos la conversión para saber el nombre del archivo.

![img16](/secnotes/assets/img/templo/rot13.png)

![img17](/secnotes/assets/img/templo/command.png)

Tenemos resultado, nuestro siguiente paso será subir una reverse Shell y conectarnos al servidor con el mismo procedimiento anterior.

https://www.revshells.com/  (la vieja confiable)

![img18](/secnotes/assets/img/templo/reverseshell.png)

![img19](/secnotes/assets/img/templo/reverse_shell.png)

ya tenemos conexión al servidor. Ahora nuestro primer paso es hacer el tratamiento de la terminal.

`python3 -c 'import pty; pty.spawn("/bin/bash")'`

luego ctrl + z 

`stty raw -echo; fg`

(si la terminal no se ve presionar enter otra vez)
 y reiniciamos la terminal 

 `reset xterm`

y los últimos para exportar las variables de entorno

`export TERM=xterm`

`export SHELL=bash`

Ahora podemos continuar.. vamos a ir directamente por la pista que encontramos en un inicio en la ruta _/opt_, ya que con el usuario actual (www-data) no tenemos ningún privilegio.

![img20](/secnotes/assets/img/templo/_opt.png)

En este directorio nos encontramos un archivo .zip, dado que no tenemos la herramientas necesarias en el servidor, vamos a iniciar un servidor aprovechando python3 y lo descargaremos en nuestra máquina atacante.

![img21](/secnotes/assets/img/templo/http.server.png)

Ya en nuestra máquina intentamos descomprimir el archivo, pero este nos pide una contraseña. Así que le dejaremos la tarea a **john the ripper**.

Primero extraemos el hash del archivo comprimido.

![img22](/secnotes/assets/img/templo/hash.png)

Luego le pasamos el hash y un diccionario para que intente descifrar la contraseña.

![img23](/secnotes/assets/img/templo/john.png)

Con la contraseña descifrada podemos extraer el archivo para ver su contenido.

![img24](/secnotes/assets/img/templo/contraseña.png)

podemos ver un archivo llamado **Rodgar.txt** con un texto que pareciera ser una contraseña. El siguiente paso será probar si es válida.

![img25](/secnotes/assets/img/templo/rodgar.png)

Efectivamente era la contraseña de este usuario.
 
![img26](/secnotes/assets/img/templo/userflag.png)

y como era de esperar, nos encontramos la flag de usuario en su directorio. Seguimos con las comprobaciones básicas del usuario Rodgar, y sorpresa.. no tenemos nada en nuestra primera comprobación.

![img27](/secnotes/assets/img/templo/perm.png)

Pero... al revisar algunos datos de este, podemos ver que pertenece a un grupo en particular. 

![img28](/secnotes/assets/img/templo/id.png)

Con una investigación rápida podemos ver lo siguiente... 

![img29](/secnotes/assets/img/templo/lxd.png)

Entonces nuestra escalada de privilegios será por medio de este grupo (al parecer)

En la web nos encontramos con el procedimiento para realizar la escalada mediante un contenedor.

Esta técnica es común en entornos donde se utilizan contenedores para desarrollo o microservicios. Se basa en una confianza excesiva en los usuarios que pertenecen al grupo **lxd** o **lxc**

LXC es un gestor de contenedores (parecido a Docker, pero basado en el sistema operativo completo) Para que funcione, el servicio de LXD debe correr con privilegios de root en la máquina host. Cuando un usuario es ingresado al grupo lxd, le está dando permiso para hablar directamente con el demonio de LXD. El problema es que este no restringe lo que puede hacer un usuario con un contenedor. La escalada no ocurre por un bug, sino por una funcionalidad mal utilizada.

La lógica es la siguiente:

1.- Contenedor privilegiado: Se crea un contenedor con la bandera _security.privileged=true_. Esto hace que el usuario root dentro del contendor sea el mismo root de la máquina real.

2.- El dispositivo de disco: LXD permite añadir dispositivos a los contenedores. Añadimos el disco duro completo de la víctima (_source=/_) y le decimos que lo montara en una carpeta interna del contenedor (_path=/mnt/root_).

3.- El salto: Al entrar el contenedor creado, seremos root. Como el disco de la víctima está montado ahí, podremos entrar a la ruta _/mnt/root/etc/shadow_ y cambiar contraseñas, o en nuestro caso buscar la root flag.

https://medium.com/@mstrbgn/privilege-escalation-using-lxd-lxc-group-assignment-to-a-user-a-security-misconfiguration-a4892f611d6f

Seguimos los pasos señalados y ya tenemos acceso como usuario root dentro del contenedor

![img30](/secnotes/assets/img/templo/lxc-contenedor.png)

Ahora nos falta el último paso que, en nuestro caso, es buscar la flag del usuario root

![img31](/secnotes/assets/img/templo/root.png)


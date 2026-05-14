---
layout: post
title: "ZapasGuapas - Hackerlabs - Linux"
date: 2026-05-13
img: /assets/img/zapas/banner.png
tags: Command Injection RCE Sudo Abuse APT AWS-CLI Netcat stty Linux GTFObins Shell Escape
---
![banner](/secnotes/assets/img/zapas/banner.png)

Este laboratorio pone a prueba nuestra capacidad para identificar vulnerabilidades web y explotar configuraciones inseguras en el sistema operativo Linux. El reto nos lleva a través de una cadena de ataque que comienza con una inyección de comandos en un formulario de autenticación y culmina con el compromiso total del sistema aprovechando permisos excesivos en herramientas administrativas comunes.

Comenzamos con la fase de reconocimiento con la herramienta **auto-recon** esta nos hará un escaneo automatizado de puertos, servicios y versiones y directorios web

![img1](/secnotes/assets/img/zapas/recon.png)

![img2](/secnotes/assets/img/zapas/recon2.png)

El resultado nos muestra servicio SSH y WEB disponibles, al no tener ninguna credencial vamos a destartar el servicio SSH de momento.
Al acceder al servicio WEB nos encontramos con una página de venta de zapatillas.

![img3](/secnotes/assets/img/zapas/zapas.png)

No encontramos mayor información al navegar por ella. El siguiente paso será realizar un escaneo de directorios de manera mas profunda, la idea es agregar mas extensiones en la busqueda.

En este caso buscaremos extensiones **.html, .php, .txt, .py, .sh, .log**

![img4](/secnotes/assets/img/zapas/directorios.png)

Esta nueva búsqueda nos muestra otras rutas disponibles, de estas llama la atención _testimonial.html_, _nike.php_, y obviamente _login.html_

![img5](/secnotes/assets/img/zapas/nikephp.png)

Aquí solo tenemos un listado de las zapatillas.

![img6](/secnotes/assets/img/zapas/testimonial.png)

En esta solo un par de testimonios.. que consideraré para mejorar mis habilidades de hackeo...

![img7](/secnotes/assets/img/zapas/login.png)

y finalmente el logín. Este parece simple, pero tiene un script que nos ayudará a acceder al servidor.

![img8](/secnotes/assets/img/zapas/script.png)

Voy a explicar la parte importante del script encontrado.

`document.getElementById("loginForm").addEventListener("submit", function(event) {
    event.preventDefault();` 

Esta función "escucha" cuando queremos enviar el formulario de inicio de sesión, y evita que la página se recargue de forma convencional. En su lugar, el script toma el control total de los datos.

`var username = document.getElementById("username").value;
var password = document.getElementById("password").value;` 

En este apartado, el script captura el texto que escribimos en las cajas de usuario y contraseña. El fallo aquí es que no existe validación. Cualquier cadena de texto se almacena en estas variables (incluyendo comandos)

`xhr.open("GET", "run_command.php?username=" + encodeURIComponent(username) + "&password=" + encodeURIComponent(password), true);
xhr.send();`

Aquí el script envía una solicitud GET al archivo **run_command.php**, pasa el contenido de username y password directamente a la URL. Como consecuencia el servidor es vulnerable a **Command Injection**

Sabiendo todo esto, debemos validar si funciona de verdad. Bastará con escribir un comando en la caja de contraseña y verificar si el servidor lo ejecuta.

![img9](/secnotes/assets/img/zapas/commandinjection.png)

Aquí ejecutamos el comando `id` y efectivamente el servidor nos devuelve el resultado. Ahora lo intentaremos con una reverse shell para ganar el acceso.

![img10](/secnotes/assets/img/zapas/reverse-shell.png)

y ganamos el acceso. En este paso lo primero que debemos hacer es buscar usuarios válidos en el sistema.

![img11](/secnotes/assets/img/zapas/usuarios.png)

Para trabajar mas cómodos realizaremos un tratamiento de la shell para ganar estabilidad y funcionalidad.

para esto:

`python3 -c 'import pty; pty.spawn("/bin/bash")'` (Engañamos al sistema para que crea que hay un usuario real interactuando con la terminal, permitiendo comandos como `sudo`)

suspendemos con ctrl+z, y ejecutamos `stty raw -echo; fg`. Con esto configuramos nuestra máquina para que pase cada pulsación de tecla directamente a la red, sin procesarla directamente. Esto permite que señales como Ctrl+C o el TAB lleguen a la terminal de la víctima.

y finalmente `export TERM=xterm-256color` Con esto permitimos que la terminal tenga colores y que aplicaciones de texto utilicen toda la pantalla.

despues lanzar `reset` en la terminal ya tendremos la terminal operativa.

Navegando por los directorios de los usuarios que encontramos, vemos una nota de uno de ellos. 

![img12](/secnotes/assets/img/zapas/nota.png)

En el directorio del usuario **proadida** encontramos la user flag, pero no tenenos los permisos suficientes para leerlos.

También encontramos un archivo muy importante en el directorio _/opt_. Iniciamos un servidor local en la víctima y nos transferiremos el archivo a nuestra máquina para poder trabajar en él.

![img13](/secnotes/assets/img/zapas/http-server.png)

Al intentar descomprimir el archivos que transferimos desde la máquina víctima este nos pide una contraseña. Suerte que hemos visto el procedimiento necesario para crackearla con **JohnTheRipper** en laboratorios recientes.

![img14](/secnotes/assets/img/zapas/crackzip.png)

![img15](/secnotes/assets/img/zapas/jhon-the-ripper.png)

Ya tenemos la contraseña del archivo , procedemos a descomprimir y ver que nos encontramos.

![img15](/secnotes/assets/img/zapas/unzip.png)

Contraseña del usuario **pronike** obtenida...

![img16](/secnotes/assets/img/zapas/pronike.png)

Gracias al tratamiento de la shell pudimos cancelar el servidor local y cambiar de usuario sin perder la reverse shell.

Luego de un rato navegando por los directorios de este usuario no encontramos nada más. Así que verificamos si extiste algún permiso mal configurado para explotar.

![img17](/secnotes/assets/img/zapas/apt.png)

Tenemos disponible **apt** pero no como usuario root, sino que como el usuario **proadidas**. Según **GTFObins** 

![img18](/secnotes/assets/img/zapas/gtfobins.png)

Luego de una larga investigación y lectura, encontramos que la manera de hacer el movimiento lateral explotando este binario es con el comando:

`sudo -u proadidas /usr/bin/apt changelog apt`

luego debemos ejecutar `!/bin/bash`

> El alma de este blog es enseñar que hace cada comando, no solo copiar y pegar. Así que a continuación de explicación del paso anterior.

El binario _/usr/bin/apt_ tiene sub comandos diseñados para mostrar grandes cantidades de texto como **changelog**

Cuando solicitamos un changelog, **apt** invoca automáticamente un programa paginador (comunmente _less_) para facilitar la lectura.
Debido a que apt se lanza con _sudo -u proadidas_, el paginador herera esos privilegios. Si el paginador permite la ejecución de comandos externos, podemos escapar de él hacia una shell.

Una vez dentro del visor de texto, se aprovechó la funcionalidad de _less_ para ejecutar comandos del sistema anteponiendo el simbolo **!**

Como resultado el paginador generó un proceso hijo de bash con el UID de proadidas, obteniendo así una shell de este usuario.

![img19](/secnotes/assets/img/zapas/aproadidas.png)

Ahora hacemos el mismo procedimiento con este usuario, no encontramos nada en sus directorios y revisando los permisos encontramos que podemos lanzar aws como usuario root.

![img20](/secnotes/assets/img/zapas/aws.png)

Aquí el procedimiento es igual al usuario anterior. aprovecharemos el paginador para realizar la escala de privilegios

![img22](/secnotes/assets/img/zapas/escalada1.png)

![img23](/secnotes/assets/img/zapas/escalada2.png)

y al ejecutar `!/bin/bash` ganamos acceso como el usuario root.

![img24](/secnotes/assets/img/zapas/root.png)

![img25](/secnotes/assets/img/zapas/flags.png)

_archivo sudoers_

![img26](/secnotes/assets/img/zapas/sudoers.png)













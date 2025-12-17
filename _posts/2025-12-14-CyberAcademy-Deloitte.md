---
layout: post
title: "Deloitte - CyberAcademy - Linux - CTF"
date: 2025-12-14
img: /assets/img/deloitte2/banner.png
---

![img1](/secnotes/assets/img/deloitte1/3.png)

El resultado del escaneo nos muestra que el servicio FTP cuenta con acceso como anomymous, 
esto nos indica que podemos ingresar a este servicio como usuario anónimo y sin necesidad de ingresar una contraseña.

![img2](/secnotes/assets/img/deloitte1/4.png)

con el comando `get` **flag.txt** podemos descargar el archivo a nuestra máquina, y así poder leer la primera flag.

![img3](/secnotes/assets/img/deloitte1/5.png)

Continuamos con un escaneo de directorios sobre el servicio web (puerto 80). Para esto utilizaremos la herramienta nmap junto al script http-enum, la cual hará un escaneo al objetivo con un diccionario integrado en él.

![img4](/secnotes/assets/img/deloitte1/6.png)

el resultado nos muestra una ruta interesante **/robots.txt** y **/uploads**

![img5](/secnotes/assets/img/deloitte1/7.png)

En la ruta **robots.txt** con encontramos con el texto **"disallow"** esto es una instrucción que el archivo robots utiliza para impedir que rastreadores web accedan a páginas o secciones designadas de un sitio web. 
En este caso **/cyberacademy**
Al ingresar encontramos nuestra segunda flag

![img6](/secnotes/assets/img/deloitte1/8.png)

En la página principal encontraremos 3 links.

![img7](/secnotes/assets/img/deloitte1/9.png)

Antes de visitarlos realizaremos una inspección a la pagina principal.
con la combinación de teclas **ctrl + u** veremos el código de la página. Aquí encontraremos la tercera flag.

![img8](/secnotes/assets/img/deloitte1/10.png)

Ingresamos a **Bypass_Login_1** aquí nos pedirán credenciales para iniciar. Estas no las tenemos, así que igual que el caso anterior inspeccionaremos la página 

![img9](/secnotes/assets/img/deloitte1/11.png)

Aquí nos encontramos con una función que toma el valor ingresado por el usuario en el login y lo compara con los valores del la función. si son incorrectos mostrará una alerta de que el usuario o contraseña son incorrectos

 ![img10](/secnotes/assets/img/deloitte1/12.png)
esta función nos da el usuario **"admin"** y la contraseña **"supersecret"**, al ingresar estos datos nos darán nuestra cuarta flag

![img11](/secnotes/assets/img/deloitte1/13.png)


En el **login_2** nos solicitarán nuevamente credenciales, probamos con las anteriores y nos muestra un error del servidor

![img12](/secnotes/assets/img/deloitte1/14.png)

al revisar la información que se envía al servidor por parte del cliente, la aplicación nos concederá el acceso únicamente por la presencia de la cabecera Authorization, sin validar el contenido de esta ni las credenciales asociadas, lo que permite el acceso al sistema sin autenticación real. 
Cambiaremos el contenido de la cabecera y modificaremos el método **GET** a **FAIL**, aquí el servidor no interpretará el valor FAIL como fallo, sino que intepretará el ingreso por el camino equivocado de la lógica. 
En pocas palabras el servidor no verifica quienes somos, solo si decimos que tenemos autorización. 

![img13](/secnotes/assets/img/deloitte1/15.png)

Al enviar la solicitud obtenemos la quinta flag. 

![img14](/secnotes/assets/img/deloitte1/16.png)

El tercer link nos envía a ping, una aplicación que nos dice que podemos enviar un ping a una ip que se introduzca en el navegador

![img15](/secnotes/assets/img/deloitte1/17.png)

Ingresamos el ejemplo y efectivamente el servidor hace un ping al localhost (127.0.0.1)

![img16](/secnotes/assets/img/deloitte1/18.png)

Podemos intentar concatenar comandos y ver si el servidor es vulnerable a **RCE** (remote code execution)

![img17](/secnotes/assets/img/deloitte1/19.png)

Efectivamente podemos enviar mas de un comando el navegador. Asi que listaremos archivos aprovechando esta vulnerabilidad

![img18](/secnotes/assets/img/deloitte1/20.png)

Obtenemos nuestra sexta flag

Ya que podemos lanzar comandos desde el navegador, buscaremos algo interesante en los directorios.

![img19](/secnotes/assets/img/deloitte1/21.png)

Encontramos la séptima flag 

![img20](/secnotes/assets/img/deloitte1/22.png).

también nos encontramos con **james**, al usar el comando `file` sobre él, nos dice que tiene un enlace simbólico roto hacia la ruta **/opt**

![img21](/secnotes/assets/img/deloitte1/23.png)

Ingresamos a esta ruta y nos encontramos una flag con una cadena de texto cifrada, por los caracteres que contiene, podemos asumir que es base64

![img22](/secnotes/assets/img/deloitte1/24.png)

Decodificamos y así obtenemos nuestra octava flag

![img23](/secnotes/assets/img/deloitte1/25.png)

Volviendo atrás en la ruta **/uploads** encontramos la novena flag 

![img24](/secnotes/assets/img/deloitte1/45.png)

En este punto solo nos queda la última flag, la correspondiente al usuario root. El siguiente paso será identificar la versión de Linux de la máquina vívtima, aprovechando la vulnerabilidad de RCE vamos a utilizar el comando `uname -a` para que el servidor nos muestre esta información.

![img25](/secnotes/assets/img/deloitte1/26.png)

la versión encontrada es la 4.4, en esta versión de Linux es muy común encontrar **/bin/bash**, **nc**, **Python**, **Python2** o **perl**.
Con el comando `which bash` buscaremos si está disponible en el objetivo

![img26](/secnotes/assets/img/deloitte1/27.png)

Confirmando que existe, nos crearemos una Reverse Shell para conectarnos al servidor.

![img27](/secnotes/assets/img/deloitte1/28.png)

una vez conectados buscaremos vulnerabilidades relacionadas con la versión del kernel de la máquina víctima.

![img28](/secnotes/assets/img/deloitte1/29.png)

![img29](/secnotes/assets/img/deloitte1/30.png)

![img30](/secnotes/assets/img/deloitte1/31.png)

Según el resultado de searchsploit encontramos que esta versión tiene una vulnerabilidad asociada al CVE-2017-16995.
sabiendo esto vamos a descargar el exploit, lo compilaremos y lo vamos a enviar a la máquina víctima y así escalar privilegios.
Desde nuestra máquina vamos a crear un contenedor de Docker con una imagen de la misma versión de Linux a la que vamos a atacar, esto por que necesitamos compilar el exploit descargado. Si lo hacemos directamente en nuesto sistema operativo el binario del exploit queda ligado a la versión del SO, la versión del GLIBC, arquitectura y algunas opciones del compilador. 
En pocas palabras es similar a crear un programa para Windows 11 y tratar de ejecutarlo en Windows XP, el archivo existe, pero el sistema no entiende las instrucciones modernas.
Ya con el contenedor inciado y el exploit en el, vamos a compilarlo y enviarlo a la máquina víctima.

![img31](/secnotes/assets/img/deloitte1/37.png)

![img31](/secnotes/assets/img/deloitte1/38.png)

![img32](/secnotes/assets/img/deloitte1/39.png)
Levantamos un servidor con **python3** en nuestra máquina atacante, y desde la máquina víctima descargamos el exploit compilado. Una vez terminado, le damos permisos de ejecución y lo iniciamos, al completarse obtendremos una Shell como root.
Ahora solo nos queda navegar al directorio root y obtener la última flag.

![img33](/secnotes/assets/img/deloitte1/10flag.png)













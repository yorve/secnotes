---
layout: post
title: "Influencer - Dockerlabs - Linux - Fácil"
date: 2026-02-01
img: /assets/img/influencer/1.png
---

![img1](/secnotes/assets/img/influencer/1.png)

En este laboratio pondremos a prueba los ataques de fuerza bruta contra distintos servicios.

Para la fase de reconocimiento, utilizaremos un script que arme para estos labotarios.

> https://github.com/yorve/Auto-Recon

Este nos ayudará para automatizar la fase de reconocimientos de puertos, servicios, escaneo de directorios web y otros.

![img1](/secnotes/assets/img/influencer/objetivo.png)

Ingresamos los datos solicitados, Esta herramienta creará un directorio de trabajo, en el cual se exportarán los datos encontrados.

![img2](/secnotes/assets/img/influencer/script.png)

La primera etapa nos muestra un escaneo de puertos y servicios detectados.

![img3](/secnotes/assets/img/influencer/servicios.png)

La segunda etapa nos muestra información sobre el servicio web

![img4](/secnotes/assets/img/influencer/web.png)

Una vez finalizado, el resultado nos muestra información por donde empezar.
Vemos que el servicio web contiene *401 Unauthorized*, Esto nos indica que el objetivo tiene un mecanismo de autenticación y que el servidor responde correctamente.
*WWW-Authenticate: Basic*, indica que el usuario y contraseña se envían en `Authorization: Basic base64(user:pass)`, no existe hash ni tokens, esto lo hace vulnerable a ataques de fuerza bruta.

![img5](/secnotes/assets/img/influencer/directorios.png)

El escaneo de directorios no se inicio, esto ocurre por que el objetivo pide pasar la primera autenticación para seguir.

![img6](/secnotes/assets/img/influencer/web1.png)

efectivamente al ingresar por el navegador, este nos pide igresar las credenciales al acceder. 

![img7](/secnotes/assets/img/influencer/curlget.png)

Al inspeccionar la página con la herramienta curl, se confirma que el sitio utiliza HTTP Basic Authentication.
Este mecanismo no corresponde a un formulario HTML, sino que a una autenticación a nivel de protocolo HTTP, donde el navegador incluye las credenciales en la cabecera. 

*Authorization: Basic base64(usuario:contraseña)*

La autenticación HTTP Bascis es independiente del método HTTP utilizado (GET o POST). En este caso, el acceso inicial al recurso protegido se realiza mediante peticiones GET, razón por la cual el servidor responde con el código 401 Unauthorized cuando no se incluyen credenciales válidas. 

Ya con los datos anteriores, vamos a intentar un ataque de fuerza bruta con la herramienta hydra.

![img8](/secnotes/assets/img/influencer/fuerzabruta1.png)

Utilizamos el argumento -C (combo) y el diccionario de usuarios y contraseña que contengan el formato *user:pass* (admin:admin, root:root, etc)
Obtenemos las credenciales del usuario httpadmin.

![img9](/secnotes/assets/img/influencer/login1.png)

Una vez ingresadas las credenciales encontradas, no tenemos nada (aparentemente), pero esto nos da pie para realizar un escaneo de directorios con la herramienta gobuster utilizando las credenciales obtenidas en el ataque de fuerza bruta.

![img10](/secnotes/assets/img/influencer/gobuster1.png)

En este escaneo encontramos una ruta a /login.php, aquí nos encontramos con otro panel de login.

![img11](/secnotes/assets/img/influencer/login2.png)

Tenemos una doble autenticacion encadenada. Esto significa que primero se debe pasar la primera barrera (Basic Auth) y pasar por la segunda.

![img12](/secnotes/assets/img/influencer/login3.png)

Utilizamos nuevamente gobuster para hacer la misma verificación anterior, esta vez debemos utilizar las credenciales encontradas para pasar la primera barrera y luego hacer la petición por método POST con credenciales de prueba y así ver la respuesta que entrega el servidor.
en este caso el mensaje de *Credenciales Incorrectas*. 

![img13](/secnotes/assets/img/influencer/login4.png)

Entonces, el formulario tiene método POST, el servidor procesa estos parámetros y devuelve un mensaje de error dependiendo del contenido envíado, y el POST funciona solo despues de pasar al Basic Auth.
vamos a realizar otro ataque de fuerza bruta, ahora sobre el segundo login.

![img14](/secnotes/assets/img/influencer/fuerzabruta2.png)

Aqui utilizamos hydra con el usuario *admin* (corazonada) con el diccionario *Rockyou*, el método *http-post-form* para indicarle que es método POST, ya que los parámetros van en el cuerpo del request.
y la cadena `/login.php:username=^USER^&password=^PASS^:H=Authorization: Basic aHR0cGFkbWluOmZodHRwYWRtaW4=:F=Credenciales incorrectas.`

`H=Authorization: Basic aHR0cGFkbWluOmZodHRwYWRtaW4=`   Este valor son las credenciales en base64 (lo mismo que hace el request)

Esto es por que hydra se autentica contra el primer login (primera barrera), así podemos llegar al segundo login.
El ataque se basó en la detección del mensaje de error “Credenciales incorrectas”, permitiendo identificar credenciales válidas cuando ese mensaje no aparecía en la respuesta.

Ahora tenemos las credenciales del usuario admin

![img15](/secnotes/assets/img/influencer/usuario.png)

al ingresar estas credenciales solo nos muestra un mensaje y un usuario. Ahora nuestro enfoque será en el servicio SSH.
Utilizaremos hydra nuevamente con este nuevo usuario. 

![img16](/secnotes/assets/img/influencer/ssh.png)

Obtenemos la contraseña para este nuevo usuario.

Con la sesion de este usuario activa, buscamos distintas formas para escalar privilegios, pero este usuario no tenia permisos suficientes para hacer algo..

![img17](/secnotes/assets/img/influencer/ssh1.png)

![img18](/secnotes/assets/img/influencer/ssh2.png)

ya que tenemos disponible scp, vamos a pasar de nuestra máquina atacante el script de LinEnum para escanear alguna vulnerabilidad.

![img19](/secnotes/assets/img/influencer/ssh3.png)

pero, esta no nos ayudó a completar nuestro objetivo. Buscando mas información nos encontramos con un script que nos permitirá realizar un ataque de fuerza bruta interno contra el usuario root.

> https://github.com/D1se0/suBruteforce/blob/main/suBruteforceBash/suBruteforce.sh

copiamos el código y nos creamos el script en la máquina víctima, y con la herramienta scp nos pasamos el diccionario rockyou a la máquina víctima.

![img20](/secnotes/assets/img/influencer/ssh4.png)

y al ejecutarlo nos dará la contraseña de root

![img21](/secnotes/assets/img/influencer/root.png)

y podemos cambiarnos al usuario root

![img22](/secnotes/assets/img/influencer/root1.png)

En un entorno real, los ataques de fuerza bruta locales contra el binario su no suelen ser viables debido a las protecciones implementadas por PAM.
Sin embargo, en este laboratorio, dichas protecciones han sido debilitadas intencionadamente, permitiendo la automatización de intentos contra el usuario root.
Aprovechando esta configuración insegura, fue posible realizar un ataque de fuerza bruta interno y obtener la contraseña del usuario root.


 




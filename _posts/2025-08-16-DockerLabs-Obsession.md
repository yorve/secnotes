---
layout: post
title: "Obsession - Dockerlabs - Linux - Fácil"
date: 2025-08-16
img: /assets/img/obssesion/1.png
---

En este laboratorio nos enfrentamos a un reto de nivel fácil, orientado a poner en práctica técnicas básicas de enumeración, explotación y escalada de privilegios en un entorno Linux.

El objetivo consiste en descubrir servicios expuestos, identificar usuarios válidos y obtener acceso inicial a la máquina mediante un ataque de diccionario. Posteriormente, aprovecharemos configuraciones de sudo que permiten la ejecución de programas como root para lograr la elevación de privilegios y, finalmente, acceder a los archivos más sensibles del sistema

**Enumeración** 

Comenzamos con un escaneo a los puertos de la máquina objetivo, con el fin de enumerar sus servicios dispoibles.

 ![img2](/secnotes/assets/img/obssesion/2.png)


Seguimos con un escaneo a las versiones de los servicios encontrados y verificaricamos si existe alguna vulnerabilidad conocida de ellos.

![img3](/secnotes/assets/img/obssesion/3.png)
 

En el servicio FTP tenemos acceso como _Anonymous_, esto significa que podemos ingresar a los directorios de la máquina sin necesidad de credenciales. Además nos lista dos archivos .txt 
Una vez dentro de la máquina utilizaremos el comando `get` para descargarnos en nuestra máquina los archivos listados.
 
![img4](/secnotes/assets/img/obssesion/4.png)


Vemos el archivo chat-gonza.txt 

![img5](/secnotes/assets/img/obssesion/5.png)
 
Y el archivo pendientes.txt

![img6](/secnotes/assets/img/obssesion/6.png)
 
Aquí podemos obtener dos posibles usuarios llamados _Gonza_  y _Russoski_.

Revisamos si en el servicio web existe algo de interés, al inspeccionar y ver el código fuente no encontramos nada de interés, así que realizaremos un escaneo con **Gobuster** en busca de algún directorio existente.
 
![img7](/secnotes/assets/img/obssesion/7.png)

![img8](/secnotes/assets/img/obssesion/8.png) 

Efectivamente nos encontramos dos rutas en donde podríamos encontrar información de valor.
En la primera ruta _/important_ nos encontramos con un archivo .md, estos son archivos de texto en formato markdown, normalmente se usas para escribir documentos fáciles de leer en texto plano y se pueden convertir a HTML u otros formatos.
 
![img9](/secnotes/assets/img/obssesion/9.png)

 ![img10](/secnotes/assets/img/obssesion/10.png)

 
En la ruta _/backup_, encontramos un archivo de texto que nos confirma que un usuario válido es russoski

![img11](/secnotes/assets/img/obssesion/11.png)

![img12](/secnotes/assets/img/obssesion/12.png) 

**Explotación**

Ya tenemos un usuario válido y el servicio SSH disponible. Como no conocemos la contraseña podemos hacer un ataque de diccionario. Para este caso utilizaremos el diccionario rockyou

![img13](/secnotes/assets/img/obssesion/13.png)

**Desglose del comando** 

`172.17.0.2` -  la IP de la máquina objetivo. 

`ssh` -  servicio al que atacar.

`-l russoski` - usuario fijo al que Hydra intentará entrar.

`-P /usr/share/wordlists/rockyou.txt` - diccionario de contraseñas 

`-t 64` - número de hilos simultáneos (64 intentos paralelos. Esto realiza el ataque más rápido, pero más ruidoso)

 ![img14](/secnotes/assets/img/obssesion/14.png)

Con el diccionario usuario encontramos la contraseña del usuario. 
Ya tenemos las credenciales, ahora podremos acceder por el servicio SSH a la máquina objetivo.

![img15](/secnotes/assets/img/obssesion/15.png)
 
Navegando por los directorios no encontramos nada de interés. Solo un script de Python que nos genera una contraseñas.

![img16](/secnotes/assets/img/obssesion/16.png)
 
Al ejecutar el script nos genera una contraseña.

![img17](/secnotes/assets/img/obssesion/17.png) 

**Elevación de privilegios**

Ya que no tenemos acceso al directorio root con el usuario _russoski_, veremos que podemos ejecutar. Para esto utilizaremos el comando `sudo -l`

![img18](/secnotes/assets/img/obssesion/18.png)
 
Esto nos indica que podemos usar vim con permisos de root sin necesidad de ingresar una contraseña.
Vim es un editor de texto avanzado (como nano, joe, Emacs, etc)
En **gtfobins** encontramos que podemos elevar privilegios con un comando. 

![img19](/secnotes/assets/img/obssesion/19.png) 

![img20](/secnotes/assets/img/obsession/20.png)

Ejecutamos el primer comando (a) y obtenemos acceso como root

![img21](/secnotes/assets/img/obssesion/21.png)
 
Ahora solo navegamos por los directorios en búsqueda del famoso video.

![img22](/secnotes/assets/img/obssesion/22.png)


![img23](/secnotes/assets/img/obssesion/23.png)

:heart_eyes:
 
 
 

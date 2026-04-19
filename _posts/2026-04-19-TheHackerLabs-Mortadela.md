---
layout: post
title: "Mortadela - Hackerlabs - Linux "
date: 2026-04-16
img: /assets/img/mortadela/banner.png
tags: [tags: [HackerLabs, Writeup, Linux, SQLi, WPScan, JohnTheRipper, KeePass, MemoryForensics, CVE-2023-32784, PrivEsc]
---

En este laboratorio nos enfrentamos a un escenario de post-explotación avanzado. Tras obtener acceso inicial y recolectar archivos confidenciales, el desafío se centró en la exfiltración de datos protegidos por una base de datos KeePass y un contenedor ZIP cifrado

Empezamos con la fase de reconocimiento, y como hemos visto en los laboratorios anteriores, utilizaremos la herramienta Auto-recon para realizar los escaneos de forma automatizada.

![img1](/secnotes/assets/img/mortadela/reconocimiento.png)

![img2](/secnotes/assets/img/mortadela/reconocimiento2.png)

![img3](/secnotes/assets/img/mortadela/reconocimiento3.png)

Adicionalmente vamos a hacer un escaneo de directorios web

![img4](/secnotes/assets/img/mortadela/gobuster.png)

Podemoss observar que tenemos WordPress en él, así que utilizaremos la herramienta wpscan para obtener más información y enumerar usuarios válidos.

`wpscan --url <host>/wordpress --enumerate u`

Con este comando wpscan utiliza ataques pasivos y activos contra la esctructura de WordPress. Así puede recopilar información útil.

![img5](/secnotes/assets/img/mortadela/wpscan.png)

![img6](/secnotes/assets/img/mortadela/wp-user.png)

Encontramos un usuario llamado *mortadela*

Luego de realizar múltiples intentos de ataques de diccionario contra WordPress y sql con el usuario **mortadela** no pudimos dar con la contraseña, sin embargo, con la herramienta hydra pudimos dar con ella para el usuario **root** de la base de datos sql

![img7](/secnotes/assets/img/mortadela/hydra-root.png)

Con estas credenciales de la base de datos sql, el siguiente paso es ingresar y buscar información de interés.

![img8](/secnotes/assets/img/mortadela/sql.png)

Una vez dentro, listamos la base de datos, y aquí nos encontramos dos datos interesantes.

![img9](/secnotes/assets/img/mortadela/databases.png)

La primera, el usuario de wordpress y su hash. (podría servirnos para después)

![img10](/secnotes/assets/img/mortadela/sqlwpuser.png)

La segunda en la db **confidencial**, nos encontramos unas credenciales del usuario **mortadela**. 

![img11](/secnotes/assets/img/mortadela/confidencial.png)

![img12](/secnotes/assets/img/mortadela/user.png)

Con estas credenciales probaremos entrar via ssh a la máquina víctima.

![img13](/secnotes/assets/img/mortadela/ssh.png)

Obtenemos un acceso exitoso, estando aquí deberemos buscar información de interés.

listamos y encontramos la flag de usuario

![img14](/secnotes/assets/img/mortadela/user-flag.png)

Buscando en los directorios, en la ruta _/opt_ nos encontramos con un archivo llamado **muyconfidencial.zip**, primeramente intentamos descomprimir el archivo, pero nos pide una contraseña para decomprimir.

![img15](/secnotes/assets/img/mortadela/unzip.png)

En el resto de directorios no encontramos nada de interés. Así que nuestra meta sera crackear la contraseña de este archivo comprimido. Para lograrlo utilizaremos la herramienta **John The Ripper**.

Pero antes de esto deberemos obtener el archivo zipeado a nuestra máquina atacante, ya que tendremos mayor control solo herramientas necesarias para trabajar con el archivo. Como sabemos, en la máquina víctima tenemos disponible Python3, iniciaremos un servidor y nos transferiremos el archivo a nuestra máquina mediante **wget**

![img16](/secnotes/assets/img/mortadela/wget.png)

Ya con el arcivo en nuestro poder vamos a utilizar **zip2john** para extraer el hash y romperlo con john. Para esto:

`zip2john muyconfidencial.zip > hashzip` 

**zip2john** es una herramienta de john the ripper diseñada para extraer el hash de la clave de cifrado de un archivo **PKZIP**. Lo que hace es leer la cabecera del archivo compimido y lo transforma en un formato que John pueda entender.
con el redireccionamiento "> hashzip", guardamos esa firma criptográfica en un archivo para poder procesarlo.

ahora con john vamos a romper el hash del arcvhivo zip 

`john --wordlist=<rockyou>`

![img17](/secnotes/assets/img/mortadela/crackeozip.png)

El resultado nos dio **pinkgirl**, con esta contraseña ya podemos aplicar **unzip** sobre el archivo y conocer su contenido.

![img18](/secnotes/assets/img/mortadela/zip.png)

Vemos que tenemos el archivo llamado **Database.kdbx**, para ver el contenido de esta base de datos debemos utilizar la herramienta **Keepasxc**. 

![img19](/secnotes/assets/img/mortadela/keepass.png)

![img20](/secnotes/assets/img/mortadela/keepass1.png)

no es sorpresa que al abrir esta base de datos nos soliciten una contraseña para acceder... 

Dentro del archivo comprimido existe otro archivo llamado **KeePass.DMP**, este corresponde al volcado de memoria (memory dump) del proceso de KeePass. Buscando vulnerabilidades, nos encontramos con la **CVE-2023-32784**  que nos dice que existe un fallo de seguridad que permite recuperar la contraseña maestra en texto plano (a exepción del primer caracter) debido a que KeePass dejaba residuos de las cajas de texto en la memoria RAM del sistema. Aunque la base de datos .kdbx esté cifrada con AES, si tenemos acceso a un volcado de memoria de cuando la base de datos estaba abierta o en uso, podemos reconstruir la llave maestra analizando los artefactos ded las cadenas de caracteeres.

con la herramienta keepassdumper vamos a ver este archivo de volcado de memoria.

![img21](/secnotes/assets/img/mortadela/keepassdumper.png)

![img22](/secnotes/assets/img/mortadela/keepassdumper1.png)

![img23](/secnotes/assets/img/mortadela/bd.png)

**KeePass-Password-Dumper**

Este es un script que automatiza la búsqueda de patrones especificos en archivos .dmp. El script escanea el volcado de memoria en busca de secuencias de caracteres que coincidan con la estructura de entrada de KeePass.

Como observamos en el resultado, el script nos entregó una cadena con caracteres confirmados. Pero debido a como funciona la vulnerabilidad, el primer carácter no se puede recuperar automáticamente, por lo que debemos deducirlo. luego de varios intentos dimos que este carácter era una M


![img24](/secnotes/assets/img/mortadela/bd.png)

En la base de datos, tenemos unas credenciales de un usuario root 

![img25](/secnotes/assets/img/mortadela/root.png)

con esto solo nos queda probar estas credenciales en el servicio ssh

![img26](/secnotes/assets/img/mortadela/acceso-root.png)

https://labs.thehackerslabs.com/machines/59












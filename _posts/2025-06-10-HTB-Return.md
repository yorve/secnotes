---
---
![banner](/assets/img/return/return.png)

#1.- Reconocimiento
## escaneo inicial
---
![img1](secnotes/assets/img/return/1.jpg)
![img2](/assets/img/return/2.png)

Con esta información sabemos que nos encontramos ante una
máquina Windows y enumeramos los puertos para verificar que
servicios corren en ellos.

![img3](/assets/img/return/3.png)

---
#2.- Enumeración
---

Al revisar el servicio web nos encontramos con un panel de
una impresora a la cual podemos acceder a la configuración
de esta. 

![img4](/assets/img/return/4.png)

Aquí nos encontramos con un usuario llamado “svc-printer”

![img5](/assets/img/return/5.png)

Al inspeccionar el código de la página no encontramos información importante. 
Con la herramienta “enum4linux” realizaremos un escaneo, esta se utiliza para enumerar información de sistemas Windows a través del protocolo SMB (puerto 445) y RPC (puerto 135).  Este escaneo permite obtener información sin necesidad de credenciales.

Este escaneo podría enumerar:
•	Usuarios de dominio
•	Grupos y miembros
•	Shares Compartidos (SMB)
•	Políticas de contraseñas
•	Controlador de dominio
•	Arquitectura y versión del sistema
•	Políticas de bloqueo de cuentas
•	Servicios del sistema
•	computadores conectados al dominio

![img6](/assets/img/return/6.png)

Con esta herramienta encontramos algo de información.
•	Dominio NetBIOS: RETURN
•	Dominio DNS: return.local
•	SID del dominio: S-1-5-21-3750359090-2939318659-876128439
•	Controlador de dominio: printer.return.local
•	Nombre del host: PRINTER
•	Sistema operativo identificado: Windows Server 2019 (Build 17763)
•	SMBv1: deshabilitado
•	SMB Signing: requerido (firmas obligatorias en sesiones SMB)
•	Servicios expuestos: LDAP (389), LDAPS (636), SMB (445), NetBIOS (139)

![img7](/assets/img/return/7.png)

Este panel de administración de la impresora permite configurar un servidor LDAP externo al cual se conectaría una impresora para autenticarse o consultar usuarios. Estos paneles tienen los campos vistos
•	Server Address / IP
•	LDAP Port
•	Blin Dn / Ususario LDAP
•	Password

---
3.- Explotación
---

En el panel de configuración pondremos nuestra IP en el Server Address y pondremos en nuestra máquina el puerto 389 en escucha. Con esto lograremos que la impresora se intente autenticar con el usuario svc-printer y su contraseña.

![img8](/assets/img/return/8.png)

![img9](/assets/img/return/9.png)

Esto funcionó por que el panel de la impresora usa una configuración de LDAP simple, y es por esto que podemos ver la contraseña en texto plano.
Ahora que tenemos un usuario, su contraseña y el servicio de winrm (administración remota de Windows) disponible, utilizaremos la herramienta “evil-winrm” para conectarnos a la máquina objetivo.

![img10](/assets/img/return/10.png)

![img11](/assets/img/return/11.png)

Y establecemos la conexión.

![img12](/assets/img/return/12.png)

Navegando por los directorios encontramos la flag de usuario

![img13](/assets/img/return/13.png)

---
4.- Escalación de privilegios.
---

Con la sesión activa por medio de evil-winrm lanzaremos el comando “net user svc-printer”, con esto podremos enumerar los grupos a los que pertenece el usuario svc-printer.

![img14](/assets/img/return/14.png)

Aquí encontramos información importante. Entre algunas es que el usuario esta en el grupo Remote Management Use. Este grupo no es tan elevado como Administrators, pero nos permite reiniciar servicios, cambiar configuraciones del sistema, entre otros.
En los sistemas de Windows hay un servicio que funciona por defecto llamado Volume Shadow Copy Service (vss). Este corre con privilegios elevados y no está protegido contra modificaciones si un usuario no tiene permisos suficientes.
Con el comando “sc.exe query vss” podemos comprobar si el servicio está instalado y detenido. Esto nos permitirá modificar el binario. 

![img15](/assets/img/return/15.png)

##BinPath hijacking##

Esta es una técnica de escalada de privilegios en sistemas Windows, que se aprovecha de como el sistema interpreta rutas de archivos mal formateadas o sin comillas. 
Cuando creamos un servicio con sc.exe o desde el registro, se le asigna una ruta binaria (binPath) que indica qué ejecutable debe correr el servicio.
Cuando la ruta contiene espacios y no está correctamente entrecomillada, windows interpreta la ruta por partes, y esto puede ejecutar un binario incorrecto si este existe.
Sabiendo esto, nos crearemos una Reverse Shell y la subiremos a la máquina víctima para establecer una conexión. Esto lo vamos a realizar con meterpreter ya que es más robusta y estable.

Nos crearemos el payload ejecutable con msfvenom

![img16](/assets/img/return/16.png)

Y lo subimos a la máquina víctima

![img17](/assets/img/return/17.png)

Ahora con Metasploit configuraremos un listener para la reverse Shell que subimos en la máquina víctima.

![img18](/assets/img/return/18.png)

![img19](/assets/img/return/19.png)

![img20](/assets/img/return/20.png)

En la sesión de evil-winrm con el comando:
sc.exe config vss binPath="C:\Users\svc-printer\Desktop\rs.exe"
Este comando configura el servicio vss para que, en vez de ejecutar el comando original, ejecute rs.exe

![img21](/assets/img/return/21.png)

![img22](/assets/img/return/22.png)

Ahora debemos migrar a un proceso con privilegios de SYSTEM, ya que la sesión que creamos se cierra al cabo de unos minutos. Para esto utilizamos el comando “ps” cuando obtengamos la sesión y buscamos un proceso que se ejecute como NT AUTHORITY\SYSTEM  

![img23](/assets/img/return/23.png)

Con el comando “migrate “y el PID obtendremos más estabilidad.
Luego abrimos una Shell y ya tendremos un acceso completo con todos los privilegios a la máquina.

![img24](/assets/img/return/24.png)

Ahora solo nos queda encontrar la flag correspondiente.

![img25](/assets/img/return/25.png)


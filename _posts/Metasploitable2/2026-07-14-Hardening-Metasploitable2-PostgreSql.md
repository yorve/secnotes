---
layout: metasploitable2-post
title: "postgreSQL"
date: 2026-07-14 09:05:00 -0400
img: /assets/img/metasploitable2/banner.png
tags: [Vuln, Linux, Hardening, postgreSQL, root, Metasploitable 2 ]
---


Este es el canal de comunicación predeterminado que utiliza el motor de bases de datos **PostgreSQL**. Al igual que en MySQL, este permite que aplicaciones, servidores web y herramientas de administración se conecten a la base de datos para gestionar la información.

![](/secnotes/assets/img/metasploitable2/5432/22d0052a77f8689c2460ade6892c1571_MD5.jpg)

El cliente nativo de PostgreSQL en kali se llama `psql`. A diferencia de MySQL, el protocolo de PostgreSQL requiere que definamos explícitamente a qué la base de datos queremos conectarnos inicialmente. Ya que no sabemos cuales existen, utilizaremos la que trae por defecto llamada `postgres`. También utilizaremos el usuario `postgres` y contraseña `postgres` que trae por defecto.

![](/secnotes/assets/img/metasploitable2/5432/1b878541d7daaa6df6e75b515a365e40_MD5.jpg)

Nuevamente nos topamos con problemas de compatibilidad de versiones. Nuestro equipo cuenta con la versión `psql 18` que es de este año 2026, pero la versión de metasploitable2 corresponde al 2008.
## Extracción de información ##

Una vez que hallamos ingresado, el lenguaje cambia ligeramente respecto a MySQL. Aquí los comandos del sistema de control empiezan con una barra invertida. 

![](/secnotes/assets/img/metasploitable2/5432/e6ceb03704960ad2a0f031f21ba7444c_MD5.jpg)

![](/secnotes/assets/img/metasploitable2/5432/b14c3d4ed368ae4a14baa609cbeb6c47_MD5.jpg)

![](/secnotes/assets/img/metasploitable2/5432/c7623d492705d55111fe3606b698d688_MD5.jpg)

luego de investigar un poco, dimos con la forma de listar las tablas técnicas que empiezan con pg_. Aquí podemos ver dos interesantes, `pg_shadow y pg_user`. Siendo esta última la más importante, ya que guarda las credenciaes y los hashes de contraseña.

Para ver esta información lanzaremos el siguiente comando:

`SELECT usename, passwd, usesuper, usecreatedb FROM pg_shadow;`

![](/secnotes/assets/img/metasploitable2/5432/90d229a0feabb9d01f2cc82ec4a918ae_MD5.jpg)

Esto nos muestra los nombres de usuarios de la base de datos, sus contraseñas (en hash MD5), y si tienen privilegios de superusuario (t: significa true).

También podemos ver otro tipo de información, como el directorio donde se guardan los datos en el disco duro, o que versión exacta del motor y sistema operativo Linux corre aquí.

![](/secnotes/assets/img/metasploitable2/5432/db26517626dc55da74065dabac852819_MD5.jpg)


## Prueba máxima 

Ya que somos un superusuario, podemos intentar ver el contenido de un archivo real del sistema operativo. 

nos crearemos una tabla temporal en la memoria:

`CREATE TEMP TABLE contenido_archivo (linea text);`

Leeremos el archivo `/etc/passwd` y lo copiamos en la tabla.

`COPY contenido_archivo FROM '/etc/passwd';`

Vemos la información.

`SELECT * FROM contenido_archivo;`

![](/secnotes/assets/img/metasploitable2/5432/11f4852f8c0b30f5fffc289c9679e4ea_MD5.jpg)

## Hardening

Si estuviéramos en un entorno real, técnicamente tendríamos dos opciones:

1. Actualizar a la última versión de PostgreSQL y ganar las ventajas como el cifrado TLS/SSL, parches de seguridad y gestión de permisos avanzados. Pero esto nos suma nuevos retos, partiendo por la actualización del SO del servidor, una mitigación compleja de datos, ya que el formato que se guardan físicamente en el disco duro cambia entre versiones no es sensilla.
2. Si el servicio es obsoleto / innecesario, la mejor práctica es apagar el servicio y así reducir la superficie de ataque.

Vamos a aplicar esta segunda opción.

Detenemos el servicio de PostgreSQL 

`/etc/init.d/postgresql-8.3 stop`

Eliminamos de raíz los enlaces de arranque automático del servicio.

`update-rc.d -f postgresql-8.3 remove`

![](/secnotes/assets/img/metasploitable2/5432/e3d4e34d1446106e783d4b5cd60c09db_MD5.jpg)

![](/secnotes/assets/img/metasploitable2/5432/253bf6ae2bfaf475ea4b8068d0d45780_MD5.jpg)

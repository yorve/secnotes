---
layout: metasploitable-post
title: "Metasploitable 2 - Hardening WEB"
date: 2026-06-25
img: /assets/img/metasploitable2/banner.png
tags: [Vuln, Linux, Hardening, web, Metasploitable 2]
---
![banner]({{ site.baseurl }}/assets/img/metasploitable2/banner.png)

Este es un nuevo proyecto de Hardening para el laboratorio Metasploitable2. Este laboratorio es conocido por tener múltiples vulnerabilidades que como atacante podemos sacar provecho y comprometer la máquina. Pero esta vez nos pondrémos en los zapatos del equipo defensivo y aplicaremos configuraciones correctas para volver Metasploitable 2 una máquina segura.

**Los objetivos del proyecto serán:**

- Reducir la superficie de ataque.
- Corregir fallas de configuración.
- Implementar contramedidas.
- Validar la postura de seguridad.

**Metodología:**

- Inspección y validación de la vulnerabilidad. Remediación (Hardening).
- Validación de seguridad.
- Esta máquina tiene multiples puertos y vulnerabilidades habilitados.
- Es por eso que iremos resolviendolas por servicios por separado.

# Servicio Web #

![web]({{ site.baseurl }}/assets/img/metasploitable2/20260619161642.png)

Llegamos al servicio WEB en el puerto 80.  Aquí nmap nos encontró la siguiente información. 

![web]({{ site.baseurl }}/assets/img/metasploitable2/f067ac6416cca1a1d6d6d005d04debfd_MD5.jpg)

![web]({{ site.baseurl }}/assets/img/metasploitable2/490768bc4b279d321eae1d7d85ccbe75_MD5.jpg)

Desde la fase de reconocimiento podemos ver información crítica, como por ejemplo la versión del server **Apache/2.2.8 (Ubuntu)  DAV/2** 

![web]({{ site.baseurl }}/assets/img/metasploitable2/455b479e1baabafa9d8efc5576ad5464_MD5.jpg)

o rutas de directorios que podemos ver directamente desde el navegador.

![web]({{ site.baseurl }}/assets/img/metasploitable2/d7a20aab7cf74a6eefe4c1bd521122e2_MD5.jpg)

En este caso, para cerrarle las ventanas a este reconocimiento masivo, vamos a ocultar los Banner informativos, deshabilitar el listado de directorios y ocultar la cabecera PHP.

**Ocultar Banner** : El archivo de configuración de apache se encuentra en la ruta `/etc/apache2/apache2.conf`. Aquí deberemos agregar dos líneas de directivas al final del archivo:
	- `ServerTokens Prod`
	- `ServerSignature Off`

![web]({{ site.baseurl }}/assets/img/metasploitable2/b2b97b169490b0c6d4c8256f89d0362a_MD5.jpg)

**Deshabilitar el Listado de Directorios:** Para realizar esto, debemos modificar la línea desde `Options` quitándole la palabra `Indexes` o poniéndole el símbolo menos `-` por delante, para prohibirle a Apache listar archivos cuando falte un Index.  El archivo de configuración está en: `vim /etc/apache2/sites-available/default`

![web]({{ site.baseurl }}/assets/img/metasploitable2/585dbf3cc98787f1e99fdc017ba63a51_MD5.jpg)

Nmap también nos reportó que los directorios `/doc/` y `/dav/` también listaban archivos de forma vulnerable. Para estos debemos repetir el procedimiento.

![web]({{ site.baseurl }}/assets/img/metasploitable2/6267103d5546be112b9a0af49b74932c_MD5.jpg)

[Guía de Explotación servicio WEB](https://docs.rapid7.com/metasploit/metasploitable-2-exploitability-guide/)

**Aquí nos encontramos con el primer inconveniente..**

Las aplicaciones web expuestas en esta máquina representan un problema crítico porque, aunque blindemos la infraestructura de Apache, un atacante aún puede explotar el código vulnerable de estas herramientas para tomar el control del servidor (por ejemplo, mediante inyecciones SQL, subida de archivos maliciosos o RCE).

La mejor opción para este caso, es aplicar un control de acceso a la red a nivel de servidor web y no que simplemente esté accesible para todo el mundo.

 ## Contramedida ##

Apache nos permite aplicar restricciones de acceso por carpetas específicas utilizando un módulo llamado `authz`. 

La ruta del archivo que vamos a modificar se encuentra en: `etc/apache2/sites-available/default`

Bajaremos hasta la etiqueta `</VirtualHost>` para inyectar las restricciones para las rutas expuestas.

```
<Directory /var/www/phpMyAdmin/>
		Order Deny,Allow 
		Deny from all Allow from 127.0.0.1 
</Directory>
		 
<Directory /var/www/tikiwiki/> 
		Order Deny,Allow 
		Deny from all Allow from 127.0.0.1 
</Directory> 
		
<Directory /usr/share/doc/>
		 Order Deny,Allow
		 Deny from all Allow from 127.0.0.1 
</Directory>

<Directory /var/www/dvwa/>
		 Order Deny,Allow
		 Deny from all
  	  	 Allow from 127.0.0.1
</Directory>

<Directory /var/www/mutillidae/>
		 Order Deny,Allow
  		 Deny from all
		 Allow from 127.0.0.1
</Directory>
```

y modificamos las líneas de `Allow from all` por `Allow from 127.0.0.1`

![web]({{ site.baseurl }}/assets/img/metasploitable2/27353dd23e752fdee5b8462da4982da4_MD5.jpg)
![web]({{ site.baseurl }}/assets/img/metasploitable2/a8f022e7994f78ed3519cf335238e707_MD5.jpg)

**Ocultar la cabecera PHP**: Para ocultar la cabecera PHP debemos buscar la directiva `expose_php` y cambiamos su estado a `Off` en el archivo de configuración que se encuentra en la ruta`/etc/php5/apache2/php.ini`
   
![web]({{ site.baseurl }}/assets/img/metasploitable2/47a4ed820bce6dc18fe3f8fa0261eac0_MD5.jpg)

También necesitamos agregar una directiva en el archivo 

`/etc/apache2/sites-available/default`

Donde tendremos que agregar: 

`Header always unset X-Powered-By`

![web]({{ site.baseurl }}/assets/img/metasploitable2/cf7cc0a87386e796db21bf7b9c4f9d9f_MD5.jpg)

Con esto el servidor Apache aplicara un filtro de censura a nivel de red justo en la salida del servidor.

**Quitar el listado de la carpeta `/icons/`:** Apache suele preconfigurar la carpeta de iconos en un archivo global de alias independientes. Este archivo se encuentra en `/etc/apache2/mods-available/alias.conf` y al igual que en las directivas, agregamos el signo menos `-` antes de `Indexes Multiviews` 

![web]({{ site.baseurl }}/assets/img/metasploitable2/3e9b2f77c8ba80afd02d9ff7005e33fc_MD5.jpg)

**Archivo phpinfo.php**: En un entorno real la mejor práctica es eliminar por completo este archivo. Este solo sirve para desarrollo y, si un atacante lo encuentra, obtendrá una radiografía completa de la configuración del servidor, rutas internas y extensiones. 

![web]({{ site.baseurl }}/assets/img/metasploitable2/cdddc750093b032bd417274862b05b04_MD5.jpg)

reiniciamos el servicio para aplicar las nuevas configuraciones
`/etc/init.d/apache2 restart`

![web]({{ site.baseurl }}/assets/img/metasploitable2/e5c25503d0ccc450400b65495b488222_MD5.jpg)  
![web]({{ site.baseurl }}/assets/img/metasploitable2/6dc88da9e22f510a488bbdfa7e0d9627_MD5.jpg)
![web]({{ site.baseurl }}/assets/img/metasploitable2/203a157de939b190e80c554b17e919af_MD5.jpg)

Con estos ajustes la máquina queda en un estado de fortificación aceptable. Nadie en la red podrá interactuar con las aplicaciones web a menos que tenga acceso vía SSH con credenciales válidas para tunelizar el tráfico. 

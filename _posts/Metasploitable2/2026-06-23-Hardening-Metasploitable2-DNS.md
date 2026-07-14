---
layout: post
title: "Metasploitable 2 - Hardening Servicio DNS - BIND 9.4.2"
date: 2026-06-23 21:00:00 -05000
img: /assets/img/metasploitable2/banner.png
tags: [Vuln, Linux, Hardening, DNS, BIND 9.4.2, root, Metasploitable 2 ]
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

![DNS]({{ site.baseurl }}/assets/img/metasploitable2/20260619161605.png)

En este puerto corre el servicio de DNS (Domain Name System), específicamente la versión `ISC BIND versión 9.4.2`.

Como ya sabemos, el servicio de DNS es el encargado de traducir nombres de dominio a direcciones IP. En esta versión de BIND podemos encontrar vulnerabilidades graves, como una denegación de servicios (DoS) conocida como **TKEY Cache Poisoning** (CVE-2009-0696) y a nivel de configuración, la exposición a ataques de **Amplificación de DNS** debido a que permite consultas recursivas abiertas a cualquiera.

 - **Vulnerabilidad de Ejecución Remota / Dos (CVE-2009-0696):** Este se debe a un error en el procesamiento de requerimientos en la sección **TKEY** que permite a un atacante enviar un paquete malformado y hacer que el servidor DNS colapse de inmediato.
 - **Configuración de Consulta Recursiva Abierta (Open Resolver):** El servidor acepta resolver peticiones de dominios de internet externos para cualquier IP que se le pregunte. Esto permite que los atacantes usen nuestra máquina como vector para ataques DDOS de amplificiación de DNS hacia terceros.

La vulnerabilidad **Open Resolver** es una de las fallas de configuración más peligrosas debido al impacto que puede generar, no solo en el servidor de la víctima, sino que también a terceras personas en internet.

A un atacante no le interesa heredar la máquina víctima, sino que usar la potencia de la red como un "arma" de destrucción masiva contra otra víctima. 

Esta puede afectar principalmente de tres maneras:

- **Participación Involuntaria de Ataques DDOS (Amplificación):** Esta es la consecuencia principal. Un atacante spoofea (suplanta) su propia dirección IP, haciéndose pasar por la IP de la víctima real (por ejemplo, el servidor web de un banco). Después. le envía miles de consultas DNS a la máquina víctima pidiendo registros muy pesados (como la transferencia de zona o registros).
	- **El efecto de amplificación:** La petición del atacante mide apenas 40 bytes, pero la respuesta que genera el servidor DNS mal configurado puede medir 4000 bytes (100 veces más grande).
	- El servidor le enviará esa gigantesca respuesta a la víctima real. Al multiplicar esto por miles de consultas simultáneas, la máquina ayudaría a **saturar por completo el ancho de banda de la víctima**, haciendo caer sus servicios corporativos.
- **Degradación del Rendimiento Local y Consumo de Recursos:** Mientras el servidor DNS está ocupado resolviendo consultas recursivas para todo el mundo en internet y enviando respuestas masivas clonadas:
	- La memoria RAM y la CPU de la máquina víctima estará al 100%
	- El ancho de banda de la misma red se saturará por completo, provocando lentitud externa en los servicios legítimos de la empresa (Se notaría que el "Internet" no funciona).
- **Daños a la Reputación IP y Listas Negras (Blacklisting)**: Como el servidor está enviando ráfagas de tráfico basura a otras empresas, los sistemas de defensa perimetral del mundo detectarán que la IP de la víctima está lanzando un ataque informático.
	- La dirección IP pública será reportada automáticamente a organismos internacionales y caerá en listas negras globales.
	- La consecuencia será que los servidores de correo de los clientes legítimos empezarán a rechazar los correos electrónicos de la empresa víctima, considerándolos como SPAM o tráfico malicioso, aislando digitalmente a la organización. 


# Evidencias #

para evidenciar este fallo de configuración, utilizaremos la herramienta nativa de Kali Linux `dig`. Esta es una herramienta que se utiliza para realizar consultas a los servidores DNS, es el equivalente a preguntarle directamente a una libreta de direcciones de internet como llegar a un lugar o qué información tiene guardada sobre un dominio.

A diferencia de comandos más sencillos como `ping` o `nslookup`, `dig` devuelve las respuestas completas y crudas del servidor, tal y como este lo procesa. 

![DNS]({{ site.baseurl }}/assets/img/metasploitable2/39f203efc0976490623cbdb325f8e18f_MD5.jpg)

Al utilizar el simbolo `@` le decimos a `dig` que no realice la solicitud a internet normal, sino que vaya directamente al servidor DNS que esta corriendo en esa IP y oblígalo a responder. Al recibir una respuesta sobre GOOGLE, podemos saber que ese DNS está mal configurado por que esta trabajando para extraños.

# Hardening #

Dado a que el servidor DNS empresarial interno solo debe responder a clientes autorizados de la propia red local, la estrategia consistirá en **restringir la recursividad** y securizar las directivas del archivo de configuración global.

## Ubicación del archivo de configuración de BIND ##

El archivo principal donde guardan las configuraciones de BIND se encuentran comúnmente en la ruta _/etc/bind/_ y el archivo es _named.conf.options_

![DNS]({{ site.baseurl }}/assets/img/metasploitable2/44e875ef4da302c64c801466f4387045_MD5.jpg)

Con nuestro editor de texto, vamos a agregar un bloque de configuración.

Debajo de _directory "/var/cache/bind";_ vamos a agregar:

```
    allow-query { 127.0.0.1; 192.168.0.1/24; };
    allow-recursion { 127.0.0.1; 192.168.1.0/24; };
    allow-transfer { none; };
    version "Not Disclosed";
```

**Estas reglas dicen lo siguiente:**

 -  `allow-query {127.0.0.1; 192.168.1.0/24; }` Permitir consultas desde; Regula quién tiene derecho a preguntarle al servidor por dominios que él mismo administra. (sus propias zonas DNS locales). Cualquier máquina externa en internet que intente escanear o consultar los nombres de dominio locales será rechazada inmediatamente. Evita que un atacante mapee la infraestructura interna de la empresa.
 - `allow-recursion { 127.0.0.1; 192.168.1.0/24; }` Permitir recursividad desde; Esta es la línea que destruye la vulnerabilidad de **Open Resolver**. La recursividad es el permiso que tiene el servidor para salir a internet a buscar la IP de una página que él no conoce, para luego dársela al cliente que se la pidió. Si el atacante le pide buscar una página en internet, el servidor verá que la IP solicitante no está en la lista de permitidos y arrojará el `status: REFUSED`. 
 -  `allow-transfer { none; }` Permitir transferencia de zona a...; La transferencia de zona (`AXFR`) es un comando que usan los servidores DNS esclavos para clonar toda la base de datos de un servidor principal de un solo golpe. Al configurarlo en `none`, evitamos que un atacante ejecute un comando como `dig axfr @IP-DEL-SERVIDOR` y se descargue de forma gratuita la lista completa de todos los servidores, subdominios, IPs y servicios de la empresa.
 - `version "Not Disclosed"` Versión no revelada, por defecto si un atacante le pregunta a BIND por su versión usando un comando de texto, el servidor responde orgullosamente: **"SOY ISC BIND 9.4.2"**, al poner esta directiva alteramos el banner informativo del servicio. Ahora si un atacante quiere ver la versión, el servidor responderá literalmente con el texto `Not Disclosed` (O lo que pongamos entre las comillas). Esto frena el reconocimiento del atacante, ya que al no saber la versión de este, no podrá buscar exploits específicos para lanzar contra la víctima. 

Ya tenemos las reglas en el archivo de configuración.

![DNS]({{ site.baseurl }}/assets/img/metasploitable2/ec89ce5860a609ccfa6bdcc83a17bddd_MD5.jpg)

Reiniciamos el servicio para aplicar los cambios.

`/etc/init.d/bind9 restart`


![DNS]({{ site.baseurl }}/assets/img/metasploitable2/511d39b4d876e6caaa79924f5a28fd3b_MD5.jpg)

Ahora al intentar hacer la solicitud desde nuestra máquina atacante el servidor nos rechazará de inmediato y veremos el mensaje de `status: REFUSED`, que está deshabilitada la recursión.


![DNS]({{ site.baseurl }}/assets/img/metasploitable2/415f0774b5fdb6bd9134cc7eaff7ac05_MD5.jpg)


![DNS]({{ site.baseurl }}/assets/img/metasploitable2/79ef80800fb129b48274a0824405de38_MD5.jpg)


| Puerto/servicio | Estado inicial                  | Estado actual       | acción de Hardening                                        |
| --------------- | ------------------------------- | ------------------- | ---------------------------------------------------------- |
| 21 - FTP        | Abierto `vsftpd 2.3.4`          | Cerrado             | Servicio deshabilitado en `xinetd`                         |
| 23 - Telnet     | Abierto (Acceso en texto plano) | Cerrado             | Línea comentada con `#` en `inetd.conf` y memoria purgada. |
| 25 - SMTP       | Enumeración de usuarios `VRFY`  | Blindado            | Directiva `disable_vrfy_command = yes` en Postfix          |
| 53 - DNS        | Versión expuesta `BIND 9.4.2`   | Blindado y Ofuscado | ACLs restrictivas y ocultamiento de banner con `version`   |

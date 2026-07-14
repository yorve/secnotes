---
layout: post
title: "Metasploitable 2 - Hardening Servicio RMIREGISTRY"
date: 2026-07-09
img: /assets/img/metasploitable2/banner.png
tags: [Vuln, Linux, Hardening, rmiregistry, CVE-2011-3556, Backdoor, root, Metasploitable 2 ]
---

Sobre este puerto corre el servicio `java-rmi`, **rmi** este significa _Remote Method Invocation_, y es un sistema de Java que permite a un objeto que corre en una máquina invocar métodos de un objeto que está en otra máquina totalmente distinta.

El **Registry** en el puerto 1099 actúa como un directorio telefónico, donde los programas registran sus objetos para que los otros los encuentre.

La vulnerabilidad de este servicio recae en el diseño del protocolo, por defecto el Registro de Java RMI confía ciegamente en cualquier objeto serializado que reciba y lo deserializa sin validar si es malicioso. Un atacante puede conectarse a este puerto y enviar un objeto modificado que al ser leído por el servidor, fuerce al sistema operativo de la víctima a ejecutar comandos arbitrarios de fondo.

Esta vulnerabilidad esta asociada al **CVE-2011-3556**.

[CVE-2011-3556 ](https://www.cve.org/CVERecord?id=CVE-2011-3556)


## Hardening

El servicio `rmiregistry` pertenece a una implementación antigua. Aunque el protocolo cuenta con una vulnerabilidad de diseño histórica, su vulneración de forma manual se encuentra completamente neutralizada debido a la degradación tecnológica de las herramientas de ataque.
	-**Incompatibilidad de entornos de ejecución:** Las herramientas modernas de inyección de objetos Java como `rmiscout` requieren compiladores estrictos (Java 1.8) que entran en conflicto con las dependencias actuales del sistema operativo atacante (Kali Linux).
	-**Ruptura de la cadena de suministro:** Los servidores y repositorios públicos encargados de despachar las librerías críticas para la construcción de los payloads de explotación han sido dados de baja o privatizados con el paso de los años, devolviendo errores de autenticación e impidiendo la compilación del código malicioso.
	**-Comportamiento del servicio:** La implementación minimalista de la víctima no responde a los scripts de enumeración estándar (`rmi-dumpregistry` de Nmap).

Para dar de baja este puerto de forma definitiva, vamos a localizar el proceso de Java.

[Open: Pasted image 20260709184121.png](16b52e7df55d7b507323fe490967e4eb_MD5.jpg)
![/secnotes/](16b52e7df55d7b507323fe490967e4eb_MD5.jpg)

Luego terminaremos el proceso.

`sudo kill -9 5151`  (5151 es el número de PID que encontramos con el comando anterior)

y removemos el servicio del arranque del sistema.

`sudo update-rc.d -f rmiregistry remove`

[Open: Pasted image 20260709184312.png](7b6bbdd4de9b3a5f71a32a4ef5fbaebc_MD5.jpg)
![](7b6bbdd4de9b3a5f71a32a4ef5fbaebc_MD5.jpg)

Al matar el proceso (`kill -9`) liberamos el puerto de inmediato en la memoria, y al removerlo con `update-rc.d`, le quitamos el permiso de arrancar solo cuando la máquina se encienda.

Con esto completado, al escanear desde una máquina atacante, veremos que el puerto se encuentra cerrado.

[Open: Pasted image 20260709184445.png](f648c8459742e92f3ecc6a2db20222d0_MD5.jpg)
![](f648c8459742e92f3ecc6a2db20222d0_MD5.jpg)

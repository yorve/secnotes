---
layout: post
title: "Vacaciones - Dockerlabs - Linux - Fácil"
date: 2025-08-21
img: /assets/img/vacaciones/vacaciones.png
---
![img1](/secnotes/assets/img/vacaciones/vacaciones.png)

La máquina Vacaciones de DockerLabs es un laboratorio de dificultad baja orientada a practicar técnicas básicas de enumeración, explotación y escalada de privilegios en un entorno controlado.


Comenzamos con un reconocimiento de la máquina objetivo.

![img2](/secnotes/assets/img/vacaciones/1.png)

Tenemos servicio ssh y web disponibles. Sin credenciales no podemos acceder a la máquina por el servicio ssh. Asi que comenzaremos a enumerar por el servicio web.

Al acceder a este servicio solo nos mostrará la pagina por defecto de Ubuntu.

![img3](/secnotes/assets/img/vacaciones/2.png)
 
Gobuster y Nmap no nos arrojó información 

![img4](/secnotes/assets/img/vacaciones/3.png)
 
![img5](/secnotes/assets/img/vacaciones/4.png) 

Ni siquiera el código de la pagina ni inspeccionando nos muestra información. 

![img6](/secnotes/assets/img/vacaciones/5.png)

![img7](/secnotes/assets/img/vacaciones/6.png)

  
Si hacemos una petición con `curl` nos mostrara el siguiente mensaje oculto.

![img8](/secnotes/assets/img/vacaciones/7.png)
 
Cuando usamos `curl`, estamos haciendo una petición HTTP directa y sin procesar al servidor, recibimos todo el contenido que el servidor envía, incluso si es un comentario oculto en el código fuente. Estos comentarios no son visibles en el navegador a simple vista ya que los navegadores no muestran comentarios HTML en pantalla.
Ya tenemos algo de información, un posible usuario llamado *Juan* y uno llamado *Camilo*. Además de un correo electrónico importante.
Con estos usuarios vamos a usar la herramienta **Hydra** para hacer un ataque de diccionario.

![img9](/secnotes/assets/img/vacaciones/8.png)

Encontramos que la contraseña de **camilo** es **password1**, con estas credenciales probaremos por el servicio ssh.

![img10](/secnotes/assets/img/vacaciones/9.png)
 
Ya con la conexión establecida, podemos navegar por los directorios, en la ruta `/var/mail/camilo` encontramos un archivo *correo.txt* que contiene lo siguiente.

![img11](/secnotes/assets/img/vacaciones/10.png)

Ahora tenemos las credenciales de **Juan**. Vamos a conectarnos por ssh con ellas.

![img12](/secnotes/assets/img/vacaciones/11.png) 
 
Con el comando `sudo -l` podemos ver la lista de comandos que podemos ejecutar con este usuario sin necesidad de contraseña. Este usuario puede ejecutar **ruby**

![img13](/secnotes/assets/img/vacaciones/12.png)
 
**Ruby** es un lenguaje de programación, interpretado y orientado a objetos y para uso general. 

Podemos revisar en la página **GTFObins** para ver si existe alguna forma de elevar privilegios con ruby

![img14](/secnotes/assets/img/vacaciones/13.png)
 
Y efectivamente tenemos una forma de hacerlo.

![img15](/secnotes/assets/img/vacaciones/14.png)

Al ejecutar el comando obtendremos una Shell como root

![img16](/secnotes/assets/img/vacaciones/15.png)

Con el comando `echo $SHELL` veremos que interprete de comandos usamos

![img17](/secnotes/assets/img/vacaciones/14.png)
 
Sabiendo que usamos bash podemos mejorar la Shell con `bash -i`

![img18](/secnotes/assets/img/vacaciones/17.png)



 




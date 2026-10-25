---
layout: post
title: Empieza aquí
description: Una ruta de aprendizaje para practicar pentesting y conectar cada hallazgo con su detección y mitigación.
permalink: /empieza-aqui/
---

Este es mi cuaderno de aprendizaje de ciberseguridad. Encontrarás resoluciones de laboratorios, comandos de referencia y una serie dedicada a corregir configuraciones vulnerables.

## 1. Prepara tu base

Antes de resolver una máquina, familiarízate con la terminal de Linux, permisos, procesos y servicios. Repasa también puertos TCP/UDP, DNS y peticiones HTTP. No necesitas dominarlo todo: anota los conceptos que aparezcan y vuelve sobre ellos al terminar.

## 2. Aborda un laboratorio por etapas

1. **Reconoce:** identifica el objetivo, sus puertos y los servicios expuestos.
2. **Enumera:** investiga cada servicio y formula una hipótesis a partir de lo que observas.
3. **Comprueba:** prueba la hipótesis y guarda la evidencia. Si falla, registra qué aprendiste.
4. **Profundiza:** una vez dentro, revisa identidades, permisos y configuraciones.
5. **Explica:** reconstruye la cadena completa y piensa qué cambio habría detenido cada paso.

Los laboratorios de esta web sirven para practicar en entornos propios o autorizados.

## 3. Usa los writeups como apoyo

Intenta resolver una etapa antes de leer la siguiente. Si te atascas, busca una pista concreta en el artículo y vuelve a tu terminal. Al terminar, explica con tus palabras por qué funcionó la técnica y repítela sin copiar la solución.

[Explora los artículos y filtra por técnica o sistema]({{ '/' | relative_url }}#catalog-title).

## 4. Conecta ataque y defensa

Para cada hallazgo, pregúntate: ¿qué lo permitió?, ¿qué registro o alerta podría detectarlo?, ¿cómo lo corregiría?, ¿cómo comprobaría que la corrección funciona?

La [serie de hardening de Metasploitable 2]({{ '/metasploitable2' | relative_url }}) está dedicada a esa parte del aprendizaje.

## 5. Construye tu referencia

Guarda comandos junto a su propósito, parámetros y resultado esperado. Anota versiones y errores: un comando aislado pierde utilidad si no sabes cuándo usarlo.

- [Cheatsheet de comandos]({{ '/cheatsheet/' | relative_url }})
- [Artículos por etiquetas]({{ '/tags/' | relative_url }})
- [Acerca de mí]({{ '/about' | relative_url }})

## Antes de dar por terminado un laboratorio

- Puedo describir la cadena de ataque sin mirar la solución.
- Entiendo qué evidencia justificó cada paso.
- Distingo la causa del fallo del comando que lo aprovechó.
- Puedo proponer una mitigación y una forma de comprobarla.

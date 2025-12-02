# SSH_MANAGER

Modulo de PowerShell para gestion avanzada y despliegue de claves SSH.

## CARACTERISTICAS

- **Generacion RSA 4096-bit**: Creacion segura de pares de claves con proteccion opcional por frase de paso.
- **Despliegue Automatizado**: Inyeccion fluida de claves publicas a objetivos Linux.
- **Inyeccion de Config SSH**: Creacion automatica de alias en `~/.ssh/config`.
- **Accesos Directos**: Generacion de accesos directos `.lnk` en Windows para conectividad en un clic.
- **Limpieza Inteligente**: Eliminacion automatica de claves, alias y accesos directos.
- **Subida Sanitizada**: Elimina saltos de linea de Windows para prevenir corrupcion de `authorized_keys`.

## USO

```powershell
.\ssh_manager.ps1
```

## REQUISITOS

- Windows PowerShell 5.1 o Core
- Cliente OpenSSH (Nativo en Windows 10/11)

## AUTOR

@TaquitoSuabe

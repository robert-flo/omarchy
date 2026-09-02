# Onboarding — instalar y mantener una máquina nueva

Cómo dejar cualquier máquina (x86_64, instalada con la ISO oficial estable de omarchy.org) en tu
**sistema personal**. Se hacen una sola vez por máquina.

## Antes de empezar

Necesitas la clave pública del repositorio personal: `keys/omarchy-personal-repo.pub.asc`
(la privada nunca sale del proyecto).

## Los pasos

```bash
# 1) Confiar la clave del repo personal en esta máquina (una vez, como root)
sudo pacman-key --add /ruta/a/omarchy-personal-repo.pub.asc
sudo pacman-key --lsign-key D5E75EAC51A44715

# 2) Instalar el par personal la primera vez (aún no hay repo configurado)
#    La versión actual del par se lee de la tabla de estado del README (docs/personal/README.md).
#    Descarga desde el navegador (o curl):
#    https://robert-flo.github.io/omarchy-personal-repo/stable/x86_64/omarchy-<VERSIÓN>-any.pkg.tar.zst
#    …y su .sig (mismo nombre + .sig), e instala AMBOS a la vez (misma versión, obligatorio):
sudo pacman -U omarchy-<VERSIÓN>-any.pkg.tar.zst omarchy-settings-<VERSIÓN>-any.pkg.tar.zst
#    El .sig al lado del .pkg.tar.zst lo verifica pacman automáticamente (Good signature de
#    D5E75EAC51A44715); no hace falta pasarlo como argumento.

# 3) Escribir el pacman.conf del sistema personal (ya trae el repo personal ANTES del oficial)
omarchy refresh pacman

# 4) Update completo: convergencia de paquetes, migraciones y hooks
omarchy update

# 5) Reconciliar la lista de paquetes con la del sistema personal
omarchy reinstall pkgs

# 6) Materializa las configs del sistema personal sobre tu usuario (si ya hay un usuario activo):
omarchy reinstall-configs
```

> **Nota sobre el bootstrap de launchers (POC deprecado):** si una máquina heredó el POC
> `omarchy-personal-bootstrap-launchers` de etapas tempranas, su lógica ya fue absorbida por la fila
> "Wrapper de terceros" de la Matriz (`install/user/*.sh` + `omarchy-mise-install`) y viaja por
> `omarchy update` → `omarchy refresh-applications`. No es necesario correr el POC en máquinas nuevas.

## Comprobar que quedó bien

```bash
pacman -Q omarchy omarchy-settings      # → omarchy 4.0.2-103 (misma versión ambos)
omarchy-debug --no-sudo --print         # sin errores
```

Además, en `/etc/pacman.conf` debes ver la sección `[omarchy-personal]` **antes** de `[omarchy]`.

## Qué pasa si en el paso 4 ves "Something went wrong"

Es una peculiaridad conocida del update no interactivo (ver el siguiente apartado). En una terminal
normal solo te pedirá la contraseña y seguirá. No hay nada roto en el sistema.

## Uso diario

- **Mantener:** `omarchy update` (actualiza paquetes + AUR + mise; corre migraciones y hooks).
  Actualiza lo instalado; **no instala** paquetes nuevos.
- **Instalar un paquete personal nuevo:** `sudo pacman -S hola-mundo` (una vez; luego se mantiene solo).
- **Reconciliar el set:** `omarchy reinstall pkgs`.
- **Volver a sembrar configs (nuclear):** `omarchy reinstall-configs`; más fino: `omarchy refresh
  shell`, `omarchy refresh config <relpath>`.
- **Verificar:** `pacman -Q omarchy omarchy-settings`, `omarchy version`, `pacman -Qn`.

## Problemas comunes

- **"Perdí mi personalización tras `omarchy update`."** Síntoma: el par ya no es la versión personal.
  En máquinas normales no debería pasar (prioridad por versión y posición + guard §5.3). Si ocurre en
  una máquina dev con el par `-dev` local, es un caso aparte.
- **`omarchy update -y` aborta con "Something went wrong"** (sesiones sin terminal). Quirk de `sudo`
  (`sudo -v` bajo pty pide contraseña y expira a los ~5 min). En terminal normal no molesta. Si se
  necesita totalmente automatizado, drop-in temporal `Defaults:USER !authenticate` en sudoers.
- **Una webapp nueva no aparece en el launcher.** Reconstruir el paquete NO toca el usuario actual;
  refrescar: `omarchy-refresh-applications`.

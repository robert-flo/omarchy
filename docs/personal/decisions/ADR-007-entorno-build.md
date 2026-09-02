# ADR-007 — Entorno de build: `archlinux:base-devel` rolling

- **Estado:** Aceptada con riesgo declarado (L8)

## Contexto

La Action builda dentro de `docker run archlinux:base-devel` (imagen **rolling**: el tag mutable
sigue la última versión de Arch). Un build reproducible al 100% exigiría pin a digest
(`archlinux:base-devel@sha256:…`). Upstream builda igual (rolling) y el repo personal solo sirve
`stable`, con cadencia de rebuild muy baja.

## Decisión

- **Mantener `archlinux:base-devel` rolling**, de forma consciente y documentada:
  - Cada release reconstruye todo el conjunto publicado; el pin a digest solo daría determinismo
    byte-a-byte entre dos runs del MISMO commit, que no es un caso real (cada republicación cambia
    `pkgrel` → ya es un build distinto).
  - Riesgo aceptado: un update de base-devel podría cambiar deps/comportamiento entre dos
    republicaciones del mismo `pkgver`. Impacto real bajo (una o dos máquinas, mismo usuario).
- **Acción de seguimiento (no bloqueante):** si se instala en terceros o se exige reproducibilidad,
  migrar a pin por digest documentado en el workflow.

## Consecuencias

- Simplicidad a costa de no tener determinismo estricto (declarado, no oculto).
- El guard §5.3 y la validación post-publicación cubren la seguridad funcional.

# Demo, PR y tareas manuales — Unlock WP Plugin Fix

Este archivo reúne todo lo que **no se puede automatizar** desde el entorno del agente
y que debes ejecutar tú: subir la rama, crear el Lock en testnet, levantar/desplegar
el sitio, grabar el video y abrir el PR.

---

## 1. Cómo subir los cambios (sin credenciales en el agente)

Tienes dos vías. La rama ya existe localmente en `unlock-wordpress-plugin/` con 16 commits.

### Opción A — Aplicar los parches (recomendada si clonas tu fork aparte)

```bash
# 1. Haz fork en GitHub: https://github.com/unlock-protocol/unlock-wordpress-plugin/fork
git clone https://github.com/<tu-usuario>/unlock-wordpress-plugin.git
cd unlock-wordpress-plugin

# 2. Aplica los 16 parches en orden
git am /ruta/a/patches/*.patch

# 3. Sube la rama
git push -u origin fix/audit-corrections
```

### Opción B — Aplicar el diff combinado

```bash
cd unlock-wordpress-plugin
git checkout -b fix/audit-corrections
git apply /ruta/a/patches/ALL-CHANGES.diff
git add -A
git commit -m "fix: apply audit corrections"
```

### Opción C — Desde el bundle

```bash
git clone https://github.com/<tu-usuario>/unlock-wordpress-plugin.git
cd unlock-wordpress-plugin
git fetch /ruta/a/unlock-wordpress-plugin-fix.bundle fix/audit-corrections:fix/audit-corrections
git checkout fix/audit-corrections
git push -u origin fix/audit-corrections
```

> Nota: `git am` conserva los 16 commits atómicos y sus mensajes, ideal para el PR.

---

## 2. Crear el Lock en testnet (solo tú, requiere wallet)

1. Instala MetaMask y añade **Base Sepolia** o **Sepolia**.
2. Consigue fondos de faucet:
   - Base Sepolia: <https://www.alchemy.com/faucets/base-sepolia>
   - Sepolia: <https://sepoliafaucet.com/>
3. Ve a <https://app.unlock-protocol.com/locks/create>.
4. Configura:
   - **Network:** Base Sepolia (84532) o Sepolia (11155111).
   - **Precio:** `0` (gratis) para facilitar la demo, o `0.0001` ETH.
   - **Duración:** 30 días o ilimitada.
   - **Cantidad de miembros:** ilimitada.
5. Confirma la transacción. Copia la **dirección del Lock** (`0x…`).
6. Pega la dirección en `demo/setup.sh` (variable `LOCK_ADDRESS`) o pásala por entorno.

> El proxy RPC del plugin (`https://rpc.unlock-protocol.com/<network_id>`) responde
> correctamente para Sepolia (11155111), Base Sepolia (84532) y Base (8453). Se
> verificó por HTTP; **Goerli (5) y Polygon Amoy (80002) devuelven 404** en ese proxy.

---

## 3. Levantar el sitio de demo localmente

```bash
# 1. Compila los assets del plugin (requiere Node + Yarn)
cd unlock-wordpress-plugin
yarn install
yarn build:all

# 2. Levanta WordPress + MySQL
cd ../demo
LOCK_ADDRESS=0xTU_LOCK NETWORK_ID=84532 ./setup.sh
```

Esto deja:
- Sitio en `http://localhost:8080`
- Una **página completa** protegida
- Un **post público con un bloque protegido** dentro
- Las redes por defecto del plugin (verifica que aparezcan Sepolia y Base Sepolia)

### Checklist de verificación (sección 5.3 de la documentación)

- [ ] El plugin se activa sin warnings en `wp-content/debug.log`.
- [ ] `wp option get unlock_protocol_settings` incluye Sepolia y Base Sepolia (bug 1 corregido).
- [ ] Un visitante sin wallet ve el botón "Login with Unlock" / "Purchase this".
- [ ] Un visitante sin Key ve el bloqueo, no el contenido.
- [ ] Tras comprar/reclamar una Key, el contenido se muestra.
- [ ] En feeds/excerpts/REST el contenido **no** dispara el flujo (bug 5 corregido).
- [ ] Añadir/eliminar una red en el admin funciona sin warnings (bug 11 corregido).

---

## 4. Desplegar el sitio público (opciones)

Elige una y ejecútala tú (el agente no tiene acceso a tu infraestructura):

- **VPS con Docker:** copia `demo/` y `unlock-wordpress-plugin/`, instala Docker, y
  `docker compose up -d` detrás de Nginx + Certbot. Cambia `SITE_URL` a tu dominio.
- **Railway / Render:** crea un servicio WordPress + MySQL desde el marketplace y
  monta el plugin como volumen o súbelo por SFTP.
- **WordPress Playground** (<https://playground.wordpress.net/>): compatible para una
  demo rápida, pero **no persiste** ni ejecuta OAuth real de forma fiable; úsalo solo
  como apoyo visual.

Recuerda volver a ejecutar `setup.sh` con `SITE_URL=https://tu-dominio` para que el
`redirect_uri` del OAuth coincida con el host.

---

## 5. Guion del video (máx. 3 min)

| Tiempo | Plano | Qué mostrar |
|---|---|---|
| 0:00–0:20 | Presentación | "Plugin de Unlock Protocol para WordPress: bugs corregidos y demo end-to-end". |
| 0:20–0:50 | Antes/después | Muestra `git log --oneline master..fix/audit-corrections` con los 16 commits y el resultado de PHPCS (173→126 errores, 12→9 warnings). |
| 0:50–1:20 | Admin | Ajustes → Unlock Protocol: muestra que las redes incluyen Sepolia/Base Sepolia y añade/elimina una red. |
| 1:20–1:50 | Contenido bloqueado | Abre la página protegida en una ventana incógnito: se ve el botón, no el contenido. |
| 1:50–2:30 | Flujo real | Conecta la wallet, compra/reclama la Key en el checkout de Unlock, vuelve y el contenido se desbloquea. |
| 2:30–3:00 | Cierre | Muestra la dirección del Lock en el explorer de la testnet y el repositorio/PR. |

Herramientas: OBS Studio o Loom. Graba la terminal y el navegador; usa incógnito para
probar el estado "sin Key" y una segunda cuenta para el estado "con Key".

---

## 6. Texto para el Pull Request

**Título:**

```
Fix functional, security and compatibility issues found during audit
```

**Descripción:**

```markdown
## Summary

Audit and fix of the Unlock Protocol WordPress plugin. No rewrite: each
issue is fixed with a focused, atomic commit. A full report is included
in FIXES.md.

## Fixed

- Duplicate `mainnet` key in `networks_list()` silently dropped the Goerli
  entry; default list now uses unique keys and current testnets.
- `has_access()` used an undefined `$url` and aborted on the first error.
- `validate()` did not validate addresses/URL, had no timeout and did not
  check the RPC response code (also triggered a PHP 8.1 deprecation).
- `render_content()` could iterate over `null`; full-post filter ran in
  every `the_content` context.
- Infinite loop in `Helper::unique_username()`.
- Asset version used a URL with `file_exists()`; editor assets could warn
  when the build was missing.
- REST settings: network deletion index validation and general settings
  sanitization.
- OAuth registration now handles `wp_insert_user()` errors.
- Admin UI no longer accepts a lock without a network.

## Verification

- All PHP files pass `php -l`.
- PHPCS with WordPress Coding Standards (WPCS 3.4.1, PHPCS 3.13.6):
  errors 173 → 126, warnings 12 → 9, **no new violations introduced**.
- Manual checklist script and Docker demo included in `demo/`.

## Notes

JavaScript dependencies were intentionally not upgraded in this PR to
keep the diff focused.
```

---

## 7. Estado y limitaciones conocidas

| Tarea | Estado |
|---|---|
| Correcciones de código (16 commits) | Hecho |
| Lint de sintaxis PHP | Hecho (`php -l`, todos OK) |
| PHPCS + WPCS real | Hecho (173→126 errores, 12→9 warnings) |
| Parches/bundle para subir | Hecho (`patches/`, `unlock-wordpress-plugin-fix.bundle`) |
| WordPress real corriendo | **No posible aquí**: sin Docker, MySQL, WP-CLI ni extensiones de BD en el PHP local. Script reproducible en `demo/`. |
| Lock en testnet | **Solo tú** (requiere wallet y faucet) |
| Despliegue público | **Solo tú** (requiere infraestructura) |
| Video demo | **Solo tú** (guion en la sección 5) |
| PR en GitHub | **Solo tú** (sin `gh`/credenciales) |
| Actualización de dependencias JS | Pendiente (follow-up, para no ensuciar el diff) |
| Tests PHPUnit | Pendiente (el repo no tiene infraestructura de tests) |

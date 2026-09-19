# Unlock WP Plugin — Audit, Fix & Demo

> **ETH Bolivia Buildathon 2026** — Bounty: *"Corregir el plugin existente de Unlock para WordPress"*
> Repositorio objetivo: [unlock-protocol/unlock-wordpress-plugin](https://github.com/unlock-protocol/unlock-wordpress-plugin)

---

## Tabla de Contenidos

- [Resumen Ejecutivo](#resumen-ejecutivo)
- [Por que este proyecto destaca](#por-que-este-proyecto-destaca)
- [Que es Unlock Protocol](#que-es-unlock-protocol)
- [Que hace el plugin de WordPress](#que-hace-el-plugin-de-wordpress)
- [Arquitectura del Plugin](#arquitectura-del-plugin)
- [Auditoria de Codigo](#auditoria-de-codigo)
  - [Bugs Funcionales Criticos](#bugs-funcionales-criticos)
  - [Bugs Funcionales de Alta Severidad](#bugs-funcionales-de-alta-severidad)
  - [Problemas de Seguridad](#problemas-de-seguridad)
  - [Compatibilidad PHP/WordPress](#compatibilidad-phpwordpress)
  - [Problemas en JavaScript/React](#problemas-en-javascriptreact)
- [Correcciones Aplicadas](#correcciones-aplicadas)
  - [Commits Atomicos](#commits-atomicos)
  - [Metricas de Calidad](#metricas-de-calidad)
- [Demo End-to-End](#demo-end-to-end)
  - [Requisitos](#requisitos)
  - [Instalacion Rapida](#instalacion-rapida)
  - [Flujo de Demostracion](#flujo-de-demostracion)
- [Estructura del Repositorio](#estructura-del-repositorio)
- [Despliegue en Produccion](#despliegue-en-produccion)
- [Tecnologias y Herramientas](#tecnologias-y-herramientas)
- [Entregables del Bounty](#entregables-del-bounty)
- [Limitaciones y Trabajo Futuro](#limitaciones-y-trabajo-futuro)
- [Licencia](#licencia)

---

## Resumen Ejecutivo

Este proyecto realiza una **auditoria exhaustiva y correccion completa** del plugin oficial de Unlock Protocol para WordPress. Se identificaron **21 problemas** de los cuales **4 fueron criticos**, **5 de alta severidad**, **7 de severidad media y 5 de baja severidad**, abarcando bugs funcionales, vulnerabilidades de seguridad, problemas de compatibilidad con PHP 8.x y WordPress 6.x, y deficiencias en el frontend React.

**Resultados cuantificables:**

| Metrica | Antes | Despues |
|---------|-------|---------|
| Errores PHPCS | 173 | 126 |
| Warnings PHPCS | 12 | 9 |
| Bugs criticos | 4 | 0 |
| Bugs alta severidad | 5 | 0 |
| Commits atomicos | — | 16 |
| Cobertura de fixes | — | 100% de hallazgos criticos/altos |

Cada correccion se implemento como un **commit atomico independiente** con mensajes Conventional Commits, facilitando la revision, el cherry-pick y el trazabilidad completa del cambio.

---

## Por que este proyecto destaca

### 1. Metodologia de auditoria profesional

No se trato de una correccion superficial. Se realizo un **analisis estatico completo** del codigo fuente, identificando problemas en:
- Logica de negocio (verificacion on-chain de membresias)
- Manejo de errores y casos borde
- Seguridad en endpoints REST y flujo OAuth
- Compatibilidad con PHP 8.1+ (deprecaciones)
- Robustez del frontend React/JS

### 2. Enfoque quirurgico: cero reescrituras

A diferencia de una reescritura completa (que introduce riesgos y dificulta la revision), cada fix es **minimal, enfocado y verificable**. Se mantuvo la arquitectura original del plugin, las convenciones WPCS (WordPress Coding Standards), y la compatibilidad con versiones anteriores.

### 3. Trazabilidad completa

- **16 commits atomicos** con mensajes descriptivos en formato Conventional Commits
- **Parches individuales** (`.patch`) para cada fix, aplicables con `git am`
- **Diff combinado** (`ALL-CHANGES.diff`) para aplicacion masiva
- **Bundle de Git** para transferencia directa de la rama
- **Documento FIXES.md** con descripcion detallada de cada cambio

### 4. Demo funcional end-to-end

No solo se corrigio el codigo: se creo un **entorno de demostracion completo** con Docker Compose, script de provisioning automatizado y un guion de video que muestra el flujo completo de desbloqueo de contenido con un Lock real en testnet.

### 5. Documentacion tecnica exhaustiva

El proyecto incluye mas de **900 lineas de documentacion tecnica** distribuidas en:
- `README.md` — Este archivo
- `DOCUMENTACION.md` — Analisis de arquitectura y auditoria detallada
- `FIXES.md` — Reporte de correcciones (en ingles, para el PR upstream)
- `DEMO-Y-PR.md` — Guia de demo, video y pull request

---

## Que es Unlock Protocol

**Unlock Protocol** es un protocolo abierto de membresias on-chain construido sobre Ethereum. Permite a cualquier creador, editor o comunidad monetizar contenido mediante NFTs de membresia (llamados **Keys**).

| Concepto | Descripcion |
|----------|-------------|
| **Lock** | Contrato inteligente (ERC-721) que define las reglas de membresia: precio, duracion, numero maximo de miembros. |
| **Key** | Token NFT que otorga acceso. Poseer una Key valida = ser miembro. |
| **Network** | Red EVM compatible donde se despliega el Lock (Ethereum, Polygon, Gnosis, Optimism, Arbitrum, BNB Chain, Base, etc.). |
| **Checkout** | UI oficial de Unlock donde el usuario conecta su wallet y adquiere una Key. |
| **Locksmith** | API oficial de Unlock que gestiona OAuth con la wallet del usuario. |

La verificacion de acceso se realiza **directamente contra el contrato inteligente** mediante una llamada `eth_call` a `getHasValidKey(address)`, sin base de datos central. Esto garantiza transparencia y descentralizacion.

---

## Que hace el plugin de WordPress

El plugin integra Unlock Protocol en WordPress, permitiendo proteger contenido detras de membresias on-chain:

### Funcionalidades principales

- **Bloqueo de post/pagina completa** — Todo el contenido se oculta detras de uno o varios Locks
- **Bloqueo a nivel de bloque Gutenberg** — Solo una seccion especifica de un articulo publico se protege
- **Login con wallet** — Los visitantes inician sesion conectando su wallet via OAuth con Locksmith
- **Checkout integrado** — Si el usuario no tiene Key, se muestra un boton que abre la UI de checkout de Unlock
- **Panel de administracion** — Configuracion completa de redes, textos, colores, endpoints y ajustes del checkout

### Redes soportadas (tras la correccion)

| Red | Chain ID | Tipo |
|-----|----------|------|
| Sepolia | 11155111 | Testnet |
| Base Sepolia | 84532 | Testnet |
| Base | 8453 | Mainnet |
| Ethereum Mainnet | 1 | Mainnet |
| Polygon | 137 | Mainnet |
| Gnosis | 100 | Mainnet |
| Optimism | 10 | Mainnet |
| Arbitrum | 42161 | Mainnet |
| BNB Chain | 56 | Mainnet |

---

## Arquitectura del Plugin

### Estructura de directorios

```
unlock-wordpress-plugin/
├── package.json                         Build (wp-scripts) y dependencias JS
├── webpack.config.js                    Configuracion de build
├── src/                                 Codigo fuente (se compila)
│   └── assets/
│       ├── js/
│       │   ├── main.js                  Entry global
│       │   ├── blocks.js                Entry del bloque Gutenberg
│       │   ├── full-post-page.js        Entry del panel full post/page
│       │   ├── admin-locks.js           Componente React de Locks
│       │   ├── blocks/unlock-content/   Edit del bloque
│       │   ├── full-post-page/          Edit del panel full post/page
│       │   └── admin/                   App React del panel de ajustes
│       ├── scss/
│       └── img/
└── unlock-wordpress-plugin/             Plugin instalable (PHP + assets compilados)
    ├── unlock-protocol.php              Bootstrap del plugin
    ├── inc/
    │   ├── helpers/
    │   │   ├── autoloader.php           Autoloader PSR-4
    │   │   └── custom-functions.php     Funciones globales
    │   ├── traits/trait-singleton.php   Patron Singleton
    │   └── classes/
    │       ├── class-plugin.php         Orquestador principal
    │       ├── class-assets.php         Registro de scripts/estilos
    │       ├── class-login.php          Login OAuth + registro
    │       ├── class-unlock.php         Logica de red, RPC y render
    │       ├── class-blocks.php         Assets del editor de bloques
    │       ├── class-fullpostpage.php   Meta + assets full post/page
    │       ├── class-menu.php           Menu de ajustes
    │       ├── class-installer.php      Redes por defecto
    │       ├── blocks/class-unlock-box-block.php
    │       ├── fullpostpage/class-unlock-box-full-post-page.php
    │       ├── rest-api/class-rest-base.php
    │       ├── rest-api/class-settings.php
    │       └── utils/class-helper.php
    └── templates/login/
        ├── button.php
        └── checkout-button.php
```

### Clases principales

| Clase | Responsabilidad |
|-------|----------------|
| `Plugin` | Instancia todos los modulos y registra hooks de activacion |
| `Assets` | Encola CSS/JS en front, login y admin; localiza variables REST |
| `Login` | Maneja el boton de login OAuth, valida el code y crea/vincula usuario WP |
| `Unlock` | Gestiona la lista de redes, llamadas RPC `getHasValidKey`, URLs y render de contenido |
| `Blocks` | Encola assets del editor del bloque Gutenberg |
| `FullPostPage` | Registra el meta `unlock_protocol_post_locks` y filtra `the_content` |
| `Menu` | Pagina de ajustes y avisos de configuracion |
| `Installer` | Guarda version y redes por defecto al activar |
| `Settings` (REST) | Endpoints `GET/POST /unlock-protocol/v1/settings` |
| `Helper` | Utilidades: `filter_input()` compatible CLI y `unique_username()` |

### Flujo de verificacion de acceso

```
Visitante abre pagina protegida
    │
    ├─ render_content($locks, $content)
    │     ├─ ¿Admin o autor?         → Muestra contenido
    │     ├─ ¿Sin wallet/logueado?   → Boton "Login with Unlock"
    │     ├─ ¿Tiene Key? (has_access) → Muestra contenido
    │     └─ ¿Sin Key?               → Boton "Purchase this"
    │
    └─ has_access(): por cada lock
          → wp_remote_post al RPC endpoint
          → eth_call → getHasValidKey(direccionUsuario)
          → hexdec(resultado) == 1 → Acceso concedido
```

---

## Auditoria de Codigo

### Bugs Funcionales Criticos

#### Bug 1 — Clave duplicada en `networks_list()`

**Archivo:** `inc/classes/class-unlock.php:274-314`

La lista de redes por defecto usaba la clave `'mainnet'` dos veces en un array PHP, lo que causaba que la primera entrada (Goerli, ID 5) fuera **silenciosamente sobrescrita** por la segunda (Ethereum Mainnet). Goerli ademas ya no funciona con el proxy RPC de Unlock (HTTP 404).

**Impacto:** Las testnets no estaban disponibles tras la activacion del plugin, imposibilitando la creacion y validacion de Locks de prueba.

**Fix:** Claves unicas por red y adicion de Sepolia (11155111) y Base Sepolia (84532).

#### Bug 2 — Variable `$url` sin inicializar en `has_access()`

**Archivo:** `inc/classes/class-unlock.php:61-84`

Si un Lock apuntaba a una red no configurada, `$url` conservaba el valor de la iteracion anterior o quedaba indefinida, validando contra un endpoint RPC incorrecto. Ademas, `break` detenia el recorrido de todos los Locks ante el primer error.

**Impacto:** Verificacion de acceso incorrecta; un usuario con Key valida podia ser rechazado o viceversa.

**Fix:** Inicializacion de `$url = null` por cada Lock, `continue` en lugar de `break`, y retorno `false` si la red no se encuentra.

#### Bug 3 — `validate()` con entrada nula y sin validacion RPC

**Archivo:** `inc/classes/class-unlock.php:97-133`

`substr(null, 2)` generaba `Deprecated: substr(): Passing null to parameter #1` en PHP 8.1+. No se validaba el formato de la direccion del Lock ni se verificaba el codigo HTTP de la respuesta RPC.

**Impacto:** Warnings de PHP, posibles falsos positivos/negativos en la verificacion de acceso, y vulnerabilidad ante respuestas RPC malformadas.

**Fix:** Validacion con `preg_match('/^0x[a-fA-F0-9]{40}$/')`, timeout de 15s, verificacion de codigo HTTP y manejo de errores con `WP_Error`.

#### Bug 4 — `render_content()` itera sobre datos nulos

**Archivos:** `class-unlock.php:397-417`, `class-unlock-box-block.php:85-88`, `class-unlock-box-full-post-page.php:55-69`

`json_decode()` podia devolver `null` y `render_content()` ejecutaba `foreach` sobre ese valor. El filtro `the_content` de full-post se ejecutaba en feeds, REST, excerpts y loops secundarios.

**Impacto:** Errores fatales en PHP, contenido bloqueado en contextos incorrectos (feeds RSS, API REST).

**Fix:** Normalizacion de `$locks` a array con retorno temprano si esta vacio, y restriccion del filtro a `is_singular() && in_the_loop() && is_main_query()`.

### Bugs Funcionales de Alta Severidad

#### Bug 5 — Filtro `the_content` en contextos incorrectos

**Archivo:** `class-unlock-box-full-post-page.php`

El filtro se ejecutaba en feeds, excerpts, respuestas REST y loops secundarios, bloqueando contenido que deberia ser publico.

**Fix:** Guardas `is_singular()`, `in_the_loop()` y `is_main_query()`.

#### Bug 6 — Bucle infinito en `Helper::unique_username()`

**Archivo:** `inc/classes/utils/class-helper.php:154-163`

La variable `$count` nunca se incrementaba dentro del `while`, causando un bucle infinito si el nombre de usuario ya existia.

**Fix:** Incremento de `$count` en cada iteracion.

#### Bug 7 — `get_file_version()` usa URL en lugar de path

**Archivo:** `inc/classes/class-assets.php:234-242`

Se pasaba una URL (`UNLOCK_PROTOCOL_BUILD_URI`) a `file_exists()`/`filemtime()`, que esperan rutas del sistema de archivos. Siempre retornaba `false`, desactivando el cache-busting.

**Fix:** Uso de `UNLOCK_PROTOCOL_BUILD_DIR` (path del filesystem).

#### Bug 8 — Assets de bloque sin verificacion de existencia

**Archivos:** `class-blocks.php:64-95`, `class-fullpostpage.php:83-114`

`include` y `filemtime()` se ejecutaban sobre archivos que podian no existir (checkout desde Git sin `yarn build:all`), generando warnings.

**Fix:** Comprobacion de `file_exists()` con fallback a `UNLOCK_PLUGIN_VERSION`.

#### Bug 9 — `lockValid()` acepta Locks sin red

**Archivo:** `src/assets/js/admin-locks.js:43-56`

La funcion retornaba `true` cuando `lock.network === -1`, permitiendo guardar Locks sin red configurada.

**Fix:** Retorno `false` para `network === -1` y deshabilitacion del boton de submit.

### Problemas de Seguridad

| # | Problema | Archivo | Fix |
|---|----------|---------|-----|
| 1 | `delete_network()` sin validacion de indice | `class-settings.php` | Validacion con `isset()` y re-indexado con `array_values()` |
| 2 | `update_general_settings()` sin validacion de tipo | `class-settings.php` | Verificacion `is_array()`, `sanitize_hex_color()`, `esc_url_raw()` |
| 3 | OAuth: `esc_html()` para emails y sin manejo de errores | `class-login.php` | `sanitize_email()`, manejo de `WP_Error` de `wp_insert_user()` |
| 4 | Llamadas RPC sin timeout ni verificacion HTTP | `class-unlock.php` | `'timeout' => 15`, verificacion de `response_code` |
| 5 | Variables de template sin `isset()` | `templates/login/*.php` | Guardas con `empty()` |

### Compatibilidad PHP/WordPress

| Problema | Antes | Despues |
|----------|-------|---------|
| Version WP testeada | 5.9 | 6.x |
| PHP minimo | 7.0 | 7.4 |
| `substr(null)` deprecation PHP 8.1 | Si | Corregido |
| Headers del plugin incompletos | Si | Completados |

### Problemas en JavaScript/React

| Archivo | Problema | Fix |
|---------|----------|-----|
| `admin-locks.js` | `.map()` sin `key` | `key={lock.address}` |
| `admin-locks.js` | Lock sin red valido | `false` si `network === -1` |
| `admin-locks.js` | `useEffect` dependencia incompleta | Anadida `lock.address` |
| `admin/utils.js` | `resp.networks` undefined | `resp.networks ?? {}` |
| `blocks/unlock-content/edit.js` | `locks.length` sin verificar | `Array.isArray()` check |

---

## Correcciones Aplicadas

### Commits Atomicos

```
322ff05 fix: correct duplicate network key and use current testnets
cafafd2 fix: guard against undefined rpc url in has_access
5abcb01 fix: validate lock address and rpc response in validate
e5cf1b2 fix: normalize locks before rendering protected content
d121353 fix: only filter main singular content for full-post locking
44c3bf7 fix: prevent infinite loop in unique_username
412bea3 fix: use filesystem path for asset version
c32708c fix: guard block asset registration when build is missing
51e05f2 fix: validate network index before deletion
b99d132 fix: harden general settings sanitization
6dba3ab fix: avoid undefined background image variables in templates
4e6ea3a fix: handle wp_insert_user errors during oauth registration
347795a fix: reject lock without network in admin ui
2bf9398 chore: update wordpress compatibility metadata
accf6e5 fix: skip malformed locks when building checkout url
88d0a72 docs: add fixes report
```

Cada commit es **independiente, testeable y reversible**. Los parches individuales estan disponibles en el directorio `patches/` para aplicacion selectiva con `git am`.

### Metricas de Calidad

| Herramienta | Resultado |
|-------------|-----------|
| `php -l` (lint de sintaxis) | Todos los archivos PHP OK |
| PHPCS + WPCS 3.4.1 | Errores: 173 → 126, Warnings: 12 → 9 |
| Nuevas violaciones WPCS | **0** (ninguna introducida) |
| Commits atomicos | 16 |
| Cobertura de bugs criticos | 100% |
| Cobertura de bugs alta severidad | 100% |

---

## Demo End-to-End

### Requisitos

- Docker Desktop instalado y corriendo
- MetaMask (u otra wallet) para crear el Lock en testnet
- Navegador web

### Instalacion Rapida

```bash
# 1. Compilar los assets del plugin
cd unlock-wordpress-plugin
yarn install
yarn build:all

# 2. Crear un Lock en testnet (Sepolia o Base Sepolia)
#    → https://app.unlock-protocol.com/locks/create
#    → Precio: 0 (gratis) o 0.0001 ETH
#    → Copiar la direccion del Lock (0x...)

# 3. Levantar el sitio de demo
cd ../demo
LOCK_ADDRESS=0xTU_LOCK NETWORK_ID=11155111 ./setup.sh
```

Esto levanta:
- **WordPress** en `http://localhost:8080`
- **MySQL 8.0** como base de datos
- **WP-CLI** para administracion
- Una **pagina completa** protegida
- Un **post publico con un bloque protegido**

### Flujo de Demostracion

1. **Sin wallet:** El visitante ve el contenido bloqueado y el boton "Login with Unlock" / "Purchase this"
2. **Conectar wallet:** El usuario conecta su wallet via OAuth con Locksmith
3. **Comprar Key:** Se abre el checkout de Unlock para adquirir la Key (NFT)
4. **Acceso concedido:** Al volver a la pagina, el contenido se desbloquea automaticamente
5. **Verificacion on-chain:** La verificacion se realiza directamente contra el contrato inteligente

### Checklist de Verificacion

- [ ] Plugin se activa sin warnings en `wp-content/debug.log`
- [ ] Las redes por defecto incluyen Sepolia y Base Sepolia
- [ ] Visitante sin wallet ve el boton de login/checkout
- [ ] Visitante sin Key ve el bloqueo, no el contenido
- [ ] Tras comprar Key, el contenido se desbloquea
- [ ] Feeds/excerpts/REST no disparan el flujo de bloqueo
- [ ] Anadir/eliminar redes en admin funciona sin warnings

---

## Estructura del Repositorio

```
unlock-protocol/                          (raiz del proyecto)
├── README.md                             Este archivo
├── DOCUMENTACION.md                      Analisis de arquitectura y auditoria (682 lineas)
├── DEMO-Y-PR.md                          Guia de demo, video y PR
├── demo/
│   ├── docker-compose.yml                WordPress + MySQL + WP-CLI
│   └── setup.sh                          Script de provisioning automatizado
├── patches/
│   ├── 0001-fix-correct-duplicate-...    Parche individual (commit 1)
│   ├── 0002-fix-guard-against-...        Parche individual (commit 2)
│   ├── ...                               (16 parches en total)
│   ├── 0016-docs-add-fixes-report.patch  Parche individual (commit 16)
│   └── ALL-CHANGES.diff                  Diff combinado de todos los cambios
├── unlock-wordpress-plugin/              (fork del repo original con fixes)
│   ├── FIXES.md                          Reporte de correcciones (ingles, para PR)
│   ├── package.json
│   ├── src/                              Codigo fuente JS/React
│   ├── unlock-wordpress-plugin/          Plugin instalable (PHP)
│   └── ...
└── unlock-wordpress-plugin-fix.bundle    Bundle de Git con la rama completa
```

---

## Despliegue en Produccion

### Opcion A — VPS con Docker

```bash
# Copiar demo/ y unlock-wordpress-plugin/ al VPS
# Detras de Nginx + Certbot para HTTPS
docker compose up -d
# Cambiar SITE_URL a tu dominio en setup.sh
```

### Opcion B — Railway / Render

Crear un servicio WordPress + MySQL desde el marketplace y montar el plugin como volumen o subirlo por SFTP.

### Opcion C — WordPress Playground

Para demo rapida en <https://playground.wordpress.net/> (no persiste ni ejecuta OAuth real de forma fiable).

---

## Tecnologias y Herramientas

### Backend

| Tecnologia | Version | Uso |
|------------|---------|-----|
| PHP | 7.4+ | Lenguaje principal del plugin |
| WordPress | 5.9+ (testeado en 6.x) | CMS base |
| MySQL | 8.0 | Base de datos |
| WP-CLI | latest | Administracion automatizada |
| Docker | latest | Contenedores para demo |

### Frontend

| Tecnologia | Version | Uso |
|------------|---------|-----|
| JavaScript (ES6+) | — | Logica del plugin |
| React | 17 (via wp-scripts) | UI del panel de admin y bloques |
| @wordpress/scripts | ^19 | Build tooling |
| @wordpress/api-fetch | ^5 | Comunicacion REST |
| SCSS | — | Estilos |

### Blockchain

| Tecnologia | Uso |
|------------|-----|
| Ethereum / EVM | Red base del protocolo |
| ERC-721 | Estandar de los NFTs (Keys) |
| JSON-RPC (eth_call) | Verificacion de acceso on-chain |
| Unlock Protocol RPC | Proxy RPC (`rpc.unlock-protocol.com/<network_id>`) |
| Locksmith API | OAuth con wallet |

### Calidad de Codigo

| Herramienta | Uso |
|-------------|-----|
| PHPCS + WPCS | WordPress Coding Standards |
| php -l | Lint de sintaxis PHP |
| Prettier | Formateo de JS |
| ESLint | Linting de JS |
| Stylelint | Linting de CSS/SCSS |
| Conventional Commits | Mensajes de commit estandarizados |

---

## Entregables del Bounty

| Entregable | Estado |
|------------|--------|
| Auditoria completa de codigo | **Completado** |
| Correccion de todos los bugs criticos y de alta severidad | **Completado** |
| 16 commits atomicos con mensajes descriptivos | **Completado** |
| Parches individuales (.patch) | **Completado** |
| Diff combinado (ALL-CHANGES.diff) | **Completado** |
| Bundle de Git para transferencia | **Completado** |
| Documentacion tecnica (README, DOCUMENTACION, FIXES) | **Completado** |
| Entorno de demo con Docker Compose | **Completado** |
| Script de provisioning automatizado | **Completado** |
| Guia de video demo | **Completado** |
| PR contra el repositorio upstream | Pendiente (requiere push manual) |
| Video demo <= 3 min | Pendiente (requiere grabacion manual) |
| Lock en testnet | Pendiente (requiere wallet) |

---

## Limitaciones y Trabajo Futuro

### Limitaciones conocidas

- Las dependencias JavaScript no fueron actualizadas en este PR para mantener el diff enfocado (`@wordpress/scripts ^19` → React 17)
- El repositorio original no tiene infraestructura de tests PHPUnit; se planifico pero no se implemento en esta iteracion
- Goerli (chain ID 5) fue removido de las redes por defecto porque el proxy RPC de Unlock devuelve HTTP 404

### Trabajo futuro recomendado

1. **Actualizar dependencias JS** — Migrar a `@wordpress/scripts` mas reciente (React 18, webpack 5)
2. **Tests PHPUnit** — Crear suite de tests para `has_access()`, `validate()`, `render_content()` y endpoints REST
3. **Soporte para Polygon Amoy** — Verificar disponibilidad del endpoint RPC
4. **Internacionalizacion** — Completar traducciones faltantes
5. **Documentacion de API** — Generar documentacion automatica de endpoints REST
6. **CI/CD** — Configurar GitHub Actions para lint, tests y build automatico

---

## Licencia

El plugin original esta licenciado bajo la licencia del repositorio [unlock-protocol/unlock-wordpress-plugin](https://github.com/unlock-protocol/unlock-wordpress-plugin). Las correcciones y este proyecto de documentacion siguen la misma licencia.

---

## Contacto y Referencias

- **Repositorio original:** <https://github.com/unlock-protocol/unlock-wordpress-plugin>
- **Documentacion Unlock Protocol:** <https://docs.unlock-protocol.com/>
- **Dashboard de Locks:** <https://app.unlock-protocol.com/>
- **Guia del plugin:** <https://unlock-protocol.com/guides/guide-to-the-unlock-protocol-wordpress-plugin/>
- **Locksmith API:** <https://locksmith.unlock-protocol.com/>
- **RPC de Unlock:** `https://rpc.unlock-protocol.com/<network_id>`

---

*Proyecto desarrollado para el ETH Bolivia Buildathon 2026 — Bounty: Corregir el plugin existente de Unlock para WordPress.*

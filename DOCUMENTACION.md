# Documentación — Auditoría y corrección del plugin Unlock Protocol para WordPress

> Bounty: **ETH Bolivia Buildathon 2026 — "Corregir el plugin existente de Unlock para WordPress"** ($400 USD)
> Repositorio objetivo: <https://github.com/unlock-protocol/unlock-wordpress-plugin>
> Estado de esta documentación: **auditoría de código estática completada**. Las correcciones y el proyecto de demostración se describen en el plan de trabajo.

---

## Índice

1. [Qué es Unlock Protocol](#1-qué-es-unlock-protocol)
2. [Qué hace el plugin de WordPress](#2-qué-hace-el-plugin-de-wordpress)
3. [Arquitectura del plugin](#3-arquitectura-del-plugin)
4. [Flujo funcional completo](#4-flujo-funcional-completo)
5. [Entorno de desarrollo local](#5-entorno-de-desarrollo-local)
6. [Auditoría: resumen de hallazgos](#6-auditoría-resumen-de-hallazgos)
7. [Bugs funcionales (severidad crítica/alta)](#7-bugs-funcionales-severidad-críticaalta)
8. [Problemas de seguridad](#8-problemas-de-seguridad)
9. [Compatibilidad con WordPress/PHP](#9-compatibilidad-con-wordpressphp)
10. [Problemas en JavaScript/React](#10-problemas-en-javascriptreact)
11. [Dependencias desactualizadas](#11-dependencias-desactualizadas)
12. [Plan de correcciones (commits atómicos)](#12-plan-de-correcciones-commits-atómicos)
13. [Proyecto de demostración](#13-proyecto-de-demostración)
14. [Entregables del bounty](#14-entregables-del-bounty)
15. [Convenciones del repositorio](#15-convenciones-del-repositorio)
16. [Referencias](#16-referencias)

---

## 1. Qué es Unlock Protocol

**Unlock Protocol** es un protocolo de membresías on-chain. Sus piezas fundamentales son:

| Concepto | Descripción |
|---|---|
| **Lock** | Contrato inteligente que define las reglas de una membresía (precio, duración, cantidad de miembros, etc.). |
| **Key** | NFT **ERC-721** que representa la membresía. Poseer una Key válida = tener acceso. |
| **Network** | Red EVM donde está desplegado el Lock (Ethereum mainnet, Polygon, Gnosis, Optimism, Arbitrum, BNB Chain, testnets…). |
| **Checkout** | UI oficial de Unlock (`https://app.unlock-protocol.com/checkout`) donde el usuario conecta su wallet y compra/reclama una Key. |
| **Locksmith** | API oficial de Unlock (`https://locksmith.unlock-protocol.com`) que valida el OAuth de la cuenta Unlock. |

La verificación de acceso se hace **directamente contra el contrato** (llamada `eth_call` a `getHasValidKey(address)`), no contra una base de datos central. Esto es clave para entender el plugin: WordPress no almacena si el usuario tiene membresía; pregunta al contrato.

---

## 2. Qué hace el plugin de WordPress

El plugin permite a un administrador proteger contenido detrás de uno o varios Locks:

- **Bloqueo de post/página completa** (full-post / full-page).
- **Bloqueo a nivel de bloque** (Gutenberg), para proteger solo una parte de un artículo público.
- **Login con Unlock**: el visitante conecta su wallet vía OAuth con Locksmith y el plugin crea/vincula un usuario de WordPress.
- **Checkout**: si el usuario no tiene Key, se le muestra un botón que abre la UI de checkout de Unlock.
- **Panel de administración** (`Ajustes → Unlock Protocol`) para configurar:
  - Textos y colores de los botones de Login y Checkout.
  - Imagen de fondo difuminada y texto de llamada a la acción.
  - Lista de **redes** (ID, nombre, endpoint RPC).
  - URLs base de checkout y Locksmith.
  - `custom_paywall_config` (JSON para personalizar el checkout).

El plugin delega toda la parte criptográfica al checkout oficial y a las llamadas JSON-RPC; no maneja claves privadas.

---

## 3. Arquitectura del plugin

### 3.1 Estructura de carpetas

```
unlock-wordpress-plugin/                 (raíz del repo)
├── package.json                         Scripts de build (wp-scripts) y deps JS
├── webpack.config.js                    Config de build (hereda de @wordpress/scripts)
├── yarn.lock
├── README.txt                           Readme de WordPress.org (metadatos del plugin)
├── src/                                 Código FUENTE (se compila)
│   └── assets/
│       ├── js/
│       │   ├── main.js                  Entry global (importa SCSS)
│       │   ├── blocks.js                Entry del bloque Gutenberg
│       │   ├── full-post-page.js        Entry del panel de full post/page
│       │   ├── admin-locks.js           Componente React compartido de Locks
│       │   ├── blocks/unlock-content/   Edit del bloque
│       │   ├── full-post-page/…         Edit del panel full post/page
│       │   └── admin/                   App React del panel de ajustes
│       ├── scss/
│       └── img/
└── unlock-wordpress-plugin/             PLUGIN INSTALABLE (PHP + assets compilados)
    ├── unlock-protocol.php              Bootstrap del plugin
    ├── inc/
    │   ├── helpers/
    │   │   ├── autoloader.php           Autoloader PSR-4 casero
    │   │   └── custom-functions.php     Funciones globales `unlock_protocol_*` / `up_*`
    │   ├── traits/trait-singleton.php   Patrón Singleton
    │   └── classes/
    │       ├── class-plugin.php         Orquestador
    │       ├── class-assets.php         Registro de scripts/estilos
    │       ├── class-login.php          Login OAuth + registro de usuario
    │       ├── class-unlock.php         Lógica de red, RPC y render
    │       ├── class-blocks.php         Assets del editor de bloques
    │       ├── class-fullpostpage.php   Meta + assets de full post/page
    │       ├── class-menu.php           Menú de ajustes
    │       ├── class-installer.php      Redes por defecto al activar
    │       ├── blocks/class-unlock-box-block.php
    │       ├── fullpostpage/class-unlock-box-full-post-page.php
    │       ├── rest-api/class-rest-base.php
    │       ├── rest-api/class-settings.php
    │       └── utils/class-helper.php
    └── templates/login/
        ├── button.php
        └── checkout-button.php
```

### 3.2 Namespace y autoloader

- Namespace raíz: `Unlock_Protocol\Inc\`.
- `inc/helpers/autoloader.php` convierte el namespace a ruta (`str_replace('_', '-', strtolower(...))`) y registra `spl_autoload_register`.
- Todas las clases usan el trait `Singleton` (`get_instance()`), por lo que los hooks se registran una sola vez.

### 3.3 Clases principales y responsabilidades

| Clase | Archivo | Responsabilidad |
|---|---|---|
| `Plugin` | `class-plugin.php` | Instancia todos los módulos y registra el hook de activación. |
| `Assets` | `class-assets.php` | Encola CSS/JS en front, login y admin; localiza `unlockProtocol` (REST root, nonce, textos). |
| `Login` | `class-login.php` | Añade botón al formulario de login, valida el `code` OAuth, crea/vincula usuario WP. |
| `Unlock` | `class-unlock.php` | Lista de redes, llamada RPC `getHasValidKey`, URLs de login/checkout, render de contenido. |
| `Blocks` | `class-blocks.php` | Encola assets del editor del bloque. |
| `FullPostPage` | `class-fullpostpage.php` | Registra el meta `unlock_protocol_post_locks` y sus assets. |
| `Menu` | `class-menu.php` | Página de ajustes y aviso si el registro de usuarios está desactivado. |
| `Installer` | `class-installer.php` | Al activar, guarda versión y redes por defecto. |
| `Settings` (REST) | `rest-api/class-settings.php` | Endpoints `GET/POST /unlock-protocol/v1/settings` y `/settings/delete`. |
| `Unlock_Box_Block` | `blocks/class-unlock-box-block.php` | Registra el bloque dinámico `unlock-protocol/unlock-box`. |
| `Unlock_Box_Full_Post_Page` | `fullpostpage/…` | Filtra `the_content` y aplica el bloqueo full-post. |
| `Helper` | `utils/class-helper.php` | `filter_input()` compatible CLI y `unique_username()`. |

### 3.4 Endpoints REST

| Método | Ruta | Permiso | Función |
|---|---|---|---|
| `GET` | `/unlock-protocol/v1/settings` | `manage_options` | Devuelve todos los ajustes. |
| `POST` | `/unlock-protocol/v1/settings` | `manage_options` | Actualiza `general` o añade `networks`. |
| `POST` | `/unlock-protocol/v1/settings/delete` | `manage_options` | Elimina una red por índice. |

La verificación de permisos usa `current_user_can('manage_options')`; el nonce lo añade `wp_localize_script` (`rest.nonce`) y `apiFetch` lo envía automáticamente.

### 3.5 Hooks principales

```php
// Acciones
register_activation_hook( ... , [Plugin::class, 'activate'] );
add_action( 'wp_enqueue_scripts',        [Assets, 'enqueue_scripts'] );
add_action( 'login_enqueue_scripts',     [Assets, 'enqueue_scripts'] );
add_action( 'admin_enqueue_scripts',     [Assets, 'admin_enqueue_scripts'] );
add_action( 'rest_api_init',             [API, 'register_api'] );
add_action( 'login_form',                [Login, 'login_button'] );
add_action( 'authenticate',              [Login, 'authenticate'] );
add_action( 'wp',                        [Login, 'login_user'] );
add_action( 'init',                      [Unlock_Box_Block, 'register_block_type'] );
add_action( 'init',                      [FullPostPage, 'meta_fields_register_meta'] );
add_action( 'enqueue_block_editor_assets', [Blocks, 'enqueue_assets'] );
add_action( 'admin_menu',                [Menu, 'admin_menu'] );

// Filtros
add_filter( 'the_content',               [Unlock_Box_Full_Post_Page, 'trigger_unlockprotocol_flow'] );
add_filter( 'unlock_authenticate_user',  [Login, 'authenticate'] );
```

---

## 4. Flujo funcional completo

### 4.1 Protección de contenido

```
Autor escribe un post/página
        │
        ├─ Bloque Gutenberg "Unlock Protocol"
        │     → atributo `locks` = [{ address, network }, …]
        │
        └─ Panel "Full post/page" (meta `unlock_protocol_post_locks`)
              → JSON string con [{ address, network }, …]

Visitante abre la página
        │
        ├─ render_content($locks, $content)  (class-unlock.php)
        │     ├─ ¿admin o autor?            → muestra contenido
        │     ├─ ¿no logueado o sin wallet? → botón "Login with Unlock"
        │     ├─ ¿tiene Key? (has_access)   → muestra contenido
        │     └─ ¿no tiene Key?             → botón "Purchase this"
        │
        └─ has_access(): por cada lock → wp_remote_post al RPC con
              eth_call → getHasValidKey(direcciónUsuario)
              hexdec(resultado) == 1  ⇒ acceso concedido
```

### 4.2 Login con wallet

```
Usuario pulsa "Login with Unlock"
   → get_login_url(): app.unlock-protocol.com/checkout?client_id=…&redirect_uri=…&state=nonce
   → Usuario completa OAuth en Locksmith
   → vuelve a wp-login.php?code=…&state=…
   → Login::authenticate(): verifica nonce, POST a Locksmith con el code
   → Locksmith devuelve { me: "0x…" }
   → busca/crea usuario WP con meta `unlock_ethereum_address`
   → wp_set_auth_cookie() + redirección
```

### 4.3 Checkout de membresía

```
Botón "Purchase this" → get_checkout_url()
   → app.unlock-protocol.com/checkout?redirectUri=…&paywallConfig={"locks":{…},"pessimistic":true}
   → Usuario compra/reclama la Key
   → vuelve a la página
   → has_access() detecta la Key y muestra el contenido
```

---

## 5. Entorno de desarrollo local

### 5.1 Opciones recomendadas

**Opción A — `wp-env` (la más reproducible, requiere Docker):**

```bash
# En la raíz del repo
npx @wordpress/env start
# WordPress: http://localhost:8888  (admin / password)
```

Con `wp-env` se puede mapear el plugin dentro del contenedor y activarlo con WP-CLI.

**Opción B — Docker + WordPress + MySQL:**

```bash
docker network create wpnet
docker run -d --name wpdb --network wpnet \
  -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=wordpress mysql:8
docker run -d --name wp --network wpnet -p 8080:80 \
  -e WORDPRESS_DB_HOST=wpdb -e WORDPRESS_DB_USER=root \
  -e WORDPRESS_DB_PASSWORD=root -e WORDPRESS_DB_NAME=wordpress wordpress:latest
# Copiar/symlink del plugin:
#   wp-content/plugins/unlock-wordpress-plugin -> <repo>/unlock-wordpress-plugin
```

**Opción C — LocalWP** (recomendada por el README): crear sitio, y enlazar simbólicamente `wp-content/plugins/unlock-wordpress-plugin`.

**Opción D — WP-CLI + servidor embebido de PHP (rápida, sin Docker):**

```bash
wp core download
wp config create --dbname=unlock --dbuser=root --dbpass=root
wp core install --url=http://localhost:8080 --title="Unlock Demo" \
  --admin_user=admin --admin_password=admin --admin_email=admin@example.com
wp server --host=localhost --port=8080
wp plugin activate unlock-protocol
```

### 5.2 Compilar assets

```bash
yarn install
yarn build:all      # build + admin + blocks + POT
# o
yarn release        # build:all + zip
```

> Nota: el plugin instalable vive en `unlock-wordpress-plugin/` y los assets compilados se escriben en `unlock-wordpress-plugin/assets/build/`. Ese directorio **no está versionado** (ver `.gitignore`), por lo que hay que compilar antes de probar desde el código fuente.

### 5.3 Checklist de pruebas manuales

- [ ] Activar el plugin y comprobar que se crean las redes por defecto.
- [ ] Ajustes → Unlock Protocol → añadir/eliminar red (validaciones).
- [ ] Crear un Lock en testnet (Polygon Amoy / Base Sepolia) desde `app.unlock-protocol.com`.
- [ ] Añadir bloque `Unlock Protocol`, seleccionar red y dirección, verificar validación de dirección.
- [ ] Publicar y comprobar el estado bloqueado sin wallet.
- [ ] Login con wallet y verificar que el contenido se desbloquea.
- [ ] Probar full-post/page con el panel lateral.
- [ ] Probar con PHP 8.1/8.2 y WordPress 6.x (revisar `debug.log`).
- [ ] Ejecutar `phpcs` con `WordPress` estándar.

---

## 6. Auditoría: resumen de hallazgos

| # | Severidad | Área | Archivo | Resumen |
|---|---|---|---|---|
| 1 | **Crítica** | Funcional | `class-unlock.php` | Clave `'mainnet'` duplicada en `networks_list()`: se pierde Goerli. |
| 2 | **Crítica** | Funcional | `class-unlock.php` | `$url` sin inicializar en `has_access()`; puede validar contra la red equivocada. |
| 3 | **Crítica** | Funcional | `class-unlock.php` | `substr(null, 2)` en `validate()`; sin validar lock/URL ni código HTTP. |
| 4 | **Crítica** | Funcional | `class-unlock.php` / full-post | `$locks` puede ser `null`/no-array y `render_content()` hace `foreach` sobre él. |
| 5 | **Alta** | Funcional | `class-unlock-box-full-post-page.php` | `the_content` se filtra en cualquier contexto (feeds, REST, excerpts, loops). |
| 6 | **Alta** | Funcional | `class-unlock-box-block.php` | `$attributes['locks']` sin `isset()`. |
| 7 | **Alta** | Funcional | `class-helper.php` | `unique_username()` es un **bucle infinito** (`$count` nunca incrementa). |
| 8 | **Alta** | Funcional | `class-assets.php` | `get_file_version()` usa una **URL** con `file_exists()` (siempre `false`). |
| 9 | **Alta** | Funcional | `class-blocks.php` / `class-fullpostpage.php` | `filemtime()`/`include` sobre archivos que pueden no existir. |
| 10 | **Alta** | Funcional | `admin-locks.js` | `lockValid()` considera **válido** un lock con `network === -1` (sin red). |
| 11 | **Media** | Seguridad | `class-settings.php` | `delete_network()`: validación inútil tras `(int)`; índice inexistente → warning. |
| 12 | **Media** | Seguridad | `class-settings.php` | `update_general_settings()` no valida que `$data` sea array; rompe el JSON de paywall. |
| 13 | **Media** | Seguridad | `class-login.php` | `esc_html()` para construir emails; falta validar `client_id`/`redirect_uri`. |
| 14 | **Media** | Seguridad | `class-unlock.php` | Llamadas RPC sin timeout explícito ni verificación de `response_code`. |
| 15 | **Media** | Seguridad | `templates/login/*.php` | `$login_bg_image` / `$checkout_bg_image` usadas sin `isset()` → warnings. |
| 16 | **Media** | Compatibilidad | `README.txt` | `Tested up to: 5.9`, `Requires PHP: 7.0` desactualizados. |
| 17 | **Baja** | WPCS | varios | Mezcla de `array()` y `[]`; indentación con espacios en `class-unlock-box-full-post-page.php`; llaves y comillas no WPCS en `class-unlock.php`. |
| 18 | **Baja** | JS/React | `admin-locks.js` | `.map()` sin `key`; dependencia incompleta en `useEffect`. |
| 19 | **Baja** | JS/React | `admin/utils.js` | `resp.networks` puede ser `undefined` → `Object.entries` lanza. |
| 20 | **Baja** | Dependencias | `package.json` | `@wordpress/scripts ^19`, `api-fetch ^5`, `server-side-render ^3` muy antiguos. |
| 21 | **Baja** | Docs | `README.txt` | Enlace mal formado `[deploying your first lock]https://…`. |

---

## 7. Bugs funcionales (severidad crítica/alta)

### Bug 1 — Redes por defecto: clave `'mainnet'` duplicada

**Archivo:** `unlock-wordpress-plugin/inc/classes/class-unlock.php:274-314`

```php
public static function networks_list() {
    $networks = array(
        'mainnet'  => array( 'network_name' => 'goerli',  'network_id' => 5,  'network_rpc_endpoint' => 'https://rpc.unlock-protocol.com/5' ),
        'mainnet'  => array( 'network_name' => 'mainnet', 'network_id' => 1,  'network_rpc_endpoint' => 'https://rpc.unlock-protocol.com/1' ),
        // …
    );
}
```

**Causa raíz:** la primera entrada se indexa con `'mainnet'` y la segunda la sobrescribe. **Goerli (id 5) desaparece de la lista.**

**Impacto:** el README recomienda Goerli como red de pruebas, pero al activar el plugin esa red no existe en la configuración; los Locks de testnet no se pueden validar. También afecta a `Installer::add_default_networks()` (`class-installer.php:59-71`), que llama a este método.

**Reproducción:**
1. Activar el plugin en una instalación limpia.
2. `wp option get unlock_protocol_settings --format=json`.
3. Verificar que no aparece `network_id: 5`.

**Corrección propuesta:** usar claves únicas (`goerli`, `mainnet`, …) y añadir las testnets vigentes (Sepolia, Polygon Amoy, Base Sepolia) según la documentación actual de Unlock.

---

### Bug 2 — `has_access()`: variable `$url` sin inicializar

**Archivo:** `class-unlock.php:61-84`

```php
foreach ( $locks as $lock ) {
    if ( ! $has_unlocked ) {
        foreach ( $networks as $network ) {
            if ( $network['network_id'] == $lock['network'] ) {
                $url = $network['network_rpc_endpoint'];
            }
        }
        $validation = self::validate( $url, $lock['address'], $user_ethereum_address );
        if ( is_wp_error( $validation ) || ! isset( $validation['result'] ) ) {
            break; // ← corta TODO el bucle de locks
        }
        $has_unlocked = hexdec( $validation['result'] ) == 1;
    }
}
```

**Causa raíz:**
- Si el lock apunta a una red que ya no está en `$networks`, `$url` conserva el valor de la iteración anterior (o queda indefinida) y se hace la llamada RPC a una red incorrecta.
- `break` detiene el recorrido de **todos** los locks ante el primer error, en lugar de continuar con el siguiente.
- `hexdec()` sobre un resultado vacío/inválido emite warnings.

**Corrección propuesta:** inicializar `$url = null`, `continue`/`break` según el caso, usar `isset( $lock['network'], $lock['address'] )`, y devolver `false` si no se encuentra la red.

---

### Bug 3 — `validate()`: dirección nula y falta de validación RPC

**Archivo:** `class-unlock.php:97-133`

```php
$user_ethereum_address = $user_ethereum_address ? $user_ethereum_address : up_get_user_ethereum_address();
$user_ethereum_address = substr( $user_ethereum_address, 2 ); // ← null → warning PHP 8
```

**Causa raíz:**
- `substr(null, 2)` genera `Deprecated: substr(): Passing null to parameter #1` en PHP 8.1+.
- No se valida el formato de `$lock_address` (debería ser `0x` + 40 hex).
- `wp_remote_post()` no especifica `timeout` ni comprueba `wp_remote_retrieve_response_code()`.
- `json_decode()` puede devolver `null` y luego `has_access()` accede a `$validation['result']`.

**Corrección propuesta:** validar la dirección con `preg_match('/^0x[a-fA-F0-9]{40}$/', …)`, añadir `'timeout' => 15`, comprobar el código HTTP y devolver `WP_Error` con mensajes claros traducibles.

---

### Bug 4 — `render_content()` recibe datos no confiables

**Archivos:** `class-unlock.php:397-417`, `class-unlock-box-full-post-page.php:55-69`, `class-unlock-box-block.php:85-88`

```php
public static function render_content( $locks, $content ) {
    if ( current_user_can( 'manage_options' ) || ( get_the_author_meta( 'ID' ) === get_current_user_id() ) ) {
        return $content;
    }
    // …
    if ( ! Unlock::has_access( $networks, $locks ) ) { … }
}
```

**Causa raíz:**
- `json_decode( $attributes, true )` puede devolver `null`; `foreach ( $locks as … )` en `has_access()` falla.
- `get_the_author_meta('ID')` dentro de un loop puede devolver el autor de otro post.
- El filtro `the_content` de full-post se ejecuta también en feeds, REST, excerpts, widgets y loops, no solo en la vista principal de un singular.

**Corrección propuesta:**
- Normalizar `$locks` a array y salir temprano si está vacío.
- En `trigger_unlockprotocol_flow()`: `if ( ! is_singular() || ! in_the_loop() || ! is_main_query() ) return $content;`.
- Usar `get_the_author_meta( 'ID', get_the_ID() )`.

---

### Bug 5 — `Helper::unique_username()` bucle infinito

**Archivo:** `inc/classes/utils/class-helper.php:154-163`

```php
while ( username_exists( $uname ) ) {
    $uname = $uname . '' . $count; // ← $count nunca cambia
}
```

**Causa raíz:** `$count` nunca se incrementa; si el nombre existe, el bucle no termina. Aunque hoy la función no se usa en el flujo principal, es un bug latente que agotaría el tiempo de ejecución de PHP.

**Corrección propuesta:** `$count++` dentro del bucle (o `$uname = $username . $count; $count++;`).

---

### Bug 6 — `get_file_version()` usa una URL como ruta de archivo

**Archivo:** `inc/classes/class-assets.php:234-242`

```php
$file_path = sprintf( '%s/%s', UNLOCK_PROTOCOL_BUILD_URI, $file ); // URI, no path
return file_exists( $file_path ) ? filemtime( $file_path ) : false;
```

**Causa raíz:** `UNLOCK_PROTOCOL_BUILD_URI` es una URL (`http://…/assets/build`); `file_exists()` espera una ruta del sistema de archivos. Siempre devuelve `false`, por lo que los assets no se cache-bustean.

**Corrección propuesta:** usar `UNLOCK_PROTOCOL_BUILD_DIR` (definido en `unlock-protocol.php:17`) y comprobar `file_exists()` antes de `filemtime()`.

---

### Bug 7 — Assets de bloque/full-post con `filemtime()` sin comprobar

**Archivos:** `class-blocks.php:64-95`, `class-fullpostpage.php:83-114`

```php
$asset_file = include UNLOCK_PROTOCOL_BUILD_DIR . '/js/blocks.asset.php';
// …
filemtime( UNLOCK_PROTOCOL_PATH . '/assets/build/js/blocks.js' )
```

**Causa raíz:** si los assets no están compilados (instalación desde Git sin `yarn build:all`), `include` y `filemtime()` fallan con warnings. Además `wp_register_style()` apunta a `css/blocks.css` / `css/full-post-page.css` que solo existen tras el build.

**Corrección propuesta:** comprobar `file_exists()` para el `.asset.php` y los assets; usar `UNLOCK_PLUGIN_VERSION` como fallback de versión.

---

### Bug 8 — `lockValid()` acepta un lock sin red

**Archivo:** `src/assets/js/admin-locks.js:43-56`

```js
const lockValid = (lock) => {
  if (lock.network === -1) {
    return true; // ← un lock sin red se considera válido
  }
  // …
};
```

**Causa raíz:** la opción "None" tiene `value: -1`; `locksValid()` comprueba `lock.network === -1` y marca inválido, pero `lockValid()` retorna `true` para ese mismo caso. La lógica es contradictoria.

**Corrección propuesta:** devolver `false` cuando `lock.network === -1` y validar en `AddLockForm.onSave()` que la red y la dirección sean válidas antes de guardar.

---

## 8. Problemas de seguridad

### 8.1 `delete_network()` sin validación de índice

**Archivo:** `rest-api/class-settings.php:129-161`

```php
$network_index = (int) sanitize_text_field( $request->get_param( 'network_index' ) );
if ( '' === $network_index || ! is_int( $network_index ) ) { // siempre false
    return new \WP_Error( … );
}
// …
$removed_network = $networks[ $network_index ]; // índice inexistente → warning
```

**Impacto:** un administrador (o un CSRF que supere el nonce) puede provocar warnings/`Undefined array key`, y no se valida que el índice exista. El acceso ya está restringido a `manage_options`, por lo que el riesgo es de robustez más que de escalada.

**Corrección:** comprobar `isset( $networks[ $network_index ] )` y devolver `WP_Error` con `400`; aplicar `array_values()` al guardar para mantener índices consecutivos (evita que el REST devuelva un objeto en lugar de un array).

### 8.2 `update_general_settings()` sin validación de tipo

**Archivo:** `rest-api/class-settings.php:172-182`

```php
$data = array_map( 'sanitize_text_field', $data );
```

**Impacto:** si `settings` no es un array, `array_map` emite warning. `custom_paywall_config` es un JSON y `sanitize_text_field` puede alterar comillas/estructura. Los colores no se validan como hex.

**Corrección:** comprobar `is_array( $data )`, validar colores con `sanitize_hex_color()` y tratar `custom_paywall_config` como JSON (`json_decode`/`wp_json_encode`) o como texto sin filtrar comillas.

### 8.3 Login OAuth

**Archivo:** `class-login.php:90-173`

- `get_email_address()` usa `esc_html()` para construir un email; corresponde `sanitize_email()`/`sanitize_text_field()`.
- No se revalida `client_id`/`redirect_uri` en la respuesta OAuth (se confía en el `state`). Es aceptable pero conviene documentarlo.
- `register()` no comprueba `is_wp_error( $uid )` antes de `get_user_by( 'id', $uid )` → posible fatal si `wp_insert_user` falla.

**Corrección:** usar `sanitize_email()`/`sanitize_text_field()`, manejar `WP_Error` en `register()` y registrar la dirección con validación de checksum EVM (opcional).

### 8.4 Llamadas RPC

- Añadir `'timeout' => 15` y comprobar `wp_remote_retrieve_response_code()`.
- No registrar datos sensibles; no hay claves privadas en el plugin (correcto).
- El plugin **no** maneja claves privadas ni seed phrases: toda la firma ocurre en la wallet del usuario. Esto debe mantenerse.

---

## 9. Compatibilidad con WordPress/PHP

| Punto | Estado actual | Recomendación |
|---|---|---|
| `README.txt` | `Tested up to: 5.9` | Actualizar a WordPress 6.x. |
| `README.txt` | `Requires PHP: 7.0` | Subir a `7.4` o `8.0` y probar en 8.1/8.2/8.3. |
| Header del plugin | Sin `Requires at least` / `Requires PHP` | Añadirlos en `unlock-protocol.php`. |
| `filter_input` con `FILTER_SANITIZE_FULL_SPECIAL_CHARS` | Deprecado en PHP 8.1 en combinación con `FILTER_FLAG_STRIP_HIGH` | Revisar `Helper::filter_input` y la llamada en `Login::authenticate`. |
| Arrays | Mezcla de `array()` y `[]` | Unificar según WPCS. |
| `filemtime()` | Sobre archivos que pueden no existir | Comprobar existencia. |
| Dependencias JS | `@wordpress/scripts ^19` (React 17) | Actualizar a la versión alineada con WordPress 6.x. |

---

## 10. Problemas en JavaScript/React

| Archivo | Línea | Problema | Corrección |
|---|---|---|---|
| `admin-locks.js` | 24 | `.map()` sin `key` | Añadir `key={lock.address}`. |
| `admin-locks.js` | 44 | Lock sin red se considera válido | Devolver `false` si `network === -1`. |
| `admin-locks.js` | 88 | `disabled={!network}` permite `-1` | `disabled={!network \|\| network === -1}`. |
| `admin-locks.js` | 122-130 | `useEffect` con dependencia incompleta | Añadir `lock.address`. |
| `admin/utils.js` | 13 | `resp.networks` puede ser `undefined` | `Object.entries(resp.networks ?? {})`. |
| `admin/General.js` | 32, 66 | `catch` vacío y `__(err.message)` | Manejar el error y no usar mensajes dinámicos como dominio. |
| `blocks/unlock-content/edit.js` | 25 | `locks.length` sin comprobar | `if (!Array.isArray(locks) || locks.length === 0)`. |
| `Networks.js` | 198 | Índices con huecos tras eliminar | Aplicar `array_values()` en el backend. |

---

## 11. Dependencias desactualizadas

**`package.json` (actual):**

```json
"devDependencies": {
  "@wordpress/scripts": "^19.0.0",
  "rimraf": "^3.0.2",
  "shelljs": "^0.8.4"
},
"dependencies": {
  "@wordpress/api-fetch": "^5.2.4",
  "@wordpress/server-side-render": "^3.0.4",
  "sweetalert2": "^11.1.9"
}
```

- `@wordpress/scripts ^19` corresponde a WordPress 5.9 (React 17). WordPress 6.x usa versiones muy superiores (React 18, webpack 5 moderno).
- `@wordpress/api-fetch ^5` y `@wordpress/server-side-render ^3` también son de la era 5.9.
- `server-side-render` no parece usarse en el código actual; se puede eliminar.
- No hay `composer.json` ni `phpcs.xml` en el repo: **no existe configuración de PHPCS/PHPUnit**. Esto es relevante para el criterio de "cumplimiento de guías del repositorio".

---

## 12. Plan de correcciones (commits atómicos)

Se propone un commit por bug, con mensajes en formato Conventional Commits (`fix: …`), en este orden de prioridad:

| Orden | Commit | Archivos |
|---|---|---|
| 1 | `fix: correct duplicate network key and add current testnets` | `class-unlock.php`, `class-installer.php` |
| 2 | `fix: guard against undefined rpc url in has_access` | `class-unlock.php` |
| 3 | `fix: validate lock address and rpc response in validate` | `class-unlock.php` |
| 4 | `fix: normalize locks before rendering protected content` | `class-unlock.php`, `class-unlock-box-block.php` |
| 5 | `fix: only filter main singular content for full-post locking` | `class-unlock-box-full-post-page.php` |
| 6 | `fix: prevent infinite loop in unique_username` | `class-helper.php` |
| 7 | `fix: use filesystem path for asset version` | `class-assets.php` |
| 8 | `fix: guard block asset registration when build is missing` | `class-blocks.php`, `class-fullpostpage.php` |
| 9 | `fix: reject lock without network in admin ui` | `admin-locks.js` |
| 10 | `fix: validate network index before deletion` | `class-settings.php` |
| 11 | `fix: harden general settings sanitization` | `class-settings.php` |
| 12 | `fix: avoid undefined background image variables in templates` | `templates/login/*.php` |
| 13 | `fix: handle wp_insert_user errors during oauth registration` | `class-login.php` |
| 14 | `chore: update wordpress compatibility metadata` | `README.txt`, `unlock-protocol.php` |
| 15 | `chore: update js dependencies` | `package.json`, `yarn.lock` |
| 16 | `test: add phpunit coverage for access verification` | `tests/…`, `phpunit.xml`, `composer.json` |
| 17 | `docs: add fix report and demo instructions` | `README.md` |

**Reglas:** no reescribir el plugin, no reformatear archivos completos, mantener `array()` y docblocks WPCS, y ejecutar el linter antes de cerrar cada commit.

---

## 13. Proyecto de demostración

### 13.1 Objetivo

Demostrar de punta a punta que el plugin corregido funciona con un **Lock real en testnet**.

### 13.2 Componentes

1. **Lock en testnet** (recomendado: **Polygon Amoy** o **Base Sepolia**).
   - Crear en <https://app.unlock-protocol.com/locks/create>.
   - Precio bajo o gratuito para facilitar la prueba.
   - Anotar la dirección del Lock y el `network_id`.
2. **Sitio WordPress de prueba** con el plugin corregido:
   - Una **página completa** protegida (full-page).
   - Un **artículo público** con un **bloque Unlock** embebido (solo una parte protegida).
3. **Flujo a documentar:**
   - Visitante sin wallet → ve el contenido bloqueado + botón "Unlock".
   - Conecta wallet → checkout → compra/reclama la Key.
   - Vuelve a la página → el contenido se desbloquea.
4. **Despliegue público:** VPS con Docker Compose, o WordPress Playground si es compatible. Alternativa: contenedor gratuito (Fly.io/Railway) con WordPress + MySQL.

### 13.3 Entregables de la demo

- URL pública del sitio.
- Dirección del Lock en testnet.
- Video de ≤ 3 minutos (problema → corrección → flujo completo).
- README con instrucciones de instalación y prueba.

---

## 14. Entregables del bounty

| Entregable | Estado / acción |
|---|---|
| Nombre del proyecto | "Unlock WP Plugin — Fix & Demo" (sugerido) |
| Equipo e integrantes | Completar |
| Descripción breve (2–4 líneas) | Completar con la lista de bugs corregidos |
| Fork + PR contra `unlock-protocol/unlock-wordpress-plugin` | Crear rama `fix/…` y abrir PR |
| README con bugs, integración, instalación | Crear |
| URL pública de demo | Pendiente de despliegue |
| Video demo ≤ 3 min | Pendiente |
| Dirección del Lock en testnet | Pendiente |
| Contacto | Completar |

> Nota: en este entorno **no hay `gh` (GitHub CLI) ni credenciales**, por lo que el push y la apertura del PR deben ejecutarse desde una máquina con acceso al fork. Todos los commits y archivos quedan preparados localmente.

---

## 15. Convenciones del repositorio

- **PHP:** WordPress Coding Standards (WPCS); docblocks con `@since`, `@param`, `@return`; prefijo `unlock_protocol_` / `up_`.
- **Indentación PHP:** tabs (los archivos existentes usan tabs).
- **JS:** Prettier (`.prettierrc`), ESLint (`src/assets/.eslintrc.json`), Stylelint.
- **Build:** `@wordpress/scripts`; assets compilados a `unlock-wordpress-plugin/assets/build/`.
- **Commits:** descriptivos; este trabajo usará `fix:`/`chore:`/`test:`/`docs:`.
- **No versionar:** `node_modules`, `assets/build`, `dist`, `.pot` generado.
- **Seguridad:** no incluir claves privadas ni credenciales; usar variables de entorno y wallets de testnet.

---

## 16. Referencias

- Repositorio: <https://github.com/unlock-protocol/unlock-wordpress-plugin>
- Guía del plugin: <https://unlock-protocol.com/guides/guide-to-the-unlock-protocol-wordpress-plugin/>
- Documentación general: <https://docs.unlock-protocol.com/>
- Herramientas/SDKs: <https://docs.unlock-protocol.com/tools/>
- Dashboard de Locks: <https://app.unlock-protocol.com/>
- Locksmith: <https://locksmith.unlock-protocol.com/>
- RPC de Unlock: `https://rpc.unlock-protocol.com/<network_id>`

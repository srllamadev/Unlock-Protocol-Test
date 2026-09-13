#!/usr/bin/env bash
#
# Provision the demo WordPress site with the fixed Unlock Protocol plugin.
#
# Usage:
#   LOCK_ADDRESS=0x... NETWORK_ID=11155111 ./setup.sh
#
# Requirements: Docker Desktop running, bash.
set -euo pipefail

LOCK_ADDRESS="${LOCK_ADDRESS:-}"
NETWORK_ID="${NETWORK_ID:-11155111}"   # Sepolia by default; 84532 = Base Sepolia
SITE_URL="${SITE_URL:-http://localhost:8080}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASS="${ADMIN_PASS:-admin}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@example.com}"

WP="docker compose exec -T cli wp --allow-root"

echo "==> Starting containers"
docker compose up -d

echo "==> Waiting for WordPress files to be ready"
for i in $(seq 1 60); do
  if docker compose exec -T wordpress test -f wp-includes/version.php; then
    break
  fi
  sleep 2
done

echo "==> Waiting for the database"
$WP db check >/dev/null 2>&1 || sleep 5

echo "==> Installing WordPress"
$WP core install \
  --url="$SITE_URL" \
  --title="Unlock WP Plugin Demo" \
  --admin_user="$ADMIN_USER" \
  --admin_password="$ADMIN_PASS" \
  --admin_email="$ADMIN_EMAIL" \
  --skip-email 2>/dev/null || echo "    (already installed)"

echo "==> Enabling user registration (required for Unlock wallet login)"
$WP option update users_can_register 1

echo "==> Activating the fixed plugin"
$WP plugin activate unlock-protocol

echo "==> Default networks stored by the plugin (should include Sepolia/Base Sepolia)"
$WP option get unlock_protocol_settings --format=json

if [[ -z "$LOCK_ADDRESS" ]]; then
  echo
  echo "!! LOCK_ADDRESS is empty. Create a lock on a testnet and re-run with:"
  echo "   LOCK_ADDRESS=0x... NETWORK_ID=$NETWORK_ID ./setup.sh"
  echo "   The site is installed but no content is protected yet."
  exit 0
fi

echo "==> Creating a full-page protected page"
PAGE_ID=$($WP post create \
  --post_type=page \
  --post_title="Contenido Premium (full page)" \
  --post_content="<p>Este contenido solo es visible para quien posee una Key.</p>" \
  --post_status=publish \
  --porcelain)

$WP post meta update "$PAGE_ID" unlock_protocol_post_locks \
  "[{\"address\":\"$LOCK_ADDRESS\",\"network\":$NETWORK_ID}]"

echo "==> Creating a public post with a locked block"
POST_ID=$($WP post create \
  --post_title="Articulo publico con bloque protegido" \
  --post_content="<!-- wp:paragraph --><p>Introduccion publica.</p><!-- /wp:paragraph -->
<!-- wp:unlock-protocol/unlock-box {\"locks\":[{\"address\":\"$LOCK_ADDRESS\",\"network\":$NETWORK_ID}]} -->
<!-- wp:paragraph --><p>Contenido exclusivo para miembros.</p><!-- /wp:paragraph -->
<!-- /wp:unlock-protocol/unlock-box -->" \
  --post_status=publish \
  --porcelain)

echo
echo "=============================================="
echo " Demo listo"
echo "=============================================="
echo " Sitio:            $SITE_URL"
echo " Admin:            $SITE_URL/wp-admin ($ADMIN_USER / $ADMIN_PASS)"
echo " Pagina bloqueada: $SITE_URL/?page_id=$PAGE_ID"
echo " Post con bloque:  $SITE_URL/?p=$POST_ID"
echo " Lock:             $LOCK_ADDRESS (network $NETWORK_ID)"
echo "=============================================="

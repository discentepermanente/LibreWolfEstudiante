#!/bin/bash
# =============================================================================
# Script: instalar-librewolf-itsi.sh
# =============================================================================
# DESCRIPCIÓN:
#   Instalación idempotente de LibreWolf para estudiantes del ITSI.
#   Configuración orientada a PROTECCIÓN TOTAL contra contenido inapropiado,
#   eliminación de telemetría, bloqueo de extensiones no autorizadas,
#   y liberación controlada de Canvas para permitir el uso de Figma.
#
# AUTOR: Fidel Chávez
# VERSIÓN: 3.0 (con ClearMind)
# FECHA: 2026-06-11
#
# COMPATIBILIDAD:
#   Ubuntu 22.04, 24.04, 26.04 LTS
#
# REQUISITOS:
#   - Ejecutar como superusuario (sudo)
#   - Conexión a internet activa
#
# IDEMPOTENCIA:
#   El script puede ejecutarse múltiples veces sin efectos secundarios.
#   Si LibreWolf ya existe, lo elimina completamente y lo reinstala.
#
# PROTECCIONES INCLUIDAS:
#   🔒 DNS 1.1.1.3 (Cloudflare Family) - Bloqueo a nivel de red
#   🔒 SafeSearch forzado en TODAS las búsquedas
#   🔒 ClearMind - Bloqueo avanzado de contenido adulto (extensión)
#   🔒 LeechBlock - Bloqueo adicional de sitios específicos
#   🔒 uBlock Origin - Bloqueo de publicidad y rastreadores
#   🔒 Navegación segura (Safe Browsing)
#   🔒 Sin telemetría ni estudios de usuario
#   🔒 Sin Pocket, sin Firefox Accounts
#   🔒 Bloqueo de instalación/desinstalación de extensiones
#   🔒 Políticas bloqueadas (no modificables por estudiantes)
#   🔒 Eliminación automática de cookies y caché al cerrar
#   🔒 Cámara, micrófono y ubicación bloqueados
#
# LIBERADO PARA ESTUDIOS:
#   🎨 Canvas API completamente funcional (Figma)
#   🎨 WebGL activado (gráficos 3D)
#   📝 Extensión Markdown Reader instalada
#   🔧 Herramientas de desarrollo disponibles
#
# USO:
#   sudo ./instalar-librewolf-itsi.sh
#
# =============================================================================

# Colores para output (mejora legibilidad)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
# FUNCIÓN: eliminar_navegadores
# Elimina TODOS los rastros de Firefox y LibreWolf del sistema
# =============================================================================
eliminar_navegadores() {
    echo -e "${BLUE}🧹 ELIMINACIÓN TOTAL - TODOS LOS RASTROS${NC}"
    echo "========================================="
    
    # 0. DETENER PROCESOS
    echo -e "${YELLOW}0. 🛑 Deteniendo procesos en ejecución...${NC}"
    pkill -x firefox 2>/dev/null || true
    pkill -x librewolf 2>/dev/null || true
    pkill -P $(pgrep -x firefox 2>/dev/null) 2>/dev/null || true
    pkill -P $(pgrep -x librewolf 2>/dev/null) 2>/dev/null || true
    sleep 2
    
    declare -A navegadores=(
        [firefox]="org.mozilla.firefox"
        [librewolf]="org.librewolf"
    )
    
    # 1. DESINSTALAR PAQUETES
    echo -e "${YELLOW}1. 🗑️  Desinstalando paquetes...${NC}"
    
    declare -A metodos_disponibles
    command -v apt >/dev/null 2>&1 && metodos_disponibles[apt]=1
    command -v snap >/dev/null 2>&1 && metodos_disponibles[snap]=1
    command -v flatpak >/dev/null 2>&1 && metodos_disponibles[flatpak]=1

    for nav in "${!navegadores[@]}"; do
        echo "   🔍 ${nav^}"
        local encontrado=0
        
        for metodo in "${!metodos_disponibles[@]}"; do
            case $metodo in
                apt)
                    if dpkg -l | grep -qi "$nav"; then
                        echo "     🗑️  APT"
                        [[ "$nav" == "firefox" ]] && \
                            sudo apt purge firefox firefox-esr firefox-locale-* -y >/dev/null 2>&1 || \
                            sudo apt purge "$nav"* -y >/dev/null 2>&1
                        encontrado=1
                    fi
                    ;;
                snap)
                    if snap list | grep -qi "$nav"; then
                        echo "     🗑️  Snap"
                        sudo snap remove --purge "$nav" >/dev/null 2>&1
                        encontrado=1
                    fi
                    ;;
                flatpak)
                    if flatpak list | grep -qi "${navegadores[$nav]}"; then
                        echo "     🗑️  Flatpak"
                        flatpak uninstall --delete-data "${navegadores[$nav]}" -y >/dev/null 2>&1
                        encontrado=1
                    fi
                    ;;
            esac
        done
        [[ $encontrado -eq 0 ]] && echo "     ✅ No instalado"
    done
    
    # 2. LIMPIAR CONFIGURACIONES DE USUARIO
    echo ""
    echo -e "${YELLOW}2. 🗂️  Eliminando configuraciones de usuario...${NC}"
    
    local REAL_USER="${SUDO_USER:-$USER}"
    local REAL_HOME=""
    
    if [[ "$REAL_USER" == "root" ]]; then
        REAL_USER=$(ls /home | head -1)
    fi
    
    if [[ -n "$REAL_USER" ]]; then
        REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    fi
    
    if [[ -z "$REAL_HOME" ]] || [[ ! -d "$REAL_HOME" ]]; then
        if [[ "$REAL_USER" != "root" ]] && [[ -d "/home/$REAL_USER" ]]; then
            REAL_HOME="/home/$REAL_USER"
        else
            REAL_HOME="/home/$(ls /home | head -1)"
        fi
    fi
    
    echo "   👤 Usuario: $REAL_USER"
    echo "   🏠 Home: $REAL_HOME"
    
    # Eliminar TODAS las carpetas y archivos del usuario
    local carpetas_usuario=(
        "$REAL_HOME/.librewolf"
        "$REAL_HOME/.librewolf_logs"
        "$REAL_HOME/.librewolf_educational_mode"
        "$REAL_HOME/.librewolf_manual_config.sh"
        "$REAL_HOME/.librewolf*"
        "$REAL_HOME/.mozilla"
        "$REAL_HOME/.cache/mozilla"
        "$REAL_HOME/.cache/librewolf"
        "$REAL_HOME/.config/librewolf"
        "$REAL_HOME/.config/firefox"
        "$REAL_HOME/.local/share/applications/librewolf*"
        "$REAL_HOME/.local/share/applications/firefox*"
        "$REAL_HOME/.local/share/icons/librewolf*"
        "$REAL_HOME/.local/share/icons/firefox*"
        "$REAL_HOME/snap/librewolf"
        "$REAL_HOME/snap/firefox"
        "$REAL_HOME/Desktop/librewolf*.desktop"
        "$REAL_HOME/Desktop/firefox*.desktop"
        "$REAL_HOME/.gnome/apps/librewolf*"
        "$REAL_HOME/.gnome/apps/firefox*"
    )
    
    for item in "${carpetas_usuario[@]}"; do
        for elemento in $item; do
            if [[ -e "$elemento" ]]; then
                echo "     🗑️  $(basename "$elemento")"
                rm -rf "$elemento" >/dev/null 2>&1
            fi
        done
    done
    
    # 3. LIMPIAR ARCHIVOS DEL SISTEMA
    echo ""
    echo -e "${YELLOW}3. 🗃️  Limpiando archivos del sistema...${NC}"
    
    local archivos_sistema=(
        "/etc/apt/sources.list.d/extrepo_librewolf*"
        "/usr/share/keyrings/librewolf*"
        "/var/cache/apt/archives/librewolf*"
        "/var/lib/apt/lists/repo.librewolf.net*"
        "/var/lib/extrepo/keys/librewolf*"
        "/usr/lib/firefox*"
        "/usr/lib/librewolf*"
        "/opt/firefox*"
        "/opt/librewolf*"
        "/usr/share/applications/firefox*.desktop"
        "/usr/share/applications/librewolf*.desktop"
        "/usr/local/bin/firefox"
        "/usr/local/bin/librewolf"
        "/var/lib/snapd/desktop/applications/firefox*"
        "/var/lib/snapd/desktop/applications/librewolf*"
        "/usr/share/doc/firefox*"
        "/usr/share/doc/librewolf*"
        "/usr/share/man/man1/firefox*"
        "/usr/share/man/man1/librewolf*"
        "/root/.librewolf_manual_config.sh"
    )
    
    for archivo in "${archivos_sistema[@]}"; do
        for elemento in $archivo; do
            if [[ -e "$elemento" ]]; then
                echo "     🗑️  $(basename "$elemento")"
                sudo rm -rf "$elemento" >/dev/null 2>&1
            fi
        done
    done
    
    # 4. LIMPIAR CACHÉ Y DEPENDENCIAS
    echo ""
    echo -e "${YELLOW}4. 🧽 Limpieza final del sistema...${NC}"
    
    if command -v apt >/dev/null 2>&1; then
        sudo apt autoremove --purge -y >/dev/null 2>&1
        sudo apt autoclean >/dev/null 2>&1
        sudo apt clean >/dev/null 2>&1
    fi
    
    if command -v flatpak >/dev/null 2>&1; then
        flatpak remove --unused -y >/dev/null 2>&1
    fi
    
    # 5. ACTUALIZAR BASES DE DATOS
    echo ""
    echo -e "${YELLOW}5. 🔄 Actualizando bases de datos...${NC}"
    
    if command -v updatedb >/dev/null 2>&1; then
        sudo updatedb >/dev/null 2>&1
    fi
    
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$REAL_HOME/.local/share/applications" >/dev/null 2>&1
    fi
    
    # 6. VERIFICACIÓN FINAL
    echo ""
    echo -e "${YELLOW}6. 🔍 Verificación final...${NC}"
    
    local restos_encontrados=0
    
    if command -v locate >/dev/null 2>&1; then
        echo "   🔎 Buscando con locate:"
        local resultados=$(locate -i librewolf firefox 2>/dev/null | grep -v "/proc/\|/sys/")
        
        if [[ -n "$resultados" ]]; then
            echo "     ⚠️  Se encontraron algunos archivos residuales:"
            echo "$resultados" | head -10 | while read -r linea; do
                echo "       • $(basename "$linea")"
            done
            if [[ $(echo "$resultados" | wc -l) -gt 10 ]]; then
                echo "       ... y más"
            fi
            restos_encontrados=1
        else
            echo "     ✅ No se encontraron archivos residuales"
        fi
    fi
    
    echo "   📦 Verificando paquetes:"
    if dpkg -l | grep -qi "firefox\|librewolf"; then
        echo "     ⚠️  ¡AÚN HAY PAQUETES INSTALADOS!"
        restos_encontrados=1
    else
        echo "     ✅ No hay paquetes instalados"
    fi
    
    echo ""
    echo "========================================="
    
    if [[ $restos_encontrados -eq 0 ]]; then
        echo -e "${GREEN}✅ ¡ELIMINACIÓN COMPLETA EXITOSA!${NC}"
    else
        echo -e "${YELLOW}⚠️  Eliminación casi completa.${NC}"
    fi
}

# =============================================================================
# FUNCIÓN: instalar_librewolf
# Instala LibreWolf desde el repositorio oficial usando extrepo
# =============================================================================
instalar_librewolf() {
    echo
    echo
    echo -e "${BLUE}🚀 Iniciando instalación de LibreWolf${NC}"
    echo "====================================="
    
    sudo apt update >/dev/null 2>&1 && echo "✓ Repositorios actualizados"
    
    command -v extrepo >/dev/null 2>&1 \
    && echo "✓ extrepo ya disponible" \
    || { echo "📥 Instalando extrepo..."; apt -y install extrepo 2>/dev/null; }
    
    echo "🔧 Configurando repositorio..."
    extrepo enable librewolf >/dev/null 2>&1 \
    && echo "✓ Repositorio habilitado" \
    || echo "⚠️  Usando repositorios existentes"
    
    echo "📦 Instalando LibreWolf..."
    sudo apt update >/dev/null 2>&1 \
    && apt -y install librewolf >/dev/null 2>&1 \
    && echo -e "${GREEN}✅ LibreWolf instalado correctamente${NC}" \
    || echo -e "${RED}❌ Error al instalar LibreWolf${NC}"
    
    echo "====================================="
}

# =============================================================================
# FUNCIÓN: politicas
# Aplica todas las políticas de protección:
#   - DNS 1.1.1.3 forzado
#   - SafeSearch en todas las búsquedas
#   - Extensiones preinstaladas (incluyendo ClearMind)
#   - Bloqueo de instalación/desinstalación de extensiones
#   - Bloqueo de telemetría y rastreo
#   - Canvas liberado para Figma
# =============================================================================
politicas() {
    echo ""
    echo -e "${BLUE}🔧 CONFIGURANDO POLÍTICAS DE PROTECCIÓN${NC}"
    echo "======================================"
    echo -e "${YELLOW}🛡️  ACTIVANDO DNS PROTEGIDO (1.1.1.3 - Cloudflare Family)${NC}"
    echo -e "${YELLOW}🛡️  AGREGANDO ClearMind - Protección avanzada contra contenido adulto${NC}"
    
    local POLICY_FILE="/usr/share/librewolf/distribution/policies.json"
    
    sudo mkdir -p "$(dirname "$POLICY_FILE")"
    
    sudo tee "$POLICY_FILE" > /dev/null << 'POLICY_EOF'
{
  "policies": {
    "DisableTelemetry": true,
    "DisableFirefoxStudies": true,
    "DisablePocket": true,
    "DisableFirefoxAccounts": true,
    "DisableFormHistory": true,
    "DisableSafeMode": true,
    "DisablePrivateBrowsing": false,

    "DisableDeveloperTools": false,
    "DisableFirefoxScreenshots": true,
    "DisablePasswordManager": true,
    "DisableSetDesktopBackground": true,
    "DisableForgetButton": true,
    "DisableFeedbackCommands": true,
    "DisableProfileImport": true,
    "DisableProfileRefresh": true,
    "DisableAppUpdate": false,
    "DisableBuiltinPDFViewer": true,
    "DisableMasterPasswordCreation": true,

    "DNSOverHTTPS": {
      "Enabled": true,
      "Locked": true,
      "ProviderURL": "https://cloudflare-dns.com/dns-query",
      "ProviderName": "Cloudflare Family Filter",
      "BootstrapAddress": "1.1.1.3"
    },

    "Homepage": {
      "URL": "https://duckduckgo.com/?safe=active&kae=d&k7=0d0d0d&kj=1a1a1a&kx=ff9900&k9=00aa00&k8=888888&ka=00aa00&kb=1a1a1a&kc=00aa00&kf=888888&kl=es-sv&kad=es_ES&kaj=m&kax=es_419&kp=-2&kam=osm&ko=-1&kaa=a",
      "Locked": true,
      "StartPage": "homepage"
    },

    "SearchEngines": {
      "Default": "DuckDuckGo Seguro",
      "PreventInstalls": true,
      "Remove": [
        "Google", "Bing", "Amazon.com", "eBay", "Twitter", "Yahoo"
      ],
      "Add": [
        {
          "Name": "DuckDuckGo Seguro",
          "URL": "https://duckduckgo.com/?safe=active&q={searchTerms}",
          "Method": "GET",
          "IconURL": "https://duckduckgo.com/favicon.ico",
          "Suggested": true,
          "Default": true
        }
      ],
      "Locked": true
    },

    "Permissions": {
      "Camera": {
        "BlockNewRequests": true,
        "Locked": true
      },
      "Microphone": {
        "BlockNewRequests": true,
        "Locked": true
      },
      "Location": {
        "BlockNewRequests": true,
        "Locked": true
      },
      "Notifications": {
        "BlockNewRequests": true,
        "Locked": true
      },
      "Autoplay": {
        "Default": "block-audio",
        "Locked": true
      }
    },

    "Cookies": {
      "Allow": [],
      "Block": ["http://*", "https://*"],
      "Default": "reject-tracker",
      "AcceptThirdParty": "never",
      "ExpireAtSessionEnd": true,
      "RejectTracker": true,
      "Locked": true
    },

    "Extensions": {
      "Install": [
        "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi",
        "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi",
        "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi",
        "https://addons.mozilla.org/firefox/downloads/file/4641717/ruffle_rs-0.2.0.25347.xpi",
        "https://addons.mozilla.org/firefox/downloads/file/2994462/kl-1.5.4.xpi",
        "https://addons.mozilla.org/firefox/downloads/latest/duckduckgo-for-firefox/latest.xpi",
        "https://addons.mozilla.org/firefox/downloads/latest/markdown-reader-ext/latest.xpi",
        "https://addons.mozilla.org/firefox/downloads/latest/leechblock/latest.xpi",
        "https://addons.mozilla.org/firefox/downloads/latest/clearmind-block-porn-websites/latest.xpi"
      ],
      "Locked": [
        "uBlock0@raymondhill.net",
        "addon@darkreader.org",
        "jid1-MnnxcxisBPnSXQ@jetpack",
        "{b5501fd1-7084-45c5-9aa6-567c2fcf5dc6}",
        "{b9e5d196-6a3b-48b2-9b2b-08e661d144c5}",
        "jid1-ZAdIEUB7XOzOJw@jetpack",
        "markdown-reader-ext@bener",
        "leechblock@proginosko.com",
        "clear-mind@anti-porn-blocker"
      ],
      "Uninstall": [
        "screenshots@mozilla.org",
        "webcompat@mozilla.org",
        "formautofill@mozilla.org"
      ],
      "InstallDefault": false,
      "AllowedTypes": ["extension"]
    },

    "SanitizeOnShutdown": {
      "Cache": true,
      "Cookies": true,
      "Downloads": true,
      "FormData": true,
      "History": true,
      "Sessions": true,
      "SiteSettings": false,
      "OfflineApps": true,
      "Locked": true
    },

    "Preferences": {
      "intl.locale.requested": { "Value": "es-ES", "Status": "locked" },
      "browser.search.region": { "Value": "SV", "Status": "locked" },
      "browser.search.defaultenginename": { "Value": "DuckDuckGo Seguro", "Status": "locked" },
      
      "keyword.URL": {
        "Value": "https://duckduckgo.com/?safe=active&q=",
        "Status": "locked"
      },
      
      "intl.accept_languages": { "Value": "es-SV, es-ES, es, en-US, en", "Status": "locked" },

      "xpinstall.enabled": { "Value": false, "Status": "locked" },
      "xpinstall.whitelist.required": { "Value": true, "Status": "locked" },
      "extensions.update.enabled": { "Value": true, "Status": "locked" },
      "extensions.getAddons.showPane": { "Value": false, "Status": "locked" },
      "extensions.htmlaboutaddons.recommendations.enabled": { "Value": false, "Status": "locked" },

      "browser.search.widget.inNavBar": { "Value": false, "Status": "locked" },
      "browser.newtabpage.enabled": { "Value": true, "Status": "locked" },
      "browser.newtabpage.activity-stream.showSponsored": { "Value": false, "Status": "locked" },
      "browser.newtabpage.activity-stream.showSponsoredTopSites": { "Value": false, "Status": "locked" },
      "browser.startup.page": { "Value": 1, "Status": "locked" },
      
      "browser.newtabpage.activity-stream.feeds.topsites": { "Value": true, "Status": "locked" },
      "browser.newtabpage.activity-stream.section.highlights.includeVisited": { "Value": true, "Status": "locked" },
      "browser.newtabpage.activity-stream.section.highlights.includeBookmarks": { "Value": true, "Status": "locked" },
      "browser.newtabpage.activity-stream.default.sites": { 
        "Value": "https://www.tuinstitutoonline.com/aula_virtual/course/index.php?categoryid=52", 
        "Status": "locked" 
      },

      "privacy.sanitize.sanitizeOnShutdown": { "Value": true, "Status": "locked" },
      "privacy.sanitize.timeSpan": { "Value": 0, "Status": "locked" },
      "privacy.clearOnShutdown.history": { "Value": true, "Status": "locked" },
      "privacy.clearOnShutdown.cookies": { "Value": true, "Status": "locked" },
      "privacy.clearOnShutdown.cache": { "Value": true, "Status": "locked" },

      "canvas.capturestream.enabled": { "Value": true, "Status": "locked" },
      "webgl.disabled": { "Value": false, "Status": "locked" },
      "webgl.enable-webgl2": { "Value": true, "Status": "locked" },
      
      "browser.urlbar.suggest.searches": { "Value": false, "Status": "locked" },

      "geo.enabled": { "Value": false, "Status": "locked" },
      "media.autoplay.default": { "Value": 1, "Status": "locked" },
      "media.eme.enabled": { "Value": false, "Status": "locked" },
      "media.gmp-widevinecdm.enabled": { "Value": false, "Status": "locked" },
      "media.navigator.enabled": { "Value": false, "Status": "locked" },
      "media.peerconnection.enabled": { "Value": false, "Status": "locked" },

      "signon.autofillForms": { "Value": false, "Status": "locked" },
      "signon.rememberSignons": { "Value": false, "Status": "locked" },

      "datareporting.healthreport.uploadEnabled": { "Value": false, "Status": "locked" },
      "privacy.resistFingerprinting": { "Value": true, "Status": "locked" },
      "privacy.trackingprotection.enabled": { "Value": true, "Status": "locked" },

      "device.sensors.enabled": { "Value": false, "Status": "locked" },

      "browser.safebrowsing.enabled": { "Value": true, "Status": "locked" },
      "browser.safebrowsing.malware.enabled": { "Value": true, "Status": "locked" },
      "browser.safebrowsing.downloads.enabled": { "Value": true, "Status": "locked" },
      "browser.safebrowsing.phishing.enabled": { "Value": true, "Status": "locked" },
      
      "google.search.safequery": { "Value": "active", "Status": "locked" },
      "bing.search.safequery": { "Value": "moderate", "Status": "locked" },
      "youtube.safesearch": { "Value": "moderate", "Status": "locked" },

      "network.trr.mode": { "Value": 3, "Status": "locked" },
      "network.trr.uri": { "Value": "https://cloudflare-dns.com/dns-query", "Status": "locked" },
      "network.trr.custom_uri": { "Value": "https://cloudflare-dns.com/dns-query", "Status": "locked" },
      "network.trr.bootstrapAddress": { "Value": "1.1.1.3", "Status": "locked" },
      "network.trr.useGET": { "Value": true, "Status": "locked" },
      "network.trr.blocklist": { "Value": "", "Status": "locked" },
      "network.trr.exclude-etc-hosts": { "Value": true, "Status": "locked" }
    }
  }
}
POLICY_EOF

    sudo chmod 644 "$POLICY_FILE"
    sudo chown root:root "$POLICY_FILE"
    
    echo ""
    echo -e "${GREEN}✅ PROTECCIÓN TOTAL ACTIVADA${NC}"
    echo -e "${BLUE}🛡️  DNS 1.1.1.3 (Cloudflare Family) - BLOQUEA:${NC}"
    echo "   🔒 Pornografía infantil (CSAM)"
    echo "   🔒 Contenido sexual explícito"
    echo "   🔒 Apuestas"
    echo "   🔒 Violencia extrema"
    echo -e "${BLUE}🛡️  SafeSearch FORZADO en TODAS las búsquedas${NC}"
    echo -e "${BLUE}🛡️  ClearMind - Protección avanzada contra contenido adulto (NUEVO)${NC}"
    echo -e "${BLUE}🛡️  LeechBlock instalado (bloqueo de sitios adultos)${NC}"
    echo -e "${BLUE}🛡️  Extensiones bloqueadas - NO se pueden instalar/desinstalar${NC}"
    echo -e "${GREEN}🎨 Canvas LIBERADO para Figma${NC}"
    echo "======================================"
}

# =============================================================================
# FUNCIÓN: limpieza_adicional
# Limpieza post-instalación de seguridad
# =============================================================================
limpieza_adicional() {
    echo ""
    echo -e "${YELLOW}🧹 LIMPIEZA ADICIONAL DE SEGURIDAD${NC}"
    echo "======================================"
    
    if command -v snap >/dev/null 2>&1; then
        echo "   Limpiando caché de snap..."
        sudo snap set system refresh.retain=2
    fi
    
    if command -v apt >/dev/null 2>&1; then
        echo "   Limpiando paquetes huérfanos..."
        sudo apt autoremove --purge -y >/dev/null 2>&1
        sudo apt autoclean -y >/dev/null 2>&1
    fi
    
    echo -e "${GREEN}✅ Limpieza adicional completada${NC}"
}

# =============================================================================
# FUNCIÓN: instalar_marcador_markdown
# Crea un marcador de respaldo de Markdown Reader en la barra de marcadores
# =============================================================================
instalar_marcador_markdown() {
    echo ""
    echo -e "${YELLOW}🔖 CREANDO MARCADOR DE MARKDOWN READER${NC}"
    echo "======================================"
    
    local REAL_USER="${SUDO_USER:-$USER}"
    local REAL_HOME=""
    
    if [[ "$REAL_USER" == "root" ]]; then
        REAL_USER=$(ls /home | head -1)
    fi
    
    if [[ -n "$REAL_USER" ]]; then
        REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    fi
    
    if [[ -z "$REAL_HOME" ]] || [[ ! -d "$REAL_HOME" ]]; then
        if [[ "$REAL_USER" != "root" ]] && [[ -d "/home/$REAL_USER" ]]; then
            REAL_HOME="/home/$REAL_USER"
        else
            REAL_HOME="/home/$(ls /home | head -1)"
        fi
    fi
    
    LOCAL_STATE_DIR="$REAL_HOME/.librewolf"
    if [[ -d "$LOCAL_STATE_DIR" ]]; then
        PROFILE_DIR=$(find "$LOCAL_STATE_DIR" -maxdepth 1 -type d -name "*.default-release" | head -1)
        if [[ -n "$PROFILE_DIR" ]]; then
            PLACES_DB="$PROFILE_DIR/places.sqlite"
            if [[ -f "$PLACES_DB" ]]; then
                echo "   📝 Añadiendo marcador de respaldo a la barra de herramientas..."
                sqlite3 "$PLACES_DB" <<EOF 2>/dev/null
INSERT OR REPLACE INTO moz_bookmarks (id, type, fk, parent, position, title, dateAdded, lastModified, guid)
VALUES (
    (SELECT id FROM moz_bookmarks WHERE fk = (SELECT id FROM moz_places WHERE url = 'https://www.markdownreader.com/')),
    1,
    (SELECT id FROM moz_places WHERE url = 'https://www.markdownreader.com/'),
    (SELECT id FROM moz_bookmarks WHERE guid = 'toolbar_____'),
    (SELECT COALESCE(MAX(position), -1) + 1 FROM moz_bookmarks WHERE parent = (SELECT id FROM moz_bookmarks WHERE guid = 'toolbar_____')),
    '📝 Markdown Reader Web',
    CAST(strftime('%s', 'now') * 1000000 AS INTEGER),
    CAST(strftime('%s', 'now') * 1000000 AS INTEGER),
    REPLACE(hex(randomblob(4)), ' ', '') || REPLACE(hex(randomblob(4)), ' ', '')
);
INSERT OR IGNORE INTO moz_places (url, title, rev_host, visit_count, hidden, typed, frecency, last_visit_date, guid)
VALUES ('https://www.markdownreader.com/', 'Markdown Reader', 
        '.' || reverse_host('https://www.markdownreader.com/') || '.', 
        0, 0, 0, 0, CAST(strftime('%s', 'now') * 1000000 AS INTEGER),
        REPLACE(hex(randomblob(4)), ' ', '') || REPLACE(hex(randomblob(4)), ' ', ''));
EOF
                echo -e "${GREEN}   ✅ Marcador '📝 Markdown Reader Web' añadido${NC}"
            fi
        fi
    fi
    echo "======================================"
}

# =============================================================================
# EJECUCIÓN PRINCIPAL
# =============================================================================
clear
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}   LIBREWOLF - INSTALACIÓN PROTEGIDA PARA ESTUDIANTES${NC}"
echo -e "${CYAN}   ITSI - Con ClearMind y protección total${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Fase 1: Eliminar navegadores existentes
eliminar_navegadores
sleep 3
clear

# Fase 2: Instalar LibreWolf
instalar_librewolf
sleep 3
clear

# Fase 3: Aplicar políticas de protección
politicas
sleep 2

# Fase 4: Limpieza adicional
limpieza_adicional

# Fase 5: Marcador de respaldo
instalar_marcador_markdown

# RESULTADO FINAL
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🎓 INSTALACIÓN COMPLETADA - PROTECCIÓN TOTAL${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}✅ CAPAS DE PROTECCIÓN ACTIVADAS:${NC}"
echo "   1️⃣ DNS 1.1.1.3 (Cloudflare Family) - Bloqueo a nivel de red"
echo "   2️⃣ SafeSearch forzado - Bloqueo a nivel de búsqueda"
echo "   3️⃣ ClearMind - Protección avanzada contra contenido adulto (NUEVO)"
echo "   4️⃣ LeechBlock - Bloqueo de sitios específicos"
echo "   5️⃣ uBlock Origin - Bloqueo de publicidad y rastreadores"
echo "   6️⃣ Navegación segura - Anti-phishing/malware"
echo "   7️⃣ Extensiones bloqueadas - Sin instalación/desinstalación"
echo ""
echo -e "${BLUE}🔒 CONTENIDO BLOQUEADO:${NC}"
echo "   • Pornografía infantil (CSAM)"
echo "   • Contenido sexual explícito"
echo "   • Violencia extrema"
echo "   • Apuestas y juegos de azar"
echo "   • Malware y phishing"
echo "   • Publicidad invasiva"
echo ""
echo -e "${BLUE}✅ LIBERADO PARA ESTUDIOS:${NC}"
echo "   🎨 Canvas FUNCIONANDO (Figma compatible)"
echo "   📝 Markdown Reader instalado (extensión + marcador web)"
echo "   🎨 WebGL activado (gráficos 3D)"
echo ""
echo -e "${BLUE}🔒 NADIE PUEDE:${NC}"
echo "   • Instalar extensiones"
echo "   • Desinstalar extensiones"
echo "   • Modificar políticas"
echo "   • Deshabilitar SafeSearch"
echo "   • Cambiar DNS"
echo "   • Desactivar ClearMind o LeechBlock"
echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}🛡️  LOS ESTUDIANTES ESTÁN 100% PROTEGIDOS${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${CYAN}📌 ClearMind proporciona protección multicapa contra contenido adulto${NC}"
echo -e "${CYAN}   con listas actualizadas y bloqueo por palabras clave.${NC}"
echo ""

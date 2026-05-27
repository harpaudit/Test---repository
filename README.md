# MOSES CRM — Solar Pipeline Management

MVP de gestión de deals/contratos solares con seguimiento de comisiones, estados y KPIs financieros.

---

## Requisitos

- Python 3.9 o superior
- pip

---

## Instalación

### 1. Crear entorno virtual

```bash
cd MOSES-CRM
python3 -m venv venv
source venv/bin/activate        # macOS / Linux
# venv\Scripts\activate         # Windows
```

### 2. Instalar dependencias

```bash
pip install -r requirements.txt
```

### 3. Ejecutar la aplicación

```bash
python app.py
```

La base de datos SQLite (`moses_crm.db`) se crea automáticamente en el primer arranque junto con:
- El usuario administrador por defecto
- Los 4 status predeterminados del pipeline

### 4. Abrir en el navegador

```
http://localhost:5001
```

> **macOS:** El puerto 5000 está reservado por el servicio AirPlay Receiver del sistema, por eso la app usa el 5001.
> Para desactivar AirPlay y usar el 5000: Preferencias del Sistema → General → AirDrop y Handoff → desactivar "AirPlay Receiver".

---

## Credenciales por defecto

| Campo     | Valor               |
|-----------|---------------------|
| Correo    | Admin@harpaudit.com |
| Contraseña| Orion123#           |
| Rol       | Administrador       |

---

## Estructura del proyecto

```
MOSES-CRM/
├── app.py                    # Aplicación Flask + todas las rutas
├── models.py                 # Modelos ORM (SQLAlchemy)
├── requirements.txt
├── README.md
├── moses_crm.db              # Base de datos (generada al correr)
└── templates/
    ├── base.html             # Layout base con sidebar
    ├── login.html            # Página de autenticación
    ├── dashboard.html        # KPIs + tabla principal de deals
    ├── deal_form.html        # Crear / Editar deal (con toggle Redline)
    ├── deal_detail.html      # Detalle del deal + historial de status
    ├── installers.html       # Lista de instaladores
    ├── installer_form.html   # Crear / Editar instalador
    └── admin_statuses.html   # Gestión de status del pipeline
```

---

## Funcionalidades principales

### Roles
- **Admin** (`Admin@harpaudit.com`): CRUD completo de instaladores, gestión de status, edición y eliminación de deals.
- **Usuario normal**: Puede crear y ver deals, cambiar status.

### Cálculo Redline (cuando está habilitado)
```
Total Commission = Contract Amount - (System Size × Company Redline) - Adders
Total PPW        = Contract Amount / System Size
Net PPW          = (Contract Amount - Adders) / System Size
```

### Cálculo sin Redline
Solo se ingresa el **Monto Total Adeudado**. Útil cuando el instalador no provee información granular.

### Status & Historial
Cada cambio de status queda registrado con timestamp, usuario responsable y nota opcional. La vista de detalle muestra cuánto tiempo estuvo el deal en cada status.

### Exportación Excel
El botón **Exportar Excel** en el dashboard descarga un archivo `.xlsx` respetando los filtros activos (instalador / status).

---

## Variables de entorno (opcionales)

| Variable   | Descripción                        | Default                      |
|------------|------------------------------------|------------------------------|
| SECRET_KEY | Clave secreta para sesiones Flask  | `moses-crm-secret-x9k-2024`  |

Para producción se recomienda establecer `SECRET_KEY` como variable de entorno:

```bash
export SECRET_KEY="tu-clave-segura-aqui"
python app.py
```

---

## Instaladores predeterminados sugeridos

Agrégalos desde el panel de **Instaladores** → Nuevo Instalador:

`Solarmite`, `Gamma`, `Rumiante`, `Ecovole`, `OWE`, `Suntria`, `EY`, `Solarships`, `Spartan`, `Logic`

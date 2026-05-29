# MOSES CRM — Solar Pipeline Management

Sistema de gestión de deals/contratos solares con seguimiento de comisiones, estados, KPIs financieros y pipeline completo.

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
- Los stages predeterminados del pipeline

### 4. Abrir en el navegador

```
http://localhost:5001
```

> **macOS:** El puerto 5000 está reservado por el servicio AirPlay Receiver del sistema, por eso la app usa el 5001.
> Para desactivarlo: Preferencias del Sistema → General → AirDrop y Handoff → desactivar "AirPlay Receiver".

---

## Credenciales por defecto

| Campo      | Valor               |
|------------|---------------------|
| Correo     | Admin@harpaudit.com |
| Contraseña | Orion123#           |
| Rol        | Administrador       |

---

## Estructura del proyecto

```
MOSES-CRM/
├── app.py                    # Aplicación Flask + todas las rutas
├── models.py                 # Modelos ORM (SQLAlchemy)
├── requirements.txt
├── README.md
├── moses_crm.db              # Base de datos SQLite (generada al correr)
└── templates/
    ├── base.html             # Layout base: nav, modal global, estilos
    ├── login.html            # Página de autenticación
    ├── dashboard.html        # KPIs, tabla de deals, leaderboard de dealers
    ├── deal_form.html        # Crear / Editar deal (página completa)
    ├── deal_detail.html      # Detalle del deal + pagos + historial de status
    ├── dealers.html          # Lista de dealers
    ├── dealer_form.html      # Crear / Editar dealer
    ├── dealer_detail.html    # Detalle del dealer + deals asociados
    └── admin_statuses.html   # Gestión de stages del pipeline
```

---

## Funcionalidades

### Dashboard (Overview)

La pantalla principal muestra toda la información del pipeline en un solo vistazo:

#### KPIs (parte superior)
Cuatro tarjetas con los indicadores clave:
- **Total Deals** — número total de contratos registrados
- **Pipeline** — balance pendiente acumulado de todos los deals activos
- **Total Collected** — suma de pagos recibidos
- **Pending** — deals que aún no han sido completados

#### Layout de dos columnas
- **Columna izquierda:** Top dealers (ranking por pipeline) + Pipeline by status (conteo de deals por cada stage con botón de filtro directo)
- **Columna derecha:** Tabla completa de todos los deals

#### Tabla de deals
- Columnas: #, Deal, Dealer, Status, Original, Paid, Remaining, Created
- **Ordenamiento** por columnas Original, Remaining y Created — clic en el encabezado alterna entre ascendente ↑ y descendente ↓
- **Filtros** por dealer y por status; selector de paginación (10 / 20 / 50 por página)
- **Botón Clear** aparece cuando hay cualquier filtro u ordenamiento activo
- **Paginación AJAX** — cambiar de página no recarga ni desplaza la pantalla
- **Menú kebab (⋮)** por fila con opciones: Ver, Editar, Eliminar

---

### Deals

#### Crear deal (modal)
El botón **+ New deal** en la barra de navegación abre un modal sobre el dashboard sin perder el contexto. El formulario incluye:
- Nombre del deal y dealer (obligatorios)
- Stage inicial
- Modo de cálculo: **Redline** o **Fixed amount**
- Notas opcionales

Al guardar, la tabla se actualiza automáticamente sin recargar la página.

#### Editar deal (modal)
El botón **Edit deal** en la vista de detalle, y la opción **Edit** del menú kebab en la tabla, abren el mismo formulario de edición en un modal pre-cargado con los datos actuales del deal.

#### Vista de detalle
Accesible desde cualquier fila de la tabla. Muestra:
- Resumen de pagos: monto cobrado, pendiente, porcentaje de avance
- Información financiera (modo Redline o Fixed amount)
- Panel de registro de pagos con nota opcional
- Panel de cambio de status con nota
- Historial completo de cambios de status con timestamps y duración en cada etapa

#### Eliminación
Disponible desde el menú kebab. Solicita confirmación antes de proceder.

#### Exportación Excel
El botón **Export Excel** / **Export current view** descarga un archivo `.xlsx` con los deals visibles según los filtros activos. Incluye todas las columnas financieras.

---

### Cálculo financiero

#### Modo Redline
Se activa cuando el dealer provee información granular del contrato:

```
Total Commission = Contract Amount − (System Size × Company Redline) − Adders
Total PPW        = Contract Amount / System Size
Net PPW          = (Contract Amount − Adders) / System Size
```

Los valores se calculan en tiempo real mientras se escribe (live preview).

#### Modo Fixed Amount
Para cuando el dealer no provee datos granulares. Se ingresa únicamente el **Monto Total Adeudado**, que se convierte en el valor original del deal. Los pagos se registran contra ese monto.

---

### Dealers

- Lista de todos los dealers con número de deals y estado (activo/inactivo)
- Vista de detalle por dealer con todos sus deals asociados y métricas
- CRUD completo (crear, editar, desactivar) — solo administradores

---

### Stages del pipeline (Status Management)

Accesible desde el menú **Statuses** (solo administradores). Permite gestionar completamente los stages del pipeline:

- **Crear** un nuevo stage con nombre, orden y color de badge
  - Al asignar una posición, los stages existentes se reordenan automáticamente
- **Editar** nombre, orden y color de cualquier stage
  - Cambiar el orden reordena los demás stages automáticamente
- **Eliminar** cualquier stage que no tenga deals asociados
  - Los stages con deals muestran un candado; no se pueden eliminar hasta reasignar sus deals
- **Reordenar** arrastrando las filas con el handle (⣿) — drag & drop en tiempo real con SortableJS

Los colores disponibles son: Blue, Red, Yellow, Green, Gray, Purple, Orange.

---

### Roles y permisos

| Acción                              | Admin | Usuario normal |
|-------------------------------------|:-----:|:--------------:|
| Ver deals y detalle                 | ✓     | ✓              |
| Crear deal                          | ✓     | ✓              |
| Editar deal                         | ✓     | —              |
| Eliminar deal                       | ✓     | —              |
| Registrar pagos                     | ✓     | ✓              |
| Cambiar status de deal              | ✓     | ✓              |
| CRUD de dealers                     | ✓     | —              |
| Gestión de stages del pipeline      | ✓     | —              |

---

### Navegación

- **Barra superior:** Logo, tabs (Overview, Dealers, Statuses, Reports), botón + New deal, avatar de usuario
- **Avatar (esquina superior derecha):** Muestra un dropdown con el email del usuario y la opción **Log out**
- **Reports:** Próximamente (deshabilitado)

---

## Variables de entorno (opcionales)

| Variable   | Descripción                       | Default                     |
|------------|-----------------------------------|-----------------------------|
| SECRET_KEY | Clave secreta para sesiones Flask | `moses-crm-secret-x9k-2024` |

Para producción se recomienda establecer `SECRET_KEY` como variable de entorno:

```bash
export SECRET_KEY="tu-clave-segura-aqui"
python app.py
```

---

## Dealers predeterminados sugeridos

Agrégalos desde el panel de **Dealers** → Nuevo Dealer:

`Solarmite`, `Gamma`, `Rumiante`, `Ecovole`, `OWE`, `Suntria`, `EY`, `Solarships`, `Spartan`, `Logic`

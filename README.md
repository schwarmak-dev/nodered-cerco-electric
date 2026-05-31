# ElectricFence Node-RED — Cerco Eléctrico Inteligente

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**ElectricFence Node-RED** es un sistema de monitoreo y control para cercos eléctricos basado en **Node-RED**, **MQTT** y **MySQL**. Diseñado para correr en **Docker** o en una **Raspberry Pi** con pines GPIO.

> Creado por [schwarmak-dev](https://github.com/schwarmak-dev) — si usas este proyecto, menciona la fuente original. Open source bajo licencia MIT.

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Docker Compose                              │
│                                                                     │
│  ┌──────────┐    MQTT     ┌──────────┐    SQL     ┌──────────┐     │
│  │ Emisor   │◄──────────► │ Mosquitto│◄──────────► │  MySQL   │     │
│  │ (simulador│  1883      │  Broker  │   3306     │  8.x     │     │
│  │ o GPIO)  │            └────┬──────┘            └──────────┘     │
│  └──────────┘                 │                                     │
│                               │ MQTT                                │
│                        ┌──────▼──────┐                             │
│                        │  Node-RED   │   Dashboard                  │
│                        │  4.0.2      │◄──── :1880/ui ───────────► │
│                        │             │                              │
│                        │ - Persistencia BD                          │
│                        │ - Receptor / Resolver                      │
│                        │ - Dashboard profesional                    │
│                        └─────────────┘                             │
└─────────────────────────────────────────────────────────────────────┘
```

## Componentes

| Componente     | Tecnología         | Puerto |
|----------------|--------------------|--------|
| Node-RED       | nodered/node-red   | `1880` |
| Mosquitto MQTT | eclipse-mosquitto  | `1883` |
| MySQL          | mysql:8            | `3306` |
| Dashboard UI   | node-red-dashboard | `1880/ui` |

## Flujos incluidos

### 1. Persistencia BD (`brokerabierto.json`)
Escucha todos los mensajes `ElectricFence/#` y los guarda automáticamente en la tabla `registro` de MySQL.

### 2. Emisor (`emisorabierto.json`)
Simulador por botones para activar/desactivar alarmas, estados y controles de cada zona del cerco. Incluye mapeo completo de rutas (R1, R2, R3, Switch) publicado como JSON enriquecido.

### 3. Receptor (`receptorabierto.json`)
Resuelve los mensajes MQTT por dispositivo destino (Broker, Switch, R1-R4) y actualiza un dashboard profesional con:

- Indicador de sistema armado/desarmado
- Luces por zona: Estado (verde), Alarma (rojo), Control (azul)
- Contadores y último evento
- Botones Armar / Desalarmar

## Requisitos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows/Mac) o Docker Engine (Linux)
- Git (opcional, para clonar)

## Inicio rápido

```bash
# Clonar
git clone https://github.com/schwarmak-dev/nodered-cerco-electric.git
cd nodered-cerco-electric

# Configurar credenciales (opcional)
# Editar .env si se desea cambiar user/pass de MySQL

# Levantar todo
docker compose up -d --build
```

### Configuración inicial (solo la primera vez)

1. Abrir `http://localhost:1880`
2. Ir al tab **Persistencia BD**
3. Hacer doble clic en el nodo `monitor_cercos` (MySQLdatabase)
4. Ingresar:
   - **User:** `monitor`
   - **Password:** `monitorpass123`
5. Click **Update** → **Deploy**

### Probar el simulador

1. Ir al tab **ElectricFence Emisor**
2. Hacer clic en cualquier botón azul (ej: *Alarma Zona1 Sup ON*)
3. Ver el dashboard en `http://localhost:1880/ui`
4. Consultar los datos guardados:

```bash
docker compose exec mysql mysql -u monitor -pmonitorpass123 monitor_cercos -e "SELECT * FROM registro"
```

## Estructura del proyecto

```
nodered-cerco-electric/
├── docker-compose.yml       # Orquestación de servicios
├── Dockerfile               # Imagen Node-RED personalizada
├── .env                     # Variables de entorno (MySQL)
├── docker/
│   └── entrypoint.sh        # Script de entrada (combina flujos)
├── flows/
│   ├── brokerabierto.json   # Persistencia en MySQL
│   ├── emisorabierto.json   # Simulador de señales
│   └── receptorabierto.json # Dashboard y resolución
├── mosquitto/
│   └── config/
│       └── mosquitto.conf   # Configuración MQTT
└── mysql/
    └── init/
        └── 01-schema.sql    # Tabla registro
```

## Dashboard

El dashboard (Node-RED UI) en `http://localhost:1880/ui` ofrece:

- **Estado del sistema**: Armado/Desarmado con indicador visual
- **Alarmas activas**: Contador y luces rojas por zona
- **Estado de cercos**: Luces verdes para estado encendido
- **Controles**: Luces azules para controles activos
- **Último evento**: Detalle del último mensaje recibido
- **Botones**: Armar alarma / Desalarmar

## GPIO en Raspberry Pi

Si se ejecuta en una **Raspberry Pi**, se puede habilitar el tab **ElectricFence Emisor GPIO**:

1. En `flows/emisorabierto.json`, cambiar `"disabled": true` a `"disabled": false` en el tab `224ec496b36f6d5e`
2. Agregar al `docker-compose.yml` en el servicio `node-red`:

```yaml
    privileged: true
    devices:
      - /dev/gpiomem:/dev/gpiomem
```

> En Windows o sin GPIO, usar el simulador por botones (tab ElectricFence Emisor).

## Personalización

- **Credenciales MySQL**: editar `.env`
- **Puertos**: modificar `docker-compose.yml` si hay conflictos (ej: MySQL local en `3306`)
- **Flujos**: los archivos `.json` en `flows/` se combinan automáticamente al arrancar el contenedor

## Licencia

MIT — ver archivo [LICENSE](LICENSE).

---

**Schwarmak Dev** — [GitHub](https://github.com/schwarmak-dev)

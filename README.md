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

### 1. BROKER (`brokernuevo.json`)
Raspberry BROKER (emisor .104): recibe señales físicas de cercos via GPIO, publica MQTT y muestra dashboard.
- **Tab BROKER**: Suscribe a `inchalam/cercos/alarma/#` e `inchalam/cercos/estado/#`, activa GPIOs de salida (módulo relé 1 y 2).
- **Tab ALARMAS**: Dashboard UI con LEDs de alarma y estado por zona.
- **Tab CONTROL CERCOS**: Publica comandos ON/OFF hacia G1.

### 2. G1 (`g1.json`)
Raspberry G1 (receptor .106): control ON/OFF de cercos via relé GPIO.
- **Canal C1**: GPIO24 (Relé 1) — arma/desarma TODOS los cercos. Escucha `inchalam/cercos/onoff/#`.
- **Canal C2**: GPIO25 (Relé 2) — arma/desarma solo Alambron. Escucha `inchalam/cercos/onoff/alambron/#`.
- **Canal C3**: GPIO24 — activa al recibir CUALQUIER alarma de cerco (`inchalam/cercos/alarma/#`).
- **Estados PGM**: Lee 7 GPIO de entrada (GPIO23,22,12,20,19,4,21) y publica estados de cercos por MQTT.

### 3. REPEATER (`repeater_fixed.json`)
Raspberry REPEATER (brokerm .105): repetidor de alarmas.
- Lee 7 GPIO de entrada (hebras de cerco) y publica a `inchalam/cercos/alarma/...`.
- Mapeo: IN1=GPIO17 (Puelche sup), IN2=GPIO18 (Puelche inf), IN3=GPIO10 (Estac. sup), IN4=GPIO9 (Estac. inf), IN5=GPIO11 (Desp. sup), IN6=GPIO22 (Desp. inf), IN7=GPIO27 (Alambron).

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
│   ├── brokernuevo.json     # BROKER — alarmas, estados GPIO, dashboard
│   ├── g1.json              # G1 — control ON/OFF cercos via relé
│   └── repeater_fixed.json  # REPEATER — repetidor de alarmas GPIO
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

El sistema está diseñado para ejecutarse en **3 Raspberry Pi** conectadas vía MQTT:

| Dispositivo | IP | Función |
|-------------|-----|---------|
| BROKER (.104) | 192.168.1.104 | Recibe señales físicas, publica MQTT, dashboard |
| REPEATER (.105) | 192.168.1.105 | Repetidor de alarmas MQTT |
| G1 (.106) | 192.168.1.106 | Control ON/OFF de cercos via relé |

### Mapeo de GPIO

**REPEATER (entrada — alarmas):**

| Entrada | GPIO | Zona |
|---------|------|------|
| IN1 | GPIO17 | Puelche superior |
| IN2 | GPIO18 | Puelche inferior |
| IN3 | GPIO10 | Estacionamiento superior |
| IN4 | GPIO9 | Estacionamiento inferior |
| IN5 | GPIO11 | Despacho superior |
| IN6 | GPIO22 | Despacho inferior |
| IN7 | GPIO27 | Alambron |

**BROKER (salida — alarmas y estados):**

| Salida | GPIO | Función |
|--------|------|---------|
| Relé 1 IN1 | GPIO17 | Alarma Puelche superior |
| Relé 1 IN2 | GPIO18 | Alarma Puelche inferior |
| Relé 1 IN3 | GPIO10 | Alarma Estacionamiento superior |
| Relé 1 IN4 | GPIO9 | Alarma Estacionamiento inferior |
| Relé 1 IN5 | GPIO11 | Alarma Despacho superior |
| Relé 1 IN6 | GPIO8 | Alarma Despacho inferior |
| Relé 1 IN7 | GPIO7 | Alarma Alambron |
| Relé 2 IN1 | GPIO23 | Estado Puelche superior |
| Relé 2 IN2 | GPIO22 | Estado Puelche inferior |
| Relé 2 IN3 | GPIO12 | Estado Estacionamiento superior |
| Relé 2 IN4 | GPIO20 | Estado Estacionamiento inferior |
| Relé 2 IN5 | GPIO19 | Estado Despacho superior |
| Relé 2 IN6 | GPIO4 | Estado Despacho inferior |
| Relé 2 IN7 | GPIO21 | Estado Alambron |

**G1 (salida — control de cercos):**

| Salida | GPIO | Función |
|--------|------|---------|
| Relé 1 | GPIO24 | Arma/desarma TODOS los cercos |
| Relé 2 | GPIO25 | Arma/desarma solo Alambron |

**G1 (entrada — estados PGM):**

| Entrada | GPIO | Zona |
|---------|------|------|
| IN_STATE | GPIO23 | Puelche superior |
| IN_STATE | GPIO22 | Puelche inferior |
| IN_STATE | GPIO12 | Estacionamiento superior |
| IN_STATE | GPIO20 | Estacionamiento inferior |
| IN_STATE | GPIO19 | Despacho superior |
| IN_STATE | GPIO4 | Despacho inferior |
| IN_STATE | GPIO21 | Alambron |

## Personalización

- **Credenciales MySQL**: editar `.env`
- **Puertos**: modificar `docker-compose.yml` si hay conflictos (ej: MySQL local en `3306`)
- **Flujos**: los archivos `.json` en `flows/` se combinan automáticamente al arrancar el contenedor

## Licencia

MIT — ver archivo [LICENSE](LICENSE).

---

**Schwarmak Dev** — [GitHub](https://github.com/schwarmak-dev)

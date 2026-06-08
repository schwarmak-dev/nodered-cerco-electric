# ⚡ ElectricFence Node-RED — Sistema Inteligente de Cerco Eléctrico

<div align="center">

![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
![Node-RED](https://img.shields.io/badge/Node--RED-4.0.2-green.svg)
![MQTT](https://img.shields.io/badge/MQTT-Mosquitto-orange.svg)
![MySQL](https://img.shields.io/badge/MySQL-8.x-blue.svg)
![Docker](https://img.shields.io/badge/Docker-Compose-purple.svg)
![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi-3%20unidades-red.svg)

</div>

<p align="center">
  <strong>Sistema de monitoreo y control para cercos eléctricos con Node-RED, MQTT y MySQL</strong><br>
  Diseñado para correr en Docker o en Raspberry Pi con pines GPIO
</p>

---

## 🎯 ¿Qué es ElectricFence?

**ElectricFence Node-RED** es una solución completa y escalable para el monitoreo y control de cercos eléctricos. Utiliza **3 Raspberry Pi** interconectadas vía MQTT para crear una red inteligente que:

- ✅ Detecta intrusiones en **7 zonas** de cercos
- ✅ Publica alarmas y estados en tiempo real
- ✅ Controla relés para armado/desarmado remoto
- ✅ Muestra un dashboard profesional con LEDs de estado
- ✅ Registra eventos en MySQL para auditoría

> **Creado por [schwarmak-dev](https://github.com/schwarmak-dev)** — Open source bajo licencia MIT.

---

## 🏗️ Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           SISTEMA ELECTRICFENCE                                  │
│                                                                                 │
│  ┌──────────────────┐        ┌──────────────────┐        ┌──────────────────┐   │
│  │   REPEATER       │        │     BROKER       │        │       G1         │   │
│  │  (.105)          │  MQTT  │     (.104)       │  MQTT  │     (.106)       │   │
│  │                  │◄──────►│                  │◄──────►│                  │   │
│  │ • 7 GPIO entrada │  1883  │ • Dashboard LED  │  1883  │ • Control relé   │   │
│  │ • Detecta hebras │        │ • Alarma/Estado  │        │ • Armado/Desarm  │   │
│  │ • Publica alarmas│        │ • Control ON/OFF │        │ • 2 relés GPIO   │   │
│  └────────┬─────────┘        └────────┬─────────┘        └──────────────────┘   │
│           │                           │                                         │
│           │         ┌─────────────────┼─────────────────┐                       │
│           │         │                 │                 │                       │
│           ▼         ▼                 ▼                 ▼                       │
│  ┌─────────────────────────────────────────────────────────────────────────┐   │
│  │                         Docker Compose                                  │   │
│  │                                                                         │   │
│  │  ┌──────────┐    MQTT     ┌──────────┐    SQL     ┌──────────┐         │   │
│  │  │ Mosquitto│◄──────────► │  MySQL   │            │ Node-RED │         │   │
│  │  │ Broker   │   1883      │  8.x     │   3306     │  4.0.2   │         │   │
│  │  └──────────┘             └──────────┘            └────┬─────┘         │   │
│  │                                                        │               │   │
│  │                                                ┌───────▼───────┐       │   │
│  │                                                │  Dashboard UI │       │   │
│  │                                                │  :1880/ui     │       │   │
│  │                                                └───────────────┘       │   │
│  └─────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Componentes del Sistema

| Componente | Tecnología | Puerto | Función |
|------------|------------|--------|---------|
| **Node-RED** | nodered/node-red 4.0.2 | `1880` | Motor de flujos y dashboard |
| **Mosquitto MQTT** | eclipse-mosquitto 2 | `1883` | Broker de mensajería |
| **MySQL** | mysql:8 | `3306` | Almacenamiento de registros |
| **Dashboard UI** | node-red-dashboard | `1880/ui` | Interfaz gráfica de monitoreo |

---

## 📦 Flujos Incluidos

### 1. 🔵 BROKER (`brokernuevo.json`)

**Raspberry BROKER (IP: .104)** — El cerebro del sistema de monitoreo.

| Tab | Función |
|-----|---------|
| **BROKER** | Suscribe a alarmas y estados, activa GPIOs de salida (módulo relé 1 y 2) |
| **ALARMAS** | Dashboard UI con LEDs de alarma (rojo) y estado (verde) por zona |
| **CONTROL CERCOS** | Publica comandos ON/OFF desde BROKER hacia G1 |

**Zonas monitoreadas:**
- 🏠 Puelche (superior/inferior)
- 🚗 Estacionamiento (superior/inferior)
- 📦 Despacho (superior/inferior)
- ⚡ Alambron (único)

---

### 2. 🟢 G1 (`g1.json`)

**Raspberry G1 (IP: .106)** — El ejecutor de comandos de control.

| Canal | GPIO | Función |
|-------|------|---------|
| **C1** | GPIO24 (Relé 1) | Arma/desarma **TODOS** los cercos |
| **C2** | GPIO25 (Relé 2) | Arma/desarma solo **Alambron** |
| **C3** | GPIO24 | Activa al recibir CUALQUIER alarma |

**Características:**
- Pulso de 500ms para activación de relés
- Lee 7 estados PGM (GPIO23,22,12,20,19,4,21)
- Publica estados de cercos por MQTT

---

### 3. 🟠 REPEATER (`repeater_fixed.json`)

**Raspberry REPEATER (IP: .105)** — El detector de intrusiones.

| Entrada | GPIO | Zona |
|---------|------|------|
| IN1 | GPIO17 | Puelche superior |
| IN2 | GPIO18 | Puelche inferior |
| IN3 | GPIO10 | Estacionamiento superior |
| IN4 | GPIO9 | Estacionamiento inferior |
| IN5 | GPIO11 | Despacho superior |
| IN6 | GPIO22 | Despacho inferior |
| IN7 | GPIO27 | Alambron |

**Características:**
- Lee hebras de cerco físicas
- Publica alarmas con payload JSON enriquecido
- Origen: `repeater-rpi-publisher`

---

## 🚀 Inicio Rápido

### Requisitos Previos

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows/Mac) o Docker Engine (Linux)
- Git (opcional, para clonar)
- 3 Raspberry Pi con GPIO (para producción)

### Instalación

```bash
# 1. Clonar el repositorio
git clone https://github.com/schwarmak-dev/nodered-cerco-electric.git
cd nodered-cerco-electric

# 2. Configurar variables de entorno (opcional)
# Crear archivo .env con:
# MYSQL_ROOT_PASSWORD=tu_password_root
# MYSQL_USER=monitor
# MYSQL_PASSWORD=tu_password_monitor

# 3. Levantar todo el sistema
docker compose up -d --build
```

### Verificación

1. Abrir **Node-RED Editor**: `http://localhost:1880`
2. Abrir **Dashboard**: `http://localhost:1880/ui`
3. Verificar que los 3 flujos estén cargados (BROKER, G1, REPEATER)

### Configuración Inicial (Primera Vez)

1. Ir al tab **BROKER** en Node-RED
2. Hacer doble clic en el nodo `monitor_cercos` (MySQLdatabase)
3. Configurar credenciales:
   - **Host:** `mysql` (nombre del contenedor Docker)
   - **User:** `monitor`
   - **Password:** `monitorpass123`
4. Click **Update** → **Deploy**

---

## 📊 Dashboard

El dashboard profesional en `http://localhost:1880/ui` ofrece:

```
┌─────────────────────────────────────────────────────────────────┐
│                    DASHBOARD ELECTRICFENCE                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────┐  ┌─────────────────────┐              │
│  │   CERCO ALARMA      │  │   CERCO ESTADO      │              │
│  │                     │  │                     │              │
│  │  🔴 Puelche Sup     │  │  🟢 Puelche Sup     │              │
│  │  🔴 Puelche Inf     │  │  🟢 Puelche Inf     │              │
│  │  🔴 Estac. Sup      │  │  🟢 Estac. Sup      │              │
│  │  🔴 Estac. Inf      │  │  🟢 Estac. Inf      │              │
│  │  🔴 Desp. Sup       │  │  🟢 Desp. Sup       │              │
│  │  🔴 Desp. Inf       │  │  🟢 Desp. Inf       │              │
│  │  🔴 Alambron        │  │  🟢 Alambron        │              │
│  └─────────────────────┘  └─────────────────────┘              │
│                                                                 │
│  📈 Último Evento: Alarma Puelche superior - 12:34:56          │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**Características del Dashboard:**
- ✅ LEDs de estado por zona (rojo = alarma, verde = encendido)
- ✅ Conteo de alarmas activas
- ✅ Registro del último evento recibido
- ✅ Actualización en tiempo real

---

## 🗺️ Mapeo Completo de GPIO

### Dispositivos y IPs

| Dispositivo | IP | Función Principal |
|-------------|-----|-------------------|
| **REPEATER** | 192.168.1.105 | Detecta intrusiones, publica alarmas |
| **BROKER** | 192.168.1.104 | Recibe datos, muestra dashboard, controla |
| **G1** | 192.168.1.106 | Ejecuta comandos ON/OFF de cercos |

### REPEATER — Entradas (Hebras de Cerco)

```
┌─────────────────────────────────────────────────────────────┐
│                    REPEATER (.105)                           │
│                                                             │
│  IN1 ──► GPIO17 ──► Puelche Superior                       │
│  IN2 ──► GPIO18 ──► Puelche Inferior                       │
│  IN3 ──► GPIO10 ──► Estacionamiento Superior               │
│  IN4 ──► GPIO9  ──► Estacionamiento Inferior               │
│  IN5 ──► GPIO11 ──► Despacho Superior                      │
│  IN6 ──► GPIO22 ──► Despacho Inferior                      │
│  IN7 ──► GPIO27 ──► Alambron                               │
│                                                             │
│  intype: down — activa con 3.3V, reposo en GND             │
└─────────────────────────────────────────────────────────────┘
```

### BROKER — Salidas (Módulos Relé)

```
┌─────────────────────────────────────────────────────────────┐
│                    BROKER (.104)                             │
│                                                             │
│  MÓDULO RELÉ 1 — ALARMAS                                   │
│  ├── IN1 ──► GPIO17 ──► Alarma Puelche Superior            │
│  ├── IN2 ──► GPIO18 ──► Alarma Puelche Inferior            │
│  ├── IN3 ──► GPIO10 ──► Alarma Estacionamiento Superior    │
│  ├── IN4 ──► GPIO9  ──► Alarma Estacionamiento Inferior    │
│  ├── IN5 ──► GPIO11 ──► Alarma Despacho Superior           │
│  ├── IN6 ──► GPIO8  ──► Alarma Despacho Inferior           │
│  └── IN7 ──► GPIO7  ──► Alarma Alambron                    │
│                                                             │
│  MÓDULO RELÉ 2 — ESTADOS                                   │
│  ├── IN1 ──► GPIO23 ──► Estado Puelche Superior            │
│  ├── IN2 ──► GPIO22 ──► Estado Puelche Inferior            │
│  ├── IN3 ──► GPIO12 ──► Estado Estacionamiento Superior    │
│  ├── IN4 ──► GPIO20 ──► Estado Estacionamiento Inferior    │
│  ├── IN5 ──► GPIO19 ──► Estado Despacho Superior           │
│  ├── IN6 ──► GPIO4  ──► Estado Despacho Inferior           │
│  └── IN7 ──► GPIO21 ──► Estado Alambron                    │
└─────────────────────────────────────────────────────────────┘
```

### G1 — Control de Cercos

```
┌─────────────────────────────────────────────────────────────┐
│                    G1 (.106)                                 │
│                                                             │
│  SALIDAS (Control)                                          │
│  ├── GPIO24 (Relé 1) ──► Arma/desarma TODOS los cercos     │
│  └── GPIO25 (Relé 2) ──► Arma/desarma solo Alambron        │
│                                                             │
│  ENTRADAS (Estados PGM)                                     │
│  ├── GPIO23 ──► Puelche Superior                            │
│  ├── GPIO22 ──► Puelche Inferior                            │
│  ├── GPIO12 ──► Estacionamiento Superior                    │
│  ├── GPIO20 ──► Estacionamiento Inferior                    │
│  ├── GPIO19 ──► Despacho Superior                           │
│  ├── GPIO4  ──► Despacho Inferior                           │
│  └── GPIO21 ──► Alambron                                    │
│                                                             │
│  Pulso: 500ms al recibir active:true                        │
└─────────────────────────────────────────────────────────────┘
```

---

## 📂 Estructura del Proyecto

```
nodered-cerco-electric/
│
├── 📄 docker-compose.yml       # Orquestación de servicios
├── 📄 Dockerfile               # Imagen Node-RED personalizada
├── 📄 .env                     # Variables de entorno (MySQL)
├── 📄 LICENSE                  # Licencia MIT
├── 📄 README.md                # Este archivo
│
├── 📁 docker/
│   └── 📄 entrypoint.sh        # Script de entrada (combina flujos)
│
├── 📁 flows/                   # Flujos Node-RED
│   ├── 📄 brokernuevo.json     # BROKER — alarmas, estados, dashboard
│   ├── 📄 g1.json              # G1 — control ON/OFF cercos
│   └── 📄 repeater_fixed.json  # REPEATER — repetidor de alarmas
│
├── 📁 mosquitto/
│   └── 📁 config/
│       └── 📄 mosquitto.conf   # Configuración MQTT
│
└── 📁 mysql/
    └── 📁 init/
        └── 📄 01-schema.sql    # Tabla registro
```

---

## 🔧 Personalización

### Cambiar Credenciales MySQL

Crear archivo `.env` en la raíz del proyecto:

```env
MYSQL_ROOT_PASSWORD=tu_password_root_seguro
MYSQL_USER=monitor
MYSQL_PASSWORD=tu_password_monitor_seguro
```

### Cambiar Puertos

Editar `docker-compose.yml`:

```yaml
services:
  mosquitto:
    ports:
      - "1884:1883"  # Cambiar 1883 a 1884
  mysql:
    ports:
      - "3307:3306"  # Cambiar 3306 a 3307
  node-red:
    ports:
      - "1881:1880"  # Cambiar 1880 a 1881
```

### Agregar Nuevas Zonas

1. Editar el flujo correspondiente (BROKER, G1 o REPEATER)
2. Agregar nodos MQTT con el topic: `inchalam/cercos/alarma/{zona}/{subzona}`
3. Conectar a GPIO disponible en el módulo relé
4. Deploy y reiniciar contenedor

---

## 🐛 Solución de Problemas

| Problema | Solución |
|----------|----------|
| Node-RED no carga los flujos | Verificar que los JSON estén en `flows/` y reiniciar contenedor |
| MySQL no conecta | Verificar credenciales en `.env` y que el contenedor esté corriendo |
| MQTT no recibe mensajes | Verificar configuración de Mosquitto y IPs de los dispositivos |
| GPIO no responde | Verificar permisos y que los módulos relé estén conectados |

---

## 📝 Topics MQTT

```
inchalam/cercos/alarma/{zona}/{subzona}     # Alarmas de cerco
inchalam/cercos/estado/{zona}/{subzona}     # Estados de cerco
inchalam/cercos/onoff/#                      # Comandos ON/OFF
inchalam/cercos/onoff/alambron/#             # Control solo Alambron
```

**Ejemplo de payload:**
```json
{
  "topic": "inchalam/cercos/alarma/puelche/superior",
  "active": true,
  "value": 1,
  "description": "Alarma cerco Puelche superior",
  "origin": "repeater-rpi-publisher",
  "timestamp": "2026-06-08T12:34:56.789Z"
}
```

---

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Forke el repositorio
2. Cree una rama para su feature (`git checkout -b feature/nueva-zona`)
3. Commit sus cambios (`git commit -m 'Agregar nueva zona de cerco'`)
4. Push a la rama (`git push origin feature/nueva-zona`)
5. Abra un Pull Request

---

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Consulte el archivo [LICENSE](LICENSE) para más detalles.

---

## 🙏 Agradecimientos

- **[schwarmak-dev](https://github.com/schwarmak-dev)** — Creador original del proyecto
- **Node-RED** — Plataforma de programación visual para IoT
- **Eclipse Mosquitto** — Broker MQTT ligero y confiable
- **Docker** — Plataforma de contenedores para despliegue sencillo

---

## 📞 Soporte

Si tiene preguntas o problemas:

- 📧 Abra un [issue](https://github.com/schwarmak-dev/nodered-cerco-electric/issues) en GitHub
- 💬 Contacte al creador: [schwarmak-dev](https://github.com/schwarmak-dev)

---

<div align="center">

**Hecho con ❤️ para la comunidad de IoT y seguridad perimetral**

![GitHub Stars](https://img.shields.io/github/stars/schwarmak-dev/nodered-cerco-electric?style=social)
![GitHub Forks](https://img.shields.io/github/forks/schwarmak-dev/nodered-cerco-electric?style=social)

</div>

-- ============================================================
-- Surf en la Zurriola (Donostia) — esquema de base de datos
-- Motor: SQLite 3
--
-- Modela un año de surf en la playa de la Zurriola:
--   · surfistas y sus tablas
--   · condiciones del mar por franja horaria
--   · sesiones de surf (quién surfeó, con qué tabla,
--     en qué zona del pico y cómo fue)
-- ============================================================

PRAGMA foreign_keys = ON;

-- ------------------------------------------------------------
-- Surfistas habituales de la Zurriola
-- ------------------------------------------------------------
CREATE TABLE surfistas (
    surfista_id   INTEGER PRIMARY KEY,
    nombre        TEXT NOT NULL,
    nivel         TEXT NOT NULL CHECK (nivel IN ('principiante', 'intermedio', 'avanzado')),
    stance        TEXT NOT NULL CHECK (stance IN ('regular', 'goofy')),
    anio_inicio   INTEGER NOT NULL CHECK (anio_inicio BETWEEN 1980 AND 2026),
    barrio        TEXT                -- barrio de Donostia donde vive
);

-- ------------------------------------------------------------
-- Tablas de surf (cada surfista tiene su quiver)
-- ------------------------------------------------------------
CREATE TABLE tablas (
    tabla_id      INTEGER PRIMARY KEY,
    surfista_id   INTEGER NOT NULL REFERENCES surfistas(surfista_id),
    tipo          TEXT NOT NULL CHECK (tipo IN ('shortboard', 'fish', 'evolutiva', 'longboard')),
    longitud_pies REAL NOT NULL CHECK (longitud_pies BETWEEN 5.0 AND 10.0),
    litros        REAL NOT NULL CHECK (litros BETWEEN 20 AND 90)
);

-- ------------------------------------------------------------
-- Condiciones del mar en la Zurriola, tres franjas al día.
-- El viento S/SO es offshore en la Zurriola (mar ordenado);
-- el N/NO es onshore (mar movido).
-- ------------------------------------------------------------
CREATE TABLE condiciones (
    condicion_id      INTEGER PRIMARY KEY,
    fecha             TEXT NOT NULL,                -- ISO 8601: YYYY-MM-DD
    franja            TEXT NOT NULL CHECK (franja IN ('amanecer', 'mediodia', 'tarde')),
    altura_ola_m      REAL NOT NULL CHECK (altura_ola_m >= 0),
    periodo_s         REAL NOT NULL CHECK (periodo_s BETWEEN 3 AND 22),
    direccion_viento  TEXT NOT NULL CHECK (direccion_viento IN ('N','NE','E','SE','S','SO','O','NO')),
    viento_kmh        REAL NOT NULL CHECK (viento_kmh >= 0),
    marea             TEXT NOT NULL CHECK (marea IN ('subiendo', 'bajando')),
    altura_marea_m    REAL NOT NULL CHECK (altura_marea_m BETWEEN 0 AND 5),
    temp_agua_c       REAL NOT NULL CHECK (temp_agua_c BETWEEN 8 AND 25),
    UNIQUE (fecha, franja)
);

-- ------------------------------------------------------------
-- Sesiones de surf. Una sesión ocurre bajo unas condiciones
-- concretas, en una zona del pico, con una tabla del quiver.
-- ------------------------------------------------------------
CREATE TABLE sesiones (
    sesion_id     INTEGER PRIMARY KEY,
    surfista_id   INTEGER NOT NULL REFERENCES surfistas(surfista_id),
    tabla_id      INTEGER NOT NULL REFERENCES tablas(tabla_id),
    condicion_id  INTEGER NOT NULL REFERENCES condiciones(condicion_id),
    zona          TEXT NOT NULL CHECK (zona IN ('Sagüés', 'centro', 'Kursaal')),
    duracion_min  INTEGER NOT NULL CHECK (duracion_min BETWEEN 15 AND 240),
    olas_cogidas  INTEGER NOT NULL CHECK (olas_cogidas >= 0),
    valoracion    INTEGER NOT NULL CHECK (valoracion BETWEEN 1 AND 10)
);

-- Índices para las consultas más habituales
CREATE INDEX idx_condiciones_fecha   ON condiciones(fecha);
CREATE INDEX idx_sesiones_surfista   ON sesiones(surfista_id);
CREATE INDEX idx_sesiones_condicion  ON sesiones(condicion_id);

-- ------------------------------------------------------------
-- Vista de conveniencia: sesiones con toda su información
-- desnormalizada, para no repetir los JOIN en cada consulta.
-- ------------------------------------------------------------
CREATE VIEW v_sesiones AS
SELECT
    se.sesion_id,
    su.nombre,
    su.nivel,
    c.fecha,
    c.franja,
    se.zona,
    t.tipo          AS tipo_tabla,
    c.altura_ola_m,
    c.periodo_s,
    c.direccion_viento,
    c.viento_kmh,
    c.marea,
    c.altura_marea_m,
    se.duracion_min,
    se.olas_cogidas,
    se.valoracion
FROM sesiones    se
JOIN surfistas   su ON su.surfista_id  = se.surfista_id
JOIN tablas      t  ON t.tabla_id      = se.tabla_id
JOIN condiciones c  ON c.condicion_id  = se.condicion_id;

# -*- coding: utf-8 -*-
"""
Genera seed.sql con un año de datos sintéticos pero realistas
de surf en la Zurriola (jul 2025 - jun 2026).

Realismo que se intenta capturar:
  · más mar en otoño/invierno, verano más flojo
  · viento S/SO (offshore en la Zurriola) => mejores sesiones
  · temperatura del agua estacional (12-22 ºC)
  · los surfistas salen más cuando las condiciones acompañan,
    y los principiantes evitan los días grandes
  · la valoración de la sesión depende de las condiciones

Uso:  python3 tools/generar_datos.py > seed.sql
"""

import math
import random
from datetime import date, timedelta

random.seed(2026)  # reproducible

# ------------------------------------------------------------------
# Surfistas: (nombre, nivel, stance, año inicio, barrio)
# ------------------------------------------------------------------
SURFISTAS = [
    ("Maialen Etxeberria", "avanzado",      "regular", 2008, "Gros"),
    ("Jon Aguirre",        "avanzado",      "goofy",   2005, "Gros"),
    ("Nerea Zubizarreta",  "avanzado",      "regular", 2011, "Egia"),
    ("Iker Lasa",          "avanzado",      "goofy",   2013, "Intxaurrondo"),
    ("Ane Otegi",          "intermedio",    "regular", 2017, "Gros"),
    ("Mikel Urrutia",      "intermedio",    "regular", 2016, "Amara"),
    ("Uxue Garmendia",     "intermedio",    "goofy",   2019, "Antiguo"),
    ("Aitor Elizondo",     "intermedio",    "regular", 2018, "Egia"),
    ("Leire Arrieta",      "intermedio",    "goofy",   2020, "Gros"),
    ("Unai Mendizabal",    "intermedio",    "regular", 2015, "Centro"),
    ("Irati Goikoetxea",   "principiante",  "regular", 2024, "Gros"),
    ("Xabier Aranburu",    "principiante",  "goofy",   2023, "Amara"),
    ("Olatz Iriondo",      "principiante",  "regular", 2024, "Antiguo"),
    ("Beñat Larrañaga",    "principiante",  "regular", 2025, "Egia"),
    ("June Salaberria",    "principiante",  "goofy",   2023, "Intxaurrondo"),
]

# tipos de tabla plausibles por nivel: (tipo, rango longitud, rango litros)
TABLAS_POR_NIVEL = {
    "avanzado":     [("shortboard", (5.7, 6.4), (26, 34)), ("fish", (5.5, 6.2), (28, 38))],
    "intermedio":   [("shortboard", (6.0, 6.8), (30, 40)), ("evolutiva", (6.6, 7.6), (38, 52)), ("fish", (5.8, 6.4), (32, 42))],
    "principiante": [("evolutiva", (7.0, 8.0), (48, 62)), ("longboard", (8.5, 9.6), (60, 80))],
}

FRANJAS = ["amanecer", "mediodia", "tarde"]
VIENTOS = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"]
# En la Zurriola el offshore es S/SO/SE; el onshore N/NO/NE
OFFSHORE = {"S": 1.0, "SO": 0.9, "SE": 0.8, "O": 0.4, "E": 0.4, "NE": 0.15, "NO": 0.1, "N": 0.0}

INICIO = date(2025, 7, 1)
FIN = date(2026, 6, 30)


def q(s):
    return "'" + s.replace("'", "''") + "'"


def estacionalidad(d):
    """0 en pleno verano, 1 en pleno invierno (para tamaño de mar)."""
    dia = d.timetuple().tm_yday
    # pico de invierno hacia mediados de enero (día ~15)
    return 0.5 - 0.5 * math.cos(2 * math.pi * (dia - 15) / 365.25 + math.pi)


def calidad(altura, periodo, viento_dir, viento_kmh, altura_marea):
    """Puntuación 0-1 de lo buenas que son las condiciones en la Zurriola."""
    # tamaño: lo ideal ronda 1.0-1.8 m
    s_altura = math.exp(-((altura - 1.4) ** 2) / (2 * 0.55 ** 2))
    # periodo: mejor cuanto más largo (satura hacia 14 s)
    s_periodo = min(periodo / 14.0, 1.0)
    # viento: offshore flojo es lo mejor; el onshore fuerte lo destroza
    s_viento = OFFSHORE[viento_dir] * math.exp(-max(viento_kmh - 8, 0) / 25.0)
    if OFFSHORE[viento_dir] < 0.3:
        s_viento = max(s_viento, 0.25 * math.exp(-viento_kmh / 15.0))
    # marea: la Zurriola suele funcionar mejor a media marea
    s_marea = math.exp(-((altura_marea - 2.2) ** 2) / (2 * 1.0 ** 2))
    return 0.40 * s_altura + 0.25 * s_periodo + 0.25 * s_viento + 0.10 * s_marea


def main():
    print("-- Archivo generado por tools/generar_datos.py — no editar a mano.")
    print("PRAGMA foreign_keys = ON;")
    print("BEGIN TRANSACTION;")

    # ---- surfistas ----
    for i, (nombre, nivel, stance, anio, barrio) in enumerate(SURFISTAS, start=1):
        print("INSERT INTO surfistas VALUES (%d, %s, %s, %s, %d, %s);"
              % (i, q(nombre), q(nivel), q(stance), anio, q(barrio)))

    # ---- tablas (quiver de cada surfista) ----
    tablas_de = {}  # surfista_id -> [tabla_id, ...]
    tabla_id = 0
    for sid, (_, nivel, _, _, _) in enumerate(SURFISTAS, start=1):
        opciones = TABLAS_POR_NIVEL[nivel]
        n = random.choice([1, 2, 2, 3]) if nivel != "principiante" else random.choice([1, 1, 2])
        tablas_de[sid] = []
        for tipo, (lmin, lmax), (vmin, vmax) in random.sample(opciones, min(n, len(opciones))):
            tabla_id += 1
            tablas_de[sid].append(tabla_id)
            print("INSERT INTO tablas VALUES (%d, %d, %s, %.1f, %.1f);"
                  % (tabla_id, sid, q(tipo), random.uniform(lmin, lmax), random.uniform(vmin, vmax)))

    # ---- condiciones y sesiones ----
    condicion_id = 0
    sesion_id = 0
    d = INICIO
    # estado del swell con algo de persistencia entre días
    swell = 1.0
    while d <= FIN:
        inv = estacionalidad(d)  # 0 verano, 1 invierno
        # el swell evoluciona día a día (persistencia + estacionalidad)
        objetivo = 0.6 + 1.5 * inv
        swell += 0.45 * (objetivo - swell) + random.gauss(0, 0.35)
        swell = max(0.15, min(swell, 4.0))
        temp_agua = 12.5 + 9.0 * (1 - inv) + random.gauss(0, 0.6)
        # dirección de viento del día (cambia poco entre franjas)
        viento_dia = random.choices(VIENTOS, weights=[14, 10, 6, 8, 12, 14, 10, 16])[0]

        for fi, franja in enumerate(FRANJAS):
            condicion_id += 1
            altura = max(0.1, swell + random.gauss(0, 0.15))
            periodo = max(4.0, min(19.0, 7.0 + 4.5 * inv + 2.5 * (altura - 1) + random.gauss(0, 1.2)))
            # al amanecer suele haber menos viento (térmica)
            viento_dir = viento_dia if random.random() < 0.75 else random.choice(VIENTOS)
            viento_kmh = max(0.0, random.gauss(8 + 6 * fi * 0.8 + 6 * inv, 5))
            marea = random.choice(["subiendo", "bajando"])
            altura_marea = round(random.uniform(0.4, 4.6), 1)

            print("INSERT INTO condiciones VALUES (%d, %s, %s, %.2f, %.1f, %s, %.1f, %s, %.1f, %.1f);"
                  % (condicion_id, q(d.isoformat()), q(franja), altura, periodo,
                     q(viento_dir), viento_kmh, q(marea), altura_marea, temp_agua))

            cal = calidad(altura, periodo, viento_dir, viento_kmh, altura_marea)

            # ---- ¿quién se mete al agua en esta franja? ----
            finde = d.weekday() >= 5
            for sid, (_, nivel, _, _, _) in enumerate(SURFISTAS, start=1):
                p = 0.05 + 0.55 * cal
                if nivel == "principiante":
                    p *= 0.55
                    if altura > 1.8:      # los días grandes ni se asoman
                        p = 0.0
                elif nivel == "avanzado":
                    p *= 1.25
                if not finde and franja == "mediodia":
                    p *= 0.35             # entre semana a mediodía se curra
                if finde:
                    p *= 1.3
                if random.random() >= min(p, 0.85):
                    continue

                sesion_id += 1
                tabla = random.choice(tablas_de[sid])
                zona = random.choices(["Sagüés", "centro", "Kursaal"],
                                      weights=[45, 35, 20] if nivel != "principiante" else [15, 45, 40])[0]
                duracion = int(max(20, min(210, random.gauss(60 + 60 * cal, 20))))
                destreza = {"principiante": 4, "intermedio": 8, "avanzado": 13}[nivel]
                olas = max(0, int(random.gauss(destreza * (duracion / 60.0) * (0.4 + 0.8 * cal), 3)))
                valoracion = max(1, min(10, int(round(random.gauss(2.5 + 7.0 * cal, 1.1)))))

                print("INSERT INTO sesiones VALUES (%d, %d, %d, %d, %s, %d, %d, %d);"
                      % (sesion_id, sid, tabla, condicion_id, q(zona), duracion, olas, valoracion))
        d += timedelta(days=1)

    print("COMMIT;")


if __name__ == "__main__":
    main()

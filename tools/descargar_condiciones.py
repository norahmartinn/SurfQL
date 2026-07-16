# -*- coding: utf-8 -*-
"""
Descarga las condiciones REALES del mar frente a la Zurriola
(jul 2025 - jun 2026) desde las APIs abiertas de Open-Meteo
y las deja en datos/condiciones_reales.csv.

Fuentes (gratuitas, sin API key):
  · Marine API  -> altura y periodo de ola, temperatura del agua
                   y altura del mar (marea), modelo MFWAM/ERA5
  · Archive API -> viento a 10 m (velocidad y dirección)

De las series horarias se extraen tres franjas al día
(amanecer=8h, mediodia=13h, tarde=18h). El sentido de la marea
(subiendo/bajando) se deduce comparando la altura del mar con
la hora anterior. La altura de marea se pasa de referencia
"nivel medio del mar" a la convención de las tablas de mareas
locales (~0-4.7 m) sumando 2.5 m.

Uso:  python3 tools/descargar_condiciones.py
"""

import csv
import json
import os
import urllib.request

LAT, LON = 43.328, -1.973          # playa de la Zurriola
DESDE, HASTA = "2025-07-01", "2026-06-30"
FRANJAS = {8: "amanecer", 13: "mediodia", 18: "tarde"}
OFFSET_MAREA = 2.5                 # nivel medio del mar -> escala de tabla de mareas

MARINE_URL = (
    "https://marine-api.open-meteo.com/v1/marine"
    "?latitude=%s&longitude=%s"
    "&hourly=wave_height,wave_period,sea_surface_temperature,sea_level_height_msl"
    "&start_date=%s&end_date=%s&timezone=Europe%%2FMadrid"
) % (LAT, LON, DESDE, HASTA)

VIENTO_URL = (
    "https://archive-api.open-meteo.com/v1/archive"
    "?latitude=%s&longitude=%s"
    "&hourly=wind_speed_10m,wind_direction_10m"
    "&start_date=%s&end_date=%s&timezone=Europe%%2FMadrid"
) % (LAT, LON, DESDE, HASTA)


def descargar(url):
    with urllib.request.urlopen(url, timeout=120) as r:
        return json.load(r)["hourly"]


def rumbo(grados):
    """Grados meteorológicos (de dónde viene) -> rosa de 8 puntos en español."""
    puntos = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"]
    return puntos[int((grados + 22.5) // 45) % 8]


def rellenar(serie):
    """Rellena huecos (None) con el último valor conocido."""
    ultimo = None
    out = []
    for v in serie:
        if v is not None:
            ultimo = v
        out.append(ultimo)
    return out


def main():
    print("Descargando oleaje, marea y temperatura del agua (Open-Meteo Marine)...")
    mar = descargar(MARINE_URL)
    print("Descargando viento (Open-Meteo Archive)...")
    viento = descargar(VIENTO_URL)
    assert mar["time"] == viento["time"], "las dos series no están alineadas"

    ola = rellenar(mar["wave_height"])
    periodo = rellenar(mar["wave_period"])
    temp_agua = rellenar(mar["sea_surface_temperature"])
    nivel_mar = rellenar(mar["sea_level_height_msl"])
    v_kmh = rellenar(viento["wind_speed_10m"])
    v_dir = rellenar(viento["wind_direction_10m"])

    os.makedirs("datos", exist_ok=True)
    ruta = os.path.join("datos", "condiciones_reales.csv")
    n = 0
    with open(ruta, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["fecha", "franja", "altura_ola_m", "periodo_s",
                    "direccion_viento", "viento_kmh", "marea",
                    "altura_marea_m", "temp_agua_c"])
        for i, t in enumerate(mar["time"]):
            hora = int(t[11:13])
            if hora not in FRANJAS or i == 0:
                continue
            marea = "subiendo" if nivel_mar[i] >= nivel_mar[i - 1] else "bajando"
            w.writerow([
                t[:10],
                FRANJAS[hora],
                round(ola[i], 2),
                round(min(max(periodo[i], 3.0), 22.0), 1),
                rumbo(v_dir[i]),
                round(v_kmh[i], 1),
                marea,
                round(min(max(nivel_mar[i] + OFFSET_MAREA, 0.0), 5.0), 2),
                round(min(max(temp_agua[i], 8.0), 25.0), 1),
            ])
            n += 1
    print("OK: %d franjas escritas en %s" % (n, ruta))


if __name__ == "__main__":
    main()

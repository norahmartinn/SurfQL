-- Progresión mes a mes de los principiantes: ¿mejoran con el tiempo?
-- Técnicas: strftime para agrupar por mes, funciones de ventana
-- LAG() para comparar con el mes anterior y media móvil de 3 meses
-- (AVG OVER con marco ROWS BETWEEN).

WITH mensual AS (
    SELECT
        su.nombre,
        strftime('%Y-%m', c.fecha)                       AS mes,
        ROUND(SUM(se.olas_cogidas) * 60.0
              / SUM(se.duracion_min), 2)                 AS olas_por_hora
    FROM sesiones se
    JOIN surfistas   su ON su.surfista_id  = se.surfista_id
    JOIN condiciones c  ON c.condicion_id  = se.condicion_id
    WHERE su.nivel = 'principiante'
    GROUP BY su.nombre, mes
)
SELECT
    nombre,
    mes,
    olas_por_hora,
    LAG(olas_por_hora) OVER w                            AS mes_anterior,
    ROUND(olas_por_hora - LAG(olas_por_hora) OVER w, 2)  AS diferencia,
    ROUND(AVG(olas_por_hora) OVER (
        w ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2)  AS media_movil_3m
FROM mensual
WINDOW w AS (PARTITION BY nombre ORDER BY mes)
ORDER BY nombre, mes;

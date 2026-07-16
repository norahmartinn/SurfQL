-- Ranking de surfistas por olas cogidas por hora de agua.
-- Técnicas: funciones de ventana (RANK() OVER con PARTITION BY),
-- agregación por surfista, CTE.
--
-- Se rankea dentro de cada nivel: no tiene sentido comparar
-- a un principiante con alguien que lleva 20 años en el agua.

WITH stats AS (
    SELECT
        su.nombre,
        su.nivel,
        COUNT(*)                                            AS sesiones,
        SUM(se.olas_cogidas)                                AS olas_total,
        ROUND(SUM(se.duracion_min) / 60.0, 1)               AS horas_agua,
        ROUND(SUM(se.olas_cogidas) * 60.0
              / SUM(se.duracion_min), 2)                    AS olas_por_hora
    FROM sesiones se
    JOIN surfistas su ON su.surfista_id = se.surfista_id
    GROUP BY su.surfista_id
)
SELECT
    RANK() OVER (PARTITION BY nivel ORDER BY olas_por_hora DESC) AS puesto,
    nivel,
    nombre,
    sesiones,
    horas_agua,
    olas_total,
    olas_por_hora
FROM stats
ORDER BY
    CASE nivel WHEN 'avanzado' THEN 1 WHEN 'intermedio' THEN 2 ELSE 3 END,
    puesto;

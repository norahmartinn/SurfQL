-- La racha más larga de días seguidos surfeando de cada surfista.
-- Técnicas: problema clásico de "gaps and islands" con CTEs
-- encadenadas, DISTINCT, funciones de ventana (ROW_NUMBER)
-- y aritmética de fechas con julianday().
--
-- Idea: si a cada fecha le restamos su número de fila (ordenado por
-- fecha), los días consecutivos comparten el mismo valor => forman grupo.

WITH dias AS (
    SELECT DISTINCT se.surfista_id, c.fecha
    FROM sesiones se
    JOIN condiciones c ON c.condicion_id = se.condicion_id
),
numerados AS (
    SELECT
        surfista_id,
        fecha,
        julianday(fecha)
          - ROW_NUMBER() OVER (PARTITION BY surfista_id ORDER BY fecha) AS grupo
    FROM dias
),
rachas AS (
    SELECT
        surfista_id,
        MIN(fecha)  AS desde,
        MAX(fecha)  AS hasta,
        COUNT(*)    AS dias_seguidos
    FROM numerados
    GROUP BY surfista_id, grupo
)
SELECT
    su.nombre,
    su.nivel,
    r.desde,
    r.hasta,
    MAX(r.dias_seguidos) AS racha_maxima
FROM rachas r
JOIN surfistas su ON su.surfista_id = r.surfista_id
GROUP BY r.surfista_id
ORDER BY racha_maxima DESC;

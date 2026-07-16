-- ¿Cuáles fueron los 10 mejores días del año en la Zurriola?
-- Técnicas: JOIN múltiple, GROUP BY, HAVING, agregación.
--
-- Un "buen día" = valoración media alta con un mínimo de sesiones
-- (para que un 10 aislado de una sola persona no cuente como día épico).

SELECT
    c.fecha,
    COUNT(*)                        AS sesiones,
    ROUND(AVG(se.valoracion), 2)    AS valoracion_media,
    ROUND(AVG(c.altura_ola_m), 2)   AS ola_m,
    ROUND(AVG(c.periodo_s), 1)      AS periodo_s,
    MAX(c.direccion_viento)         AS viento
FROM sesiones se
JOIN condiciones c ON c.condicion_id = se.condicion_id
GROUP BY c.fecha
HAVING COUNT(*) >= 8
ORDER BY valoracion_media DESC
LIMIT 10;

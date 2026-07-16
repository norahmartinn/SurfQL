-- Para quien tiene más de una tabla: ¿usa cada tabla para lo que toca?
-- (tabla corta para días buenos, tabla con volumen para días flojos)
-- Técnicas: subconsulta correlada en el WHERE (surfistas con >1 tabla),
-- JOIN de 4 tablas, agregación por tabla del quiver.

SELECT
    su.nombre,
    t.tipo,
    t.longitud_pies,
    t.litros,
    COUNT(*)                          AS sesiones,
    ROUND(AVG(c.altura_ola_m), 2)     AS ola_media_m,
    ROUND(AVG(c.periodo_s), 1)        AS periodo_medio_s
FROM sesiones se
JOIN surfistas   su ON su.surfista_id = se.surfista_id
JOIN tablas      t  ON t.tabla_id     = se.tabla_id
JOIN condiciones c  ON c.condicion_id = se.condicion_id
WHERE (SELECT COUNT(*) FROM tablas t2
       WHERE t2.surfista_id = su.surfista_id) > 1
GROUP BY t.tabla_id
ORDER BY su.nombre, ola_media_m DESC;

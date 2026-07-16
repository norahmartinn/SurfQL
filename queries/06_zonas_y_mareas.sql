-- ¿Qué zona del pico funciona mejor según la marea?
-- Técnicas: GROUP BY sobre varias dimensiones, CASE para
-- discretizar la altura de marea, agregados con ROUND.
--
-- Zonas de la Zurriola: Sagüés (la punta, la ola con más pared),
-- el centro, y el lado del Kursaal (más protegido).

SELECT
    se.zona,
    CASE
        WHEN c.altura_marea_m < 1.5 THEN 'baja'
        WHEN c.altura_marea_m < 3.0 THEN 'media'
        ELSE 'alta'
    END                              AS tramo_marea,
    COUNT(*)                         AS sesiones,
    ROUND(AVG(se.valoracion), 2)     AS valoracion_media,
    ROUND(AVG(se.olas_cogidas), 1)   AS olas_media
FROM sesiones se
JOIN condiciones c ON c.condicion_id = se.condicion_id
GROUP BY se.zona, tramo_marea
ORDER BY se.zona,
         CASE tramo_marea WHEN 'baja' THEN 1 WHEN 'media' THEN 2 ELSE 3 END;

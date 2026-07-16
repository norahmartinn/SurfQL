-- ¿Con qué combinación de tamaño de ola y tipo de viento
-- disfruta más la gente en la Zurriola?
-- Técnicas: CASE para discretizar variables continuas,
-- tabla cruzada (pivot manual) con agregación condicional.
--
-- En la Zurriola el viento de componente sur es offshore (ordena el mar)
-- y el de componente norte es onshore (lo destroza).

SELECT
    CASE
        WHEN c.altura_ola_m < 0.8 THEN '1. pequeño (<0.8 m)'
        WHEN c.altura_ola_m < 1.5 THEN '2. medio (0.8-1.5 m)'
        WHEN c.altura_ola_m < 2.2 THEN '3. bueno (1.5-2.2 m)'
        ELSE                           '4. grande (>2.2 m)'
    END AS tamano,
    ROUND(AVG(CASE WHEN c.direccion_viento IN ('S','SO','SE')
                   THEN se.valoracion END), 2) AS offshore,
    ROUND(AVG(CASE WHEN c.direccion_viento IN ('E','O')
                   THEN se.valoracion END), 2) AS lateral,
    ROUND(AVG(CASE WHEN c.direccion_viento IN ('N','NO','NE')
                   THEN se.valoracion END), 2) AS onshore,
    COUNT(*) AS sesiones
FROM sesiones se
JOIN condiciones c ON c.condicion_id = se.condicion_id
GROUP BY tamano
ORDER BY tamano;

-- Días desaprovechados: franjas con pinta de buenas condiciones
-- (ola de 1 a 2 m, periodo largo, viento offshore flojo)
-- en las que casi nadie se metió al agua.
-- Técnicas: LEFT JOIN con agregación, filtrado sobre el agregado
-- en HAVING, COUNT sobre columna anulable.

SELECT
    c.fecha,
    c.franja,
    c.altura_ola_m,
    c.periodo_s,
    c.direccion_viento,
    c.viento_kmh,
    COUNT(se.sesion_id) AS sesiones
FROM condiciones c
LEFT JOIN sesiones se ON se.condicion_id = c.condicion_id
WHERE c.altura_ola_m BETWEEN 1.0 AND 2.0
  AND c.periodo_s >= 11
  AND c.direccion_viento IN ('S', 'SO', 'SE')
  AND c.viento_kmh < 15
GROUP BY c.condicion_id
HAVING COUNT(se.sesion_id) <= 2
ORDER BY c.fecha, c.franja;






/* ===============================
caso 1: analisis de propiedades
=============================== */

SELECT
    p.nro_propiedad                AS "ID PROPIEDAD",
    p.direccion_propiedad         AS "DIRECCIÓN",
    c.nombre_comuna               AS "COMUNA",
    p.nro_dormitorios             AS "DORMITORIOS",
    TO_CHAR(p.valor_arriendo, '$999,999,999') AS "ARRIENDO",
    TO_CHAR(p.valor_gasto_comun, '$999,999,999') AS "GASTO COMÚN",
    
    -- Ajuste del 10%
    TO_CHAR(ROUND(p.valor_gasto_comun * 1.10), '$999,999,999') AS "GASTO COMÚN AJUSTADO"

FROM PROPIEDAD p
JOIN COMUNA c ON p.id_comuna = c.id_comuna

WHERE p.valor_arriendo < &VALOR_MAXIMO
AND p.nro_dormitorios IS NOT NULL
AND p.id_comuna IN (82, 84, 87)

ORDER BY 
    p.valor_gasto_comun ASC NULLS LAST,
    p.valor_arriendo DESC;



/* =========================================================
   CASO 2: ANÁLISIS DE ANTIGÜEDAD DE ARRIENDO
   ========================================================= */

SELECT
    p.nro_propiedad                       AS "ID PROPIEDAD",
    p.direccion_propiedad                 AS "DIRECCIÓN",
    
    TO_CHAR(a.fecini_arriendo, 'DD/MM/YYYY') AS "FECHA INICIO",
    
    CASE 
        WHEN a.fecter_arriendo IS NULL THEN 'Propiedad Actualmente Arrendada'
        ELSE TO_CHAR(a.fecter_arriendo, 'DD/MM/YYYY')
    END AS "FECHA TÉRMINO",
    
    -- Cálculo días
    ROUND(
        NVL(a.fecter_arriendo, SYSDATE) - a.fecini_arriendo
    ) AS "DÍAS ARRENDADOS",
    
    -- Cálculo años
    ROUND(
        MONTHS_BETWEEN(NVL(a.fecter_arriendo, SYSDATE), a.fecini_arriendo) / 12
    ) AS "AÑOS",
    
    -- Clasificación
    CASE
        WHEN MONTHS_BETWEEN(NVL(a.fecter_arriendo, SYSDATE), a.fecini_arriendo)/12 >= 10 
            THEN 'COMPROMISO DE VENTA'
        WHEN MONTHS_BETWEEN(NVL(a.fecter_arriendo, SYSDATE), a.fecini_arriendo)/12 BETWEEN 5 AND 9 
            THEN 'CLIENTE ANTIGUO'
        ELSE 'CLIENTE NUEVO'
    END AS "CLASIFICACIÓN"

FROM ARRIENDO_PROPIEDAD a
JOIN PROPIEDAD p ON a.nro_propiedad = p.nro_propiedad

WHERE 
    (NVL(a.fecter_arriendo, SYSDATE) - a.fecini_arriendo) >= &DIAS_MINIMOS

ORDER BY 
    "DÍAS ARRENDADOS" DESC;



/* =========================================================
   CASO 3: ARRIENDO PROMEDIO POR TIPO DE PROPIEDAD
   ========================================================= */

SELECT
    tp.desc_tipo_propiedad AS "TIPO PROPIEDAD",
    
    COUNT(*) AS "CANTIDAD PROPIEDADES",
    
    TO_CHAR(ROUND(AVG(p.valor_arriendo)), '$999,999,999') 
        AS "PROMEDIO ARRIENDO",
    
    TO_CHAR(ROUND(AVG(p.valor_gasto_comun)), '$999,999,999') 
        AS "PROMEDIO GASTO COMÚN"

FROM PROPIEDAD p
JOIN TIPO_PROPIEDAD tp 
    ON p.id_tipo_propiedad = tp.id_tipo_propiedad

GROUP BY tp.desc_tipo_propiedad

HAVING ROUND(AVG(p.valor_arriendo)) >= &PROMEDIO_MINIMO

ORDER BY 
    tp.desc_tipo_propiedad ASC,
    AVG(p.valor_arriendo) DESC;




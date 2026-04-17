







-- Crear tabla de resultados

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE RECAUDACION_BONOS_MEDICOS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE RECAUDACION_BONOS_MEDICOS
(
    RUT_MEDICO         VARCHAR2(20),
    NOMBRE_MEDICO      VARCHAR2(120),
    TOTAL_RECAUDADO    NUMBER,
    UNIDAD_MEDICA      VARCHAR2(80)
);

-- Insertar informacion calculada

INSERT INTO RECAUDACION_BONOS_MEDICOS
SELECT
    m.med_run || '-' || m.dv_run     AS RUT_MEDICO,
    INITCAP(m.pnombre || ' ' || m.appaterno || ' ' || m.apmaterno) AS NOMBRE_MEDICO,
    ROUND(SUM(b.costo_bono))         AS TOTAL_RECAUDADO,
    u.nombre_unidad                  AS UNIDAD_MEDICA

FROM medico m

JOIN unidad_medica u
ON m.id_unidad = u.id_unidad

JOIN consulta c
ON c.id_medico = m.id_medico

JOIN bono b
ON b.id_consulta = c.id_consulta

JOIN cargo ca
ON m.id_cargo = ca.id_cargo

WHERE
    EXTRACT(YEAR FROM b.fecha_emision) =
    EXTRACT(YEAR FROM SYSDATE) - 1

AND ca.nombre_cargo NOT IN
(
    'DIRECTOR',
    'SUBDIRECTOR',
    'JEFE MEDICO'
)

GROUP BY
    m.med_run,
    m.dv_run,
    m.pnombre,
    m.appaterno,
    m.apmaterno,
    u.nombre_unidad

ORDER BY
    TOTAL_RECAUDADO ASC;

COMMIT;



/*========================================================
CASO 2: PERDIDAS POR ESPECIALIDAD
========================================================*/

-- Consulta principal de perdidas

SELECT

    e.nombre_especialidad              AS ESPECIALIDAD_MEDICA,
    COUNT(b.id_bono)                   AS CANTIDAD_BONOS,
    ROUND(SUM(b.costo_bono))           AS MONTO_PERDIDA,
    MIN(b.fecha_emision)               AS FECHA_BONO,

    CASE
        WHEN EXTRACT(YEAR FROM MIN(b.fecha_emision)) >=
             EXTRACT(YEAR FROM SYSDATE) - 1
        THEN 'COBRABLE'
        ELSE 'INCOBRABLE'
    END AS ESTADO_DE_COBRO

FROM bono b

JOIN consulta c
ON b.id_consulta = c.id_consulta

JOIN medico m
ON c.id_medico = m.id_medico

JOIN especialidad e
ON m.id_especialidad = e.id_especialidad

WHERE b.id_bono NOT IN
(
    SELECT id_bono
    FROM pagos
)

GROUP BY
    e.nombre_especialidad

ORDER BY
    CANTIDAD_BONOS ASC,
    MONTO_PERDIDA DESC;



/*========================================================
CASO 3: PROYECCION PRESUPUESTARIA
========================================================*/

-- Eliminar datos anteriores del año actual

DELETE FROM CANT_BONOS_PACIENTES_ANNIO
WHERE ANNIO_CALCULO =
EXTRACT(YEAR FROM SYSDATE);


-- Insertar datos calculados

INSERT INTO CANT_BONOS_PACIENTES_ANNIO
(
    ANNIO_CALCULO,
    PAC_RUN,
    DV_RUN,
    EDAD,
    CANTIDAD_BONOS,
    MONTO_TOTAL_BONOS,
    SISTEMA_SALUD
)

SELECT

    EXTRACT(YEAR FROM SYSDATE) AS ANNIO_CALCULO,
    p.pac_run,
    p.dv_run,

    TRUNC(
        MONTHS_BETWEEN(SYSDATE, p.fecha_nacimiento) / 12
    ) AS EDAD,

    COUNT(b.id_bono) AS CANTIDAD_BONOS,

    ROUND(NVL(SUM(b.costo_bono),0)) AS MONTO_TOTAL_BONOS,

    s.nombre_sistema AS SISTEMA_SALUD

FROM paciente p

LEFT JOIN sistema_salud s
ON p.id_sistema = s.id_sistema

LEFT JOIN consulta c
ON p.id_paciente = c.id_paciente

LEFT JOIN bono b
ON c.id_consulta = b.id_consulta
AND EXTRACT(YEAR FROM b.fecha_emision) =
    EXTRACT(YEAR FROM SYSDATE) - 1

GROUP BY
    p.pac_run,
    p.dv_run,
    p.fecha_nacimiento,
    s.nombre_sistema

HAVING
    COUNT(b.id_bono) <=
    (
        SELECT ROUND(AVG(total_bonos))
        FROM
        (
            SELECT COUNT(id_bono) total_bonos
            FROM bono
            WHERE EXTRACT(YEAR FROM fecha_emision) =
            EXTRACT(YEAR FROM SYSDATE) - 1
            GROUP BY id_paciente
        )
    )

ORDER BY
    MONTO_TOTAL_BONOS ASC,
    EDAD DESC;

COMMIT;



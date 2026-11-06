-- =====================================================
-- Consultas de prueba (testers) - MySQL 8.0.16+
-- Ejecutar sobre la base cargada con vivero_completo.sql.
-- Cada consulta indica qué pregunta de negocio responde y sobre qué
-- período.
--
-- Períodos: los reportes se calculan sobre períodos cerrados relativos
-- al día en que se ejecutan (mes anterior, últimos 3 meses, últimos 30
-- días...). datos.sql carga las fechas también relativas a ese día, así
-- que siempre hay datos en esos períodos.
--   * Mes anterior:      fecha >  LAST_DAY(CURRENT_DATE - INTERVAL 2 MONTH)
--                        fecha <= LAST_DAY(CURRENT_DATE - INTERVAL 1 MONTH)
--   * Últimos 3 meses:   fecha >= CURRENT_DATE - INTERVAL 3 MONTH
-- Los filtros comparan la columna fecha contra un rango, sin aplicarle
-- funciones, para que MySQL pueda usar idx_venta_fecha / idx_compra_fecha.
--
-- El nombre de un producto está en su subtipo (planta o insumo), por eso
-- varias consultas hacen LEFT JOIN a ambas tablas y toman el que exista.
-- =====================================================

USE vivero;

-- -----------------------------------------------------
-- 1. Ranking de vendedores del mes anterior (el primero es el mejor
--    vendedor del mes): cantidad de ventas y facturación
-- -----------------------------------------------------
SELECT DATE_FORMAT(CURRENT_DATE - INTERVAL 1 MONTH, '%Y-%m') AS mes,
       CONCAT(ve.apellido, ', ', ve.nombre)                  AS vendedor,
       COUNT(v.id_venta)                                     AS cantidad_ventas,
       SUM(v.total_facturado)                                AS total_facturado
  FROM vendedor ve
  JOIN venta v ON v.id_vendedor = ve.id_vendedor
 WHERE v.fecha >  LAST_DAY(CURRENT_DATE - INTERVAL 2 MONTH)
   AND v.fecha <= LAST_DAY(CURRENT_DATE - INTERVAL 1 MONTH)
 GROUP BY ve.id_vendedor, ve.apellido, ve.nombre
 ORDER BY total_facturado DESC;

-- -----------------------------------------------------
-- 2. Top 5 productos más vendidos (por unidades) de los últimos 3 meses
-- -----------------------------------------------------
SELECT p.id_producto,
       COALESCE(pl.nombre, i.nombre) AS nombre,
       SUM(dv.cantidad)              AS unidades_vendidas,
       SUM(dv.subtotal)              AS facturado
  FROM venta v
  JOIN detalle_venta dv ON dv.id_venta    = v.id_venta
  JOIN producto p       ON p.id_producto  = dv.id_producto
  LEFT JOIN planta pl   ON pl.id_producto = p.id_producto
  LEFT JOIN insumo i    ON i.id_producto  = p.id_producto
 WHERE v.fecha >= CURRENT_DATE - INTERVAL 3 MONTH
 GROUP BY p.id_producto, pl.nombre, i.nombre
 ORDER BY unidades_vendidas DESC
 LIMIT 5;

-- -----------------------------------------------------
-- 3. Planta e insumo más facturados de los últimos 3 meses
--    Una consulta por tipo, cada una con su primer puesto (LIMIT 1).
-- -----------------------------------------------------
(SELECT 'planta'         AS tipo,
        pl.nombre        AS nombre,
        SUM(dv.subtotal) AS facturado
   FROM venta v
   JOIN detalle_venta dv ON dv.id_venta    = v.id_venta
   JOIN planta pl        ON pl.id_producto = dv.id_producto
  WHERE v.fecha >= CURRENT_DATE - INTERVAL 3 MONTH
  GROUP BY pl.id_planta, pl.nombre
  ORDER BY facturado DESC
  LIMIT 1)
UNION ALL
(SELECT 'insumo'         AS tipo,
        i.nombre         AS nombre,
        SUM(dv.subtotal) AS facturado
   FROM venta v
   JOIN detalle_venta dv ON dv.id_venta   = v.id_venta
   JOIN insumo i         ON i.id_producto = dv.id_producto
  WHERE v.fecha >= CURRENT_DATE - INTERVAL 3 MONTH
  GROUP BY i.id_insumo, i.nombre
  ORDER BY facturado DESC
  LIMIT 1);

-- -----------------------------------------------------
-- 4. Ventas mensuales de los últimos 6 meses (incluye el mes en curso):
--    cantidad de ventas, total y ticket promedio (RF-05)
-- -----------------------------------------------------
SELECT DATE_FORMAT(fecha, '%Y-%m')     AS mes,
       COUNT(*)                        AS cantidad_ventas,
       SUM(total_facturado)            AS total_facturado,
       ROUND(AVG(total_facturado), 2)  AS ticket_promedio
  FROM venta
 WHERE fecha > LAST_DAY(CURRENT_DATE - INTERVAL 6 MONTH)
 GROUP BY mes
 ORDER BY mes;

-- -----------------------------------------------------
-- 5. Facturación del mes anterior por forma de pago y su porcentaje
--    sobre el total de ese mes
-- -----------------------------------------------------
SELECT forma_de_pago,
       COUNT(*)             AS cantidad_ventas,
       SUM(total_facturado) AS total_facturado,
       ROUND(100 * SUM(total_facturado) /
             (SELECT SUM(total_facturado)
                FROM venta
               WHERE fecha >  LAST_DAY(CURRENT_DATE - INTERVAL 2 MONTH)
                 AND fecha <= LAST_DAY(CURRENT_DATE - INTERVAL 1 MONTH)), 2) AS porcentaje
  FROM venta
 WHERE fecha >  LAST_DAY(CURRENT_DATE - INTERVAL 2 MONTH)
   AND fecha <= LAST_DAY(CURRENT_DATE - INTERVAL 1 MONTH)
 GROUP BY forma_de_pago
 ORDER BY total_facturado DESC;

-- -----------------------------------------------------
-- 6. Top 3 clientes identificados de los últimos 3 meses por monto
--    comprado, y cuánto se vendió a consumidor final (cliente 1) en el
--    mismo período
-- -----------------------------------------------------
(SELECT CONCAT(c.apellido, ', ', c.nombre) AS cliente,
        COUNT(v.id_venta)                  AS cantidad_ventas,
        SUM(v.total_facturado)             AS total_comprado
   FROM cliente c
   JOIN venta v ON v.id_cliente = c.id_cliente
  WHERE c.id_cliente <> 1
    AND v.fecha >= CURRENT_DATE - INTERVAL 3 MONTH
  GROUP BY c.id_cliente, c.apellido, c.nombre
  ORDER BY total_comprado DESC
  LIMIT 3)
UNION ALL
(SELECT 'Consumidor final', COUNT(*), SUM(total_facturado)
   FROM venta
  WHERE id_cliente = 1
    AND fecha >= CURRENT_DATE - INTERVAL 3 MONTH);

-- -----------------------------------------------------
-- 7. Alerta de stock crítico: productos activos por debajo de su
--    stock mínimo, con cuánto falta para llegar al mínimo y cuánto se
--    vendió en los últimos 30 días, para priorizar la reposición (RF-05)
-- -----------------------------------------------------
SELECT p.id_producto,
       COALESCE(pl.nombre, i.nombre)            AS nombre,
       p.cantidad_stock,
       p.stock_minimo,
       p.stock_minimo - p.cantidad_stock        AS faltante,
       COALESCE(ult.unidades, 0)                AS vendido_ultimos_30_dias
  FROM producto p
  LEFT JOIN planta pl ON pl.id_producto = p.id_producto
  LEFT JOIN insumo i  ON i.id_producto  = p.id_producto
  LEFT JOIN (SELECT dv.id_producto, SUM(dv.cantidad) AS unidades
               FROM venta v
               JOIN detalle_venta dv ON dv.id_venta = v.id_venta
              WHERE v.fecha >= CURRENT_DATE - INTERVAL 30 DAY
              GROUP BY dv.id_producto) ult ON ult.id_producto = p.id_producto
 WHERE p.activo = TRUE
   AND p.cantidad_stock < p.stock_minimo
 ORDER BY vendido_ultimos_30_dias DESC, faltante DESC;

-- -----------------------------------------------------
-- 8. Margen por producto vendido en el mes anterior (precio cobrado vs.
--    precio de compra vigente)
-- -----------------------------------------------------
SELECT COALESCE(pl.nombre, i.nombre)                         AS nombre,
       SUM(dv.cantidad)                                      AS unidades,
       SUM(dv.subtotal)                                      AS facturado,
       SUM(dv.cantidad * p.precio_compra)                    AS costo,
       SUM(dv.subtotal) - SUM(dv.cantidad * p.precio_compra) AS margen,
       ROUND(100 * (SUM(dv.subtotal) - SUM(dv.cantidad * p.precio_compra))
                 / SUM(dv.subtotal), 2)                      AS margen_pct
  FROM venta v
  JOIN detalle_venta dv ON dv.id_venta    = v.id_venta
  JOIN producto p       ON p.id_producto  = dv.id_producto
  LEFT JOIN planta pl   ON pl.id_producto = p.id_producto
  LEFT JOIN insumo i    ON i.id_producto  = p.id_producto
 WHERE v.fecha >  LAST_DAY(CURRENT_DATE - INTERVAL 2 MONTH)
   AND v.fecha <= LAST_DAY(CURRENT_DATE - INTERVAL 1 MONTH)
 GROUP BY p.id_producto, pl.nombre, i.nombre
 ORDER BY margen DESC;

-- -----------------------------------------------------
-- 9. Compras a cada proveedor en los últimos 3 meses (los proveedores
--    sin compras en el período aparecen con 0)
-- -----------------------------------------------------
SELECT pr.nombre_empresa,
       pr.cuit,
       COUNT(c.id_compra)                 AS cantidad_compras,
       COALESCE(SUM(c.total_facturado), 0) AS total_comprado,
       MAX(c.fecha)                       AS ultima_compra
  FROM proveedor pr
  LEFT JOIN compra c ON c.id_proveedor = pr.id_proveedor
                    AND c.fecha >= CURRENT_DATE - INTERVAL 3 MONTH
 GROUP BY pr.id_proveedor, pr.nombre_empresa, pr.cuit
 ORDER BY total_comprado DESC;

-- -----------------------------------------------------
-- 10. Productos activos con stock que no se vendieron en los últimos
--     30 días (mercadería inmovilizada), con la fecha de su última venta
-- -----------------------------------------------------
SELECT p.id_producto,
       COALESCE(pl.nombre, i.nombre) AS nombre,
       p.cantidad_stock,
       (SELECT MAX(v.fecha)
          FROM venta v
          JOIN detalle_venta dv ON dv.id_venta = v.id_venta
         WHERE dv.id_producto = p.id_producto) AS ultima_venta
  FROM producto p
  LEFT JOIN planta pl ON pl.id_producto = p.id_producto
  LEFT JOIN insumo i  ON i.id_producto  = p.id_producto
 WHERE p.activo = TRUE
   AND p.cantidad_stock > 0
   AND NOT EXISTS (SELECT 1
                     FROM venta v
                     JOIN detalle_venta dv ON dv.id_venta = v.id_venta
                    WHERE dv.id_producto = p.id_producto
                      AND v.fecha >= CURRENT_DATE - INTERVAL 30 DAY)
 ORDER BY ultima_venta, nombre;

-- -----------------------------------------------------
-- 11. Detalle de una venta (como se imprimiría el ticket)
--     Se busca por número de venta, como al reimprimir un ticket.
-- -----------------------------------------------------
SELECT v.id_venta,
       v.fecha,
       CONCAT_WS(', ', c.apellido, c.nombre) AS cliente,
       CONCAT(ve.apellido, ', ', ve.nombre)  AS vendedor,
       COALESCE(pl.nombre, i.nombre)         AS producto,
       dv.cantidad,
       dv.precio_unitario,
       dv.subtotal,
       v.total_facturado
  FROM venta v
  JOIN cliente c        ON c.id_cliente   = v.id_cliente
  JOIN vendedor ve      ON ve.id_vendedor = v.id_vendedor
  JOIN detalle_venta dv ON dv.id_venta    = v.id_venta
  LEFT JOIN planta pl   ON pl.id_producto = dv.id_producto
  LEFT JOIN insumo i    ON i.id_producto  = dv.id_producto
 WHERE v.id_venta = 6;

-- -----------------------------------------------------
-- 12. Historial de compras de un cliente en los últimos 6 meses (RF-05)
-- -----------------------------------------------------
SELECT v.fecha,
       v.id_venta,
       COALESCE(pl.nombre, i.nombre) AS producto,
       dv.cantidad,
       dv.precio_unitario,
       dv.subtotal
  FROM venta v
  JOIN detalle_venta dv ON dv.id_venta    = v.id_venta
  LEFT JOIN planta pl   ON pl.id_producto = dv.id_producto
  LEFT JOIN insumo i    ON i.id_producto  = dv.id_producto
 WHERE v.id_cliente = 2
   AND v.fecha >= CURRENT_DATE - INTERVAL 6 MONTH
 ORDER BY v.fecha, v.id_venta;


-- =====================================================
-- PRUEBAS NEGATIVAS
-- Cada sentencia DEBE fallar: demuestra que una restricción o un
-- trigger impide cargar datos inválidos. Se indica el error esperado.
--
-- El cliente mysql corta en el primer error, así que esta sección se
-- ejecuta con:   mysql --force -u <usuario> -p < queries.sql
-- (en Workbench, ejecutar cada sentencia por separado).
-- Todo va dentro de una transacción que se deshace al final.
-- =====================================================

START TRANSACTION;

-- -----------------------------------------------------
-- P1. Registrar una compra con una fila de detalle_compra 
-- 	   (producto, cantidad y precio unitario).
--     Resultado esperado: El subtotal se calcula como  
-- 	   cantidad × precio_unitario. El stock del producto  
-- 	   aumenta en la cantidad comprada, su precio_compra
-- 	   pasa a ser el precio unitario y su precio_venta pasa
-- 	   a ser precio unitario × 1.40. El total_facturado 
-- 	   de la compra se recalcula.
-- -----------------------------------------------------
INSERT INTO compra (fecha, forma_de_pago, id_proveedor) VALUE (CURRENT_DATE(), 'efectivo', 3);
INSERT INTO detalle_compra (id_compra, id_producto, cantidad, precio_unitario) VALUE (LAST_INSERT_ID(), 14,  10,  4500.00);
    
    
-- -----------------------------------------------------
-- P2. Registrar una venta con dos filas de detalle_venta.
--     Resultado esperado: El precio_unitario de cada fila
-- 	   se toma del precio_venta del producto y el subtotal
-- 	   se calcula como cantidad × precio_unitario. El stock 
-- 	   de cada producto disminuye en la cantidad vendida 
-- 	   y el total_facturado de la venta es la suma de los 
-- 	   subtotales.
-- -----------------------------------------------------
INSERT INTO venta (fecha, forma_de_pago, id_cliente, id_vendedor) VALUE (CURRENT_DATE(), 'crédito', 4, 1);
SET @venta = LAST_INSERT_ID();
INSERT INTO detalle_venta (id_venta, id_producto, cantidad) VALUES 
			(@venta, 10, 10), (@venta, 16, 2);

-- -----------------------------------------------------
-- P3. Borrar una venta completa.
--     Resultado esperado: Se eliminan sus detalles (ON 
-- 	   DELETE CASCADE) y el stock vendido vuelve al 
-- 	   producto (trg_venta_bd).
-- -----------------------------------------------------
DELETE FROM venta WHERE id_venta = @venta;


-- -----------------------------------------------------
-- P4. Dar de baja un producto (activo = FALSE).
--     Resultado esperado: El producto permanece en la 
-- 	   base con su historial y deja de poder venderse.
-- -----------------------------------------------------
UPDATE producto SET activo = 0 WHERE id_producto = 14; 
INSERT INTO detalle_venta (id_venta, id_producto, cantidad)
	VALUE (16, 14, 1);


-- -----------------------------------------------------
-- N1. Vender más unidades que el stock disponible
--     Error esperado: 'Stock insuficiente para el producto' (trg_detalle_venta_bi)
-- -----------------------------------------------------
INSERT INTO detalle_venta (id_venta, id_producto, cantidad)
	VALUES (4, 5, 100);

-- -----------------------------------------------------
-- N2. Aumentar la cantidad de un detalle de venta por encima del stock
--     Error esperado: 'Stock insuficiente para el producto' (trg_detalle_venta_bu)
-- -----------------------------------------------------
UPDATE detalle_venta SET cantidad = 500 WHERE id_venta = 1 AND id_producto = 5;

-- -----------------------------------------------------
-- N3. Cambiar el producto de un detalle ya cargado
--     Error esperado: 'No se puede cambiar la venta ni el producto o su precio...' (trg_detalle_venta_bu)
-- -----------------------------------------------------
UPDATE detalle_venta SET id_producto = 2 WHERE id_venta = 4 AND id_producto = 1;

-- -----------------------------------------------------
-- N4. Vender un producto dado de baja
--     Error esperado: 'El producto está dado de baja' (trg_detalle_venta_bi)
-- -----------------------------------------------------
INSERT INTO detalle_venta (id_venta, id_producto, cantidad)
VALUES (4, 20, 1);

-- -----------------------------------------------------
-- N5. Repetir un producto dentro de la misma venta
--     Error esperado: 'Duplicate entry' en uq_dventa_venta_producto
-- -----------------------------------------------------
INSERT INTO detalle_venta (id_venta, id_producto, cantidad)
VALUES (4, 1, 1);

-- -----------------------------------------------------
-- N6. Anular un renglón de compra cuyo stock ya se vendió
--     (del limonero se compraron 6 y se vendieron 3: quedaría en -3)
--     Error esperado: CHECK 'chk_producto_stock' (trg_detalle_compra_ad)
-- -----------------------------------------------------
DELETE FROM detalle_compra WHERE id_compra = 2 AND id_producto = 5;

-- -----------------------------------------------------
-- N7. Anular la compra completa: mismo caso, por la cascada
--     Error esperado: CHECK 'chk_producto_stock' (trg_compra_bd)
-- -----------------------------------------------------
DELETE FROM compra WHERE id_compra = 2;

-- -----------------------------------------------------
-- N8. Cargar como planta un producto que ya es insumo
--     Error esperado: 'El producto ya está registrado como insumo' (trg_planta_bi)
-- -----------------------------------------------------
INSERT INTO planta (nombre, tipo_planta, nivel_de_luz, riego_cada_dias, id_producto)
VALUES ('Helecho', 'ornamental', 'bajo', 5, 11);

-- -----------------------------------------------------
-- N9. Dos plantas para el mismo producto
--     Error esperado: 'Duplicate entry' en la clave única de planta.id_producto
-- -----------------------------------------------------
INSERT INTO planta (nombre, tipo_planta, nivel_de_luz, riego_cada_dias, id_producto)
VALUES ('Echeveria rosa', 'suculenta', 'alto', 10, 1);

-- -----------------------------------------------------
-- N10. Categoría de planta fuera de las permitidas
--      Error esperado: 'Data truncated for column tipo_planta' (ENUM, modo estricto)
-- -----------------------------------------------------
UPDATE planta SET tipo_planta = 'helecho' WHERE id_planta = 1;

-- -----------------------------------------------------
-- N11. Riego fuera de rango
--      Error esperado: CHECK 'chk_planta_riego'
-- -----------------------------------------------------
UPDATE planta SET riego_cada_dias = 0 WHERE id_planta = 1;

-- -----------------------------------------------------
-- N12. Precio de venta negativo
--      Error esperado: CHECK 'chk_producto_precios'
-- -----------------------------------------------------
UPDATE producto SET precio_venta = -100 WHERE id_producto = 1;

-- -----------------------------------------------------
-- N13. Detalle de venta con cantidad 0
--      Error esperado: CHECK 'chk_dventa_cantidad'
-- -----------------------------------------------------
INSERT INTO detalle_venta (id_venta, id_producto, cantidad)
VALUES (4, 2, 0);

-- -----------------------------------------------------
-- N14. Forma de pago fuera de las permitidas
--      Error esperado: 'Data truncated for column forma_de_pago' (ENUM, modo estricto)
-- -----------------------------------------------------
INSERT INTO venta (forma_de_pago, id_cliente, id_vendedor)
VALUES ('cheque', 2, 1);

-- -----------------------------------------------------
-- N15. Venta con fecha futura
--      Error esperado: 'La fecha de la venta no puede ser posterior a hoy' (trg_venta_bi)
-- -----------------------------------------------------
INSERT INTO venta (fecha, forma_de_pago, id_cliente, id_vendedor)
VALUES (CURRENT_DATE + INTERVAL 1 DAY, 'efectivo', 2, 1);

-- -----------------------------------------------------
-- N16. Cliente con DNI repetido
--      Error esperado: 'Duplicate entry' en la clave única de dni
-- -----------------------------------------------------
INSERT INTO cliente (nombre, apellido, dni) VALUES ('Laura', 'Benítez', '32456789');

-- -----------------------------------------------------
-- N17. CUIT que no tiene 11 dígitos
--      Error esperado: CHECK 'chk_proveedor_cuit'
-- -----------------------------------------------------
INSERT INTO proveedor (nombre_empresa, cuit, telefono)
VALUES ('Vivero Sur', '3071234567', '1140005555');

-- -----------------------------------------------------
-- N18. Venta de un vendedor que no existe
--      Error esperado: FK 'fk_venta_vendedor'
-- -----------------------------------------------------
INSERT INTO venta (forma_de_pago, id_cliente, id_vendedor)
VALUES ('efectivo', 2, 99);

-- -----------------------------------------------------
-- N19. Borrar un cliente que tiene ventas
--      Error esperado: FK 'fk_venta_cliente' (ON DELETE RESTRICT)
-- -----------------------------------------------------
DELETE FROM cliente WHERE id_cliente = 2;

-- -----------------------------------------------------
-- N20. Borrar un producto con ventas y compras (se debe dar de baja con activo = FALSE)
--      Error esperado: FK 'fk_dcompra_producto' (ON DELETE RESTRICT). También lo
--      frenaría 'fk_dventa_producto'; MySQL informa la primera que encuentra.
-- -----------------------------------------------------
DELETE FROM producto WHERE id_producto = 1;

ROLLBACK;

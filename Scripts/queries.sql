-- =====================================================
-- Consultas de prueba (testers) - MySQL 8.0.16+
-- Ejecutar sobre la base cargada con vivero_completo.sql.
-- Cada consulta indica qué valida o qué pregunta de negocio responde.
--
-- El nombre de un producto está en su subtipo (planta o insumo), por eso
-- varias consultas hacen LEFT JOIN a ambas tablas y toman el que exista.
-- =====================================================

USE vivero;

-- -----------------------------------------------------
-- 1. Top 3 vendedores por facturación
-- -----------------------------------------------------
SELECT ve.id_vendedor,
       CONCAT(ve.apellido, ', ', ve.nombre) AS vendedor,
       COUNT(v.id_venta)                    AS cantidad_ventas,
       SUM(v.total_facturado)               AS total_facturado
  FROM vendedor ve
  JOIN venta v ON v.id_vendedor = ve.id_vendedor
 GROUP BY ve.id_vendedor, ve.apellido, ve.nombre
 ORDER BY total_facturado DESC
 LIMIT 3;

-- -----------------------------------------------------
-- 2. Top 3 productos más vendidos por unidades
-- -----------------------------------------------------
SELECT p.id_producto,
       COALESCE(pl.nombre, i.nombre) AS nombre,
       SUM(dv.cantidad)              AS unidades_vendidas,
       SUM(dv.subtotal)              AS facturado
  FROM producto p
  JOIN detalle_venta dv ON dv.id_producto = p.id_producto
  LEFT JOIN planta pl   ON pl.id_producto = p.id_producto
  LEFT JOIN insumo i    ON i.id_producto  = p.id_producto
 GROUP BY p.id_producto, pl.nombre, i.nombre
 ORDER BY unidades_vendidas DESC
 LIMIT 3;

-- -----------------------------------------------------
-- 3. Producto más facturado de cada tipo (planta, insumo)
--    Usa una función de ventana para rankear dentro de cada tipo.
-- -----------------------------------------------------
SELECT tipo, nombre, facturado
  FROM (SELECT CASE WHEN pl.id_planta IS NOT NULL THEN 'planta' ELSE 'insumo' END AS tipo,
               COALESCE(pl.nombre, i.nombre) AS nombre,
               SUM(dv.subtotal)              AS facturado
          FROM producto p
          JOIN detalle_venta dv ON dv.id_producto = p.id_producto
          LEFT JOIN planta pl   ON pl.id_producto = p.id_producto
          LEFT JOIN insumo i    ON i.id_producto  = p.id_producto
         GROUP BY p.id_producto, pl.id_planta, pl.nombre, i.nombre) ranking
 WHERE puesto = 1
 ORDER BY facturado DESC;

-- -----------------------------------------------------
-- 4. Ventas mensuales: cantidad de ventas, total y ticket promedio (RF-05)
-- -----------------------------------------------------
SELECT DATE_FORMAT(fecha, '%Y-%m')     AS mes,
       COUNT(*)                        AS cantidad_ventas,
       SUM(total_facturado)            AS total_facturado,
       ROUND(AVG(total_facturado), 2)  AS ticket_promedio
  FROM venta
 GROUP BY mes
 ORDER BY mes;

-- -----------------------------------------------------
-- 5. Facturación por forma de pago y su porcentaje sobre el total
-- -----------------------------------------------------
SELECT forma_de_pago,
       COUNT(*)             AS cantidad_ventas,
       SUM(total_facturado) AS total_facturado,
       ROUND(100 * SUM(total_facturado) / (SELECT SUM(total_facturado) FROM venta), 2) AS porcentaje
  FROM venta
 GROUP BY forma_de_pago
 ORDER BY total_facturado DESC;

-- -----------------------------------------------------
-- 6. Top 3 clientes identificados por monto comprado, y cuánto se
--    vendió a consumidor final (cliente 1)
-- -----------------------------------------------------
(SELECT CONCAT(c.apellido, ', ', c.nombre) AS cliente,
        COUNT(v.id_venta)                  AS cantidad_ventas,
        SUM(v.total_facturado)             AS total_comprado
   FROM cliente c
   JOIN venta v ON v.id_cliente = c.id_cliente
  WHERE c.id_cliente <> 1
  GROUP BY c.id_cliente, c.apellido, c.nombre
  ORDER BY total_comprado DESC
  LIMIT 3)
UNION ALL
(SELECT 'Consumidor final', COUNT(*), SUM(total_facturado)
   FROM venta
  WHERE id_cliente = 1);

-- -----------------------------------------------------
-- 7. Alerta de stock crítico: productos activos por debajo de su
--    stock mínimo, con cuánto falta para llegar al mínimo (RF-05)
-- -----------------------------------------------------
SELECT p.id_producto,
       COALESCE(pl.nombre, i.nombre)      AS nombre,
       p.cantidad_stock,
       p.stock_minimo,
       p.stock_minimo - p.cantidad_stock  AS faltante
  FROM producto p
  LEFT JOIN planta pl ON pl.id_producto = p.id_producto
  LEFT JOIN insumo i  ON i.id_producto  = p.id_producto
 WHERE p.activo = TRUE
   AND p.cantidad_stock < p.stock_minimo
 ORDER BY faltante DESC;

-- -----------------------------------------------------
-- 8. Margen por producto vendido (precio cobrado vs. precio de compra vigente)
-- -----------------------------------------------------
SELECT COALESCE(pl.nombre, i.nombre)                        AS nombre,
       SUM(dv.cantidad)                                     AS unidades,
       SUM(dv.subtotal)                                     AS facturado,
       SUM(dv.cantidad * p.precio_compra)                   AS costo,
       SUM(dv.subtotal) - SUM(dv.cantidad * p.precio_compra) AS margen,
       ROUND(100 * (SUM(dv.subtotal) - SUM(dv.cantidad * p.precio_compra))
                 / SUM(dv.subtotal), 2)                     AS margen_pct
  FROM producto p
  JOIN detalle_venta dv ON dv.id_producto = p.id_producto
  LEFT JOIN planta pl   ON pl.id_producto = p.id_producto
  LEFT JOIN insumo i    ON i.id_producto  = p.id_producto
 GROUP BY p.id_producto, pl.nombre, i.nombre
 ORDER BY margen DESC;

-- -----------------------------------------------------
-- 9. Compras por proveedor
-- -----------------------------------------------------
SELECT pr.nombre_empresa,
       pr.cuit,
       COUNT(c.id_compra)     AS cantidad_compras,
       SUM(c.total_facturado) AS total_comprado,
       MAX(c.fecha)           AS ultima_compra
  FROM proveedor pr
  LEFT JOIN compra c ON c.id_proveedor = pr.id_proveedor
 GROUP BY pr.id_proveedor, pr.nombre_empresa, pr.cuit
 ORDER BY total_comprado DESC;

-- -----------------------------------------------------
-- 10. Productos que nunca se vendieron
-- -----------------------------------------------------
SELECT p.id_producto,
       COALESCE(pl.nombre, i.nombre) AS nombre,
       p.cantidad_stock,
       p.activo
  FROM producto p
  LEFT JOIN planta pl ON pl.id_producto = p.id_producto
  LEFT JOIN insumo i  ON i.id_producto  = p.id_producto
 WHERE NOT EXISTS (SELECT 1 FROM detalle_venta dv WHERE dv.id_producto = p.id_producto)
 ORDER BY nombre;

-- -----------------------------------------------------
-- 11. Detalle de una venta (como se imprimiría el ticket)
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
 WHERE v.id_venta = 3;

-- -----------------------------------------------------
-- 12. Historial de compras de un cliente (RF-05)
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
-- N1. Vender más unidades que el stock disponible
--     Error esperado: 'Stock insuficiente para el producto' (trg_detalle_venta_bi)
-- -----------------------------------------------------
INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario)
VALUES (1, 5, 100, 22000.00);

-- -----------------------------------------------------
-- N2. Aumentar la cantidad de un detalle de venta por encima del stock
--     Error esperado: 'Stock insuficiente para el producto' (trg_detalle_venta_bu)
-- -----------------------------------------------------
UPDATE detalle_venta SET cantidad = 500 WHERE id_venta = 4 AND id_producto = 5;

-- -----------------------------------------------------
-- N3. Cambiar el producto de un detalle ya cargado
--     Error esperado: 'No se puede cambiar la venta ni el producto...' (trg_detalle_venta_bu)
-- -----------------------------------------------------
UPDATE detalle_venta SET id_producto = 2 WHERE id_venta = 1 AND id_producto = 1;

-- -----------------------------------------------------
-- N4. Vender un producto dado de baja
--     Error esperado: 'El producto está dado de baja' (trg_detalle_venta_bi)
-- -----------------------------------------------------
INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario)
VALUES (1, 20, 1, 1200.00);

-- -----------------------------------------------------
-- N5. Repetir un producto dentro de la misma venta
--     Error esperado: 'Duplicate entry' en uq_dventa_venta_producto
-- -----------------------------------------------------
INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario)
VALUES (1, 1, 1, 3500.00);

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
INSERT INTO detalle_venta (id_venta, id_producto, cantidad, precio_unitario)
VALUES (1, 2, 0, 4800.00);

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

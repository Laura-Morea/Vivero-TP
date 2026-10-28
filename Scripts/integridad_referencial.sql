-- =====================================================
-- Restricciones de integridad (MySQL 8.0.16+)
-- Ejecutar DESPUÉS de schema.sql.
--
-- Contiene, en este orden:
--   1. Restricciones de dominio (CHECK).
--   2. Claves foráneas.
--
-- Política de las claves foráneas:
--   * ON UPDATE CASCADE en todas: si cambia un id, se propaga.
--   * ON DELETE RESTRICT hacia las entidades con historial (cliente,
--     vendedor, proveedor, producto vendido o comprado): no se borran,
--     un producto se da de baja con producto.activo = FALSE.
--   * ON DELETE CASCADE de una venta/compra a sus detalles, y de un
--     producto a su planta o insumo.
--   * En MySQL las cascadas NO disparan triggers: por eso, al borrar una
--     venta o compra, trg_venta_bd / trg_compra_bd ajustan el stock antes
--     de que la cascada borre los detalles.
-- =====================================================

USE vivero;

-- =====================================================
-- 1. RESTRICCIONES DE DOMINIO
-- =====================================================

ALTER TABLE vendedor
    ADD CONSTRAINT chk_vendedor_dni      CHECK (dni REGEXP '^[0-9]+$'),
    ADD CONSTRAINT chk_vendedor_telefono CHECK (telefono REGEXP '^[+]?[0-9]+$'),
    ADD CONSTRAINT chk_vendedor_mail     CHECK (mail LIKE '%_@_%._%');

-- el dni admite letras: puede ser un pasaporte o un documento extranjero
ALTER TABLE cliente
    ADD CONSTRAINT chk_cliente_dni      CHECK (dni REGEXP '^[0-9A-Za-z]+$'),
    ADD CONSTRAINT chk_cliente_telefono CHECK (telefono REGEXP '^[+]?[0-9]+$');

ALTER TABLE proveedor
    ADD CONSTRAINT chk_proveedor_cuit     CHECK (cuit REGEXP '^[0-9]{11}$'),
    ADD CONSTRAINT chk_proveedor_telefono CHECK (telefono REGEXP '^[+]?[0-9]+$');

ALTER TABLE producto
    ADD CONSTRAINT chk_producto_stock   CHECK (cantidad_stock >= 0),
    ADD CONSTRAINT chk_producto_minimo  CHECK (stock_minimo >= 0),
    ADD CONSTRAINT chk_producto_precios CHECK (precio_compra >= 0 AND precio_venta >= 0);

ALTER TABLE planta
    ADD CONSTRAINT chk_planta_riego CHECK (riego_cada_dias BETWEEN 1 AND 365);

ALTER TABLE venta
    ADD CONSTRAINT chk_venta_total CHECK (total_facturado >= 0);

ALTER TABLE detalle_venta
    ADD CONSTRAINT chk_dventa_cantidad CHECK (cantidad > 0),
    ADD CONSTRAINT chk_dventa_precio   CHECK (precio_unitario >= 0);

ALTER TABLE compra
    ADD CONSTRAINT chk_compra_total CHECK (total_facturado >= 0);

ALTER TABLE detalle_compra
    ADD CONSTRAINT chk_dcompra_cantidad CHECK (cantidad > 0),
    ADD CONSTRAINT chk_dcompra_precio   CHECK (precio_unitario >= 0);

-- =====================================================
-- 2. CLAVES FORÁNEAS
-- =====================================================

-- -----------------------------------------------------
-- Subtipos de producto
-- -----------------------------------------------------

ALTER TABLE planta
    ADD CONSTRAINT fk_planta_producto
        FOREIGN KEY (id_producto) REFERENCES producto (id_producto)
        ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE insumo
    ADD CONSTRAINT fk_insumo_producto
        FOREIGN KEY (id_producto) REFERENCES producto (id_producto)
        ON DELETE CASCADE ON UPDATE CASCADE;

-- -----------------------------------------------------
-- Circuito de venta
-- -----------------------------------------------------

ALTER TABLE venta
    ADD CONSTRAINT fk_venta_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    ADD CONSTRAINT fk_venta_vendedor
        FOREIGN KEY (id_vendedor) REFERENCES vendedor (id_vendedor)
        ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE detalle_venta
    ADD CONSTRAINT fk_dventa_venta
        FOREIGN KEY (id_venta) REFERENCES venta (id_venta)
        ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_dventa_producto
        FOREIGN KEY (id_producto) REFERENCES producto (id_producto)
        ON DELETE RESTRICT ON UPDATE CASCADE;

-- -----------------------------------------------------
-- Circuito de reposición
-- -----------------------------------------------------

ALTER TABLE compra
    ADD CONSTRAINT fk_compra_proveedor
        FOREIGN KEY (id_proveedor) REFERENCES proveedor (id_proveedor)
        ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE detalle_compra
    ADD CONSTRAINT fk_dcompra_compra
        FOREIGN KEY (id_compra) REFERENCES compra (id_compra)
        ON DELETE CASCADE ON UPDATE CASCADE,
    ADD CONSTRAINT fk_dcompra_producto
        FOREIGN KEY (id_producto) REFERENCES producto (id_producto)
        ON DELETE RESTRICT ON UPDATE CASCADE;

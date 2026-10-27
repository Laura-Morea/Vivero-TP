-- =====================================================
-- Restricciones de integridad referencial (MySQL 8.0.16+)
-- Ejecutar DESPUÉS de schema.sql.
--
-- Política:
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

-- =====================================================
-- Restricciones de integridad referencial (MySQL 8.0.16+)
-- Ejecutar DESPUÉS de schema.sql.
--
-- Política: todas las FK son ON DELETE RESTRICT / ON UPDATE RESTRICT.
--   * No se puede borrar un registro que esté referenciado (un cliente con
--     ventas, un producto vendido, etc.).
--   * Los detalles no usan ON DELETE CASCADE porque en MySQL las cascadas
--     no disparan triggers y el stock no se revertiría. Para borrar una
--     venta o compra, primero se borran sus detalles.
--   * Las FK compuestas de planta/servicio no admiten CASCADE porque la
--     columna "tipo" tiene un CHECK.
-- =====================================================

USE vivero;

-- -----------------------------------------------------
-- Subtipos de producto
-- -----------------------------------------------------

ALTER TABLE planta
    ADD CONSTRAINT fk_planta_producto
        FOREIGN KEY (id_producto, tipo) REFERENCES producto (id_producto, tipo)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT fk_planta_tipo_planta
        FOREIGN KEY (id_tipo_planta) REFERENCES tipo_planta (id_tipo_planta)
        ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE servicio
    ADD CONSTRAINT fk_servicio_producto
        FOREIGN KEY (id_producto, tipo) REFERENCES producto (id_producto, tipo)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT fk_servicio_tipo_servicio
        FOREIGN KEY (id_tipo_servicio) REFERENCES tipo_servicio (id_tipo_servicio)
        ON DELETE RESTRICT ON UPDATE RESTRICT;

-- -----------------------------------------------------
-- Circuito de reposición
-- -----------------------------------------------------

ALTER TABLE compra
    ADD CONSTRAINT fk_compra_proveedor
        FOREIGN KEY (id_proveedor) REFERENCES proveedor (id_proveedor)
        ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE detalle_compra
    ADD CONSTRAINT fk_dcompra_compra
        FOREIGN KEY (id_compra) REFERENCES compra (id_compra)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT fk_dcompra_producto
        FOREIGN KEY (id_producto) REFERENCES producto (id_producto)
        ON DELETE RESTRICT ON UPDATE RESTRICT;

-- -----------------------------------------------------
-- Circuito de venta
-- -----------------------------------------------------

ALTER TABLE venta
    ADD CONSTRAINT fk_venta_cliente
        FOREIGN KEY (id_cliente) REFERENCES cliente (id_cliente)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT fk_venta_vendedor
        FOREIGN KEY (id_vendedor) REFERENCES vendedor (id_vendedor)
        ON DELETE RESTRICT ON UPDATE RESTRICT;

ALTER TABLE detalle_venta
    ADD CONSTRAINT fk_dventa_venta
        FOREIGN KEY (id_venta) REFERENCES venta (id_venta)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    ADD CONSTRAINT fk_dventa_producto
        FOREIGN KEY (id_producto) REFERENCES producto (id_producto)
        ON DELETE RESTRICT ON UPDATE RESTRICT;

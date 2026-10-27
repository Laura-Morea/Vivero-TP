-- =====================================================
-- Triggers del sistema de vivero (MySQL 8.0.16+)
-- Ejecutar DESPUÉS de integridad_referencial.sql.
--
-- Qué automatizan o validan:
--   * un producto es planta o insumo, nunca las dos cosas
--   * las fechas de venta y compra no pueden ser futuras
--   * subtotal de cada detalle (cantidad * precio_unitario)
--   * total_facturado de venta y de compra
--   * stock: las compras suman, las ventas restan
--   * no se vende sin stock ni un producto dado de baja
--   * borrar una venta o compra ajusta el stock (la cascada a los
--     detalles no dispara sus triggers)
--
-- DELIMITER es un comando del cliente mysql / Workbench. Si tu cliente
-- no lo soporta, ejecutá cada trigger por separado.
-- =====================================================

USE vivero;

DELIMITER $$

-- =====================================================
-- SUBTIPOS: un producto no puede ser planta e insumo a la vez
-- =====================================================

CREATE TRIGGER trg_planta_bi
BEFORE INSERT ON planta
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM insumo WHERE id_producto = NEW.id_producto) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El producto ya está registrado como insumo';
    END IF;
END$$

CREATE TRIGGER trg_planta_bu
BEFORE UPDATE ON planta
FOR EACH ROW
BEGIN
    IF NEW.id_producto <> OLD.id_producto
       AND EXISTS (SELECT 1 FROM insumo WHERE id_producto = NEW.id_producto) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El producto ya está registrado como insumo';
    END IF;
END$$

CREATE TRIGGER trg_insumo_bi
BEFORE INSERT ON insumo
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM planta WHERE id_producto = NEW.id_producto) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El producto ya está registrado como planta';
    END IF;
END$$

CREATE TRIGGER trg_insumo_bu
BEFORE UPDATE ON insumo
FOR EACH ROW
BEGIN
    IF NEW.id_producto <> OLD.id_producto
       AND EXISTS (SELECT 1 FROM planta WHERE id_producto = NEW.id_producto) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El producto ya está registrado como planta';
    END IF;
END$$

-- =====================================================
-- VENTA y COMPRA: fecha no futura y ajuste de stock al borrar
-- (un CHECK no puede usar CURRENT_DATE, por eso son triggers)
-- =====================================================

CREATE TRIGGER trg_venta_bi
BEFORE INSERT ON venta
FOR EACH ROW
BEGIN
    IF NEW.fecha > CURRENT_DATE THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La fecha de la venta no puede ser posterior a hoy';
    END IF;
END$$

CREATE TRIGGER trg_venta_bu
BEFORE UPDATE ON venta
FOR EACH ROW
BEGIN
    IF NEW.fecha > CURRENT_DATE THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La fecha de la venta no puede ser posterior a hoy';
    END IF;
END$$

CREATE TRIGGER trg_venta_bd
BEFORE DELETE ON venta
FOR EACH ROW
BEGIN
    -- devuelve al stock lo vendido; después la cascada borra los detalles
    UPDATE producto p
      JOIN detalle_venta dv ON dv.id_producto = p.id_producto
       SET p.cantidad_stock = p.cantidad_stock + dv.cantidad
     WHERE dv.id_venta = OLD.id_venta;
END$$

CREATE TRIGGER trg_compra_bi
BEFORE INSERT ON compra
FOR EACH ROW
BEGIN
    IF NEW.fecha > CURRENT_DATE THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La fecha de la compra no puede ser posterior a hoy';
    END IF;
END$$

CREATE TRIGGER trg_compra_bu
BEFORE UPDATE ON compra
FOR EACH ROW
BEGIN
    IF NEW.fecha > CURRENT_DATE THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La fecha de la compra no puede ser posterior a hoy';
    END IF;
END$$

CREATE TRIGGER trg_compra_bd
BEFORE DELETE ON compra
FOR EACH ROW
BEGIN
    -- descuenta lo que había sumado la compra; si ese stock ya se
    -- vendió, el CHECK chk_producto_stock frena el borrado
    UPDATE producto p
      JOIN detalle_compra dc ON dc.id_producto = p.id_producto
       SET p.cantidad_stock = p.cantidad_stock - dc.cantidad
     WHERE dc.id_compra = OLD.id_compra;
END$$

-- =====================================================
-- DETALLE_COMPRA
-- =====================================================

CREATE TRIGGER trg_detalle_compra_bi
BEFORE INSERT ON detalle_compra
FOR EACH ROW
BEGIN
    SET NEW.subtotal = NEW.cantidad * NEW.precio_unitario;
END$$

CREATE TRIGGER trg_detalle_compra_ai
AFTER INSERT ON detalle_compra
FOR EACH ROW
BEGIN
    -- suma stock y deja el precio de esta compra como último precio de compra
    UPDATE producto
       SET cantidad_stock = cantidad_stock + NEW.cantidad,
           precio_compra  = NEW.precio_unitario
     WHERE id_producto = NEW.id_producto;

    UPDATE compra
       SET total_facturado = (SELECT COALESCE(SUM(subtotal), 0)
                                FROM detalle_compra WHERE id_compra = NEW.id_compra)
     WHERE id_compra = NEW.id_compra;
END$$

CREATE TRIGGER trg_detalle_compra_bu
BEFORE UPDATE ON detalle_compra
FOR EACH ROW
BEGIN
    IF NEW.id_compra <> OLD.id_compra OR NEW.id_producto <> OLD.id_producto THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede cambiar la compra ni el producto de un detalle; borrá el detalle y creá uno nuevo';
    END IF;

    SET NEW.subtotal = NEW.cantidad * NEW.precio_unitario;
END$$

CREATE TRIGGER trg_detalle_compra_au
AFTER UPDATE ON detalle_compra
FOR EACH ROW
BEGIN
    -- ajusta el stock por la diferencia (si queda negativo, lo frena el CHECK de producto)
    -- y, si se corrigió el precio, lo toma como último precio de compra
    UPDATE producto
       SET cantidad_stock = cantidad_stock + (NEW.cantidad - OLD.cantidad),
           precio_compra  = NEW.precio_unitario
     WHERE id_producto = NEW.id_producto;

    UPDATE compra
       SET total_facturado = (SELECT COALESCE(SUM(subtotal), 0)
                                FROM detalle_compra WHERE id_compra = NEW.id_compra)
     WHERE id_compra = NEW.id_compra;
END$$

CREATE TRIGGER trg_detalle_compra_ad
AFTER DELETE ON detalle_compra
FOR EACH ROW
BEGIN
    -- revierte el stock que había sumado (si ya se vendió, lo frena el CHECK)
    UPDATE producto
       SET cantidad_stock = cantidad_stock - OLD.cantidad
     WHERE id_producto = OLD.id_producto;

    UPDATE compra
       SET total_facturado = (SELECT COALESCE(SUM(subtotal), 0)
                                FROM detalle_compra WHERE id_compra = OLD.id_compra)
     WHERE id_compra = OLD.id_compra;
END$$

-- =====================================================
-- DETALLE_VENTA
-- =====================================================

CREATE TRIGGER trg_detalle_venta_bi
BEFORE INSERT ON detalle_venta
FOR EACH ROW
BEGIN
    DECLARE v_stock  INT;
    DECLARE v_activo BOOLEAN;

    SELECT cantidad_stock, activo INTO v_stock, v_activo
      FROM producto WHERE id_producto = NEW.id_producto;

    IF NOT v_activo THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El producto está dado de baja';
    END IF;

    IF v_stock < NEW.cantidad THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stock insuficiente para el producto';
    END IF;

    SET NEW.subtotal = NEW.cantidad * NEW.precio_unitario;
END$$

CREATE TRIGGER trg_detalle_venta_ai
AFTER INSERT ON detalle_venta
FOR EACH ROW
BEGIN
    UPDATE producto
       SET cantidad_stock = cantidad_stock - NEW.cantidad
     WHERE id_producto = NEW.id_producto;

    UPDATE venta
       SET total_facturado = (SELECT COALESCE(SUM(subtotal), 0)
                                FROM detalle_venta WHERE id_venta = NEW.id_venta)
     WHERE id_venta = NEW.id_venta;
END$$

CREATE TRIGGER trg_detalle_venta_bu
BEFORE UPDATE ON detalle_venta
FOR EACH ROW
BEGIN
    DECLARE v_stock INT;

    IF NEW.id_venta <> OLD.id_venta OR NEW.id_producto <> OLD.id_producto THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede cambiar la venta ni el producto de un detalle; borrá el detalle y creá uno nuevo';
    END IF;

    SELECT cantidad_stock INTO v_stock
      FROM producto WHERE id_producto = NEW.id_producto;

    -- si aumenta la cantidad, tiene que alcanzar el stock para la diferencia
    IF NEW.cantidad > OLD.cantidad AND v_stock < (NEW.cantidad - OLD.cantidad) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stock insuficiente para el producto';
    END IF;

    SET NEW.subtotal = NEW.cantidad * NEW.precio_unitario;
END$$

CREATE TRIGGER trg_detalle_venta_au
AFTER UPDATE ON detalle_venta
FOR EACH ROW
BEGIN
    UPDATE producto
       SET cantidad_stock = cantidad_stock - (NEW.cantidad - OLD.cantidad)
     WHERE id_producto = NEW.id_producto;

    UPDATE venta
       SET total_facturado = (SELECT COALESCE(SUM(subtotal), 0)
                                FROM detalle_venta WHERE id_venta = NEW.id_venta)
     WHERE id_venta = NEW.id_venta;
END$$

CREATE TRIGGER trg_detalle_venta_ad
AFTER DELETE ON detalle_venta
FOR EACH ROW
BEGIN
    -- devuelve el stock al borrar el detalle
    UPDATE producto
       SET cantidad_stock = cantidad_stock + OLD.cantidad
     WHERE id_producto = OLD.id_producto;

    UPDATE venta
       SET total_facturado = (SELECT COALESCE(SUM(subtotal), 0)
                                FROM detalle_venta WHERE id_venta = OLD.id_venta)
     WHERE id_venta = OLD.id_venta;
END$$

DELIMITER ;

-- =====================================================
-- Triggers del sistema de vivero (MySQL 8.0.16+)
-- Ejecutar DESPUÉS de schema.sql.
--
-- Qué automatizan:
--   * subtotal de cada detalle (cantidad * precio_unitario)
--   * total de compra / total_facturado de venta
--   * stock: las compras suman, las ventas restan
--   * los servicios nunca tocan stock
--   * las compras de servicios se rechazan
--
-- Nota: en MySQL las cascadas de FK no disparan triggers, por eso las
-- FK de los detalles no tienen ON DELETE CASCADE. Para borrar una venta
-- o compra, primero se borran sus detalles.
--
-- DELIMITER es un comando del cliente mysql / Workbench. Si tu cliente
-- no lo soporta, ejecutá cada trigger por separado.
-- =====================================================

USE vivero;

DELIMITER $$

-- =====================================================
-- DETALLE_COMPRA
-- =====================================================

CREATE TRIGGER trg_detalle_compra_bi
BEFORE INSERT ON detalle_compra
FOR EACH ROW
BEGIN
    DECLARE v_tipo VARCHAR(10);

    SELECT tipo INTO v_tipo FROM producto WHERE id_producto = NEW.id_producto;

    IF v_tipo = 'servicio' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se pueden registrar compras de servicios';
    END IF;

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
       SET total = (SELECT COALESCE(SUM(subtotal), 0)
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
    UPDATE producto
       SET cantidad_stock = cantidad_stock + (NEW.cantidad - OLD.cantidad)
     WHERE id_producto = NEW.id_producto;

    UPDATE compra
       SET total = (SELECT COALESCE(SUM(subtotal), 0)
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
       SET total = (SELECT COALESCE(SUM(subtotal), 0)
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
    DECLARE v_tipo  VARCHAR(10);
    DECLARE v_stock INT;

    SELECT tipo, cantidad_stock INTO v_tipo, v_stock
      FROM producto WHERE id_producto = NEW.id_producto;

    -- los servicios no tienen stock (v_stock es NULL), solo se valida el resto
    IF v_tipo <> 'servicio' AND v_stock < NEW.cantidad THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stock insuficiente para el producto';
    END IF;

    SET NEW.subtotal = NEW.cantidad * NEW.precio_unitario;
END$$

CREATE TRIGGER trg_detalle_venta_ai
AFTER INSERT ON detalle_venta
FOR EACH ROW
BEGIN
    -- el WHERE excluye servicios: no tienen stock que descontar
    UPDATE producto
       SET cantidad_stock = cantidad_stock - NEW.cantidad
     WHERE id_producto = NEW.id_producto
       AND tipo <> 'servicio';

    UPDATE venta
       SET total_facturado = (SELECT COALESCE(SUM(subtotal), 0)
                                FROM detalle_venta WHERE id_venta = NEW.id_venta)
     WHERE id_venta = NEW.id_venta;
END$$

CREATE TRIGGER trg_detalle_venta_bu
BEFORE UPDATE ON detalle_venta
FOR EACH ROW
BEGIN
    DECLARE v_tipo  VARCHAR(10);
    DECLARE v_stock INT;

    IF NEW.id_venta <> OLD.id_venta OR NEW.id_producto <> OLD.id_producto THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede cambiar la venta ni el producto de un detalle; borrá el detalle y creá uno nuevo';
    END IF;

    SELECT tipo, cantidad_stock INTO v_tipo, v_stock
      FROM producto WHERE id_producto = NEW.id_producto;

    -- si aumenta la cantidad, tiene que alcanzar el stock para la diferencia
    IF v_tipo <> 'servicio' AND NEW.cantidad > OLD.cantidad
       AND v_stock < (NEW.cantidad - OLD.cantidad) THEN
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
     WHERE id_producto = NEW.id_producto
       AND tipo <> 'servicio';

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
     WHERE id_producto = OLD.id_producto
       AND tipo <> 'servicio';

    UPDATE venta
       SET total_facturado = (SELECT COALESCE(SUM(subtotal), 0)
                                FROM detalle_venta WHERE id_venta = OLD.id_venta)
     WHERE id_venta = OLD.id_venta;
END$$

DELIMITER ;

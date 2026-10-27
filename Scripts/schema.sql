-- =====================================================
-- Sistema de gestión de vivero - Schema (MySQL 8.0.16+)
-- Basado en DER_Vivero.drawio y EER_tablas_Vivero.drawio.
-- "producto" es el supertipo; "planta" e "insumo" son sus subtipos
-- (una tabla por subtipo, cada una con su PK y una FK única a producto).
--
-- Este archivo define las tablas con sus restricciones de dominio y de
-- entidad (PK, NOT NULL, DEFAULT, UNIQUE, CHECK). Las claves foráneas
-- están en integridad_referencial.sql y se ejecutan después.
-- =====================================================

DROP DATABASE IF EXISTS vivero;
CREATE DATABASE vivero CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE vivero;

-- -----------------------------------------------------
-- Personas y proveedores
-- -----------------------------------------------------

CREATE TABLE vendedor (
    id_vendedor INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(50)  NOT NULL,
    apellido    VARCHAR(50)  NOT NULL,
    dni         VARCHAR(12)  NOT NULL UNIQUE,
    telefono    VARCHAR(15)  NOT NULL,
    mail        VARCHAR(100) NULL,
    direccion   VARCHAR(100) NULL,
    CONSTRAINT chk_vendedor_dni      CHECK (dni REGEXP '^[0-9]+$'),
    CONSTRAINT chk_vendedor_telefono CHECK (telefono REGEXP '^[+]?[0-9]+$'),
    CONSTRAINT chk_vendedor_mail     CHECK (mail LIKE '%_@_%._%')
);

-- Todos los datos son opcionales: el cliente puede no querer darlos.
-- El "consumidor final" es una fila más de esta tabla (ver datos.sql).
CREATE TABLE cliente (
    id_cliente  INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(50) NULL,
    apellido    VARCHAR(50) NULL,
    dni         VARCHAR(12) NULL UNIQUE,
    telefono    VARCHAR(15) NULL,
    -- admite letras: puede ser un pasaporte o un documento extranjero
    CONSTRAINT chk_cliente_dni      CHECK (dni REGEXP '^[0-9A-Za-z]+$'),
    CONSTRAINT chk_cliente_telefono CHECK (telefono REGEXP '^[+]?[0-9]+$')
);

CREATE TABLE proveedor (
    id_proveedor   INT AUTO_INCREMENT PRIMARY KEY,
    nombre_empresa VARCHAR(100) NOT NULL,
    cuit           VARCHAR(11)  NOT NULL UNIQUE,      -- 11 dígitos, sin guiones
    telefono       VARCHAR(15)  NOT NULL,
    CONSTRAINT chk_proveedor_cuit     CHECK (cuit REGEXP '^[0-9]{11}$'),
    CONSTRAINT chk_proveedor_telefono CHECK (telefono REGEXP '^[+]?[0-9]+$')
);

-- -----------------------------------------------------
-- Producto (supertipo): stock y precios de cada artículo
-- -----------------------------------------------------

CREATE TABLE producto (
    id_producto    INT AUTO_INCREMENT PRIMARY KEY,
    cantidad_stock INT           NOT NULL DEFAULT 0,  -- lo actualizan los triggers
    stock_minimo   INT           NOT NULL DEFAULT 0,  -- por debajo de este valor hay que reponer
    precio_compra  DECIMAL(10,2) NOT NULL,            -- precio de la última compra
    precio_venta   DECIMAL(10,2) NOT NULL,
    activo         BOOLEAN       NOT NULL DEFAULT TRUE, -- baja lógica: FALSE = no se vende más
    CONSTRAINT chk_producto_stock   CHECK (cantidad_stock >= 0),
    CONSTRAINT chk_producto_minimo  CHECK (stock_minimo >= 0),
    CONSTRAINT chk_producto_precios CHECK (precio_compra >= 0 AND precio_venta >= 0)
);

-- -----------------------------------------------------
-- Subtipos de producto
-- id_producto es UNIQUE: cada producto tiene a lo sumo una planta o un
-- insumo (relación 1:1). Que no esté en las dos tablas a la vez lo
-- controlan los triggers trg_planta_bi / trg_insumo_bi.
-- -----------------------------------------------------

CREATE TABLE planta (
    id_planta       INT AUTO_INCREMENT PRIMARY KEY,
    nombre          VARCHAR(50)  NOT NULL,
    tipo_planta     ENUM('suculenta', 'cactus', 'aromática', 'frutal',
                         'ornamental', 'arbusto', 'árbol', 'flor de estación') NOT NULL,
    de_interior     BOOLEAN      NOT NULL DEFAULT FALSE,
    descripcion     VARCHAR(100) NULL,
    nivel_de_luz    ENUM('bajo', 'medio', 'alto') NOT NULL,
    riego_cada_dias SMALLINT     NOT NULL,
    id_producto     INT          NOT NULL UNIQUE,
    CONSTRAINT chk_planta_riego CHECK (riego_cada_dias BETWEEN 1 AND 365)
);

CREATE TABLE insumo (
    id_insumo   INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(50)  NOT NULL,
    descripcion VARCHAR(100) NULL,
    id_producto INT          NOT NULL UNIQUE
);

-- -----------------------------------------------------
-- Circuito de venta
-- -----------------------------------------------------

CREATE TABLE venta (
    id_venta        INT AUTO_INCREMENT PRIMARY KEY,
    fecha           DATE NOT NULL DEFAULT (CURRENT_DATE), -- no puede ser futura: trg_venta_bi/bu
    forma_de_pago   ENUM('efectivo', 'débito', 'crédito', 'transferencia') NOT NULL,
    total_facturado DECIMAL(10,2) NOT NULL DEFAULT 0,     -- derivado: suma de subtotales (trigger)
    id_cliente      INT NOT NULL,                         -- relación "recibe"
    id_vendedor     INT NOT NULL,                         -- relación "realiza"
    CONSTRAINT chk_venta_total CHECK (total_facturado >= 0)
);

-- Relación N:M venta - producto
CREATE TABLE detalle_venta (
    id_detalle_venta INT AUTO_INCREMENT PRIMARY KEY,
    id_venta         INT NOT NULL,
    id_producto      INT NOT NULL,
    cantidad         INT NOT NULL,
    precio_unitario  DECIMAL(10,2) NOT NULL,              -- precio cobrado en esta venta
    subtotal         DECIMAL(10,2) NOT NULL DEFAULT 0,    -- derivado: cantidad * precio_unitario (trigger)
    -- un producto aparece una sola vez por venta (más unidades = más cantidad)
    UNIQUE KEY uq_dventa_venta_producto (id_venta, id_producto),
    CONSTRAINT chk_dventa_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_dventa_precio   CHECK (precio_unitario >= 0)
);

-- -----------------------------------------------------
-- Circuito de reposición
-- -----------------------------------------------------

CREATE TABLE compra (
    id_compra       INT AUTO_INCREMENT PRIMARY KEY,
    fecha           DATE NOT NULL DEFAULT (CURRENT_DATE), -- no puede ser futura: trg_compra_bi/bu
    forma_de_pago   ENUM('efectivo', 'débito', 'crédito', 'transferencia') NOT NULL,
    total_facturado DECIMAL(10,2) NOT NULL DEFAULT 0,     -- derivado: suma de subtotales (trigger)
    id_proveedor    INT NOT NULL,                         -- relación "provee"
    CONSTRAINT chk_compra_total CHECK (total_facturado >= 0)
);

-- Relación N:M compra - producto
CREATE TABLE detalle_compra (
    id_detalle_compra INT AUTO_INCREMENT PRIMARY KEY,
    id_compra         INT NOT NULL,
    id_producto       INT NOT NULL,
    cantidad          INT NOT NULL,
    precio_unitario   DECIMAL(10,2) NOT NULL,             -- precio pagado en esta compra
    subtotal          DECIMAL(10,2) NOT NULL DEFAULT 0,   -- derivado: cantidad * precio_unitario (trigger)
    UNIQUE KEY uq_dcompra_compra_producto (id_compra, id_producto),
    CONSTRAINT chk_dcompra_cantidad CHECK (cantidad > 0),
    CONSTRAINT chk_dcompra_precio   CHECK (precio_unitario >= 0)
);

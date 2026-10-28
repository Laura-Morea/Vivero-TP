-- =====================================================
-- Sistema de gestión de vivero - Schema (MySQL 8.0.16+)
-- Basado en DER_Vivero.drawio y EER_tablas_Vivero.drawio.
-- "producto" es el supertipo; "planta" e "insumo" son sus subtipos
-- (una tabla por subtipo, cada una con su PK y una FK única a producto).
--
-- Este archivo define las tablas con sus columnas, tipos, PK, NOT NULL,
-- DEFAULT y UNIQUE. Las restricciones con nombre (CHECK y claves
-- foráneas) están en integridad_referencial.sql y se ejecutan después.
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
    mail        VARCHAR(100),
    direccion   VARCHAR(100)
);

-- Todos los datos son opcionales: el cliente puede no querer darlos.
-- El "consumidor final" es una fila más de esta tabla (ver datos.sql).
CREATE TABLE cliente (
    id_cliente  INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(50),
    apellido    VARCHAR(50),
    dni         VARCHAR(12) UNIQUE,
    telefono    VARCHAR(15)
);

CREATE TABLE proveedor (
    id_proveedor   INT AUTO_INCREMENT PRIMARY KEY,
    nombre_empresa VARCHAR(100) NOT NULL,
    cuit           VARCHAR(11)  NOT NULL UNIQUE,      -- 11 dígitos, sin guiones
    telefono       VARCHAR(15)  NOT NULL
);

-- -----------------------------------------------------
-- Producto (supertipo): stock y precios de cada artículo
-- -----------------------------------------------------

CREATE TABLE producto (
    id_producto    INT AUTO_INCREMENT PRIMARY KEY,
    cantidad_stock INT           NOT NULL DEFAULT 0,  -- lo actualizan los triggers
    stock_minimo   INT           NOT NULL DEFAULT 0,  -- por debajo de este valor hay que reponer
    precio_compra  DECIMAL(10,2),                     -- precio de la última compra; NULL = todavía sin compras
    precio_venta   DECIMAL(10,2) NOT NULL,
    activo         BOOLEAN       NOT NULL DEFAULT TRUE -- baja lógica: FALSE = no se vende más
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
    descripcion     VARCHAR(100),
    nivel_de_luz    ENUM('bajo', 'medio', 'alto') NOT NULL,
    riego_cada_dias SMALLINT     NOT NULL,
    id_producto     INT          NOT NULL UNIQUE
);

CREATE TABLE insumo (
    id_insumo   INT AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(50)  NOT NULL,
    descripcion VARCHAR(100),
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
    id_vendedor     INT NOT NULL                          -- relación "realiza"
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
    UNIQUE KEY uq_dventa_venta_producto (id_venta, id_producto)
);

-- -----------------------------------------------------
-- Circuito de reposición
-- -----------------------------------------------------

CREATE TABLE compra (
    id_compra       INT AUTO_INCREMENT PRIMARY KEY,
    fecha           DATE NOT NULL DEFAULT (CURRENT_DATE), -- no puede ser futura: trg_compra_bi/bu
    forma_de_pago   ENUM('efectivo', 'débito', 'crédito', 'transferencia') NOT NULL,
    total_facturado DECIMAL(10,2) NOT NULL DEFAULT 0,     -- derivado: suma de subtotales (trigger)
    id_proveedor    INT NOT NULL                          -- relación "provee"
);

-- Relación N:M compra - producto
CREATE TABLE detalle_compra (
    id_detalle_compra INT AUTO_INCREMENT PRIMARY KEY,
    id_compra         INT NOT NULL,
    id_producto       INT NOT NULL,
    cantidad          INT NOT NULL,
    precio_unitario   DECIMAL(10,2) NOT NULL,             -- precio pagado en esta compra
    subtotal          DECIMAL(10,2) NOT NULL DEFAULT 0,   -- derivado: cantidad * precio_unitario (trigger)
    UNIQUE KEY uq_dcompra_compra_producto (id_compra, id_producto)
);

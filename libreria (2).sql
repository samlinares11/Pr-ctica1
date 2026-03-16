-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1:3307
-- Tiempo de generación: 16-03-2026 a las 17:12:55
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `libreria`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `actualizar_datos_socio` (IN `p_soc_numero` INT, IN `p_nueva_direccion` VARCHAR(255), IN `p_nuevo_telefono` VARCHAR(10))   BEGIN
	UPDATE socio
    SET soc_direccion = p_nueva_direccion,
    	soc_telefono = p_nuevo_telefono
    WHERE soc_numero = p_soc_numero;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `buscar_libro_xnombre` (IN `nombreLibro` VARCHAR(255))   SELECT * 
FROM libro
WHERE lib_titulo=nombreLibro$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `eliminar_libro_seguro` (IN `p_isbn` BIGINT(20))   BEGIN
    DECLARE total_dependencias INT DEFAULT 0;

    -- Contamos registros en las tablas que dependen del libro
    SELECT (
        (SELECT COUNT(*) FROM prestamo WHERE lib_copiaISBN = p_isbn) +
        (SELECT COUNT(*) FROM tipoautores WHERE copia_ISBN = p_isbn)
    ) INTO total_dependencias;

    -- Lógica de seguridad
    IF total_dependencias = 0 THEN
        DELETE FROM libro WHERE lib_isbn = p_isbn;
        SELECT CONCAT('Éxito: El libro con ISBN ', p_isbn, ' ha sido eliminado.') AS Mensaje;
    ELSE
        SELECT CONCAT('Error: No se puede eliminar. El libro tiene ', total_dependencias, ' registros asociados.') AS Mensaje;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_listaAutores` ()   SELECT aut_codigo, aut_apellido
FROM autor
ORDER BY aut_apellido DESC$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_tipoAutor` (`variable` VARCHAR(20))   SELECT aut_apellido AS 'AUTOR', tipoAutor 
FROM autor 
INNER JOIN tipoautores 
ON aut_codigo=copia_autor 
WHERE tipoAutor=variable$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `insert_libro` (`c1_isbn` BIGINT(20), `c2_titulo` VARCHAR(255), `c3_genero` VARCHAR(20), `c4_paginas` INT(11), `c5_diaspres` TINYINT(4))   INSERT INTO libro (lib_isbn, lib_titulo, lib_genero, lib_numeroPaginas, lib_diaPrestamo)
VALUES (c1_isbn, c2_titulo, c3_genero, c4_paginas, c5_diaspres)$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `insert_socio` (`s1_numero` INT(11), `s2_nombre` VARCHAR(45), `s3_apellido` VARCHAR(45), `s4_direccion` VARCHAR(255), `s5_telefono` VARCHAR(10))   INSERT INTO socio(soc_numero,soc_nombre,soc_apellido,soc_direccion,soc_telefono) 
VALUES (s1_numero,s2_nombre,s3_apellido, s4_direccion,s5_telefono)$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `listar_libros_en_prestamo` ()   BEGIN
	SELECT 
    l.lib_titulo AS 'Título del Libro',
    s.soc_nombre AS 'Nombre del Socio',
    s.soc_apellido AS 'Apellido del Socio',
    p.pres_fechaPrestamo AS 'Fecha de Préstamo'
    FROM libro l 
    INNER JOIN prestamo p ON l.lib_isbn=p.lib_copiaISBN
    INNER JOIN socio s ON p.soc_copiaNumero=s.soc_numero;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `lista_socios_prestamos` ()   BEGIN
	SELECT 
    	s.soc_numero,
        s.soc_nombre,
        s.soc_apellido,
        p.pres_id,
        p.pres_fechaPrestamo
    FROM socio s 
    LEFT JOIN prestamo p ON s.soc_numero=p.soc_copiaNumero;
END$$

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `dias_prestamo_libro` (`p_isbn` BIGINT(20)) RETURNS INT(11) DETERMINISTIC BEGIN
    DECLARE dias INT DEFAULT 0;
    
    -- La consulta debe ser una sola instrucción fluida hasta el punto y coma
    SELECT DATEDIFF(pres_fechaDevolucion, pres_fechaPrestamo) INTO dias 
    FROM prestamo 
    WHERE lib_copiaISBN = p_isbn
    ORDER BY pres_fechaPrestamo DESC
    LIMIT 1;
    
    -- Validamos si el libro aún no ha sido devuelto (NULL)
    IF dias IS NULL THEN
        SET dias = 0;
    END IF;

    RETURN dias;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `total_socios_registrados` () RETURNS INT(11) DETERMINISTIC BEGIN
	DECLARE total INT;
    SELECT COUNT(*) INTO total FROM socio;
    RETURN total;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auditoria_autor`
--

CREATE TABLE `auditoria_autor` (
  `id_auditoria` int(11) NOT NULL,
  `aud_aut_codigo` int(11) DEFAULT NULL,
  `accion` varchar(10) DEFAULT 'UPDATE',
  `antiguo_apellido` varchar(45) DEFAULT NULL,
  `nuevo_apellido` varchar(45) DEFAULT NULL,
  `antigua_muerte` date DEFAULT NULL,
  `nueva_muerte` date DEFAULT NULL,
  `fecha_modificacion` datetime DEFAULT NULL,
  `usuario` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auditoria_libro`
--

CREATE TABLE `auditoria_libro` (
  `aud_id` int(11) NOT NULL,
  `aud_lib_isbn` bigint(20) DEFAULT NULL,
  `aud_lib_titulo` varchar(255) DEFAULT NULL,
  `usuario` varchar(100) DEFAULT NULL,
  `aud_fecha_registro` datetime DEFAULT NULL,
  `accion` varchar(50) DEFAULT 'INSERT'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `auditoria_libro`
--

INSERT INTO `auditoria_libro` (`aud_id`, `aud_lib_isbn`, `aud_lib_titulo`, `usuario`, `aud_fecha_registro`, `accion`) VALUES
(1, 4444444444, 'La Divina Comedia', 'root@localhost', '2026-03-16 10:12:52', 'INSERT'),
(2, 4444444444, 'Cambio de: La Divina Comedia a: La Divina Comedia', 'root@localhost', '2026-03-16 10:20:05', 'UPDATE'),
(3, 4444444444, 'La Divina Comedia', 'root@localhost', '2026-03-16 10:33:10', 'DELETE');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `auditoria_socio`
--

CREATE TABLE `auditoria_socio` (
  `id_auditoria` int(11) NOT NULL,
  `soc_numero` int(11) DEFAULT NULL,
  `accion` varchar(10) DEFAULT NULL,
  `antiguo_nombre` varchar(255) DEFAULT NULL,
  `nuevo_nombre` varchar(255) DEFAULT NULL,
  `antiguo_apellido` varchar(255) DEFAULT NULL,
  `nuevo_apellido` varchar(255) DEFAULT NULL,
  `antigua_direccion` varchar(255) DEFAULT NULL,
  `nueva_direccion` varchar(255) DEFAULT NULL,
  `antiguo_telefono` varchar(255) DEFAULT NULL,
  `nuevo_telefono` varchar(255) DEFAULT NULL,
  `fecha_modificacion` datetime DEFAULT NULL,
  `usuario` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `auditoria_socio`
--

INSERT INTO `auditoria_socio` (`id_auditoria`, `soc_numero`, `accion`, `antiguo_nombre`, `nuevo_nombre`, `antiguo_apellido`, `nuevo_apellido`, `antigua_direccion`, `nueva_direccion`, `antiguo_telefono`, `nuevo_telefono`, `fecha_modificacion`, `usuario`) VALUES
(1, 1, 'UPDATE', 'Ana', 'Anabel Antonia', 'Ruiz', 'Alderete Ruiz', 'Calle Primavera 123, Ciudad Jardín, Barcelona', 'Calle Primavera 321, Ciudad Hermosa, Barcelona', '9123456780', '3333333333', '2026-03-16 08:01:35', 'root@localhost'),
(2, 13, 'DELETE', 'Lorenzo', NULL, 'Millán', NULL, 'Calle Falsa 123, Mallorca', NULL, '1234567891', NULL, '2026-03-16 09:12:39', 'root@localhost');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `autor`
--

CREATE TABLE `autor` (
  `aut_codigo` int(11) NOT NULL,
  `aut_apellido` varchar(45) NOT NULL,
  `aut_nacimiento` date NOT NULL,
  `aut_muerte` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `autor`
--

INSERT INTO `autor` (`aut_codigo`, `aut_apellido`, `aut_nacimiento`, `aut_muerte`) VALUES
(98, 'Smith', '1974-12-21', '2018-07-21'),
(123, 'Taylor', '1980-04-15', '0000-00-00'),
(234, 'Medina', '1977-06-21', '2005-09-12'),
(345, 'Wilson', '1975-08-29', '0000-00-00'),
(432, 'Miller', '1981-10-26', '0000-00-00'),
(456, 'Garcia', '1978-09-27', '2021-12-09'),
(567, 'Davis', '1983-03-04', '2010-03-28'),
(678, 'Silva', '1986-02-02', '0000-00-00'),
(765, 'López', '1976-07-08', '2020-07-15'),
(789, 'Rodriguez', '1985-12-10', '0000-00-00'),
(890, 'Brown', '1982-11-17', '0000-00-00'),
(901, 'Soto', '1979-05-13', '2015-11-05');

--
-- Disparadores `autor`
--
DELIMITER $$
CREATE TRIGGER `trg_auditoria_autor_update` AFTER UPDATE ON `autor` FOR EACH ROW BEGIN
    INSERT INTO auditoria_autor (
        aud_aut_codigo,       
        accion, 
        antiguo_apellido, 
        nuevo_apellido, 
        antigua_muerte, 
        nueva_muerte, 
        fecha_modificacion, 
        usuario
    ) VALUES (
        OLD.aut_codigo, 
        'UPDATE', 
        OLD.aut_apellido, 
        NEW.aut_apellido, 
        OLD.aut_muerte, 
        NEW.aut_muerte, 
        NOW(), 
        CURRENT_USER()
    );
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `libro`
--

CREATE TABLE `libro` (
  `lib_isbn` bigint(20) NOT NULL,
  `lib_titulo` varchar(255) NOT NULL,
  `lib_genero` varchar(20) NOT NULL,
  `lib_numeroPaginas` int(11) NOT NULL,
  `lib_diaPrestamo` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `libro`
--

INSERT INTO `libro` (`lib_isbn`, `lib_titulo`, `lib_genero`, `lib_numeroPaginas`, `lib_diaPrestamo`) VALUES
(1234567890, 'El Sueño de los Susurros', 'novela', 275, 7),
(1357924680, 'El Jardín de las Mariposas Perdidas', 'novela', 536, 7),
(2468135790, 'La Melodía de la Oscuridad', 'romance', 189, 7),
(2718281828, 'El Bosque de los Suspiros', 'novela', 387, 2),
(3141592653, 'El Secreto de las Estrellas Olvidadas', 'Misterio', 203, 7),
(5555555555, 'La Última Llave del Destino', 'cuento', 503, 7),
(7777777777, 'El Misterio de la Luna Plateada', 'Misterio', 422, 7),
(8642097531, 'El Reloj de Arena Infinito', 'novela', 321, 7),
(8888888888, 'La Ciudad de los Susurros', 'Misterio', 274, 1),
(9517530862, 'Las Crónicas del Eco Silencioso', 'fantasia', 448, 7),
(9876543210, 'El Laberinto de los Recuerdos', 'cuento', 412, 7),
(9999999999, 'El Enigma de los Espejos Rotos', 'romance', 156, 7),
(9788426721006, 'sql', 'ingeniería', 384, 15);

--
-- Disparadores `libro`
--
DELIMITER $$
CREATE TRIGGER `tr_auditoria_delete_libro` AFTER DELETE ON `libro` FOR EACH ROW BEGIN
    INSERT INTO auditoria_libro (
        aud_lib_isbn, 
        aud_lib_titulo, 
        usuario, 
        aud_fecha_registro,
        accion
    )
    VALUES (
        OLD.lib_isbn, 
        OLD.lib_titulo, 
        USER(), 
        NOW(),
        'DELETE'
    );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tr_auditoria_insert_libro` AFTER INSERT ON `libro` FOR EACH ROW BEGIN
    INSERT INTO auditoria_libro (
        aud_lib_isbn, 
        aud_lib_titulo, 
        usuario, 
        aud_fecha_registro -- Aquí estaba el error, faltaba el prefijo 'aud_'
    )
    VALUES (
        NEW.lib_isbn, 
        NEW.lib_titulo, 
        USER(), 
        NOW()
    );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `tr_auditoria_update_libro` AFTER UPDATE ON `libro` FOR EACH ROW BEGIN
    INSERT INTO auditoria_libro (
        aud_lib_isbn, 
        aud_lib_titulo, 
        usuario, 
        aud_fecha_registro,
        accion
    )
    VALUES (
        OLD.lib_isbn, 
        CONCAT('Cambio de: ', OLD.lib_titulo, ' a: ', NEW.lib_titulo), 
        USER(), 
        NOW(),
        'UPDATE'
    );
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `prestamo`
--

CREATE TABLE `prestamo` (
  `pres_id` varchar(20) NOT NULL,
  `pres_fechaPrestamo` date NOT NULL,
  `pres_fechaDevolucion` date NOT NULL,
  `soc_copiaNumero` int(11) NOT NULL,
  `lib_copiaISBN` bigint(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `prestamo`
--

INSERT INTO `prestamo` (`pres_id`, `pres_fechaPrestamo`, `pres_fechaDevolucion`, `soc_copiaNumero`, `lib_copiaISBN`) VALUES
('pres1', '2023-01-15', '2023-01-20', 1, 1234567890),
('pres2', '2023-02-03', '2023-02-04', 2, 9999999999),
('pres3', '2023-04-09', '2023-04-11', 6, 2718281828),
('pres4', '2023-06-14', '2023-06-15', 9, 8888888888),
('pres5', '2023-07-02', '2023-07-09', 10, 5555555555),
('pres6', '2023-08-19', '2023-08-26', 12, 5555555555),
('pres7', '2023-10-24', '2023-10-27', 3, 1357924680),
('pres8', '2023-11-11', '2023-11-12', 4, 9999999999);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `socio`
--

CREATE TABLE `socio` (
  `soc_numero` int(11) NOT NULL,
  `soc_nombre` varchar(45) NOT NULL,
  `soc_apellido` varchar(45) NOT NULL,
  `soc_direccion` varchar(255) NOT NULL,
  `soc_telefono` varchar(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `socio`
--

INSERT INTO `socio` (`soc_numero`, `soc_nombre`, `soc_apellido`, `soc_direccion`, `soc_telefono`) VALUES
(1, 'Anabel Antonia', 'Alderete Ruiz', 'Calle Primavera 321, Ciudad Hermosa, Barcelona', '3333333333'),
(2, 'Andrés Felipe', 'Galindo Luna', 'Avenida del Sol 456, Pueblo Nuevo, Madrid', '2123456789'),
(3, 'Juan ', 'González', 'Calle Principal 789, Villa Flores, Valencia', '2012345678'),
(4, 'Maria', 'Rodríguez', 'Carrera del Río 321, El Pueblo, Sevilla', '3012345678'),
(5, 'Pedro ', 'Martínez', 'Calle del Bosque 654, Los Pinos, Málaga', '1234567812'),
(6, 'Ana ', 'López', 'Avenida Central 987, Villa Hermosa, Bilbao', '6123456781'),
(7, 'Carlos', 'Sánchez', 'Calle de la Luna 234, El Prado, Alicante', '1123456781'),
(8, 'Laura', 'Ramírez', 'Carrera del Mar 567, Playa Azul, Palma de Mallorca', '1312345678'),
(9, 'Luis', 'Hernández', 'Avenida de la Montaña 890, Monte Verde, Granada', '6101234567'),
(10, 'Andrea', 'García', 'Calle del Sol 432, La Colina, Zaragoza', '1112345678'),
(11, 'Alejandro', 'Torres', 'Carrera del Oeste 765, Ciudad Nueva, Murcia', '4951234567'),
(12, 'Sofia', 'Morales', 'Avenida del Mar 098, Costa Brava, Gijón', '5512345678');

--
-- Disparadores `socio`
--
DELIMITER $$
CREATE TRIGGER `trg_auditoria_socio_delete` AFTER DELETE ON `socio` FOR EACH ROW BEGIN
    INSERT INTO auditoria_socio (
        soc_numero, 
        accion, 
        antiguo_nombre, nuevo_nombre, 
        antiguo_apellido, nuevo_apellido, 
        antigua_direccion, nueva_direccion, 
        antiguo_telefono, nuevo_telefono, 
        fecha_modificacion, 
        usuario
    ) VALUES (
        OLD.soc_numero, 
        'DELETE', 
        OLD.soc_nombre, NULL, 
        OLD.soc_apellido, NULL, 
        OLD.soc_direccion, NULL, 
        OLD.soc_telefono, NULL, 
        NOW(), 
        CURRENT_USER()
    );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_auditoria_socio_update` AFTER UPDATE ON `socio` FOR EACH ROW BEGIN
    INSERT INTO auditoria_socio (
        soc_numero, 
        accion, 
        antiguo_nombre, nuevo_nombre, 
        antiguo_apellido, nuevo_apellido, 
        antigua_direccion, nueva_direccion, 
        antiguo_telefono, nuevo_telefono, 
        fecha_modificacion, 
        usuario
    ) VALUES (
        OLD.soc_numero, 
        'UPDATE', 
        OLD.soc_nombre, NEW.soc_nombre, 
        OLD.soc_apellido, NEW.soc_apellido, 
        OLD.soc_direccion, NEW.soc_direccion, 
        OLD.soc_telefono, NEW.soc_telefono, 
        NOW(), 
        CURRENT_USER()
    );
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tipoautores`
--

CREATE TABLE `tipoautores` (
  `copia_ISBN` bigint(20) NOT NULL,
  `copia_autor` int(11) NOT NULL,
  `tipoAutor` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `tipoautores`
--

INSERT INTO `tipoautores` (`copia_ISBN`, `copia_autor`, `tipoAutor`) VALUES
(1357924680, 123, 'Traductor'),
(1234567890, 123, 'Autor'),
(1234567890, 456, 'Coautor'),
(2718281828, 789, 'Traductor'),
(8888888888, 234, 'Autor'),
(2468135790, 234, 'Autor'),
(9876543210, 567, 'Autor'),
(1234567890, 890, 'Autor'),
(8642097531, 345, 'Autor'),
(8888888888, 345, 'Coautor'),
(5555555555, 678, 'Autor'),
(3141592653, 901, 'Autor'),
(9517530862, 432, 'Autor'),
(7777777777, 765, 'Autor'),
(9999999999, 98, 'Autor');

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_catalogo_detallado`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_catalogo_detallado` (
`ISBN` bigint(20)
,`Título` varchar(255)
,`Género` varchar(20)
,`Páginas` int(11)
,`Categoría de Tamaño` varchar(8)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vista_reporte_prestamos`
-- (Véase abajo para la vista actual)
--
CREATE TABLE `vista_reporte_prestamos` (
`ID Préstamo` varchar(20)
,`Nombre Socio` varchar(45)
,`Apellido Socio` varchar(45)
,`Libro` varchar(255)
,`Autor` varchar(45)
,`Fecha Salida` date
,`Fecha Entrega` date
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_catalogo_detallado`
--
DROP TABLE IF EXISTS `vista_catalogo_detallado`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_catalogo_detallado`  AS SELECT `libro`.`lib_isbn` AS `ISBN`, `libro`.`lib_titulo` AS `Título`, `libro`.`lib_genero` AS `Género`, `libro`.`lib_numeroPaginas` AS `Páginas`, CASE WHEN `libro`.`lib_numeroPaginas` > 500 THEN 'Extenso' WHEN `libro`.`lib_numeroPaginas` between 200 and 500 THEN 'Promedio' ELSE 'Corto' END AS `Categoría de Tamaño` FROM `libro` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vista_reporte_prestamos`
--
DROP TABLE IF EXISTS `vista_reporte_prestamos`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vista_reporte_prestamos`  AS SELECT `p`.`pres_id` AS `ID Préstamo`, `s`.`soc_nombre` AS `Nombre Socio`, `s`.`soc_apellido` AS `Apellido Socio`, `l`.`lib_titulo` AS `Libro`, `a`.`aut_apellido` AS `Autor`, `p`.`pres_fechaPrestamo` AS `Fecha Salida`, `p`.`pres_fechaDevolucion` AS `Fecha Entrega` FROM ((((`prestamo` `p` join `socio` `s` on(`p`.`soc_copiaNumero` = `s`.`soc_numero`)) join `libro` `l` on(`p`.`lib_copiaISBN` = `l`.`lib_isbn`)) join `tipoautores` `ta` on(`l`.`lib_isbn` = `ta`.`copia_ISBN`)) join `autor` `a` on(`ta`.`copia_autor` = `a`.`aut_codigo`)) WHERE `ta`.`tipoAutor` = 'Autor' ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `auditoria_autor`
--
ALTER TABLE `auditoria_autor`
  ADD PRIMARY KEY (`id_auditoria`);

--
-- Indices de la tabla `auditoria_libro`
--
ALTER TABLE `auditoria_libro`
  ADD PRIMARY KEY (`aud_id`);

--
-- Indices de la tabla `auditoria_socio`
--
ALTER TABLE `auditoria_socio`
  ADD PRIMARY KEY (`id_auditoria`);

--
-- Indices de la tabla `autor`
--
ALTER TABLE `autor`
  ADD PRIMARY KEY (`aut_codigo`);

--
-- Indices de la tabla `libro`
--
ALTER TABLE `libro`
  ADD PRIMARY KEY (`lib_isbn`),
  ADD KEY `idx_libro_titulo` (`lib_titulo`);

--
-- Indices de la tabla `prestamo`
--
ALTER TABLE `prestamo`
  ADD PRIMARY KEY (`pres_id`),
  ADD KEY `soc_copiaNumero` (`soc_copiaNumero`),
  ADD KEY `lib_copiaISBN` (`lib_copiaISBN`);

--
-- Indices de la tabla `socio`
--
ALTER TABLE `socio`
  ADD PRIMARY KEY (`soc_numero`);

--
-- Indices de la tabla `tipoautores`
--
ALTER TABLE `tipoautores`
  ADD KEY `copia_ISBN` (`copia_ISBN`),
  ADD KEY `copia_autor` (`copia_autor`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `auditoria_autor`
--
ALTER TABLE `auditoria_autor`
  MODIFY `id_auditoria` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `auditoria_libro`
--
ALTER TABLE `auditoria_libro`
  MODIFY `aud_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `auditoria_socio`
--
ALTER TABLE `auditoria_socio`
  MODIFY `id_auditoria` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `prestamo`
--
ALTER TABLE `prestamo`
  ADD CONSTRAINT `prestamo_ibfk_1` FOREIGN KEY (`soc_copiaNumero`) REFERENCES `socio` (`soc_numero`),
  ADD CONSTRAINT `prestamo_ibfk_2` FOREIGN KEY (`lib_copiaISBN`) REFERENCES `libro` (`lib_isbn`);

--
-- Filtros para la tabla `tipoautores`
--
ALTER TABLE `tipoautores`
  ADD CONSTRAINT `tipoautores_ibfk_1` FOREIGN KEY (`copia_ISBN`) REFERENCES `libro` (`lib_isbn`),
  ADD CONSTRAINT `tipoautores_ibfk_2` FOREIGN KEY (`copia_autor`) REFERENCES `autor` (`aut_codigo`);

DELIMITER $$
--
-- Eventos
--
CREATE DEFINER=`root`@`localhost` EVENT `ev_limpiar_prestamos_antiguos` ON SCHEDULE EVERY 1 MONTH STARTS '2026-03-16 23:59:59' ENDS '2027-03-16 23:59:59' ON COMPLETION NOT PRESERVE ENABLE DO BEGIN
    -- Eliminamos préstamos con fecha de devolución mayor a 365 días
    DELETE FROM prestamo 
    WHERE pres_fechaDevolucion < DATE_SUB(NOW(), INTERVAL 1 YEAR);
END$$

DELIMITER ;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

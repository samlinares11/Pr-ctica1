-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 02-03-2026 a las 17:37:13
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
(1, 'Ana', 'Ruiz', 'Calle Primavera 123, Ciudad Jardín, Barcelona', '9123456780'),
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
(12, 'Sofia', 'Morales', 'Avenida del Mar 098, Costa Brava, Gijón', '5512345678'),
(13, 'Lorenzo', 'Millán', 'Calle Falsa 123, Mallorca', '1234567891');

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

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `autor`
--
ALTER TABLE `autor`
  ADD PRIMARY KEY (`aut_codigo`);

--
-- Indices de la tabla `libro`
--
ALTER TABLE `libro`
  ADD PRIMARY KEY (`lib_isbn`);

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
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

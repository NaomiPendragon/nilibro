-- =============================================================================
-- Nilibro — Catálogo inicial: 5 clásicos en español de dominio público
--
-- Correr en el SQL Editor DESPUÉS de nilibro.sql y nilibro_ajustes.sql, y
-- después de subir los archivos de la carpeta catalogo/ del proyecto:
--   catalogo/portadas/*.jpg  →  bucket `portadas`, carpeta `catalogo`
--   catalogo/pdfs/*.pdf      →  bucket `pdfs`,     carpeta `catalogo`
--
-- Textos: Project Gutenberg (sin su encabezado ni licencia). Portadas propias.
-- Son libros del catálogo, no autopublicados: el capítulo guarda solo su
-- nombre y la página del PDF donde empieza (sin `contenido`).
-- Se puede correr dos veces: si la obra ya existe, la salta.
-- =============================================================================

-- Don Quijote de la Mancha — Miguel de Cervantes (128 capítulos, 1066 páginas)
DO $$
DECLARE
    v_autor bigint;
    v_obra  bigint;
    v_libro bigint;
BEGIN
    IF EXISTS (SELECT 1 FROM obra WHERE titulo = 'Don Quijote de la Mancha') THEN
        RAISE NOTICE 'Ya existe: %', 'Don Quijote de la Mancha';
        RETURN;
    END IF;

    SELECT id INTO v_autor FROM autor WHERE nombre = 'Miguel de Cervantes' AND usuario_id IS NULL;
    IF v_autor IS NULL THEN
        INSERT INTO autor (nombre) VALUES ('Miguel de Cervantes') RETURNING id INTO v_autor;
    END IF;

    INSERT INTO obra (titulo, autor_id, sinopsis, genero_id)
    VALUES ('Don Quijote de la Mancha', v_autor, 'Un hidalgo de La Mancha enloquece de tanto leer libros de caballerías y sale, con su escudero Sancho Panza, a deshacer agravios por los caminos de España. Las dos partes completas (1605 y 1615).',
            (SELECT id FROM genero_libro WHERE nombre = 'Aventura'))
    RETURNING id INTO v_obra;

    INSERT INTO libro (obra_id, portada, pdf, paginas, estado, fecha_publicacion)
    VALUES (v_obra, 'catalogo/don-quijote.jpg', 'catalogo/don-quijote.pdf', 1066, 'publicado', current_date)
    RETURNING id INTO v_libro;

    INSERT INTO capitulo (libro_id, numero_capitulo, nombre, pagina_pdf) VALUES
        (v_libro, 1, 'Preliminares y prólogo', 3),
        (v_libro, 2, 'Parte I, cap. 1. Que trata de la condición y ejercicio del famoso hidalgo don Quijote de la Mancha', 19),
        (v_libro, 3, 'Parte I, cap. 2. Que trata de la primera salida que de su tierra hizo el ingenioso don Quijote', 24),
        (v_libro, 4, 'Parte I, cap. 3. Donde se cuenta la graciosa manera que tuvo don Quijote en armarse caballero', 30),
        (v_libro, 5, 'Parte I, cap. 4. De lo que le sucedió a nuestro caballero cuando salió de la venta', 36),
        (v_libro, 6, 'Parte I, cap. 5. Donde se prosigue la narración de la desgracia de nuestro caballero', 43),
        (v_libro, 7, 'Parte I, cap. 6. Del donoso y grande escrutinio que el cura y el barbero hicieron en la librería de nuestro ingenioso hidalgo', 48),
        (v_libro, 8, 'Parte I, cap. 7. De la segunda salida de nuestro buen caballero don Quijote de la Mancha', 56),
        (v_libro, 9, 'Parte I, cap. 8. Del buen suceso que el valeroso don Quijote tuvo en la espantable y jamás imaginada aventura de los molinos de viento, con otros sucesos dignos de felice recordación', 61),
        (v_libro, 10, 'Parte I, cap. 9. Donde se concluye y da fin a la estupenda batalla que el gallardo vizcaíno y el valiente manchego tuvieron', 70),
        (v_libro, 11, 'Parte I, cap. 10. De lo que más le avino a don Quijote con el vizcaíno, y del peligro en que se vio con una turba de yangüeses', 75),
        (v_libro, 12, 'Parte I, cap. 11. De lo que le sucedió a don Quijote con unos cabreros', 81),
        (v_libro, 13, 'Parte I, cap. 12. De lo que contó un cabrero a los que estaban con don Quijote', 88),
        (v_libro, 14, 'Parte I, cap. 13. Donde se da fin al cuento de la pastora Marcela, con otros sucesos', 94),
        (v_libro, 15, 'Parte I, cap. 14. Donde se ponen los versos desesperados del difunto pastor, con otros no esperados sucesos', 104),
        (v_libro, 16, 'Parte I, cap. 15. Donde se cuenta la desgraciada aventura que se topó don Quijote en topar con unos desalmados yangüeses', 114),
        (v_libro, 17, 'Parte I, cap. 16. De lo que le sucedió al ingenioso hidalgo en la venta que él imaginaba ser castillo', 122),
        (v_libro, 18, 'Parte I, cap. 17. Donde se prosiguen los innumerables trabajos que el bravo don Quijote y su buen escudero Sancho Panza pasaron en la venta que, por su mal, pensó que era castillo', 130),
        (v_libro, 19, 'Parte I, cap. 18. Donde se cuentan las razones que pasó Sancho Panza con su señor Don Quijote, con otras aventuras dignas de ser contadas', 139),
        (v_libro, 20, 'Parte I, cap. 19. De las discretas razones que Sancho pasaba con su amo, y de la aventura que le sucedió con un cuerpo muerto, con otros acontecimientos famosos', 150),
        (v_libro, 21, 'Parte I, cap. 20. De la jamás vista ni oída aventura que con más poco peligro fue acabada de famoso caballero en el mundo, como la que acabó el valeroso don Quijote de la Mancha', 158),
        (v_libro, 22, 'Parte I, cap. 21. Que trata de la alta aventura y rica ganancia del yelmo de Mambrino, con otras cosas sucedidas a nuestro invencible caballero', 171),
        (v_libro, 23, 'Parte I, cap. 22. De la libertad que dio don Quijote a muchos desdichados que, mal de su grado, los llevaban donde no quisieran ir', 182),
        (v_libro, 24, 'Parte I, cap. 23. De lo que le aconteció al famoso don Quijote en Sierra Morena, que fue una de las más raras aventuras que en esta verdadera historia se cuentan', 193),
        (v_libro, 25, 'Parte I, cap. 24. Donde se prosigue la aventura de la Sierra Morena', 204),
        (v_libro, 26, 'Parte I, cap. 25. Que trata de las estrañas cosas que en Sierra Morena sucedieron al valiente caballero de la Mancha, y de la imitación que hizo a la penitencia de Beltenebros', 213),
        (v_libro, 27, 'Parte I, cap. 26. Donde se prosiguen las finezas que de enamorado hizo don Quijote en Sierra Morena', 229),
        (v_libro, 28, 'Parte I, cap. 27. De cómo salieron con su intención el cura y el barbero, con otras cosas dignas de que se cuenten en esta grande historia', 237),
        (v_libro, 29, 'Parte I, cap. 28. Que trata de la nueva y agradable aventura que al cura y barbero sucedió en la mesma sierra', 253),
        (v_libro, 30, 'Parte I, cap. 29. Que trata de la discreción de la hermosa Dorotea, con otras cosas de mucho gusto y pasatiempo', 267),
        (v_libro, 31, 'Parte I, cap. 30. Que trata del gracioso artificio y orden que se tuvo en sacar a nuestro enamorado caballero de la asperísima penitencia en que se había puesto', 279),
        (v_libro, 32, 'Parte I, cap. 31. De los sabrosos razonamientos que pasaron entre don Quijote y Sancho Panza, su escudero, con otros sucesos', 289),
        (v_libro, 33, 'Parte I, cap. 32. Que trata de lo que sucedió en la venta a toda la cuadrilla de don Quijote', 298),
        (v_libro, 34, 'Parte I, cap. 33. Donde se cuenta la novela del Curioso impertinente', 305),
        (v_libro, 35, 'Parte I, cap. 34. Donde se prosigue la novela del Curioso impertinente', 323),
        (v_libro, 36, 'Parte I, cap. 35. Donde se da fin a la novela del Curioso impertinente', 341),
        (v_libro, 37, 'Parte I, cap. 36. Que trata de la brava y descomunal batalla que don Quijote tuvo con unos cueros de vino tinto, con otros raros sucesos que en la venta le sucedieron', 350),
        (v_libro, 38, 'Parte I, cap. 37. Que prosigue la historia de la famosa infanta Micomicona, con otras graciosas aventuras', 360),
        (v_libro, 39, 'Parte I, cap. 38. Que trata del curioso discurso que hizo don Quijote de las armas y las letras', 371),
        (v_libro, 40, 'Parte I, cap. 39. Donde el cautivo cuenta su vida y sucesos', 375),
        (v_libro, 41, 'Parte I, cap. 40. Donde se prosigue la historia del cautivo', 383),
        (v_libro, 42, 'Parte I, cap. 41. Donde todavía prosigue el cautivo su suceso', 395),
        (v_libro, 43, 'Parte I, cap. 42. Que trata de lo que más sucedió en la venta y de otras muchas cosas dignas de saberse', 413),
        (v_libro, 44, 'Parte I, cap. 43. Donde se cuenta la agradable historia del mozo de mulas, con otros estraños acaecimientos en la venta sucedidos]', 420),
        (v_libro, 45, 'Parte I, cap. 44. Donde se prosiguen los inauditos sucesos de la venta', 431),
        (v_libro, 46, 'Parte I, cap. 45. Donde se acaba de averiguar la duda del yelmo de Mambrino y de la albarda, y otras aventuras sucedidas, con toda verdad', 440),
        (v_libro, 47, 'Parte I, cap. 46. De la notable aventura de los cuadrilleros, y la gran ferocidad de nuestro buen caballero don Quijote', 448),
        (v_libro, 48, 'Parte I, cap. 47. Del estraño modo con que fue encantado don Quijote de la Mancha, con otros famosos sucesos', 456),
        (v_libro, 49, 'Parte I, cap. 48. Donde prosigue el canónigo la materia de los libros de caballerías, con otras cosas dignas de su ingenio', 466),
        (v_libro, 50, 'Parte I, cap. 49. Donde se trata del discreto coloquio que Sancho Panza tuvo con su señor don Quijote', 473),
        (v_libro, 51, 'Parte I, cap. 50. De las discretas altercaciones que don Quijote y el canónigo tuvieron, con otros sucesos', 480),
        (v_libro, 52, 'Parte I, cap. 51. Que trata de lo que contó el cabrero a todos los que llevaban a don Quijote', 487),
        (v_libro, 53, 'Parte I, cap. 52. De la pendencia que don Quijote tuvo con el cabrero, con la rara aventura de los deceplinantes, a quien dio felice fin a costa de su sudor', 492),
        (v_libro, 54, 'Parte II: preliminares y prólogo', 504),
        (v_libro, 55, 'Parte II, cap. 1. De lo que el cura y el barbero pasaron con don Quijote cerca de su enfermedad', 514),
        (v_libro, 56, 'Parte II, cap. 2. Que trata de la notable pendencia que Sancho Panza tuvo con la sobrina y ama de don Quijote, con otros sujetos graciosos', 525),
        (v_libro, 57, 'Parte II, cap. 3. Del ridículo razonamiento que pasó entre don Quijote, Sancho Panza y el bachiller Sansón Carrasco', 530),
        (v_libro, 58, 'Parte II, cap. 4. Donde Sancho Panza satisface al bachiller Sansón Carrasco de sus dudas y preguntas, con otros sucesos dignos de saberse y de contarse', 538),
        (v_libro, 59, 'Parte II, cap. 5. De la discreta y graciosa plática que pasó entre Sancho Panza y su mujer Teresa Panza, y otros sucesos dignos de felice recordación', 544),
        (v_libro, 60, 'Parte II, cap. 6. De lo que le pasó a Don Quijote con su sobrina y con su ama, y es uno de los importantes capítulos de toda la historia', 551),
        (v_libro, 61, 'Parte II, cap. 7. De lo que pasó don Quijote con su escudero, con otros sucesos famosísimos', 557),
        (v_libro, 62, 'Parte II, cap. 8. Donde se cuenta lo que le sucedió a don Quijote, yendo a ver su señora Dulcinea del Toboso', 564),
        (v_libro, 63, 'Parte II, cap. 9. Donde se cuenta lo que en él se verá', 572),
        (v_libro, 64, 'Parte II, cap. 10. Donde se cuenta la industria que Sancho tuvo para encantar a la señora Dulcinea, y de otros sucesos tan ridículos como verdaderos', 576),
        (v_libro, 65, 'Parte II, cap. 11. De la estraña aventura que le sucedió al valeroso don Quijote con el carro, o carreta, de Las Cortes de la Muerte', 585),
        (v_libro, 66, 'Parte II, cap. 12. De la estraña aventura que le sucedió al valeroso don Quijote con el bravo Caballero de los Espejos', 592),
        (v_libro, 67, 'Parte II, cap. 13. Donde se prosigue la aventura del Caballero del Bosque, con el discreto, nuevo y suave coloquio que pasó entre los dos escuderos', 599),
        (v_libro, 68, 'Parte II, cap. 14. Donde se prosigue la aventura del Caballero del Bosque', 606),
        (v_libro, 69, 'Parte II, cap. 15. Donde se cuenta y da noticia de quién era el Caballero de los Espejos y su escudero', 617),
        (v_libro, 70, 'Parte II, cap. 16. De lo que sucedió a don Quijote con un discreto caballero de la Mancha', 620),
        (v_libro, 71, 'Parte II, cap. 17. De donde se declaró el último punto y estremo adonde llegó y pudo llegar el inaudito ánimo de don Quijote, con la felicemente acabada aventura de los leones', 629),
        (v_libro, 72, 'Parte II, cap. 18. De lo que sucedió a don Quijote en el castillo o casa del Caballero del Verde Gabán, con otras cosas extravagantes', 640),
        (v_libro, 73, 'Parte II, cap. 19. Donde se cuenta la aventura del pastor enamorado, con otros en verdad graciosos sucesos', 650),
        (v_libro, 74, 'Parte II, cap. 20. Donde se cuentan las bodas de Camacho el rico, con el suceso de Basilio el pobre', 658),
        (v_libro, 75, 'Parte II, cap. 21. Donde se prosiguen las bodas de Camacho, con otros gustosos sucesos', 668),
        (v_libro, 76, 'Parte II, cap. 22. Donde se da cuenta de la grande aventura de la cueva de Montesinos, que está en el corazón de la Mancha, a quien dio felice cima el valeroso don Quijote de la Mancha', 675),
        (v_libro, 77, 'Parte II, cap. 23. De las admirables cosas que el estremado don Quijote contó que había visto en la profunda cueva de Montesinos, cuya imposibilidad y grandeza hace que se tenga esta aventura por apócrifa', 683),
        (v_libro, 78, 'Parte II, cap. 24. Donde se cuentan mil zarandajas tan impertinentes como necesarias al verdadero entendimiento desta grande historia', 693),
        (v_libro, 79, 'Parte II, cap. 25. Donde se apunta la aventura del rebuzno y la graciosa del titerero, con las memorables adivinanzas del mono adivino', 700),
        (v_libro, 80, 'Parte II, cap. 26. Donde se prosigue la graciosa aventura del titerero, con otras cosas en verdad harto buenas', 710),
        (v_libro, 81, 'Parte II, cap. 27. Donde se da cuenta quiénes eran maese Pedro y su mono, con el mal suceso que don Quijote tuvo en la aventura del rebuzno, que no la acabó como él quisiera y como lo tenía pensado', 719),
        (v_libro, 82, 'Parte II, cap. 28. De cosas que dice Benengeli que las sabrá quien le leyere, si las lee con atención', 726),
        (v_libro, 83, 'Parte II, cap. 29. De la famosa aventura del barco encantado', 731),
        (v_libro, 84, 'Parte II, cap. 30. De lo que le avino a don Quijote con una bella cazadora', 738),
        (v_libro, 85, 'Parte II, cap. 31. Que trata de muchas y grandes cosas', 743),
        (v_libro, 86, 'Parte II, cap. 32. De la respuesta que dio don Quijote a su reprehensor, con otros graves y graciosos sucesos', 752),
        (v_libro, 87, 'Parte II, cap. 33. De la sabrosa plática que la duquesa y sus doncellas pasaron con Sancho Panza, digna de que se lea y de que se note', 765),
        (v_libro, 88, 'Parte II, cap. 34. Que cuenta de la noticia que se tuvo de cómo se había de desencantar la sin par Dulcinea del Toboso, que es una de las aventuras más famosas deste libro', 772),
        (v_libro, 89, 'Parte II, cap. 35. Donde se prosigue la noticia que tuvo don Quijote del desencanto de Dulcinea, con otros admirables sucesos', 780),
        (v_libro, 90, 'Parte II, cap. 36. Donde se cuenta la estraña y jamás imaginada aventura de la dueña Dolorida, alias de la condesa Trifaldi, con una carta que Sancho Panza escribió a su mujer Teresa Panza', 788),
        (v_libro, 91, 'Parte II, cap. 37. Donde se prosigue la famosa aventura de la dueña Dolorida', 794),
        (v_libro, 92, 'Parte II, cap. 38. Donde se cuenta la que dio de su mala andanza la dueña Dolorida', 797),
        (v_libro, 93, 'Parte II, cap. 39. Donde la Trifaldi prosigue su estupenda y memorable historia', 803),
        (v_libro, 94, 'Parte II, cap. 40. De cosas que atañen y tocan a esta aventura y a esta memorable historia', 806),
        (v_libro, 95, 'Parte II, cap. 41. De la venida de Clavileño, con el fin desta dilatada aventura', 812),
        (v_libro, 96, 'Parte II, cap. 42. De los consejos que dio don Quijote a Sancho Panza antes que fuese a gobernar la ínsula, con otras cosas bien consideradas', 823),
        (v_libro, 97, 'Parte II, cap. 43. De los consejos segundos que dio don Quijote a Sancho Panza', 828),
        (v_libro, 98, 'Parte II, cap. 44. Cómo Sancho Panza fue llevado al gobierno, y de la estraña aventura que en el castillo sucedió a don Quijote', 834),
        (v_libro, 99, 'Parte II, cap. 45. De cómo el gran Sancho Panza tomó la posesión de su ínsula, y del modo que comenzó a gobernar', 844),
        (v_libro, 100, 'Parte II, cap. 46. Del temeroso espanto cencerril y gatuno que recibió don Quijote en el discurso de los amores de la enamorada Altisidora', 852),
        (v_libro, 101, 'Parte II, cap. 47. Donde se prosigue cómo se portaba Sancho Panza en su gobierno', 857),
        (v_libro, 102, 'Parte II, cap. 48. De lo que le sucedió a don Quijote con doña Rodríguez, la dueña de la duquesa, con otros acontecimientos dignos de escritura y de memoria eterna', 866),
        (v_libro, 103, 'Parte II, cap. 49. De lo que le sucedió a Sancho Panza rondando su ínsula', 874),
        (v_libro, 104, 'Parte II, cap. 50. Donde se declara quién fueron los encantadores y verdugos que azotaron a la dueña y pellizcaron y arañaron a don Quijote, con el suceso que tuvo el paje que llevó la carta a Teresa Sancha, mujer de Sancho Panza', 886),
        (v_libro, 105, 'Parte II, cap. 51. Del progreso del gobierno de Sancho Panza, con otros sucesos tales como buenos', 896),
        (v_libro, 106, 'Parte II, cap. 52. Donde se cuenta la aventura de la segunda dueña Dolorida, o Angustiada, llamada por otro nombre doña Rodríguez', 904),
        (v_libro, 107, 'Parte II, cap. 53. Del fatigado fin y remate que tuvo el gobierno de Sancho Panza', 911),
        (v_libro, 108, 'Parte II, cap. 54. Que trata de cosas tocantes a esta historia, y no a otra alguna', 917),
        (v_libro, 109, 'Parte II, cap. 55. De cosas sucedidas a Sancho en el camino, y otras que no hay más que ver', 925),
        (v_libro, 110, 'Parte II, cap. 56. De la descomunal y nunca vista batalla que pasó entre don Quijote de la Mancha y el lacayo Tosilos, en la defensa de la hija de la dueña doña Rodríguez', 932),
        (v_libro, 111, 'Parte II, cap. 57. Que trata de cómo don Quijote se despidió del duque, y de lo que le sucedió con la discreta y desenvuelta Altisidora, doncella de la duquesa', 937),
        (v_libro, 112, 'Parte II, cap. 58. Que trata de cómo menudearon sobre don Quijote aventuras tantas, que no se daban vagar unas a otras', 942),
        (v_libro, 113, 'Parte II, cap. 59. Donde se cuenta del extraordinario suceso, que se puede tener por aventura, que le sucedió a don Quijote', 954),
        (v_libro, 114, 'Parte II, cap. 60. De lo que sucedió a don Quijote yendo a Barcelona', 963),
        (v_libro, 115, 'Parte II, cap. 61. De lo que le sucedió a don Quijote en la entrada de Barcelona, con otras cosas que tienen más de lo verdadero que de lo discreto', 976),
        (v_libro, 116, 'Parte II, cap. 62. Que trata de la aventura de la cabeza encantada, con otras niñerías que no pueden dejar de contarse', 979),
        (v_libro, 117, 'Parte II, cap. 63. De lo mal que le avino a Sancho Panza con la visita de las galeras, y la nueva aventura de la hermosa morisca', 992),
        (v_libro, 118, 'Parte II, cap. 64. Que trata de la aventura que más pesadumbre dio a don Quijote de cuantas hasta entonces le habían sucedido', 1002),
        (v_libro, 119, 'Parte II, cap. 65. Donde se da noticia quién era el de la Blanca Luna, con la libertad de Don Gregorio, y de otros sucesos', 1007),
        (v_libro, 120, 'Parte II, cap. 66. Que trata de lo que verá el que lo leyere, o lo oirá el que lo escuchare leer', 1013),
        (v_libro, 121, 'Parte II, cap. 67. De la resolución que tomó don Quijote de hacerse pastor y seguir la vida del campo, en tanto que se pasaba el año de su promesa, con otros sucesos en verdad gustosos y buenos', 1019),
        (v_libro, 122, 'Parte II, cap. 68. De la cerdosa aventura que le aconteció a don Quijote', 1024),
        (v_libro, 123, 'Parte II, cap. 69. Del más raro y más nuevo suceso que en todo el discurso desta grande historia avino a don Quijote', 1030),
        (v_libro, 124, 'Parte II, cap. 70. Que sigue al de sesenta y nueve, y trata de cosas no escusadas para la claridad desta historia', 1036),
        (v_libro, 125, 'Parte II, cap. 71. De lo que a don Quijote le sucedió con su escudero Sancho yendo a su aldea', 1044),
        (v_libro, 126, 'Parte II, cap. 72. De cómo don Quijote y Sancho llegaron a su aldea', 1050),
        (v_libro, 127, 'Parte II, cap. 73. De los agüeros que tuvo don Quijote al entrar de su aldea, con otros sucesos que adornan y acreditan esta grande historia', 1055),
        (v_libro, 128, 'Parte II, cap. 74. De cómo don Quijote cayó malo, y del testamento que hizo, y su muerte', 1060);
END $$;

-- Lazarillo de Tormes — Anónimo (8 capítulos, 59 páginas)
DO $$
DECLARE
    v_autor bigint;
    v_obra  bigint;
    v_libro bigint;
BEGIN
    IF EXISTS (SELECT 1 FROM obra WHERE titulo = 'Lazarillo de Tormes') THEN
        RAISE NOTICE 'Ya existe: %', 'Lazarillo de Tormes';
        RETURN;
    END IF;

    SELECT id INTO v_autor FROM autor WHERE nombre = 'Anónimo' AND usuario_id IS NULL;
    IF v_autor IS NULL THEN
        INSERT INTO autor (nombre) VALUES ('Anónimo') RETURNING id INTO v_autor;
    END IF;

    INSERT INTO obra (titulo, autor_id, sinopsis, genero_id)
    VALUES ('Lazarillo de Tormes', v_autor, 'Lázaro cuenta su vida de niño pobre al servicio de un ciego, un clérigo y un escudero, entre otros amos, y cómo aprendió a sobrevivir a fuerza de ingenio. La novela picaresca por excelencia (1554).',
            (SELECT id FROM genero_libro WHERE nombre = 'Aventura'))
    RETURNING id INTO v_obra;

    INSERT INTO libro (obra_id, portada, pdf, paginas, estado, fecha_publicacion)
    VALUES (v_obra, 'catalogo/lazarillo-de-tormes.jpg', 'catalogo/lazarillo-de-tormes.pdf', 59, 'publicado', current_date)
    RETURNING id INTO v_libro;

    INSERT INTO capitulo (libro_id, numero_capitulo, nombre, pagina_pdf) VALUES
        (v_libro, 1, 'Prólogo', 3),
        (v_libro, 2, 'Tratado Primero: Cuenta Lázaro su vida, y cuyo hijo fue', 5),
        (v_libro, 3, 'Tratado Segundo: Cómo Lázaro se asentó con un clérigo, y de las cosas que con él pasó', 18),
        (v_libro, 4, 'Tratado Tercero: Cómo Lázaro se asentó con un escudero, y de lo que le acaeció con él', 29),
        (v_libro, 5, 'Tratado Cuarto: Cómo Lázaro se asentó con un fraile de la Merced, y de lo que le', 46),
        (v_libro, 6, 'Tratado Quinto: Cómo Lázaro se asentó con un buldero, y de las cosas que con él pasó', 47),
        (v_libro, 7, 'Tratado Sexto: Cómo Lázaro se asentó con un capellán, y lo que con él pasó', 56),
        (v_libro, 8, 'Tratado Séptimo: Cómo Lázaro se asentó con un alguacil, y de lo que le acaeció con él', 57);
END $$;

-- Marianela — Benito Pérez Galdós (22 capítulos, 162 páginas)
DO $$
DECLARE
    v_autor bigint;
    v_obra  bigint;
    v_libro bigint;
BEGIN
    IF EXISTS (SELECT 1 FROM obra WHERE titulo = 'Marianela') THEN
        RAISE NOTICE 'Ya existe: %', 'Marianela';
        RETURN;
    END IF;

    SELECT id INTO v_autor FROM autor WHERE nombre = 'Benito Pérez Galdós' AND usuario_id IS NULL;
    IF v_autor IS NULL THEN
        INSERT INTO autor (nombre) VALUES ('Benito Pérez Galdós') RETURNING id INTO v_autor;
    END IF;

    INSERT INTO obra (titulo, autor_id, sinopsis, genero_id)
    VALUES ('Marianela', v_autor, 'Nela, una muchacha huérfana y poco agraciada, sirve de lazarillo a Pablo, un joven ciego que la cree hermosa. Todo cambia cuando un médico promete devolverle la vista (1878).',
            (SELECT id FROM genero_libro WHERE nombre = 'Drama'))
    RETURNING id INTO v_obra;

    INSERT INTO libro (obra_id, portada, pdf, paginas, estado, fecha_publicacion)
    VALUES (v_obra, 'catalogo/marianela.jpg', 'catalogo/marianela.pdf', 162, 'publicado', current_date)
    RETURNING id INTO v_libro;

    INSERT INTO capitulo (libro_id, numero_capitulo, nombre, pagina_pdf) VALUES
        (v_libro, 1, 'Perdido', 3),
        (v_libro, 2, 'Guiado', 9),
        (v_libro, 3, 'Un diálogo que servirá de exposición', 18),
        (v_libro, 4, 'La familia de piedra', 25),
        (v_libro, 5, 'Trabajo. Paisaje. Figura', 34),
        (v_libro, 6, 'Tonterías', 40),
        (v_libro, 7, 'Más tonterías', 47),
        (v_libro, 8, 'Prosiguen las tonterías', 54),
        (v_libro, 9, 'Los Golfines', 62),
        (v_libro, 10, 'Historia de dos hijos del pueblo', 73),
        (v_libro, 11, 'El patriarca de Aldeacorba', 77),
        (v_libro, 12, 'El doctor Celipín', 85),
        (v_libro, 13, 'Entre dos cestas', 89),
        (v_libro, 14, 'De cómo la Virgen María se apareció a la Nela', 93),
        (v_libro, 15, 'Los tres', 101),
        (v_libro, 16, 'La promesa', 106),
        (v_libro, 17, 'Fugitiva y meditabunda', 110),
        (v_libro, 18, 'La Nela se decide a partir', 118),
        (v_libro, 19, 'Domesticación', 124),
        (v_libro, 20, 'El nuevo mundo', 136),
        (v_libro, 21, 'Los ojos matan', 144),
        (v_libro, 22, 'Adiós', 160);
END $$;

-- Azul... — Rubén Darío (23 capítulos, 125 páginas)
DO $$
DECLARE
    v_autor bigint;
    v_obra  bigint;
    v_libro bigint;
BEGIN
    IF EXISTS (SELECT 1 FROM obra WHERE titulo = 'Azul...') THEN
        RAISE NOTICE 'Ya existe: %', 'Azul...';
        RETURN;
    END IF;

    SELECT id INTO v_autor FROM autor WHERE nombre = 'Rubén Darío' AND usuario_id IS NULL;
    IF v_autor IS NULL THEN
        INSERT INTO autor (nombre) VALUES ('Rubén Darío') RETURNING id INTO v_autor;
    END IF;

    INSERT INTO obra (titulo, autor_id, sinopsis, genero_id)
    VALUES ('Azul...', v_autor, 'Cuentos en prosa y poemas con los que el nicaragüense Rubén Darío inauguró el modernismo hispanoamericano. Edición de 1890, con la carta-prólogo de Juan Valera.',
            (SELECT id FROM genero_libro WHERE nombre = 'Poesía'))
    RETURNING id INTO v_obra;

    INSERT INTO libro (obra_id, portada, pdf, paginas, estado, fecha_publicacion)
    VALUES (v_obra, 'catalogo/azul.jpg', 'catalogo/azul.pdf', 125, 'publicado', current_date)
    RETURNING id INTO v_libro;

    INSERT INTO capitulo (libro_id, numero_capitulo, nombre, pagina_pdf) VALUES
        (v_libro, 1, 'Carta-prólogo de Juan Valera', 3),
        (v_libro, 2, 'El rey burgués', 21),
        (v_libro, 3, 'El sátiro sordo', 26),
        (v_libro, 4, 'La ninfa', 31),
        (v_libro, 5, 'El fardo', 36),
        (v_libro, 6, 'El velo de la reina mab', 42),
        (v_libro, 7, 'La canción del oro', 46),
        (v_libro, 8, 'El rubí', 51),
        (v_libro, 9, 'El palacio del sol', 58),
        (v_libro, 10, 'El pájaro azul', 62),
        (v_libro, 11, 'Palomas blancas y garzas morenas', 67),
        (v_libro, 12, 'En Chile', 74),
        (v_libro, 13, 'La muerte de la emperatriz de la china', 85),
        (v_libro, 14, 'A una estrella', 92),
        (v_libro, 15, 'Primaveral', 95),
        (v_libro, 16, 'Estival', 99),
        (v_libro, 17, 'Autumnal', 105),
        (v_libro, 18, 'Invernal', 108),
        (v_libro, 19, 'Pensamientos de otoño', 113),
        (v_libro, 20, 'A un poeta', 116),
        (v_libro, 21, 'Anagke', 118),
        (v_libro, 22, 'Sonetos', 121),
        (v_libro, 23, 'Medallones', 123);
END $$;

-- Cuentos de amor de locura y de muerte — Horacio Quiroga (18 capítulos, 174 páginas)
DO $$
DECLARE
    v_autor bigint;
    v_obra  bigint;
    v_libro bigint;
BEGIN
    IF EXISTS (SELECT 1 FROM obra WHERE titulo = 'Cuentos de amor de locura y de muerte') THEN
        RAISE NOTICE 'Ya existe: %', 'Cuentos de amor de locura y de muerte';
        RETURN;
    END IF;

    SELECT id INTO v_autor FROM autor WHERE nombre = 'Horacio Quiroga' AND usuario_id IS NULL;
    IF v_autor IS NULL THEN
        INSERT INTO autor (nombre) VALUES ('Horacio Quiroga') RETURNING id INTO v_autor;
    END IF;

    INSERT INTO obra (titulo, autor_id, sinopsis, genero_id)
    VALUES ('Cuentos de amor de locura y de muerte', v_autor, 'Dieciocho cuentos del uruguayo Horacio Quiroga, entre ellos «El almohadón de pluma» y «La gallina degollada»: la selva, la enfermedad y el miedo como nunca se habían contado (1917).',
            (SELECT id FROM genero_libro WHERE nombre = 'Terror'))
    RETURNING id INTO v_obra;

    INSERT INTO libro (obra_id, portada, pdf, paginas, estado, fecha_publicacion)
    VALUES (v_obra, 'catalogo/cuentos-de-amor-de-locura-y-de-muerte.jpg', 'catalogo/cuentos-de-amor-de-locura-y-de-muerte.pdf', 174, 'publicado', current_date)
    RETURNING id INTO v_libro;

    INSERT INTO capitulo (libro_id, numero_capitulo, nombre, pagina_pdf) VALUES
        (v_libro, 1, 'Una estación de amor', 3),
        (v_libro, 2, 'Los ojos sombríos', 24),
        (v_libro, 3, 'El solitario', 33),
        (v_libro, 4, 'La muerte de Isolda', 39),
        (v_libro, 5, 'El infierno artificial', 47),
        (v_libro, 6, 'La gallina degollada', 55),
        (v_libro, 7, 'Los buques suicidantes', 63),
        (v_libro, 8, 'El almohadón de pluma', 67),
        (v_libro, 9, 'El perro rabioso', 71),
        (v_libro, 10, 'A la deriva', 80),
        (v_libro, 11, 'La insolación', 84),
        (v_libro, 12, 'El alambre de púa', 92),
        (v_libro, 13, 'Los mensú', 104),
        (v_libro, 14, 'Yaguaí', 115),
        (v_libro, 15, 'Los pescadores de vigas', 126),
        (v_libro, 16, 'La miel silvestre', 133),
        (v_libro, 17, 'Nuestro primer cigarro', 139),
        (v_libro, 18, 'La meningitis y su sombra', 149);
END $$;

-- =============================================================================
-- Nilibro — Esquema de base de datos (PostgreSQL / Supabase)
--
-- Ejecutar en el SQL Editor de Supabase. Depende del esquema `auth` de
-- Supabase (auth.users, auth.uid()), así que NO corre tal cual sobre un
-- Postgres "pelado" como el del docker-compose.
--
-- Archivos (portadas, PDFs, fotos de perfil) viven en Supabase Storage; en la
-- BD solo se guarda la ruta del objeto dentro del bucket.
-- =============================================================================


-- =============================================================================
-- 1. CATÁLOGOS
-- =============================================================================

CREATE TABLE genero_libro (
    id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre  text NOT NULL UNIQUE
);

CREATE TABLE editorial (
    id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre  text NOT NULL UNIQUE
);

CREATE TABLE categoria_foro (
    id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre  text NOT NULL UNIQUE
);


-- =============================================================================
-- 2. USUARIOS Y AUTORES
-- =============================================================================

-- Perfil público. Correo, contraseña y última sesión los maneja Supabase Auth
-- en auth.users (email, encrypted_password, last_sign_in_at).
CREATE TABLE usuario (
    id              uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
    nickname        text NOT NULL,
    foto_perfil     text,                                   -- ruta en bucket
    fecha_registro  timestamptz NOT NULL DEFAULT now(),
    rol             text NOT NULL DEFAULT 'lector'
                    CHECK (rol IN ('lector', 'admin')),
    CHECK (nickname ~ '^[A-Za-z0-9_.]{3,30}$')
);

-- Nickname único sin importar mayúsculas: "Lysme" y "lysme" son el mismo.
CREATE UNIQUE INDEX usuario_nickname_uq ON usuario (lower(nickname));

-- Un autor puede no tener cuenta (Cervantes) o ser un usuario que publica
-- sus propias obras (usuario_id apunta a su cuenta).
CREATE TABLE autor (
    id                   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre               text NOT NULL,
    biografia            text,
    genero_principal_id  bigint REFERENCES genero_libro (id) ON DELETE SET NULL,
    usuario_id           uuid UNIQUE REFERENCES usuario (id) ON DELETE SET NULL
);

-- Un usuario puede seguir a un autor
CREATE TABLE suscripcion (
    usuario_id  uuid   NOT NULL REFERENCES usuario (id) ON DELETE CASCADE,
    autor_id    bigint NOT NULL REFERENCES autor (id)   ON DELETE CASCADE,
    fecha       timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (usuario_id, autor_id)
);


-- =============================================================================
-- 3. OBRAS, LIBROS Y CAPÍTULOS
-- =============================================================================

-- Obra en general: "Harry Potter y la piedra filosofal"
CREATE TABLE obra (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    titulo     text   NOT NULL,
    autor_id   bigint NOT NULL REFERENCES autor (id)        ON DELETE RESTRICT,
    sinopsis   text,
    genero_id  bigint NOT NULL REFERENCES genero_libro (id) ON DELETE RESTRICT
);

-- Publicación específica: editorial Salamandra, 5ta versión
CREATE TABLE libro (
    id                 bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    obra_id            bigint NOT NULL REFERENCES obra (id) ON DELETE CASCADE,
    portada            text,                                -- ruta en bucket
    editorial_id       bigint REFERENCES editorial (id) ON DELETE RESTRICT,  -- NULL = autopublicado
    version            integer NOT NULL DEFAULT 1 CHECK (version > 0),
    fecha_publicacion  date,
    paginas            integer CHECK (paginas > 0),
    pdf                text,                                -- ruta en bucket
    idioma             char(2) NOT NULL DEFAULT 'es'
                       CHECK (idioma ~ '^[a-z]{2}$'),       -- ISO 639-1: es, en, fr...
    estado             text NOT NULL DEFAULT 'borrador'
                       CHECK (estado IN ('borrador', 'publicado')),
    -- Un libro publicado tiene que tener su PDF generado
    CHECK (estado = 'borrador' OR pdf IS NOT NULL)
);

-- Capítulos del libro: índice sobre el PDF + texto fuente para poder editarlo
CREATE TABLE capitulo (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    libro_id         bigint  NOT NULL REFERENCES libro (id) ON DELETE CASCADE,
    numero_capitulo  integer NOT NULL CHECK (numero_capitulo > 0),
    nombre           text,
    pagina_pdf       integer CHECK (pagina_pdf > 0),
    contenido        text,
    UNIQUE (libro_id, numero_capitulo)
);


-- =============================================================================
-- 4. INTERACCIÓN CON LIBROS
-- =============================================================================

CREATE TABLE resena (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    libro_id      bigint   NOT NULL REFERENCES libro (id)   ON DELETE CASCADE,
    usuario_id    uuid     NOT NULL REFERENCES usuario (id) ON DELETE CASCADE,
    texto         text,
    calificacion  smallint NOT NULL CHECK (calificacion BETWEEN 1 AND 5),
    fecha         timestamptz NOT NULL DEFAULT now(),
    UNIQUE (usuario_id, libro_id)
);

-- Comentarios por capítulo, con respuestas (comentario_padre_id)
CREATE TABLE comentario (
    id                   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_id           uuid   NOT NULL REFERENCES usuario (id)  ON DELETE CASCADE,
    capitulo_id          bigint NOT NULL REFERENCES capitulo (id) ON DELETE CASCADE,
    comentario           text   NOT NULL,
    fecha                timestamptz NOT NULL DEFAULT now(),
    comentario_padre_id  bigint REFERENCES comentario (id) ON DELETE CASCADE
);

-- Relaciona libros con usuario e indica su progreso de lectura
CREATE TABLE biblioteca (
    usuario_id            uuid   NOT NULL REFERENCES usuario (id) ON DELETE CASCADE,
    libro_id              bigint NOT NULL REFERENCES libro (id)   ON DELETE CASCADE,
    fecha_adicion         timestamptz NOT NULL DEFAULT now(),
    fecha_ultima_lectura  timestamptz,
    ultima_pagina_leida   integer NOT NULL DEFAULT 0 CHECK (ultima_pagina_leida >= 0),
    estado_lectura        text NOT NULL DEFAULT 'quiero_leer'
                          CHECK (estado_lectura IN ('quiero_leer', 'leyendo', 'leido', 'abandonado')),
    PRIMARY KEY (usuario_id, libro_id)
);

-- aceptada: NULL = pendiente, true = aceptada, false = rechazada
CREATE TABLE recomendacion (
    id                     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_recomienda_id  uuid   NOT NULL REFERENCES usuario (id) ON DELETE CASCADE,
    usuario_recibe_id      uuid   NOT NULL REFERENCES usuario (id) ON DELETE CASCADE,
    libro_id               bigint NOT NULL REFERENCES libro (id)   ON DELETE CASCADE,
    mensaje                text,
    fecha_recomendacion    timestamptz NOT NULL DEFAULT now(),
    aceptada               boolean,
    CHECK (usuario_recomienda_id <> usuario_recibe_id)
);


-- =============================================================================
-- 5. CLUBES DE LECTURA
-- =============================================================================

CREATE TABLE club_lectura (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          text NOT NULL,
    descripcion     text,
    tipo            text NOT NULL DEFAULT 'publico'
                    CHECK (tipo IN ('privado', 'publico')),
    lider_id        uuid REFERENCES usuario (id) ON DELETE SET NULL,
    creado_por_id   uuid REFERENCES usuario (id) ON DELETE SET NULL,
    fecha_creacion  timestamptz NOT NULL DEFAULT now(),
    cupo_maximo     integer CHECK (cupo_maximo > 0)          -- NULL = sin límite
);

CREATE TABLE miembro_club (
    club_lectura_id  bigint NOT NULL REFERENCES club_lectura (id) ON DELETE CASCADE,
    usuario_id       uuid   NOT NULL REFERENCES usuario (id)      ON DELETE CASCADE,
    fecha_ingreso    timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (club_lectura_id, usuario_id)
);

CREATE TABLE plan_club (
    id                    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    club_lectura_id       bigint  NOT NULL REFERENCES club_lectura (id) ON DELETE CASCADE,
    orden                 integer NOT NULL CHECK (orden > 0),
    libro_id              bigint  NOT NULL REFERENCES libro (id) ON DELETE RESTRICT,
    fecha_inicio_lectura  date,
    fecha_limite_lectura  date,
    UNIQUE (club_lectura_id, orden),
    CHECK (fecha_limite_lectura >= fecha_inicio_lectura)
);


-- =============================================================================
-- 6. FOROS
-- =============================================================================

CREATE TABLE foro (
    id                          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre                      text   NOT NULL,
    categoria_id                bigint NOT NULL REFERENCES categoria_foro (id) ON DELETE RESTRICT,
    fecha_ultima_actualizacion  timestamptz NOT NULL DEFAULT now()   -- la mantiene un trigger
);

CREATE TABLE hilo (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre          text   NOT NULL,
    foro_id         bigint NOT NULL REFERENCES foro (id)    ON DELETE CASCADE,
    usuario_id      uuid   NOT NULL REFERENCES usuario (id) ON DELETE CASCADE,
    fecha_creacion  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE mensaje (
    id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hilo_id           bigint NOT NULL REFERENCES hilo (id)    ON DELETE CASCADE,
    usuario_id        uuid   NOT NULL REFERENCES usuario (id) ON DELETE CASCADE,
    contenido         text   NOT NULL,
    fecha             timestamptz NOT NULL DEFAULT now(),
    mensaje_padre_id  bigint REFERENCES mensaje (id) ON DELETE CASCADE
);


-- =============================================================================
-- 7. ÍNDICES
-- Postgres no indexa las FK automáticamente. Las que ya son el primer campo
-- de una PK o UNIQUE (capitulo.libro_id, biblioteca.usuario_id, etc.) no
-- necesitan índice aparte.
-- =============================================================================

CREATE INDEX autor_genero_principal_idx  ON autor (genero_principal_id);
CREATE INDEX suscripcion_autor_idx       ON suscripcion (autor_id);
CREATE INDEX obra_autor_idx              ON obra (autor_id);
CREATE INDEX obra_genero_idx             ON obra (genero_id);
CREATE INDEX libro_obra_idx              ON libro (obra_id);
CREATE INDEX libro_editorial_idx         ON libro (editorial_id);
CREATE INDEX libro_idioma_idx            ON libro (idioma);
CREATE INDEX resena_libro_idx            ON resena (libro_id);
CREATE INDEX comentario_capitulo_idx     ON comentario (capitulo_id);
CREATE INDEX comentario_usuario_idx      ON comentario (usuario_id);
CREATE INDEX comentario_padre_idx        ON comentario (comentario_padre_id);
CREATE INDEX biblioteca_libro_idx        ON biblioteca (libro_id);
CREATE INDEX recomendacion_recomienda_idx ON recomendacion (usuario_recomienda_id);
CREATE INDEX recomendacion_recibe_idx    ON recomendacion (usuario_recibe_id);
CREATE INDEX recomendacion_libro_idx     ON recomendacion (libro_id);
CREATE INDEX club_lectura_lider_idx      ON club_lectura (lider_id);
CREATE INDEX club_lectura_creador_idx    ON club_lectura (creado_por_id);
CREATE INDEX miembro_club_usuario_idx    ON miembro_club (usuario_id);
CREATE INDEX plan_club_libro_idx         ON plan_club (libro_id);
CREATE INDEX foro_categoria_idx          ON foro (categoria_id);
CREATE INDEX hilo_foro_idx               ON hilo (foro_id);
CREATE INDEX hilo_usuario_idx            ON hilo (usuario_id);
CREATE INDEX mensaje_hilo_idx            ON mensaje (hilo_id);
CREATE INDEX mensaje_usuario_idx         ON mensaje (usuario_id);
CREATE INDEX mensaje_padre_idx           ON mensaje (mensaje_padre_id);


-- =============================================================================
-- 8. FUNCIONES Y TRIGGERS
-- =============================================================================

-- 8.1 Al registrarse en Supabase Auth se crea su perfil en `usuario`.
-- El nickname se toma de los metadatos del signUp:
--   supabase.auth.signUp({ email, password, options: { data: { nickname: 'lysme' } } })
-- Si no viene, se genera uno provisional (lector_xxxxxxxxxx).
CREATE FUNCTION crear_perfil_usuario()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    INSERT INTO public.usuario (id, nickname)
    VALUES (
        NEW.id,
        COALESCE(
            NEW.raw_user_meta_data ->> 'nickname',
            'lector_' || substr(replace(NEW.id::text, '-', ''), 1, 10)
        )
    );
    RETURN NEW;
END;
$$;

CREATE TRIGGER al_registrar_usuario
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION crear_perfil_usuario();


-- 8.2 Cada hilo o mensaje nuevo actualiza la fecha del foro al que pertenece
CREATE FUNCTION actualizar_fecha_foro()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF TG_TABLE_NAME = 'hilo' THEN
        UPDATE public.foro SET fecha_ultima_actualizacion = now()
         WHERE id = NEW.foro_id;
    ELSE
        UPDATE public.foro SET fecha_ultima_actualizacion = now()
         WHERE id = (SELECT foro_id FROM public.hilo WHERE id = NEW.hilo_id);
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER hilo_actualiza_foro
    AFTER INSERT ON hilo
    FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_foro();

CREATE TRIGGER mensaje_actualiza_foro
    AFTER INSERT ON mensaje
    FOR EACH ROW EXECUTE FUNCTION actualizar_fecha_foro();


-- 8.3 El líder de un club nuevo queda inscrito automáticamente como miembro
CREATE FUNCTION inscribir_lider_club()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    IF NEW.lider_id IS NOT NULL THEN
        INSERT INTO public.miembro_club (club_lectura_id, usuario_id)
        VALUES (NEW.id, NEW.lider_id)
        ON CONFLICT DO NOTHING;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER club_inscribe_lider
    AFTER INSERT ON club_lectura
    FOR EACH ROW EXECUTE FUNCTION inscribir_lider_club();


-- 8.4 No se puede entrar a un club que ya llenó su cupo
CREATE FUNCTION validar_cupo_club()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
    v_cupo     integer;
    v_miembros integer;
BEGIN
    SELECT cupo_maximo INTO v_cupo
      FROM public.club_lectura WHERE id = NEW.club_lectura_id
       FOR UPDATE;                                   -- evita que dos entren al último cupo a la vez

    IF v_cupo IS NOT NULL THEN
        SELECT count(*) INTO v_miembros
          FROM public.miembro_club WHERE club_lectura_id = NEW.club_lectura_id;
        IF v_miembros >= v_cupo THEN
            RAISE EXCEPTION 'El club % ya alcanzó su cupo máximo (%)', NEW.club_lectura_id, v_cupo;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER miembro_valida_cupo
    BEFORE INSERT ON miembro_club
    FOR EACH ROW EXECUTE FUNCTION validar_cupo_club();


-- =============================================================================
-- 9. SEGURIDAD (Row Level Security)
--
-- En Supabase cualquier tabla del esquema public queda expuesta a la API con
-- la llave pública (anon). Sin RLS, cualquiera podría leer o borrar todo.
-- Con RLS activo, solo se permite lo que digan las políticas. El backend que
-- use la llave service_role se salta RLS.
-- =============================================================================

-- 9.1 Funciones auxiliares (SECURITY DEFINER para no chocar con el propio RLS)

CREATE FUNCTION es_admin()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.usuario
         WHERE id = (SELECT auth.uid()) AND rol = 'admin'
    );
$$;

-- ¿El usuario actual es la cuenta de este autor?
CREATE FUNCTION es_autor(p_autor_id bigint)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.autor
         WHERE id = p_autor_id AND usuario_id = (SELECT auth.uid())
    );
$$;

-- ¿El usuario actual es el autor de esta obra?
CREATE FUNCTION es_autor_de_obra(p_obra_id bigint)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1
          FROM public.obra o
          JOIN public.autor a ON a.id = o.autor_id
         WHERE o.id = p_obra_id AND a.usuario_id = (SELECT auth.uid())
    );
$$;

-- ¿El usuario actual es el autor del libro (de su obra)?
CREATE FUNCTION es_autor_de_libro(p_libro_id bigint)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1
          FROM public.libro l
          JOIN public.obra o  ON o.id = l.obra_id
          JOIN public.autor a ON a.id = o.autor_id
         WHERE l.id = p_libro_id AND a.usuario_id = (SELECT auth.uid())
    );
$$;

CREATE FUNCTION es_miembro_club(p_club_id bigint)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.miembro_club
         WHERE club_lectura_id = p_club_id AND usuario_id = (SELECT auth.uid())
    );
$$;

CREATE FUNCTION es_lider_club(p_club_id bigint)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.club_lectura
         WHERE id = p_club_id AND lider_id = (SELECT auth.uid())
    );
$$;

-- ¿El club es visible para el usuario actual? (público, o privado y es miembro)
CREATE FUNCTION club_visible(p_club_id bigint)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = ''
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.club_lectura c
         WHERE c.id = p_club_id
           AND (c.tipo = 'publico' OR public.es_miembro_club(c.id) OR public.es_admin())
    );
$$;


-- 9.2 Activar RLS en todas las tablas

ALTER TABLE genero_libro   ENABLE ROW LEVEL SECURITY;
ALTER TABLE editorial      ENABLE ROW LEVEL SECURITY;
ALTER TABLE categoria_foro ENABLE ROW LEVEL SECURITY;
ALTER TABLE usuario        ENABLE ROW LEVEL SECURITY;
ALTER TABLE autor          ENABLE ROW LEVEL SECURITY;
ALTER TABLE suscripcion    ENABLE ROW LEVEL SECURITY;
ALTER TABLE obra           ENABLE ROW LEVEL SECURITY;
ALTER TABLE libro          ENABLE ROW LEVEL SECURITY;
ALTER TABLE capitulo       ENABLE ROW LEVEL SECURITY;
ALTER TABLE resena         ENABLE ROW LEVEL SECURITY;
ALTER TABLE comentario     ENABLE ROW LEVEL SECURITY;
ALTER TABLE biblioteca     ENABLE ROW LEVEL SECURITY;
ALTER TABLE recomendacion  ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_lectura   ENABLE ROW LEVEL SECURITY;
ALTER TABLE miembro_club   ENABLE ROW LEVEL SECURITY;
ALTER TABLE plan_club      ENABLE ROW LEVEL SECURITY;
ALTER TABLE foro           ENABLE ROW LEVEL SECURITY;
ALTER TABLE hilo           ENABLE ROW LEVEL SECURITY;
ALTER TABLE mensaje        ENABLE ROW LEVEL SECURITY;


-- 9.3 Catálogos y foros: lectura pública, escritura solo admin

CREATE POLICY lectura_publica ON genero_libro   FOR SELECT USING (true);
CREATE POLICY admin_escribe   ON genero_libro   FOR ALL TO authenticated
    USING (es_admin()) WITH CHECK (es_admin());

CREATE POLICY lectura_publica ON editorial      FOR SELECT USING (true);
CREATE POLICY admin_escribe   ON editorial      FOR ALL TO authenticated
    USING (es_admin()) WITH CHECK (es_admin());

CREATE POLICY lectura_publica ON categoria_foro FOR SELECT USING (true);
CREATE POLICY admin_escribe   ON categoria_foro FOR ALL TO authenticated
    USING (es_admin()) WITH CHECK (es_admin());

CREATE POLICY lectura_publica ON foro           FOR SELECT USING (true);
CREATE POLICY admin_escribe   ON foro           FOR ALL TO authenticated
    USING (es_admin()) WITH CHECK (es_admin());


-- 9.4 usuario: perfiles públicos; cada quien edita el suyo.
-- El rol NO se puede cambiar desde la API (evita que alguien se vuelva admin):
-- solo se concede UPDATE sobre nickname y foto_perfil.

CREATE POLICY lectura_publica ON usuario FOR SELECT USING (true);
CREATE POLICY edita_propio    ON usuario FOR UPDATE TO authenticated
    USING (id = (SELECT auth.uid())) WITH CHECK (id = (SELECT auth.uid()));

REVOKE UPDATE ON usuario FROM authenticated, anon;
GRANT  UPDATE (nickname, foto_perfil) ON usuario TO authenticated;


-- 9.5 autor: público; un usuario puede crear su ficha de autor y editarla

CREATE POLICY lectura_publica ON autor FOR SELECT USING (true);
CREATE POLICY crea_propio     ON autor FOR INSERT TO authenticated
    WITH CHECK (usuario_id = (SELECT auth.uid()) OR es_admin());
CREATE POLICY edita_propio    ON autor FOR UPDATE TO authenticated
    USING (usuario_id = (SELECT auth.uid()) OR es_admin())
    WITH CHECK (usuario_id = (SELECT auth.uid()) OR es_admin());
CREATE POLICY admin_borra     ON autor FOR DELETE TO authenticated
    USING (es_admin());


-- 9.6 obra / libro / capitulo: el autor gestiona lo suyo.
-- Los libros en borrador (y sus capítulos) solo los ve su autor.

CREATE POLICY lectura_publica ON obra FOR SELECT USING (true);
CREATE POLICY autor_escribe   ON obra FOR ALL TO authenticated
    USING (es_autor(autor_id) OR es_admin())
    WITH CHECK (es_autor(autor_id) OR es_admin());

CREATE POLICY lectura_publicados ON libro FOR SELECT
    USING (estado = 'publicado' OR es_autor_de_obra(obra_id) OR es_admin());
CREATE POLICY autor_escribe      ON libro FOR ALL TO authenticated
    USING (es_autor_de_obra(obra_id) OR es_admin())
    WITH CHECK (es_autor_de_obra(obra_id) OR es_admin());

-- El SELECT sobre libro ya filtra por su propio RLS (solo publicados o propios)
CREATE POLICY lectura_si_libro_visible ON capitulo FOR SELECT
    USING (EXISTS (SELECT 1 FROM libro l WHERE l.id = capitulo.libro_id));
CREATE POLICY autor_escribe            ON capitulo FOR ALL TO authenticated
    USING (es_autor_de_libro(libro_id) OR es_admin())
    WITH CHECK (es_autor_de_libro(libro_id) OR es_admin());


-- 9.7 Contenido de usuarios (reseñas, comentarios, hilos, mensajes):
-- todos leen, cada uno escribe lo suyo, el admin modera (borra).

CREATE POLICY lectura_publica ON resena FOR SELECT USING (true);
CREATE POLICY crea_propio     ON resena FOR INSERT TO authenticated
    WITH CHECK (usuario_id = (SELECT auth.uid()));
CREATE POLICY edita_propio    ON resena FOR UPDATE TO authenticated
    USING (usuario_id = (SELECT auth.uid())) WITH CHECK (usuario_id = (SELECT auth.uid()));
CREATE POLICY borra_propio    ON resena FOR DELETE TO authenticated
    USING (usuario_id = (SELECT auth.uid()) OR es_admin());

CREATE POLICY lectura_publica ON comentario FOR SELECT USING (true);
CREATE POLICY crea_propio     ON comentario FOR INSERT TO authenticated
    WITH CHECK (usuario_id = (SELECT auth.uid()));
CREATE POLICY edita_propio    ON comentario FOR UPDATE TO authenticated
    USING (usuario_id = (SELECT auth.uid())) WITH CHECK (usuario_id = (SELECT auth.uid()));
CREATE POLICY borra_propio    ON comentario FOR DELETE TO authenticated
    USING (usuario_id = (SELECT auth.uid()) OR es_admin());

CREATE POLICY lectura_publica ON hilo FOR SELECT USING (true);
CREATE POLICY crea_propio     ON hilo FOR INSERT TO authenticated
    WITH CHECK (usuario_id = (SELECT auth.uid()));
CREATE POLICY edita_propio    ON hilo FOR UPDATE TO authenticated
    USING (usuario_id = (SELECT auth.uid())) WITH CHECK (usuario_id = (SELECT auth.uid()));
CREATE POLICY borra_propio    ON hilo FOR DELETE TO authenticated
    USING (usuario_id = (SELECT auth.uid()) OR es_admin());

CREATE POLICY lectura_publica ON mensaje FOR SELECT USING (true);
CREATE POLICY crea_propio     ON mensaje FOR INSERT TO authenticated
    WITH CHECK (usuario_id = (SELECT auth.uid()));
CREATE POLICY edita_propio    ON mensaje FOR UPDATE TO authenticated
    USING (usuario_id = (SELECT auth.uid())) WITH CHECK (usuario_id = (SELECT auth.uid()));
CREATE POLICY borra_propio    ON mensaje FOR DELETE TO authenticated
    USING (usuario_id = (SELECT auth.uid()) OR es_admin());


-- 9.8 Datos personales: suscripciones (públicas, para contar seguidores),
-- biblioteca (privada) y recomendaciones (solo quien envía y quien recibe).

CREATE POLICY lectura_publica ON suscripcion FOR SELECT USING (true);
CREATE POLICY gestiona_propio ON suscripcion FOR ALL TO authenticated
    USING (usuario_id = (SELECT auth.uid())) WITH CHECK (usuario_id = (SELECT auth.uid()));

CREATE POLICY gestiona_propio ON biblioteca FOR ALL TO authenticated
    USING (usuario_id = (SELECT auth.uid())) WITH CHECK (usuario_id = (SELECT auth.uid()));

CREATE POLICY ve_propias      ON recomendacion FOR SELECT TO authenticated
    USING ((SELECT auth.uid()) IN (usuario_recomienda_id, usuario_recibe_id));
CREATE POLICY envia           ON recomendacion FOR INSERT TO authenticated
    WITH CHECK (usuario_recomienda_id = (SELECT auth.uid()));
CREATE POLICY responde        ON recomendacion FOR UPDATE TO authenticated     -- aceptar / rechazar
    USING (usuario_recibe_id = (SELECT auth.uid()))
    WITH CHECK (usuario_recibe_id = (SELECT auth.uid()));
CREATE POLICY borra_enviada   ON recomendacion FOR DELETE TO authenticated
    USING (usuario_recomienda_id = (SELECT auth.uid()));

-- Quien recibe solo puede cambiar `aceptada`, no el mensaje ni el libro
REVOKE UPDATE ON recomendacion FROM authenticated, anon;
GRANT  UPDATE (aceptada) ON recomendacion TO authenticated;


-- 9.9 Clubes: los públicos los ve cualquiera, los privados solo sus miembros.
-- El líder administra el club, su plan de lectura y puede sacar miembros.

CREATE POLICY lectura_si_visible ON club_lectura FOR SELECT
    USING (tipo = 'publico' OR es_miembro_club(id) OR es_admin());
CREATE POLICY crea_propio        ON club_lectura FOR INSERT TO authenticated
    WITH CHECK (creado_por_id = (SELECT auth.uid()) AND lider_id = (SELECT auth.uid()));
CREATE POLICY lider_edita        ON club_lectura FOR UPDATE TO authenticated
    USING (lider_id = (SELECT auth.uid()) OR es_admin())
    WITH CHECK (lider_id = (SELECT auth.uid()) OR es_admin());
CREATE POLICY lider_borra        ON club_lectura FOR DELETE TO authenticated
    USING (lider_id = (SELECT auth.uid()) OR es_admin());

CREATE POLICY lectura_si_visible ON miembro_club FOR SELECT
    USING (club_visible(club_lectura_id));
-- Uno mismo se une a un club público; a un privado lo agrega el líder
CREATE POLICY unirse             ON miembro_club FOR INSERT TO authenticated
    WITH CHECK (
        (usuario_id = (SELECT auth.uid())
            AND EXISTS (SELECT 1 FROM club_lectura c
                         WHERE c.id = club_lectura_id AND c.tipo = 'publico'))
        OR es_lider_club(club_lectura_id)
    );
CREATE POLICY salir_o_expulsar   ON miembro_club FOR DELETE TO authenticated
    USING (usuario_id = (SELECT auth.uid()) OR es_lider_club(club_lectura_id) OR es_admin());

CREATE POLICY lectura_si_visible ON plan_club FOR SELECT
    USING (club_visible(club_lectura_id));
CREATE POLICY lider_escribe      ON plan_club FOR ALL TO authenticated
    USING (es_lider_club(club_lectura_id) OR es_admin())
    WITH CHECK (es_lider_club(club_lectura_id) OR es_admin());


-- =============================================================================
-- 10. DATOS INICIALES
-- =============================================================================

INSERT INTO genero_libro (nombre) VALUES
    ('Fantasía'), ('Ciencia ficción'), ('Romance'), ('Misterio'), ('Terror'),
    ('Novela histórica'), ('Aventura'), ('Poesía'), ('Drama'), ('Juvenil'),
    ('No ficción'), ('Biografía');

INSERT INTO categoria_foro (nombre) VALUES
    ('General'), ('Recomendaciones'), ('Escritura creativa'),
    ('Clubes de lectura'), ('Géneros'), ('Ayuda y sugerencias');

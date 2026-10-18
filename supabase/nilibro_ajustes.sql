-- =============================================================================
-- Nilibro — Ajustes al esquema (2026-10-17)
--
-- Correr en el SQL Editor de Supabase DESPUÉS de nilibro.sql. No modifica el
-- archivo original: agrega lo que faltaba frente a los requerimientos del
-- documento de diseño (Nilibro Semana 5).
--
--   1. Favoritos en la biblioteca personal          (RF-04)
--   2. Conversación dentro de cada club             (RF-09)
--   3. Reportes de contenido para moderación        (RF-10)
--   4. Buckets de Storage y sus políticas           (portadas, fotos, PDFs)
-- =============================================================================


-- =============================================================================
-- 1. FAVORITOS (RF-04: "marcar favoritos")
-- =============================================================================

ALTER TABLE biblioteca
    ADD COLUMN favorito boolean NOT NULL DEFAULT false;


-- =============================================================================
-- 2. MENSAJES DE CLUB (RF-09: "conversar dentro del club")
--
-- Los hilos y mensajes de foro cuelgan de `foro`; los clubes necesitan su
-- propia conversación, visible solo para sus miembros.
-- =============================================================================

CREATE TABLE mensaje_club (
    id                bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    club_lectura_id   bigint NOT NULL REFERENCES club_lectura (id) ON DELETE CASCADE,
    usuario_id        uuid   NOT NULL DEFAULT auth.uid()
                      REFERENCES usuario (id) ON DELETE CASCADE,
    contenido         text   NOT NULL CHECK (length(trim(contenido)) > 0),
    fecha             timestamptz NOT NULL DEFAULT now(),
    mensaje_padre_id  bigint REFERENCES mensaje_club (id) ON DELETE CASCADE
);

CREATE INDEX mensaje_club_club_idx    ON mensaje_club (club_lectura_id);
CREATE INDEX mensaje_club_usuario_idx ON mensaje_club (usuario_id);
CREATE INDEX mensaje_club_padre_idx   ON mensaje_club (mensaje_padre_id);

ALTER TABLE mensaje_club ENABLE ROW LEVEL SECURITY;

-- Solo los miembros leen y escriben; el líder y el admin moderan
CREATE POLICY lectura_miembros ON mensaje_club FOR SELECT TO authenticated
    USING (es_miembro_club(club_lectura_id) OR es_admin());
CREATE POLICY miembro_escribe  ON mensaje_club FOR INSERT TO authenticated
    WITH CHECK (usuario_id = (SELECT auth.uid()) AND es_miembro_club(club_lectura_id));
CREATE POLICY edita_propio     ON mensaje_club FOR UPDATE TO authenticated
    USING (usuario_id = (SELECT auth.uid())) WITH CHECK (usuario_id = (SELECT auth.uid()));
CREATE POLICY borra_moderado   ON mensaje_club FOR DELETE TO authenticated
    USING (usuario_id = (SELECT auth.uid()) OR es_lider_club(club_lectura_id) OR es_admin());


-- =============================================================================
-- 3. REPORTES (RF-10: "reportar contenido inapropiado para su moderación")
--
-- Un reporte apunta exactamente a UNO de los contenidos que escriben los
-- usuarios. FKs separadas en lugar de un id genérico para no perder la
-- integridad referencial.
-- =============================================================================

CREATE TABLE reporte (
    id               bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    usuario_id       uuid   NOT NULL DEFAULT auth.uid()
                     REFERENCES usuario (id) ON DELETE CASCADE,   -- quien reporta
    mensaje_id       bigint REFERENCES mensaje (id)      ON DELETE CASCADE,
    comentario_id    bigint REFERENCES comentario (id)   ON DELETE CASCADE,
    resena_id        bigint REFERENCES resena (id)       ON DELETE CASCADE,
    mensaje_club_id  bigint REFERENCES mensaje_club (id) ON DELETE CASCADE,
    motivo           text   NOT NULL CHECK (length(trim(motivo)) > 0),
    estado           text   NOT NULL DEFAULT 'pendiente'
                     CHECK (estado IN ('pendiente', 'revisado', 'descartado')),
    fecha            timestamptz NOT NULL DEFAULT now(),
    CHECK (num_nonnulls(mensaje_id, comentario_id, resena_id, mensaje_club_id) = 1)
);

CREATE INDEX reporte_usuario_idx      ON reporte (usuario_id);
CREATE INDEX reporte_mensaje_idx      ON reporte (mensaje_id);
CREATE INDEX reporte_comentario_idx   ON reporte (comentario_id);
CREATE INDEX reporte_resena_idx       ON reporte (resena_id);
CREATE INDEX reporte_mensaje_club_idx ON reporte (mensaje_club_id);
CREATE INDEX reporte_pendientes_idx   ON reporte (estado) WHERE estado = 'pendiente';

ALTER TABLE reporte ENABLE ROW LEVEL SECURITY;

-- Cada quien crea y ve sus reportes; solo el admin los revisa y cierra
CREATE POLICY crea_propio  ON reporte FOR INSERT TO authenticated
    WITH CHECK (usuario_id = (SELECT auth.uid()));
CREATE POLICY ve_propios   ON reporte FOR SELECT TO authenticated
    USING (usuario_id = (SELECT auth.uid()) OR es_admin());
CREATE POLICY admin_revisa ON reporte FOR UPDATE TO authenticated
    USING (es_admin()) WITH CHECK (es_admin());
CREATE POLICY admin_borra  ON reporte FOR DELETE TO authenticated
    USING (es_admin());


-- =============================================================================
-- 4. STORAGE
--
-- Tres buckets públicos: cualquiera puede ver una portada, una foto de perfil
-- o el PDF de un libro publicado (todos los usuarios acceden a todo lo
-- publicado). Para subir, cada usuario escribe solo en su carpeta
-- `<su uuid>/...`; el admin puede escribir en cualquier parte (catálogo).
--
-- La ruta que se guarda en la BD (libro.portada, libro.pdf,
-- usuario.foto_perfil) es la ruta del objeto dentro del bucket.
-- =============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) VALUES
    ('portadas',     'portadas',     true,  5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
    ('fotos_perfil', 'fotos_perfil', true,  2097152, ARRAY['image/jpeg', 'image/png', 'image/webp']),
    ('pdfs',         'pdfs',         true, 52428800, ARRAY['application/pdf'])
ON CONFLICT (id) DO NOTHING;

CREATE POLICY nilibro_sube_propio ON storage.objects FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id IN ('portadas', 'fotos_perfil', 'pdfs')
        AND ((storage.foldername(name))[1] = (SELECT auth.uid())::text OR public.es_admin())
    );

CREATE POLICY nilibro_lee_propio ON storage.objects FOR SELECT TO authenticated
    USING (
        bucket_id IN ('portadas', 'fotos_perfil', 'pdfs')
        AND ((storage.foldername(name))[1] = (SELECT auth.uid())::text OR public.es_admin())
    );

CREATE POLICY nilibro_cambia_propio ON storage.objects FOR UPDATE TO authenticated
    USING (
        bucket_id IN ('portadas', 'fotos_perfil', 'pdfs')
        AND ((storage.foldername(name))[1] = (SELECT auth.uid())::text OR public.es_admin())
    );

CREATE POLICY nilibro_borra_propio ON storage.objects FOR DELETE TO authenticated
    USING (
        bucket_id IN ('portadas', 'fotos_perfil', 'pdfs')
        AND ((storage.foldername(name))[1] = (SELECT auth.uid())::text OR public.es_admin())
    );


-- =============================================================================
-- 5. ADMINISTRADOR (manual, una sola vez)
--
-- El rol no se puede cambiar desde la API. Después de registrarte en la app,
-- conviértete en admin desde el SQL Editor (cambia el nickname):
--
--   UPDATE usuario SET rol = 'admin' WHERE lower(nickname) = 'tu_nickname';
-- =============================================================================

# Nilibro

Plataforma digital de lectura y comunidad literaria. Proyecto de Emprendimiento de Base Tecnológica (Politécnico Grancolombiano, 2026-02).

Stack: Vite + React + `supabase-js` (Auth, Postgres con RLS, Storage), desplegado en Vercel.

## Supabase

En el SQL Editor, en este orden:

1. `supabase/nilibro.sql`: esquema completo, RLS, triggers y catálogos.
2. `supabase/nilibro_ajustes.sql`: favoritos, mensajes de club, reportes y buckets de Storage.

Luego, en **Authentication → Sign In / Providers**, apagar **Confirm email**.

Para tener un administrador (puede cargar libros del catálogo con autores sin cuenta y su PDF): regístrate en la app y corre en el SQL Editor:

```sql
UPDATE usuario SET rol = 'admin' WHERE lower(nickname) = 'tu_nickname';
```

## Local

El proyecto vive en D: pero se corre desde WSL (en Windows no hay Node):

```bash
cd "/mnt/d/Bibliotecas/Documentos/Estudios/Poli/2026-02/Emprendimiento de Base Tecnológica/nilibro"
cp .env.example .env    # y llena las dos variables
npm install
npm run dev             # http://localhost:5173
```

## Pantallas y requerimientos

| Pantalla | Ruta | Requerimientos |
|---|---|---|
| Inicio de sesión y registro | `/` sin sesión | RF-01 |
| Inicio | `/` | RF-04, RF-07 (recomendaciones por género) |
| Catálogo y búsqueda | `/buscar` | RF-02 (título, autor y género) |
| Detalle del libro | `/libro/:id` | RF-06 (reseñas), RF-08 (seguir autor), RF-10 (reportar) |
| Lector | `/leer/:id` | RF-03 (tamaño de letra, modo oscuro, marcador), RF-06 (comentarios) |
| Mi biblioteca | `/biblioteca` | RF-04 (estantes y favoritos) |
| Publicar / editar obra | `/publicar`, `/publicar/:id` | RF-05 (genera el PDF desde los capítulos) |
| Comunidad: autores | `/comunidad` | RF-08 |
| Perfil | `/perfil` | RF-01, RF-05 (mis obras: abrir, retirar, eliminar) |

Clubes y foros (RF-09, RF-10) ya tienen tablas y RLS; sus pantallas quedan para la siguiente fase.

import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!url || !anonKey) {
  throw new Error('Faltan VITE_SUPABASE_URL o VITE_SUPABASE_ANON_KEY (revisa el .env)')
}

export const supabase = createClient(url, anonKey)

// URL pública de un archivo guardado en un bucket (portadas, fotos_perfil, pdfs)
export function urlPublica(bucket, ruta) {
  if (!ruta) return null
  return supabase.storage.from(bucket).getPublicUrl(ruta).data.publicUrl
}

// Sube un archivo a la carpeta del usuario y devuelve su ruta dentro del bucket
export async function subirArchivo(bucket, usuarioId, archivo, nombre) {
  const extension = archivo.name?.split('.').pop() || 'pdf'
  const ruta = `${usuarioId}/${nombre}-${Date.now()}.${extension}`
  const { error } = await supabase.storage.from(bucket).upload(ruta, archivo, {
    contentType: archivo.type || 'application/pdf',
  })
  if (error) throw error
  return ruta
}

// Traduce los errores más comunes de Supabase/Postgres a algo legible
export function mensajeError(error) {
  if (!error) return ''
  if (error.code === '23505') return 'Ese valor ya existe (por ejemplo, el nickname ya está en uso).'
  if (error.code === '23514') return 'Algún dato no cumple las reglas de la base de datos.'
  if (error.code === '42501') return 'No tienes permiso para hacer eso.'
  if (error.message?.includes('Database error saving new user')) {
    return 'No se pudo crear la cuenta. Revisa que el nickname no esté en uso.'
  }
  if (error.message === 'Invalid login credentials') return 'Correo o contraseña incorrectos.'
  return error.message
}

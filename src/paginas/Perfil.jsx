import { useCallback, useEffect, useState } from 'react'
import { Link } from 'react-router'
import { mensajeError, subirArchivo, supabase, urlPublica } from '../supabase.js'
import { useSesion } from '../sesion.jsx'
import { LIBRO_CAMPOS, NICKNAME_VALIDO } from '../datos.js'
import { Pestanas, Portada } from '../componentes/Libro.jsx'

const PESTANAS = { obras: 'Mis obras', resenas: 'Reseñas', clubes: 'Clubes' }

export default function Perfil() {
  const { usuarioId, perfil, recargarPerfil } = useSesion()
  const [pestana, setPestana] = useState('obras')
  const [obras, setObras] = useState([])
  const [resenas, setResenas] = useState([])
  const [cifras, setCifras] = useState({ leidos: 0, seguidores: 0, siguiendo: 0 })
  const [editando, setEditando] = useState(false)
  const [nickname, setNickname] = useState('')
  const [foto, setFoto] = useState(null)
  const [error, setError] = useState('')

  const cargar = useCallback(async () => {
    const { data: autor } = await supabase.from('autor').select('id').eq('usuario_id', usuarioId).maybeSingle()

    const [leidos, siguiendo, seguidores, misObras, misResenas] = await Promise.all([
      supabase.from('biblioteca').select('*', { count: 'exact', head: true }).eq('estado_lectura', 'leido'),
      supabase.from('suscripcion').select('*', { count: 'exact', head: true }).eq('usuario_id', usuarioId),
      autor
        ? supabase.from('suscripcion').select('*', { count: 'exact', head: true }).eq('autor_id', autor.id)
        : Promise.resolve({ count: 0 }),
      autor
        ? supabase.from('libro').select(LIBRO_CAMPOS).eq('obra.autor_id', autor.id).order('id', { ascending: false })
        : Promise.resolve({ data: [] }),
      supabase.from('resena').select('id, calificacion, texto, libro(id, obra(titulo))').eq('usuario_id', usuarioId).order('fecha', { ascending: false }),
    ])
    setCifras({ leidos: leidos.count ?? 0, siguiendo: siguiendo.count ?? 0, seguidores: seguidores.count ?? 0 })
    setObras(misObras.data ?? [])
    setResenas(misResenas.data ?? [])
  }, [usuarioId])

  useEffect(() => {
    void cargar()
  }, [cargar])

  async function guardarPerfil(e) {
    e.preventDefault()
    setError('')
    if (!NICKNAME_VALIDO.test(nickname)) return setError('El nickname debe tener de 3 a 30 letras, números, punto o guion bajo.')
    try {
      const cambios = { nickname }
      if (foto) cambios.foto_perfil = await subirArchivo('fotos_perfil', usuarioId, foto, 'perfil')
      const { error } = await supabase.from('usuario').update(cambios).eq('id', usuarioId)
      if (error) throw error
      await recargarPerfil()
      setEditando(false)
    } catch (err) {
      setError(mensajeError(err))
    }
  }

  // "Retirar" una obra = devolverla a borrador; deja de verse para los demás
  async function retirar(libroId) {
    const { error } = await supabase.from('libro').update({ estado: 'borrador' }).eq('id', libroId)
    if (error) return setError(mensajeError(error))
    await cargar()
  }

  // DELETE: borrar la obra se lleva en cascada su libro, capítulos y comentarios
  async function eliminar(libro) {
    if (!confirm(`¿Eliminar "${libro.obra.titulo}"? No se puede deshacer.`)) return
    const { error } = await supabase.from('obra').delete().eq('id', libro.obra.id)
    if (error) return setError(mensajeError(error))
    await cargar()
  }

  const urlFoto = urlPublica('fotos_perfil', perfil?.foto_perfil)

  return (
    <section>
      <h1>Mi perfil</h1>
      <div className="perfil">
        <div className="tarjeta perfil-datos">
          <div className="avatar grande">
            {urlFoto ? <img src={urlFoto} alt="" /> : perfil?.nickname?.[0]?.toUpperCase()}
          </div>
          <strong>{perfil?.nickname}</strong>
          <span className="suave">@{perfil?.nickname}{perfil?.rol === 'admin' && ' · admin'}</span>

          <div className="cifras">
            <div><strong>{cifras.leidos}</strong><span>Libros leídos</span></div>
            <div><strong>{cifras.seguidores}</strong><span>Seguidores</span></div>
            <div><strong>{cifras.siguiendo}</strong><span>Siguiendo</span></div>
          </div>

          {editando ? (
            <form onSubmit={guardarPerfil} className="columna">
              <input value={nickname} onChange={(e) => setNickname(e.target.value)} aria-label="Nickname" />
              <label className="boton secundario">
                {foto ? foto.name : 'Cambiar foto'}
                <input type="file" accept="image/jpeg,image/png,image/webp" hidden onChange={(e) => setFoto(e.target.files[0] ?? null)} />
              </label>
              <button type="submit">Guardar</button>
              <button type="button" className="secundario" onClick={() => setEditando(false)}>Cancelar</button>
            </form>
          ) : (
            <button onClick={() => { setNickname(perfil?.nickname ?? ''); setEditando(true) }}>Editar perfil</button>
          )}
          <button className="secundario" onClick={() => supabase.auth.signOut()}>Cerrar sesión</button>
          {error && <p className="error">{error}</p>}
        </div>

        <div className="crece">
          <Pestanas opciones={PESTANAS} activa={pestana} onCambio={setPestana} />

          {pestana === 'obras' && (
            <div className="lista">
              {obras.length === 0 && <p className="suave">Todavía no has publicado obras.</p>}
              {obras.map((l) => (
                <div key={l.id} className="tarjeta fila">
                  <Portada libro={l} className="mini" />
                  <div className="crece">
                    <Link to={`/libro/${l.id}`}><strong>{l.obra.titulo}</strong></Link>
                    <p className="suave">{l.obra.genero_libro?.nombre} · {l.estado === 'publicado' ? 'Publicada' : 'Borrador'}</p>
                  </div>
                  <div className="acciones">
                    <Link to={`/publicar/${l.id}`} className="boton secundario">Abrir</Link>
                    {l.estado === 'publicado' && <button className="secundario" onClick={() => retirar(l.id)}>Retirar</button>}
                    <button className="peligro" onClick={() => eliminar(l)}>Eliminar</button>
                  </div>
                </div>
              ))}
              <Link to="/publicar" className="boton secundario ancho">+ Publicar una obra</Link>
            </div>
          )}

          {pestana === 'resenas' && (
            <div className="lista">
              {resenas.length === 0 && <p className="suave">Todavía no has escrito reseñas.</p>}
              {resenas.map((r) => (
                <div key={r.id} className="tarjeta">
                  <Link to={`/libro/${r.libro.id}`}><strong>{r.libro.obra.titulo}</strong></Link>{' '}
                  <span className="estrellas">{'★'.repeat(r.calificacion)}{'☆'.repeat(5 - r.calificacion)}</span>
                  {r.texto && <p>{r.texto}</p>}
                </div>
              ))}
            </div>
          )}

          {pestana === 'clubes' && <p className="suave tarjeta">Los clubes de lectura llegan en la siguiente fase del proyecto.</p>}
        </div>
      </div>
    </section>
  )
}

import { useCallback, useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router'
import { mensajeError, supabase, urlPublica } from '../supabase.js'
import { useSesion } from '../sesion.jsx'
import { LIBRO_CAMPOS } from '../datos.js'
import { Pestanas, Portada } from '../componentes/Libro.jsx'

const estrellas = (n) => '★'.repeat(n) + '☆'.repeat(5 - n)

export default function Detalle() {
  const { id } = useParams()
  const { usuarioId } = useSesion()
  const navegar = useNavigate()

  const [libro, setLibro] = useState(null)
  const [enBiblioteca, setEnBiblioteca] = useState(false)
  const [sigue, setSigue] = useState(false)
  const [resenas, setResenas] = useState([])
  const [pestana, setPestana] = useState('sinopsis')
  const [calificacion, setCalificacion] = useState(5)
  const [texto, setTexto] = useState('')
  const [error, setError] = useState('')

  const cargar = useCallback(async () => {
    const { data, error } = await supabase
      .from('libro')
      .select(`${LIBRO_CAMPOS}, capitulo(count)`)
      .eq('id', id)
      .maybeSingle()
    if (error) return setError(mensajeError(error))
    if (!data) return setError('Este libro no existe o todavía es un borrador.')
    setLibro(data)

    const [biblioteca, suscripcion, listaResenas] = await Promise.all([
      supabase.from('biblioteca').select('libro_id').eq('libro_id', id).maybeSingle(),
      supabase.from('suscripcion').select('autor_id').eq('usuario_id', usuarioId).eq('autor_id', data.obra.autor.id).maybeSingle(),
      supabase.from('resena').select('id, texto, calificacion, fecha, usuario_id, usuario(nickname)').eq('libro_id', id).order('fecha', { ascending: false }),
    ])
    setEnBiblioteca(!!biblioteca.data)
    setSigue(!!suscripcion.data)
    setResenas(listaResenas.data ?? [])

    const mia = listaResenas.data?.find((r) => r.usuario_id === usuarioId)
    if (mia) {
      setCalificacion(mia.calificacion)
      setTexto(mia.texto ?? '')
    }
  }, [id, usuarioId])

  useEffect(() => {
    void cargar()
  }, [cargar])

  async function ejecutar(consulta) {
    setError('')
    const { error } = await consulta
    if (error) return setError(mensajeError(error))
    await cargar()
  }

  const alternarBiblioteca = () =>
    ejecutar(
      enBiblioteca
        ? supabase.from('biblioteca').delete().eq('libro_id', id).eq('usuario_id', usuarioId)
        : supabase.from('biblioteca').insert({ usuario_id: usuarioId, libro_id: Number(id) }),
    )

  const alternarSeguir = () =>
    ejecutar(
      sigue
        ? supabase.from('suscripcion').delete().eq('autor_id', libro.obra.autor.id).eq('usuario_id', usuarioId)
        : supabase.from('suscripcion').insert({ usuario_id: usuarioId, autor_id: libro.obra.autor.id }),
    )

  function guardarResena(e) {
    e.preventDefault()
    return ejecutar(
      supabase
        .from('resena')
        .upsert(
          { libro_id: Number(id), usuario_id: usuarioId, calificacion, texto: texto.trim() || null },
          { onConflict: 'usuario_id,libro_id' },
        ),
    )
  }

  function reportar(resenaId) {
    const motivo = prompt('¿Por qué reportas esta reseña?')
    if (!motivo?.trim()) return
    void ejecutar(supabase.from('reporte').insert({ resena_id: resenaId, motivo: motivo.trim() }))
    alert('Gracias, un administrador lo revisará.')
  }

  if (error && !libro) return <p className="error">{error}</p>
  if (!libro) return <p>Cargando…</p>

  const { obra } = libro
  const esMio = obra.autor.usuario_id === usuarioId
  const totalCapitulos = libro.capitulo?.[0]?.count ?? 0
  const pdf = urlPublica('pdfs', libro.pdf)
  const miResena = resenas.some((r) => r.usuario_id === usuarioId)

  return (
    <section>
      <button className="enlace" onClick={() => navegar(-1)}>← Volver</button>

      <div className="detalle">
        <div className="detalle-portada">
          <Portada libro={libro} />
          <Link to={`/leer/${libro.id}`} className="boton">Leer ahora</Link>
          <button className="secundario" onClick={alternarBiblioteca}>
            {enBiblioteca ? 'Quitar de mi biblioteca' : 'Agregar a mi biblioteca'}
          </button>
          {pdf && <a href={pdf} target="_blank" rel="noreferrer" className="boton secundario">Descargar PDF</a>}
          {esMio && <Link to={`/publicar/${libro.id}`} className="boton secundario">Editar obra</Link>}
        </div>

        <div className="detalle-info">
          <h1>{obra.titulo}</h1>
          <p className="suave">
            {obra.autor.nombre} · {obra.genero_libro?.nombre}
            {libro.paginas && ` · ${libro.paginas} páginas`} · {totalCapitulos} capítulos
            {libro.estado === 'borrador' && ' · Borrador (solo tú lo ves)'}
          </p>

          <Pestanas opciones={{ sinopsis: 'Sinopsis', resenas: `Reseñas (${resenas.length})` }} activa={pestana} onCambio={setPestana} />

          {pestana === 'sinopsis' ? (
            <p className="sinopsis">{obra.sinopsis || 'Esta obra no tiene sinopsis.'}</p>
          ) : (
            <>
              <form className="tarjeta resena-form" onSubmit={guardarResena}>
                <strong>{miResena ? 'Tu reseña' : 'Escribe una reseña'}</strong>
                <select value={calificacion} onChange={(e) => setCalificacion(Number(e.target.value))} aria-label="Calificación">
                  {[5, 4, 3, 2, 1].map((n) => (
                    <option key={n} value={n}>{estrellas(n)}</option>
                  ))}
                </select>
                <textarea rows={3} value={texto} onChange={(e) => setTexto(e.target.value)} placeholder="¿Qué te pareció?" />
                <div className="acciones">
                  <button type="submit">{miResena ? 'Actualizar' : 'Publicar reseña'}</button>
                  {miResena && (
                    <button
                      type="button"
                      className="peligro"
                      onClick={() => ejecutar(supabase.from('resena').delete().eq('libro_id', id).eq('usuario_id', usuarioId))}
                    >
                      Borrar
                    </button>
                  )}
                </div>
              </form>

              <h3>Reseñas de la comunidad</h3>
              {resenas.length === 0 && <p className="suave">Todavía no hay reseñas.</p>}
              {resenas.map((r) => (
                <div key={r.id} className="tarjeta resena">
                  <strong>{r.usuario?.nickname}</strong> <span className="estrellas">{estrellas(r.calificacion)}</span>
                  {r.texto && <p>{r.texto}</p>}
                  {r.usuario_id !== usuarioId && (
                    <button className="enlace pequeno" onClick={() => reportar(r.id)}>Reportar</button>
                  )}
                </div>
              ))}
            </>
          )}

          {!esMio && (
            <button className="secundario" onClick={alternarSeguir}>
              {sigue ? 'Dejar de seguir al autor' : 'Seguir autor'}
            </button>
          )}
          {error && <p className="error">{error}</p>}
        </div>
      </div>
    </section>
  )
}

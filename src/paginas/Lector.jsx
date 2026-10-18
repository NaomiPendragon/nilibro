import { useCallback, useEffect, useState } from 'react'
import { Link, useParams } from 'react-router'
import { mensajeError, supabase, urlPublica } from '../supabase.js'
import { useSesion } from '../sesion.jsx'

const TAMANOS = [15, 17, 19, 22]

// Preferencias de lectura del navegador (tamaño de letra y modo oscuro)
function leerPreferencia(clave, porDefecto) {
  try {
    const valor = localStorage.getItem(clave)
    return valor === null ? porDefecto : JSON.parse(valor)
  } catch {
    return porDefecto
  }
}
function guardarPreferencia(clave, valor) {
  try {
    localStorage.setItem(clave, JSON.stringify(valor))
  } catch {
    // modo incógnito o almacenamiento bloqueado: se usa el valor por defecto
  }
}

export default function Lector() {
  const { id } = useParams()
  const { usuarioId } = useSesion()
  const [libro, setLibro] = useState(null)
  const [indice, setIndice] = useState(null)
  const [tamano, setTamano] = useState(() => leerPreferencia('lector-tamano', 1))
  const [oscuro, setOscuro] = useState(() => leerPreferencia('lector-oscuro', false))
  const [error, setError] = useState('')

  useEffect(() => {
    async function cargar() {
      const [{ data, error }, { data: entrada }] = await Promise.all([
        supabase
          .from('libro')
          .select('id, pdf, paginas, obra(titulo), capitulo(id, numero_capitulo, nombre, contenido, pagina_pdf)')
          .eq('id', id)
          .order('numero_capitulo', { referencedTable: 'capitulo' })
          .maybeSingle(),
        supabase.from('biblioteca').select('ultima_pagina_leida').eq('libro_id', id).maybeSingle(),
      ])
      if (error || !data) return setError(error ? mensajeError(error) : 'Libro no encontrado.')
      setLibro(data)

      // Retomar donde quedó: el último capítulo que empieza antes de la página guardada
      const pagina = entrada?.ultima_pagina_leida ?? 0
      const caps = data.capitulo.filter((c) => c.contenido?.trim())
      let inicio = 0
      caps.forEach((c, i) => {
        if ((c.pagina_pdf ?? c.numero_capitulo) <= pagina) inicio = i
      })
      setIndice(inicio)
    }
    void cargar()
  }, [id])

  const capitulos = libro?.capitulo.filter((c) => c.contenido?.trim()) ?? []
  const actual = indice !== null ? capitulos.at(indice) : null

  // Guarda el progreso (y agrega el libro a la biblioteca si no estaba)
  const guardarProgreso = useCallback(
    async (capitulo, terminado) => {
      await supabase.from('biblioteca').upsert(
        {
          usuario_id: usuarioId,
          libro_id: Number(id),
          ultima_pagina_leida: capitulo.pagina_pdf ?? capitulo.numero_capitulo,
          estado_lectura: terminado ? 'leido' : 'leyendo',
          fecha_ultima_lectura: new Date().toISOString(),
        },
        { onConflict: 'usuario_id,libro_id' },
      )
    },
    [id, usuarioId],
  )

  useEffect(() => {
    if (actual) void guardarProgreso(actual, false)
  }, [actual, guardarProgreso])

  function cambiarTamano() {
    const siguiente = (tamano + 1) % TAMANOS.length
    setTamano(siguiente)
    guardarPreferencia('lector-tamano', siguiente)
  }
  function alternarOscuro() {
    setOscuro(!oscuro)
    guardarPreferencia('lector-oscuro', !oscuro)
  }

  if (error) return <p className="error centro">{error}</p>
  if (!libro) return <p className="centro">Cargando…</p>

  const pdf = urlPublica('pdfs', libro.pdf)
  const progreso = capitulos.length ? Math.round(((indice + 1) / capitulos.length) * 100) : 0

  return (
    <div className={`lector ${oscuro ? 'oscuro' : ''}`}>
      <header className="lector-barra">
        <Link to={`/libro/${id}`} className="enlace">← {libro.obra.titulo}</Link>
        {capitulos.length > 0 && (
          <select value={indice ?? 0} onChange={(e) => setIndice(Number(e.target.value))} aria-label="Índice de capítulos">
            {capitulos.map((c, i) => (
              <option key={c.id} value={i}>
                Capítulo {c.numero_capitulo}{c.nombre ? `: ${c.nombre}` : ''}
              </option>
            ))}
          </select>
        )}
        <div className="acciones">
          <button className="secundario" onClick={cambiarTamano} title="Tamaño de letra">Aa</button>
          <button className="secundario" onClick={alternarOscuro}>{oscuro ? 'Modo claro' : 'Modo oscuro'}</button>
        </div>
      </header>

      {actual ? (
        <>
          <div className="progreso" aria-label={`${progreso}% leído`}>
            <div style={{ width: `${progreso}%` }} />
          </div>
          <article className="lector-texto" style={{ fontSize: TAMANOS.at(tamano) }}>
            <h1>Capítulo {actual.numero_capitulo}{actual.nombre ? `: ${actual.nombre}` : ''}</h1>
            {actual.contenido.split('\n').map((parrafo, i) => (parrafo.trim() ? <p key={i}>{parrafo}</p> : null))}
          </article>

          <nav className="lector-pie">
            <button className="secundario" disabled={indice === 0} onClick={() => setIndice(indice - 1)}>← Anterior</button>
            <span className="suave">{indice + 1} de {capitulos.length}</span>
            {indice < capitulos.length - 1 ? (
              <button onClick={() => setIndice(indice + 1)}>Siguiente →</button>
            ) : (
              <button onClick={() => guardarProgreso(actual, true)}>Terminar libro</button>
            )}
          </nav>

          <Comentarios capituloId={actual.id} usuarioId={usuarioId} />
        </>
      ) : pdf ? (
        // Libros del catálogo: solo tienen el PDF
        <iframe className="lector-pdf" src={pdf} title={libro.obra.titulo} />
      ) : (
        <p className="vacio">Este libro todavía no tiene contenido.</p>
      )}
    </div>
  )
}

// Comentarios del capítulo, con respuestas de un nivel (comentario_padre_id)
function Comentarios({ capituloId, usuarioId }) {
  const [comentarios, setComentarios] = useState([])
  const [texto, setTexto] = useState('')
  const [respondiendo, setRespondiendo] = useState(null)
  const [error, setError] = useState('')

  const cargar = useCallback(async () => {
    const { data } = await supabase
      .from('comentario')
      .select('id, comentario, fecha, usuario_id, comentario_padre_id, usuario(nickname)')
      .eq('capitulo_id', capituloId)
      .order('fecha')
    setComentarios(data ?? [])
  }, [capituloId])

  useEffect(() => {
    void cargar()
  }, [cargar])

  async function enviar(e) {
    e.preventDefault()
    setError('')
    const { error } = await supabase.from('comentario').insert({
      capitulo_id: capituloId,
      usuario_id: usuarioId,
      comentario: texto.trim(),
      comentario_padre_id: respondiendo?.id ?? null,
    })
    if (error) return setError(mensajeError(error))
    setTexto('')
    setRespondiendo(null)
    await cargar()
  }

  async function borrar(comentarioId) {
    await supabase.from('comentario').delete().eq('id', comentarioId)
    await cargar()
  }

  const raiz = comentarios.filter((c) => !c.comentario_padre_id)
  const respuestas = (padreId) => comentarios.filter((c) => c.comentario_padre_id === padreId)

  const tarjeta = (c) => (
    <div key={c.id} className="comentario">
      <strong>{c.usuario?.nickname}</strong>
      <p>{c.comentario}</p>
      <div className="acciones">
        {!c.comentario_padre_id && <button className="enlace pequeno" onClick={() => setRespondiendo(c)}>Responder</button>}
        {c.usuario_id === usuarioId && <button className="enlace pequeno" onClick={() => borrar(c.id)}>Borrar</button>}
      </div>
    </div>
  )

  return (
    <section className="comentarios">
      <h2>Comentarios del capítulo</h2>
      {raiz.length === 0 && <p className="suave">Sé la primera persona en comentar.</p>}
      {raiz.map((c) => (
        <div key={c.id}>
          {tarjeta(c)}
          <div className="respuestas">{respuestas(c.id).map(tarjeta)}</div>
        </div>
      ))}

      <form onSubmit={enviar} className="comentar">
        {respondiendo && (
          <p className="suave">
            Respondiendo a {respondiendo.usuario?.nickname}{' '}
            <button type="button" className="enlace pequeno" onClick={() => setRespondiendo(null)}>Cancelar</button>
          </p>
        )}
        <textarea rows={2} value={texto} onChange={(e) => setTexto(e.target.value)} placeholder="Escribe un comentario" required />
        <button type="submit">Comentar</button>
        {error && <p className="error">{error}</p>}
      </form>
    </section>
  )
}

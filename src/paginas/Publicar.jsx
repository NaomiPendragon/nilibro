import { useEffect, useState } from 'react'
import { useNavigate, useParams } from 'react-router'
import { mensajeError, subirArchivo, supabase, urlPublica } from '../supabase.js'
import { useSesion } from '../sesion.jsx'
import { generarPdf } from '../pdf.js'

const CAPITULO_VACIO = { nombre: '', contenido: '' }

// Devuelve el id del autor ligado a la cuenta; si no existe, lo crea con su nickname
async function autorPropio(usuarioId, nickname) {
  const { data } = await supabase.from('autor').select('id').eq('usuario_id', usuarioId).maybeSingle()
  if (data) return data.id
  const { data: nuevo, error } = await supabase
    .from('autor')
    .insert({ nombre: nickname, usuario_id: usuarioId })
    .select('id')
    .single()
  if (error) throw error
  return nuevo.id
}

// Catálogo (solo admin): autores sin cuenta, como Cervantes
async function autorCatalogo(nombre) {
  const { data } = await supabase.from('autor').select('id').is('usuario_id', null).ilike('nombre', nombre).maybeSingle()
  if (data) return data.id
  const { data: nuevo, error } = await supabase.from('autor').insert({ nombre }).select('id').single()
  if (error) throw error
  return nuevo.id
}

// Descarga la portada que ya estaba en el bucket, para meterla en el PDF
async function portadaGuardada(ruta) {
  if (!ruta) return null
  const respuesta = await fetch(urlPublica('portadas', ruta))
  return respuesta.ok ? respuesta.blob() : null
}

export default function Publicar() {
  const { libroId } = useParams()
  const { usuarioId, perfil } = useSesion()
  const navegar = useNavigate()
  const esAdmin = perfil?.rol === 'admin'

  const [generos, setGeneros] = useState([])
  const [libro, setLibro] = useState(null) // libro existente cuando se edita
  const [titulo, setTitulo] = useState('')
  const [generoId, setGeneroId] = useState('')
  const [sinopsis, setSinopsis] = useState('')
  const [portada, setPortada] = useState(null) // archivo nuevo
  const [capitulos, setCapitulos] = useState([])
  const [editando, setEditando] = useState(null) // índice del capítulo abierto
  const [autorExterno, setAutorExterno] = useState('') // solo admin
  const [pdfExterno, setPdfExterno] = useState(null) // solo admin
  const [error, setError] = useState('')
  const [guardando, setGuardando] = useState('')

  useEffect(() => {
    async function cargar() {
      const { data } = await supabase.from('genero_libro').select('id, nombre').order('nombre')
      setGeneros(data ?? [])
      if (!libroId) return

      const { data: existente, error } = await supabase
        .from('libro')
        .select('id, estado, portada, pdf, obra(id, titulo, sinopsis, genero_id, autor(nombre, usuario_id)), capitulo(numero_capitulo, nombre, contenido)')
        .eq('id', libroId)
        .order('numero_capitulo', { referencedTable: 'capitulo' })
        .single()
      if (error) return setError(mensajeError(error))
      setLibro(existente)
      setTitulo(existente.obra.titulo)
      setGeneroId(String(existente.obra.genero_id))
      setSinopsis(existente.obra.sinopsis ?? '')
      setCapitulos(existente.capitulo.map(({ nombre, contenido }) => ({ nombre: nombre ?? '', contenido: contenido ?? '' })))
      if (!existente.obra.autor.usuario_id) setAutorExterno(existente.obra.autor.nombre)
    }
    void cargar()
  }, [libroId])

  function cambiarCapitulo(i, campo, valor) {
    setCapitulos(capitulos.map((c, j) => (j === i ? { ...c, [campo]: valor } : c)))
  }

  function agregarCapitulo() {
    setCapitulos([...capitulos, { ...CAPITULO_VACIO }])
    setEditando(capitulos.length)
  }

  function quitarCapitulo(i) {
    setCapitulos(capitulos.filter((_, j) => j !== i))
    setEditando(null)
  }

  async function guardar(publicar) {
    setError('')
    const esCatalogo = esAdmin && autorExterno.trim() !== ''
    const conTexto = capitulos.filter((c) => c.contenido.trim())
    if (!titulo.trim() || !generoId) return setError('El título y el género son obligatorios.')
    if (publicar && conTexto.length === 0 && !(esCatalogo && (pdfExterno || libro?.pdf))) {
      return setError('Para publicar, la obra necesita al menos un capítulo con texto.')
    }

    try {
      setGuardando('Guardando la obra…')
      const autorId = esCatalogo ? await autorCatalogo(autorExterno.trim()) : await autorPropio(usuarioId, perfil.nickname)
      const datosObra = { titulo: titulo.trim(), sinopsis: sinopsis.trim() || null, genero_id: Number(generoId), autor_id: autorId }

      // CREATE o UPDATE de la obra y su libro
      let id = libro?.id
      if (libro) {
        const { error } = await supabase.from('obra').update(datosObra).eq('id', libro.obra.id)
        if (error) throw error
      } else {
        const { data: obra, error } = await supabase.from('obra').insert(datosObra).select('id').single()
        if (error) throw error
        const { data: nuevo, error: errorLibro } = await supabase.from('libro').insert({ obra_id: obra.id }).select('id').single()
        if (errorLibro) throw errorLibro
        id = nuevo.id
      }

      if (portada) {
        setGuardando('Subiendo la portada…')
        const ruta = await subirArchivo('portadas', usuarioId, portada, `libro-${id}`)
        const { error } = await supabase.from('libro').update({ portada: ruta }).eq('id', id)
        if (error) throw error
      }

      // Capítulos: se reescriben por número y se borran los que sobran
      const filas = capitulos.map((c, i) => ({
        libro_id: id,
        numero_capitulo: i + 1,
        nombre: c.nombre.trim() || null,
        contenido: c.contenido,
      }))
      if (filas.length) {
        const { error } = await supabase.from('capitulo').upsert(filas, { onConflict: 'libro_id,numero_capitulo' })
        if (error) throw error
      }
      const { error: errorBorrar } = await supabase.from('capitulo').delete().eq('libro_id', id).gt('numero_capitulo', filas.length)
      if (errorBorrar) throw errorBorrar

      // Un libro publicado siempre tiene su PDF (CHECK de la tabla libro).
      // Si ya estaba publicado, se regenera para que coincida con los cambios.
      if (publicar || libro?.estado === 'publicado') {
        let pdf = libro?.pdf ?? null
        let paginas = null
        if (esCatalogo && pdfExterno) {
          setGuardando('Subiendo el PDF…')
          pdf = await subirArchivo('pdfs', usuarioId, pdfExterno, `libro-${id}`)
        } else if (filas.length) {
          setGuardando('Generando el PDF…')
          const generado = await generarPdf({
            titulo: datosObra.titulo,
            autor: esCatalogo ? autorExterno.trim() : perfil.nickname,
            sinopsis: datosObra.sinopsis,
            capitulos: filas,
            portada: portada ?? (await portadaGuardada(libro?.portada)),
          })
          pdf = await subirArchivo('pdfs', usuarioId, generado.archivo, `libro-${id}`)
          paginas = generado.paginas
          const conPagina = filas.map((f, i) => ({ ...f, pagina_pdf: generado.paginasCapitulos.at(i) }))
          const { error } = await supabase.from('capitulo').upsert(conPagina, { onConflict: 'libro_id,numero_capitulo' })
          if (error) throw error
        }
        const cambios = { pdf, estado: 'publicado' }
        if (paginas) cambios.paginas = paginas
        if (libro?.estado !== 'publicado') cambios.fecha_publicacion = new Date().toISOString().slice(0, 10)
        const { error } = await supabase.from('libro').update(cambios).eq('id', id)
        if (error) throw error
      }

      navegar(`/libro/${id}`)
    } catch (e) {
      setError(mensajeError(e))
    } finally {
      setGuardando('')
    }
  }

  const portadaActual = portada ? URL.createObjectURL(portada) : urlPublica('portadas', libro?.portada)

  return (
    <section>
      <h1>{libro ? 'Editar obra' : 'Publicar una obra'}</h1>

      <div className="publicar">
        <div className="columna">
          <label>
            Título
            <input value={titulo} onChange={(e) => setTitulo(e.target.value)} placeholder="Título de tu obra" />
          </label>
          <label>
            Género
            <select value={generoId} onChange={(e) => setGeneroId(e.target.value)}>
              <option value="">Selecciona un género</option>
              {generos.map((g) => (
                <option key={g.id} value={g.id}>{g.nombre}</option>
              ))}
            </select>
          </label>
          <label>
            Sinopsis
            <textarea rows={5} value={sinopsis} onChange={(e) => setSinopsis(e.target.value)} />
          </label>

          <div className="subir-portada">
            {portadaActual ? <img className="portada mini" src={portadaActual} alt="Portada" /> : <div className="portada vacia mini"><span>Portada</span></div>}
            <label className="boton secundario">
              Subir portada
              <input type="file" accept="image/jpeg,image/png,image/webp" hidden onChange={(e) => setPortada(e.target.files[0] ?? null)} />
            </label>
          </div>

          {esAdmin && (
            <fieldset className="tarjeta">
              <legend>Catálogo (solo admin)</legend>
              <label>
                Autor sin cuenta en Nilibro
                <input value={autorExterno} onChange={(e) => setAutorExterno(e.target.value)} placeholder="Déjalo vacío si la obra es tuya" />
              </label>
              <label>
                PDF del libro
                <input type="file" accept="application/pdf" onChange={(e) => setPdfExterno(e.target.files[0] ?? null)} />
              </label>
            </fieldset>
          )}
        </div>

        <div className="columna">
          <h2>Capítulos</h2>
          {capitulos.map((c, i) =>
            editando === i ? (
              <div key={i} className="tarjeta capitulo-editor">
                <input value={c.nombre} onChange={(e) => cambiarCapitulo(i, 'nombre', e.target.value)} placeholder={`Nombre del capítulo ${i + 1} (opcional)`} />
                <textarea rows={12} value={c.contenido} onChange={(e) => cambiarCapitulo(i, 'contenido', e.target.value)} placeholder="Escribe o pega el texto del capítulo" />
                <div className="acciones">
                  <button type="button" onClick={() => setEditando(null)}>Listo</button>
                  <button type="button" className="peligro" onClick={() => quitarCapitulo(i)}>Quitar</button>
                </div>
              </div>
            ) : (
              <div key={i} className="tarjeta fila">
                <strong>Capítulo {i + 1}{c.nombre && `: ${c.nombre}`}</strong>
                <button type="button" className="secundario" onClick={() => setEditando(i)}>Editar</button>
              </div>
            ),
          )}
          <button type="button" className="secundario ancho" onClick={agregarCapitulo}>+ Agregar capítulo</button>

          {error && <p className="error">{error}</p>}

          <div className="acciones-publicar">
            <button type="button" className="secundario" disabled={!!guardando} onClick={() => guardar(false)}>
              {libro?.estado === 'publicado' ? 'Guardar cambios' : 'Guardar borrador'}
            </button>
            {libro?.estado !== 'publicado' && (
              <button type="button" disabled={!!guardando} onClick={() => guardar(true)}>
                Publicar
              </button>
            )}
          </div>
          {guardando && <p className="suave">{guardando}</p>}
        </div>
      </div>
    </section>
  )
}

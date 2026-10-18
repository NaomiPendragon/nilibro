import { useCallback, useEffect, useState } from 'react'
import { Link } from 'react-router'
import { mensajeError, supabase } from '../supabase.js'
import { useSesion } from '../sesion.jsx'
import { ESTADOS_LECTURA, LIBRO_CAMPOS, porcentaje } from '../datos.js'
import { Pestanas, Portada, TarjetaLibro } from '../componentes/Libro.jsx'

const FILTROS = { todos: 'Todos', ...ESTADOS_LECTURA, favoritos: 'Favoritos' }

export default function Biblioteca() {
  const { usuarioId } = useSesion()
  const [entradas, setEntradas] = useState([])
  const [filtro, setFiltro] = useState('todos')
  const [agregando, setAgregando] = useState(false)
  const [error, setError] = useState('')

  // READ: el RLS de biblioteca solo devuelve las filas del usuario con sesión
  const cargar = useCallback(async () => {
    const { data, error } = await supabase
      .from('biblioteca')
      .select(`libro_id, estado_lectura, favorito, ultima_pagina_leida, libro(${LIBRO_CAMPOS})`)
      .order('fecha_adicion', { ascending: false })
    if (error) return setError(mensajeError(error))
    setEntradas(data)
  }, [])

  useEffect(() => {
    void cargar()
  }, [cargar])

  // UPDATE / DELETE de una entrada de la biblioteca
  async function cambiar(libroId, cambios) {
    setError('')
    const consulta = cambios
      ? supabase.from('biblioteca').update(cambios).eq('libro_id', libroId).eq('usuario_id', usuarioId)
      : supabase.from('biblioteca').delete().eq('libro_id', libroId).eq('usuario_id', usuarioId)
    const { error } = await consulta
    if (error) return setError(mensajeError(error))
    await cargar()
  }

  // Un libro retirado por su autor deja de ser visible: su entrada llega sin libro
  const visibles = entradas.filter(
    (e) => e.libro && (filtro === 'todos' ? true : filtro === 'favoritos' ? e.favorito : e.estado_lectura === filtro),
  )

  return (
    <section>
      <div className="titulo-seccion">
        <h1>Mi biblioteca</h1>
        <button onClick={() => setAgregando(true)}>+ Agregar libro</button>
      </div>

      <Pestanas opciones={FILTROS} activa={filtro} onCambio={setFiltro} />
      {error && <p className="error">{error}</p>}

      {visibles.length === 0 ? (
        <p className="vacio">No hay libros aquí todavía.</p>
      ) : (
        <div className="cuadricula">
          {visibles.map((e) => (
            <TarjetaLibro key={e.libro_id} libro={e.libro} progreso={porcentaje(e)}>
              <select
                value={e.estado_lectura}
                onChange={(ev) => cambiar(e.libro_id, { estado_lectura: ev.target.value })}
                aria-label="Estado de lectura"
              >
                {Object.entries(ESTADOS_LECTURA).map(([valor, texto]) => (
                  <option key={valor} value={valor}>{texto}</option>
                ))}
              </select>
              <div className="acciones">
                <button
                  className={`secundario icono ${e.favorito ? 'marcado' : ''}`}
                  onClick={() => cambiar(e.libro_id, { favorito: !e.favorito })}
                  aria-label={e.favorito ? 'Quitar de favoritos' : 'Marcar como favorito'}
                  title="Favorito"
                >
                  {e.favorito ? '★' : '☆'}
                </button>
                <button className="peligro" onClick={() => confirm('¿Quitar este libro de tu biblioteca?') && cambiar(e.libro_id, null)}>
                  Quitar
                </button>
              </div>
            </TarjetaLibro>
          ))}
        </div>
      )}

      <div className="tarjeta fila">
        <div>
          <strong>Mis obras publicadas</strong>
          <p className="suave">Gestiona tus historias y capítulos</p>
        </div>
        <Link to="/perfil" className="boton secundario">Abrir</Link>
      </div>

      {agregando && (
        <AgregarLibro
          usuarioId={usuarioId}
          yaAgregados={entradas.map((e) => e.libro_id)}
          onCerrar={() => setAgregando(false)}
          onAgregado={cargar}
        />
      )}
    </section>
  )
}

// Ventana para agregar un libro publicado a la biblioteca (Figura 16)
function AgregarLibro({ usuarioId, yaAgregados, onCerrar, onAgregado }) {
  const [busqueda, setBusqueda] = useState('')
  const [resultados, setResultados] = useState([])
  const [estado, setEstado] = useState('quiero_leer')
  const [error, setError] = useState('')

  useEffect(() => {
    const espera = setTimeout(async () => {
      let consulta = supabase.from('libro').select(LIBRO_CAMPOS).eq('estado', 'publicado').limit(12)
      if (busqueda.trim()) consulta = consulta.ilike('obra.titulo', `%${busqueda.trim()}%`)
      const { data } = await consulta
      setResultados(data ?? [])
    }, 300)
    return () => clearTimeout(espera)
  }, [busqueda])

  async function agregar(libroId) {
    const { error } = await supabase.from('biblioteca').insert({ usuario_id: usuarioId, libro_id: libroId, estado_lectura: estado })
    if (error) return setError(mensajeError(error))
    await onAgregado()
    onCerrar()
  }

  return (
    <div className="fondo-modal" onClick={onCerrar}>
      <div className="modal tarjeta" onClick={(e) => e.stopPropagation()} role="dialog" aria-label="Agregar libro">
        <h2>Agregar libro</h2>
        <input autoFocus value={busqueda} onChange={(e) => setBusqueda(e.target.value)} placeholder="Busca por título" />
        <label>
          Agregar como
          <select value={estado} onChange={(e) => setEstado(e.target.value)}>
            {Object.entries(ESTADOS_LECTURA).map(([valor, texto]) => (
              <option key={valor} value={valor}>{texto}</option>
            ))}
          </select>
        </label>
        {error && <p className="error">{error}</p>}
        <ul className="lista-modal">
          {resultados.map((l) => (
            <li key={l.id}>
              <Portada libro={l} className="mini" />
              <div>
                <strong>{l.obra.titulo}</strong>
                <span className="suave">{l.obra.autor?.nombre}</span>
              </div>
              {yaAgregados.includes(l.id) ? (
                <span className="suave">Ya está</span>
              ) : (
                <button onClick={() => agregar(l.id)}>Agregar</button>
              )}
            </li>
          ))}
          {resultados.length === 0 && <li className="suave">No se encontraron libros publicados.</li>}
        </ul>
        <button className="secundario" onClick={onCerrar}>Cerrar</button>
      </div>
    </div>
  )
}

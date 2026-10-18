import { useEffect, useState } from 'react'
import { useSearchParams } from 'react-router'
import { supabase } from '../supabase.js'
import { LIBRO_CAMPOS } from '../datos.js'
import { TarjetaLibro } from '../componentes/Libro.jsx'

// Igual que LIBRO_CAMPOS pero con el autor obligatorio, para filtrar por su nombre
const CAMPOS_POR_AUTOR = LIBRO_CAMPOS.replace('autor(', 'autor!inner(')

export default function Buscar() {
  const [parametros, setParametros] = useSearchParams()
  const q = parametros.get('q') ?? ''
  const generoId = parametros.get('genero') ?? ''
  const [generos, setGeneros] = useState([])
  const [libros, setLibros] = useState([])
  const [cargando, setCargando] = useState(true)

  useEffect(() => {
    void supabase.from('genero_libro').select('id, nombre').order('nombre').then(({ data }) => setGeneros(data ?? []))
  }, [])

  useEffect(() => {
    async function buscar() {
      setCargando(true)
      const texto = `%${q.trim()}%`
      const base = (campos) => {
        let consulta = supabase.from('libro').select(campos).eq('estado', 'publicado').limit(48)
        if (generoId) consulta = consulta.eq('obra.genero_id', Number(generoId))
        return consulta
      }
      // Por título o por nombre del autor (RF-02)
      const [porTitulo, porAutor] = await Promise.all([
        base(LIBRO_CAMPOS).ilike('obra.titulo', texto),
        q.trim() ? base(CAMPOS_POR_AUTOR).ilike('obra.autor.nombre', texto) : Promise.resolve({ data: [] }),
      ])
      const unicos = new Map([...(porTitulo.data ?? []), ...(porAutor.data ?? [])].map((l) => [l.id, l]))
      setLibros([...unicos.values()])
      setCargando(false)
    }
    void buscar()
  }, [q, generoId])

  function cambiarGenero(valor) {
    const nuevos = new URLSearchParams(parametros)
    if (valor) nuevos.set('genero', valor)
    else nuevos.delete('genero')
    setParametros(nuevos)
  }

  return (
    <section>
      <div className="titulo-seccion">
        <h1>{q ? `Resultados para "${q}"` : 'Catálogo'}</h1>
        <select value={generoId} onChange={(e) => cambiarGenero(e.target.value)} aria-label="Filtrar por género">
          <option value="">Todos los géneros</option>
          {generos.map((g) => (
            <option key={g.id} value={g.id}>{g.nombre}</option>
          ))}
        </select>
      </div>

      {cargando ? (
        <p>Buscando…</p>
      ) : libros.length === 0 ? (
        <p className="vacio">No encontramos libros con esa búsqueda.</p>
      ) : (
        <div className="cuadricula">
          {libros.map((l) => <TarjetaLibro key={l.id} libro={l} />)}
        </div>
      )}
    </section>
  )
}

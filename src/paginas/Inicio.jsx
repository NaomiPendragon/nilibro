import { useEffect, useState } from 'react'
import { Link } from 'react-router'
import { supabase } from '../supabase.js'
import { LIBRO_CAMPOS, porcentaje } from '../datos.js'
import { Portada, TarjetaLibro } from '../componentes/Libro.jsx'

export default function Inicio() {
  const [continuar, setContinuar] = useState(null)
  const [recomendados, setRecomendados] = useState([])

  useEffect(() => {
    async function cargar() {
      const { data: mia } = await supabase
        .from('biblioteca')
        .select(`libro_id, estado_lectura, ultima_pagina_leida, fecha_ultima_lectura, libro(${LIBRO_CAMPOS})`)
      // Un libro retirado por su autor deja de ser visible: su entrada llega sin libro
      const entradas = (mia ?? []).filter((e) => e.libro)

      const leyendo = entradas
        .filter((e) => e.estado_lectura === 'leyendo')
        .sort((a, b) => (b.fecha_ultima_lectura ?? '').localeCompare(a.fecha_ultima_lectura ?? ''))
      setContinuar(leyendo.at(0) ?? null)

      // Recomendaciones simples: libros publicados de los géneros que ya lee,
      // que no estén en su biblioteca. Si no hay, los más recientes.
      const generos = [...new Set(entradas.map((e) => e.libro.obra.genero_id))]
      const yaTiene = entradas.map((e) => e.libro_id)
      let consulta = supabase.from('libro').select(LIBRO_CAMPOS).eq('estado', 'publicado').order('id', { ascending: false }).limit(18)
      if (generos.length) consulta = consulta.in('obra.genero_id', generos)
      let { data } = await consulta
      let sugeridos = (data ?? []).filter((l) => !yaTiene.includes(l.id))
      if (sugeridos.length === 0) {
        ;({ data } = await supabase.from('libro').select(LIBRO_CAMPOS).eq('estado', 'publicado').order('id', { ascending: false }).limit(18))
        sugeridos = (data ?? []).filter((l) => !yaTiene.includes(l.id))
      }
      setRecomendados(sugeridos.slice(0, 6))
    }
    void cargar()
  }, [])

  return (
    <section>
      <h2>Continuar leyendo</h2>
      {continuar ? (
        <div className="tarjeta fila">
          <Portada libro={continuar.libro} className="mini" />
          <div className="crece">
            <strong>{continuar.libro.obra.titulo}</strong>
            <p className="suave">{continuar.libro.obra.autor?.nombre}</p>
            <div className="progreso"><div style={{ width: `${porcentaje(continuar)}%` }} /></div>
          </div>
          <Link to={`/leer/${continuar.libro_id}`} className="boton">Continuar</Link>
        </div>
      ) : (
        <p className="suave">Cuando empieces un libro, aparecerá aquí.</p>
      )}

      <div className="titulo-seccion">
        <h2>Recomendados para ti</h2>
        <Link to="/buscar" className="enlace">Ver todo</Link>
      </div>
      {recomendados.length === 0 ? (
        <p className="suave">Todavía no hay libros publicados.</p>
      ) : (
        <div className="cuadricula">
          {recomendados.map((l) => <TarjetaLibro key={l.id} libro={l} />)}
        </div>
      )}

      <div className="dos-columnas">
        <div>
          <h2>Clubes de lectura</h2>
          <p className="suave tarjeta">Los clubes llegan en la siguiente fase del proyecto.</p>
        </div>
        <div>
          <h2>Foros recientes</h2>
          <p className="suave tarjeta">Los foros llegan en la siguiente fase del proyecto.</p>
        </div>
      </div>
    </section>
  )
}

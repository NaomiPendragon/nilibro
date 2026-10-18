import { useCallback, useEffect, useState } from 'react'
import { Link } from 'react-router'
import { mensajeError, supabase } from '../supabase.js'
import { useSesion } from '../sesion.jsx'
import { Pestanas } from '../componentes/Libro.jsx'

const PESTANAS = { autores: 'Autores', clubes: 'Clubes', foros: 'Foros' }

export default function Comunidad() {
  const [pestana, setPestana] = useState('autores')

  return (
    <section>
      <h1>Comunidad</h1>
      <Pestanas opciones={PESTANAS} activa={pestana} onCambio={setPestana} />
      {pestana === 'autores' && <Autores />}
      {pestana === 'clubes' && <FaseDos titulo="Clubes de lectura" texto="Crea un club, elige el primer libro e invita a otros lectores." />}
      {pestana === 'foros' && <FaseDos titulo="Foros" texto="Temas por categoría, hilos y respuestas." />}
    </section>
  )
}

// Clubes y foros ya tienen tablas y RLS, pero sus pantallas quedan para la fase 2
function FaseDos({ titulo, texto }) {
  return (
    <div className="tarjeta fase-dos">
      <strong>{titulo}</strong>
      <p>{texto}</p>
      <p className="suave">Disponible en la siguiente fase del proyecto.</p>
    </div>
  )
}

function Autores() {
  const { usuarioId } = useSesion()
  const [autores, setAutores] = useState([])
  const [siguiendo, setSiguiendo] = useState([])
  const [error, setError] = useState('')

  const cargar = useCallback(async () => {
    const [lista, mias] = await Promise.all([
      supabase.from('autor').select('id, nombre, biografia, usuario_id, obra(count), suscripcion(count)').order('nombre'),
      supabase.from('suscripcion').select('autor_id').eq('usuario_id', usuarioId),
    ])
    if (lista.error) return setError(mensajeError(lista.error))
    setAutores(lista.data)
    setSiguiendo((mias.data ?? []).map((s) => s.autor_id))
  }, [usuarioId])

  useEffect(() => {
    void cargar()
  }, [cargar])

  async function alternar(autorId) {
    setError('')
    const { error } = siguiendo.includes(autorId)
      ? await supabase.from('suscripcion').delete().eq('autor_id', autorId).eq('usuario_id', usuarioId)
      : await supabase.from('suscripcion').insert({ autor_id: autorId, usuario_id: usuarioId })
    if (error) return setError(mensajeError(error))
    await cargar()
  }

  return (
    <>
      {error && <p className="error">{error}</p>}
      {autores.length === 0 && <p className="vacio">Todavía no hay autores.</p>}
      <div className="lista">
        {autores.map((a) => (
          <div key={a.id} className="tarjeta fila">
            <div className="avatar grande">{a.nombre[0]?.toUpperCase()}</div>
            <div className="crece">
              <Link to={`/buscar?q=${encodeURIComponent(a.nombre)}`}><strong>{a.nombre}</strong></Link>
              <p className="suave">
                {a.obra[0]?.count ?? 0} obras · {a.suscripcion[0]?.count ?? 0} seguidores
              </p>
            </div>
            {a.usuario_id !== usuarioId && (
              <button className={siguiendo.includes(a.id) ? 'secundario' : ''} onClick={() => alternar(a.id)}>
                {siguiendo.includes(a.id) ? 'Siguiendo' : 'Seguir'}
              </button>
            )}
          </div>
        ))}
      </div>
    </>
  )
}

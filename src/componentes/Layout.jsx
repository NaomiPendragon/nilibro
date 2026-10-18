import { useState } from 'react'
import { Link, NavLink, Outlet, useNavigate } from 'react-router'
import { useSesion } from '../sesion.jsx'
import { urlPublica } from '../supabase.js'

const SECCIONES = [
  { a: '/', texto: 'Inicio' },
  { a: '/biblioteca', texto: 'Mi biblioteca' },
  { a: '/comunidad', texto: 'Comunidad' },
  { a: '/publicar', texto: 'Publicar' },
  { a: '/perfil', texto: 'Perfil' },
]

export default function Layout() {
  const { perfil } = useSesion()
  const [busqueda, setBusqueda] = useState('')
  const navegar = useNavigate()

  function buscar(e) {
    e.preventDefault()
    const q = busqueda.trim()
    if (q) navegar(`/buscar?q=${encodeURIComponent(q)}`)
  }

  const foto = urlPublica('fotos_perfil', perfil?.foto_perfil)

  return (
    <div className="marco">
      <aside className="lateral">
        <Link to="/" className="logo">Nilibro</Link>
        <nav>
          {SECCIONES.map((s) => (
            <NavLink key={s.a} to={s.a} end={s.a === '/'}>
              {s.texto}
            </NavLink>
          ))}
        </nav>
      </aside>

      <div className="contenido">
        <header className="barra">
          <form onSubmit={buscar} className="buscador">
            <input
              type="search"
              placeholder="Buscar libros, autores o clubes"
              value={busqueda}
              onChange={(e) => setBusqueda(e.target.value)}
              aria-label="Buscar"
            />
          </form>
          <Link to="/perfil" className="avatar" title={perfil?.nickname}>
            {foto ? <img src={foto} alt="" /> : perfil?.nickname?.[0]?.toUpperCase()}
          </Link>
        </header>
        <main>
          <Outlet />
        </main>
      </div>
    </div>
  )
}

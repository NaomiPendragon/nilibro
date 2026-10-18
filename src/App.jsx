import { Navigate, Route, Routes } from 'react-router'
import { useSesion } from './sesion.jsx'
import Layout from './componentes/Layout.jsx'
import Acceso from './paginas/Acceso.jsx'
import Inicio from './paginas/Inicio.jsx'
import Biblioteca from './paginas/Biblioteca.jsx'
import Detalle from './paginas/Detalle.jsx'
import Lector from './paginas/Lector.jsx'
import Publicar from './paginas/Publicar.jsx'
import Comunidad from './paginas/Comunidad.jsx'
import Perfil from './paginas/Perfil.jsx'
import Buscar from './paginas/Buscar.jsx'

export default function App() {
  const { session, cargando } = useSesion()

  if (cargando) return <p className="centro">Cargando…</p>
  if (!session) return <Acceso />

  return (
    <Routes>
      <Route element={<Layout />}>
        <Route index element={<Inicio />} />
        <Route path="biblioteca" element={<Biblioteca />} />
        <Route path="libro/:id" element={<Detalle />} />
        <Route path="publicar" element={<Publicar />} />
        <Route path="publicar/:libroId" element={<Publicar />} />
        <Route path="comunidad" element={<Comunidad />} />
        <Route path="perfil" element={<Perfil />} />
        <Route path="buscar" element={<Buscar />} />
      </Route>
      {/* El lector va a pantalla completa, sin menú lateral */}
      <Route path="leer/:id" element={<Lector />} />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}

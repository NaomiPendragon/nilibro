import { Link } from 'react-router'
import { urlPublica } from '../supabase.js'

export function Portada({ libro, className = '' }) {
  const url = urlPublica('portadas', libro?.portada)
  return url ? (
    <img className={`portada ${className}`} src={url} alt={`Portada de ${libro.obra?.titulo}`} />
  ) : (
    <div className={`portada vacia ${className}`}>
      <span>{libro?.obra?.titulo ?? 'Portada'}</span>
    </div>
  )
}

// Tarjeta de la cuadrícula: portada, título y, si se pasa, barra de progreso
export function TarjetaLibro({ libro, progreso, children }) {
  return (
    <div className="tarjeta-libro">
      <Link to={`/libro/${libro.id}`}>
        <Portada libro={libro} />
      </Link>
      {progreso !== undefined && (
        <div className="progreso" aria-label={`${progreso}% leído`}>
          <div style={{ width: `${progreso}%` }} />
        </div>
      )}
      <Link to={`/libro/${libro.id}`} className="titulo-libro">
        {libro.obra?.titulo}
      </Link>
      <span className="suave">{libro.obra?.autor?.nombre}</span>
      {children}
    </div>
  )
}

export function Pestanas({ opciones, activa, onCambio }) {
  return (
    <div className="pestanas" role="tablist">
      {Object.entries(opciones).map(([clave, texto]) => (
        <button
          key={clave}
          role="tab"
          aria-selected={activa === clave}
          className={activa === clave ? 'activa' : ''}
          onClick={() => onCambio(clave)}
        >
          {texto}
        </button>
      ))}
    </div>
  )
}

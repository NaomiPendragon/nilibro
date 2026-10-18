import { useState } from 'react'
import { mensajeError, supabase } from '../supabase.js'
import { NICKNAME_VALIDO } from '../datos.js'

export default function Acceso() {
  const [modo, setModo] = useState('entrar') // 'entrar' | 'registro'
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [nickname, setNickname] = useState('')
  const [error, setError] = useState('')
  const [enviando, setEnviando] = useState(false)

  const entrando = modo === 'entrar'

  async function enviar(e) {
    e.preventDefault()
    setError('')
    if (!entrando && !NICKNAME_VALIDO.test(nickname)) {
      return setError('El nickname debe tener de 3 a 30 letras, números, punto o guion bajo.')
    }
    setEnviando(true)
    // El trigger crear_perfil_usuario toma el nickname de estos metadatos
    const { error } = entrando
      ? await supabase.auth.signInWithPassword({ email, password })
      : await supabase.auth.signUp({ email, password, options: { data: { nickname } } })
    setEnviando(false)
    if (error) setError(mensajeError(error))
  }

  return (
    <div className="acceso">
      <section className="acceso-marca">
        <h1 className="logo">Nilibro</h1>
        <p>Lee, comparte y publica en un solo lugar.</p>
      </section>

      <section className="acceso-formulario">
        <form className="tarjeta" onSubmit={enviar}>
          <h2>{entrando ? 'Inicia sesión' : 'Crea tu cuenta'}</h2>

          {!entrando && (
            <label>
              Nickname
              <input value={nickname} onChange={(e) => setNickname(e.target.value)} placeholder="lysme" required />
            </label>
          )}
          <label>
            Correo electrónico
            <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} placeholder="tu@correo.com" required />
          </label>
          <label>
            Contraseña
            <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} minLength={6} required />
          </label>

          {error && <p className="error">{error}</p>}

          <button type="submit" disabled={enviando}>
            {enviando ? 'Un momento…' : entrando ? 'Iniciar sesión' : 'Registrarme'}
          </button>

          <p className="cambio">
            {entrando ? '¿No tienes cuenta? ' : '¿Ya tienes cuenta? '}
            <button type="button" className="enlace" onClick={() => setModo(entrando ? 'registro' : 'entrar')}>
              {entrando ? 'Crear cuenta' : 'Iniciar sesión'}
            </button>
          </p>
        </form>
      </section>
    </div>
  )
}

import { createContext, useCallback, useContext, useEffect, useState } from 'react'
import { supabase } from './supabase.js'

const SesionContexto = createContext(null)

export function SesionProvider({ children }) {
  const [session, setSession] = useState(null)
  const [perfil, setPerfil] = useState(null)
  const [cargando, setCargando] = useState(true)

  const cargarPerfil = useCallback(async (usuarioId) => {
    if (!usuarioId) return setPerfil(null)
    const { data } = await supabase.from('usuario').select('*').eq('id', usuarioId).maybeSingle()
    setPerfil(data)
  }, [])

  useEffect(() => {
    async function iniciar() {
      const { data } = await supabase.auth.getSession()
      setSession(data.session)
      await cargarPerfil(data.session?.user.id)
      setCargando(false)
    }
    void iniciar()

    const { data } = supabase.auth.onAuthStateChange((_evento, nueva) => {
      setSession(nueva)
      void cargarPerfil(nueva?.user.id)
    })
    return () => data.subscription.unsubscribe()
  }, [cargarPerfil])

  const valor = {
    session,
    usuarioId: session?.user.id ?? null,
    perfil,
    cargando,
    recargarPerfil: () => cargarPerfil(session?.user.id),
  }

  return <SesionContexto.Provider value={valor}>{children}</SesionContexto.Provider>
}

export function useSesion() {
  return useContext(SesionContexto)
}

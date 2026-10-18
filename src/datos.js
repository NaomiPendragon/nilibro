// Campos que se piden siempre que se muestra un libro con su obra, género y autor
export const LIBRO_CAMPOS =
  'id, portada, estado, paginas, pdf, fecha_publicacion, ' +
  'obra!inner(id, titulo, sinopsis, genero_id, genero_libro(nombre), autor(id, nombre, usuario_id))'

export const ESTADOS_LECTURA = {
  quiero_leer: 'Por leer',
  leyendo: 'Leyendo',
  leido: 'Leído',
  abandonado: 'Abandonado',
}

// Porcentaje leído a partir de la última página guardada en la biblioteca
export function porcentaje(entrada) {
  const paginas = entrada?.libro?.paginas
  if (!paginas) return 0
  return Math.min(100, Math.round((entrada.ultima_pagina_leida / paginas) * 100))
}

export const NICKNAME_VALIDO = /^[A-Za-z0-9_.]{3,30}$/

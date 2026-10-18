// Convierte la imagen de portada (JPEG, PNG o WebP) a JPEG con un canvas:
// jsPDF no lee todos los formatos, y así el PDF queda más liviano.
async function portadaComoJpeg(imagen) {
  const url = URL.createObjectURL(imagen)
  try {
    const img = new Image()
    img.src = url
    await img.decode()
    const canvas = document.createElement('canvas')
    canvas.width = img.naturalWidth
    canvas.height = img.naturalHeight
    const contexto = canvas.getContext('2d')
    contexto.fillStyle = '#ffffff' // fondo blanco para PNG con transparencia
    contexto.fillRect(0, 0, canvas.width, canvas.height)
    contexto.drawImage(img, 0, 0)
    return { datos: canvas.toDataURL('image/jpeg', 0.9), ancho: img.naturalWidth, alto: img.naturalHeight }
  } finally {
    URL.revokeObjectURL(url)
  }
}

// Arma el PDF de una obra autopublicada a partir de sus capítulos.
// Devuelve el archivo, el total de páginas y la página donde empieza cada
// capítulo (se guarda en capitulo.pagina_pdf y sirve como marcador de lectura).
export async function generarPdf({ titulo, autor, sinopsis, capitulos, portada }) {
  // jsPDF pesa bastante: se carga solo cuando alguien publica. Si la página se
  // abrió antes de un deploy nuevo, ese archivo ya no existe en Vercel.
  let jsPDF
  try {
    ;({ jsPDF } = await import('jspdf'))
  } catch {
    throw new Error(
      'Hay una versión nueva de Nilibro. Tu obra quedó guardada como borrador: recarga la página y ábrela desde Perfil → Mis obras para publicarla.',
    )
  }
  const doc = new jsPDF({ format: 'a5', unit: 'mm' })

  const ancho = doc.internal.pageSize.getWidth()
  const alto = doc.internal.pageSize.getHeight()
  const margen = 16
  const interlineado = 5.6
  const anchoTexto = ancho - margen * 2

  // Primera página: la portada, centrada y sin deformarla
  if (portada) {
    const imagen = await portadaComoJpeg(portada)
    const escala = Math.min(ancho / imagen.ancho, alto / imagen.alto)
    const w = imagen.ancho * escala
    const h = imagen.alto * escala
    doc.addImage(imagen.datos, 'JPEG', (ancho - w) / 2, (alto - h) / 2, w, h)
    doc.addPage()
  }

  // Portada interna
  doc.setFont('helvetica', 'bold').setFontSize(22)
  doc.text(doc.splitTextToSize(titulo, anchoTexto), ancho / 2, alto / 3, { align: 'center' })
  doc.setFont('helvetica', 'normal').setFontSize(13)
  doc.text(autor, ancho / 2, alto / 3 + 20, { align: 'center' })
  if (sinopsis) {
    doc.setFontSize(10)
    doc.text(doc.splitTextToSize(sinopsis, anchoTexto), margen, alto / 2 + 10)
  }

  const paginasCapitulos = []
  for (const capitulo of capitulos) {
    doc.addPage()
    paginasCapitulos.push(doc.getNumberOfPages())

    let y = margen + 6
    doc.setFont('helvetica', 'bold').setFontSize(15)
    const encabezado = capitulo.nombre
      ? `Capítulo ${capitulo.numero_capitulo}: ${capitulo.nombre}`
      : `Capítulo ${capitulo.numero_capitulo}`
    for (const linea of doc.splitTextToSize(encabezado, anchoTexto)) {
      doc.text(linea, margen, y)
      y += 7
    }
    y += 4

    doc.setFont('helvetica', 'normal').setFontSize(11)
    for (const parrafo of (capitulo.contenido ?? '').split('\n')) {
      for (const linea of doc.splitTextToSize(parrafo || ' ', anchoTexto)) {
        if (y > alto - margen) {
          doc.addPage()
          y = margen
        }
        doc.text(linea, margen, y)
        y += interlineado
      }
      y += 2
    }
  }

  return {
    archivo: new File([doc.output('blob')], 'libro.pdf', { type: 'application/pdf' }),
    paginas: doc.getNumberOfPages(),
    paginasCapitulos,
  }
}

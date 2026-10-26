$enc = New-Object System.Text.UTF8Encoding($false)
$content = [System.IO.File]::ReadAllText("index.html", $enc)

# 1. Update Moto Cards Header in Operations (tabOperador === 'operaciones')
$oldMotoCardHeader = @'
                            <div key={moto.id} className="bg-white rounded-3xl border border-slate-200/80 shadow-xl shadow-slate-200/50 overflow-hidden flex flex-col justify-between">
                              <div>
                                {/* Encabezado de la unidad */}
                                <div className={`p-5 flex items-center justify-between text-white ${
                                  enAgua ? 'bg-gradient-to-r from-[#E5097F] to-[#D00772]' : disponible ? 'bg-[#0D1B2A]' : 'bg-slate-700'
                                }`}>
                                  <div>
                                    <span className="text-lg font-black uppercase tracking-tight block">
                                      #{moto.numero} • {moto.nombre}
                                    </span>
                                    <span className="text-[11px] text-white/80 uppercase font-medium">
                                      Base: {moto.ubicacion === 'sunsol' ? 'Sunsol Isla Caribe' : 'Playa Parguito'}
                                    </span>
                                  </div>
                                  <span className="px-3 py-1 rounded-full text-xs font-extrabold tracking-wide uppercase bg-black/25">
                                    {enAgua ? 'En Agua' : disponible ? 'Disponible' : 'Taller'}
                                  </span>
                                </div>
'@

$newMotoCardHeader = @'
                            <div key={moto.id} className="group bg-white rounded-3xl border border-slate-200/80 shadow-xl shadow-slate-200/50 overflow-hidden flex flex-col justify-between transition-all hover:shadow-2xl">
                              <div>
                                {/* Foto oficial y cabecera de la unidad (idéntica a la Vista Cliente) */}
                                <div className="relative h-44 w-full bg-[#0D1B2A] overflow-hidden">
                                  <img
                                    src={moto.imagen}
                                    alt={moto.nombre}
                                    className="w-full h-full object-cover opacity-85 group-hover:scale-105 transition-transform duration-500"
                                  />
                                  <div className="absolute inset-0 bg-gradient-to-t from-[#0D1B2A] via-[#0D1B2A]/40 to-black/20"></div>

                                  {/* Badges superiores de identificación y estado */}
                                  <div className="absolute top-3 left-3 flex items-center gap-1.5">
                                    <span className="px-2.5 py-1 rounded-md bg-[#0D1B2A]/90 text-[#8FD6F2] font-mono text-xs font-black shadow">
                                      #{moto.numero}
                                    </span>
                                    <span className="px-2 py-0.5 rounded-md bg-[#1DA1DB]/90 text-white font-mono text-[10px] font-bold uppercase shadow">
                                      {moto.ubicacion === 'sunsol' ? 'SUNSOL' : 'PARGUITO'}
                                    </span>
                                  </div>

                                  <div className="absolute top-3 right-3">
                                    <span className={`px-2.5 py-1 rounded-full text-[10px] font-condensed font-black uppercase tracking-wider shadow ${
                                      enAgua
                                        ? 'bg-[#E5097F] text-white animate-pulse'
                                        : disponible
                                        ? 'bg-emerald-500 text-white'
                                        : 'bg-amber-600 text-white'
                                    }`}>
                                      {enAgua ? 'EN EL AGUA' : disponible ? 'LISTA EN ORILLA' : 'EN TALLER'}
                                    </span>
                                  </div>

                                  {/* Datos del modelo y tarifas oficiales superpuestos */}
                                  <div className="absolute bottom-2.5 left-3.5 right-3.5 flex items-end justify-between text-white">
                                    <div>
                                      <span className="font-condensed text-xl font-black uppercase block leading-none drop-shadow">
                                        {moto.nombre}
                                      </span>
                                      <span className="text-[10px] font-mono font-bold text-[#8FD6F2] block mt-0.5 uppercase tracking-wide">
                                        {moto.subtitulo}
                                      </span>
                                    </div>
                                    <div className="text-right">
                                      <span className="text-[10px] font-mono text-slate-300 block">15m: 30€ • 20m: 40€</span>
                                      <span className="text-[10px] font-mono text-slate-300 block">30m: 60€</span>
                                    </div>
                                  </div>
                                </div>
'@

# Normalize line breaks for matching
$contentNorm = $content.Replace("`r`n", "`n")
$oldHeaderNorm = $oldMotoCardHeader.Replace("`r`n", "`n")
$newHeaderNorm = $newMotoCardHeader.Replace("`r`n", "`n")

if ($contentNorm.Contains($oldHeaderNorm)) {
    $contentNorm = $contentNorm.Replace($oldHeaderNorm, $newHeaderNorm)
    Write-Host "1. Updated Moto Cards header with real photos and client-aligned styles."
} else {
    Write-Host "Warning: oldMotoCardHeader not found directly."
}

# 2. Add Waiver Status to immediate queue cards (reservasPendientes)
$oldQueueDetail = @'
                                    <span className="text-xs text-slate-500 block mt-1">
                                      {resItem.toldo} • {resItem.personas === 2 ? '2 Personas' : '1 Piloto'} • Chaleco #{resItem.chaleco}
                                    </span>
                                  </div>
'@

$newQueueDetail = @'
                                    <span className="text-xs text-slate-500 block mt-1">
                                      {resItem.toldo} • {resItem.personas === 2 ? '2 Personas' : '1 Piloto'} • Chaleco #{resItem.chaleco}
                                    </span>
                                    {(() => {
                                      const w = firmasDia.find(f => f.nombre.toLowerCase().trim() === (resItem.cli || '').toLowerCase().trim());
                                      return w ? (
                                        <div className="mt-1.5 flex items-center justify-between text-[10px] bg-emerald-50 text-emerald-800 px-2 py-1 rounded-lg border border-emerald-200">
                                          <span className="font-bold flex items-center gap-1">
                                            <Icons.CheckCircle className="w-3.5 h-3.5 text-emerald-600" />
                                            Waiver Firmado ({w.id})
                                          </span>
                                          <button
                                            type="button"
                                            onClick={() => handleDescargarPDFContrato(w)}
                                            className="text-emerald-700 underline font-bold hover:text-emerald-900 cursor-pointer"
                                          >
                                            Ver PDF
                                          </button>
                                        </div>
                                      ) : (
                                        <div className="mt-1.5 text-[10px] bg-amber-50 text-amber-800 px-2 py-1 rounded-lg border border-amber-200 flex items-center gap-1">
                                          <Icons.AlertTriangle className="w-3.5 h-3.5 text-amber-600 shrink-0" />
                                          <span>Sin firma digital aún</span>
                                        </div>
                                      );
                                    })()}
                                  </div>
'@

$oldQueueNorm = $oldQueueDetail.Replace("`r`n", "`n")
$newQueueNorm = $newQueueDetail.Replace("`r`n", "`n")

if ($contentNorm.Contains($oldQueueNorm)) {
    $contentNorm = $contentNorm.Replace($oldQueueNorm, $newQueueNorm)
    Write-Host "2. Updated immediate queue cards with waiver verification."
} else {
    Write-Host "Warning: oldQueueDetail not found directly."
}

# 3. Highlight the 4 Web Zarpes in Agenda de Citas
$oldSlotHeader = @'
                                    <div>
                                      <strong className="font-mono text-lg font-black text-[#0D1B2A]">{ev.horaInicioReal}</strong>
                                      <span className="block text-[10px] font-mono text-slate-400">
                                        Capacidad: {ev.cantOcupadas}/3 ocupadas • {ev.cantLibres}/3 libres
                                      </span>
                                    </div>
'@

$newSlotHeader = @'
                                    <div>
                                      <div className="flex items-center gap-2">
                                        <strong className="font-mono text-lg font-black text-[#0D1B2A]">{ev.horaInicioReal}</strong>
                                        {MINUTOS_ZARPES_WEB.includes(slot.minutos) && (
                                          <span className="px-2 py-0.5 rounded-full bg-[#E5097F]/10 border border-[#E5097F]/30 text-[#E5097F] text-[9px] font-mono font-bold uppercase">
                                            ⭐ Zarpe Web (+5m)
                                          </span>
                                        )}
                                      </div>
                                      <span className="block text-[10px] font-mono text-slate-400">
                                        Capacidad: {ev.cantOcupadas}/3 ocupadas • {ev.cantLibres}/3 libres
                                      </span>
                                    </div>
'@

$oldSlotNorm = $oldSlotHeader.Replace("`r`n", "`n")
$newSlotNorm = $newSlotHeader.Replace("`r`n", "`n")

if ($contentNorm.Contains($oldSlotNorm)) {
    $contentNorm = $contentNorm.Replace($oldSlotNorm, $newSlotNorm)
    Write-Host "3. Highlighted the 4 Web Zarpes in Agenda de Citas."
} else {
    Write-Host "Warning: oldSlotHeader not found directly."
}

# 4. Modernize modalDespachoMoto
$oldModalDespacho = @'
          {modalDespachoMoto && (
            <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
              <div className="bg-white max-w-md w-full p-6 shadow-2xl border-t-8 border-[#E5097F] relative">
                <button
                  type="button"
                  onClick={() => setModalDespachoMoto(null)}
                  className="absolute top-4 right-4 text-slate-400 hover:text-black cursor-pointer"
                >
                  <Icons.X className="w-5 h-5" />
                </button>
                <span className="text-[10px] font-mono uppercase text-[#E5097F] font-bold block">
                  DESPACHO DE UNIDAD AL AGUA
                </span>
                <h3 className="font-condensed text-2xl font-bold uppercase text-[#0D1B2A]">
                  MOTO #{modalDespachoMoto.numero} • {modalDespachoMoto.nombre}
                </h3>

                <form onSubmit={handleConfirmarDespachoMoto} className="space-y-4 mt-4">
                  <div>
                    <label className="text-xs font-bold uppercase text-slate-600 block mb-1">Nombre del Piloto *</label>
                    <input
                      type="text"
                      required
                      value={despachoNombre}
                      onChange={e => setDespachoNombre(e.target.value)}
                      className="w-full px-3.5 py-2.5 border border-slate-300 text-xs"
                    />
                  </div>
                  <div>
                    <label className="text-xs font-bold uppercase text-slate-600 block mb-1">Toldo / Documento</label>
                    <input
                      type="text"
                      value={despachoToldo}
                      onChange={e => setDespachoToldo(e.target.value)}
                      className="w-full px-3.5 py-2.5 border border-slate-300 text-xs"
                    />
                  </div>
                  <div>
                    <label className="text-xs font-bold uppercase text-slate-600 block mb-1">Duración y Tarifa *</label>
                    <div className="grid grid-cols-4 gap-2">
                      {TARIFAS_OFICIALES.map(t => (
                        <button
                          key={t.min}
                          type="button"
                          onClick={() => setDespachoDuracion(t.min)}
                          className={`p-2 border text-center font-condensed cursor-pointer ${
                            despachoDuracion === t.min
                              ? 'bg-[#E5097F] text-white border-[#E5097F]'
                              : 'bg-slate-50 text-slate-800 border-slate-300'
                          }`}
                        >
                          <div className="text-sm font-bold">{t.min}M</div>
                          <div className="text-xs font-mono">{t.eur}€</div>
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* CHECKLIST OBLIGATORIO DE SEGURIDAD ANTES DEL ZARPE */}
                  <div className="p-3 bg-[#F2F6FA] border-l-4 border-[#1DA1DB] space-y-1.5">
                    <label className="flex items-start gap-2 text-xs text-[#0D1B2A] cursor-pointer">
                      <input
                        type="checkbox"
                        checked={despachoChecklistSeguridad}
                        onChange={e => setDespachoChecklistSeguridad(e.target.checked)}
                        className="mt-0.5"
                      />
                      <span>
                        <strong>Checklist de Zarpe OK:</strong> Llave cortacorriente (Lanyard) sujeta a la muñeca del piloto, chaleco(s) abrochado(s), canal de boyas explicado y tanque con reserva segura ({modalDespachoMoto.gasolinaLts}L disponibles).
                      </span>
                    </label>
                  </div>

                  <button
                    type="submit"
                    className="w-full py-3 rounded-full bg-[#E5097F] hover:bg-[#C8066C] text-white font-condensed text-sm font-bold uppercase tracking-widest cursor-pointer"
                  >
                    LANZAR AL AGUA ({despachoDuracion} MIN • {TARIFAS_MAP[despachoDuracion]}€)
                  </button>
                </form>
              </div>
            </div>
          )}
'@

$newModalDespacho = @'
          {modalDespachoMoto && (
            <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-md flex items-center justify-center p-4">
              <div className="bg-white max-w-lg w-full rounded-3xl shadow-2xl border-2 border-white/80 overflow-hidden relative animate-fadeIn">
                
                {/* Cabecera con imagen y modelo de la moto */}
                <div className="relative h-28 bg-[#0D1B2A] overflow-hidden">
                  <img
                    src={modalDespachoMoto.imagen}
                    alt={modalDespachoMoto.nombre}
                    className="w-full h-full object-cover opacity-60"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-[#0D1B2A] via-[#0D1B2A]/60 to-transparent"></div>
                  
                  <button
                    type="button"
                    onClick={() => setModalDespachoMoto(null)}
                    className="absolute top-3 right-3 w-8 h-8 rounded-full bg-black/40 hover:bg-black/60 text-white flex items-center justify-center cursor-pointer transition z-10"
                  >
                    <Icons.X className="w-4 h-4" />
                  </button>

                  <div className="absolute bottom-3 left-4 right-4 flex items-end justify-between text-white">
                    <div>
                      <span className="text-[10px] font-mono uppercase tracking-wider text-[#E5097F] font-bold block">
                        TERMINAL DE DESPACHO A EMBARCACIÓN
                      </span>
                      <h3 className="font-condensed text-2xl font-black uppercase text-white leading-tight">
                        MOTO #{modalDespachoMoto.numero} • {modalDespachoMoto.nombre}
                      </h3>
                    </div>
                    <span className="px-2.5 py-1 rounded-full bg-emerald-500/90 text-white text-[10px] font-bold uppercase font-mono">
                      {modalDespachoMoto.gasolinaLts}L Gasolina
                    </span>
                  </div>
                </div>

                <form onSubmit={handleConfirmarDespachoMoto} className="p-6 space-y-4">
                  <div>
                    <label className="text-xs font-bold uppercase text-slate-700 block mb-1">
                      Nombre y Apellido del Piloto *
                    </label>
                    <input
                      type="text"
                      required
                      placeholder="Ej: Alejandro Carrillo"
                      value={despachoNombre}
                      onChange={e => setDespachoNombre(e.target.value)}
                      className="w-full px-4 py-2.5 rounded-xl bg-slate-50 border border-slate-300 text-xs text-[#0D1B2A] focus:outline-none focus:border-[#E5097F]"
                    />
                  </div>

                  {/* Verificación automática de Contrato / Waiver firmado */}
                  {(() => {
                    const firmaOk = firmasDia.find(f => f.nombre.toLowerCase().trim() === despachoNombre.toLowerCase().trim() && despachoNombre.trim() !== '');
                    if (firmaOk) {
                      return (
                        <div className="p-3 bg-emerald-50 border border-emerald-200 rounded-2xl flex items-center justify-between text-xs">
                          <div className="flex items-center gap-2">
                            <Icons.CheckCircle className="w-5 h-5 text-emerald-600 shrink-0" />
                            <div>
                              <strong className="text-emerald-900 block font-bold">Waiver Digital Firmado ({firmaOk.id})</strong>
                              <span className="text-[11px] text-emerald-700 block">C.I.: {firmaOk.documento} • Hora: {firmaOk.hora}</span>
                              {firmaOk.acompanantes && (
                                <span className="text-[10px] text-emerald-800 block mt-0.5">👥 Acompañantes: {firmaOk.acompanantes}</span>
                              )}
                            </div>
                          </div>
                          <button
                            type="button"
                            onClick={() => handleDescargarPDFContrato(firmaOk)}
                            className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white font-condensed text-[11px] font-bold uppercase rounded-lg shadow-xs cursor-pointer"
                          >
                            PDF
                          </button>
                        </div>
                      );
                    }
                    if (despachoNombre.trim().length > 3) {
                      return (
                        <div className="p-2.5 bg-amber-50 border border-amber-200 rounded-xl flex items-center gap-2 text-xs text-amber-800">
                          <Icons.AlertTriangle className="w-4 h-4 text-amber-600 shrink-0" />
                          <span>Sin firma digital detectada con este nombre. Solicite firma al abordar.</span>
                        </div>
                      );
                    }
                    return null;
                  })()}

                  <div>
                    <label className="text-xs font-bold uppercase text-slate-700 block mb-1">
                      Ubicación de Salida / Toldo del Cliente
                    </label>
                    <input
                      type="text"
                      placeholder="Ej: Toldo #14 frente a Sunsol"
                      value={despachoToldo}
                      onChange={e => setDespachoToldo(e.target.value)}
                      className="w-full px-4 py-2.5 rounded-xl bg-slate-50 border border-slate-300 text-xs text-[#0D1B2A] focus:outline-none focus:border-[#E5097F]"
                    />
                  </div>

                  <div>
                    <label className="text-xs font-bold uppercase text-slate-700 block mb-1.5">
                      Duración y Tarifa Oficial *
                    </label>
                    <div className="grid grid-cols-4 gap-2">
                      {TARIFAS_OFICIALES.map(t => (
                        <button
                          key={t.min}
                          type="button"
                          onClick={() => setDespachoDuracion(t.min)}
                          className={`p-2.5 rounded-xl border text-center font-condensed cursor-pointer transition-all ${
                            despachoDuracion === t.min
                              ? 'bg-[#E5097F] text-white border-[#E5097F] shadow-md shadow-[#E5097F]/30 scale-[1.02]'
                              : 'bg-slate-50 text-slate-800 border-slate-200 hover:bg-slate-100'
                          }`}
                        >
                          <div className="text-base font-extrabold leading-none">{t.min}M</div>
                          <div className="text-xs font-mono font-bold mt-1">{t.eur}€</div>
                          <div className="text-[9px] font-mono opacity-80">Bs. {(t.eur * tasaEUR).toFixed(0)}</div>
                        </button>
                      ))}
                    </div>
                  </div>

                  {/* CHECKLIST OBLIGATORIO DE SEGURIDAD ANTES DEL ZARPE */}
                  <div className="p-3 bg-slate-50 border-l-4 border-[#1DA1DB] rounded-xl space-y-1">
                    <label className="flex items-start gap-2 text-xs text-[#0D1B2A] cursor-pointer">
                      <input
                        type="checkbox"
                        checked={despachoChecklistSeguridad}
                        onChange={e => setDespachoChecklistSeguridad(e.target.checked)}
                        className="mt-0.5 accent-[#E5097F]"
                      />
                      <span className="leading-snug">
                        <strong>Checklist de Zarpe OK:</strong> Llave cortacorriente (Lanyard) sujeta a la muñeca, chaleco salvavidas colocado, canal de navegación indicado y combustible seguro ({modalDespachoMoto.gasolinaLts}L disponibles).
                      </span>
                    </label>
                  </div>

                  <button
                    type="submit"
                    className="w-full py-3.5 rounded-full bg-[#E5097F] hover:bg-[#C8066C] text-white font-condensed text-base font-black uppercase tracking-wider cursor-pointer shadow-lg transition-all"
                  >
                    LANZAR AL AGUA ({despachoDuracion} MIN • {TARIFAS_MAP[despachoDuracion]}€ / Bs. {(TARIFAS_MAP[despachoDuracion] * tasaEUR).toFixed(2)})
                  </button>
                </form>
              </div>
            </div>
          )}
'@

$oldModalNorm = $oldModalDespacho.Replace("`r`n", "`n")
$newModalNorm = $newModalDespacho.Replace("`r`n", "`n")

if ($contentNorm.Contains($oldModalNorm)) {
    $contentNorm = $contentNorm.Replace($oldModalNorm, $newModalNorm)
    Write-Host "4. Modernized modalDespachoMoto with photo header, live waiver detection and official prices."
} else {
    Write-Host "Warning: oldModalDespacho not found directly."
}

# Write updated file with UTF8 encoding
$contentFinal = $contentNorm.Replace("`n", "`r`n")
[System.IO.File]::WriteAllText("index.html", $contentFinal, $enc)
Write-Host "Updates successfully saved to index.html."

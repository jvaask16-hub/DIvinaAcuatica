'use client';

import React, { useState } from 'react';
import DashboardPlaya from './components/DashboardPlaya';
import AgendaHorariosYTickets from './components/AgendaHorariosYTickets';
import PantallaTurnosClientes from './components/PantallaTurnosClientes';
import CalculadoraCajaBCV from './components/CalculadoraCajaBCV';
import RegistroFirmaWaiver from './components/RegistroFirmaWaiver';

export default function HomePage() {
  const [currentView, setCurrentView] = useState<'flota' | 'agenda' | 'radar' | 'caja' | 'waiver'>('flota');

  return (
    <div className="min-h-screen bg-[#F1F4F9] text-slate-900 flex items-center justify-center p-3 sm:p-8 font-sans selection:bg-slate-900 selection:text-white">
      <div className="w-full max-w-5xl bg-white rounded-[36px] sm:rounded-[44px] shadow-xl border border-slate-200/80 p-5 sm:p-10 transition-all">
        
        {/* =============================================================== */}
        {/* BARRA SUPERIOR ELEGANTE (ESTILO FLYSKY / LIMPIO Y MINIMALISTA)   */}
        {/* =============================================================== */}
        <header className="flex flex-col sm:flex-row items-center justify-between gap-4 pb-6 border-b border-slate-100">
          {/* LOGO LIMPIO */}
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-slate-900 text-white flex items-center justify-center font-black text-sm tracking-tighter shadow-sm">
              DA
            </div>
            <div>
              <h1 className="font-extrabold text-base sm:text-lg text-slate-900 tracking-tight leading-tight">
                Divina Acuática
              </h1>
              <span className="text-xs text-slate-400 font-medium block">
                Playa Parguito • Sunsol Isla Caribe
              </span>
            </div>
          </div>

          {/* PÍLDORA DE NAVEGACIÓN CENTRADA */}
          <nav className="flex items-center gap-1 bg-slate-100/90 p-1.5 rounded-full border border-slate-200/70 text-xs font-semibold text-slate-600">
            <button
              type="button"
              onClick={() => setCurrentView('flota')}
              className={`px-4 py-2 rounded-full transition-all cursor-pointer ${
                currentView === 'flota'
                  ? 'bg-white text-slate-900 font-bold shadow-sm'
                  : 'hover:text-slate-900'
              }`}
            >
              Flota (3)
            </button>
            <button
              type="button"
              onClick={() => setCurrentView('agenda')}
              className={`px-4 py-2 rounded-full transition-all cursor-pointer ${
                currentView === 'agenda'
                  ? 'bg-white text-slate-900 font-bold shadow-sm'
                  : 'hover:text-slate-900'
              }`}
            >
              Agenda & Turnos
            </button>
            <button
              type="button"
              onClick={() => setCurrentView('radar')}
              className={`px-4 py-2 rounded-full transition-all cursor-pointer ${
                currentView === 'radar'
                  ? 'bg-white text-slate-900 font-bold shadow-sm'
                  : 'hover:text-slate-900'
              }`}
            >
              Radar Clientes
            </button>
            <button
              type="button"
              onClick={() => setCurrentView('caja')}
              className={`px-4 py-2 rounded-full transition-all cursor-pointer ${
                currentView === 'caja'
                  ? 'bg-white text-slate-900 font-bold shadow-sm'
                  : 'hover:text-slate-900'
              }`}
            >
              Caja BCV
            </button>
            <button
              type="button"
              onClick={() => setCurrentView('waiver')}
              className={`px-4 py-2 rounded-full transition-all cursor-pointer ${
                currentView === 'waiver'
                  ? 'bg-white text-slate-900 font-bold shadow-sm'
                  : 'hover:text-slate-900'
              }`}
            >
              Waiver
            </button>
          </nav>

          {/* BADGE OPERATIVO DERECHA */}
          <div className="hidden lg:flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
            <span className="text-xs font-mono font-semibold text-slate-500">
              Canal VHF Ch-68
            </span>
          </div>
        </header>

        {/* VISTAS */}
        <main>
          {currentView === 'flota' && <DashboardPlaya />}
          {currentView === 'agenda' && <AgendaHorariosYTickets />}
          {currentView === 'radar' && <PantallaTurnosClientes />}
          {currentView === 'caja' && <CalculadoraCajaBCV />}
          {currentView === 'waiver' && (
            <div className="pt-6">
              <RegistroFirmaWaiver />
            </div>
          )}
        </main>
      </div>
    </div>
  );
}

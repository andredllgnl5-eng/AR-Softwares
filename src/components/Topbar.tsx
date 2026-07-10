import { Bell, ChevronDown, Command, Menu, Search, Wifi } from 'lucide-react';
import { useState } from 'react';
import { useApp } from '../contexts/AppContext';

export function Topbar() {
  const { activeCompany, companies, selectCompany, user, demoMode } = useApp();
  const [open, setOpen] = useState(false);
  return (
    <header className="topbar">
      <button className="icon-button mobile-menu"><Menu size={20}/></button>
      <div className="company-switcher">
        <button onClick={() => setOpen(!open)} className="company-switcher__button">
          <span className="company-avatar">{activeCompany?.trade_name.slice(0, 2).toUpperCase()}</span>
          <span><small>Empresa ativa</small><strong>{activeCompany?.trade_name}</strong></span>
          <ChevronDown size={16}/>
        </button>
        {open && <div className="company-menu panel-glass">
          <div className="company-menu__search"><Search size={16}/><input placeholder="Pesquisar empresa"/></div>
          {companies.map((company) => <button key={company.id} onClick={() => { selectCompany(company); setOpen(false); }} className={company.id === activeCompany?.id ? 'selected' : ''}><span className="company-avatar small">{company.trade_name.slice(0,2).toUpperCase()}</span><span><strong>{company.trade_name}</strong><small>{company.role}</small></span></button>)}
          <button className="company-menu__add">+ Cadastrar nova empresa</button>
        </div>}
      </div>
      <button className="global-search"><Search size={18}/><span>Pesquisar clientes, produtos, pedidos...</span><kbd><Command size={13}/> K</kbd></button>
      <div className="topbar__actions">
        {demoMode && <span className="status-pill"><Wifi size={13}/> Modo demonstração</span>}
        <button className="icon-button"><Bell size={18}/><i/></button>
        <button className="profile-button"><span>{user?.full_name?.slice(0,1).toUpperCase()}</span><div><strong>{user?.full_name}</strong><small>Administrador</small></div><ChevronDown size={15}/></button>
      </div>
    </header>
  );
}

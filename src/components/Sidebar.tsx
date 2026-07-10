import { NavLink } from 'react-router-dom';
import { BarChart3, Box, BriefcaseBusiness, Building2, CalendarDays, CircleDollarSign, FileText, LayoutDashboard, Settings, ShoppingBag, Sparkles, Users } from 'lucide-react';
import { Logo } from './Logo';

const items = [
  ['/', 'Dashboard', LayoutDashboard],
  ['/companies', 'Empresas', Building2],
  ['/customers', 'Clientes', Users],
  ['/products', 'Produtos', Box],
  ['/catalog', 'Catálogo', ShoppingBag],
  ['/quotes', 'Orçamentos', FileText],
  ['/orders', 'Pedidos', BriefcaseBusiness],
  ['/crm', 'CRM', BarChart3],
  ['/agenda', 'Agenda', CalendarDays],
  ['/finance', 'Financeiro', CircleDollarSign],
] as const;

export function Sidebar() {
  return (
    <aside className="sidebar">
      <Logo />
      <nav className="sidebar__nav">
        {items.map(([to, label, Icon]) => <NavLink key={to} to={to} end={to === '/'} className={({ isActive }) => `nav-item ${isActive ? 'is-active' : ''}`}><Icon size={18}/><span>{label}</span></NavLink>)}
      </nav>
      <div className="sidebar__bottom">
        <NavLink to="/ai" className="nav-item nav-item--ai"><Sparkles size={18}/><span>IA Comercial</span><b>Beta</b></NavLink>
        <NavLink to="/settings" className="nav-item"><Settings size={18}/><span>Configurações</span></NavLink>
      </div>
    </aside>
  );
}

import { ArrowRight, Building2, Plus, Search, Sparkles } from 'lucide-react';
import { Navigate, useNavigate } from 'react-router-dom';
import { Logo } from '../components/Logo';
import { useApp } from '../contexts/AppContext';

export function Workspaces() {
  const { user, companies, activeCompany, selectCompany } = useApp();
  const navigate = useNavigate();
  if (!user) return <Navigate to="/login" replace/>;
  if (activeCompany) return <Navigate to="/" replace/>;
  return <div className="workspace-page"><div className="workspace-page__glow"/><header><Logo/><div className="workspace-user"><span>{user.full_name.slice(0,1)}</span><div><strong>{user.full_name}</strong><small>{user.email}</small></div></div></header><main><span className="eyebrow"><Sparkles size={14}/> Seus ambientes de trabalho</span><h1>Escolha uma empresa</h1><p>Todo o AR Sales será carregado com os dados e a identidade visual do workspace selecionado.</p><div className="workspace-search"><Search/><input placeholder="Pesquisar empresa..."/></div><div className="workspace-grid">{companies.map((company)=><button key={company.id} className="workspace-card" style={{'--company-accent': company.primary_color} as React.CSSProperties} onClick={()=>{selectCompany(company);navigate('/');}}><span className="workspace-card__logo">{company.trade_name.slice(0,2).toUpperCase()}</span><div><strong>{company.trade_name}</strong><small>{company.legal_name}</small><span>{company.role}</span></div><ArrowRight/></button>)}<button className="workspace-card workspace-card--new"><span className="workspace-card__logo"><Plus/></span><div><strong>Nova empresa</strong><small>Crie um novo workspace comercial</small></div></button></div></main><footer><Building2 size={15}/> {companies.length} empresas vinculadas à sua conta</footer></div>;
}

import { ArrowRight, Check, Eye, EyeOff, LockKeyhole, Mail, ShieldCheck, Sparkles } from 'lucide-react';
import { useState, type FormEvent } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import { Logo } from '../components/Logo';
import { useApp } from '../contexts/AppContext';

export function Login() {
  const { user, activeCompany, signIn, demoMode } = useApp();
  const navigate = useNavigate();
  const [email, setEmail] = useState(demoMode ? 'demo@arsoftwares.com.br' : '');
  const [password, setPassword] = useState(demoMode ? '12345678' : '');
  const [show, setShow] = useState(false);
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);
  if (user) return <Navigate to={activeCompany ? '/' : '/workspaces'} replace/>;
  const submit = async (event: FormEvent) => {
    event.preventDefault(); setError(''); setSubmitting(true);
    try { await signIn(email, password); navigate('/workspaces'); } catch (e) { setError(e instanceof Error ? e.message : 'Não foi possível entrar.'); } finally { setSubmitting(false); }
  };
  return <div className="auth-page">
    <section className="auth-visual">
      <div className="auth-grid"/><div className="orb orb--one"/><div className="orb orb--two"/>
      <Logo/>
      <div className="auth-copy"><span className="eyebrow"><Sparkles size={14}/> Nova geração em vendas B2B</span><h1>Um workspace.<br/><em>Empresas ilimitadas.</em></h1><p>Gerencie clientes, catálogos, propostas, pedidos e equipes em uma experiência comercial única.</p><div className="auth-benefits"><span><Check/>Multiempresa de verdade</span><span><Check/>Operação online e offline</span><span><Check/>Segurança por workspace</span></div></div>
      <div className="floating-card floating-card--sales"><small>Vendas no mês</small><strong>R$ 284.500</strong><span>+18,4% este mês</span></div>
      <div className="floating-card floating-card--ai"><Sparkles size={17}/><div><strong>IA Comercial</strong><small>4 novas oportunidades encontradas</small></div></div>
      <small className="auth-footer">AR Softwares © 2026</small>
    </section>
    <section className="auth-form-wrap"><form onSubmit={submit} className="auth-form"><div className="mobile-brand"><Logo/></div><span className="auth-form__icon"><ShieldCheck/></span><h2>Bem-vindo ao AR Sales</h2><p>Acesse seu workspace comercial inteligente.</p>
      <label>E-mail<div className="input-wrap"><Mail size={17}/><input type="email" value={email} onChange={(e)=>setEmail(e.target.value)} placeholder="seu@email.com" required/></div></label>
      <label>Senha<div className="input-wrap"><LockKeyhole size={17}/><input type={show?'text':'password'} value={password} onChange={(e)=>setPassword(e.target.value)} placeholder="Sua senha" required minLength={6}/><button type="button" onClick={()=>setShow(!show)}>{show?<EyeOff size={17}/>:<Eye size={17}/>}</button></div></label>
      <div className="form-row"><label className="checkbox"><input type="checkbox" defaultChecked/> Manter conectado</label><a href="#">Esqueci minha senha</a></div>
      {error && <div className="form-error">{error}</div>}
      <button className="primary-button" disabled={submitting}>{submitting?'Entrando...':'Entrar no AR Sales'}<ArrowRight size={18}/></button>
      {demoMode && <div className="demo-hint"><strong>Ambiente demonstrativo</strong><span>As credenciais já estão preenchidas.</span></div>}
      <p className="security-note"><LockKeyhole size={13}/> Seus dados são protegidos com segurança de nível empresarial.</p>
    </form></section>
  </div>;
}

import { BrowserRouter, Route, Routes } from 'react-router-dom';
import { AppProvider } from './contexts/AppContext';
import { AppShell } from './components/AppShell';
import { Login } from './pages/Login';
import { Workspaces } from './pages/Workspaces';
import { Dashboard } from './pages/Dashboard';
import { Placeholder } from './pages/Placeholder';
import { Customers } from './pages/Customers';
import { Products } from './pages/Products';
import { Catalog } from './pages/Catalog';
export default function App(){return <BrowserRouter><AppProvider><Routes><Route path="/login" element={<Login/>}/><Route path="/workspaces" element={<Workspaces/>}/><Route element={<AppShell/>}><Route index element={<Dashboard/>}/><Route path="companies" element={<Placeholder title="Empresas" description="Gerencie workspaces, identidades visuais, usuários e configurações."/>}/><Route path="customers" element={<Customers/>}/><Route path="products" element={<Products/>}/><Route path="catalog" element={<Catalog/>}/><Route path="quotes" element={<Placeholder title="Orçamentos" description="Criação, personalização, aprovação e geração de propostas."/>}/><Route path="orders" element={<Placeholder title="Pedidos" description="Conversão de propostas e acompanhamento da operação."/>}/><Route path="crm" element={<Placeholder title="CRM" description="Pipeline, oportunidades, tarefas e relacionamento."/>}/><Route path="agenda" element={<Placeholder title="Agenda" description="Visitas, reuniões, rotas e follow-ups."/>}/><Route path="finance" element={<Placeholder title="Financeiro" description="Comissões, metas e indicadores comerciais."/>}/><Route path="ai" element={<Placeholder title="IA Comercial" description="Recomendações e automações inteligentes para sua equipe."/>}/><Route path="settings" element={<Placeholder title="Configurações" description="Preferências, segurança, permissões e integrações."/>}/></Route></Routes></AppProvider></BrowserRouter>}

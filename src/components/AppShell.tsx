import { Outlet, Navigate } from 'react-router-dom';
import { useApp } from '../contexts/AppContext';
import { Sidebar } from './Sidebar';
import { Topbar } from './Topbar';

export function AppShell() {
  const { user, activeCompany, loading } = useApp();
  if (loading) return <div className="splash"><div className="loader"/><strong>Preparando seu workspace...</strong></div>;
  if (!user) return <Navigate to="/login" replace/>;
  if (!activeCompany) return <Navigate to="/workspaces" replace/>;
  return <div className="app-shell"><Sidebar/><main className="app-main"><Topbar/><div className="page-area"><Outlet/></div></main></div>;
}

import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { supabase, isSupabaseConfigured } from '../lib/supabase';
import { demoCompanies, demoUser } from '../lib/demo';
import type { Company, UserProfile } from '../lib/types';

type AppContextValue = {
  user: UserProfile | null;
  companies: Company[];
  activeCompany: Company | null;
  loading: boolean;
  demoMode: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  selectCompany: (company: Company) => void;
};

const AppContext = createContext<AppContextValue | null>(null);
const ACTIVE_COMPANY_KEY = 'ar-sales-active-company';

export function AppProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<UserProfile | null>(null);
  const [companies, setCompanies] = useState<Company[]>([]);
  const [activeCompany, setActiveCompany] = useState<Company | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const bootstrap = async () => {
      if (!supabase || !isSupabaseConfigured) {
        setUser(demoUser);
        setCompanies(demoCompanies);
        const stored = localStorage.getItem(ACTIVE_COMPANY_KEY);
        setActiveCompany(demoCompanies.find((company) => company.id === stored) ?? null);
        setLoading(false);
        return;
      }

      const { data } = await supabase.auth.getSession();
      if (!data.session?.user) {
        setLoading(false);
        return;
      }
      await loadAuthenticatedUser(data.session.user.id, data.session.user.email ?? '');
      setLoading(false);
    };

    void bootstrap();

    if (!supabase) return;
    const { data: subscription } = supabase.auth.onAuthStateChange((_event, session) => {
      if (!session?.user) {
        setUser(null);
        setCompanies([]);
        setActiveCompany(null);
        return;
      }
      void loadAuthenticatedUser(session.user.id, session.user.email ?? '');
    });
    return () => subscription.subscription.unsubscribe();
  }, []);

  const loadAuthenticatedUser = async (userId: string, email: string) => {
    if (!supabase) return;
    const [{ data: profile }, { data: memberships, error }] = await Promise.all([
      supabase.from('profiles').select('id, full_name, avatar_url').eq('id', userId).maybeSingle(),
      supabase
        .from('company_members')
        .select('company_id, companies(id, trade_name, legal_name, logo_url, primary_color), roles(name)')
        .eq('user_id', userId)
        .eq('status', 'active'),
    ]);
    if (error) throw error;
    setUser({ id: userId, email, full_name: profile?.full_name || email.split('@')[0], avatar_url: profile?.avatar_url });
    const normalized = (memberships ?? []).flatMap((membership: any) => {
      const company = Array.isArray(membership.companies) ? membership.companies[0] : membership.companies;
      const role = Array.isArray(membership.roles) ? membership.roles[0] : membership.roles;
      return company ? [{ ...company, role: role?.name ?? 'Membro' } as Company] : [];
    });
    setCompanies(normalized);
    const stored = localStorage.getItem(ACTIVE_COMPANY_KEY);
    setActiveCompany(normalized.find((company) => company.id === stored) ?? null);
  };

  const signIn = async (email: string, password: string) => {
    if (!supabase) {
      setUser(demoUser);
      setCompanies(demoCompanies);
      return;
    }
    const { error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) throw error;
  };

  const signOut = async () => {
    localStorage.removeItem(ACTIVE_COMPANY_KEY);
    if (supabase) await supabase.auth.signOut();
    setUser(null);
    setCompanies([]);
    setActiveCompany(null);
  };

  const selectCompany = (company: Company) => {
    localStorage.setItem(ACTIVE_COMPANY_KEY, company.id);
    document.documentElement.style.setProperty('--accent', company.primary_color || '#2f7cff');
    setActiveCompany(company);
  };

  const value = useMemo(() => ({ user, companies, activeCompany, loading, demoMode: !isSupabaseConfigured, signIn, signOut, selectCompany }), [user, companies, activeCompany, loading]);
  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useApp() {
  const context = useContext(AppContext);
  if (!context) throw new Error('useApp deve ser usado dentro de AppProvider');
  return context;
}

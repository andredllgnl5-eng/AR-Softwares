import type { Company, UserProfile } from './types';

export const demoUser: UserProfile = {
  id: 'demo-user',
  full_name: 'André Dallagnol',
  email: 'andre@arsoftwares.com.br',
};

export const demoCompanies: Company[] = [
  { id: 'refri', trade_name: 'Refri', legal_name: 'Refri Soluções Térmicas', primary_color: '#2f7cff', role: 'Administrador' },
  { id: 'refro', trade_name: 'Refro', legal_name: 'Refro Refrigeração', primary_color: '#8b5cf6', role: 'Representante' },
  { id: 'jelly', trade_name: 'Jelly Fish', legal_name: 'Jelly Fish Água Quente', primary_color: '#00b8a9', role: 'Administrador' },
  { id: 'tosi', trade_name: 'Tosi', legal_name: 'Indústrias Tosi', primary_color: '#c77935', role: 'Vendedor' },
];

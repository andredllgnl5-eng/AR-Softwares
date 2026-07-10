export type Company = {
  id: string;
  trade_name: string;
  legal_name?: string;
  logo_url?: string | null;
  primary_color?: string | null;
  role?: string;
};

export type UserProfile = {
  id: string;
  full_name: string;
  email: string;
  avatar_url?: string | null;
};

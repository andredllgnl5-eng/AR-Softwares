# AR Sales — Frontend V1

Primeira versão funcional do workspace comercial da AR Softwares.

## Incluído

- Login premium
- Modo demonstração sem configuração externa
- Seleção de empresas/workspaces
- Troca dinâmica da empresa ativa
- Tema visual adaptado à cor da empresa
- Dashboard executivo responsivo
- Sidebar completa
- Agenda, pipeline, KPIs, propostas recentes e IA comercial
- Rotas preparadas para todos os módulos principais
- Integração com Supabase Auth, profiles, company_members, companies e roles
- Migration SQL inicial em `supabase/migrations`

## Executar

```bash
npm install
npm run dev
```

Abra `http://localhost:5173`.

## Modo demonstração

Sem arquivo `.env`, o sistema entra automaticamente em modo demonstrativo. As credenciais aparecem preenchidas na tela de login.

## Conectar ao Supabase

1. Copie `.env.example` para `.env`.
2. Informe `VITE_SUPABASE_URL` e `VITE_SUPABASE_ANON_KEY`.
3. Execute a migration SQL no Supabase.
4. Crie um usuário no Supabase Auth e vincule-o a uma empresa em `company_members`.
5. Reinicie o servidor de desenvolvimento.

## Produção

```bash
npm run build
```

A compilação foi validada com sucesso. Os arquivos finais serão gerados em `dist/`.

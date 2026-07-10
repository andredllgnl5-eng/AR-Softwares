export function Logo({ compact = false }: { compact?: boolean }) {
  return (
    <div className={`brand ${compact ? 'brand--compact' : ''}`} aria-label="AR Sales">
      <div className="brand__mark"><span>A</span><span>R</span></div>
      {!compact && <div><strong>AR Sales</strong><small>Workspace comercial</small></div>}
    </div>
  );
}

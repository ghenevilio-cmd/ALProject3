function ReceivingShell({ children, header, sidebar, content, stacked = false }) {
  return (
    <div
      style={{
        width: '100%',
        height: '100%',
        minHeight: '100%',
        display: 'flex',
        flexDirection: 'column',
        padding: stacked ? '16px' : '24px 24px 24px 16px',
        color: '#132238',
      }}
    >
      <div
        style={{
          width: '100%',
          height: '100%',
          minHeight: 0,
          display: 'grid',
          gridTemplateRows: 'auto minmax(0, 1fr)',
          gap: '18px',
        }}
      >
        {header}

        <section
          style={{
            display: 'grid',
            gridTemplateColumns: stacked ? 'minmax(0, 1fr)' : 'minmax(280px, 400px) minmax(0, 1fr)',
            gap: '16px',
            alignItems: stacked ? 'start' : 'stretch',
            minHeight: 0,
          }}
        >
          <div
            style={{
              display: 'grid',
              gap: '18px',
              minWidth: 0,
              alignContent: 'start',
              gridAutoRows: 'max-content',
            }}
          >
            {sidebar}
          </div>

          <div style={{ minWidth: 0, minHeight: 0, paddingLeft: stacked ? 0 : '16px', height: '100%' }}>{content}</div>
        </section>

        {children}
      </div>
    </div>
  );
}

export function Panel({ title, subtitle, children, noPadding = false, style }) {
  return (
    <section
      style={{
        background: 'rgba(255,255,255,0.82)',
        border: '1px solid rgba(255,255,255,0.55)',
        borderRadius: '24px',
        boxShadow: '0 18px 40px rgba(19, 34, 56, 0.08)',
        backdropFilter: 'blur(18px)',
        overflow: noPadding ? 'visible' : 'hidden',
        minWidth: 0,
        ...style,
      }}
    >
      <div style={{ padding: '16px 20px 8px' }}>
        <div style={{ fontSize: '18px', fontWeight: 800, color: '#132238' }}>{title}</div>
        <div style={{ marginTop: '4px', fontSize: '13px', color: '#5a6c81' }}>{subtitle}</div>
      </div>
      <div style={noPadding ? undefined : { padding: '10px 20px 18px' }}>{children}</div>
    </section>
  );
}

export function InfoCard({ label, value }) {
  return (
    <div
      style={{
        borderRadius: '18px',
        padding: '16px',
        background: 'rgba(255,255,255,0.12)',
        border: '1px solid rgba(255,255,255,0.18)',
        minHeight: '92px',
      }}
    >
      <div style={{ fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.08em' }}>
        {label}
      </div>
      <div style={{ marginTop: '10px', fontSize: '20px', fontWeight: 800, wordBreak: 'break-word' }}>
        {value}
      </div>
    </div>
  );
}

export function MetricRow({ label, value, tone, active = false, onClick }) {
  const interactive = typeof onClick === 'function';

  return (
    <div
      onClick={onClick}
      style={{
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        padding: '14px 16px',
        borderRadius: '18px',
        background: active
          ? 'linear-gradient(180deg, rgba(224, 242, 254, 0.95) 0%, rgba(219, 234, 254, 0.95) 100%)'
          : 'linear-gradient(180deg, #ffffff 0%, #f6fafc 100%)',
        border: active ? `1px solid ${tone}` : '1px solid rgba(19, 34, 56, 0.08)',
        cursor: interactive ? 'pointer' : 'default',
        transition: 'transform 160ms ease, box-shadow 160ms ease, border-color 160ms ease',
        boxShadow: active ? '0 12px 24px rgba(29, 78, 216, 0.12)' : 'none',
      }}
    >
      <span style={{ color: '#41546a', fontWeight: 600 }}>{label}</span>
      <span style={{ color: tone, fontSize: '22px', fontWeight: 800 }}>{value}</span>
    </div>
  );
}

export function StatusPill({ status }) {
  const isFullyReceived = status === 'Fully Received';
  const isPartial = status === 'Partial';
  const isReleased = status === 'Released';
  const isLateReleased = status === 'Late Released';

  return (
    <span
      style={{
        display: 'inline-flex',
        alignItems: 'center',
        justifyContent: 'center',
        borderRadius: '999px',
        padding: '8px 12px',
        background: isFullyReceived
          ? 'rgba(22, 163, 74, 0.14)'
          : isPartial
            ? 'rgba(217, 119, 6, 0.14)'
            : isLateReleased
              ? 'rgba(185, 28, 28, 0.14)'
              : isReleased
                ? 'rgba(15, 118, 110, 0.14)'
                : 'rgba(29, 78, 216, 0.14)',
        color: isFullyReceived ? '#15803d' : isPartial ? '#b45309' : isLateReleased ? '#b91c1c' : isReleased ? '#0f766e' : '#1d4ed8',
        fontWeight: 800,
        fontSize: '12px',
      }}
    >
      {status || '-'}
    </span>
  );
}

export default ReceivingShell;

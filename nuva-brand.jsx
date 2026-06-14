// nuva-brand.jsx — logo marks (3 directions), Liquid Glass app icon, wordmark.
// Marks are built from circles/arcs only (no illustrative SVG).

// Concentric "ripple" mark — the support-spreading metaphor
function RippleMark({ size = 48, color = '#2E6FD6', accent = '#0FA995', variant = 'ripple' }) {
  const c = 24;
  if (variant === 'dawn') {
    // new dawn: rising arc over horizon + soft rays
    return (
      <svg width={size} height={size} viewBox="0 0 48 48" style={{ display: 'block' }}>
        <defs>
          <linearGradient id="nv-dawn" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor={accent}/><stop offset="1" stopColor={color}/>
          </linearGradient>
        </defs>
        <path d="M8 30a16 16 0 0 1 32 0" fill="none" stroke="url(#nv-dawn)" strokeWidth="3.4" strokeLinecap="round"/>
        <line x1="6" y1="36" x2="42" y2="36" stroke={color} strokeWidth="3.4" strokeLinecap="round"/>
        <line x1="13" y1="41" x2="35" y2="41" stroke={color} strokeWidth="3.4" strokeLinecap="round" opacity="0.45"/>
        <circle cx="24" cy="30" r="4.5" fill={accent}/>
      </svg>
    );
  }
  if (variant === 'together') {
    // two forms drawing close — "not alone"
    return (
      <svg width={size} height={size} viewBox="0 0 48 48" style={{ display: 'block' }}>
        <defs>
          <linearGradient id="nv-tg" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0" stopColor={color}/><stop offset="1" stopColor={accent}/>
          </linearGradient>
        </defs>
        <circle cx="18" cy="24" r="11.5" fill="none" stroke={color} strokeWidth="3.4"/>
        <circle cx="30" cy="24" r="11.5" fill="none" stroke={accent} strokeWidth="3.4"/>
        <path d="M24 15.2a11.4 11.4 0 0 1 0 17.6 11.4 11.4 0 0 1 0-17.6Z" fill="url(#nv-tg)" opacity="0.9"/>
      </svg>
    );
  }
  // default ripple — concentric rings + center
  return (
    <svg width={size} height={size} viewBox="0 0 48 48" style={{ display: 'block' }}>
      <defs>
        <linearGradient id="nv-rp" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor={accent}/><stop offset="1" stopColor={color}/>
        </linearGradient>
      </defs>
      <circle cx={c} cy={c} r="20" fill="none" stroke={color} strokeWidth="2.2" opacity="0.30"/>
      <circle cx={c} cy={c} r="14" fill="none" stroke={color} strokeWidth="2.8" opacity="0.55"/>
      <circle cx={c} cy={c} r="8" fill="none" stroke="url(#nv-rp)" strokeWidth="3.2"/>
      <circle cx={c} cy={c} r="3" fill={accent}/>
    </svg>
  );
}

// Wordmark
function Wordmark({ size = 30, color = '#0E1E33', weight = 600 }) {
  return (
    <span className="nuva-font" style={{
      fontSize: size, fontWeight: weight, letterSpacing: -0.5, color,
      lineHeight: 1, display: 'inline-block',
    }}>Nuva</span>
  );
}

// Full lockup: mark + wordmark
function LogoLockup({ variant = 'ripple', dark = false, size = 40 }) {
  const color = dark ? '#5EA0F0' : '#2E6FD6';
  const accent = dark ? '#36C9B6' : '#0FA995';
  const txt = dark ? '#EAF1FB' : '#0E1E33';
  return (
    <div style={{ display: 'inline-flex', alignItems: 'center', gap: 12 }}>
      <RippleMark size={size} color={color} accent={accent} variant={variant} />
      <Wordmark size={size * 0.78} color={txt} />
    </div>
  );
}

// ───────────────────────────────────────────────────────────
// Liquid Glass app icon — layered glass squircle + ripple depth
// ───────────────────────────────────────────────────────────
function AppIcon({ size = 120 }) {
  const r = Math.round(size * 0.225);
  return (
    <div style={{
      width: size, height: size, borderRadius: r, position: 'relative', overflow: 'hidden',
      background: 'linear-gradient(150deg, #3E86E6 0%, #2E6FD6 45%, #0FA995 130%)',
      boxShadow: `0 ${size*0.10}px ${size*0.22}px rgba(20,50,110,0.35), inset 0 1px 1px rgba(255,255,255,0.5)`,
    }}>
      {/* depth blobs */}
      <div style={{ position: 'absolute', inset: 0,
        background: 'radial-gradient(circle at 28% 22%, rgba(255,255,255,0.55), transparent 45%)' }} />
      <div style={{ position: 'absolute', inset: 0,
        background: 'radial-gradient(circle at 80% 95%, rgba(15,169,149,0.7), transparent 55%)' }} />
      {/* glass ripple rings */}
      <svg width={size} height={size} viewBox="0 0 120 120" style={{ position: 'absolute', inset: 0 }}>
        <circle cx="60" cy="62" r="44" fill="none" stroke="rgba(255,255,255,0.30)" strokeWidth="4"/>
        <circle cx="60" cy="62" r="30" fill="none" stroke="rgba(255,255,255,0.55)" strokeWidth="5"/>
        <circle cx="60" cy="62" r="16" fill="none" stroke="rgba(255,255,255,0.9)" strokeWidth="5.5"/>
        <circle cx="60" cy="62" r="5.5" fill="#fff"/>
      </svg>
      {/* top specular sheen */}
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, height: '46%',
        background: 'linear-gradient(180deg, rgba(255,255,255,0.4), transparent)',
        borderTopLeftRadius: r, borderTopRightRadius: r }} />
      {/* edge highlight */}
      <div style={{ position: 'absolute', inset: 0, borderRadius: r,
        boxShadow: 'inset 0 0 0 1px rgba(255,255,255,0.35), inset 0 -2px 6px rgba(10,40,90,0.25)' }} />
    </div>
  );
}

Object.assign(window, { RippleMark, Wordmark, LogoLockup, AppIcon });

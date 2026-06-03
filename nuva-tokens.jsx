// nuva-tokens.jsx — Liquid Glass design tokens, phone frame, glass primitives, icons.
// Pairs with lib/ios-frame.jsx (IOSStatusBar). No `const styles` (scope-safe naming).

// ───────────────────────────────────────────────────────────
// Global style injection: font, keyframes, base reset
// ───────────────────────────────────────────────────────────
(function injectNuvaBase() {
  if (document.getElementById('nuva-base')) return;
  const s = document.createElement('style');
  s.id = 'nuva-base';
  s.textContent = `
    @import url('https://fonts.googleapis.com/css2?family=Onest:wght@300;400;500;600;700&display=swap');
    .nuva-font { font-family: 'Onest', -apple-system, system-ui, sans-serif; }
    @keyframes nuva-breathe { 0%,100%{ transform: scale(0.82); opacity:.55 } 50%{ transform: scale(1.12); opacity:1 } }
    @keyframes nuva-ripple { 0%{ transform: scale(.4); opacity:.65 } 100%{ transform: scale(1.7); opacity:0 } }
    @keyframes nuva-float { 0%,100%{ transform: translateY(0) } 50%{ transform: translateY(-6px) } }
    @media (prefers-reduced-motion: reduce) {
      .nuva-anim { animation: none !important; }
    }
    .nuva-scroll::-webkit-scrollbar { display:none; }
    .nuva-scroll { scrollbar-width:none; }
  `;
  document.head.appendChild(s);
})();

// ───────────────────────────────────────────────────────────
// Token palette per theme
// ───────────────────────────────────────────────────────────
function nuvaTokens(dark) {
  if (dark) {
    return {
      dark: true,
      text:       '#EAF1FB',
      textSec:    'rgba(225,235,250,0.62)',
      textTer:    'rgba(225,235,250,0.40)',
      blue:       '#5EA0F0',
      blueDeep:   '#3E7BD4',
      teal:       '#36C9B6',
      danger:     '#FF6B6B',
      // gradient backdrop layers
      bgBase:     'linear-gradient(180deg, #0B1626 0%, #0A1320 55%, #080F1A 100%)',
      blobA:      'radial-gradient(circle at 22% 16%, rgba(62,123,212,0.55), transparent 60%)',
      blobB:      'radial-gradient(circle at 84% 30%, rgba(54,201,182,0.30), transparent 55%)',
      blobC:      'radial-gradient(circle at 60% 96%, rgba(94,160,240,0.28), transparent 60%)',
      // glass
      glassBg:    'rgba(255,255,255,0.07)',
      glassBgUp:  'rgba(255,255,255,0.11)',
      glassBorder:'rgba(255,255,255,0.16)',
      glassShadow:'0 10px 34px rgba(0,0,0,0.45)',
      glassShine: 'inset 0 1px 0 rgba(255,255,255,0.22), inset 0 -1px 0 rgba(255,255,255,0.05)',
      hairline:   'rgba(255,255,255,0.10)',
      chipBg:     'rgba(255,255,255,0.09)',
    };
  }
  return {
    dark: false,
    text:       '#0E1E33',
    textSec:    'rgba(14,30,51,0.60)',
    textTer:    'rgba(14,30,51,0.40)',
    blue:       '#2E6FD6',
    blueDeep:   '#1E56B8',
    teal:       '#0FA995',
    danger:     '#E0484D',
    bgBase:     'linear-gradient(180deg, #EDF3FB 0%, #E6EEFA 50%, #E9F2F6 100%)',
    blobA:      'radial-gradient(circle at 20% 14%, rgba(120,170,240,0.55), transparent 58%)',
    blobB:      'radial-gradient(circle at 86% 26%, rgba(70,200,184,0.34), transparent 52%)',
    blobC:      'radial-gradient(circle at 64% 98%, rgba(150,185,245,0.45), transparent 60%)',
    glassBg:    'rgba(255,255,255,0.55)',
    glassBgUp:  'rgba(255,255,255,0.72)',
    glassBorder:'rgba(255,255,255,0.85)',
    glassShadow:'0 10px 30px rgba(30,60,110,0.12)',
    glassShine: 'inset 0 1px 0 rgba(255,255,255,0.9), inset 0 -1px 0 rgba(255,255,255,0.4)',
    hairline:   'rgba(20,45,85,0.10)',
    chipBg:     'rgba(255,255,255,0.6)',
  };
}

// ───────────────────────────────────────────────────────────
// Phone frame with refractive Liquid Glass backdrop
// ───────────────────────────────────────────────────────────
function NuvaPhone({ dark = false, children, width = 360, height = 780, scroll = false }) {
  const t = nuvaTokens(dark);
  return (
    <div className="nuva-font" style={{
      width, height, borderRadius: 46, position: 'relative', overflow: 'hidden',
      boxShadow: '0 50px 90px rgba(20,40,80,0.22), 0 0 0 1px rgba(0,0,0,0.10)',
      WebkitFontSmoothing: 'antialiased',
    }}>
      {/* refractive backdrop */}
      <div style={{ position: 'absolute', inset: 0, background: t.bgBase }} />
      <div style={{ position: 'absolute', inset: 0, background: t.blobA }} />
      <div style={{ position: 'absolute', inset: 0, background: t.blobB }} />
      <div style={{ position: 'absolute', inset: 0, background: t.blobC }} />

      {/* dynamic island */}
      <div style={{
        position: 'absolute', top: 11, left: '50%', transform: 'translateX(-50%)',
        width: 116, height: 34, borderRadius: 20, background: '#000', zIndex: 50,
      }} />
      {/* status bar */}
      <div style={{ position: 'absolute', top: 0, left: 0, right: 0, zIndex: 40 }}>
        {window.IOSStatusBar ? <IOSStatusBar dark={dark} /> : null}
      </div>

      {/* content */}
      <div className={scroll ? 'nuva-scroll' : ''} style={{
        position: 'absolute', inset: 0, paddingTop: 54, zIndex: 10,
        display: 'flex', flexDirection: 'column',
        overflowY: scroll ? 'auto' : 'hidden',
      }}>
        {children}
      </div>

      {/* home indicator */}
      <div style={{
        position: 'absolute', bottom: 8, left: 0, right: 0, zIndex: 60,
        display: 'flex', justifyContent: 'center', pointerEvents: 'none',
      }}>
        <div style={{ width: 128, height: 5, borderRadius: 100,
          background: dark ? 'rgba(255,255,255,0.65)' : 'rgba(14,30,51,0.28)' }} />
      </div>
    </div>
  );
}

// ───────────────────────────────────────────────────────────
// Glass primitives
// ───────────────────────────────────────────────────────────
function GlassCard({ dark, children, style = {}, radius = 28, raised = false, onClick }) {
  const t = nuvaTokens(dark);
  return (
    <div onClick={onClick} style={{
      position: 'relative', borderRadius: radius, flexShrink: 0,
      background: raised ? t.glassBgUp : t.glassBg,
      backdropFilter: 'blur(30px) saturate(180%)', WebkitBackdropFilter: 'blur(30px) saturate(180%)',
      border: `1px solid ${t.glassBorder}`,
      boxShadow: `${t.glassShadow}, ${t.glassShine}`,
      ...style,
    }}>{children}</div>
  );
}

function GlassButton({ dark, children, variant = 'primary', onClick, style = {}, full = false }) {
  const t = nuvaTokens(dark);
  const base = {
    height: 54, borderRadius: 16, border: 'none', cursor: 'pointer',
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8,
    fontFamily: 'Onest, system-ui', fontSize: 17, fontWeight: 600, letterSpacing: -0.2,
    width: full ? '100%' : undefined, padding: '0 24px', position: 'relative', overflow: 'hidden',
    ...style,
  };
  if (variant === 'primary') {
    return (
      <button onClick={onClick} style={{ ...base, color: '#fff',
        background: `linear-gradient(180deg, ${t.blue}, ${t.blueDeep})`,
        boxShadow: `0 8px 22px ${dark ? 'rgba(46,111,214,0.40)' : 'rgba(46,111,214,0.30)'}, inset 0 1px 0 rgba(255,255,255,0.35)`,
      }}>{children}</button>
    );
  }
  if (variant === 'danger') {
    return (
      <button onClick={onClick} style={{ ...base, color: '#fff',
        background: `linear-gradient(180deg, ${t.danger}, ${dark ? '#D43B40' : '#C73B40'})`,
        boxShadow: `0 8px 22px ${dark ? 'rgba(255,107,107,0.35)' : 'rgba(224,72,77,0.28)'}, inset 0 1px 0 rgba(255,255,255,0.3)`,
      }}>{children}</button>
    );
  }
  // glass
  return (
    <button onClick={onClick} style={{ ...base, color: t.text,
      background: t.glassBgUp,
      backdropFilter: 'blur(24px) saturate(180%)', WebkitBackdropFilter: 'blur(24px) saturate(180%)',
      border: `1px solid ${t.glassBorder}`,
      boxShadow: t.glassShine,
    }}>{children}</button>
  );
}

function Chip({ dark, children, active = false, onClick, icon }) {
  const t = nuvaTokens(dark);
  return (
    <button onClick={onClick} style={{
      height: 40, padding: '0 16px', borderRadius: 999, cursor: 'pointer',
      display: 'inline-flex', alignItems: 'center', gap: 7,
      fontFamily: 'Onest, system-ui', fontSize: 15, fontWeight: 500, letterSpacing: -0.1,
      color: active ? '#fff' : t.text,
      background: active ? `linear-gradient(180deg, ${t.blue}, ${t.blueDeep})` : t.chipBg,
      border: `1px solid ${active ? 'transparent' : t.glassBorder}`,
      backdropFilter: 'blur(20px) saturate(170%)', WebkitBackdropFilter: 'blur(20px) saturate(170%)',
      boxShadow: active ? `0 6px 16px ${dark ? 'rgba(46,111,214,0.4)' : 'rgba(46,111,214,0.25)'}` : t.glassShine,
    }}>{icon}{children}</button>
  );
}

// ───────────────────────────────────────────────────────────
// Floating glass tab bar
// ───────────────────────────────────────────────────────────
function FloatingTabBar({ dark, active = 0, t: tr }) {
  const k = nuvaTokens(dark);
  const items = [
    { icon: 'home', label: tr('tab_home') },
    { icon: 'search', label: tr('tab_find') },
    { icon: 'community', label: tr('tab_community') },
    { icon: 'calm', label: tr('tab_calm') },
    { icon: 'user', label: tr('tab_profile') },
  ];
  return (
    <div style={{
      position: 'absolute', left: 14, right: 14, bottom: 26, zIndex: 30,
      height: 66, borderRadius: 30, display: 'flex', alignItems: 'center',
      padding: '0 8px',
      background: k.glassBgUp,
      backdropFilter: 'blur(34px) saturate(190%)', WebkitBackdropFilter: 'blur(34px) saturate(190%)',
      border: `1px solid ${k.glassBorder}`,
      boxShadow: `${k.glassShadow}, ${k.glassShine}`,
    }}>
      {items.map((it, i) => {
        const on = i === active;
        return (
          <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column',
            alignItems: 'center', justifyContent: 'center', gap: 3 }}>
            <NuvaIcon name={it.icon} size={23} color={on ? k.blue : k.textTer} strokeWidth={on ? 2.2 : 1.9} />
            <span style={{ fontSize: 10.5, fontWeight: on ? 600 : 500,
              color: on ? k.blue : k.textTer, letterSpacing: -0.1 }}>{it.label}</span>
          </div>
        );
      })}
    </div>
  );
}

// ───────────────────────────────────────────────────────────
// Striped image placeholder (for photos we don't have)
// ───────────────────────────────────────────────────────────
function ImgPlaceholder({ dark, label = 'photo', style = {}, radius = 16 }) {
  const t = nuvaTokens(dark);
  const stroke = dark ? 'rgba(255,255,255,0.10)' : 'rgba(30,60,110,0.10)';
  return (
    <div style={{ position: 'relative', overflow: 'hidden', borderRadius: radius,
      background: dark ? 'rgba(255,255,255,0.04)' : 'rgba(30,60,110,0.05)',
      backgroundImage: `repeating-linear-gradient(45deg, ${stroke} 0 1px, transparent 1px 9px)`,
      display: 'flex', alignItems: 'center', justifyContent: 'center', ...style }}>
      <span style={{ fontFamily: 'ui-monospace, Menlo, monospace', fontSize: 10.5,
        letterSpacing: 0.3, color: t.textTer, textTransform: 'lowercase' }}>{label}</span>
    </div>
  );
}

// ───────────────────────────────────────────────────────────
// Line icon set (simple geometric strokes)
// ───────────────────────────────────────────────────────────
function NuvaIcon({ name, size = 24, color = 'currentColor', strokeWidth = 1.9 }) {
  const p = { fill: 'none', stroke: color, strokeWidth, strokeLinecap: 'round', strokeLinejoin: 'round' };
  const f = { fill: color };
  const paths = {
    home:      <><path {...p} d="M4 11.5 12 4l8 7.5"/><path {...p} d="M6 10v9h12v-9"/></>,
    search:    <><circle {...p} cx="11" cy="11" r="6.5"/><path {...p} d="m20 20-3.6-3.6"/></>,
    community: <><path {...p} d="M4 12a8 8 0 1 1 3.5 6.6L4 20l1.2-3.3"/><circle {...f} cx="9" cy="12" r="1.2"/><circle {...f} cx="13" cy="12" r="1.2"/><circle {...f} cx="17" cy="12" r="1.2"/></>,
    calm:      <><path {...p} d="M3 12c2.5 0 2.5-5 5-5s2.5 10 5 10 2.5-5 5-5"/></>,
    user:      <><circle {...p} cx="12" cy="8" r="4"/><path {...p} d="M5 20c0-3.9 3.1-6.5 7-6.5s7 2.6 7 6.5"/></>,
    sparkle:   <><path {...p} d="M12 3c.6 3.8 1.4 4.6 5.2 5.2C13.4 8.8 12.6 9.6 12 13.4 11.4 9.6 10.6 8.8 6.8 8.2 10.6 7.6 11.4 6.8 12 3Z"/><path {...p} d="M18.5 13c.3 1.7.7 2.1 2.5 2.4-1.8.3-2.2.7-2.5 2.4-.3-1.7-.7-2.1-2.5-2.4 1.8-.3 2.2-.7 2.5-2.4Z"/></>,
    shield:    <><path {...p} d="M12 3.5 19 6v5c0 4.6-3 7.8-7 9.5-4-1.7-7-4.9-7-9.5V6l7-2.5Z"/><path {...p} d="m9 11.5 2 2 4-4"/></>,
    star:      <path {...f} d="M12 3.5l2.5 5.4 5.9.6-4.4 4 1.2 5.8L12 16.9 6.8 19.3 8 13.5 3.6 9.5l5.9-.6L12 3.5Z"/>,
    heart:     <path {...p} d="M12 20s-7-4.3-7-9.3A3.8 3.8 0 0 1 12 8a3.8 3.8 0 0 1 7-2.3c0 5-7 9.3-7 9.3Z"/>,
    chevronR:  <path {...p} d="m9 5 7 7-7 7"/>,
    chevronL:  <path {...p} d="m15 5-7 7 7 7"/>,
    send:      <><path {...p} d="M12 19V6"/><path {...p} d="m6 11 6-6 6 6"/></>,
    play:      <path {...f} d="M8 5.5v13l11-6.5-11-6.5Z"/>,
    pause:     <><rect {...f} x="7" y="5" width="3.5" height="14" rx="1.2"/><rect {...f} x="13.5" y="5" width="3.5" height="14" rx="1.2"/></>,
    globe:     <><circle {...p} cx="12" cy="12" r="8.5"/><path {...p} d="M3.5 12h17M12 3.5c2.4 2.3 3.7 5.4 3.7 8.5S14.4 18.2 12 20.5c-2.4-2.3-3.7-5.4-3.7-8.5S9.6 5.8 12 3.5Z"/></>,
    sun:       <><circle {...p} cx="12" cy="12" r="4"/><path {...p} d="M12 2.5v2.5M12 19v2.5M2.5 12H5M19 12h2.5M5 5l1.8 1.8M17.2 17.2 19 19M19 5l-1.8 1.8M6.8 17.2 5 19"/></>,
    moon:      <path {...p} d="M20 13.5A8 8 0 1 1 10.5 4 6.5 6.5 0 0 0 20 13.5Z"/>,
    calendar:  <><rect {...p} x="4" y="5.5" width="16" height="15" rx="3"/><path {...p} d="M4 10h16M8 3.5v4M16 3.5v4"/></>,
    filter:    <path {...p} d="M4 6h16M7 12h10M10 18h4"/>,
    plus:      <path {...p} d="M12 5v14M5 12h14"/>,
    check:     <path {...p} d="m5 12 4.5 4.5L19 7"/>,
    video:     <><rect {...p} x="3.5" y="6.5" width="12" height="11" rx="3"/><path {...p} d="m15.5 10.5 5-3v9l-5-3"/></>,
    bell:      <><path {...p} d="M6 9a6 6 0 0 1 12 0c0 5 2 6 2 6H4s2-1 2-6Z"/><path {...p} d="M10 19a2 2 0 0 0 4 0"/></>,
    lock:      <><rect {...p} x="5" y="10.5" width="14" height="10" rx="3"/><path {...p} d="M8 10.5V8a4 4 0 0 1 8 0v2.5"/></>,
    bookmark:  <path {...p} d="M7 4.5h10v16l-5-3.5-5 3.5v-16Z"/>,
  };
  return <svg width={size} height={size} viewBox="0 0 24 24" style={{ display: 'block', flexShrink: 0 }}>{paths[name] || null}</svg>;
}

Object.assign(window, {
  nuvaTokens, NuvaPhone, GlassCard, GlassButton, Chip, FloatingTabBar, ImgPlaceholder, NuvaIcon,
});

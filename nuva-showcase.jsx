// nuva-showcase.jsx — gallery shell: floating glass header, brand, design system, screen pairs.
const { useState, useCallback } = React;

const SC_STRINGS = {
  ru: { brand: 'Бренд и иконка', system: 'Дизайн-система', screens: 'Ключевые экраны',
        logoOpts: 'Логотип — 3 направления', icon: 'Иконка приложения · Liquid Glass',
        palette: 'Палитра', type: 'Типографика — Onest', comps: 'Liquid Glass компоненты',
        light: 'Светлая', dark: 'Тёмная', langSw: 'Переключатель языка', sub: 'Приложение психологической поддержки · iOS',
        s_ob: '1 · Онбординг — приветствие', s_chat: '2 · Чат с ИИ — интейк', s_home: '3 · Главный экран',
        note: 'Нажмите RU / EN / FR или иконку темы — текст и подача меняются на месте.' },
  en: { brand: 'Brand & icon', system: 'Design system', screens: 'Key screens',
        logoOpts: 'Logo — 3 directions', icon: 'App icon · Liquid Glass',
        palette: 'Palette', type: 'Typography — Onest', comps: 'Liquid Glass components',
        light: 'Light', dark: 'Dark', langSw: 'Language switcher', sub: 'Mental-health support app · iOS',
        s_ob: '1 · Onboarding — welcome', s_chat: '2 · AI chat — intake', s_home: '3 · Home',
        note: 'Tap RU / EN / FR or the theme icon — copy and presentation update in place.' },
  fr: { brand: 'Marque et icône', system: 'Système de design', screens: 'Écrans clés',
        logoOpts: 'Logo — 3 directions', icon: 'Icône de l’app · Liquid Glass',
        palette: 'Palette', type: 'Typographie — Onest', comps: 'Composants Liquid Glass',
        light: 'Clair', dark: 'Sombre', langSw: 'Sélecteur de langue', sub: 'App de soutien psychologique · iOS',
        s_ob: '1 · Accueil — bienvenue', s_chat: '2 · Chat IA — orientation', s_home: '3 · Accueil',
        note: 'Touchez RU / EN / FR ou l’icône de thème — le texte et la présentation changent sur place.' },
};

function galleryColors(dark) {
  return dark
    ? { bg: '#080C14', panel: '#0F1622', text: '#EAF1FB', sub: 'rgba(225,235,250,0.55)', line: 'rgba(255,255,255,0.08)' }
    : { bg: '#E7EBF1', panel: '#FFFFFF', text: '#0E1E33', sub: 'rgba(14,30,51,0.52)', line: 'rgba(14,30,51,0.08)' };
}

// Refractive stage so component demos show real translucency
function GlassStage({ dark, children, style = {} }) {
  const t = nuvaTokens(dark);
  return (
    <div style={{ position: 'relative', overflow: 'hidden', borderRadius: 24, ...style }}>
      <div style={{ position: 'absolute', inset: 0, background: t.bgBase }} />
      <div style={{ position: 'absolute', inset: 0, background: t.blobA }} />
      <div style={{ position: 'absolute', inset: 0, background: t.blobB }} />
      <div style={{ position: 'relative', zIndex: 1 }}>{children}</div>
    </div>
  );
}

function Caption({ children, g }) {
  return <div style={{ fontSize: 12.5, fontWeight: 500, color: g.sub, letterSpacing: 0.2, marginTop: 10, textAlign: 'center' }}>{children}</div>;
}

function SectionTitle({ children, g }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 14, margin: '8px 0 26px' }}>
      <h2 className="nuva-font" style={{ margin: 0, fontSize: 15, fontWeight: 600, letterSpacing: 1.4,
        textTransform: 'uppercase', color: g.text }}>{children}</h2>
      <div style={{ flex: 1, height: 1, background: g.line }} />
    </div>
  );
}

function Panel({ g, children, label, style = {} }) {
  return (
    <div style={{ background: g.panel, borderRadius: 22, padding: 22, border: `1px solid ${g.line}`,
      boxShadow: '0 1px 3px rgba(20,40,80,0.04)', ...style }}>
      {label && <div className="nuva-font" style={{ fontSize: 13.5, fontWeight: 600, color: g.text, marginBottom: 16 }}>{label}</div>}
      {children}
    </div>
  );
}

// ── Screen pair (light + dark) ──────────────────────────────
function ScreenPair({ title, Comp, g, scText }) {
  return (
    <div style={{ marginBottom: 46 }}>
      <h3 className="nuva-font" style={{ margin: '0 0 18px', fontSize: 19, fontWeight: 600, color: g.text, letterSpacing: -0.3 }}>{title}</h3>
      <div style={{ display: 'flex', gap: 30, flexWrap: 'wrap' }}>
        {[false, true].map(d => (
          <div key={String(d)}>
            <NuvaPhone dark={d}><Comp dark={d} /></NuvaPhone>
            <Caption g={g}>{d ? scText.dark : scText.light}</Caption>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── Brand section ───────────────────────────────────────────
function BrandSection({ g, dark, scText }) {
  const variants = [
    { v: 'ripple', name: 'Ripple — расходящаяся рябь / spreading ripple' },
    { v: 'dawn', name: 'Dawn — новый рассвет / new dawn' },
    { v: 'together', name: 'Together — «вы не одни» / not alone' },
  ];
  return (
    <div>
      <SectionTitle g={g}>{scText.brand}</SectionTitle>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 18, marginBottom: 18 }}>
        {variants.map((it, i) => (
          <Panel key={i} g={g}>
            <GlassStage dark={dark} style={{ height: 130, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <LogoLockup variant={it.v} dark={dark} size={46} />
            </GlassStage>
            <div style={{ fontSize: 12.5, color: g.sub, marginTop: 12, textAlign: 'center', lineHeight: 1.4 }}>{it.name}</div>
          </Panel>
        ))}
      </div>
      <Panel g={g} label={scText.icon}>
        <GlassStage dark={dark} style={{ padding: '30px 24px', display: 'flex', alignItems: 'center', gap: 30, flexWrap: 'wrap', justifyContent: 'center' }}>
          <AppIcon size={120} />
          <AppIcon size={84} />
          <AppIcon size={60} />
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8, color: nuvaTokens(dark).text }}>
            <Wordmark size={40} color={nuvaTokens(dark).text} />
            <span className="nuva-font" style={{ fontSize: 14, color: nuvaTokens(dark).textSec, letterSpacing: 0.5 }}>you’re not alone</span>
          </div>
        </GlassStage>
      </Panel>
    </div>
  );
}

// ── Design system section ───────────────────────────────────
function SystemSection({ g, dark, scText }) {
  const t = nuvaTokens(dark);
  const swatches = [
    ['Blue', t.blue], ['Blue deep', t.blueDeep], ['Teal accent', t.teal],
    ['Emergency', t.danger], ['Text', t.text], ['Text secondary', t.textSec],
  ];
  const typeSamples = [
    ['Display · 30 / 600', 30, 600, 'Вы не одни'],
    ['Title · 22 / 600', 22, 600, 'Find a specialist'],
    ['Headline · 17 / 600', 17, 600, 'Trouvez le bon spécialiste'],
    ['Body · 16 / 400', 16, 400, 'Diacritics: café · Ëtre · Straße · señor · naïve'],
    ['Caption · 13 / 400', 13, 400, 'Шаг 2 из 4 · Step 2 of 4 · Étape 2 sur 4'],
  ];
  return (
    <div>
      <SectionTitle g={g}>{scText.system}</SectionTitle>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 18, marginBottom: 18 }}>
        {/* palette */}
        <Panel g={g} label={scText.palette}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            {swatches.map(([name, col], i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <div style={{ width: 34, height: 34, borderRadius: 10, background: col, flexShrink: 0,
                  border: `1px solid ${g.line}` }} />
                <div style={{ minWidth: 0 }}>
                  <div className="nuva-font" style={{ fontSize: 12.5, fontWeight: 600, color: g.text }}>{name}</div>
                  <div style={{ fontFamily: 'ui-monospace, monospace', fontSize: 10.5, color: g.sub, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{String(col).startsWith('#') ? col : '—'}</div>
                </div>
              </div>
            ))}
          </div>
        </Panel>
        {/* type */}
        <Panel g={g} label={scText.type}>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 13 }}>
            {typeSamples.map(([lab, fs, fw, txt], i) => (
              <div key={i}>
                <div style={{ fontFamily: 'ui-monospace, monospace', fontSize: 10, color: g.sub, marginBottom: 2 }}>{lab}</div>
                <div className="nuva-font" style={{ fontSize: fs, fontWeight: fw, color: g.text, letterSpacing: -0.2, lineHeight: 1.15 }}>{txt}</div>
              </div>
            ))}
          </div>
        </Panel>
      </div>
      {/* components */}
      <Panel g={g} label={scText.comps}>
        <GlassStage dark={dark} style={{ padding: 26 }}>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 16, alignItems: 'center', marginBottom: 20 }}>
            <GlassButton dark={dark} variant="primary">Get started</GlassButton>
            <GlassButton dark={dark} variant="glass">Secondary</GlassButton>
            <GlassButton dark={dark} variant="danger">Get help now</GlassButton>
          </div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 10, alignItems: 'center', marginBottom: 20 }}>
            <Chip dark={dark} active>Anxiety</Chip>
            <Chip dark={dark}>Burnout</Chip>
            <Chip dark={dark}>Sleep</Chip>
            <LangContextBridge dark={dark} />
          </div>
          <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>
            <GlassCard dark={dark} radius={20} raised style={{ padding: 16, width: 220 }}>
              <div className="nuva-font" style={{ fontSize: 14.5, fontWeight: 600, color: t.text }}>Glass card</div>
              <div className="nuva-font" style={{ fontSize: 12.5, color: t.textSec, marginTop: 4 }}>Translucent · blur · edge shine · concentric radius</div>
            </GlassCard>
            <div style={{ position: 'relative', width: 240, height: 70 }}>
              <MiniTabBar dark={dark} />
            </div>
          </div>
        </GlassStage>
        <div style={{ fontSize: 12.5, color: g.sub, marginTop: 14 }}>{scText.langSw}: <span style={{ fontFamily: 'ui-monospace, monospace' }}>RU / EN / FR</span> — {SC_STRINGS[dark ? 'en' : 'en'] && ''}{scText.note}</div>
      </Panel>
    </div>
  );
}

// small standalone lang pill demo (uses real control)
function LangContextBridge({ dark }) { return <LangPill dark={dark} />; }

// mini floating tab bar for the components panel
function MiniTabBar({ dark }) {
  const k = nuvaTokens(dark);
  return (
    <div style={{ position: 'absolute', inset: 0, borderRadius: 24, display: 'flex', alignItems: 'center', padding: '0 6px',
      background: k.glassBgUp, border: `1px solid ${k.glassBorder}`,
      backdropFilter: 'blur(30px) saturate(190%)', WebkitBackdropFilter: 'blur(30px) saturate(190%)',
      boxShadow: `${k.glassShadow}, ${k.glassShine}` }}>
      {['home','search','community','calm','user'].map((n, i) => (
        <div key={i} style={{ flex: 1, display: 'flex', justifyContent: 'center' }}>
          <NuvaIcon name={n} size={21} color={i === 0 ? k.blue : k.textTer} strokeWidth={i === 0 ? 2.2 : 1.9} />
        </div>
      ))}
    </div>
  );
}

// ── Header ──────────────────────────────────────────────────
function Header({ lang, setLang, pageDark, setPageDark, g, scText }) {
  const t = nuvaTokens(pageDark);
  const langs = ['ru', 'en', 'fr'];
  return (
    <div style={{ position: 'sticky', top: 0, zIndex: 100, padding: '14px 0', marginBottom: 8 }}>
      <div style={{ maxWidth: 1160, margin: '0 auto', padding: '0 28px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', height: 60, padding: '0 14px 0 18px',
          borderRadius: 22, background: t.glassBgUp, border: `1px solid ${t.glassBorder}`,
          backdropFilter: 'blur(30px) saturate(190%)', WebkitBackdropFilter: 'blur(30px) saturate(190%)',
          boxShadow: `${t.glassShadow}, ${t.glassShine}` }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
            <LogoLockup dark={pageDark} size={30} />
            <span className="nuva-font" style={{ fontSize: 13, color: g.sub, borderLeft: `1px solid ${g.line}`, paddingLeft: 14 }}>{scText.sub}</span>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            {/* lang segmented */}
            <div style={{ display: 'flex', gap: 3, padding: 3, borderRadius: 999,
              background: pageDark ? 'rgba(255,255,255,0.07)' : 'rgba(14,30,51,0.06)', border: `1px solid ${g.line}` }}>
              {langs.map(l => (
                <button key={l} onClick={() => setLang(l)} style={{ height: 32, padding: '0 13px', borderRadius: 999, cursor: 'pointer',
                  border: 'none', fontFamily: 'Onest, system-ui', fontSize: 13, fontWeight: 600, letterSpacing: 0.3,
                  background: lang === l ? `linear-gradient(180deg, ${t.blue}, ${t.blueDeep})` : 'transparent',
                  color: lang === l ? '#fff' : g.text }}>{l.toUpperCase()}</button>
              ))}
            </div>
            {/* theme toggle */}
            <button onClick={() => setPageDark(v => !v)} style={{ width: 40, height: 38, borderRadius: 12, cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              background: pageDark ? 'rgba(255,255,255,0.07)' : 'rgba(14,30,51,0.06)', border: `1px solid ${g.line}` }}>
              <NuvaIcon name={pageDark ? 'sun' : 'moon'} size={19} color={g.text} strokeWidth={2} />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

// ── Root ────────────────────────────────────────────────────
function NuvaShowcase() {
  const [lang, setLang] = useState('ru');
  const [pageDark, setPageDark] = useState(false);
  const g = galleryColors(pageDark);
  const scText = SC_STRINGS[lang];
  const cycle = useCallback(() => setLang(l => (l === 'ru' ? 'en' : l === 'en' ? 'fr' : 'ru')), []);

  return (
    <LangContext.Provider value={lang}>
      <LangControlContext.Provider value={{ lang, cycle }}>
        <div className="nuva-font" style={{ minHeight: '100vh', background: g.bg, transition: 'background .4s', paddingBottom: 80 }}>
          <Header lang={lang} setLang={setLang} pageDark={pageDark} setPageDark={setPageDark} g={g} scText={scText} />
          <div style={{ maxWidth: 1160, margin: '0 auto', padding: '24px 28px 0' }}>
            <div style={{ marginBottom: 54 }}><BrandSection g={g} dark={pageDark} scText={scText} /></div>
            <div style={{ marginBottom: 54 }}><SystemSection g={g} dark={pageDark} scText={scText} /></div>
            <SectionTitle g={g}>{scText.screens}</SectionTitle>
            <ScreenPair title={scText.s_ob} Comp={OnboardingScreen} g={g} scText={{ light: scText.light, dark: scText.dark }} />
            <ScreenPair title={scText.s_chat} Comp={ChatScreen} g={g} scText={{ light: scText.light, dark: scText.dark }} />
            <ScreenPair title={scText.s_home} Comp={HomeScreen} g={g} scText={{ light: scText.light, dark: scText.dark }} />
          </div>
        </div>
      </LangControlContext.Provider>
    </LangContext.Provider>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<NuvaShowcase />);

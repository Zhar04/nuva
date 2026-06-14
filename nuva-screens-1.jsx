// nuva-screens-1.jsx — Onboarding, AI chat intake, Home. ({ dark }) → screen content.
// Localizes via useT(); in-screen language pill cycles RU→EN→FR (wired to host).

// Shared control context (provided by showcase) so the in-screen pill can switch language
const LangControlContext = React.createContext({ lang: 'ru', cycle: () => {} });

function LangPill({ dark }) {
  const k = nuvaTokens(dark);
  const ctrl = React.useContext(LangControlContext);
  return (
    <button onClick={ctrl.cycle} style={{
      height: 38, padding: '0 12px 0 10px', borderRadius: 999, cursor: 'pointer',
      display: 'inline-flex', alignItems: 'center', gap: 6,
      background: k.glassBgUp, border: `1px solid ${k.glassBorder}`,
      backdropFilter: 'blur(20px) saturate(180%)', WebkitBackdropFilter: 'blur(20px) saturate(180%)',
      boxShadow: k.glassShine, color: k.text,
      fontFamily: 'Onest, system-ui', fontSize: 13.5, fontWeight: 600, letterSpacing: 0.2,
    }}>
      <NuvaIcon name="globe" size={17} color={k.blue} strokeWidth={2} />
      {ctrl.lang.toUpperCase()}
    </button>
  );
}

function IconPill({ dark, name }) {
  const k = nuvaTokens(dark);
  return (
    <div style={{ width: 38, height: 38, borderRadius: 999,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      background: k.glassBgUp, border: `1px solid ${k.glassBorder}`,
      backdropFilter: 'blur(20px) saturate(180%)', WebkitBackdropFilter: 'blur(20px) saturate(180%)',
      boxShadow: k.glassShine }}>
      <NuvaIcon name={name} size={19} color={k.text} strokeWidth={1.9} />
    </div>
  );
}

// ───────────────────────────────────────────────────────────
// 1 · Onboarding — welcome
// ───────────────────────────────────────────────────────────
function OnboardingScreen({ dark }) {
  const t = useT();
  const k = nuvaTokens(dark);
  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', padding: '8px 24px 30px' }}>
      {/* header */}
      <div style={{ display: 'flex', justifyContent: 'flex-end', paddingBottom: 8 }}>
        <LangPill dark={dark} />
      </div>

      {/* hero */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 26 }}>
        <div style={{ position: 'relative', width: 150, height: 150, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          {/* breathing ripple halo */}
          <div className="nuva-anim" style={{ position: 'absolute', width: 150, height: 150, borderRadius: '50%',
            background: `radial-gradient(circle, ${dark ? 'rgba(94,160,240,0.35)' : 'rgba(46,111,214,0.25)'}, transparent 68%)`,
            animation: 'nuva-breathe 6s ease-in-out infinite' }} />
          <RippleMark size={92} color={k.blue} accent={k.teal} variant="ripple" />
        </div>
        <Wordmark size={40} color={k.text} />
        <div style={{ textAlign: 'center', maxWidth: 300 }}>
          <h1 className="nuva-font" style={{ margin: 0, fontSize: 30, fontWeight: 600, letterSpacing: -0.6,
            color: k.text, lineHeight: 1.12 }}>{t('ob_title')}</h1>
          <p className="nuva-font" style={{ margin: '14px 0 0', fontSize: 16.5, fontWeight: 400,
            color: k.textSec, lineHeight: 1.45, textWrap: 'pretty' }}>{t('ob_sub')}</p>
        </div>
      </div>

      {/* actions */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        <GlassButton dark={dark} variant="primary" full>{t('ob_get_started')}</GlassButton>
        <GlassButton dark={dark} variant="glass" full>{t('ob_have_account')}</GlassButton>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 7, marginTop: 6 }}>
          <NuvaIcon name="lock" size={14} color={k.textTer} strokeWidth={2} />
          <span className="nuva-font" style={{ fontSize: 12.5, color: k.textTer, textAlign: 'center', textWrap: 'pretty' }}>
            {t('ob_privacy_note')}
          </span>
        </div>
      </div>
    </div>
  );
}

// ───────────────────────────────────────────────────────────
// 2 · AI chat intake
// ───────────────────────────────────────────────────────────
function ChatScreen({ dark }) {
  const t = useT();
  const k = nuvaTokens(dark);
  const chips = ['chip_anxiety', 'chip_burnout', 'chip_sleep', 'chip_relations'];

  const StepBar = () => (
    <div style={{ display: 'flex', gap: 5, alignItems: 'center' }}>
      {[0,1,2,3].map(i => (
        <div key={i} style={{ width: 22, height: 4, borderRadius: 4,
          background: i < 2 ? k.blue : k.hairline }} />
      ))}
    </div>
  );

  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
      {/* header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '6px 18px 12px' }}>
        <IconPill dark={dark} name="chevronL" />
        <div style={{ flex: 1 }}>
          <div className="nuva-font" style={{ fontSize: 16, fontWeight: 600, color: k.text, letterSpacing: -0.2 }}>{t('chat_header')}</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 5 }}>
            <StepBar />
            <span className="nuva-font" style={{ fontSize: 12, color: k.textSec }}>{t('chat_step')}</span>
          </div>
        </div>
        <LangPill dark={dark} />
      </div>

      {/* conversation */}
      <div className="nuva-scroll" style={{ flex: 1, overflowY: 'auto', padding: '8px 18px', display: 'flex', flexDirection: 'column', gap: 14 }}>
        {/* assistant */}
        <div style={{ display: 'flex', gap: 10, alignItems: 'flex-start' }}>
          <div style={{ width: 34, height: 34, borderRadius: 999, flexShrink: 0, marginTop: 2,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            background: `linear-gradient(150deg, ${k.blue}, ${k.teal})`,
            boxShadow: 'inset 0 1px 1px rgba(255,255,255,0.5)' }}>
            <RippleMark size={20} color="#fff" accent="#fff" />
          </div>
          <div style={{ flex: 1 }}>
            <div className="nuva-font" style={{ fontSize: 11.5, color: k.textTer, marginBottom: 5, marginLeft: 2 }}>{t('chat_assistant')}</div>
            <GlassCard dark={dark} radius={20} raised style={{ padding: '14px 16px', borderTopLeftRadius: 6 }}>
              <p className="nuva-font" style={{ margin: 0, fontSize: 15.5, lineHeight: 1.45, color: k.text }}>{t('chat_greeting')}</p>
            </GlassCard>
          </div>
        </div>

        {/* chips */}
        <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8, paddingLeft: 44 }}>
          {chips.map((c, i) => <Chip key={c} dark={dark} active={i === 0}>{t(c)}</Chip>)}
        </div>

        {/* user reply */}
        <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
          <div style={{ maxWidth: '78%', padding: '13px 16px', borderRadius: 20, borderTopRightRadius: 6,
            background: `linear-gradient(180deg, ${k.blue}, ${k.blueDeep})`, color: '#fff',
            boxShadow: `0 6px 16px ${dark ? 'rgba(46,111,214,0.35)' : 'rgba(46,111,214,0.22)'}` }}>
            <p className="nuva-font" style={{ margin: 0, fontSize: 15.5, lineHeight: 1.4 }}>{t('chat_user_msg')}</p>
          </div>
        </div>

        {/* typing indicator */}
        <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
          <div style={{ width: 34, height: 34, borderRadius: 999, flexShrink: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            background: `linear-gradient(150deg, ${k.blue}, ${k.teal})` }}>
            <RippleMark size={20} color="#fff" accent="#fff" />
          </div>
          <GlassCard dark={dark} radius={18} raised style={{ padding: '13px 15px', display: 'flex', gap: 5 }}>
            {[0,1,2].map(i => (
              <div key={i} className="nuva-anim" style={{ width: 7, height: 7, borderRadius: 999, background: k.textTer,
                animation: `nuva-float 1.2s ease-in-out ${i*0.18}s infinite` }} />
            ))}
          </GlassCard>
        </div>
      </div>

      {/* disclaimer + input */}
      <div style={{ padding: '6px 18px 96px' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 7, marginBottom: 10 }}>
          <NuvaIcon name="sparkle" size={14} color={k.teal} strokeWidth={2} />
          <span className="nuva-font" style={{ fontSize: 12, color: k.textSec, textAlign: 'center' }}>{t('chat_disclaimer')}</span>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, height: 52, padding: '0 6px 0 18px', borderRadius: 26,
          background: k.glassBgUp, border: `1px solid ${k.glassBorder}`,
          backdropFilter: 'blur(28px) saturate(180%)', WebkitBackdropFilter: 'blur(28px) saturate(180%)',
          boxShadow: k.glassShine }}>
          <span className="nuva-font" style={{ flex: 1, fontSize: 15.5, color: k.textTer }}>{t('chat_placeholder')}</span>
          <div style={{ width: 40, height: 40, borderRadius: 999, display: 'flex', alignItems: 'center', justifyContent: 'center',
            background: `linear-gradient(180deg, ${k.blue}, ${k.blueDeep})` }}>
            <NuvaIcon name="send" size={20} color="#fff" strokeWidth={2.2} />
          </div>
        </div>
      </div>
    </div>
  );
}

// ───────────────────────────────────────────────────────────
// 3 · Home
// ───────────────────────────────────────────────────────────
function HomeScreen({ dark }) {
  const t = useT();
  const k = nuvaTokens(dark);

  const MoodDots = () => (
    <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
      {[0.42, 0.62, 0.82, 1, 0.8].map((op, i) => {
        const sel = i === 3;
        const d = 26 + (sel ? 6 : 0);
        return (
          <div key={i} style={{ width: d, height: d, borderRadius: 999,
            background: `linear-gradient(150deg, ${k.blue}, ${k.teal})`, opacity: op,
            border: sel ? `2px solid ${dark ? '#fff' : '#fff'}` : 'none',
            boxShadow: sel ? `0 4px 12px ${dark ? 'rgba(54,201,182,0.5)' : 'rgba(15,169,149,0.35)'}` : 'none' }} />
        );
      })}
    </div>
  );

  const ActionCard = ({ icon, title, sub, big }) => (
    <GlassCard dark={dark} radius={24} raised style={{ width: '100%', padding: big ? '18px' : '16px',
      display: 'flex', flexDirection: 'column', gap: big ? 12 : 10, height: big ? 124 : 118 }}>
      <div style={{ width: 44, height: 44, borderRadius: 14, display: 'flex', alignItems: 'center', justifyContent: 'center',
        background: `linear-gradient(150deg, ${k.blue}, ${k.teal})`, boxShadow: 'inset 0 1px 1px rgba(255,255,255,0.5)' }}>
        <NuvaIcon name={icon} size={24} color="#fff" strokeWidth={2} />
      </div>
      <div style={{ marginTop: 'auto' }}>
        <div className="nuva-font" style={{ fontSize: big ? 19 : 16, fontWeight: 600, color: k.text, letterSpacing: -0.3 }}>{title}</div>
        <div className="nuva-font" style={{ fontSize: big ? 14 : 12.5, color: k.textSec, marginTop: 3, lineHeight: 1.3 }}>{sub}</div>
      </div>
    </GlassCard>
  );

  return (
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column', padding: '6px 18px 0' }}>
      {/* top bar */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
        <LogoLockup dark={dark} size={30} />
        <div style={{ display: 'flex', gap: 8 }}>
          <IconPill dark={dark} name="bell" />
          <LangPill dark={dark} />
        </div>
      </div>

      {/* greeting */}
      <h1 className="nuva-font" style={{ margin: 0, fontSize: 28, fontWeight: 600, letterSpacing: -0.5, color: k.text }}>{t('home_greeting')}</h1>
      <p className="nuva-font" style={{ margin: '4px 0 18px', fontSize: 15.5, color: k.textSec }}>{t('home_prompt')}</p>

      {/* mood check-in */}
      <GlassCard dark={dark} radius={22} style={{ padding: '16px 18px', marginBottom: 13,
        display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12 }}>
        <span className="nuva-font" style={{ fontSize: 14, fontWeight: 500, color: k.text, maxWidth: 110, lineHeight: 1.4 }}>{t('home_mood_q')}</span>
        <MoodDots />
      </GlassCard>

      {/* find specialist (hero action) */}
      <ActionCard icon="sparkle" title={t('home_find')} sub={t('home_find_sub')} big />

      {/* two small */}
      <div style={{ display: 'flex', gap: 13, marginTop: 13, flexShrink: 0 }}>
        <div style={{ flex: 1, display: 'flex' }}><ActionCard icon="calm" title={t('home_calm')} sub={t('home_calm_sub')} /></div>
        <div style={{ flex: 1, display: 'flex' }}><ActionCard icon="community" title={t('home_community')} sub={t('home_community_sub')} /></div>
      </div>

      {/* emergency — calm, present, single red accent */}
      <button style={{ marginTop: 13, height: 54, flexShrink: 0, borderRadius: 18, cursor: 'pointer', width: '100%',
        display: 'flex', alignItems: 'center', gap: 12, padding: '0 18px',
        background: dark ? 'rgba(255,107,107,0.12)' : 'rgba(224,72,77,0.08)',
        border: `1px solid ${dark ? 'rgba(255,107,107,0.35)' : 'rgba(224,72,77,0.30)'}`,
        backdropFilter: 'blur(20px)', WebkitBackdropFilter: 'blur(20px)' }}>
        <div style={{ width: 32, height: 32, borderRadius: 999, display: 'flex', alignItems: 'center', justifyContent: 'center',
          background: k.danger }}>
          <NuvaIcon name="shield" size={18} color="#fff" strokeWidth={2} />
        </div>
        <span className="nuva-font" style={{ flex: 1, textAlign: 'left', fontSize: 15.5, fontWeight: 600, color: k.danger }}>{t('need_help_now')}</span>
        <NuvaIcon name="chevronR" size={18} color={k.danger} strokeWidth={2} />
      </button>

      <FloatingTabBar dark={dark} active={0} t={t} />
    </div>
  );
}

Object.assign(window, { LangControlContext, LangPill, IconPill, OnboardingScreen, ChatScreen, HomeScreen });

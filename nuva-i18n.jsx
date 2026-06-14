// nuva-i18n.jsx — RU / EN / FR localization dictionary + helpers
// Russian is the default. EN & FR copy for the 3 key screens is verbatim
// from the brief. Other screens localized where it matters; falls back to EN→key.

const NUVA_STRINGS = {
  // ── Brand / global chrome ────────────────────────────────
  tagline:        { ru: 'вы не одни',                       en: "you're not alone",                 fr: 'vous n’êtes pas seul·e' },

  // ── Floating tab bar ─────────────────────────────────────
  tab_home:       { ru: 'Главная',     en: 'Home',        fr: 'Accueil' },
  tab_find:       { ru: 'Поиск',       en: 'Find',        fr: 'Trouver' },
  tab_community:  { ru: 'Сообщество',  en: 'Community',   fr: 'Communauté' },
  tab_calm:       { ru: 'Покой',       en: 'Calm',        fr: 'Apaiser' },
  tab_profile:    { ru: 'Профиль',     en: 'Profile',     fr: 'Profil' },

  // ── Emergency (locale-aware) ─────────────────────────────
  need_help_now:  { ru: 'Нужна помощь сейчас?', en: 'Need help now?', fr: 'Besoin d’aide maintenant ?' },
  get_help_now:   { ru: 'Получить помощь',      en: 'Get help now',   fr: 'Obtenir de l’aide' },

  // ── Onboarding (welcome) — verbatim EN/FR ────────────────
  ob_title:       { ru: 'Вы не одни.',
                    en: 'You’re not alone.',
                    fr: 'Vous n’êtes pas seul·e.' },
  ob_sub:         { ru: 'Найдите подходящего специалиста — на вашем языке, когда захочется поговорить.',
                    en: 'Find the right specialist, in your language, whenever you need to talk.',
                    fr: 'Trouvez le bon spécialiste, dans votre langue, dès que vous avez besoin de parler.' },
  ob_get_started: { ru: 'Начать',                 en: 'Get started',            fr: 'Commencer' },
  ob_have_account:{ ru: 'У меня уже есть аккаунт', en: 'I already have an account', fr: 'J’ai déjà un compte' },
  ob_privacy_note:{ ru: 'Конфиденциально и анонимно. Вы решаете, чем делиться.',
                    en: 'Private & anonymous. You decide what to share.',
                    fr: 'Confidentiel et anonyme. Vous décidez de ce que vous partagez.' },

  // ── AI chat (intake) — verbatim EN/FR ────────────────────
  chat_header:    { ru: 'Подбор специалиста', en: 'Finding your match', fr: 'Votre orientation' },
  chat_step:      { ru: 'Шаг 2 из 4', en: 'Step 2 of 4', fr: 'Étape 2 sur 4' },
  chat_greeting:  { ru: 'Здравствуйте. Я помогу найти подходящего специалиста. Что вас тревожит прямо сейчас?',
                    en: 'Hi. I’ll help you find the right specialist. What’s on your mind right now?',
                    fr: 'Bonjour. Je vais vous aider à trouver le bon spécialiste. Qu’est-ce qui vous préoccupe en ce moment ?' },
  chat_disclaimer:{ ru: 'Я навигатор — не терапевт и не ставлю диагнозов.',
                    en: 'I’m a guide — not a therapist or a diagnosis.',
                    fr: 'Je suis un guide — ni thérapeute, ni diagnostic.' },
  chip_anxiety:   { ru: 'Тревога',      en: 'Anxiety',       fr: 'Anxiété' },
  chip_burnout:   { ru: 'Выгорание',    en: 'Burnout',       fr: 'Burn-out' },
  chip_sleep:     { ru: 'Сон',          en: 'Sleep',         fr: 'Sommeil' },
  chip_relations: { ru: 'Отношения',    en: 'Relationships', fr: 'Relations' },
  chat_user_msg:  { ru: 'В последнее время много тревоги перед сном.',
                    en: 'Lately I’ve had a lot of anxiety before sleep.',
                    fr: 'Dernièrement, beaucoup d’anxiété avant de dormir.' },
  chat_placeholder:{ ru: 'Сообщение…', en: 'Message…', fr: 'Message…' },
  chat_assistant: { ru: 'Ассистент Nuva', en: 'Nuva assistant', fr: 'Assistant Nuva' },

  // ── Home ─────────────────────────────────────────────────
  home_greeting:  { ru: 'Добрый вечер.', en: 'Good evening.', fr: 'Bonsoir.' },
  home_prompt:    { ru: 'Чем займёмся сегодня?', en: 'What would you like to do?', fr: 'Que souhaitez-vous faire ?' },
  home_find:      { ru: 'Найти специалиста',  en: 'Find a specialist', fr: 'Trouver un spécialiste' },
  home_find_sub:  { ru: 'Мягкий подбор за 2 минуты', en: 'A gentle match in 2 minutes', fr: 'Une orientation douce en 2 min' },
  home_calm:      { ru: 'Успокоиться',  en: 'Calm down',  fr: 'Se calmer' },
  home_calm_sub:  { ru: 'Дыхание и звуки', en: 'Breathing & sounds', fr: 'Respiration et sons' },
  home_community: { ru: 'Сообщество',   en: 'Community',  fr: 'Communauté' },
  home_community_sub:{ ru: 'Анонимная поддержка', en: 'Anonymous support', fr: 'Soutien anonyme' },
  home_mood_q:    { ru: 'Как вы себя чувствуете?', en: 'How are you feeling?', fr: 'Comment vous sentez-vous ?' },
  home_continue:  { ru: 'Продолжить подбор', en: 'Continue your match', fr: 'Reprendre l’orientation' },
  home_continue_sub:{ ru: 'Шаг 2 из 4 · ИИ-ассистент', en: 'Step 2 of 4 · AI assistant', fr: 'Étape 2 sur 4 · assistant IA' },

  // ── Showcase chrome ──────────────────────────────────────
  sc_brand:       { ru: 'Бренд', en: 'Brand', fr: 'Marque' },
  sc_system:      { ru: 'Дизайн-система', en: 'Design system', fr: 'Système de design' },
  sc_screens:     { ru: 'Экраны', en: 'Screens', fr: 'Écrans' },
  sc_light:       { ru: 'Светлая', en: 'Light', fr: 'Clair' },
  sc_dark:        { ru: 'Тёмная', en: 'Dark', fr: 'Sombre' },
};

function nuvaT(lang, key) {
  const e = NUVA_STRINGS[key];
  if (!e) return key;
  return e[lang] || e.en || e.ru || key;
}

// React context so any nested component can localize
const LangContext = React.createContext('ru');
function useT() {
  const lang = React.useContext(LangContext);
  return React.useCallback((key) => nuvaT(lang, key), [lang]);
}

Object.assign(window, { NUVA_STRINGS, nuvaT, LangContext, useT });

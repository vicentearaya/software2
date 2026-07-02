import { t } from '../i18n/translations';
import logoImg from '../../imagen/logo.png';

export default function Header({ lang, onToggleLang }) {
  return (
    <header className="sticky top-0 z-[100] flex items-center justify-between px-6 py-4 bg-gradient-to-b from-[rgba(4,12,10,0.92)] to-[rgba(4,12,10,0.78)] backdrop-blur-[16px] border-b border-transparent [border-image:linear-gradient(90deg,transparent,rgba(0,255,214,0.35),rgba(192,132,252,0.35),transparent)_1] shadow-[0_12px_40px_rgba(0,0,0,0.35)]">
      <a className="flex items-center gap-3 no-underline text-inherit" href="#main">
        <img
          src={logoImg}
          alt={t(lang, 'nav.brand')}
          className="w-14 h-14 rounded-xl shrink-0 object-cover shadow-[0_0_24px_rgba(0,255,214,0.35)]"
        />
        <span className="flex flex-col">
          <span className="font-black text-[1.15rem] tracking-wide uppercase bg-gradient-to-br from-[#5eead4] via-[#a78bfa] to-[#f9a8d4] bg-clip-text text-transparent drop-shadow-[0_0_20px_rgba(0,255,214,0.35)]">
            {t(lang, 'nav.brand')}
          </span>
          <span className="text-[0.72rem] font-semibold text-[rgba(180,255,232,0.55)] tracking-wide">
            {t(lang, 'nav.tag')}
          </span>
        </span>
      </a>
      <button
        type="button"
        onClick={onToggleLang}
        className="font-extrabold text-[0.8rem] px-[1.15rem] py-[0.55rem] rounded-full border border-[rgba(0,255,214,0.35)] bg-[rgba(0,255,214,0.08)] text-[#b4ffe8] cursor-pointer shadow-[0_0_20px_rgba(0,255,214,0.12),inset_0_1px_0_rgba(255,255,255,0.12)] transition-all hover:border-[rgba(192,132,252,0.6)] hover:shadow-[0_0_28px_rgba(192,132,252,0.25)] hover:-translate-y-px"
        aria-label={lang === 'es' ? 'Switch to English' : 'Cambiar a español'}
      >
        {t(lang, 'nav.lang')}
      </button>
    </header>
  );
}

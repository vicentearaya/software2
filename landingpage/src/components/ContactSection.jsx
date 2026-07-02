import { useRef } from 'react';
import { t } from '../i18n/translations';
import { useReveal } from '../hooks/useReveal';

const WHATSAPP = '+56965915325';
const WHATSAPP_LINK = 'https://wa.me/56965915325';
const EMAIL = 'v.arayadaz@uandresbello.edu';
const TEAM = ['Diego Carmona', 'Constanza Malebran', 'Daniel Cortez', 'Vicente Araya'];

export default function ContactSection({ lang, reduced }) {
  const sectionRef = useRef(null);
  useReveal(sectionRef, reduced);

  return (
    <section
      ref={sectionRef}
      id="contact"
      className="section section--reveal max-w-[1280px] mx-auto px-5 py-8 md:py-12 md:px-8"
      aria-labelledby="contact-title"
    >
      <div className="text-center mb-10">
        <h2 id="contact-title" className="m-0 mb-2 text-[clamp(1.4rem,3vw,1.85rem)] font-black tracking-tight text-[#f0fffa] drop-shadow-[0_0_40px_rgba(0,255,214,0.2)]">
          {t(lang, 'contact.title')}
        </h2>
        <p className="m-0 mx-auto max-w-[38rem] text-[rgba(180,230,215,0.65)]">
          {t(lang, 'contact.sub')}
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 max-w-[900px] mx-auto">
        <a
          href={WHATSAPP_LINK}
          target="_blank"
          rel="noopener noreferrer"
          className="flex items-center gap-4 p-5 rounded-2xl border border-[rgba(0,255,214,0.15)] bg-[rgba(0,255,214,0.04)] backdrop-blur-sm transition-all hover:border-[rgba(192,132,252,0.35)] hover:bg-[rgba(192,132,252,0.06)]"
        >
          <span className="shrink-0 w-11 h-11 rounded-xl grid place-items-center bg-gradient-to-br from-[#00ffd6] to-[#a855f7] text-[#040807]">
            <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
              <path d="M12.04 2c-5.46 0-9.9 4.44-9.9 9.9 0 1.75.46 3.45 1.32 4.95L2 22l5.3-1.38a9.87 9.87 0 0 0 4.73 1.2h.01c5.46 0 9.9-4.44 9.9-9.9 0-2.64-1.03-5.13-2.9-7A9.82 9.82 0 0 0 12.04 2Zm0 1.8a8.07 8.07 0 0 1 5.73 2.37 8.03 8.03 0 0 1 2.37 5.73c0 4.48-3.64 8.11-8.11 8.11a8.1 8.1 0 0 1-4.13-1.13l-.3-.18-3.06.8.82-2.99-.2-.31a8.05 8.05 0 0 1-1.24-4.3c0-4.47 3.64-8.1 8.11-8.1Zm-4.6 4.36c-.15 0-.4.06-.6.29-.21.23-.8.78-.8 1.9 0 1.12.82 2.2.93 2.36.11.15 1.6 2.45 3.9 3.44.55.24.97.38 1.3.48.55.17 1.04.15 1.44.09.44-.07 1.35-.55 1.54-1.09.19-.53.19-.99.13-1.08-.06-.1-.21-.15-.44-.27-.23-.11-1.35-.67-1.56-.74-.21-.08-.36-.11-.5.11-.15.23-.58.74-.71.89-.13.15-.26.17-.49.06-.23-.12-.96-.36-1.83-1.13-.68-.6-1.13-1.35-1.27-1.58-.13-.23-.01-.35.1-.47.1-.1.23-.26.34-.4.11-.13.15-.22.23-.37.08-.15.04-.29-.02-.4-.06-.12-.5-1.24-.7-1.7-.18-.44-.37-.38-.5-.39l-.44-.01Z" />
            </svg>
          </span>
          <span className="min-w-0">
            <span className="block text-xs font-black uppercase tracking-wide text-[rgba(0,255,214,0.75)]">
              {t(lang, 'contact.whatsapp')}
            </span>
            <span className="block text-[0.95rem] font-semibold text-[rgba(200,255,240,0.9)] truncate">
              {WHATSAPP}
            </span>
          </span>
        </a>

        <a
          href={`mailto:${EMAIL}`}
          className="flex items-center gap-4 p-5 rounded-2xl border border-[rgba(0,255,214,0.15)] bg-[rgba(0,255,214,0.04)] backdrop-blur-sm transition-all hover:border-[rgba(192,132,252,0.35)] hover:bg-[rgba(192,132,252,0.06)]"
        >
          <span className="shrink-0 w-11 h-11 rounded-xl grid place-items-center bg-gradient-to-br from-[#00ffd6] to-[#a855f7] text-[#040807]">
            <svg xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
              <rect x="2" y="4" width="20" height="16" rx="2" />
              <path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7" />
            </svg>
          </span>
          <span className="min-w-0">
            <span className="block text-xs font-black uppercase tracking-wide text-[rgba(0,255,214,0.75)]">
              {t(lang, 'contact.email')}
            </span>
            <span className="block text-[0.95rem] font-semibold text-[rgba(200,255,240,0.9)] truncate">
              {EMAIL}
            </span>
          </span>
        </a>
      </div>

      <div className="mt-8 max-w-[900px] mx-auto p-6 rounded-2xl border border-[rgba(0,255,214,0.12)] bg-[rgba(0,255,214,0.03)] backdrop-blur-sm text-center">
        <p className="m-0 mb-3 text-xs font-black uppercase tracking-wide text-[rgba(0,255,214,0.75)]">
          {t(lang, 'contact.team.title')}
        </p>
        <div className="flex flex-wrap justify-center gap-2 mb-4">
          {TEAM.map((name) => (
            <span
              key={name}
              className="px-4 py-2 rounded-full text-[0.9rem] font-semibold text-[rgba(200,255,240,0.9)] border border-[rgba(192,132,252,0.25)] bg-[rgba(192,132,252,0.06)]"
            >
              {name}
            </span>
          ))}
        </div>
        <p className="m-0 text-[0.9rem] font-semibold text-[rgba(180,230,215,0.6)]">
          {t(lang, 'contact.team.university')}
        </p>
      </div>
    </section>
  );
}

import { useRef } from 'react';
import { t } from '../i18n/translations';
import { useReveal } from '../hooks/useReveal';

const VALUE_KEYS = ['value.1', 'value.2', 'value.3', 'value.4'];

export default function ValueSection({ lang, reduced }) {
  const sectionRef = useRef(null);
  useReveal(sectionRef, reduced);

  return (
    <section
      ref={sectionRef}
      className="section section--reveal max-w-[1280px] mx-auto px-5 py-8 md:py-12 md:px-8"
      aria-labelledby="value-title"
    >
      <div className="text-center mb-10">
        <h2 id="value-title" className="m-0 mb-2 text-[clamp(1.4rem,3vw,1.85rem)] font-black tracking-tight text-[#f0fffa] drop-shadow-[0_0_40px_rgba(0,255,214,0.2)]">
          {t(lang, 'value.title')}
        </h2>
        <p className="m-0 mx-auto max-w-[38rem] text-[rgba(180,230,215,0.65)]">
          {t(lang, 'value.sub')}
        </p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2 max-w-[900px] mx-auto">
        {VALUE_KEYS.map((key, i) => (
          <div
            key={key}
            className="flex gap-4 p-5 rounded-2xl border border-[rgba(0,255,214,0.15)] bg-[rgba(0,255,214,0.04)] backdrop-blur-sm transition-all hover:border-[rgba(192,132,252,0.35)] hover:bg-[rgba(192,132,252,0.06)]"
          >
            <span className="shrink-0 w-10 h-10 rounded-xl grid place-items-center font-black text-sm bg-gradient-to-br from-[#00ffd6] to-[#a855f7] text-[#040807]">
              {i + 1}
            </span>
            <p className="m-0 text-[0.95rem] font-semibold text-[rgba(200,255,240,0.82)] leading-relaxed">
              {t(lang, key)}
            </p>
          </div>
        ))}
      </div>
    </section>
  );
}

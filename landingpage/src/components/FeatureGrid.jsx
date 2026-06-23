import { useRef } from 'react';
import { t } from '../i18n/translations';
import { useReveal } from '../hooks/useReveal';
import FeatureCard from './FeatureCard';

const FEATURES = [
  { theme: 'mint', icon: 'dashboard', key: 'dashboard' },
  { theme: 'violet', icon: 'iot', key: 'iot', cut: true },
  { theme: 'solar', icon: 'recommend', key: 'recommend' },
  { theme: 'ocean', icon: 'inventory', key: 'inventory', wide: true, span2: true },
  { theme: 'prism', icon: 'guides', key: 'guides' },
  { theme: 'void', icon: 'history', key: 'history' },
];

export default function FeatureGrid({ lang, reduced }) {
  const sectionRef = useRef(null);
  useReveal(sectionRef, reduced);

  return (
    <section
      ref={sectionRef}
      className="section section--reveal max-w-[1280px] mx-auto px-5 py-8 md:py-12 md:px-8"
      aria-labelledby="grid-title"
    >
      <div className="text-center mb-10">
        <h2 id="grid-title" className="m-0 mb-2 text-[clamp(1.4rem,3vw,1.85rem)] font-black tracking-tight text-[#f0fffa] drop-shadow-[0_0_40px_rgba(0,255,214,0.2)]">
          {t(lang, 'sec.grid')}
        </h2>
        <p className="m-0 mx-auto max-w-[38rem] text-[rgba(180,230,215,0.65)]">
          {t(lang, 'sec.grid.sub')}
        </p>
      </div>

      <div className="grid grid-cols-[repeat(auto-fill,minmax(min(100%,288px),1fr))] md:grid-cols-3 gap-4 md:gap-6 items-stretch [&_.ux-parent--span-2]:md:col-span-2">
        {FEATURES.map((f) => (
          <FeatureCard
            key={f.key}
            theme={f.theme}
            cut={f.cut}
            wide={f.wide}
            span2={f.span2}
            icon={f.icon}
            title={t(lang, `card.${f.key}.title`)}
            text={t(lang, `card.${f.key}.text`)}
            tag={t(lang, 'cta.tag')}
          />
        ))}
      </div>
    </section>
  );
}

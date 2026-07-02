import { useRef } from 'react';
import { t } from '../i18n/translations';
import { useReveal } from '../hooks/useReveal';

const IMAGES = Object.entries(
  import.meta.glob('../../imagen/app*.png', { eager: true, import: 'default' }),
)
  .map(([path, src]) => ({
    n: Number(path.match(/app(\d+)\.png$/)?.[1] ?? 0),
    src,
  }))
  .filter(({ n }) => n >= 1 && n <= 9)
  .sort((a, b) => a.n - b.n)
  .map(({ src }) => src);

export default function AppShowcase({ lang, reduced }) {
  const sectionRef = useRef(null);
  useReveal(sectionRef, reduced);

  return (
    <section
      ref={sectionRef}
      id="showcase"
      className="section section--reveal max-w-[1280px] mx-auto px-5 py-8 md:py-12 md:px-8"
      aria-labelledby="showcase-title"
    >
      <div className="text-center mb-10">
        <h2 id="showcase-title" className="m-0 mb-2 text-[clamp(1.4rem,3vw,1.85rem)] font-black tracking-tight text-[#f0fffa] drop-shadow-[0_0_40px_rgba(0,255,214,0.2)]">
          {t(lang, 'gallery.title')}
        </h2>
        <p className="m-0 mx-auto max-w-[38rem] text-[rgba(180,230,215,0.65)]">
          {t(lang, 'gallery.sub')}
        </p>
      </div>

      <div className="scene3d">
        <div className="ring3d" style={{ '--n': IMAGES.length }}>
          {IMAGES.map((src, i) => (
            <img
              key={src}
              className="ring3d__card"
              src={src}
              style={{ '--i': i }}
              alt={`CleanPool app ${i + 1}`}
              loading="lazy"
            />
          ))}
        </div>
      </div>
    </section>
  );
}

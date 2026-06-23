import { useRef } from 'react';
import { t } from '../i18n/translations';
import { useReveal } from '../hooks/useReveal';
import { useCarousel } from '../hooks/useCarousel';

const PANELS = [
  { variant: 'a', prefix: '1' },
  { variant: 'b', prefix: '2' },
  { variant: 'c', prefix: '3' },
  { variant: 'd', prefix: '4' },
];

export default function SpotlightCarousel({ lang, reduced }) {
  const sectionRef = useRef(null);
  useReveal(sectionRef, reduced);

  const {
    rootRef,
    viewportRef,
    trackRef,
    idx,
    go,
    goTo,
    onKeyDown,
    onPointerDown,
    onPointerUp,
    onPointerCancel,
    panelWidth,
  } = useCarousel(PANELS.length, reduced);

  const liveText =
    lang === 'es'
      ? `Diapositiva ${idx + 1} de ${PANELS.length}`
      : `Slide ${idx + 1} of ${PANELS.length}`;

  return (
    <section
      ref={sectionRef}
      className="section section--reveal max-w-[1280px] mx-auto px-5 py-8 md:py-12 md:px-8"
      aria-labelledby="orbit-title"
    >
      <div className="text-center mb-10">
        <h2 id="orbit-title" className="m-0 mb-2 text-[clamp(1.4rem,3vw,1.85rem)] font-black tracking-tight text-[#f0fffa] drop-shadow-[0_0_40px_rgba(0,255,214,0.2)]">
          {t(lang, 'sec.orbit')}
        </h2>
        <p className="m-0 mx-auto max-w-[38rem] text-[rgba(180,230,215,0.65)]">
          {t(lang, 'sec.orbit.sub')}
        </p>
      </div>

      <div
        ref={rootRef}
        className="stage-wrap max-w-[440px] sm:max-w-[520px] mx-auto mt-3 outline-none"
        role="region"
        aria-roledescription="carousel"
        aria-labelledby="orbit-title"
        tabIndex={0}
        onKeyDown={onKeyDown}
      >
        <span className="sr-only" aria-live="polite">
          {liveText}
        </span>

        <div className="grid grid-cols-[auto_1fr_auto] sm:grid-cols-[auto_1fr_auto] items-center gap-1.5 max-[520px]:grid-cols-1">
          <button
            type="button"
            className="stage-fab w-12 h-12 shrink-0 rounded-full border border-[rgba(0,255,214,0.38)] bg-[rgba(0,0,0,0.4)] text-[#e8fff8] cursor-pointer grid place-items-center transition-all shadow-[0_0_22px_rgba(0,255,214,0.1)] hover:border-[rgba(192,132,252,0.55)] hover:shadow-[0_0_32px_rgba(192,132,252,0.28)] hover:scale-105 max-[520px]:hidden"
            onClick={() => go(-1)}
            aria-label={lang === 'es' ? 'Anterior' : 'Previous'}
          >
            <svg viewBox="0 0 24 24" className="w-[22px] h-[22px] fill-current" aria-hidden="true">
              <path d="M15.41 7.41L14 6l-6 6 6 6 1.41-1.41L10.83 12z" />
            </svg>
          </button>

          <div
            ref={viewportRef}
            className="stage-viewport overflow-hidden rounded-[22px] bg-[rgba(0,0,0,0.35)] border border-[rgba(0,255,214,0.22)] shadow-[0_0_0_1px_rgba(255,255,255,0.06)_inset,0_24px_56px_rgba(0,0,0,0.45)]"
            dir="ltr"
            onPointerDown={onPointerDown}
            onPointerUp={onPointerUp}
            onPointerCancel={onPointerCancel}
          >
            <div ref={trackRef} className="stage-track" id="stage-track">
              {PANELS.map((panel, i) => (
                <article
                  key={panel.variant}
                  className={`stage-card stage-card--${panel.variant}`}
                  style={panelWidth > 0 ? { flex: `0 0 ${panelWidth}px`, width: panelWidth, maxWidth: panelWidth } : undefined}
                >
                  <div className="stage-card__inner">
                    <div className="stage-card__body">
                      <span className="stage-card__tag">
                        {String(i + 1).padStart(2, '0')}
                      </span>
                      <h3>{t(lang, `carousel.${panel.prefix}t`)}</h3>
                      <p>{t(lang, `carousel.${panel.prefix}d`)}</p>
                      <ul>
                        <li>{t(lang, `carousel.${panel.prefix}b1`)}</li>
                        <li>{t(lang, `carousel.${panel.prefix}b2`)}</li>
                      </ul>
                    </div>
                  </div>
                </article>
              ))}
            </div>
          </div>

          <button
            type="button"
            className="stage-fab w-12 h-12 shrink-0 rounded-full border border-[rgba(0,255,214,0.38)] bg-[rgba(0,0,0,0.4)] text-[#e8fff8] cursor-pointer grid place-items-center transition-all shadow-[0_0_22px_rgba(0,255,214,0.1)] hover:border-[rgba(192,132,252,0.55)] hover:shadow-[0_0_32px_rgba(192,132,252,0.28)] hover:scale-105 max-[520px]:hidden"
            onClick={() => go(1)}
            aria-label={lang === 'es' ? 'Siguiente' : 'Next'}
          >
            <svg viewBox="0 0 24 24" className="w-[22px] h-[22px] fill-current" aria-hidden="true">
              <path d="M8.59 16.59L10 18l6-6-6-6-1.41 1.41L13.17 12z" />
            </svg>
          </button>
        </div>

        <div className="flex justify-center gap-2.5 mt-5" role="group" aria-label={lang === 'es' ? 'Indicadores' : 'Slide indicators'}>
          {PANELS.map((_, j) => (
            <button
              key={j}
              type="button"
              className={`w-2.5 h-2.5 rounded-full border-0 p-0 cursor-pointer transition-all ${
                j === idx
                  ? 'bg-white scale-[1.35] shadow-[0_0_18px_rgba(0,255,214,0.55)]'
                  : 'bg-[rgba(255,255,255,0.22)]'
              }`}
              aria-label={`${lang === 'es' ? 'Diapositiva' : 'Slide'} ${j + 1}`}
              aria-selected={j === idx}
              onClick={() => goTo(j)}
            />
          ))}
        </div>
      </div>
    </section>
  );
}

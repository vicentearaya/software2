import { useRef } from 'react';
import { t } from '../i18n/translations';
import { useHeroMotion } from '../hooks/useHeroMotion';
import flotadorImg from '../../imagen/flotador.png';

export default function Hero({ lang, reduced }) {
  const shellRef = useRef(null);
  useHeroMotion(shellRef, reduced);

  return (
    <section
      ref={shellRef}
      className="hero-shell max-w-[1200px] mx-auto px-5 py-10 md:py-[4.5rem] md:px-10 [--hx:0px] [--hy:0px]"
      aria-labelledby="hero-title"
    >
      <div className="grid gap-8 md:gap-14 items-center md:grid-cols-[1.05fr_0.95fr]">
        <div className="text-start">
          <p className="m-0 mb-3 text-[0.72rem] font-extrabold tracking-[0.22em] uppercase text-[rgba(0,255,214,0.75)] drop-shadow-[0_0_24px_rgba(0,255,214,0.35)]">
            {t(lang, 'hero.eyebrow')}
          </p>
          <h1
            id="hero-title"
            className="m-0 mb-4 text-[clamp(2.1rem,5.2vw,3.35rem)] font-extrabold leading-[1.06] tracking-tight"
          >
            <span className="bg-gradient-to-br from-[#5eead4] via-[#86efac] via-30% to-[#d8b4fe] to-70% bg-clip-text text-transparent drop-shadow-[0_4px_28px_rgba(0,255,214,0.18)]">
              {t(lang, 'hero.title')}
            </span>
          </h1>
          <p className="m-0 mb-7 max-w-[36rem] text-[clamp(1rem,2.2vw,1.12rem)] font-medium text-[rgba(180,255,232,0.74)] leading-relaxed">
            {t(lang, 'hero.sub')}
          </p>
          <div className="flex flex-wrap gap-3">
            <a
              href="#grid-title"
              className="inline-flex items-center justify-center px-[1.35rem] py-[0.72rem] rounded-full font-bold text-[0.9rem] no-underline border border-[rgba(0,255,214,0.45)] bg-gradient-to-br from-[rgba(0,255,214,0.22)] to-[rgba(167,139,250,0.18)] text-[#ecfffb] shadow-[0_0_32px_rgba(0,255,214,0.2),inset_0_1px_0_rgba(255,255,255,0.12)] transition-all hover:-translate-y-0.5 hover:shadow-[0_12px_40px_rgba(0,0,0,0.35),0_0_40px_rgba(192,132,252,0.28)] hover:border-[rgba(192,132,252,0.55)]"
            >
              {t(lang, 'hero.cta1')}
            </a>
            <a
              href="#orbit-title"
              className="inline-flex items-center justify-center px-[1.35rem] py-[0.72rem] rounded-full font-bold text-[0.9rem] no-underline border border-[rgba(255,255,255,0.18)] bg-[rgba(0,0,0,0.25)] text-[rgba(220,255,245,0.92)] transition-all hover:-translate-y-0.5 hover:border-[rgba(0,255,214,0.4)] hover:bg-[rgba(0,255,214,0.08)]"
            >
              {t(lang, 'hero.cta2')}
            </a>
          </div>
        </div>

        <div className="relative min-h-[220px] md:min-h-[340px] isolate" aria-hidden="true">
          <span className="hero-shape hero-blob-a" />
          <span className="hero-shape hero-blob-b" />
          <span className="hero-shape hero-ring-outer" />
          <span className="hero-shape hero-ring-inner" />
          <div className="hero-float-wrap">
            <img
              src={flotadorImg}
              alt=""
              className="w-full h-auto drop-shadow-[0_24px_60px_rgba(0,255,214,0.35)]"
            />
          </div>
        </div>
      </div>

      <style>{`
        .hero-shape {
          position: absolute;
          pointer-events: none;
          transition: transform 0.35s cubic-bezier(0.22, 1, 0.36, 1);
        }
        .hero-blob-a {
          left: 8%;
          top: 6%;
          width: clamp(100px, 22vw, 160px);
          height: clamp(100px, 22vw, 160px);
          border-radius: 58% 42% 62% 38% / 48% 52% 48% 52%;
          background: radial-gradient(circle at 32% 28%, rgba(255,255,255,0.55), transparent 45%),
            linear-gradient(145deg, #00ffd6, #22c55e);
          box-shadow: 0 24px 50px rgba(0,0,0,0.45), 0 0 60px rgba(0,255,214,0.25);
          transform: translate(var(--hx), var(--hy)) rotate(-8deg);
        }
        .hero-blob-b {
          right: 12%;
          top: 18%;
          width: clamp(72px, 14vw, 110px);
          height: clamp(72px, 14vw, 110px);
          border-radius: 50%;
          background: conic-gradient(from 210deg, #a855f7, #ec4899, #fbbf24, #a855f7);
          opacity: 0.92;
          box-shadow: 0 20px 45px rgba(0,0,0,0.4);
          transform: translate(calc(var(--hx) * -1.1), calc(var(--hy) * 0.9));
        }
        .hero-ring-outer {
          left: 50%;
          top: 42%;
          width: clamp(160px, 36vw, 240px);
          height: clamp(160px, 36vw, 240px);
          margin-left: calc(clamp(160px, 36vw, 240px) / -2);
          margin-top: calc(clamp(160px, 36vw, 240px) / -2);
          border-radius: 50%;
          border: 2px solid rgba(0, 255, 214, 0.28);
          box-shadow: 0 0 0 1px rgba(255,255,255,0.06) inset, 0 0 48px rgba(0,255,214,0.12);
          transform: translate(var(--hx), var(--hy)) rotate(12deg);
        }
        .hero-ring-inner {
          left: 50%;
          top: 42%;
          width: clamp(96px, 22vw, 140px);
          height: clamp(96px, 22vw, 140px);
          margin-left: calc(clamp(96px, 22vw, 140px) / -2);
          margin-top: calc(clamp(96px, 22vw, 140px) / -2);
          border-radius: 50%;
          border: 2px dashed rgba(255, 255, 255, 0.2);
          transform: translate(calc(var(--hx) * 0.6), calc(var(--hy) * 0.5)) rotate(-18deg);
        }
        .hero-float-wrap {
          position: absolute;
          left: 50%;
          top: 50%;
          width: clamp(180px, 42vw, 280px);
          z-index: 10;
          transform: translate(calc(-50% + var(--hx, 0px)), calc(-50% + var(--hy, 0px)));
          animation: hero-float 4s ease-in-out infinite;
        }
        @keyframes hero-float {
          0%, 100% { margin-top: 0; }
          50% { margin-top: -12px; }
        }
        @media (prefers-reduced-motion: reduce) {
          .hero-shape, .hero-float-wrap { transition: none; animation: none; }
        }
      `}</style>
    </section>
  );
}

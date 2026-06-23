import { useRef } from 'react';
import { t } from '../i18n/translations';
import { useHeroMotion } from '../hooks/useHeroMotion';
import flotadorImg from '../../imagen/flotador.png';

export default function Hero({ lang, reduced }) {
  const shellRef = useRef(null);
  useHeroMotion(shellRef, reduced);

  const deviceLabel = lang === 'es' ? 'Flotador inteligente' : 'Smart floater';
  const statusLabel = lang === 'es' ? 'Monitoreo activo' : 'Active monitoring';

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

        <div className="hero-visual relative min-h-[280px] sm:min-h-[320px] md:min-h-[400px] isolate flex items-center justify-center" aria-hidden="true">
          <div className="hero-showcase">
            <div className="hero-showcase__halo" />
            <div className="hero-showcase__orbit hero-showcase__orbit--a" />
            <div className="hero-showcase__orbit hero-showcase__orbit--b" />

            <div className="hero-showcase__frame">
              <div className="hero-showcase__rim" />
              <div className="hero-showcase__glass" />

              <div className="hero-showcase__viewport">
                <img src={flotadorImg} alt="" className="hero-showcase__img" />
                <div className="hero-showcase__vignette" />
                <div className="hero-showcase__shine" />
                <div className="hero-showcase__water-glow" />
              </div>

              <div className="hero-showcase__pedestal">
                <span className="hero-showcase__status">
                  <span className="hero-showcase__pulse" />
                  {statusLabel}
                </span>
                <span className="hero-showcase__label">{deviceLabel}</span>
              </div>
            </div>

            <span className="hero-showcase__chip hero-showcase__chip--tl">pH</span>
            <span className="hero-showcase__chip hero-showcase__chip--tr hero-showcase__chip--case">Temp</span>
            <span className="hero-showcase__chip hero-showcase__chip--br">ORP</span>
          </div>
        </div>
      </div>

      <style>{`
        .hero-visual {
          perspective: 900px;
        }

        .hero-showcase {
          position: relative;
          width: clamp(180px, 42vw, 280px);
          transform: translate(var(--hx), var(--hy));
          animation: hero-float 5s ease-in-out infinite;
        }

        .hero-showcase__halo {
          position: absolute;
          inset: -18% -12%;
          border-radius: 50%;
          background: radial-gradient(
            ellipse 70% 60% at 50% 45%,
            rgba(0, 255, 214, 0.22),
            rgba(168, 85, 247, 0.12) 45%,
            transparent 72%
          );
          filter: blur(8px);
          pointer-events: none;
        }

        .hero-showcase__orbit {
          position: absolute;
          left: 50%;
          top: 46%;
          border-radius: 50%;
          pointer-events: none;
          border: 1px solid rgba(0, 255, 214, 0.2);
        }

        .hero-showcase__orbit--a {
          width: 108%;
          aspect-ratio: 1;
          margin-left: -54%;
          margin-top: -54%;
          box-shadow: 0 0 40px rgba(0, 255, 214, 0.08) inset;
          animation: hero-spin 28s linear infinite;
        }

        .hero-showcase__orbit--b {
          width: 124%;
          aspect-ratio: 1;
          margin-left: -62%;
          margin-top: -62%;
          border-style: dashed;
          border-color: rgba(192, 132, 252, 0.22);
          animation: hero-spin 36s linear infinite reverse;
        }

        .hero-showcase__frame {
          position: relative;
          border-radius: 2rem;
          padding: 10px;
          background: linear-gradient(
            145deg,
            rgba(0, 255, 214, 0.14),
            rgba(168, 85, 247, 0.1) 50%,
            rgba(8, 226, 96, 0.12)
          );
          box-shadow:
            0 28px 60px rgba(0, 0, 0, 0.55),
            0 0 0 1px rgba(255, 255, 255, 0.08) inset,
            0 0 48px rgba(0, 255, 214, 0.12);
          transform: rotateX(4deg) rotateY(-6deg);
          transform-style: preserve-3d;
          transition: transform 0.4s cubic-bezier(0.22, 1, 0.36, 1);
        }

        .hero-visual:hover .hero-showcase__frame {
          transform: rotateX(2deg) rotateY(-2deg) translateY(-4px);
        }

        .hero-showcase__rim {
          position: absolute;
          inset: 0;
          border-radius: inherit;
          padding: 1px;
          background: linear-gradient(
            135deg,
            rgba(0, 255, 214, 0.65),
            rgba(255, 255, 255, 0.35) 35%,
            rgba(192, 132, 252, 0.55) 70%,
            rgba(8, 226, 96, 0.5)
          );
          -webkit-mask: linear-gradient(#fff 0 0) content-box, linear-gradient(#fff 0 0);
          -webkit-mask-composite: xor;
          mask-composite: exclude;
          pointer-events: none;
          z-index: 4;
        }

        .hero-showcase__glass {
          position: absolute;
          inset: 8px 8px auto 8px;
          height: 42%;
          border-radius: 1.35rem 1.35rem 2.5rem 0.5rem;
          background: linear-gradient(
            180deg,
            rgba(255, 255, 255, 0.22) 0%,
            rgba(255, 255, 255, 0.04) 100%
          );
          border: 1px solid rgba(255, 255, 255, 0.18);
          border-bottom: none;
          pointer-events: none;
          z-index: 3;
        }

        .hero-showcase__viewport {
          position: relative;
          overflow: hidden;
          border-radius: 1.35rem;
          background: linear-gradient(180deg, #0c4a6e 0%, #061210 100%);
          box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.35) inset;
          line-height: 0;
        }

        .hero-showcase__img {
          display: block;
          width: 100%;
          height: auto;
        }

        .hero-showcase__vignette {
          position: absolute;
          inset: 0;
          background:
            radial-gradient(ellipse 90% 80% at 50% 40%, transparent 30%, rgba(4, 8, 7, 0.55) 100%),
            linear-gradient(180deg, rgba(4, 8, 7, 0.15) 0%, transparent 25%, rgba(4, 8, 7, 0.45) 100%);
          pointer-events: none;
        }

        .hero-showcase__shine {
          position: absolute;
          inset: 0;
          background: linear-gradient(
            125deg,
            rgba(255, 255, 255, 0.28) 0%,
            transparent 38%,
            transparent 62%,
            rgba(0, 255, 214, 0.08) 100%
          );
          mix-blend-mode: soft-light;
          pointer-events: none;
        }

        .hero-showcase__water-glow {
          position: absolute;
          left: 10%;
          right: 10%;
          bottom: 8%;
          height: 28%;
          border-radius: 50%;
          background: radial-gradient(ellipse at center, rgba(0, 255, 214, 0.35), transparent 70%);
          filter: blur(12px);
          pointer-events: none;
        }

        .hero-showcase__pedestal {
          display: flex;
          align-items: center;
          justify-content: space-between;
          gap: 0.75rem;
          margin-top: 0.65rem;
          padding: 0.55rem 0.85rem;
          border-radius: 999px;
          background: rgba(4, 12, 10, 0.72);
          border: 1px solid rgba(0, 255, 214, 0.22);
          backdrop-filter: blur(12px);
          -webkit-backdrop-filter: blur(12px);
          box-shadow: 0 8px 24px rgba(0, 0, 0, 0.35);
        }

        .hero-showcase__status {
          display: inline-flex;
          align-items: center;
          gap: 0.45rem;
          font-size: 0.68rem;
          font-weight: 800;
          letter-spacing: 0.06em;
          text-transform: uppercase;
          color: rgba(180, 255, 232, 0.85);
        }

        .hero-showcase__pulse {
          width: 7px;
          height: 7px;
          border-radius: 50%;
          background: #08e260;
          box-shadow: 0 0 12px rgba(8, 226, 96, 0.85);
          animation: hero-pulse 2s ease-in-out infinite;
        }

        .hero-showcase__label {
          font-size: 0.78rem;
          font-weight: 700;
          color: rgba(220, 255, 245, 0.92);
          white-space: nowrap;
        }

        .hero-showcase__chip {
          position: absolute;
          z-index: 5;
          padding: 0.35rem 0.65rem;
          border-radius: 999px;
          font-size: 0.65rem;
          font-weight: 900;
          letter-spacing: 0.08em;
          text-transform: uppercase;
          color: #00894d;
          background: rgba(255, 255, 255, 0.92);
          border: 1px solid rgba(255, 255, 255, 0.65);
          box-shadow:
            0 10px 28px rgba(0, 0, 0, 0.35),
            0 0 20px rgba(0, 255, 214, 0.15);
        }

        .hero-showcase__chip--tl {
          top: -6%;
          left: -4%;
          transform: translate(calc(var(--hx) * 0.3), calc(var(--hy) * 0.3));
        }

        .hero-showcase__chip--case {
          text-transform: none;
          letter-spacing: 0.04em;
        }

        .hero-showcase__chip--tr {
          top: 4%;
          right: -10%;
          color: #9a3412;
          transform: translate(calc(var(--hx) * -0.25), calc(var(--hy) * 0.35));
        }

        .hero-showcase__chip--br {
          bottom: 14%;
          right: -8%;
          color: #3b0764;
          transform: translate(calc(var(--hx) * -0.4), calc(var(--hy) * -0.3));
        }

        @keyframes hero-float {
          0%, 100% { transform: translate(var(--hx), var(--hy)) translateY(0); }
          50% { transform: translate(var(--hx), var(--hy)) translateY(-10px); }
        }

        @keyframes hero-spin {
          from { transform: rotate(0deg); }
          to { transform: rotate(360deg); }
        }

        @keyframes hero-pulse {
          0%, 100% { opacity: 1; transform: scale(1); }
          50% { opacity: 0.65; transform: scale(0.85); }
        }

        @media (min-width: 640px) {
          .hero-showcase {
            width: clamp(200px, 38vw, 280px);
          }
        }

        @media (prefers-reduced-motion: reduce) {
          .hero-showcase,
          .hero-showcase__orbit--a,
          .hero-showcase__orbit--b,
          .hero-showcase__pulse {
            animation: none;
          }
          .hero-showcase__frame {
            transform: none;
          }
          .hero-visual:hover .hero-showcase__frame {
            transform: none;
          }
        }
      `}</style>
    </section>
  );
}

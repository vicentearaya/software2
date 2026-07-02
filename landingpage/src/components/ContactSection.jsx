import { useRef, useState } from 'react';
import { t } from '../i18n/translations';
import { useReveal } from '../hooks/useReveal';

const WHATSAPP = '+56965915325';
const WHATSAPP_LINK = 'https://wa.me/56965915325';
const FORM_ENDPOINT = 'https://formsubmit.co/ajax/v.arayadaz@uandresbello.edu';
const EMAILS = [
  { name: 'Vicente Araya', address: 'v.arayadaz@uandresbello.edu' },
  { name: 'Daniel Cortez', address: 'd.cortezfierro@uandresbello.edu' },
  { name: 'Constanza Malebran', address: 'c.malebrnpea@uandresbello.edu' },
  { name: 'Diego Carmona', address: 'd.carmonabustamante@uandresbello.edu' },
];
const TEAM = ['Diego Carmona', 'Constanza Malebran', 'Daniel Cortez', 'Vicente Araya'];

const inputClass =
  'w-full px-4 py-3 rounded-xl border border-[rgba(0,255,214,0.18)] bg-[rgba(0,255,214,0.04)] text-[rgba(200,255,240,0.92)] font-semibold text-[0.95rem] placeholder:text-[rgba(180,230,215,0.35)] outline-none transition-all focus:border-[rgba(192,132,252,0.45)] focus:bg-[rgba(192,132,252,0.06)] focus:shadow-[0_0_20px_rgba(0,255,214,0.08)]';

export default function ContactSection({ lang, reduced }) {
  const sectionRef = useRef(null);
  useReveal(sectionRef, reduced);

  const [form, setForm] = useState({ name: '', email: '', message: '' });
  const [status, setStatus] = useState('idle');

  const handleChange = (e) => {
    const { name, value } = e.target;
    setForm((prev) => ({ ...prev, [name]: value }));
    if (status !== 'idle') setStatus('idle');
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setStatus('sending');

    try {
      const res = await fetch(FORM_ENDPOINT, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'application/json',
        },
        body: JSON.stringify({
          name: form.name,
          email: form.email,
          message: form.message,
          _subject: `CleanPool — mensaje de ${form.name}`,
          _captcha: 'false',
        }),
      });

      if (res.ok) {
        setForm({ name: '', email: '', message: '' });
        setStatus('success');
      } else {
        setStatus('error');
      }
    } catch {
      setStatus('error');
    }
  };

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

        {EMAILS.map(({ name, address }) => (
          <a
            key={address}
            href={`mailto:${address}`}
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
                {t(lang, 'contact.email')} · {name}
              </span>
              <span className="block text-[0.95rem] font-semibold text-[rgba(200,255,240,0.9)] truncate">
                {address}
              </span>
            </span>
          </a>
        ))}
      </div>

      <form
        onSubmit={handleSubmit}
        className="mt-8 max-w-[900px] mx-auto p-6 rounded-2xl border border-[rgba(0,255,214,0.12)] bg-[rgba(0,255,214,0.03)] backdrop-blur-sm"
        noValidate
      >
        <p className="m-0 mb-5 text-xs font-black uppercase tracking-wide text-[rgba(0,255,214,0.75)]">
          {t(lang, 'contact.form.title')}
        </p>

        <div className="grid gap-4 sm:grid-cols-2">
          <label className="block">
            <span className="sr-only">{t(lang, 'contact.form.name')}</span>
            <input
              type="text"
              name="name"
              value={form.name}
              onChange={handleChange}
              placeholder={t(lang, 'contact.form.name')}
              required
              autoComplete="name"
              className={inputClass}
            />
          </label>
          <label className="block">
            <span className="sr-only">{t(lang, 'contact.form.email')}</span>
            <input
              type="email"
              name="email"
              value={form.email}
              onChange={handleChange}
              placeholder={t(lang, 'contact.form.email')}
              required
              autoComplete="email"
              className={inputClass}
            />
          </label>
        </div>

        <label className="block mt-4">
          <span className="sr-only">{t(lang, 'contact.form.message')}</span>
          <textarea
            name="message"
            value={form.message}
            onChange={handleChange}
            placeholder={t(lang, 'contact.form.message')}
            required
            rows={5}
            className={`${inputClass} resize-y min-h-[8rem]`}
          />
        </label>

        <input type="text" name="_gotcha" className="hidden" tabIndex={-1} autoComplete="off" aria-hidden="true" />

        <div className="mt-5 flex flex-col sm:flex-row sm:items-center gap-4">
          <button
            type="submit"
            disabled={status === 'sending'}
            className="font-extrabold text-[0.9rem] px-6 py-3 rounded-full border border-[rgba(0,255,214,0.35)] bg-[rgba(0,255,214,0.08)] text-[#b4ffe8] cursor-pointer shadow-[0_0_20px_rgba(0,255,214,0.12),inset_0_1px_0_rgba(255,255,255,0.12)] transition-all hover:border-[rgba(192,132,252,0.6)] hover:shadow-[0_0_28px_rgba(192,132,252,0.25)] hover:-translate-y-px disabled:opacity-60 disabled:cursor-not-allowed disabled:hover:translate-y-0"
          >
            {status === 'sending' ? t(lang, 'contact.form.sending') : t(lang, 'contact.form.submit')}
          </button>

          {status === 'success' && (
            <p className="m-0 text-[0.9rem] font-semibold text-[rgba(0,255,214,0.85)]" role="status">
              {t(lang, 'contact.form.success')}
            </p>
          )}
          {status === 'error' && (
            <p className="m-0 text-[0.9rem] font-semibold text-[rgba(248,113,113,0.9)]" role="alert">
              {t(lang, 'contact.form.error')}
            </p>
          )}
        </div>
      </form>

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

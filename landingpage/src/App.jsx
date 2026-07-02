import { useCallback, useEffect, useMemo, useState } from 'react';
import { LANG_KEY, t } from './i18n/translations';
import Header from './components/Header';
import Hero from './components/Hero';
import FeatureGrid from './components/FeatureGrid';
import AppShowcase from './components/AppShowcase';
import SpotlightCarousel from './components/SpotlightCarousel';
import ValueSection from './components/ValueSection';
import ContactSection from './components/ContactSection';
import Footer from './components/Footer';

export default function App() {
  const reduced = useMemo(
    () => window.matchMedia('(prefers-reduced-motion: reduce)').matches,
    [],
  );

  const [lang, setLang] = useState(() => localStorage.getItem(LANG_KEY) || 'es');

  const toggleLang = useCallback(() => {
    setLang((prev) => (prev === 'es' ? 'en' : 'es'));
  }, []);

  useEffect(() => {
    localStorage.setItem(LANG_KEY, lang);
    document.documentElement.lang = lang;
    document.title = t(lang, 'meta.title');
  }, [lang]);

  return (
    <>
      <Header lang={lang} onToggleLang={toggleLang} />
      <main id="main">
        <Hero lang={lang} reduced={reduced} />
        <FeatureGrid lang={lang} reduced={reduced} />
        <AppShowcase lang={lang} reduced={reduced} />
        <SpotlightCarousel lang={lang} reduced={reduced} />
        <ValueSection lang={lang} reduced={reduced} />
        <ContactSection lang={lang} reduced={reduced} />
      </main>
      <Footer lang={lang} />
    </>
  );
}

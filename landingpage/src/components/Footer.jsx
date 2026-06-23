import { t } from '../i18n/translations';

export default function Footer({ lang }) {
  return (
    <footer className="text-center py-12 px-4 pb-14 text-[0.82rem] font-semibold text-[rgba(180,230,215,0.4)] border-t border-[rgba(0,255,214,0.08)]">
      <p className="m-0">{t(lang, 'footer.note')}</p>
    </footer>
  );
}

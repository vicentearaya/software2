const ICONS = {
  dashboard: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path fill="#fff" d="M3 13h8V3H3v10zm0 8h8v-6H3v6zm10 0h8V11h-8v10zm0-18v6h8V3h-8z" />
    </svg>
  ),
  iot: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path fill="#fff" d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z" />
    </svg>
  ),
  recommend: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path fill="#fff" d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
    </svg>
  ),
  inventory: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path fill="#fff" d="M20 6h-2.18c.11-.31.18-.65.18-1 0-1.66-1.34-3-3-3-1.05 0-1.96.54-2.5 1.35l-.5.67-.5-.68C10.96 2.54 10.05 2 9 2 7.34 2 6 3.34 6 5c0 .35.07.69.18 1H4c-1.11 0-1.99.89-1.99 2L2 19c0 1.11.89 2 2 2h16c1.11 0 2-.89 2-2V8c0-1.11-.89-2-2-2zm-5-2c.55 0 1 .45 1 1s-.45 1-1 1-1-.45-1-1 .45-1 1-1zM9 4c.55 0 1 .45 1 1s-.45 1-1 1-1-.45-1-1 .45-1 1-1zm11 15H4v-2h16v2zm0-5H4V8h5.08L7 10.83 8.62 12 11 8.76l1-1.36 1 1.36L15.38 12 17 10.83 14.92 8H20v6z" />
    </svg>
  ),
  guides: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path fill="#fff" d="M18 2H6c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zM6 4h5v8l-2.5-1.5L6 12V4z" />
    </svg>
  ),
  history: (
    <svg viewBox="0 0 24 24" aria-hidden="true">
      <path fill="#fff" d="M13 3a9 9 0 0 0-9 9H1l3.89 3.89.07.14L9 12H6c0-3.87 3.13-7 7-7s7 3.13 7 7-3.13 7-7 7c-1.93 0-3.68-.79-4.94-2.06l-1.42 1.42A8.954 8.954 0 0 0 13 21a9 9 0 0 0 0-18zm-1 5v5l4.28 2.54.72-1.21-3.5-2.08V8H12z" />
    </svg>
  ),
};

export default function FeatureCard({ theme, cut, wide, span2, icon, title, text, tag }) {
  const classes = [
    'ux-parent',
    `ux-parent--${theme}`,
    cut && 'ux-parent--cut',
    wide && 'ux-parent--wide',
    span2 && 'ux-parent--span-2',
  ]
    .filter(Boolean)
    .join(' ');

  return (
    <div className={classes}>
      <div className="ux-card">
        <div className="ux-logo" aria-hidden="true">
          <span className="ux-circle" />
          <span className="ux-circle" />
          <span className="ux-circle" />
          <span className="ux-circle" />
          <span className="ux-circle">{ICONS[icon]}</span>
        </div>
        <div className="ux-glass" />
        <div className="ux-content">
          <span className="ux-title">{title}</span>
          <span className="ux-text">{text}</span>
        </div>
        <div className="ux-bottom">
          <span className="ux-tag">{tag}</span>
        </div>
      </div>
    </div>
  );
}

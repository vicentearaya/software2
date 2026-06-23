import { useEffect } from 'react';

export function useHeroMotion(ref, reduced) {
  useEffect(() => {
    const shell = ref.current;
    if (!shell || reduced) return;

    const onMove = (e) => {
      const r = shell.getBoundingClientRect();
      const x = (e.clientX - r.left) / r.width - 0.5;
      const y = (e.clientY - r.top) / r.height - 0.5;
      shell.style.setProperty('--hx', `${(x * 28).toFixed(1)}px`);
      shell.style.setProperty('--hy', `${(y * 22).toFixed(1)}px`);
    };

    const onLeave = () => {
      shell.style.setProperty('--hx', '0px');
      shell.style.setProperty('--hy', '0px');
    };

    shell.addEventListener('mousemove', onMove);
    shell.addEventListener('mouseleave', onLeave);
    return () => {
      shell.removeEventListener('mousemove', onMove);
      shell.removeEventListener('mouseleave', onLeave);
    };
  }, [ref, reduced]);
}

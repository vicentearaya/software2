import { useCallback, useEffect, useRef, useState } from 'react';

export function useCarousel(panelCount, reduced) {
  const rootRef = useRef(null);
  const viewportRef = useRef(null);
  const trackRef = useRef(null);
  const [idx, setIdx] = useState(0);
  const [width, setWidth] = useState(0);
  const swipeRef = useRef({ active: false, startX: 0, pid: null });

  const measure = useCallback(() => {
    const viewport = viewportRef.current;
    if (!viewport) return;
    const w = viewport.clientWidth || 0;
    setWidth(w);
  }, []);

  const go = useCallback(
    (delta) => {
      setIdx((prev) => (prev + delta + panelCount * 100) % panelCount);
    },
    [panelCount],
  );

  const goTo = useCallback((j) => setIdx(j), []);

  useEffect(() => {
    measure();
    const viewport = viewportRef.current;
    if (!viewport) return;

    let ro;
    if (typeof ResizeObserver !== 'undefined') {
      ro = new ResizeObserver(measure);
      ro.observe(viewport);
    } else {
      window.addEventListener('resize', measure);
    }
    return () => {
      ro?.disconnect();
      window.removeEventListener('resize', measure);
    };
  }, [measure]);

  useEffect(() => {
    const track = trackRef.current;
    if (!track || width < 1) return;
    track.style.transition = reduced
      ? 'none'
      : 'transform 0.55s cubic-bezier(0.2, 0.85, 0.25, 1)';
    track.style.transform = `translate3d(${-idx * width}px,0,0)`;
  }, [idx, width, reduced]);

  const onKeyDown = useCallback(
    (e) => {
      if (e.key === 'ArrowLeft') {
        e.preventDefault();
        go(-1);
      } else if (e.key === 'ArrowRight') {
        e.preventDefault();
        go(1);
      } else if (e.key === 'Home') {
        e.preventDefault();
        goTo(0);
      } else if (e.key === 'End') {
        e.preventDefault();
        goTo(panelCount - 1);
      }
    },
    [go, goTo, panelCount],
  );

  const onPointerDown = useCallback((e) => {
    if (e.pointerType === 'mouse' && e.button !== 0) return;
    swipeRef.current = { active: true, startX: e.clientX, pid: e.pointerId };
    try {
      viewportRef.current?.setPointerCapture(e.pointerId);
    } catch {
      /* noop */
    }
  }, []);

  const onPointerUp = useCallback(
    (e) => {
      const swipe = swipeRef.current;
      if (!swipe.active || e.pointerId !== swipe.pid) return;
      swipeRef.current = { active: false, startX: 0, pid: null };
      const dx = e.clientX - swipe.startX;
      if (Math.abs(dx) < 40) return;
      go(dx < 0 ? 1 : -1);
    },
    [go],
  );

  const onPointerCancel = useCallback(() => {
    swipeRef.current = { active: false, startX: 0, pid: null };
  }, []);

  return {
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
    panelWidth: width,
  };
}

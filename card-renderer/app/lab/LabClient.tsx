'use client';

import { useCallback, useEffect, useMemo, useRef, useState, type PointerEvent } from 'react';
import { CardRenderer } from '../../lib/CardRenderer';
import {
  CARD_HEIGHT,
  CARD_LAYOUT,
  CARD_TEMPLATE_FILENAME,
  CARD_TEMPLATE_PATH,
  CARD_WIDTH,
  CAT_IMAGE_Y_OFFSET,
  type CardLayout,
  type EditableLayoutKey,
  cloneCardLayout,
  formatLayoutExport,
} from '../../lib/cardLayout';

const STORAGE_KEY = 'catdex_card_renderer_layout';
const STORAGE_VERSION_KEY = 'catdex_card_renderer_layout_version';
const LAYOUT_VERSION = 'final_v1';
const sampleData = {
  cardNumber: '#0008',
  catName: 'LUNETTA',
  species: 'Gatto domestico bicolore',
  starCount: 1,
};

type DragState = {
  key: EditableLayoutKey;
  offsetX: number;
  offsetY: number;
};

const controlFields: Record<EditableLayoutKey, string[]> = {
  cardNumber: ['x', 'y', 'width', 'height', 'fontSize', 'letterSpacing'],
  catName: ['x', 'y', 'width', 'height', 'fontSize', 'letterSpacing'],
  stars: ['x', 'y', 'width', 'height', 'starSize', 'gap'],
  species: ['x', 'y', 'width', 'height', 'fontSize', 'letterSpacing'],
};

function isEditableKey(value: string): value is EditableLayoutKey {
  return value === 'cardNumber' || value === 'catName' || value === 'stars' || value === 'species';
}

function readSavedLayout(): CardLayout {
  if (typeof window === 'undefined') {
    return cloneCardLayout();
  }

  try {
    if (window.localStorage.getItem(STORAGE_VERSION_KEY) !== LAYOUT_VERSION) {
      return cloneCardLayout();
    }

    const saved = window.localStorage.getItem(STORAGE_KEY);
    if (!saved) {
      return cloneCardLayout();
    }

    return { ...cloneCardLayout(), ...JSON.parse(saved) } as CardLayout;
  } catch {
    return cloneCardLayout();
  }
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

export default function LabClient() {
  const [layout, setLayout] = useState<CardLayout>(() => cloneCardLayout());
  const [showSafeBoxes, setShowSafeBoxes] = useState(true);
  const [scale, setScale] = useState(0.42);
  const [copyLabel, setCopyLabel] = useState('Copy layout JSON');
  const previewRef = useRef<HTMLDivElement | null>(null);
  const canvasRef = useRef<HTMLDivElement | null>(null);
  const dragRef = useRef<DragState | null>(null);

  const exportText = useMemo(() => formatLayoutExport(layout), [layout]);

  useEffect(() => {
    setLayout(readSavedLayout());
    console.log('CATDEX_RENDERER_TEMPLATE_PATH', CARD_TEMPLATE_PATH);
    console.log('CATDEX_RENDERER_FONT', 'CinzelDecorative');
    console.log('CATDEX_FONT_PRIMARY', 'CinzelDecorative');
    console.log('CATDEX_RENDERER_LAYOUT_VERSION', LAYOUT_VERSION);
    console.log('CATDEX_RENDERER_USING_FINAL_LAYOUT', true);
    console.log('CATDEX_CAT_IMAGE_Y_OFFSET', CAT_IMAGE_Y_OFFSET);
  }, []);

  useEffect(() => {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(layout));
    window.localStorage.setItem(STORAGE_VERSION_KEY, LAYOUT_VERSION);
  }, [layout]);

  useEffect(() => {
    const preview = previewRef.current;
    if (!preview) {
      return undefined;
    }

    const updateScale = () => {
      const nextScale = clamp(preview.clientWidth / CARD_WIDTH, 0.18, 1);
      setScale(nextScale);
    };

    updateScale();
    const observer = new ResizeObserver(updateScale);
    observer.observe(preview);
    window.addEventListener('resize', updateScale);

    return () => {
      observer.disconnect();
      window.removeEventListener('resize', updateScale);
    };
  }, []);

  const updateSlot = useCallback((key: EditableLayoutKey, field: string, value: number) => {
    setLayout((current) => ({
      ...current,
      [key]: {
        ...current[key],
        [field]: value,
      },
    }));
  }, []);

  const pointerToCanvas = useCallback((clientX: number, clientY: number) => {
    const canvas = canvasRef.current;
    if (!canvas) {
      return { x: 0, y: 0 };
    }

    const rect = canvas.getBoundingClientRect();
    const actualScale = rect.width / CARD_WIDTH;
    return {
      x: (clientX - rect.left) / actualScale,
      y: (clientY - rect.top) / actualScale,
    };
  }, []);

  const handleDragStart = useCallback(
    (key: EditableLayoutKey, event: PointerEvent<HTMLDivElement>) => {
      event.preventDefault();
      event.stopPropagation();
      const point = pointerToCanvas(event.clientX, event.clientY);
      dragRef.current = {
        key,
        offsetX: point.x - layout[key].x,
        offsetY: point.y - layout[key].y,
      };
    },
    [layout, pointerToCanvas],
  );

  useEffect(() => {
    const handleMove = (event: globalThis.PointerEvent) => {
      const drag = dragRef.current;
      if (!drag) {
        return;
      }

      const point = pointerToCanvas(event.clientX, event.clientY);
      setLayout((current) => {
        const slot = current[drag.key];
        const nextX = Math.round(clamp(point.x - drag.offsetX, 0, CARD_WIDTH - slot.width));
        const nextY = Math.round(clamp(point.y - drag.offsetY, 0, CARD_HEIGHT - slot.height));

        return {
          ...current,
          [drag.key]: {
            ...slot,
            x: nextX,
            y: nextY,
          },
        };
      });
    };

    const handleUp = () => {
      dragRef.current = null;
    };

    window.addEventListener('pointermove', handleMove);
    window.addEventListener('pointerup', handleUp);
    window.addEventListener('pointercancel', handleUp);

    return () => {
      window.removeEventListener('pointermove', handleMove);
      window.removeEventListener('pointerup', handleUp);
      window.removeEventListener('pointercancel', handleUp);
    };
  }, [pointerToCanvas]);

  const copyLayout = async () => {
    console.log('CATDEX_RENDERER_LAYOUT_EXPORT', exportText);
    await navigator.clipboard.writeText(exportText);
    setCopyLabel('Copied');
    window.setTimeout(() => setCopyLabel('Copy layout JSON'), 1200);
  };

  const resetLayout = () => {
    const nextLayout = cloneCardLayout(CARD_LAYOUT);
    setLayout(nextLayout);
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(nextLayout));
    window.localStorage.setItem(STORAGE_VERSION_KEY, LAYOUT_VERSION);
  };

  return (
    <main style={styles.page}>
      <section style={styles.previewPane}>
        <div style={styles.previewHeader}>
          <div>
            <h1 style={styles.title}>CatDex Layout Lab</h1>
            <p style={styles.meta}>1500 x 2100 canvas</p>
          </div>
          <label style={styles.toggle}>
            <input
              type="checkbox"
              checked={showSafeBoxes}
              onChange={(event) => setShowSafeBoxes(event.target.checked)}
            />
            Show safe boxes
          </label>
        </div>

        <div ref={previewRef} style={styles.previewViewport}>
          <div style={{ width: CARD_WIDTH * scale, height: CARD_HEIGHT * scale, position: 'relative' }}>
            <div
              ref={canvasRef}
              style={{
                width: CARD_WIDTH,
                height: CARD_HEIGHT,
                transform: `scale(${scale})`,
                transformOrigin: 'top left',
              }}
            >
              <CardRenderer
                templateUrl={CARD_TEMPLATE_PATH}
                data={sampleData}
                layout={layout}
                showSafeBoxes={showSafeBoxes}
                interactive
                onDragStart={handleDragStart}
              />
            </div>
          </div>
        </div>
        <div style={styles.templateDebug}>TEMPLATE: {CARD_TEMPLATE_FILENAME}</div>
      </section>

      <aside style={styles.controlsPane}>
        <div style={styles.actions}>
          <button type="button" style={styles.primaryButton} onClick={copyLayout}>
            {copyLabel}
          </button>
          <button type="button" style={styles.secondaryButton} onClick={resetLayout}>
            Reset layout
          </button>
        </div>

        {(Object.keys(controlFields) as EditableLayoutKey[]).map((key) => (
          <section key={key} style={styles.controlSection}>
            <h2 style={styles.sectionTitle}>{key}</h2>
            <div style={styles.controlGrid}>
              {controlFields[key].map((field) => (
                <label key={field} style={styles.controlLabel}>
                  <span>{field}</span>
                  <input
                    type="number"
                    value={layout[key][field as keyof (typeof layout)[typeof key]]}
                    step={field === 'letterSpacing' ? 0.5 : 1}
                    onChange={(event) => updateSlot(key, field, Number(event.target.value))}
                    style={styles.numberInput}
                  />
                </label>
              ))}
            </div>
          </section>
        ))}

        <pre style={styles.exportBox}>{exportText}</pre>
      </aside>
    </main>
  );
}

const styles: Record<string, React.CSSProperties> = {
  page: {
    minHeight: '100vh',
    display: 'grid',
    gridTemplateColumns: 'minmax(420px, 1fr) 420px',
    gap: 20,
    padding: 20,
    background: '#10131a',
    color: '#f6f7fb',
    fontFamily: 'Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif',
  },
  previewPane: {
    minWidth: 0,
    display: 'flex',
    flexDirection: 'column',
    gap: 14,
  },
  previewHeader: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    gap: 16,
  },
  title: {
    margin: 0,
    fontSize: 24,
    lineHeight: 1.1,
    letterSpacing: 0,
  },
  meta: {
    margin: '6px 0 0',
    color: '#a8b0c2',
    fontSize: 13,
  },
  toggle: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    color: '#d6dbea',
    fontSize: 14,
  },
  previewViewport: {
    width: '100%',
    maxWidth: 760,
    overflow: 'auto',
    border: '1px solid #2a3242',
    background: '#05070b',
    padding: 12,
  },
  templateDebug: {
    color: '#a8b0c2',
    fontSize: 12,
    letterSpacing: 0,
  },
  controlsPane: {
    display: 'flex',
    flexDirection: 'column',
    gap: 12,
    minWidth: 0,
  },
  actions: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: 10,
  },
  primaryButton: {
    minHeight: 40,
    border: 0,
    background: '#f6b93b',
    color: '#10131a',
    fontWeight: 800,
    cursor: 'pointer',
  },
  secondaryButton: {
    minHeight: 40,
    border: '1px solid #394357',
    background: '#171c26',
    color: '#f6f7fb',
    fontWeight: 700,
    cursor: 'pointer',
  },
  controlSection: {
    border: '1px solid #2a3242',
    padding: 12,
    background: '#151a24',
  },
  sectionTitle: {
    margin: '0 0 10px',
    fontSize: 14,
    letterSpacing: 0,
    color: '#f6f7fb',
  },
  controlGrid: {
    display: 'grid',
    gridTemplateColumns: '1fr 1fr',
    gap: 8,
  },
  controlLabel: {
    display: 'grid',
    gap: 4,
    color: '#a8b0c2',
    fontSize: 12,
  },
  numberInput: {
    width: '100%',
    minHeight: 34,
    boxSizing: 'border-box',
    border: '1px solid #394357',
    background: '#0f131b',
    color: '#f6f7fb',
    padding: '0 8px',
    fontSize: 14,
  },
  exportBox: {
    whiteSpace: 'pre-wrap',
    overflow: 'auto',
    maxHeight: 280,
    margin: 0,
    border: '1px solid #2a3242',
    background: '#0a0d13',
    color: '#d6dbea',
    padding: 12,
    fontSize: 12,
    lineHeight: 1.5,
  },
};

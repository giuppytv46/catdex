export const CARD_WIDTH = 1500;
export const CARD_HEIGHT = 2100;
export const STAR_TOTAL = 5;
export const CARD_TEMPLATE_FILENAME = 'catdex_template_v2.png';
export const CARD_TEMPLATE_PATH = `/cards/${CARD_TEMPLATE_FILENAME}?v=2`;

export type TextLayoutSlot = {
  x: number;
  y: number;
  width: number;
  height: number;
  fontSize: number;
  letterSpacing: number;
};

export type StarsLayoutSlot = {
  x: number;
  y: number;
  width: number;
  height: number;
  starSize: number;
  gap: number;
};

export type ImageLayoutSlot = {
  x: number;
  y: number;
  width: number;
  height: number;
};

export type CardLayout = {
  cardNumber: TextLayoutSlot;
  catName: TextLayoutSlot;
  stars: StarsLayoutSlot;
  species: TextLayoutSlot;
};

export type EditableLayoutKey = 'cardNumber' | 'catName' | 'stars' | 'species';

export const CARD_LAYOUT = {
  cardNumber: { x: 140, y: 191, width: 250, height: 90, fontSize: 54, letterSpacing: 2 },
  catName: { x: 424, y: 182, width: 640, height: 110, fontSize: 72, letterSpacing: 3 },
  stars: { x: 1081, y: 211, width: 300, height: 70, starSize: 42, gap: 8 },
  species: { x: 314, y: 1536, width: 870, height: 95, fontSize: 50, letterSpacing: 0 }
};

export const CARD_IMAGE_LAYOUT: ImageLayoutSlot = { x: 250, y: 390, width: 1000, height: 850 };
export const CAT_IMAGE_Y_OFFSET = 80;

export function cloneCardLayout(layout: CardLayout = CARD_LAYOUT): CardLayout {
  return {
    cardNumber: { ...layout.cardNumber },
    catName: { ...layout.catName },
    stars: { ...layout.stars },
    species: { ...layout.species },
  };
}

export function formatLayoutExport(layout: CardLayout): string {
  return `export const CARD_LAYOUT = {
  cardNumber: { x: ${layout.cardNumber.x}, y: ${layout.cardNumber.y}, width: ${layout.cardNumber.width}, height: ${layout.cardNumber.height}, fontSize: ${layout.cardNumber.fontSize}, letterSpacing: ${layout.cardNumber.letterSpacing} },
  catName: { x: ${layout.catName.x}, y: ${layout.catName.y}, width: ${layout.catName.width}, height: ${layout.catName.height}, fontSize: ${layout.catName.fontSize}, letterSpacing: ${layout.catName.letterSpacing} },
  stars: { x: ${layout.stars.x}, y: ${layout.stars.y}, width: ${layout.stars.width}, height: ${layout.stars.height}, starSize: ${layout.stars.starSize}, gap: ${layout.stars.gap} },
  species: { x: ${layout.species.x}, y: ${layout.species.y}, width: ${layout.species.width}, height: ${layout.species.height}, fontSize: ${layout.species.fontSize}, letterSpacing: ${layout.species.letterSpacing} }
};`;
}

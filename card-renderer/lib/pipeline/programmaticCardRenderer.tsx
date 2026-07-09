import { ImageResponse } from '@vercel/og';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { CARD_HEIGHT, CARD_WIDTH, STAR_TOTAL } from '../cardLayout';
import { StarRating } from '../StarRating';
import { fileToDataUrl } from './storage';
import type { CardTemplateLayout, CardTextJson } from './types';

type RenderProgrammaticCardInput = {
  templatePath: string;
  layout: CardTemplateLayout;
  artworkImageUrl: string;
  cardNumber: string;
  starCount: number;
  text: CardTextJson;
};

type TextSlotName = 'cardNumber' | 'catName' | 'species';

const textSlotConfig: Record<
  TextSlotName,
  {
    logLabel: string;
    minFontSize: number;
    innerPadding: number;
    widthFactor: number;
    lineHeight: number;
  }
> = {
  cardNumber: {
    logLabel: 'CATDEX_TEXT_LAYOUT_CARD_NUMBER',
    minFontSize: 24,
    innerPadding: 18,
    widthFactor: 0.62,
    lineHeight: 1.05,
  },
  catName: {
    logLabel: 'CATDEX_TEXT_LAYOUT_CAT_NAME',
    minFontSize: 34,
    innerPadding: 22,
    widthFactor: 0.61,
    lineHeight: 1.02,
  },
  species: {
    logLabel: 'CATDEX_TEXT_LAYOUT_SPECIES',
    minFontSize: 28,
    innerPadding: 28,
    widthFactor: 0.54,
    lineHeight: 1.05,
  },
};

function estimatedTextWidth(text: string, fontSize: number, letterSpacing: number, widthFactor: number): number {
  const normalized = text.trim();
  const weightedLength = Array.from(normalized).reduce((total, char) => {
    if (char === ' ') {
      return total + 0.35;
    }

    if (/[ilI.,'’]/.test(char)) {
      return total + 0.34;
    }

    if (/[MW@#]/.test(char)) {
      return total + 0.92;
    }

    if (/[A-ZÀ-Ý]/.test(char)) {
      return total + 0.68;
    }

    return total + widthFactor;
  }, 0);
  return weightedLength * fontSize + letterSpacing * Math.max(0, normalized.length - 1);
}

function ellipsizeToWidth(
  text: string,
  width: number,
  fontSize: number,
  letterSpacing: number,
  widthFactor: number,
): string {
  if (estimatedTextWidth(text, fontSize, letterSpacing, widthFactor) <= width) {
    return text;
  }

  const ellipsis = '…';
  let candidate = text.trim();
  while (candidate.length > 1) {
    candidate = candidate.slice(0, -1).trimEnd();
    const next = `${candidate}${ellipsis}`;
    if (estimatedTextWidth(next, fontSize, letterSpacing, widthFactor) <= width) {
      return next;
    }
  }

  return ellipsis;
}

function fitTextToSlot({
  slotName,
  slot,
  text,
}: {
  slotName: TextSlotName;
  slot: CardTemplateLayout['catName'];
  text: string;
}) {
  const config = textSlotConfig[slotName];
  const availableWidth = Math.max(1, slot.width - config.innerPadding * 2);
  let fontSize = slot.fontSize;
  while (
    fontSize > config.minFontSize &&
    estimatedTextWidth(text, fontSize, slot.letterSpacing, config.widthFactor) > availableWidth
  ) {
    fontSize -= 1;
  }

  const chosenFontSize = Math.max(config.minFontSize, fontSize);
  const finalText = ellipsizeToWidth(
    text,
    availableWidth,
    chosenFontSize,
    slot.letterSpacing,
    config.widthFactor,
  );
  const logPayload =
    slotName === 'cardNumber'
      ? {
          x: slot.x,
          y: slot.y,
          width: slot.width,
          height: slot.height,
          centerX: slot.x + slot.width / 2,
          centerY: slot.y + slot.height / 2,
          chosenFontSize,
          text: finalText,
        }
      : {
          x: slot.x,
          y: slot.y,
          width: slot.width,
          height: slot.height,
          chosenFontSize,
          color: slot.color,
          shadow: slot.shadowColor ?? 'default',
          text: finalText,
        };
  console.log(config.logLabel, JSON.stringify(logPayload));

  return {
    finalText,
    fontSize: chosenFontSize,
    innerPadding: config.innerPadding,
    lineHeight: config.lineHeight,
  };
}

function slotStyle(slot: { x: number; y: number; width: number; height: number }) {
  return {
    position: 'absolute' as const,
    left: slot.x,
    top: slot.y,
    width: slot.width,
    height: slot.height,
  };
}

function TextSlot({
  slot,
  slotName,
  text,
  shadow = true,
}: {
  slot: CardTemplateLayout['catName'];
  slotName: TextSlotName;
  text: string;
  shadow?: boolean;
}) {
  const fitted = fitTextToSlot({ slotName, slot, text });
  const shadowColor = slot.shadowColor ?? 'rgba(0,0,0,0.55)';
  const textShadow = shadow
    ? `-2px 0 ${shadowColor}, 2px 0 ${shadowColor}, 0 -2px ${shadowColor}, 0 2px ${shadowColor}, 0 4px 10px ${shadowColor}`
    : 'none';

  return (
    <div
      style={{
        ...slotStyle(slot),
        display: 'flex',
        alignItems: 'center',
        justifyContent:
          slotName === 'cardNumber' || slotName === 'catName'
            ? 'center'
            : slot.align === 'left'
              ? 'flex-start'
              : slot.align === 'right'
                ? 'flex-end'
                : 'center',
        overflow: 'hidden',
        paddingLeft: fitted.innerPadding,
        paddingRight: fitted.innerPadding,
        whiteSpace: 'nowrap',
        textDecoration: 'none',
        borderBottom: 'none',
        color: slot.color,
        fontFamily: slot.fontFamily,
        fontSize: fitted.fontSize,
        fontWeight: 700,
        letterSpacing: slot.letterSpacing,
        lineHeight: fitted.lineHeight,
        textAlign: slotName === 'cardNumber' || slotName === 'catName' ? 'center' : slot.align,
        textShadow,
      }}
    >
      <span
        style={{
          display: 'block',
          maxWidth: '100%',
          overflow: 'hidden',
          textOverflow: 'ellipsis',
          whiteSpace: 'nowrap',
          textDecoration: 'none',
          borderBottom: 'none',
        }}
      >
        {fitted.finalText}
      </span>
    </div>
  );
}

function fittedStarsLayout(stars: CardTemplateLayout['stars'], filled: number) {
  let starSize = stars.starSize;
  let gap = stars.gap;
  let totalWidth = STAR_TOTAL * starSize + (STAR_TOTAL - 1) * gap;

  while (starSize > 22 && totalWidth > stars.width) {
    starSize -= 1;
    totalWidth = STAR_TOTAL * starSize + (STAR_TOTAL - 1) * gap;
  }

  if (totalWidth > stars.width) {
    gap = Math.max(4, Math.floor((stars.width - STAR_TOTAL * starSize) / (STAR_TOTAL - 1)));
    totalWidth = STAR_TOTAL * starSize + (STAR_TOTAL - 1) * gap;
  }

  const startX = stars.x + (stars.width - totalWidth) / 2;
  const startY = stars.y + (stars.height - starSize) / 2;
  const layout = {
    x: stars.x,
    y: stars.y,
    width: stars.width,
    height: stars.height,
    startX,
    startY,
    starSize,
    gap,
    filled,
    maxStars: STAR_TOTAL,
  };
  console.log('CATDEX_TEXT_LAYOUT_STARS', JSON.stringify(layout));

  return { starSize, gap };
}

function DebugBox({ slot }: { slot: { x: number; y: number; width: number; height: number } }) {
  return (
    <div
      style={{
        ...slotStyle(slot),
        border: '2px solid rgba(255,0,0,0.9)',
        boxSizing: 'border-box',
        pointerEvents: 'none',
      }}
    />
  );
}

async function loadFont(fontName: string): Promise<Buffer | undefined> {
  const fontMap: Record<string, string> = {
    CinzelDecorative: 'public/fonts/CinzelDecorative-Bold.ttf',
    Fredoka: 'public/fonts/Fredoka-Bold.ttf',
  };
  const fontPath = fontMap[fontName];
  if (!fontPath) {
    return undefined;
  }

  try {
    return await readFile(path.join(process.cwd(), fontPath));
  } catch {
    return undefined;
  }
}

export async function renderProgrammaticCard(input: RenderProgrammaticCardInput): Promise<ImageResponse> {
  const templateDataUrl = await fileToDataUrl(input.templatePath);
  const showLayoutDebugBoxes = process.env.SHOW_LAYOUT_DEBUG_BOXES === 'true';
  console.log('CATDEX_TEXT_LAYOUT_VERSION', 'v6_box_centered_metadata');
  console.log('CATDEX_RENDER_ARTWORK_ALPHA_PRESERVED', true);
  console.log('CATDEX_LAYOUT_DEBUG_BOXES_ENABLED', showLayoutDebugBoxes);
  const fittedStars = fittedStarsLayout(input.layout.stars, input.starCount);
  console.log('CATDEX_SPECIES_TEXT_RENDERED', false);
  console.log(
    'CATDEX_ARTWORK_LAYOUT',
    JSON.stringify({
      x: input.layout.artwork.x,
      y: input.layout.artwork.y,
      width: input.layout.artwork.width,
      height: input.layout.artwork.height,
      offsetY: input.layout.artwork.offsetY,
    }),
  );
  const fonts = (
    await Promise.all(
      Array.from(
        new Set([
          input.layout.cardNumber.fontFamily,
          input.layout.catName.fontFamily,
          input.layout.species.fontFamily,
        ]),
      ).map(async (fontFamily) => {
        const data = await loadFont(fontFamily);
        return data
          ? {
              name: fontFamily,
              data,
              weight: 700 as const,
              style: 'normal' as const,
            }
          : undefined;
      }),
    )
  ).filter((font): font is { name: string; data: Buffer; weight: 700; style: 'normal' } => Boolean(font));

  return new ImageResponse(
    (
      <div
        style={{
          position: 'relative',
          display: 'flex',
          width: CARD_WIDTH,
          height: CARD_HEIGHT,
          overflow: 'hidden',
          backgroundColor: '#172033',
        }}
      >
        <img
          src={templateDataUrl}
          alt=""
          width={CARD_WIDTH}
          height={CARD_HEIGHT}
          style={{ position: 'absolute', inset: 0, width: CARD_WIDTH, height: CARD_HEIGHT }}
        />

        {input.artworkImageUrl ? (
          <div
            style={{
              ...slotStyle({
                ...input.layout.artwork,
                y: input.layout.artwork.y + input.layout.artwork.offsetY,
              }),
              display: 'flex',
              alignItems:
                input.layout.artwork.anchor === 'top'
                  ? 'flex-start'
                  : input.layout.artwork.anchor === 'bottom'
                    ? 'flex-end'
                    : 'center',
              justifyContent: 'center',
              overflow: 'hidden',
            }}
          >
            <img
              src={input.artworkImageUrl}
              alt=""
              style={{
                width: input.layout.artwork.width,
                height: input.layout.artwork.height,
                objectFit: input.layout.artwork.fit,
                objectPosition: input.layout.artwork.anchor,
              }}
            />
          </div>
        ) : null}

        <TextSlot slot={input.layout.cardNumber} slotName="cardNumber" text={input.cardNumber} />
        <TextSlot slot={input.layout.catName} slotName="catName" text={input.text.cardTitle.toUpperCase()} />

        <div
          style={{
            ...slotStyle(input.layout.stars),
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            overflow: 'hidden',
          }}
        >
          <StarRating active={input.starCount} starSize={fittedStars.starSize} gap={fittedStars.gap} />
        </div>

        {showLayoutDebugBoxes ? (
          <>
            <DebugBox slot={input.layout.catName} />
            <DebugBox slot={input.layout.cardNumber} />
            <DebugBox slot={input.layout.stars} />
            <DebugBox
              slot={{
                ...input.layout.artwork,
                y: input.layout.artwork.y + input.layout.artwork.offsetY,
              }}
            />
          </>
        ) : null}
      </div>
    ),
    {
      width: CARD_WIDTH,
      height: CARD_HEIGHT,
      fonts: fonts.length > 0 ? fonts : undefined,
      headers: {
        'cache-control': 'public, max-age=31536000, immutable',
      },
    },
  );
}

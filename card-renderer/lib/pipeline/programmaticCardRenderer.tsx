import { ImageResponse } from '@vercel/og';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { CARD_HEIGHT, CARD_WIDTH } from '../cardLayout';
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

const minFontSize = 28;

function fittedFontSize(text: string, fontSize: number, width: number, letterSpacing: number): number {
  const estimated = text.length * fontSize * 0.58 + letterSpacing * Math.max(0, text.length - 1);
  return Math.max(minFontSize, Math.min(fontSize, Math.floor((fontSize * width) / Math.max(width, estimated))));
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

function TextSlot({ slot, text, shadow = true }: { slot: CardTemplateLayout['catName']; text: string; shadow?: boolean }) {
  const fontSize = fittedFontSize(text, slot.fontSize, slot.width, slot.letterSpacing);

  return (
    <div
      style={{
        ...slotStyle(slot),
        display: 'flex',
        alignItems: 'center',
        justifyContent: slot.align === 'left' ? 'flex-start' : slot.align === 'right' ? 'flex-end' : 'center',
        overflow: 'hidden',
        whiteSpace: 'nowrap',
        textDecoration: 'none',
        borderBottom: 'none',
        color: slot.color,
        fontFamily: slot.fontFamily,
        fontSize,
        fontWeight: 700,
        letterSpacing: slot.letterSpacing,
        lineHeight: 1,
        textAlign: slot.align,
        textShadow: shadow ? '0 4px 8px rgba(0,0,0,0.45)' : '0 2px 0 rgba(255,255,255,0.65)',
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
        {text}
      </span>
    </div>
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
  console.log('CATDEX_RENDER_ARTWORK_ALPHA_PRESERVED', true);
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

        <TextSlot slot={input.layout.cardNumber} text={input.cardNumber} />
        <TextSlot slot={input.layout.catName} text={input.text.cardTitle.toUpperCase()} />
        <TextSlot slot={input.layout.species} text={input.text.speciesLine} shadow={false} />

        <div
          style={{
            ...slotStyle(input.layout.stars),
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'flex-start',
            overflow: 'hidden',
          }}
        >
          <StarRating active={input.starCount} starSize={input.layout.stars.starSize} gap={input.layout.stars.gap} />
        </div>
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

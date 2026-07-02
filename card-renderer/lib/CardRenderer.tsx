import type { PointerEvent } from 'react';
import {
  CARD_HEIGHT,
  CARD_IMAGE_LAYOUT,
  CARD_LAYOUT,
  CARD_WIDTH,
  CAT_IMAGE_Y_OFFSET,
  type CardLayout,
  type EditableLayoutKey,
  type TextLayoutSlot,
} from './cardLayout';
import { StarRating } from './StarRating';

export type CardRenderData = {
  cardNumber: string;
  catName: string;
  species: string;
  starCount: number;
  catImageUrl?: string;
};

type CardRendererProps = {
  data: CardRenderData;
  templateUrl: string;
  layout?: CardLayout;
  showSafeBoxes?: boolean;
  interactive?: boolean;
  onDragStart?: (key: EditableLayoutKey, event: PointerEvent<HTMLDivElement>) => void;
};

const safeBoxColors: Record<EditableLayoutKey, string> = {
  cardNumber: 'rgba(255, 68, 68, 0.88)',
  catName: 'rgba(61, 132, 255, 0.88)',
  stars: 'rgba(255, 68, 68, 0.88)',
  species: 'rgba(61, 132, 255, 0.88)',
};
const cardTextFontFamily = '"CinzelDecorative", "Fredoka", "Baloo 2", "Nunito", "Sora", system-ui, sans-serif';
const minFittedFontSize = 28;

function positionStyle(slot: { x: number; y: number; width: number; height: number }) {
  return {
    position: 'absolute' as const,
    left: slot.x,
    top: slot.y,
    width: slot.width,
    height: slot.height,
  };
}

function FittedText({
  children,
  slot,
  variant,
  interactive,
  showSafeBoxes,
  onPointerDown,
}: {
  children: string;
  slot: TextLayoutSlot;
  variant: 'cardNumber' | 'catName' | 'species';
  interactive?: boolean;
  showSafeBoxes?: boolean;
  onPointerDown?: (event: PointerEvent<HTMLDivElement>) => void;
}) {
  const isSpecies = variant === 'species';
  const text = variant === 'catName' ? children.toUpperCase() : children;
  const estimatedTextWidth = text.length * slot.fontSize * (isSpecies ? 0.52 : 0.58) + slot.letterSpacing * Math.max(0, text.length - 1);
  const fittedFontSize = Math.max(
    minFittedFontSize,
    Math.min(slot.fontSize, Math.floor((slot.fontSize * slot.width) / Math.max(slot.width, estimatedTextWidth))),
  );

  return (
    <div
      onPointerDown={onPointerDown}
      style={{
        ...positionStyle(slot),
        display: 'flex',
        alignItems: 'center',
        justifyContent: variant === 'cardNumber' ? 'flex-start' : 'center',
        overflow: 'hidden',
        whiteSpace: 'nowrap',
        textDecoration: 'none',
        borderBottom: 'none',
        color: isSpecies ? '#172033' : '#ffffff',
        fontFamily: cardTextFontFamily,
        fontSize: fittedFontSize,
        fontWeight: 700,
        letterSpacing: slot.letterSpacing,
        lineHeight: 1,
        textAlign: variant === 'cardNumber' ? 'left' : 'center',
        textTransform: variant === 'catName' ? 'uppercase' : 'none',
        textShadow: isSpecies ? '0 2px 0 rgba(255,255,255,0.65)' : '0 4px 8px rgba(0,0,0,0.45)',
        outline: showSafeBoxes ? `4px solid ${safeBoxColors[variant]}` : 'none',
        backgroundColor: showSafeBoxes ? 'rgba(255,255,255,0.05)' : 'transparent',
        cursor: interactive ? 'move' : 'default',
        userSelect: 'none',
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

export function CardRenderer({
  data,
  templateUrl,
  layout = CARD_LAYOUT,
  showSafeBoxes = false,
  interactive = false,
  onDragStart,
}: CardRendererProps) {
  return (
    <div
      style={{
        position: 'relative',
        display: 'flex',
        width: CARD_WIDTH,
        height: CARD_HEIGHT,
        fontFamily: cardTextFontFamily,
        overflow: 'hidden',
        backgroundColor: '#172033',
      }}
    >
      <img
        src={templateUrl}
        alt=""
        width={CARD_WIDTH}
        height={CARD_HEIGHT}
        draggable={false}
        style={{
          position: 'absolute',
          inset: 0,
          width: CARD_WIDTH,
          height: CARD_HEIGHT,
        }}
      />

      {data.catImageUrl ? (
        <div
          style={{
            ...positionStyle({ ...CARD_IMAGE_LAYOUT, y: CARD_IMAGE_LAYOUT.y + CAT_IMAGE_Y_OFFSET }),
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            overflow: 'hidden',
          }}
        >
          <img
            src={data.catImageUrl}
            alt=""
            draggable={false}
            style={{
              width: CARD_IMAGE_LAYOUT.width,
              height: CARD_IMAGE_LAYOUT.height,
              objectFit: 'contain',
              objectPosition: 'center',
            }}
          />
        </div>
      ) : null}

      <FittedText
        slot={layout.cardNumber}
        variant="cardNumber"
        interactive={interactive}
        showSafeBoxes={showSafeBoxes}
        onPointerDown={onDragStart ? (event) => onDragStart('cardNumber', event) : undefined}
      >
        {data.cardNumber}
      </FittedText>

      <FittedText
        slot={layout.catName}
        variant="catName"
        interactive={interactive}
        showSafeBoxes={showSafeBoxes}
        onPointerDown={onDragStart ? (event) => onDragStart('catName', event) : undefined}
      >
        {data.catName}
      </FittedText>

      <FittedText
        slot={layout.species}
        variant="species"
        interactive={interactive}
        showSafeBoxes={showSafeBoxes}
        onPointerDown={onDragStart ? (event) => onDragStart('species', event) : undefined}
      >
        {data.species}
      </FittedText>

      <div
        onPointerDown={onDragStart ? (event) => onDragStart('stars', event) : undefined}
        style={{
          ...positionStyle(layout.stars),
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'flex-start',
          overflow: 'hidden',
          outline: showSafeBoxes ? `4px solid ${safeBoxColors.stars}` : 'none',
          backgroundColor: showSafeBoxes ? 'rgba(255,255,255,0.05)' : 'transparent',
          cursor: interactive ? 'move' : 'default',
          userSelect: 'none',
        }}
      >
        <StarRating active={data.starCount} starSize={layout.stars.starSize} gap={layout.stars.gap} />
      </div>
    </div>
  );
}

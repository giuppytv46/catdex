import React from 'react';
import { STAR_TOTAL } from './cardLayout';

type StarRatingProps = {
  active: number;
  starSize: number;
  gap: number;
};

export function StarRating({ active, starSize, gap }: StarRatingProps) {
  return (
    <div
      style={{
        display: 'flex',
        gap,
        alignItems: 'center',
        justifyContent: 'flex-start',
      }}
    >
      {Array.from({ length: STAR_TOTAL }).map((_, index) => {
        const filled = index < active;

        return (
          <svg
            key={index}
            width={starSize}
            height={starSize}
            viewBox="0 0 100 100"
            style={{ display: 'flex', flexShrink: 0 }}
          >
            <path
              d="M50 6 L61.8 36.3 L94 38.2 L69 58.9 L77.1 90 L50 72.2 L22.9 90 L31 58.9 L6 38.2 L38.2 36.3 Z"
              fill={filled ? '#F6B93B' : 'rgba(246,185,59,0.18)'}
              stroke={filled ? '#9A6614' : 'rgba(246,185,59,0.65)'}
              strokeWidth="3"
              strokeLinejoin="round"
            />
          </svg>
        );
      })}
    </div>
  );
}

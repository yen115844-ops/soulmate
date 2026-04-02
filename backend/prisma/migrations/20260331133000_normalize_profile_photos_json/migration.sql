-- Normalize profiles.photos: legacy JSON array of URL strings -> array of objects { url, width?, height?, aspectRatio? }
-- Idempotent for rows already using object elements (rebuilds consistent shape).

UPDATE profiles AS p
SET photos = COALESCE(
  (
    SELECT jsonb_agg(normalized ORDER BY ordinality)
    FROM (
      SELECT
        t.ordinality,
        CASE
          WHEN jsonb_typeof(t.value) = 'string' THEN
            jsonb_build_object('url', t.value #>> '{}')
          WHEN jsonb_typeof(t.value) = 'object' AND (t.value ? 'url') THEN
            jsonb_strip_nulls(
              jsonb_build_object(
                'url', t.value->>'url',
                'width', CASE
                  WHEN jsonb_typeof(t.value->'width') = 'number'
                    AND (t.value->>'width')::numeric > 0
                  THEN t.value->'width'
                END,
                'height', CASE
                  WHEN jsonb_typeof(t.value->'height') = 'number'
                    AND (t.value->>'height')::numeric > 0
                  THEN t.value->'height'
                END,
                'aspectRatio', CASE
                  WHEN jsonb_typeof(t.value->'aspectRatio') = 'number'
                    AND (t.value->>'aspectRatio')::numeric > 0
                  THEN t.value->'aspectRatio'
                END
              )
            )
          ELSE NULL
        END AS normalized
      FROM jsonb_array_elements(p.photos) WITH ORDINALITY AS t(value, ordinality)
    ) sub
    WHERE normalized IS NOT NULL
      AND (normalized->>'url') IS NOT NULL
      AND trim(BOTH FROM normalized->>'url') <> ''
  ),
  '[]'::jsonb
)
WHERE p.photos IS NOT NULL
  AND jsonb_typeof(p.photos) = 'array'
  AND jsonb_array_length(p.photos) > 0;

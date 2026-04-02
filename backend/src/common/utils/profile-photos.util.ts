/**
 * profile.photos JSON shape: legacy string URL or { url, width?, height?, aspectRatio? }.
 * Prefer persisting without aspectRatio (derived on read); width/height from server upload when known.
 */

export type ProfilePhotoStored = {
  url: string;
  width?: number;
  height?: number;
  aspectRatio?: number;
};

export type ProfilePhotoApiItem = {
  url: string;
  width?: number;
  height?: number;
  aspectRatio?: number;
};

/** Remove aspectRatio before writing to DB (optional client field; API recomputes). */
export function stripPhotosForPersistence(
  photos: ProfilePhotoStored[],
): ProfilePhotoStored[] {
  return photos.map(stripOneForStore);
}

function stripOneForStore(p: ProfilePhotoStored): ProfilePhotoStored {
  const { url, width, height } = p;
  const o: ProfilePhotoStored = { url };
  if (width !== undefined) o.width = width;
  if (height !== undefined) o.height = height;
  return o;
}

export function coerceProfilePhotosToStored(raw: unknown): ProfilePhotoStored[] {
  if (!Array.isArray(raw)) return [];
  const out: ProfilePhotoStored[] = [];
  for (const entry of raw) {
    if (typeof entry === 'string') {
      const url = entry.trim();
      if (url) out.push({ url });
      continue;
    }
    if (entry && typeof entry === 'object' && 'url' in entry) {
      const url = String((entry as { url?: unknown }).url ?? '').trim();
      if (!url) continue;
      const wRaw = (entry as { width?: unknown }).width;
      const hRaw = (entry as { height?: unknown }).height;
      const arRaw = (entry as { aspectRatio?: unknown }).aspectRatio;
      const width =
        typeof wRaw === 'number' && Number.isFinite(wRaw)
          ? Math.max(1, Math.round(wRaw))
          : undefined;
      const height =
        typeof hRaw === 'number' && Number.isFinite(hRaw)
          ? Math.max(1, Math.round(hRaw))
          : undefined;
      let aspectRatio =
        typeof arRaw === 'number' && Number.isFinite(arRaw) && arRaw > 0
          ? Number(arRaw)
          : undefined;
      if (
        aspectRatio === undefined &&
        width !== undefined &&
        height !== undefined &&
        height > 0
      ) {
        aspectRatio = Number((width / height).toFixed(4));
      }
      const item: ProfilePhotoStored = { url };
      if (width !== undefined) item.width = width;
      if (height !== undefined) item.height = height;
      if (aspectRatio !== undefined) item.aspectRatio = aspectRatio;
      out.push(item);
    }
  }
  return out;
}

export function normalizeProfilePhotosForApi(raw: unknown): ProfilePhotoApiItem[] {
  return coerceProfilePhotosToStored(raw).map((item) => {
    const { url, width, height, aspectRatio: storedAr } = item;
    const out: ProfilePhotoApiItem = { url };
    if (width !== undefined) out.width = width;
    if (height !== undefined) out.height = height;
    let aspectRatio = storedAr;
    if (
      aspectRatio === undefined &&
      width !== undefined &&
      height !== undefined &&
      height > 0
    ) {
      aspectRatio = Number((width / height).toFixed(4));
    }
    if (aspectRatio !== undefined) out.aspectRatio = aspectRatio;
    return out;
  });
}

/**
 * Merge or append photos by url; later additions override width/height for same url.
 */
export function upsertProfilePhotos(
  existing: unknown,
  additions: ProfilePhotoStored[],
): ProfilePhotoStored[] {
  const list = [...coerceProfilePhotosToStored(existing)];
  for (const add of additions) {
    const url = add.url.trim();
    if (!url) continue;
    const idx = list.findIndex((p) => p.url === url);
    if (idx === -1) {
      list.push(
        stripOneForStore({ url, width: add.width, height: add.height }),
      );
    } else {
      const prev = list[idx];
      list[idx] = stripOneForStore({
        url,
        width: add.width != null ? add.width : prev.width,
        height: add.height != null ? add.height : prev.height,
      });
    }
  }
  return list;
}

export function removeProfilePhotosByUrls(
  existing: unknown,
  urlsToRemove: string[],
): ProfilePhotoStored[] {
  const removeSet = new Set(urlsToRemove.map((u) => u.trim()).filter(Boolean));
  return coerceProfilePhotosToStored(existing).filter((p) => !removeSet.has(p.url));
}

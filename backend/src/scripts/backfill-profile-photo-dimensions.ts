import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import sharp from 'sharp';
import { PrismaClient } from '../generated/prisma/client';
import {
  coerceProfilePhotosToStored,
  stripPhotosForPersistence,
  upsertProfilePhotos,
  type ProfilePhotoStored,
} from '../common/utils/profile-photos.util';
import { basename, join } from 'path';
import { existsSync, readFileSync } from 'fs';

type ProbeResult = { width?: number; height?: number };

const adapter = new PrismaPg({
  connectionString: process.env.DATABASE_URL,
});
const prisma = new PrismaClient({ adapter });

function isMissingProfilesTableError(e: unknown): boolean {
  if (!e || typeof e !== 'object') return false;
  const err = e as { code?: string; message?: string };
  return (
    err.code === 'P2021' ||
    (typeof err.message === 'string' &&
      err.message.toLowerCase().includes('table `public.profiles` does not exist'))
  );
}

function isHttpUrl(url: string): boolean {
  return /^https?:\/\//i.test(url.trim());
}

function extractUploadFilename(url: string): string | null {
  const trimmed = url.trim();
  const marker = '/upload/files/';
  const idx = trimmed.indexOf(marker);
  if (idx === -1) return null;
  const raw = trimmed.slice(idx + marker.length).split('?')[0].split('#')[0];
  const base = basename(raw);
  const sanitized = base.replace(/[^a-zA-Z0-9._-]/g, '');
  return sanitized || null;
}

async function fetchBufferLimited(
  url: string,
  maxBytes: number,
  timeoutMs: number,
): Promise<Buffer> {
  const controller = new AbortController();
  const t = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(url, { signal: controller.signal });
    if (!res.ok) {
      throw new Error(`Fetch failed ${res.status} ${res.statusText}`);
    }
    const arr = new Uint8Array(await res.arrayBuffer());
    if (arr.byteLength > maxBytes) {
      throw new Error(`Image too large (${arr.byteLength} bytes)`);
    }
    return Buffer.from(arr);
  } finally {
    clearTimeout(t);
  }
}

async function probeImageFromBuffer(buf: Buffer): Promise<ProbeResult> {
  const meta = await sharp(buf).metadata();
  const width = meta.width && meta.width > 0 ? meta.width : undefined;
  const height = meta.height && meta.height > 0 ? meta.height : undefined;
  return { width, height };
}

async function probePhoto(url: string): Promise<ProbeResult> {
  const trimmed = url.trim();
  if (!trimmed) return {};

  // Local upload: /api/upload/files/{name} or /upload/files/{name}
  const filename = extractUploadFilename(trimmed);
  if (filename) {
    const uploadPath = join(process.cwd(), 'uploads', filename);
    if (existsSync(uploadPath)) {
      const buf = readFileSync(uploadPath);
      return probeImageFromBuffer(buf);
    }
    return {};
  }

  // External URL
  if (isHttpUrl(trimmed)) {
    const buf = await fetchBufferLimited(trimmed, 6 * 1024 * 1024, 15_000);
    return probeImageFromBuffer(buf);
  }

  return {};
}

function needsProbe(p: ProfilePhotoStored): boolean {
  return p.width === undefined || p.height === undefined;
}

async function main() {
  const dryRun = process.env.DRY_RUN === '1' || process.env.DRY_RUN === 'true';
  const limit = process.env.LIMIT ? Number(process.env.LIMIT) : undefined;
  const concurrency = process.env.CONCURRENCY
    ? Math.max(1, Math.min(32, Number(process.env.CONCURRENCY)))
    : 6;

  // Preflight: give clear guidance when DATABASE_URL points to a DB without schema.
  const regclassRows = (await prisma.$queryRawUnsafe(
    "SELECT to_regclass('public.profiles')::text AS regclass",
  )) as Array<{ regclass: string | null }>;
  const hasProfilesTable = Array.isArray(regclassRows) && !!regclassRows[0]?.regclass;
  if (!hasProfilesTable) {
    // eslint-disable-next-line no-console
    console.error(
      [
        'Backfill stopped: table public.profiles was not found in current DATABASE_URL.',
        'Run migrations on this database, then run photos:backfill again.',
        'Suggested: npm run prisma:migrate:prod (or npm run prisma:migrate for local dev).',
      ].join('\n'),
    );
    process.exitCode = 1;
    return;
  }

  const profiles = await prisma.profile.findMany({
    select: { id: true, userId: true, photos: true },
  });

  let processed = 0;
  let updated = 0;
  let probed = 0;
  let errors = 0;

  const probeCache = new Map<string, ProbeResult>();

  for (const row of profiles) {
    if (limit !== undefined && processed >= limit) break;
    processed += 1;

    const current = coerceProfilePhotosToStored(row.photos);
    const missing = current.filter(needsProbe);
    if (missing.length === 0) continue;

    // Concurrency-limited probing for this profile
    const queue = [...missing];
    const additions: ProfilePhotoStored[] = [];

    const workers = Array.from({ length: concurrency }).map(async () => {
      while (queue.length > 0) {
        const item = queue.pop();
        if (!item) break;
        const url = item.url.trim();
        if (!url) continue;

        try {
          const cached = probeCache.get(url);
          const dims = cached ?? (await probePhoto(url));
          if (!cached) probeCache.set(url, dims);
          probed += 1;

          if (dims.width && dims.height) {
            additions.push({ url, width: dims.width, height: dims.height });
          }
        } catch {
          errors += 1;
        }
      }
    });

    await Promise.all(workers);

    if (additions.length === 0) continue;

    const next = stripPhotosForPersistence(upsertProfilePhotos(current, additions));

    if (!dryRun) {
      await prisma.profile.update({
        where: { id: row.id },
        data: { photos: next as object[] },
      });
    }
    updated += 1;
  }

  // eslint-disable-next-line no-console
  console.log(
    JSON.stringify(
      { dryRun, processed, updated, probed, errors, cacheSize: probeCache.size },
      null,
      2,
    ),
  );
}

main()
  .catch((e) => {
    if (isMissingProfilesTableError(e)) {
      // eslint-disable-next-line no-console
      console.error(
        [
          'Backfill stopped: table public.profiles was not found in current DATABASE_URL.',
          'Run migrations on this database, then run photos:backfill again.',
          'Suggested: npm run prisma:migrate:prod (or npm run prisma:migrate for local dev).',
        ].join('\n'),
      );
      process.exitCode = 1;
      return;
    }
    // eslint-disable-next-line no-console
    console.error(e);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });


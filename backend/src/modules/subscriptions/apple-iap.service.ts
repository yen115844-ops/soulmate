import { Injectable } from '@nestjs/common';
import * as jose from 'jose';

const APPLE_SERVER_API_PRODUCTION = 'https://api.storekit.itunes.apple.com';
const APPLE_SERVER_API_SANDBOX = 'https://api.storekit-sandbox.itunes.apple.com';
const APPLE_LEGACY_VERIFY_PRODUCTION = 'https://buy.itunes.apple.com/verifyReceipt';
const APPLE_LEGACY_VERIFY_SANDBOX = 'https://sandbox.itunes.apple.com/verifyReceipt';

/** Transaction info decoded from Apple's signedTransactionInfo (JWS payload) */
export interface AppleTransactionInfoDecoded {
  transactionId: string;
  originalTransactionId: string;
  productId: string;
  expiresDate?: number; // ms
  purchaseDate?: number;
}

@Injectable()
export class AppleIapService {
  /**
   * Get private key PEM from env (content only, no file).
   * Supports literal \n in .env: APPLE_IAP_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nMIGT..."
   */
  private getPrivateKeyPem(): string | null {
    const raw = process.env.APPLE_IAP_PRIVATE_KEY;
    if (!raw || typeof raw !== 'string') return null;
    return raw.replace(/\\n/g, '\n').trim();
  }

  private hasServerApiConfig(): boolean {
    return !!(
      process.env.APPLE_IAP_KEY_ID &&
      process.env.APPLE_IAP_ISSUER_ID &&
      this.getPrivateKeyPem() &&
      process.env.APPLE_BUNDLE_ID
    );
  }

  /**
   * Generate JWT for App Store Server API (signed with private key from .env).
   * Uses key content from APPLE_IAP_PRIVATE_KEY (PEM string, use \n for newlines in .env).
   */
  async generateToken(): Promise<string> {
    const keyId = process.env.APPLE_IAP_KEY_ID;
    const issuerId = process.env.APPLE_IAP_ISSUER_ID;
    const bundleId = process.env.APPLE_BUNDLE_ID;
    const pem = this.getPrivateKeyPem();
    if (!keyId || !issuerId || !bundleId || !pem) {
      throw new Error('Missing APPLE_IAP_KEY_ID, APPLE_IAP_ISSUER_ID, APPLE_BUNDLE_ID or APPLE_IAP_PRIVATE_KEY');
    }

    const privateKey = await jose.importPKCS8(pem, 'ES256');
    const now = Math.floor(Date.now() / 1000);
    const token = await new jose.SignJWT({ bid: bundleId })
      .setProtectedHeader({ alg: 'ES256', kid: keyId, typ: 'JWT' })
      .setIssuer(issuerId)
      .setIssuedAt(now)
      .setExpirationTime(now + 3600)
      .setAudience('appstoreconnect-v1')
      .sign(privateKey);
    return token;
  }

  /**
   * Get transaction info via App Store Server API (uses key from .env).
   * Tries production first, then sandbox.
   */
  async getTransactionInfo(transactionId: string): Promise<{
    ok: true;
    info: AppleTransactionInfoDecoded;
    environment: 'Production' | 'Sandbox';
  } | { ok: false; error: string }> {
    if (!this.hasServerApiConfig()) {
      return { ok: false, error: 'Apple IAP key not configured (APPLE_IAP_* in .env)' };
    }

    const token = await this.generateToken();
    const authHeader = { Authorization: `Bearer ${token}` };

    for (const env of ['Production', 'Sandbox'] as const) {
      const baseUrl = env === 'Production' ? APPLE_SERVER_API_PRODUCTION : APPLE_SERVER_API_SANDBOX;
      const url = `${baseUrl}/inApps/v1/transactions/${transactionId}`;
      try {
        const res = await fetch(url, { headers: authHeader });
        if (res.status === 404) continue; // try next env
        if (!res.ok) {
          const text = await res.text();
          if (env === 'Sandbox') return { ok: false, error: `Apple API: ${res.status} ${text}` };
          continue;
        }
        const data = (await res.json()) as { signedTransactionInfo?: string };
        const signed = data?.signedTransactionInfo;
        if (!signed) return { ok: false, error: 'No signedTransactionInfo in response' };

        const info = this.decodeSignedTransactionInfo(signed);
        if (!info) return { ok: false, error: 'Failed to decode signedTransactionInfo' };

        return { ok: true, info, environment: env };
      } catch (e) {
        if (env === 'Sandbox') return { ok: false, error: (e as Error).message };
      }
    }
    return { ok: false, error: 'Transaction not found in Production or Sandbox' };
  }

  /** Decode JWS payload (middle part) without full signature verification for simplicity. */
  private decodeSignedTransactionInfo(signed: string): AppleTransactionInfoDecoded | null {
    try {
      const parts = signed.split('.');
      if (parts.length !== 3) return null;
      const payload = parts[1];
      const decoded = JSON.parse(
        Buffer.from(payload, 'base64url').toString('utf8'),
      ) as Record<string, unknown>;
      return {
        transactionId: String(decoded.transactionId ?? ''),
        originalTransactionId: String(decoded.originalTransactionId ?? ''),
        productId: String(decoded.productId ?? ''),
        expiresDate: typeof decoded.expiresDate === 'number' ? decoded.expiresDate : undefined,
        purchaseDate: typeof decoded.purchaseDate === 'number' ? decoded.purchaseDate : undefined,
      };
    } catch {
      return null;
    }
  }

  /**
   * Legacy verifyReceipt (receipt-data + shared secret). No .p8 key needed.
   * Tries production then sandbox.
   */
  async verifyReceiptLegacy(receiptData: string): Promise<{
    isValid: boolean;
    transactionId?: string;
    originalTransactionId?: string;
    expiresAt?: Date;
    error?: string;
  }> {
    const password = process.env.APPLE_SHARED_SECRET;
    if (!password) {
      return { isValid: false, error: 'APPLE_SHARED_SECRET not set' };
    }

    const urls = [
      process.env.APPLE_VERIFY_RECEIPT_URL || APPLE_LEGACY_VERIFY_PRODUCTION,
      process.env.APPLE_VERIFY_RECEIPT_SANDBOX_URL || APPLE_LEGACY_VERIFY_SANDBOX,
    ];

    for (const url of urls) {
      try {
        const res = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ 'receipt-data': receiptData, password }),
        });
        const data = (await res.json()) as {
          status?: number;
          latest_receipt_info?: Array<{
            transaction_id?: string;
            original_transaction_id?: string;
            expires_date_ms?: string;
            product_id?: string;
          }>;
          receipt?: { in_app?: Array<{ transaction_id?: string; original_transaction_id?: string }> };
        };

        if (data.status === 0) {
          const latest = data.latest_receipt_info?.[0] ?? data.receipt?.in_app?.[0];
          const txId = latest?.transaction_id ?? latest?.original_transaction_id;
          const origId = latest?.original_transaction_id ?? latest?.transaction_id;
          let expiresAt: Date | undefined;
          const expMs = data.latest_receipt_info?.[0]?.expires_date_ms;
          if (expMs) expiresAt = new Date(Number(expMs));

          return {
            isValid: true,
            transactionId: txId,
            originalTransactionId: origId,
            expiresAt,
          };
        }
        if (data.status === 21007) continue; // sandbox receipt sent to prod -> try sandbox
        if (data.status === 21008) continue; // prod receipt sent to sandbox -> try prod
      } catch (e) {
        // try next url
      }
    }
    return { isValid: false, error: 'Receipt verification failed' };
  }
}

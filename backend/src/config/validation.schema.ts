import * as Joi from 'joi';

export const validationSchema = Joi.object({
  // App
  NODE_ENV: Joi.string()
    .valid('development', 'production', 'test', 'staging')
    .default('development'),
  PORT: Joi.number().default(3000),
  API_PREFIX: Joi.string().default('api'),
  API_VERSION: Joi.string().default('v1'),
  CORS_ORIGIN: Joi.string().default('*'),

  // Database
  DATABASE_URL: Joi.string().required(),
  DB_HOST: Joi.string().default('localhost'),
  DB_PORT: Joi.number().default(5432),
  DB_NAME: Joi.string().default('mate_social'),
  DB_USER: Joi.string().default('postgres'),
  DB_PASSWORD: Joi.string().default('postgres'),

  // JWT
  JWT_ACCESS_SECRET: Joi.string().required(),
  JWT_ACCESS_EXPIRES_IN: Joi.string().default('15m'),
  JWT_REFRESH_SECRET: Joi.string().required(),
  JWT_REFRESH_EXPIRES_IN: Joi.string().default('7d'),

  // Redis
  REDIS_HOST: Joi.string().default('localhost'),
  REDIS_PORT: Joi.number().default(6379),
  REDIS_PASSWORD: Joi.string().allow('').optional(),
  REDIS_TTL: Joi.number().default(3600),

  // Upload
  MAX_FILE_SIZE: Joi.number().default(5242880),
  MAX_FILES: Joi.number().default(10),
  UPLOAD_DIR: Joi.string().default('./uploads'),
  ALLOWED_MIME_TYPES: Joi.string().default('image/jpeg,image/png,image/webp'),

  // Twilio (optional)
  TWILIO_ACCOUNT_SID: Joi.string().allow('').optional(),
  TWILIO_AUTH_TOKEN: Joi.string().allow('').optional(),
  TWILIO_PHONE_NUMBER: Joi.string().allow('').optional(),

  // Firebase (optional)
  FIREBASE_PROJECT_ID: Joi.string().allow('').optional(),
  FIREBASE_CLIENT_EMAIL: Joi.string().allow('').optional(),
  FIREBASE_PRIVATE_KEY: Joi.string().allow('').optional(),

  // Stripe (optional)
  STRIPE_SECRET_KEY: Joi.string().allow('').optional(),
  STRIPE_WEBHOOK_SECRET: Joi.string().allow('').optional(),
  STRIPE_CURRENCY: Joi.string().default('usd'),

  // Email (optional)
  EMAIL_HOST: Joi.string().default('smtp.gmail.com'),
  EMAIL_PORT: Joi.number().default(587),
  EMAIL_USER: Joi.string().allow('').optional(),
  EMAIL_PASSWORD: Joi.string().allow('').optional(),
  EMAIL_FROM: Joi.string().default('noreply@matesocial.com'),

  // Cloudinary (optional)
  CLOUDINARY_CLOUD_NAME: Joi.string().allow('').optional(),
  CLOUDINARY_API_KEY: Joi.string().allow('').optional(),
  CLOUDINARY_API_SECRET: Joi.string().allow('').optional(),

  // Rate limit (per user khi đã login, per IP khi chưa login)
  THROTTLE_SHORT_LIMIT: Joi.number().min(1).max(20).default(3),
  THROTTLE_MEDIUM_LIMIT: Joi.number().min(5).max(100).default(20),
  THROTTLE_LONG_LIMIT: Joi.number().min(20).max(500).default(100),

  // SOS
  SOS_EMERGENCY_NUMBER: Joi.string().default('113'),
  SOS_ALERT_RADIUS: Joi.number().default(5000),
  SOS_MAX_CONTACTS: Joi.number().default(5),
});

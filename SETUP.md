# 🚀 TrAIder API - Setup Guide

## Prerequisites

Sebelum memulai, pastikan Anda sudah menginstall:

1. **Node.js** (v20 atau lebih baru)
   - Download dari: https://nodejs.org/
   - Verifikasi instalasi: `node --version`

2. **PostgreSQL** (v16 atau lebih baru)
   - Download dari: https://www.postgresql.org/download/
   - Atau gunakan Docker: `docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=password postgres:16-alpine`

3. **Git** (opsional, untuk version control)
   - Download dari: https://git-scm.com/

## 📦 Installation Steps

### 1. Install Dependencies

```bash
npm install
```

### 2. Setup Environment Variables

File `.env` sudah dibuat dengan default values. Update sesuai kebutuhan:
- `DATABASE_URL`: Connection string PostgreSQL Anda
- `JWT_SECRET` & `JWT_REFRESH_SECRET`: Ganti dengan random string yang kuat
- API Keys untuk external services (jika diperlukan)

### 3. Setup Database

```bash
# Generate Prisma Client
npm run prisma:generate

# Run database migrations
npm run prisma:migrate

# (Opsional) Open Prisma Studio untuk melihat database
npm run prisma:studio
```

### 4. Start Development Server

```bash
npm run dev
```

Server akan berjalan di `http://localhost:3000`

## 🐳 Using Docker (Alternative)

Jika Anda ingin menggunakan Docker:

```bash
# Start all services (API + PostgreSQL + Redis)
docker-compose up -d

# View logs
docker-compose logs -f api

# Stop services
docker-compose down
```

## 📝 API Documentation

### Base URL
```
http://localhost:3000/api/v1
```

### Authentication Endpoints

#### Register
```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe"
}
```

#### Login
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

Response:
```json
{
  "status": "success",
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "name": "John Doe",
      "role": "USER"
    },
    "accessToken": "jwt-token",
    "refreshToken": "refresh-token"
  }
}
```

### Protected Endpoints

Gunakan Bearer Token di header:
```
Authorization: Bearer <your-access-token>
```

#### Get Current User
```http
GET /api/v1/auth/me
```

#### Get Market Tickers
```http
GET /api/v1/market/tickers
```

#### Get Portfolio
```http
GET /api/v1/trades/portfolio
```

#### Place Order
```http
POST /api/v1/trades/order
Content-Type: application/json

{
  "symbol": "BTCUSDT",
  "type": "MARKET",
  "side": "BUY",
  "quantity": 0.001
}
```

#### Get AI Trading Signals
```http
GET /api/v1/ai/signals?timeframe=1h
```

#### Get AI Analysis
```http
GET /api/v1/ai/analysis/BTCUSDT
```

## 🗂️ Project Structure

```
TrAIder-API/
├── prisma/
│   ├── schema.prisma          # Database schema
│   └── migrations/            # Database migrations
├── src/
│   ├── config/               # Configuration files
│   │   └── database.ts       # Prisma client setup
│   ├── controllers/          # Route controllers
│   │   ├── auth.controller.ts
│   │   ├── market.controller.ts
│   │   ├── trade.controller.ts
│   │   ├── ai.controller.ts
│   │   └── user.controller.ts
│   ├── middleware/           # Express middlewares
│   │   ├── auth.ts          # JWT authentication
│   │   ├── errorHandler.ts  # Error handling
│   │   ├── rateLimiter.ts   # Rate limiting
│   │   └── validateRequest.ts # Request validation
│   ├── routes/              # API routes
│   │   ├── index.ts
│   │   ├── auth.routes.ts
│   │   ├── market.routes.ts
│   │   ├── trade.routes.ts
│   │   ├── ai.routes.ts
│   │   └── user.routes.ts
│   ├── services/            # Business logic
│   │   ├── auth.service.ts
│   │   ├── user.service.ts
│   │   ├── market.service.ts
│   │   ├── trade.service.ts
│   │   └── ai.service.ts
│   ├── validators/          # Request validation schemas
│   │   ├── auth.validator.ts
│   │   ├── trade.validator.ts
│   │   └── user.validator.ts
│   ├── utils/               # Utility functions
│   │   ├── appError.ts      # Custom error class
│   │   └── logger.ts        # Winston logger
│   ├── types/               # TypeScript definitions
│   │   └── express.d.ts
│   └── server.ts            # Application entry point
├── logs/                    # Log files
├── .env                     # Environment variables
├── .env.example            # Environment template
├── .gitignore              # Git ignore rules
├── docker-compose.yml      # Docker composition
├── Dockerfile              # Docker image
├── package.json            # Dependencies
├── tsconfig.json           # TypeScript config
├── nodemon.json            # Nodemon config
└── README.md               # Documentation
```

## 🔧 Available Scripts

```bash
# Development
npm run dev              # Start with hot reload

# Production
npm run build           # Build TypeScript
npm start               # Start production server

# Database
npm run prisma:generate # Generate Prisma Client
npm run prisma:migrate  # Run migrations
npm run prisma:studio   # Open Prisma Studio

# Code Quality
npm run lint            # Run ESLint
```

## 🔐 Security Features

- ✅ JWT Authentication with refresh tokens
- ✅ Password hashing with bcrypt
- ✅ Rate limiting to prevent abuse
- ✅ Helmet for security headers
- ✅ CORS configuration
- ✅ Input validation with Joi
- ✅ SQL injection protection (Prisma ORM)
- ✅ Error handling middleware

## 📊 Database Schema

### Users
- Authentication & profile information
- User settings and preferences

### Positions
- Open/closed trading positions
- P&L tracking

### Orders
- Order management (pending, filled, cancelled)
- Order history

### Trades
- Executed trade records
- Fee tracking

### Market Data
- Candlestick data storage
- Multiple timeframes

### AI Signals
- AI-generated trading signals
- Confidence scores

## 🤖 AI Integration

Services di folder `src/services/ai.service.ts` sudah siap untuk integrasi dengan:
- Machine Learning models untuk price prediction
- Sentiment analysis
- Trading signal generation
- Technical analysis

Saat ini menggunakan mock data. Anda bisa menghubungkan ke:
- Python ML service
- External AI APIs
- Custom ML models

## 🚦 Next Steps

1. **Install Node.js** jika belum ada
2. Run `npm install` untuk install dependencies
3. Setup PostgreSQL database
4. Run database migrations
5. Start development server
6. Test API endpoints dengan Postman/Thunder Client
7. Integrate dengan frontend application
8. Deploy ke production (Heroku, AWS, DigitalOcean, dll)

## 📞 Support

Untuk pertanyaan atau bantuan, silakan buka issue di repository ini.

## 📄 License

MIT License

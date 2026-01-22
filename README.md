# TrAIder API

AI-powered Trading Platform Backend API built with Node.js, Express, TypeScript, and PostgreSQL.

## Features

- 🔐 **JWT Authentication** - Secure user authentication and authorization
- 📊 **Trading Operations** - Market data, orders, positions management
- 🤖 **AI Integration** - ML-powered trading signals and analysis
- 🗄️ **PostgreSQL + Prisma** - Type-safe database operations
- 🐳 **Docker Support** - Easy deployment with Docker Compose
- 🛡️ **Security** - Rate limiting, CORS, Helmet middleware
- 📝 **TypeScript** - Full type safety
- 🎯 **Clean Architecture** - Organized code structure

## Tech Stack

- **Runtime**: Node.js 20
- **Framework**: Express.js
- **Language**: TypeScript
- **Database**: PostgreSQL
- **ORM**: Prisma
- **Authentication**: JWT
- **Caching**: Redis
- **Validation**: Joi
- **Logging**: Winston

## Getting Started

### Prerequisites

- Node.js 20+
- PostgreSQL 16+
- Redis (optional, for caching)

### Installation

1. Clone the repository
2. Install dependencies:
```bash
npm install
```

3. Copy environment file:
```bash
copy .env.example .env
```

4. Update `.env` with your configuration

5. Setup database:
```bash
npm run prisma:migrate
npm run prisma:generate
```

6. Start development server:
```bash
npm run dev
```

### Using Docker

```bash
docker-compose up -d
```

## API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/refresh` - Refresh token
- `POST /api/v1/auth/logout` - User logout

### Market Data
- `GET /api/v1/market/tickers` - Get all tickers
- `GET /api/v1/market/ticker/:symbol` - Get specific ticker data
- `GET /api/v1/market/candles/:symbol` - Get candlestick data

### Trading
- `GET /api/v1/trades/portfolio` - Get user portfolio
- `GET /api/v1/trades/positions` - Get open positions
- `POST /api/v1/trades/order` - Place new order
- `GET /api/v1/trades/orders` - Get order history
- `DELETE /api/v1/trades/order/:id` - Cancel order

### AI Signals
- `GET /api/v1/ai/signals` - Get trading signals
- `GET /api/v1/ai/analysis/:symbol` - Get AI analysis for symbol
- `POST /api/v1/ai/predict` - Get price prediction

## Project Structure

```
src/
├── config/         # Configuration files
├── controllers/    # Route controllers
├── middleware/     # Express middlewares
├── models/         # Data models (Prisma)
├── routes/         # API routes
├── services/       # Business logic
├── utils/          # Utility functions
├── validators/     # Request validation schemas
├── types/          # TypeScript type definitions
└── server.ts       # Application entry point
```

## Environment Variables

See `.env.example` for all required environment variables.

## License

MIT

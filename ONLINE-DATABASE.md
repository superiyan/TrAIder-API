# Quick Guide: Using Free Online PostgreSQL

## 🚀 Recommended: Neon (Easiest & Free)

### Setup Steps:

1. **Go to**: https://neon.tech
2. **Sign up** with GitHub (1 click)
3. **Create project**: Click "Create Project"
   - Name: TrAIder
   - Region: Choose closest to you
4. **Copy connection string** (looks like):
   ```
   postgresql://user:pass@ep-xxx.region.aws.neon.tech/neondb?sslmode=require
   ```
5. **Update your `.env` file**:
   - Open: `.env`
   - Replace `DATABASE_URL=` with your connection string

### Why Neon?
- ✅ 100% Free tier
- ✅ No credit card required
- ✅ 3GB storage
- ✅ Auto-suspend when idle (saves resources)
- ✅ Works perfectly with Prisma
- ✅ No admin rights needed!

---

## Alternative Options:

### Supabase (Also Great)
1. Go to: https://supabase.com
2. Sign up (free)
3. Create new project
4. Get connection string from Settings > Database
5. Update `.env` file

### Railway (Developer Friendly)
1. Go to: https://railway.app
2. Sign up with GitHub
3. New Project > Add PostgreSQL
4. Copy DATABASE_URL from Variables tab
5. Update `.env` file

---

## After Getting Connection String:

1. Update `.env`:
   ```env
   DATABASE_URL="your-connection-string-here"
   ```

2. Run migrations:
   ```powershell
   npm run prisma:migrate
   ```

3. Start the API:
   ```powershell
   npm run dev
   ```

Done! 🎉

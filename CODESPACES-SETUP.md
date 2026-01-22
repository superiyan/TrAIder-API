# 🚀 Setup GitHub Codespaces - Panduan Lengkap

## Langkah 1: Buat GitHub Repository

Karena Git tidak terinstall di PC ini, kita upload manual:

### A. Buat Repository Baru
1. Buka https://github.com
2. Login ke akun GitHub
3. Klik tombol **+** → **New repository**
4. Isi detail:
   - Repository name: `TrAIder-API`
   - Description: `AI-powered Trading Platform Backend API`
   - Visibility: **Private** (recommended) atau Public
   - ❌ JANGAN centang "Add a README" (sudah ada)
5. Klik **Create repository**

### B. Upload Files ke GitHub

**Cara 1: Via Web Interface (Paling Mudah)**
1. Di halaman repository baru, klik **uploading an existing file**
2. **Drag & drop** folder `TrAIder-API` ke browser
3. Atau klik **choose your files** dan pilih semua file/folder
4. ⚠️ **PENTING:** Jangan upload folder `node_modules/` (terlalu besar)
5. Scroll ke bawah, klik **Commit changes**

**Cara 2: Via GitHub Desktop (Jika Ada)**
1. Download GitHub Desktop: https://desktop.github.com
2. File → Add Local Repository → Pilih folder TrAIder-API
3. Publish repository

## Langkah 2: Buka Codespaces

1. Di repository GitHub yang baru dibuat
2. Klik tombol hijau **Code** 
3. Pilih tab **Codespaces**
4. Klik **Create codespace on main**

Tunggu 2-3 menit untuk setup environment.

## Langkah 3: Setup Environment

Setelah Codespaces terbuka (VS Code di browser):

### A. Create .env file
```bash
cat > .env << 'EOF'
# Server
PORT=5000
NODE_ENV=development
API_VERSION=v1

# Database
DATABASE_URL=postgresql://neondb_owner:npg_rbz2Mf3mOyoG@ep-nameless-forest-a1dvbu3f-pooler.ap-southeast-1.aws.neon.tech/neondb?sslmode=require

# JWT
JWT_SECRET=your-secret-key-change-in-production
JWT_REFRESH_SECRET=your-refresh-secret-key-change-in-production
JWT_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=7d

# CORS
CORS_ORIGIN=*
EOF
```

### B. Install Dependencies (Otomatis)
Dependencies sudah auto-install via `postCreateCommand` di devcontainer.json

Jika belum, jalankan manual:
```bash
npm install
```

### C. Generate Prisma Client
```bash
npx prisma generate
```

### D. Run Database Migrations
```bash
npx prisma migrate dev --name init
```

## Langkah 4: Start Server

```bash
npm run dev
```

Output yang diharapkan:
```
[nodemon] starting `ts-node src/server.ts`
✅ Server is ready!
📡 Local: http://localhost:5000
```

## Langkah 5: Test API

Codespaces akan auto-forward port 5000. Klik notifikasi "Open in Browser" atau:

1. Buka tab **PORTS** di VS Code
2. Klik icon 🌐 pada port 5000
3. Test endpoint: `/health`

Atau via terminal:
```bash
curl http://localhost:5000/health
```

Expected response:
```json
{"status":"OK","timestamp":"2026-01-22T..."}
```

## 📊 Monitoring Codespaces Usage

- Dashboard: https://github.com/settings/billing
- Free tier: **120 core-hours/month**
- 2-core machine = 60 jam development
- 4-core machine = 30 jam development

Tips hemat quota:
- Stop codespace saat tidak pakai (auto-stop after 30 min idle)
- Gunakan 2-core machine untuk development biasa
- 4-core hanya untuk build/compile besar

## 🔄 Workflow Harian

1. Buka https://github.com/codespaces
2. Klik nama codespace yang sudah ada (restart)
3. Tunggu ~30 detik
4. `npm run dev`
5. Start coding!

## 🛑 Stop Codespace

Penting untuk hemat quota:

1. Klik nama codespace di kiri bawah VS Code
2. Pilih **Stop Current Codespace**

Atau dari dashboard: https://github.com/codespaces

## 🎯 Next Steps

Setelah API jalan di Codespaces:

1. **Test semua endpoints** dengan Postman/Thunder Client
2. **Implement business logic** (sekarang masih mock data)
3. **Deploy ke Railway/Render** untuk production
4. **Setup CI/CD** untuk auto-deploy

## ❓ Troubleshooting

### Port tidak muncul di PORTS tab
```bash
# Restart server
npm run dev
```

### Database connection error
```bash
# Re-generate Prisma Client
npx prisma generate

# Test connection
npx prisma db push
```

### npm install gagal
```bash
# Clear cache
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

### Codespace loading terus
- Refresh browser
- Atau stop & start codespace baru

## 💡 Tips Pro

1. **Install VS Code Desktop** dan connect ke Codespace untuk better performance
2. **Create codespace template** untuk project baru (simpan konfigurasi)
3. **Use prebuild** untuk startup lebih cepat (GitHub Actions)
4. **Share codespace** dengan team untuk collaboration

## 📞 Butuh Bantuan?

- GitHub Codespaces Docs: https://docs.github.com/codespaces
- VS Code Remote Docs: https://code.visualstudio.com/docs/remote/codespaces

---

**Estimasi waktu setup total: 10-15 menit** ⏱️

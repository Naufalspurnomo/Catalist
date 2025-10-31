# 🚀 Panduan Deployment Full Online - Catalis

Panduan lengkap untuk deploy Catalis ke Vercel agar **frontend & backend full online** tanpa perlu `npm start` lokal.

---

## 📦 Apa yang Sudah Berubah?

✅ **Semua URL diubah dari `newcatalist.vercel.app` → `catalist-omega.vercel.app`**
✅ **Backend dikonfigurasi sebagai Vercel Serverless Functions**
✅ **Environment variables dipindahkan dari kode ke Vercel Dashboard (lebih aman)**

---

## 🔧 Langkah-Langkah Deploy Full Online

### **Step 1: Setup Environment Variables di Vercel Dashboard**

**PENTING:** Kredensial sudah dihapus dari `vercel.json` untuk keamanan. Anda HARUS set di Vercel Dashboard.

1. Buka [Vercel Dashboard](https://vercel.com/dashboard)
2. Pilih project **catalist-omega**
3. Masuk ke **Settings → Environment Variables**
4. Tambahkan variabel berikut **SATU PER SATU**:

| Key | Value | Environment |
|-----|-------|-------------|
| `NODE_ENV` | `production` | ✓ Production ✓ Preview ✓ Development |
| `SUPABASE_URL` | `https://anzsbqqippijhemwxkqh.supabase.co` | ✓ Production ✓ Preview ✓ Development |
| `SUPABASE_KEY` | `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuenNicXFpcHBpamhlbXd4a3FoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEyMDM1MTQsImV4cCI6MjA3Njc3OTUxNH0.6l1Bt9_5_5ohFeH8IN6mP9jU0pFUToHMmV1NwQEeP-Q` | ✓ Production ✓ Preview ✓ Development |
| `MIDTRANS_SERVER_KEY` | `Mid-server-XVdnQPgGcucvnoRJYNWzNw1j` | ✓ Production ✓ Preview ✓ Development |
| `MIDTRANS_CLIENT_KEY` | `Mid-client-QZNRNJ4ROIoY8PAn` | ✓ Production ✓ Preview ✓ Development |
| `MIDTRANS_MERCHANT_ID` | `G498472407` | ✓ Production ✓ Preview ✓ Development |
| `MIDTRANS_IS_PRODUCTION` | `false` | ✓ Production ✓ Preview ✓ Development |

5. **Klik Save** setelah menambahkan setiap variabel

⚠️ **Jika tidak set environment variables, backend akan error!**

---

### **Step 2: Push & Deploy**

```bash
# Commit perubahan
git add .
git commit -m "Deploy: Update ke catalist-omega dan secure env vars"

# Push ke GitHub (Vercel auto-deploy)
git push origin main
```

Vercel akan **otomatis build & deploy**:
- Frontend: `https://catalist-omega.vercel.app`
- Backend API: `https://catalist-omega.vercel.app/api/generate-snap-token`
- Backend Callback: `https://catalist-omega.vercel.app/api/midtrans-callback`

---

### **Step 3: Verifikasi Deployment**

#### A. Cek Status Deployment
1. Buka [Vercel Dashboard](https://vercel.com/dashboard)
2. Pilih project **catalist-omega**
3. Tab **Deployments** → pastikan status **Ready**

#### B. Test Frontend
Buka: `https://catalist-omega.vercel.app`
- ✅ Website loading dengan benar
- ✅ Produk muncul dari Supabase

#### C. Test Backend API
Jalankan di terminal:

```bash
curl -X POST https://catalist-omega.vercel.app/api/generate-snap-token \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_details": {
      "order_id": "TEST-001",
      "gross_amount": 10000
    },
    "customer_details": {
      "first_name": "Test User"
    },
    "frontendOrigin": "https://catalist-omega.vercel.app"
  }'
```

**Expected Response:**
```json
{
  "token": "abc123...",
  "redirect_url": "https://app.sandbox.midtrans.com/snap/v4/..."
}
```

✅ Jika dapat response seperti ini, **backend sudah online!**

---

### **Step 4: Test Payment Flow**

1. Buka website: `https://catalist-omega.vercel.app`
2. Pilih produk dan klik **Buy Now**
3. Isi form checkout
4. Klik **Bayar Sekarang**
5. Popup Midtrans muncul (sandbox mode)
6. Test payment dengan kartu test Midtrans:
   - Card Number: `4811 1111 1111 1114`
   - CVV: `123`
   - Exp: `01/25`

✅ Payment sukses → redirect ke `payment-success.html`

---

## 🎯 Perbandingan Sebelum & Sesudah

| Aspek | ❌ Sebelum | ✅ Sesudah |
|-------|----------|-----------|
| **Frontend** | Manual upload/deploy | Auto-deploy dari git push |
| **Backend** | `npm start` di localhost | Vercel Serverless (auto) |
| **URL Frontend** | `newcatalist.vercel.app` | `catalist-omega.vercel.app` |
| **URL Backend** | `http://localhost:3001` | `https://catalist-omega.vercel.app/api` |
| **Env Variables** | Hardcoded di `vercel.json` | Secure di Vercel Dashboard |
| **Maintenance** | Harus running server 24/7 | Zero maintenance! |

---

## 📁 Struktur Project

```
catalis/
├── api/
│   └── midtrans-callback.js    # Backend serverless function
├── js/
│   └── midtrans.js              # Frontend payment logic
├── admin/                       # Admin panel (deploy terpisah)
├── vercel.json                  # Konfigurasi Vercel (NO credentials)
├── .env.example                 # Template env vars (untuk dokumentasi)
└── .env                         # Local dev only (NEVER commit!)
```

---

## 🔒 Keamanan

✅ **Credentials dihapus dari `vercel.json`**
✅ **`.env` ditambahkan ke `.gitignore`**
✅ **Environment variables disimpan di Vercel Dashboard**
✅ **Midtrans menggunakan Sandbox mode** (aman untuk testing)

---

## 🛠️ Development Lokal (Optional)

Jika ingin test di localhost:

```bash
# 1. Copy environment variables
cp .env.example .env

# 2. Edit .env dengan kredensial asli
nano .env

# 3. Install dependencies
npm install

# 4. Run backend locally
npm start

# 5. Run frontend locally (terminal baru)
npx http-server -p 8080
```

---

## 🚨 Troubleshooting

### Backend API Error 500
**Penyebab:** Environment variables belum di-set di Vercel
**Solusi:** Cek Step 1, pastikan semua 7 variabel sudah ada

### Payment Popup Tidak Muncul
**Penyebab:** Backend URL salah atau CORS issue
**Solusi:**
1. Cek browser console untuk error
2. Pastikan `js/midtrans.js` line 139 sudah benar:
   ```js
   ? "https://catalist-omega.vercel.app/api/generate-snap-token"
   ```

### Redirect Loop Setelah Payment
**Penyebab:** Callback URL salah
**Solusi:** Cek `api/midtrans-callback.js` line 407:
```js
? "https://catalist-omega.vercel.app"
```

### Deployment Gagal di Vercel
**Penyebab:** Build error atau missing files
**Solusi:**
1. Cek Vercel Logs di Dashboard
2. Pastikan `api/midtrans-callback.js` ada
3. Verifikasi `package.json` di root

---

## 🎉 Selesai!

Sekarang aplikasi Anda **100% online**:
- ✅ Tidak perlu `npm start` lagi
- ✅ Auto-deploy dari git push
- ✅ Scalable & serverless
- ✅ Secure credentials

**Happy deploying!** 🚀

---

## 📞 Support

Jika ada masalah:
1. Cek logs di Vercel Dashboard
2. Test API dengan `curl` command di Step 3
3. Verifikasi environment variables sudah lengkap

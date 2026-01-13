# Quick Deployment Guide - Cloudflare Pages

## Ready to Deploy! ✅

The React app has been built and is ready for Cloudflare Pages deployment.

## Quick Steps

### 1. Push to GitHub
```bash
git add .
git commit -m "Prepare for Cloudflare deployment"
git push origin make-local-host
```

### 2. Connect to Cloudflare Pages

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Navigate to **Pages** → **Create a project**
3. Connect your GitHub repository
4. Select the `make-local-host` branch (or merge to main first)

### 3. Configure Build Settings

- **Framework preset**: Create React App
- **Build command**: `cd Frontend && npm run build`
- **Build output directory**: `Frontend/build`
- **Root directory**: `/` (leave empty)

### 4. Set Environment Variables

Add in Cloudflare Pages → Settings → Environment variables:

```
REACT_APP_API_URL = https://your-backend-api-url.com/api
NODE_VERSION = 18
```

**Important**: Replace `your-backend-api-url.com` with your actual backend API URL.

### 5. Configure Custom Domain

1. In Pages project → **Custom domains**
2. Add `www.papita.org`
3. Cloudflare will automatically configure DNS

### 6. Deploy!

Cloudflare will automatically deploy. Check the deployment status in the dashboard.

## Files Created for Deployment

- ✅ `Frontend/public/_redirects` - SPA routing support
- ✅ `Frontend/cloudflare-pages.json` - Cloudflare configuration
- ✅ `Frontend/wrangler.toml` - Cloudflare Workers config (optional)
- ✅ `Docs/DEPLOYMENT.md` - Full deployment guide
- ✅ `Frontend/build/` - Production build (ready to deploy)

## Backend Requirements

⚠️ **Important**: The frontend needs a backend API. You must:

1. Deploy the Python Flask backend to a server
2. Configure CORS to allow `www.papita.org`
3. Set `REACT_APP_API_URL` environment variable to your backend URL

## Testing Locally

Test the production build locally:
```bash
cd Frontend
npm install -g serve
serve -s build
```

Visit `http://localhost:3000` to test.

## Need Help?

See `Docs/DEPLOYMENT.md` for detailed deployment instructions and troubleshooting.

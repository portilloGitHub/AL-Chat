# Deployment Guide - Cloudflare Pages

This guide covers deploying AL-Chat frontend to Cloudflare Pages at www.papita.org.

## Prerequisites

1. Cloudflare account with Pages enabled
2. Domain configured in Cloudflare (www.papita.org)
3. GitHub repository connected to Cloudflare Pages
4. Backend API deployed and accessible (for production API URL)

## Deployment Steps

### 1. Prepare the Repository

Ensure all changes are committed and pushed to GitHub:

```bash
git add .
git commit -m "Prepare for Cloudflare deployment"
git push origin make-local-host
```

### 2. Build the React App Locally (Optional Test)

```bash
cd Frontend
npm install
npm run build
```

Verify the `build` folder is created successfully.

### 3. Configure Cloudflare Pages

1. Log in to Cloudflare Dashboard
2. Go to **Pages** → **Create a project**
3. Connect your GitHub repository
4. Configure build settings:
   - **Framework preset**: Create React App
   - **Build command**: `cd Frontend && npm run build`
   - **Build output directory**: `Frontend/build`
   - **Root directory**: `/` (or leave empty)

### 4. Set Environment Variables

In Cloudflare Pages settings, add these environment variables:

- **REACT_APP_API_URL**: Your backend API URL (e.g., `https://api.papita.org/api` or your backend server URL)
- **NODE_VERSION**: `18` (or your preferred Node version)

**Important**: The backend API must be accessible from the web. Options:
- Deploy backend to a server with public IP
- Use Cloudflare Workers for backend
- Use a backend-as-a-service platform

### 5. Configure Custom Domain

1. In Cloudflare Pages project settings, go to **Custom domains**
2. Add `www.papita.org`
3. Configure DNS in Cloudflare:
   - Add CNAME record: `www` → `your-pages-project.pages.dev`
   - Or use Cloudflare's automatic DNS configuration

### 6. Deploy

Cloudflare Pages will automatically deploy when you:
- Push to the connected branch (usually `main` or `master`)
- Or manually trigger a deployment from the dashboard

## Post-Deployment

### Verify Deployment

1. Visit `https://www.papita.org`
2. Check browser console for errors
3. Verify API connection to backend
4. Test chat functionality

### Troubleshooting

**Issue**: API calls failing
- **Solution**: Verify `REACT_APP_API_URL` environment variable is set correctly
- Check backend CORS settings allow requests from `www.papita.org`

**Issue**: 404 errors on page refresh
- **Solution**: Verify `_redirects` file is in the `build` folder
- Cloudflare Pages should handle SPA routing automatically

**Issue**: Build fails
- **Solution**: Check build logs in Cloudflare Pages dashboard
- Verify Node version matches (set NODE_VERSION environment variable)

## Environment Variables Reference

| Variable | Description | Example |
|----------|-------------|---------|
| `REACT_APP_API_URL` | Backend API base URL | `https://api.papita.org/api` |
| `NODE_VERSION` | Node.js version for build | `18` |

## Backend Deployment Considerations

The frontend requires a backend API. Options:

1. **Deploy backend separately**:
   - Deploy Python Flask backend to a VPS, Heroku, Railway, etc.
   - Update `REACT_APP_API_URL` to point to backend URL
   - Ensure CORS is configured to allow `www.papita.org`

2. **Use Cloudflare Workers**:
   - Convert backend to Cloudflare Workers
   - Deploy as a Worker
   - Update API URL accordingly

3. **Backend-as-a-Service**:
   - Use services like Supabase, Firebase, etc.
   - Adapt backend code accordingly

## Continuous Deployment

Cloudflare Pages supports automatic deployments:
- **Production**: Deploys from `main`/`master` branch
- **Preview**: Creates preview deployments for pull requests

## Rollback

To rollback a deployment:
1. Go to Cloudflare Pages dashboard
2. Select your project
3. Go to **Deployments**
4. Click on a previous deployment
5. Click **Retry deployment** or **Promote to production**

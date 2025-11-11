# Netlify Setup for Branch Preview Deployments

This guide explains how to set up Netlify to get automatic preview deployments for every branch and PR.

## Why Netlify?

- ✅ **Automatic PR Previews**: Every PR gets a unique URL to preview changes
- ✅ **Branch Deployments**: Every branch gets its own deployment URL
- ✅ **Free for public repos**: No cost for open source projects
- ✅ **Fast builds**: Optimized for static sites like mdBook

## Setup Steps

### 1. Sign up for Netlify

1. Go to [netlify.com](https://www.netlify.com/)
2. Sign up with your GitHub account (easiest option)

### 2. Import Your Repository

1. Click "Add new site" → "Import an existing project"
2. Choose "GitHub" as the provider
3. Select `prasincs/haskell-linker-exploration`
4. Netlify will automatically detect the `netlify.toml` configuration

### 3. Configure Build Settings (should be auto-detected)

The `netlify.toml` file already configures:
- **Base directory**: `book/`
- **Build command**: Downloads mdBook and builds the book
- **Publish directory**: `book/` (mdBook output)

Click "Deploy site"

### 4. Enable Branch Deployments

1. Go to **Site settings** → **Build & deploy** → **Continuous deployment**
2. Under "Deploy contexts", enable:
   - ✅ **Deploy previews** (for PRs)
   - ✅ **Branch deploys** (for all branches or selected branches)
3. For branch deploys, you can specify pattern: `claude/*` to only deploy Claude branches

### 5. Configure PR Comments (Optional but Recommended)

Netlify will automatically comment on PRs with the preview URL. Make sure:
1. Go to **Site settings** → **Build & deploy** → **Deploy notifications**
2. Enable "GitHub pull request comments"

## How It Works

### For PRs:
1. You create a PR (e.g., from `claude/fix-gitbook-formatting-...` to `main`)
2. Netlify automatically builds and deploys a preview
3. A comment is added to the PR with the preview URL
4. You can navigate the preview before merging
5. URL looks like: `https://deploy-preview-4--your-site.netlify.app`

### For Branches:
1. You push to a branch (e.g., `claude/feature-branch`)
2. Netlify automatically deploys it
3. URL looks like: `https://claude-feature-branch--your-site.netlify.app`

### For Main:
1. When merged to `main`, Netlify deploys to production URL
2. URL looks like: `https://your-site.netlify.app`

## Keeping GitHub Pages

You can keep both:
- **Netlify**: For previews and fast development iteration
- **GitHub Pages**: For official documentation site

Or you can:
- Use Netlify as primary deployment
- Keep GitHub Pages workflow but only for `main` branch
- Disable GitHub Pages and use Netlify exclusively

## Custom Domain (Optional)

If you have a custom domain:
1. Go to **Site settings** → **Domain management**
2. Add your custom domain (e.g., `docs.yourproject.com`)
3. Configure DNS according to Netlify's instructions

## Netlify vs GitHub Pages

| Feature | Netlify | GitHub Pages |
|---------|---------|--------------|
| Branch previews | ✅ Yes | ❌ No (single deployment) |
| PR previews | ✅ Yes | ❌ No |
| Build speed | ⚡ Fast | 🐢 Slower |
| Custom redirects | ✅ Yes | ⚠️ Limited |
| Free tier | ✅ 100GB bandwidth | ✅ Unlimited for public |

## After Setup

Once configured:
1. Push your current branch to GitHub (already done)
2. Netlify will automatically build and deploy
3. You'll get a preview URL to review the changes
4. Share the URL with reviewers
5. Merge when satisfied

## Cost

**Free tier includes**:
- 100GB bandwidth/month
- 300 build minutes/month
- Unlimited sites
- HTTPS/SSL included

For a documentation site, this is typically more than enough.

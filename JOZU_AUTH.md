# Jozu Hub Authentication Setup

## Quick Setup

### 1. Get Your Jozu Hub Credentials
- Log in to https://jozu.ml
- Go to **Settings** → **Access Tokens** (or your profile section)
- Create a new access token (or use your password)

### 2. Add Secrets to GitHub

1. Go to your GitHub repo: `https://github.com/arnab2001/KitOps-kitops-governance-demo`
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add two secrets:

**Secret 1:**
- Name: `JOZU_USERNAME`
- Value: `arnabchat2001` (your Jozu Hub username)

**Secret 2:**
- Name: `JOZU_PASSWORD`
- Value: `<your-jozu-hub-password-or-token>`

### 3. Verify Setup

Run the workflow:
- Go to **Actions** → **AI Governance Gate** → **Run workflow**
- The "Compliant" job should now PUSH to `jozu.ml/arnabchat2001/kitops-governance-demo`

## What Happens Now

### Before (Simulation)
```yaml
- name: Simulate Production Push
  run: echo "Would execute: kit push..."
```

### After (Real Push)
```yaml
- name: Authenticate to Jozu Hub
  run: kit login jozu.ml -u $JOZU_USERNAME --password-stdin

- name: Push to Jozu Hub
  run: |
    kit push jozu.ml/arnabchat2001/kitops-governance-demo:$SHA
    kit push jozu.ml/arnabchat2001/kitops-governance-demo:latest
```

## Result

When policies **PASS**:
- ✅ ModelKit is pushed to Jozu Hub
- ✅ Tagged with commit SHA + `latest`
- ✅ Visible at: `https://jozu.ml/arnabchat2001/kitops-governance-demo`

When policies **FAIL**:
- ❌ Push is skipped
- ❌ Deployment blocked
- ❌ Only shows policy violation

## Troubleshooting

**Error: "authentication required"**
- Check that `JOZU_USERNAME` and `JOZU_PASSWORD` secrets are set correctly
- Verify credentials work: `kit login jozu.ml -u arnabchat2001`

**Error: "repository does not exist"**
- Create the repository on Jozu Hub first
- Or use an existing repository you have access to

**Want to use a different registry?**
Change `jozu.ml/arnabchat2001/kitops-governance-demo` to your registry in the workflow.

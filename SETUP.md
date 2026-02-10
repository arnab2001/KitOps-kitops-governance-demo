# Quick Setup Guide

## ✅ Fixed Structure

Your **GitHub repo root** is the `demo/` folder. Structure:

```
demo/                          ← Your GitHub repo root
├── .github/
│   └── workflows/
│       └── main.yml           ← ✅ Workflow (paths fixed)
├── model-artifacts/           ← Files to pack
├── kitfile-examples/          ← 4 test scenarios  
├── policies/                  ← OPA policies
└── README.md
```

## 🚀 Deploy Now

```bash
# From the demo/ directory:
cd /Volumes/arnab\ ssd/github/kitops-security/demo

# Commit and push
git add .github/workflows/main.yml
git commit -m "Fix workflow paths"
git push

# Then go to GitHub:
# Actions → "AI Governance Gate" → "Run workflow"
```

## ✅ What Got Fixed

| Before | After |
|--------|-------|
| `cd demo/model-artifacts` | `cd model-artifacts` |
| `--data demo/policies/...` | `--data policies/...` |
| `--input demo/kitfile-examples/...` | `--input kitfile-examples/...` |

All paths now work because **demo/ is your repo root**.

---

**The workflow will now:**
1. ✅ Find `model-artifacts/`
2. ✅ Pack the ModelKit
3. ✅ Validate with OPA
4. ✅ Show 4 results (1 pass, 3 fail)

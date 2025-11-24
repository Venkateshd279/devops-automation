# GitHub Setup Guide

## Quick Steps to Push to GitHub

### Step 1: Initialize Git (if not already done)
```bash
cd /Users/vdhanapalraj/Documents/Learning/automation/devops-automation-scripts

# If .git directory doesn't exist, initialize:
git init
```

### Step 2: Check Current Status
```bash
# Check what files will be committed
git status

# Should see:
# - README.md
# - USAGE_GUIDE.md
# - shell-scripts/
# - python-scripts/
# - sample-logs/
```

### Step 3: Stage All Files
```bash
# Add all files to git
git add .

# Or add specific files:
# git add README.md USAGE_GUIDE.md shell-scripts/ python-scripts/ sample-logs/
```

### Step 4: Create First Commit
```bash
git commit -m "Initial commit: DevOps automation scripts portfolio

- System health monitoring script
- Kubernetes pod health monitor
- Log analyzer for error detection
- Automated deployment with rollback
- Comprehensive documentation"
```

### Step 5: Create GitHub Repository

1. Go to https://github.com
2. Click "+" icon → "New repository"
3. Repository name: `devops-automation-scripts`
4. Description: "DevOps automation scripts for monitoring, deployment, and log analysis"
5. Choose **Public** (to showcase on profile) or **Private**
6. **DO NOT** initialize with README (we already have one)
7. Click "Create repository"

### Step 6: Connect to GitHub

GitHub will show you commands. Use these:

```bash
# Add GitHub as remote
git remote add origin https://github.com/YOUR_USERNAME/devops-automation-scripts.git

# Push to GitHub
git branch -M main
git push -u origin main
```

**Replace `YOUR_USERNAME` with your actual GitHub username**

---

## Alternative: Using SSH (Recommended)

If you have SSH keys set up:

```bash
git remote add origin git@github.com:YOUR_USERNAME/devops-automation-scripts.git
git push -u origin main
```

---

## Verify Upload

1. Go to https://github.com/YOUR_USERNAME/devops-automation-scripts
2. You should see:
   - ✅ README.md displayed on main page
   - ✅ All scripts in their folders
   - ✅ USAGE_GUIDE.md

---

## Making Future Updates

When you make changes:

```bash
# Check what changed
git status

# Add changes
git add .

# Commit with message
git commit -m "Description of changes"

# Push to GitHub
git push
```

---

## Adding a .gitignore (Optional but Recommended)

Create a `.gitignore` file:

```bash
cat > .gitignore << 'EOF'
# Temporary files
*.tmp
*.log
/tmp/
.DS_Store

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
Thumbs.db
EOF

git add .gitignore
git commit -m "Add gitignore file"
git push
```

---

## Personalizing Your Repository

### Add Topics/Tags on GitHub
On your repository page:
1. Click "⚙️ " next to "About"
2. Add topics: `devops`, `automation`, `shell-scripting`, `python`, `kubernetes`, `monitoring`, `ci-cd`
3. Save changes

### Add GitHub Actions Badge (Optional)
If you add CI/CD later, you can add build status badges to README.md

### Star Your Own Repo
Star your own repository to make it appear on your profile!

---

## Sharing Your Work

### On Your Resume
```
GitHub: github.com/YOUR_USERNAME/devops-automation-scripts
DevOps automation portfolio demonstrating Shell/Python scripting,
Kubernetes monitoring, and CI/CD deployment automation
```

### On LinkedIn
```
🚀 Published my DevOps automation portfolio on GitHub!

Includes production-ready scripts for:
✅ System health monitoring
✅ Kubernetes pod management
✅ Log analysis & error detection
✅ Automated deployments with rollback

Check it out: github.com/YOUR_USERNAME/devops-automation-scripts

#DevOps #Automation #Kubernetes #Python #ShellScripting
```

---

## Common Issues & Solutions

### Issue: "fatal: remote origin already exists"
```bash
# Remove existing remote and add again
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/devops-automation-scripts.git
```

### Issue: "Permission denied (publickey)"
```bash
# Use HTTPS instead of SSH
git remote set-url origin https://github.com/YOUR_USERNAME/devops-automation-scripts.git
```

### Issue: "Updates were rejected"
```bash
# Pull first, then push
git pull origin main --rebase
git push
```

---

## Next Steps

1. ✅ Push to GitHub (follow steps above)
2. ✅ Add topics/tags to repository
3. ✅ Make repository public for portfolio visibility
4. ✅ Share on LinkedIn
5. ✅ Add link to resume
6. ✅ Continue adding more automation scripts!

---

## Questions?

- GitHub Docs: https://docs.github.com/en/get-started
- Git Basics: https://git-scm.com/book/en/v2/Getting-Started-Git-Basics

Happy automating! 🚀

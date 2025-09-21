# ChatBox Documentation Deployment Script
# This script helps deploy your documentation to various hosting platforms

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("github", "netlify", "vercel", "firebase", "local")]
    [string]$Platform = "github"
)

Write-Host "🚀 ChatBox Documentation Deployment" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# Function to print colored output
function Write-Success { param($Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "⚠ $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "✗ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ $Message" -ForegroundColor Blue }

# Check if docs directory exists
if (!(Test-Path "docs")) {
    Write-Error "docs directory not found!"
    exit 1
}

switch ($Platform) {
    "github" {
        Write-Info "Setting up GitHub Pages deployment..."
        Write-Host ""
        Write-Host "To deploy to GitHub Pages:" -ForegroundColor White
        Write-Host "1. Go to your repository settings" -ForegroundColor White
        Write-Host "2. Scroll to 'Pages' section" -ForegroundColor White
        Write-Host "3. Set source to 'Deploy from a branch'" -ForegroundColor White
        Write-Host "4. Select 'main' branch and '/docs' folder" -ForegroundColor White
        Write-Host "5. Save and wait for deployment" -ForegroundColor White
        Write-Host ""
        Write-Info "Your docs will be live at: https://YOUR_USERNAME.github.io/YOUR_REPO/"
    }

    "netlify" {
        Write-Info "Preparing for Netlify deployment..."
        Write-Host ""
        Write-Host "To deploy to Netlify:" -ForegroundColor White
        Write-Host "1. Go to https://netlify.com" -ForegroundColor White
        Write-Host "2. Sign up/Login with GitHub" -ForegroundColor White
        Write-Host "3. Drag and drop the entire 'docs' folder" -ForegroundColor White
        Write-Host "4. Your site will be live instantly!" -ForegroundColor White
        Write-Host ""
        Write-Info "Netlify will provide you with a .netlify.app URL"
    }

    "vercel" {
        Write-Info "Setting up Vercel deployment..."
        Write-Host ""

        # Check if Vercel CLI is installed
        if (!(Get-Command vercel -ErrorAction SilentlyContinue)) {
            Write-Warning "Vercel CLI not found. Installing..."
            npm install -g vercel
        }

        Write-Host "Deploying to Vercel..." -ForegroundColor White
        Set-Location docs
        vercel --prod
        Set-Location ..
    }

    "firebase" {
        Write-Info "Setting up Firebase Hosting..."
        Write-Host ""

        # Check if Firebase CLI is installed
        if (!(Get-Command firebase -ErrorAction SilentlyContinue)) {
            Write-Warning "Firebase CLI not found. Installing..."
            npm install -g firebase-tools
        }

        Write-Host "Initializing Firebase hosting..." -ForegroundColor White
        firebase init hosting

        Write-Host "Deploying to Firebase..." -ForegroundColor White
        firebase deploy
    }

    "local" {
        Write-Info "Starting local development server..."
        Write-Host ""
        Write-Host "To test locally, you can use:" -ForegroundColor White
        Write-Host "1. Python: python -m http.server 8000" -ForegroundColor White
        Write-Host "2. Node.js: npx serve docs" -ForegroundColor White
        Write-Host "3. PHP: php -S localhost:8000 -t docs" -ForegroundColor White
        Write-Host ""
        Write-Info "Then visit http://localhost:8000 in your browser"

        # Try to start a simple Python server if available
        if (Get-Command python -ErrorAction SilentlyContinue) {
            Write-Host "Starting Python server on port 8000..." -ForegroundColor White
            Set-Location docs
            Start-Process python -ArgumentList "-m", "http.server", "8000" -NoNewWindow
            Set-Location ..
            Write-Success "Server started! Visit http://localhost:8000"
        }
    }
}

Write-Host ""
Write-Success "Documentation deployment setup complete!"
Write-Host ""
Write-Host "📖 Your documentation includes:" -ForegroundColor White
Write-Host "   • Interactive landing page" -ForegroundColor White
Write-Host "   • Feature showcase" -ForegroundColor White
Write-Host "   • Screenshots gallery" -ForegroundColor White
Write-Host "   • Installation guide" -ForegroundColor White
Write-Host "   • API documentation" -ForegroundColor White
Write-Host ""
Write-Host "📱 Don't forget to update the README links with your live URLs!" -ForegroundColor White
Write-Host ""
Write-Info "Happy deploying! 🎉"
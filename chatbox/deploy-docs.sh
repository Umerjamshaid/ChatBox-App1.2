#!/bin/bash

# ChatBox Documentation Deployment Script
# This script helps deploy your documentation to various hosting platforms

echo "🚀 ChatBox Documentation Deployment"
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if docs directory exists
if [ ! -d "docs" ]; then
    print_error "docs directory not found!"
    exit 1
fi

echo "Available deployment options:"
echo "1. GitHub Pages (Recommended - Free)"
echo "2. Netlify (Drag & Drop)"
echo "3. Vercel (CLI Deployment)"
echo "4. Firebase Hosting"
echo "5. Local testing only"
echo ""

read -p "Choose deployment option (1-5): " choice

case $choice in
    1)
        print_info "Setting up GitHub Pages deployment..."
        echo ""
        echo "To deploy to GitHub Pages:"
        echo "1. Go to your repository settings"
        echo "2. Scroll to 'Pages' section"
        echo "3. Set source to 'Deploy from a branch'"
        echo "4. Select 'main' branch and '/docs' folder"
        echo "5. Save and wait for deployment"
        echo ""
        print_info "Your docs will be live at: https://YOUR_USERNAME.github.io/YOUR_REPO/"
        ;;

    2)
        print_info "Preparing for Netlify deployment..."
        echo ""
        echo "To deploy to Netlify:"
        echo "1. Go to https://netlify.com"
        echo "2. Sign up/Login with GitHub"
        echo "3. Drag and drop the entire 'docs' folder"
        echo "4. Your site will be live instantly!"
        echo ""
        print_info "Netlify will provide you with a .netlify.app URL"
        ;;

    3)
        print_info "Setting up Vercel deployment..."
        echo ""
        if ! command -v vercel &> /dev/null; then
            print_warning "Vercel CLI not found. Installing..."
            npm install -g vercel
        fi

        echo "Deploying to Vercel..."
        cd docs
        vercel --prod
        cd ..
        ;;

    4)
        print_info "Setting up Firebase Hosting..."
        echo ""
        if ! command -v firebase &> /dev/null; then
            print_warning "Firebase CLI not found. Installing..."
            npm install -g firebase-tools
        fi

        echo "Initializing Firebase hosting..."
        firebase init hosting

        echo "Deploying to Firebase..."
        firebase deploy
        ;;

    5)
        print_info "Starting local development server..."
        echo ""
        echo "To test locally, you can use:"
        echo "1. Python: python -m http.server 8000"
        echo "2. Node.js: npx serve docs"
        echo "3. PHP: php -S localhost:8000 -t docs"
        echo ""
        print_info "Then visit http://localhost:8000 in your browser"
        ;;

    *)
        print_error "Invalid option selected"
        exit 1
        ;;
esac

echo ""
print_status "Documentation deployment setup complete!"
echo ""
echo "📖 Your documentation includes:"
echo "   • Interactive landing page"
echo "   • Feature showcase"
echo "   • Screenshots gallery"
echo "   • Installation guide"
echo "   • API documentation"
echo ""
echo "📱 Don't forget to update the README links with your live URLs!"
echo ""
print_info "Happy deploying! 🎉"
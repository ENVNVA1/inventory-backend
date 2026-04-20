#!/bin/bash

# Digital Ocean Droplet Setup Script for inventory-server Backend
# Run this script on your Digital Ocean droplet

set -e

echo "🚀 Starting Digital Ocean Droplet Setup for inventory-server..."
echo ""

# Update system
echo "📦 Step 1/8: Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Node.js 20
echo ""
echo "📦 Step 2/8: Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify Node.js installation
echo "✅ Node.js version: $(node -v)"
echo "✅ NPM version: $(npm -v)"

# Install build essentials
echo ""
echo "📦 Step 3/8: Installing build essentials..."
sudo apt-get install -y build-essential git curl

# Install PM2 globally
echo ""
echo "📦 Step 4/8: Installing PM2..."
sudo npm install -g pm2

echo "✅ PM2 version: $(pm2 -v)"

# Setup firewall
echo ""
echo "🔒 Step 5/8: Setting up firewall..."
sudo ufw allow OpenSSH
sudo ufw allow 3001/tcp  # Backend API port
sudo ufw --force enable
echo "✅ Firewall configured (SSH and port 3001)"

# Create directories
echo ""
echo "📁 Step 6/8: Creating directories..."
sudo mkdir -p /var/www
cd /var/www

# Ask for GitHub repository URL
echo ""
echo "📥 Step 7/8: Setting up repository..."
read -p "Enter your GitHub repository URL (e.g., https://github.com/username/inventory-server.git): " REPO_URL

# Clone repository
if [ ! -d "inventory-backend/.git" ]; then
    echo "Cloning repository..."
    git clone "$REPO_URL" inventory-backend
else
    echo "Repository already exists, pulling latest changes..."
    cd inventory-backend
    git pull origin main
    cd /var/www
fi

cd inventory-backend

# Install backend dependencies
echo ""
echo "📦 Installing backend dependencies..."
npm install

# Install Playwright browsers
echo ""
echo "🌐 Installing Playwright browsers (this may take a few minutes)..."
npx playwright install chromium --with-deps

# Setup environment file
echo ""
echo "⚙️  Step 8/8: Setting up environment configuration..."
if [ ! -f ".env" ]; then
    echo "Creating .env file..."
    cat > .env << 'EOF'
# Server Configuration
PORT=3001
NODE_ENV=production

# Database Configuration
MONGODB_URI=your_mongodb_uri_here

# JWT Configuration
JWT_SECRET=your_secure_jwt_secret_here
JWT_EXPIRES_IN=24h

# GoAudits Configuration
GOAUDITS_API_BASE_URL=https://api.goaudits.com
GOAUDITS_BASE_URL=https://admin.goaudits.com
GOAUDITS_EMAIL=your_goaudits_email
GOAUDITS_PASSWORD=your_goaudits_password

# Browser Automation
HEADLESS=true
BROWSER_TIMEOUT=60000

# Email Configuration (optional)
EMAIL_PROVIDER=smtp
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email
SMTP_PASSWORD=your_password

EOF
    echo "⚠️  .env file created with template values"
    echo "⚠️  IMPORTANT: Edit /var/www/inventory-backend/.env with your actual credentials"
else
    echo "✅ .env file already exists"
fi

# Start backend with PM2
echo ""
echo "🚀 Starting backend with PM2..."
pm2 start src/server.js --name "inventory-backend"

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
echo ""
echo "🔧 Setting up PM2 to start on boot..."
pm2 startup | tail -n 1 | sudo bash

# Setup log rotation for PM2
echo ""
echo "📝 Setting up log rotation..."
pm2 install pm2-logrotate
pm2 set pm2-logrotate:max_size 10M
pm2 set pm2-logrotate:retain 7

# Print status
echo ""
echo "================================"
echo "✅ Setup Complete!"
echo "================================"
echo ""
echo "📊 PM2 Status:"
pm2 status
echo ""
echo "🔑 Next Steps:"
echo "================================"
echo "1. Edit environment file:"
echo "   nano /var/www/inventory-backend/.env"
echo ""
echo "2. Restart backend after updating .env:"
echo "   pm2 restart inventory-backend"
echo ""
echo "3. Add GitHub Secrets for CI/CD:"
echo "   - DO_HOST (this server's IP: $(curl -s ifconfig.me))"
echo "   - DO_USERNAME (root)"
echo "   - DO_SSH_KEY (your private SSH key)"
echo ""
echo "4. Push code to trigger automatic deployment"
echo ""
echo "📝 Useful Commands:"
echo "================================"
echo "- View logs:        pm2 logs inventory-backend"
echo "- Restart:          pm2 restart inventory-backend"
echo "- Stop:             pm2 stop inventory-backend"
echo "- Status:           pm2 status"
echo "- Monitor:          pm2 monit"
echo ""
echo "🌐 Backend will be available at:"
echo "   http://$(curl -s ifconfig.me):3001"
echo ""
echo "📖 Full documentation:"
echo "   See .github/DEPLOYMENT.md in your repository"
echo ""

# Placeholder for SSL certificates
# These will be replaced with actual certificates from Cloudflare or Let's Encrypt

# For development/testing, you can generate self-signed certificates:
# openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout key.pem -out cert.pem

# For production, use Cloudflare Origin Certificates or Let's Encrypt:
# - Cloudflare: Generate origin certificate from Cloudflare dashboard
# - Let's Encrypt: Use certbot or similar ACME client

# Certificate files expected:
# - cert.pem: SSL certificate
# - key.pem: Private key

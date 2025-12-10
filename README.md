# agent-init


## Getting Started

create an `.env` file with the following details in your current directory

This will be moved into the `/opt/techtoday-agent`

```
FRONTEND_DOMAIN=http://localhost:5173
API_URL=http://localhost:5000
#postgresql 
POSTGRES_USER=bob
POSTGRES_PASSWORD=secret
# Mail
MAIL_USERNAME=
MAIL_PASSWORD=
# WhatsApp Integration
WHATSAPP_ACCESS_TOKEN= 
WEBHOOK_VERIFY_TOKEN=
# Google Authentication
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
# AI/LLM Configuration
OPENAI_API_KEY=
AI_NAME=Shani
# Authentication & API Tokens
ADMIN_EMAIL=
DAILY_REPORT_SECRET=secret
# API key for currency information from data.fixer.io
CURRENCY_API_KEY=
PORTAL_API_TOKEN=
LICENSE_KEY=
CONTROL_URL=
CREDIT_CONTROL=False
#github
GITHUB_USERNAME=
GITHUB_PAT=
```

Init for Agent docekr images

`bash -c "$(curl -fsSL https://raw.githubusercontent.com/Skulldorom/agent-init/refs/heads/main/init.sh)"`


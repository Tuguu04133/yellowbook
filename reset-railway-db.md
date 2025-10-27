# Railway Database Migration Fix

The issue is that we have a failed migration with SQLite syntax in a PostgreSQL database.

## Solution: Reset the Railway Database

You need to access Railway and run these commands:

### Option 1: Using Railway CLI (Recommended)

```bash
# Install Railway CLI if not already installed
npm i -g @railway/cli

# Login to Railway
railway login

# Link to your project
railway link

# Connect to the database and reset
railway run npx prisma migrate reset --force
```

### Option 2: Using Railway Dashboard

1. Go to Railway Dashboard: https://railway.app/dashboard
2. Select your project
3. Go to the PostgreSQL database service
4. Click on "Connect" tab and get the connection details
5. In your local terminal, set the DATABASE_URL temporarily:

```powershell
$env:DATABASE_URL="postgresql://postgres:[password]@[host]:[port]/railway"
npx prisma migrate reset --force
```

### Option 3: Nuclear Option - Delete and Recreate

If the above doesn't work:

1. Go to Railway Dashboard
2. Delete the PostgreSQL service
3. Create a new PostgreSQL database
4. Update the DATABASE_URL variable in your API service
5. Redeploy

The new migration files we create will be PostgreSQL-compatible.

## After Reset

Once the database is reset, commit and push the new migration:

```powershell
git add prisma/migrations
git commit -m "feat: recreate migrations for PostgreSQL"
git push origin main
```

Railway will automatically redeploy with the correct migrations.

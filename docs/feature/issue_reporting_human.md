# Issue Reporting Feature - Setup Guide

## What You Need to Do

### 1. Get OpenAI API Key

1. Go to [platform.openai.com](https://platform.openai.com)
2. Sign up or log in
3. Navigate to API Keys section
4. Create a new API key
5. Copy the key (save it somewhere safe - you won't see it again!)

### 2. Set Environment Variable

**For Local Development:**
```bash
export OPENAI_API_KEY="your-api-key-here"
```

Add this to your shell profile (`~/.zshrc` or `~/.bashrc`) to persist.

**For Production (Fly.io):**
```bash
fly secrets set OPENAI_API_KEY="your-api-key-here"
```

### 3. Run Database Migration

**Local:**
```bash~
mix ecto.migrate
```

**Production:**
```bash
fly ssh console
/app/bin/boiler eval "Boiler.Release.migrate"
exit
```

Or deploy (migration runs automatically):
```bash
fly deploy
```

### 4. Test the Feature

1. **Start server locally:**
   ```bash
   mix phx.server
   ```

2. **Submit an issue:**
   - Log in as any user
   - Visit: [http://localhost:4000/issues/new](http://localhost:4000/issues/new)
   - Enter feedback (minimum 10 characters)
   - Submit

3. **Use AI analysis (admin only):**
   - Log in as admin user
   - Visit: [http://localhost:4000/admin/issues](http://localhost:4000/admin/issues)
   - Try a suggested prompt or ask: "Summarize recent issues"
   - Wait for AI response

### 5. Deploy to Production

```bash
git add .
git commit -m "Add issue reporting and AI analysis feature"
git push
fly deploy
```

## That's It!

The feature is now live. Users can submit feedback at `/issues/new` and admins can analyze it at `/admin/issues`.

## Monitoring Costs

- Check your OpenAI usage at [platform.openai.com/usage](https://platform.openai.com/usage)
- Each AI query sends ~50 recent issues as context
- Uses GPT-4o-mini (cheaper model)
- Consider setting up usage alerts in OpenAI dashboard

## Troubleshooting

**"OpenAI API key not configured" error:**
- Ensure `OPENAI_API_KEY` environment variable is set
- Restart server after setting env var

**Migration fails:**
- Check database connection
- Run `mix ecto.reset` to reset database (WARNING: loses data)

**Can't access admin page:**
- Ensure logged in as admin user
- Check seeds ran: `mix run priv/repo/seeds.exs`

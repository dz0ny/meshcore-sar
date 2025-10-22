# Cloudflare R2 Setup for CI/CD

This document describes how to configure Cloudflare R2 for automatic artifact uploads from GitHub Actions.

## Overview

The CI/CD pipeline uploads build artifacts (APK, AAB, DMG, Windows ZIP) to a Cloudflare R2 bucket in the `unstable/` directory for every successful build. This provides:

- **Automatic artifact hosting** for all branches and commits
- **Version tracking** with timestamps and commit hashes
- **Public download URLs** (optional) for testers and developers
- **Build manifests** with metadata for each build

## Required GitHub Secrets

Configure these secrets in your GitHub repository settings (`Settings` → `Secrets and variables` → `Actions`):

### Required Secrets

| Secret Name | Description | How to Obtain |
|-------------|-------------|---------------|
| `R2_ACCOUNT_ID` | Your Cloudflare account ID | Cloudflare Dashboard → R2 → Overview (right sidebar) |
| `R2_ACCESS_KEY_ID` | R2 API token access key ID | Cloudflare Dashboard → R2 → Manage R2 API Tokens → Create API Token |
| `R2_SECRET_ACCESS_KEY` | R2 API token secret key | Generated when creating the API token (save immediately!) |
| `R2_BUCKET_NAME` | Name of your R2 bucket | Example: `meshcore-sar-builds` |

### Optional Secrets

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `R2_PUBLIC_URL` | Public URL for R2 bucket (if public access configured) | `https://meshcore-sar.dz0ny.dev` |

## Step-by-Step Setup

### 1. Create Cloudflare R2 Bucket

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Navigate to **R2** in the left sidebar
3. Click **Create Bucket**
4. Enter bucket name (e.g., `meshcore-sar-builds`)
5. Choose a location (e.g., `Automatic` or `ENAM` for Europe/North America)
6. Click **Create Bucket**

### 2. Create R2 API Token

1. In Cloudflare Dashboard, go to **R2** → **Manage R2 API Tokens**
2. Click **Create API Token**
3. Configure the token:
   - **Token name**: `github-actions-upload`
   - **Permissions**: Select **Object Read & Write**
   - **Bucket scope**:
     - Choose **Apply to specific buckets only**
     - Select your bucket (e.g., `meshcore-sar-builds`)
4. Click **Create API Token**
5. **IMPORTANT**: Copy both the **Access Key ID** and **Secret Access Key** immediately
   - The secret key will only be shown once!
   - Save them securely (e.g., password manager)

### 3. Get Your Account ID

1. In Cloudflare Dashboard, go to **R2** → **Overview**
2. Your Account ID is displayed in the right sidebar
3. Copy the Account ID

### 4. Configure GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** for each of the following:

   **R2_ACCOUNT_ID**:
   ```
   Paste your Cloudflare Account ID
   ```

   **R2_ACCESS_KEY_ID**:
   ```
   Paste the Access Key ID from step 2
   ```

   **R2_SECRET_ACCESS_KEY**:
   ```
   Paste the Secret Access Key from step 2
   ```

   **R2_BUCKET_NAME**:
   ```
   meshcore-sar-builds
   ```

### 5. (Optional) Configure Public Access

To enable public downloads from your R2 bucket:

#### Option A: Custom Domain (Recommended)

1. In Cloudflare Dashboard, go to **R2** → **Settings** for your bucket
2. Under **Public Access**, click **Connect Domain**
3. Enter your custom domain (e.g., `builds.meshcore.example.com`)
4. Follow Cloudflare's instructions to configure DNS
5. Add GitHub secret:
   ```
   R2_PUBLIC_URL = https://builds.meshcore.example.com
   ```

#### Option B: R2.dev Subdomain (Quick Setup)

1. In Cloudflare Dashboard, go to **R2** → **Settings** for your bucket
2. Under **Public Access**, click **Allow Access**
3. Enable **R2.dev subdomain**
4. Copy the generated URL (e.g., `https://pub-xxxxx.r2.dev`)
5. Add GitHub secret:
   ```
   R2_PUBLIC_URL = https://pub-xxxxx.r2.dev
   ```

**Note**: Without `R2_PUBLIC_URL` configured, artifacts will still upload successfully but download URLs won't be generated.

## Artifact Structure

Artifacts are uploaded with the following structure:

```
unstable/
├── main-abc1234/                          # Branch + commit hash
│   ├── meshcore-sar-main-abc1234-20241022-143022.apk
│   ├── meshcore-sar-main-abc1234-20241022-143022.aab
│   ├── meshcore-sar-main-abc1234-20241022-143022.dmg
│   ├── meshcore-sar-main-abc1234-20241022-143022-windows.zip
│   └── manifest.json
├── v1.2.3/                                # Release tag
│   ├── meshcore-sar-v1.2.3-20241022-150045.apk
│   ├── meshcore-sar-v1.2.3-20241022-150045.aab
│   ├── meshcore-sar-v1.2.3-20241022-150045.dmg
│   ├── meshcore-sar-v1.2.3-20241022-150045-windows.zip
│   └── manifest.json
└── develop-def5678/
    └── ...
```

### Manifest Example

Each build includes a `manifest.json` file:

```json
{
  "build_id": "main-abc1234-20241022-143022",
  "commit": "abc1234567890abcdef1234567890abcdef12345",
  "commit_short": "abc1234",
  "branch": "main",
  "tag": "",
  "timestamp": "20241022-143022",
  "workflow_run": "123",
  "artifacts": [
    "meshcore-sar-main-abc1234-20241022-143022.apk",
    "meshcore-sar-main-abc1234-20241022-143022.aab",
    "meshcore-sar-main-abc1234-20241022-143022.dmg",
    "meshcore-sar-main-abc1234-20241022-143022-windows.zip"
  ]
}
```

## Testing the Setup

1. Push a commit to your repository (or re-run an existing workflow)
2. Navigate to **Actions** tab in GitHub
3. Click on the running workflow
4. Wait for all build jobs to complete
5. Check the **Upload to Cloudflare R2** job:
   - Should show "✅ Artifacts uploaded to R2 bucket"
   - If `R2_PUBLIC_URL` is configured, download links will appear in the job summary
6. Verify in Cloudflare Dashboard:
   - Go to **R2** → Your bucket
   - Navigate to `unstable/` directory
   - You should see your build artifacts

## Troubleshooting

### "Invalid credentials" error

- **Solution**: Verify `R2_ACCESS_KEY_ID` and `R2_SECRET_ACCESS_KEY` are correct
- Regenerate API token if needed (remember to update secrets)

### "Bucket not found" error

- **Solution**: Check `R2_BUCKET_NAME` matches exactly (case-sensitive)
- Verify the bucket exists in your Cloudflare R2 dashboard

### "Permission denied" error

- **Solution**: Ensure API token has **Object Read & Write** permissions
- Verify token scope includes the specific bucket

### Artifacts not visible in R2

- **Solution**: Check workflow logs for upload errors
- Verify at least one build job completed successfully
- Check bucket permissions and CORS settings if accessing via browser

### Download URLs not showing

- **Solution**: This is normal if `R2_PUBLIC_URL` secret is not configured
- Artifacts are uploaded successfully even without public URLs
- Configure public access (see step 5) to enable download links

## Security Best Practices

1. **Never commit secrets** to your repository
2. Use **specific bucket scopes** for API tokens (not account-wide)
3. **Rotate API tokens** periodically (e.g., every 90 days)
4. **Limit public access** if artifacts contain sensitive data
5. Set up **bucket lifecycle rules** to auto-delete old unstable builds
6. Use **custom domains** instead of R2.dev subdomains for production

## Cost Considerations

Cloudflare R2 pricing (as of 2024):

- **Storage**: $0.015/GB per month
- **Operations**:
  - Class A (write): $4.50 per million requests
  - Class B (read): $0.36 per million requests
- **Egress**: **Free** (no bandwidth charges)

For typical usage:
- ~100 builds/month × 4 platforms × ~100MB = ~40GB storage
- Monthly cost: ~$0.60 + minimal operation costs

**Tip**: Set up lifecycle rules to automatically delete builds older than 30 days to minimize storage costs.

## Additional Resources

- [Cloudflare R2 Documentation](https://developers.cloudflare.com/r2/)
- [R2 API Documentation](https://developers.cloudflare.com/r2/api/s3/)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [ryand56/r2-upload-action](https://github.com/ryand56/r2-upload-action)

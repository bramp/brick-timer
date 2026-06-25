# GitHub Actions: Firebase Deploy with Workload Identity Federation

This directory contains CI/CD workflows.

This document explains how to configure Google Cloud Workload Identity Federation (WIF)
for GitHub Actions so deployments can run without long-lived `FIREBASE_TOKEN` secrets.

## What this config does

- Creates a Google Cloud service account for deployment.
- Creates a Workload Identity Pool and GitHub OIDC provider.
- Restricts trust to this repo and the `main` branch.
- Lets GitHub Actions impersonate the deploy service account.
- Uses `google-github-actions/auth` in workflow instead of Firebase token auth.

## Prerequisites

- `gcloud` CLI installed and authenticated as a project admin.
- A Firebase project already linked to your Google Cloud project.
- GitHub repository admin access to set repository or environment variables.

## Variables

Set these in your shell before running commands:

```bash
export GCP_PROJECT_ID="your-project-id"
export GITHUB_OWNER="your-github-owner"
export GITHUB_REPO="your-repo"

# Names (change if desired)
export WIF_POOL_ID="github-pool"
export WIF_PROVIDER_ID="github-provider"
export GCP_DEPLOY_SA_ID="github-firebase-deployer"

export GCP_PROJECT_NUMBER="$(gcloud projects describe "$GCP_PROJECT_ID" --format='value(projectNumber)')"
export GCP_DEPLOY_SA="${GCP_DEPLOY_SA_ID}@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
```

## 1) Enable required APIs

```bash
gcloud services enable \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  cloudresourcemanager.googleapis.com \
  sts.googleapis.com \
  cloudfunctions.googleapis.com \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com \
  firebase.googleapis.com \
  firebaseextensions.googleapis.com \
  --project="$GCP_PROJECT_ID"
```

## 2) Create deploy service account

```bash
gcloud iam service-accounts create "$GCP_DEPLOY_SA_ID" \
  --display-name="GitHub Actions Firebase Deployer" \
  --project="$GCP_PROJECT_ID"
```

## 3) Grant deploy permissions

Start with least privilege, then add roles only if deployment errors indicate they are needed.

```bash
gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
  --member="serviceAccount:${GCP_DEPLOY_SA}" \
  --role="roles/cloudfunctions.developer"

gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
  --member="serviceAccount:${GCP_DEPLOY_SA}" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
  --member="serviceAccount:${GCP_DEPLOY_SA}" \
  --role="roles/cloudbuild.builds.editor"

gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
  --member="serviceAccount:${GCP_DEPLOY_SA}" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
  --member="serviceAccount:${GCP_DEPLOY_SA}" \
  --role="roles/iam.serviceAccountUser"
```

Optional, add only if needed:

```bash
# If Firebase CLI calls fail with Firebase resource permission errors:
gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
  --member="serviceAccount:${GCP_DEPLOY_SA}" \
  --role="roles/firebase.developAdmin"

# If secret access during deploy/runtime setup is denied:
gcloud projects add-iam-policy-binding "$GCP_PROJECT_ID" \
  --member="serviceAccount:${GCP_DEPLOY_SA}" \
  --role="roles/secretmanager.admin"
```

## 4) Create Workload Identity Pool

```bash
gcloud iam workload-identity-pools create "$WIF_POOL_ID" \
  --location="global" \
  --display-name="GitHub Actions Pool" \
  --project="$GCP_PROJECT_ID"
```

## 5) Create GitHub OIDC provider

This condition limits tokens to this repo and `main` branch.

```bash
gcloud iam workload-identity-pools providers create-oidc "$WIF_PROVIDER_ID" \
  --location="global" \
  --workload-identity-pool="$WIF_POOL_ID" \
  --display-name="GitHub OIDC Provider" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.ref=assertion.ref" \
  --attribute-condition="assertion.repository=='${GITHUB_OWNER}/${GITHUB_REPO}' && assertion.ref=='refs/heads/main'" \
  --project="$GCP_PROJECT_ID"
```

## 6) Allow repo identities to impersonate deploy SA

```bash
gcloud iam service-accounts add-iam-policy-binding "$GCP_DEPLOY_SA" \
  --project="$GCP_PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${GCP_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${WIF_POOL_ID}/attribute.repository/${GITHUB_OWNER}/${GITHUB_REPO}"
```

## 7) Get the provider resource name

Save this exact output as a GitHub variable.

```bash
gcloud iam workload-identity-pools providers describe "$WIF_PROVIDER_ID" \
  --location="global" \
  --workload-identity-pool="$WIF_POOL_ID" \
  --project="$GCP_PROJECT_ID" \
  --format="value(name)"
```

Expected format:

```text
projects/123456789/locations/global/workloadIdentityPools/github-pool/providers/github-provider
```

## 8) Add GitHub variables

In GitHub, add the following repository or environment variables:

- `GCP_PROJECT_ID`: your project id
- `GCP_WIF_PROVIDER`: provider resource name from step 7
- `GCP_DEPLOY_SA`: deploy service account email (example: `github-firebase-deployer@your-project-id.iam.gserviceaccount.com`)

## 9) Workflow requirements

For WIF to work, the deploy job must include:

- `permissions.id-token: write`
- An auth step using `google-github-actions/auth@v2`

This repository's deploy workflow is already wired for those variables in `.github/workflows/deploy.yml`.

## Troubleshooting

- Error: "insufficient permission to generate access token"
  - Ensure step 6 (`roles/iam.workloadIdentityUser`) succeeded for the correct pool/provider/repo.
- Error: "permission denied" on deploy
  - Confirm deploy service account roles in step 3.
- Error: OIDC token not available
  - Ensure the job has `permissions: id-token: write`.

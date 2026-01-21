# Deploy Environments

We need to understand where and how the project is deployed.

## What to Clarify

- **Environments** - What environments exist? (local, dev, staging, production, etc.)
- **Hosting** - Where is each environment hosted? (AWS, GCP, Vercel, self-hosted, etc.)
- **Deployment method** - How do you deploy? (CI/CD, manual, scripts, etc.)

## Optional

- **URLs** - What are the URLs for each environment?
- **SSH access** - Do you have SSH access to servers? What are the hostnames?
- **Container** - Is it containerized? (Docker, Kubernetes, etc.)
- **Infrastructure as code** - Terraform, Pulumi, CloudFormation?
- **Secrets** - How are secrets managed per environment?
- **Feature flags** - Do you use feature flags?

## Examples

**Good environments answer:**
> We have three environments:
> - local for development
> - staging at staging.example.com for testing
> - production at app.example.com

**Good hosting answer:**
> Frontend on Vercel, backend on AWS ECS, database on RDS

**Good deployment answer:**
> GitHub Actions deploys to staging on merge to main, production requires manual approval

**Good SSH access answer:**
> SSH to staging: deploy@staging.example.com
> SSH to production: deploy@prod.example.com (port 2222)

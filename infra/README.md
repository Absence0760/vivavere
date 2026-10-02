# infra/

Terraform for the Vivavere AWS account. Scope today:

| File | What |
|---|---|
| `domain.tf` | `vivavere.com` registration settings: auto-renew, transfer lock, WHOIS privacy, name servers pinned to the zone |
| `email.tf` | Migadu mail DNS: MX, SPF + ownership TXT, DKIM, autoconfig/SRV hints, DMARC |
| `budgets.tf` | Account-wide monthly budget with email alerts |
| `tests/` | Plan-only `terraform test` against mocked providers (no credentials) |

Operator config is **not** in this public repo. The canonical tfvars is
`~/github/infra-secrets/vivavere/prod.tfvars`.

## Bring-up, in order

### 1. Account (once)

From `~/github/templates` on `main`, after `aws sso login --profile mgmt`:

```
./scripts/new-project-account.sh vivavere --plan && ./scripts/new-project-account.sh vivavere
```

It reads `infra-secrets/vivavere/bootstrap.tfvars`, which must be committed and
pushed first. Then assign yourself `AdministratorAccess` on the new account in
Identity Center and run `aws configure sso --profile vivavere`.

### 2. Domain (console, once)

Signed in to the **Vivavere** account: Route 53 → Registered domains → Register
`vivavere.com` — one year, auto-renew on, privacy protection on. The
registration creates the `vivavere.com` public hosted zone. Wait until the
registration shows as complete (usually minutes, sometimes hours) before
applying, because `domain.tf` reads that zone.

Terraform doesn't register the domain itself: that would need the registrant's
contact details as config, and a resource that owns the registration could
deregister it on a destroy.

### 3. Migadu

admin.migadu.com → Domains → Add `vivavere.com` in the estate's existing
account. Copy the token from its DNS page (the part after
`hosted-email-verify=`) into `infra-secrets/vivavere/prod.tfvars` as
`migadu_verification_token`. It isn't secret, since it ends up in public DNS.

### 4. Apply

```
cd ~/github/vivavere/infra && printf 'bucket = "vivavere-tfstate-%s"\n' "$(aws sts get-caller-identity --profile vivavere --query Account --output text)" > backend.config && AWS_PROFILE=vivavere terraform init -backend-config=backend.config
```

```
AWS_PROFILE=vivavere terraform plan -var-file=../../infra-secrets/vivavere/prod.tfvars -out=tfplan && AWS_PROFILE=vivavere terraform apply tfplan
```

### 5. Finish in Migadu

Run its DNS check, then create the `contact@vivavere.com` mailbox (add aliases
the same way). Once a few days of DMARC reports show Migadu aligning, raise
`dmarc_policy` to `quarantine`, then `reject`.

## Status

Steps 1–4 done 2026-10-01: account `Vivavere` created, `vivavere.com`
registered (renews 2027-10-01), mail DNS applied.

- [x] Migadu DNS check passed
- [x] `koa@vivavere.com` mailbox created
- [ ] `contact@vivavere.com` mailbox — DMARC reports go here, so they're lost until it exists
- [ ] Point `admin@`, `postmaster@`, `abuse@` at `contact@`
- [ ] Round-trip test: Gmail → `koa@` → reply lands in Gmail's inbox, not spam
- [ ] After a week or two of clean DMARC reports: `dmarc_policy = "quarantine"` in `infra-secrets/vivavere/prod.tfvars`, plan, apply

## Local validation (no credentials)

```
cd infra && terraform init -backend=false && terraform fmt -check -recursive && terraform validate && terraform test
```

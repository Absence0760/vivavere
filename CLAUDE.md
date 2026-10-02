# Vivavere

Public repo. Today it only owns the `vivavere.com` domain settings and Migadu
mail DNS (`infra/`). No app or website yet.

- **Never commit secrets or operator config here.** Filled `*.tfvars`,
  `backend.config` (embeds the AWS account ID) and any `*.sops*` file are
  gitignored. The canonical copies live in `~/github/infra-secrets/vivavere/`.
- AWS account `Vivavere` (slug `vivavere`, SSO profile `vivavere`), created
  in-org by `~/github/templates/scripts/new-project-account.sh vivavere` with
  `create_subdomain = false` — it owns `vivavere.com` itself.
- The domain is registered by hand in the Route 53 console, never by Terraform
  (`infra/domain.tf` explains why).
- Mail runs on the estate's shared Migadu account. Only Migadu sends today, so
  the apex SPF authorizes Migadu alone.
- Before changing infra: `cd infra && terraform fmt -check && terraform validate && terraform test`.

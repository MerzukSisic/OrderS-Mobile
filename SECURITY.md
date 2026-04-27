# Security Policy

OrderS is a student project for Razvoj softvera II. Do not commit `.env`
files, private keys, connection strings, JWT secrets, Stripe secret keys, or
other credentials to the repository.

## Supported Version

Only the current academic-year submission is maintained.

## Sensitive Configuration

Runtime configuration is supplied through `--dart-define` values or an ignored
local `.env` file. For submission, sensitive configuration should be packed in
the password-protected environment ZIP archive described in `README.md`.

## Reporting

Security issues should be reported directly to the project author before public
disclosure.

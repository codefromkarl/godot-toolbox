# Security Policy

## Reporting a Vulnerability

**Do not file a public GitHub issue for security vulnerabilities.**

Instead, please report security issues using
[GitHub Security Advisories](https://github.com/codefromkarl/godot-toolbox/security/advisories/new).

This allows us to assess the issue and coordinate a fix before public disclosure.

## Response Timeline

| Stage | Target |
|-------|--------|
| Acknowledgment | Within 48 hours |
| Initial assessment | Within 7 days |
| Fix or mitigation | Depends on severity and complexity |

## Scope

This policy covers:

- Vulnerabilities in the toolbox bootstrap scripts, manifest system, and
  verification pipeline
- Security issues in vendored third-party plugins (we will coordinate with
  upstream maintainers)
- Supply chain concerns related to `upstreams.lock.json` pinning integrity

## Out of Scope

- Godot Engine vulnerabilities (report to the [Godot project](https://github.com/godotengine/godot/security))
- Vulnerabilities in third-party plugins not vendored by this repository

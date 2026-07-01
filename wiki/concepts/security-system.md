---
tags: [концепция, security, authentication, authorization, voters]
date: 2026-06-25
sources: [raw/corrected/SRC-2026-06-25-SYMFONY-001/symfony-comprehensive-knowledge.md]
related: [wiki/entities/symfony.md]
---

# Security System (AuthN & AuthZ)

## Определение

Symfony Security — comprehensive security system для web applications, включающий аутентификацию (кто пользователь) и авторизацию (что может делать). SecurityBundle предоставляет authentication providers, authorization voters, firewalls, password hashing. CSRF protection и secure session cookies включены по умолчанию.

## Authentication Providers

### Built-in Providers
| Provider | Описание |
|----------|----------|
| **Form Login** | Standard username/password form authentication |
| **API Token** | Token-based auth for API endpoints |
| **LDAP** | Directory service authentication |
| **Entity** (Doctrine) | Loads users from database via Doctrine entities |
| **Memory** | Users defined in config files |
| **Chain** | Combines multiple providers into single flow |

### Custom Authentication Providers
Symfony позволяет создавать custom auth providers через `AuthenticatorInterface` для proprietary SSO or legacy systems.

## Authorization (Voters)

### Voter Pattern
Custom voters implement authorization logic:
```php
class CommentVoter extends Voter {
    protected function supports(object $subject, mixed $attribute): bool { ... }
    
    protected function voteOnAuthorize(
        string $attribute, 
        mixed $subject, 
        TokenInterface $token
    ): Vote { /* return VOTE_ALLOW / VOTE_DENY / VOTE_ABSTAIN */ }
}
```

### Decision Strategies
| Strategy | Описание |
|----------|----------|
| **Affirmative** (default) | Grant if ≥1 voter grants access |
| **Consensus** | Grant if more voters grant than deny |
| **Unanimous** | All non-abstain voters must agree to grant |
| **Priority** | First matching voter wins |

### Usage Patterns
- `$this->isGranted('ROLE_ADMIN')` — check permission in controllers/services
- `#[Security('ROLE_ADMIN')]` — attribute-based access control on controller methods
- Custom Voters для complex security logic (не рекомендуется использовать длинные expressions в `#[Security]`)

## Firewall Configuration
```yaml
# Recommended: Single firewall unless multiple auth systems needed
security:
  firewalls:
    main:
      pattern: ^/
      # authentication providers, form login, etc.
```

### Password Hashing
- Auto-selects best available hasher — `bcrypt` default as of 2026
- Configured via `password_hashers:` in security config
- `auto` hasher uses PHP's native password_hash() function

## Лучшие практики

1. **Single firewall** — unless genuinely different auth systems (e.g., form login for site + token for API)
2. **Custom Voters** для complex permission logic instead of long expressions
3. **Entity User Provider** с Doctrine для persistence in database
4. **CSRF protection** built-in for forms — no extra config needed

## Связи
- [Symfony Entity](entities/symfony.md) — SecurityBundle интегрирован в core фреймворка
- [Doctrine ORM](concepts/doctrine-orm.md) — Entity User Provider использует Doctrine entities

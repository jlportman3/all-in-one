# Contributing to Nextcloud All-in-One

We welcome contributions to improve the project! This short guide covers the basics for getting a development environment running.

## Setup
1. Clone the repository and install PHP dependencies:
   ```bash
   cd php
   composer install
   ```
2. Start the development server. This also requires a running `nextcloud-aio-mastercontainer` as described in `php/README.md`:
   ```bash
   SKIP_DOMAIN_VALIDATION=true composer run dev
   ```
   The web interface will be available at `http://localhost:8080`.

## Development checks
When you modify code in the `php` directory, please run the following commands before committing:

```bash
composer run lint        # PHP syntax checks
composer run lint:twig   # Twig template linting
composer run psalm       # Static analysis
composer run psalm:strict
composer run php-deprecation-detector
```

These scripts help keep the code base consistent and free of obvious issues.

## Manual testing
Automated tests are not provided, but manual QA plans are available under [`tests/QA`](./tests/QA). Follow these documents to verify that the application behaves as expected.

## Questions
If you encounter problems or have questions about contributing, open an issue on GitHub.

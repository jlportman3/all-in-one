# AGENT Instructions for `all-in-one`

This repository contains the source for **Nextcloud All-in-One**, a Docker-based deployment of Nextcloud with multiple optional services. The code is a mix of PHP, shell scripts and Dockerfiles.

## Repository layout
- `compose.yaml` defines the master container and its default ports.
- `Containers/` includes Dockerfiles and scripts for each service.
- `php/` is the PHP controller application. `composer.json` lists dev scripts for linting and static analysis.
- `app/` contains a Nextcloud app used inside the Nextcloud container.
- `community-containers/` holds optional container definitions.

## Getting started
1. Install dependencies: `composer install` inside the `php` directory.
2. For local development, run the master container as described in `php/README.md` and start the PHP server with:
   ```bash
   SKIP_DOMAIN_VALIDATION=true composer run dev
   ```
3. The web interface becomes available on `http://localhost:8080`.

## Useful Composer scripts
- `composer run lint` – PHP syntax checks.
- `composer run lint:twig` – Twig template linting.
- `composer run psalm` – Static analysis.
- `composer run psalm:strict` – Strict static analysis.
- `composer run php-deprecation-detector` – Scan for deprecated PHP usage.

Run these scripts before committing changes to the PHP controller.

## Notes
- The Dockerfiles fetch external resources with `curl`/`wget`. For offline environments you may need to mirror these dependencies.
- Several scripts alter file permissions broadly (e.g. `chmod 777`). Be cautious when modifying these areas.
- No automated test suite is defined in this repository, but manual QA plans are under `tests/QA`.

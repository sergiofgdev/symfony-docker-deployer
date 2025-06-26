# symfony-docker-deployer
 A production-ready boilerplate for Symfony applications featuring Docker, Deployer, PostgreSQL, and Tailwind CSS.

> **Note**
> This project is heavily inspired by and builds upon the fantastic work of the **[dunglas/symfony-docker](https://github.com/dunglas/symfony-docker)** project. Full credit and thanks to Kévin Dunglas and its contributors for providing the foundational, production-grade Docker setup for Symfony.

A production-ready boilerplate for Symfony applications featuring Docker, Deployer, PostgreSQL, and Tailwind CSS.

This boilerplate aims to provide a clean, robust, and minimally configured starting point for modern Symfony applications. It takes the power of a professional Docker setup and integrates `deployer/deployer` for seamless, automated deployments right out of the box.

All the necessary configuration files (`Dockerfile`, `deploy.php`, `compose.yaml`, `Caddyfile`, etc.) have been pre-configured and battle-tested to work together, saving you days of setup and debugging.

## Features

- **Symfony 7+**: The latest version of the Symfony framework.
- **Docker & Docker Compose**: Fully containerized development and production environments.
- **FrankenPHP**: A modern, high-performance PHP application server written in Go.
- **Deployer**: Automated, zero-downtime deployment script pre-configured for this stack.
- **PostgreSQL**: Ready for a robust and scalable database.
- **Tailwind CSS**: Integrated via the `symfonycasts/tailwind-bundle` for a modern utility-first CSS workflow.
- **GitHub Actions**: A clean CI workflow for linting your `Dockerfile`.

## Getting Started

This section outlines the steps to get the project running locally and to deploy it to a production server.

*(Note: This guide is a preliminary version. The exact steps will be finalized after a complete, clean deployment test from a fresh clone.)*

### Prerequisites

Make sure you have the following tools installed on your local machine:
- Git
- Docker & Docker Compose
- PHP (for running Deployer)
- Composer (for managing PHP dependencies)

### 1. Local Development Setup

1.  **Clone the repository:**
    ```bash
    git clone [https://github.com/sergiofgdev/symfony-docker-deployer.git](https://github.com/sergiofgdev/symfony-docker-deployer.git)
    cd symfony-docker-deployer
    ```

2.  **Create your local environment file:**
    Copy the distributed template to create your local environment file. This file is ignored by Git.
    ```bash
    cp .env.dist .env.local
    ```

3.  **Customize your local environment:**
    Open `.env.local` and fill in the `APP_SECRET` and `CADDY_MERCURE_JWT_SECRET` variables. You can leave the rest of the default values for a standard local setup.

4.  **Build and start the containers:**
    ```bash
    docker compose up --build -d
    ```

5.  **Access your application:**
    Your Symfony application should now be available at **[http://localhost](http://localhost)**.

### 2. Production Deployment

This boilerplate uses **Deployer** for automated deployments.

1.  **Prepare your production server:**
    - Ensure your server is accessible via SSH with key-based authentication.
    - Install Docker and Docker Compose on the server.
    - Make sure your deployment user (e.g., `sergio`) is part of the `docker` group to execute Docker commands without `sudo`.

2.  **Configure Deployer:**
    - Open the `deploy.php` file.
    - Update the `host()` configuration with your server's IP address, deployment user, and desired path.

3.  **Create the Production Environment File on the Server:**
    - SSH into your server.
    - Create the shared directory structure for Deployer: `mkdir -p /var/www/your-project/shared`.
    - Create the production environment file: `touch /var/www/your-project/shared/.env.prod.local`.
    - Copy the contents of your local `.env.dist` file into this new `.env.prod.local` file.
    - **Crucially, edit `.env.prod.local` on the server** to fill in your real production secrets (`APP_SECRET`, `CADDY_MERCURE_JWT_SECRET`) and a strong database password. If you have a domain, set `SERVER_NAME` to your domain name.

4.  **Run the Deployment:**
    - From your **local machine**, execute the deploy command:
    ```bash
    php vendor/bin/dep deploy
    ```

Deployer will connect to your server, clone the project, build the production Docker images, start the containers, and run the database migrations automatically.

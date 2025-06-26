<?php

namespace Deployer;

require 'recipe/symfony.php';

// =============================================================================
// Project Configuration
// =============================================================================
set('application', 'app_db');
set('repository', 'git@github.com:user/repository.git');
set('keep_releases', 3);
set('default_timeout', 600);
set('docker_project_name', 'project-name');
set('http_user', 'user');

// =============================================================================
// Host Configuration
// =============================================================================
host('project-name')
    ->set('hostname', 'host')
    ->set('remote_user', 'user')
    ->set('deploy_path', '/var/www/project-name');

// =============================================================================
// Shared Files & Directories
// =============================================================================

// Ensure the production environment file persists across deployments.
add('shared_files', ['.env.prod.local']);

// Ensure database and Caddy data are persisted outside of the release directory.
add('shared_dirs', ['docker/db/data', 'caddy_data', 'caddy_config']);

// =============================================================================
// Custom Docker Tasks
// =============================================================================

/**
 * Stops and removes all containers, networks, and volumes associated
 * with a previous deployment to prevent conflicts.
 */
task('docker:down', function () {
    run('docker compose -p {{docker_project_name}} down --remove-orphans');
})->desc('Stop and remove old containers');

/**
 * Pauses execution briefly to allow the operating system time
 * to release network ports before starting new containers.
 */
task('docker:sleep', function () {
    run('sleep 3');
})->desc('Wait for OS to free ports');

/**
 * Builds and starts the Docker containers for the production environment.
 */
task('docker:build_and_up', function () {
    run('cd {{release_or_current_path}} && docker compose -p {{docker_project_name}} -f compose.yaml -f compose.prod.yaml build --pull');
    run('cd {{release_or_current_path}} && docker compose -p {{docker_project_name}} --env-file .env.prod.local -f compose.yaml -f compose.prod.yaml up -d --wait');
})->desc('Build and start Docker containers');


/**
 * Executes Doctrine database migrations inside the running 'php' container.
 * This ensures the database schema is up-to-date with the new release.
 */
task('docker:migrate', function () {
    run('cd {{release_or_current_path}} && docker compose -p {{docker_project_name}} --env-file .env.prod.local -f compose.yaml -f compose.prod.yaml exec -T php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration');
})->desc('Run Doctrine migrations');


// =============================================================================
// Main Deployment Flow
// =============================================================================

/**
 * Defines the main deployment process.
 * This overrides the default 'deploy' task to create a Docker-centric workflow.
 */
task('deploy', [
    // From Deployer: Prepare directories, etc.
    'deploy:prepare',
    // From Deployer: Publish the new release (symlink).
    'deploy:publish',
    // Custom: Stop and remove old containers.
    'docker:down',
    // Custom: Wait for ports to be free.
    'docker:sleep',
    // Custom: Build and start new containers.
    'docker:build_and_up',
    // Custom: Run database migrations.
    'docker:migrate',
    // From Deployer: Unlock the deployment.
    'deploy:unlock',
    // From Deployer: Clean up old releases.
    'deploy:cleanup',
    // From Deployer: Display success message.
    'deploy:success'
])->desc('Deploy your project');

/**
 * Error Handling: If the deployment fails, unlock it to allow for another attempt.
 */
after('deploy:failed', 'deploy:unlock');

<?php
namespace Deployer;

require 'recipe/symfony.php';

// Config

set('repository', 'git@github.com:sergiofgdev/symfony-docker-deployer.git');

add('shared_files', []);
add('shared_dirs', []);
add('writable_dirs', []);

// Hosts

host('')
    ->set('remote_user', 'deployer')
    ->set('deploy_path', '~/symfony-docker-deployer');

// Hooks

after('deploy:failed', 'deploy:unlock');

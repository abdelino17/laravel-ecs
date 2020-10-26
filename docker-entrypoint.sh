#!/bin/sh

# Cache
php artisan route:cache --quiet
php artisan config:cache --quiet

# Permissions
# On Alpine Apache's user and groups are apache
chown -R apache:apache /var/www
chgrp -R apache /var/www/bootstrap/cache
chmod -R ug+rwx /var/www/bootstrap/cache

# Migrations
php artisan migrate --force

# Queue worker
php artisan queue:work --daemon &

# Launch the httpd in foreground
rm -rf /run/apache2/* || true && /usr/sbin/httpd -DFOREGROUND

#!/bin/bash

# 1. Instalar las dependencias de Composer
echo "Instalando dependencias de Composer..."
composer install --no-dev --optimize-autoloader

# 2. Instalar los assets
echo "Instalando assets..."
php bin/console assets:install --symlink

# 3. Compilar los assets
echo "Compilando los assets..."
npm install
npm run production

# 4. Limpiar la caché de Symfony y precargarla para producción
echo "Limpiando y precargando caché de Symfony..."
php bin/console cache:clear --env=prod --no-debug
php bin/console cache:warmup --env=prod

# 5. Ejecutar las migraciones de la base de datos
echo "Ejecutando migraciones de base de datos..."
php bin/console doctrine:migrations:migrate --no-interaction

# 6. Dar permisos de escritura a los directorios necesarios
echo "Configurando permisos de directorios..."
chmod -R 777 var/
chmod -R 777 public/

# 7. ¡Despliegue completado!
echo "Despliegue completado!"

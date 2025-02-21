# Uso una imagen base de Apache
FROM httpd:2.4

# Instala Node.js, PHP, Composer, MySQL Client, etc.
RUN apt-get update && \
    apt-get install -y \
    npm \
    nodejs \
    php \
    php-cli \
    php-mysql \
    php-curl \
    php-zip \
    unzip \
    curl \
    mariadb-client \
    vsftpd \
    lftp && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Instalar las dependencias de PHP en el servidor
WORKDIR /var/www/symfony
RUN composer install --no-dev --optimize-autoloader

# Instalar los assets
RUN php bin/console assets:install --symlink

# Compilar los assets
RUN npm install && \
    npm run production

# Limpiar la caché de Symfony y precargarla para producción
RUN php bin/console cache:clear --env=prod --no-debug && \
    php bin/console cache:warmup --env=prod

# Ejecutar las migraciones de la base de datos
RUN php bin/console doctrine:migrations:migrate --no-interaction

# Dar permisos de escritura a los directorios necesarios
RUN chmod -R 777 var/ && \
    chmod -R 777 public/

# Configuración de vsftpd (servidor FTP)
RUN echo "listen=YES" >> /etc/vsftpd.conf \
    && echo "listen_ipv6=NO" >> /etc/vsftpd.conf \
    && echo "anonymous_enable=NO" >> /etc/vsftpd.conf \
    && echo "local_enable=YES" >> /etc/vsftpd.conf \
    && echo "write_enable=YES" >> /etc/vsftpd.conf \
    && echo "chroot_local_user=YES" >> /etc/vsftpd.conf \
    && echo "listen_address=0.0.0.0" >> /etc/vsftpd.conf

# Crear usuario FTP
RUN useradd -m -d /var/www/symfony nerea \
    && echo "nerea:nerea" | chpasswd \
    && chown -R nerea:nerea /var/www/symfony

# Copio los certificados al directorio de Apache
COPY ./tf/certificate.crt /usr/local/apache2/conf/
COPY ./tf/ca_bundle.crt /usr/local/apache2/conf/
COPY ./tf/private.key /usr/local/apache2/conf/

# Copio mi configuración SSL personalizada
COPY ./tf/httpd-ssl.conf /usr/local/apache2/conf/extra/

# Habilito el módulo SSL
RUN apt-get update && apt-get install -y ssl-cert && \
    sed -i 's/#LoadModule ssl_module/LoadModule ssl_module/' /usr/local/apache2/conf/httpd.conf && \
    echo "Include /usr/local/apache2/conf/extra/httpd-ssl.conf" >> /usr/local/apache2/conf/httpd.conf

# Establece el directorio de trabajo para Symfony
WORKDIR /var/www/symfony

# Exponer los puertos necesarios
EXPOSE 80 443 21

# Iniciar Apache y vsftpd
CMD service vsftpd start && httpd-foreground

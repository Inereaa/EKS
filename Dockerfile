
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
    mariadb-client && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Instalar las dependencias de PHP en el servidor
RUN composer install --no-dev --optimize-autoloader

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

# Expongo los puertos necesarios
EXPOSE 80 443

# Instrucción por defecto
CMD ["httpd-foreground"]

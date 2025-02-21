
# Uso una imagen base de Apache
FROM httpd:2.4

# Instalo Node.js
RUN apt-get update && \
    apt-get install -y npm && \
    apt-get install -y nodejs

# Instalo PHP, Composer y MySQL Client
RUN apt-get update && apt-get install -y \
    php \
    php-cli \
    php-mysql \
    php-curl \
    php-zip \
    unzip \
    curl \
    mariadb-client \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copio los archivos de la página web al directorio de Apache
COPY ./index.html /usr/local/apache2/htdocs/
COPY ./mywall/ /usr/local/apache2/htdocs/mywall/

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

# Expongo los puertos necesarios
EXPOSE 80
EXPOSE 443

# Instrucción por defecto
CMD ["httpd-foreground"]

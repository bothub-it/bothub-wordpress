FROM romeoz/docker-phpfpm:5.6

ENV OS_LOCALE="en_US.UTF-8"
RUN apt-get update && apt-get install -y locales && locale-gen ${OS_LOCALE}
ENV LANG=${OS_LOCALE} \
    LANGUAGE=${OS_LOCALE} \
    LC_ALL=${OS_LOCALE} \
	NGINX_CONF_DIR=/etc/nginx

COPY ./supervisord.conf /etc/supervisor/conf.d/
COPY ./app /var/www/app/

RUN	\
	BUILD_DEPS='software-properties-common python-software-properties wget' \
    && dpkg-reconfigure locales \
	&& apt-get install --no-install-recommends -y $BUILD_DEPS \
    && wget -O - http://nginx.org/keys/nginx_signing.key | apt-key add - \
	&& echo "deb http://nginx.org/packages/ubuntu/ xenial nginx" | tee -a /etc/apt/sources.list \
	&& echo "deb-src http://nginx.org/packages/ubuntu/ xenial nginx" | tee -a /etc/apt/sources.list \
	&& apt-get update \
	&& apt-get install -y nginx \
	&& rm -rf  ${NGINX_CONF_DIR}/sites-enabled/* ${NGINX_CONF_DIR}/sites-available/* \
	# Install supervisor
	&& apt-get install -y supervisor && mkdir -p /var/log/supervisor \
	&& chown www-data:www-data /var/www/app/ -Rf \
	# Cleaning
	&& apt-get purge -y --auto-remove $BUILD_DEPS \
	&& apt-get autoremove -y && apt-get clean \
	&& rm -rf /var/lib/apt/lists/* \
	# Forward request and error logs to docker log collector
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

COPY ./configs/nginx.conf ${NGINX_CONF_DIR}/nginx.conf
COPY ./configs/default.conf ${NGINX_CONF_DIR}/conf.d/default.conf
COPY ./configs/app.conf ${NGINX_CONF_DIR}/sites-enabled/app.conf
COPY ./configs/www.conf /etc/php/5.6/fpm/pool.d/www.conf
COPY ./configs/php.ini /etc/php/5.6/fpm/php.ini

RUN chown -R www-data:www-data /var/www/app

WORKDIR /var/www/app/

EXPOSE 80 443

CMD ["/usr/bin/supervisord"]

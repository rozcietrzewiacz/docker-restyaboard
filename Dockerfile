FROM debian:wheezy-backports

ARG TERM=linux
ARG DEBIAN_FRONTEND=noninteractive

# restyaboard version
ENV restyaboard_version=v0.3

# update & install package
RUN apt-get update --yes --quiet && \
    apt-get install --yes --quiet \
 cron \
 curl \
 libapache2-mod-php5 \
 nginx \
 patch \
 php5 \
 php5-curl \
 php5-fpm \
 php5-imagick \
 php5-pgsql \
 postgresql \
 unzip

RUN echo "postfix postfix/mailname string example.com" | debconf-set-selections \
        && echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections \
        && apt-get install -y postfix

# deploy app
RUN curl -L -o /tmp/restyaboard.zip https://github.com/RestyaPlatform/board/releases/download/${restyaboard_version}/board-${restyaboard_version}.zip \
        && unzip /tmp/restyaboard.zip -d /usr/share/nginx/html \
        && rm /tmp/restyaboard.zip

# setting app
WORKDIR /usr/share/nginx/html
COPY fixes_710-711-715.patch ./
RUN patch --binary -p1 < fixes_710-711-715.patch
RUN cp -R media /tmp/ \
        && cp restyaboard.conf /etc/nginx/conf.d \
        && sed -i 's/^.*listen.mode = 0660$/listen.mode = 0660/' /etc/php5/fpm/pool.d/www.conf \
        && sed -i 's|^.*fastcgi_pass.*$|fastcgi_pass unix:/var/run/php5-fpm.sock;|' /etc/nginx/conf.d/restyaboard.conf \
        && sed -i -e "/fastcgi_pass/a fastcgi_param HTTPS 'off';" /etc/nginx/conf.d/restyaboard.conf

# volume
VOLUME /usr/share/nginx/html/media

# entry point
COPY docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["start"]

# expose port
EXPOSE 80

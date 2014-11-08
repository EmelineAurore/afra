# To run Afra.
#
# [1]: https://github.com/yeban/afra
# [2]: http://afra.sbcs.qmul.ac.uk
#
# VERSION   0.0.1

FROM  debian:sid
MAINTAINER  Anurag Priyam <anurag08priyam@gmail.com>

RUN groupadd -r postgres && useradd -r -g postgres postgres

RUN apt-get update && apt-get install -y curl build-essential && rm -rf /var/lib/apt/lists/* \
	&& curl -o /usr/local/bin/gosu -SL 'https://github.com/tianon/gosu/releases/download/1.1/gosu' \
	&& chmod +x /usr/local/bin/gosu

## make the "en_US.UTF-8" locale so postgres will be utf-8 enabled by default
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
	&& localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

RUN apt-get update && apt-get install -y apt-utils postgresql postgresql-client postgresql-doc pgadmin3 sudo

RUN apt-get install -y libexpat1-dev

RUN mkdir -p /var/run/postgresql && chown -R postgres /var/run/postgresql

RUN apt-get install -y nodejs git

RUN groupadd -r afra && useradd -m -g afra afra

USER afra

RUN cd /home/afra/ && git clone https://github.com/yeban/afra.git src

## Setup ruby
USER root
RUN cd /tmp/ && curl -o ruby-install-0.3.0.tar.gz -L https://github.com/postmodern/ruby-install/archive/v0.3.0.tar.gz \
             && tar xvf ruby-install-0.3.0.tar.gz && cd ruby-install-0.3.0/ && make install

RUN ruby-install ruby 2.1.4

RUN cd /tmp/ && curl -o chruby-0.3.7.tar.gz -L https://github.com/postmodern/chruby/archive/v0.3.7.tar.gz \
             && tar xvf chruby-0.3.7.tar.gz && cd chruby-0.3.7/ && make install

RUN cd /tmp/ && curl -o chgems-0.3.2.tar.gz -L https://github.com/postmodern/chgems/archive/v0.3.2.tar.gz \
             && tar xvf chgems-0.3.2.tar.gz && cd chgems-0.3.2/ && make install

## Setup postgres
USER postgres

RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER afra WITH SUPERUSER PASSWORD 'afra';" \
    && /etc/init.d/postgresql stop

RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.4/main/pg_hba.conf

RUN echo "listen_addresses='*'" >> /etc/postgresql/9.4/main/postgresql.conf

EXPOSE 5432

VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

USER root

## Setup Nginx
RUN apt-get -y install nginx-full openssl ca-certificates

## TODO: Add nginx config for afra
#ADD nginx.conf /etc/nginx/nginx.conf

VOLUME ["/etc/nginx"]
VOLUME ["/srv/www"]

EXPOSE 80
EXPOSE 443

#Setup Afra
RUN /etc/init.d/postgresql start && cd /home/afra/src/ && su afra -s /bin/bash -c "source /usr/local/share/chruby/chruby.sh && chruby ruby-2.1.4 && /usr/local/src/ruby-2.1.4/bin/rake" && /etc/init.d/postgresql stop

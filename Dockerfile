# Ejabberd 13.12
FROM stackbrew/ubuntu:12.04

# ORIGINAL MAINTAINER Rafael Römhild <rafael@roemhild.de>
MAINTAINER John Regan <john@jrjrtech.com>

# enable universe repo
RUN echo "deb http://archive.ubuntu.com/ubuntu precise main universe" > /etc/apt/sources.list \
&&  echo "deb http://archive.ubuntu.com/ubuntu/ precise-security main universe" >> /etc/apt/sources.list \
&&  echo "deb http://archive.ubuntu.com/ubuntu/ precise-updates main universe" >> /etc/apt/sources.list \
&& apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install curl build-essential m4 git libncurses5-dev libssh-dev libyaml-dev libexpat-dev libssl-dev libldap2-dev unixodbc-dev odbc-postgresql libmyodbc tdsodbc

# user & group
RUN addgroup ejabberd && adduser --system --ingroup ejabberd --home /opt/ejabberd --disabled-login ejabberd

# erlang
RUN mkdir -p /src/erlang \
&& cd /src/erlang \
&& curl http://erlang.org/download/otp_src_R16B03-1.tar.gz > otp_src_R16B03-1.tar.gz \
&& tar xf otp_src_R16B03-1.tar.gz \
&& cd otp_src_R16B03-1 \
&& ./configure \
&& make \
&& make install \
&& cd / && rm -rf /src/erlang

# ejabberd
RUN mkdir -p /src/ejabberd \
&& cd /src/ejabberd \
&& curl -L "http://www.process-one.net/downloads/downloads-action.php?file=/ejabberd/13.12/ejabberd-13.12.tgz" > ejabberd-13.12.tgz \
&& tar xf ejabberd-13.12.tgz \
&& cd ejabberd-13.12 \
&& ./configure --enable-user=ejabberd --enable-nif --enable-odbc --enable-mysql --enable-pgsql --enable-json --enable-http \
&& make \
&& make install \
&& cd / && rm -rf /src/ejabberd


# cleanup
RUN DEBIAN_FRONTEND=noninteractive apt-get -y remove git libncurses5-dev libssh-dev libyaml-dev libexpat-dev libssl-dev libldap2-dev unixodbc-dev

# This is so hacky - ejabberdctl has "start" and "live" commands
# "start" spawns a process in the background
# "live" keeps it attached (which I want), but it quits if
# not connected to stdin
# so I'm changing the start option to just not detach
# This also gives normal output instead of the crazy erlang output
RUN sed -i 's/-detach//' /sbin/ejabberdctl

# copy config
RUN rm /etc/ejabberd/ejabberd.yml
ADD ./ejabberd.yml /etc/ejabberd/
ADD ./ejabberdctl.cfg /etc/ejabberd/

# docker sets up really restrictive permissions
# on empty volumes, so let's make some dumb files
RUN touch /var/log/ejabberd/dummy && chown -R ejabberd:ejabberd /var/log/ejabberd
RUN touch /var/lib/ejabberd/dummy && chown -R ejabberd:ejabberd /var/lib/ejabberd
RUN touch /etc/ejabberd/dummy && chown -R ejabberd:ejabberd /etc/ejabberd

# set 123456 as default password for admin@localhost
RUN ejabberdctl admin localhost 123456

USER ejabberd
VOLUME ["/etc/ejabberd"]
VOLUME ["/var/log/ejabberd"]
VOLUME ["/var/lib/ejabberd"]

EXPOSE 5222 5269 5280
CMD ["start"]
ENTRYPOINT ["ejabberdctl"]

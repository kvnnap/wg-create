FROM alpine
LABEL authors="Kevin Napoli kvnnap@gmail.com"

COPY init.sh /init.sh

RUN apk --no-cache add wireguard-tools bash iptables

VOLUME /etc/wireguard

ENTRYPOINT ["/init.sh"]

FROM alpine:edge

RUN apk add --no-cache openssh socat tini bash rsyslog \
 && mkdir -p /root/.ssh \
 && chmod 700 /root/.ssh \
 && touch /var/log/lastlog \
 && ln -s /dev/stdout /var/log/btmp

EXPOSE 22
VOLUME ["/ssh-agent"]
CMD ["/usr/sbin/sshd", "-D"]

FROM alpine:edge

RUN apk add --no-cache openssh socat tini bash rsyslog \
 && mkdir -p /root/.ssh \
 && chmod 700 /root/.ssh \
 && touch /var/log/lastlog \
 && ln -s /dev/stdout /var/log/btmp \
 && sed -i'' \
  -e '/^[#]PasswordAuthentication.*$/d' \
  -e 's/^[#]*PermitRootLogin.*$/PermitRootLogin prohibit-password/' \
  -e 's/^[#]*PasswordAuthentication.*$/PasswordAuthentication no/' \
  -e 's/^[#]*AllowAgentForwarding.*$/AllowAgentForwarding yes/' \
  -e 's/^[#]*AllowTcpForwarding.*/AllowTcpForwarding yes/' \
  -e 's/^[#]*GatewayPorts.*/GatewayPorts yes/' \
  -e 's/^[#]*X11Forwarding.*$/X11Forwarding yes/' \
  -e 's/^[#]*SyslogFacility.*/SyslogFacility AUTH/' \
  -e 's/^[#]*LogLevel.*/LogLevel VERBOSE/' \
  -e 's/^[#]*ChallengeResponseAuthentication.*/ChallengeResponseAuthentication no/' \
  /etc/ssh/sshd_config \
 && echo "StreamLocalBindUnlink yes" >> /etc/ssh/sshd_config \
 && echo "StreamLocalBindMask 0111" >> /etc/ssh/sshd_config \
 && mkdir -p /etc/rsyslog.d/ \
 && sed -i'' \
  -e 's/module(load="imklog")/#module(load="imklog")/' \
  -e 's@/var/log/messages@/dev/stdout@' \
  -e 's@/var/log/auth.log@/dev/stdout@' \
  /etc/rsyslog.conf  \
 && true

COPY --chmod=755 docker-entrypoint.sh /docker-entrypoint.sh
EXPOSE 22
VOLUME ["/ssh-agent"]
ENTRYPOINT ["/sbin/tini", "--", "/docker-entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]

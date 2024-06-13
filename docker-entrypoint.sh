#!/bin/bash

# Enable RSYSLOG_FileFormat output format
awk '/^\$WorkDirectory/{print;getline;print "module(load=\"builtin:omfile\" Template=\"RSYSLOG_FileFormat\")";}{print}' /etc/rsyslog.conf > /etc/rsyslog.conf.new
mv /etc/rsyslog.conf.new /etc/rsyslog.conf

# Disable the stdout listeners in the main rsyslog config
sed -i'' -e 's@^\(.*/dev/stdout\)$@#\1@g' /etc/rsyslog.conf

# Use a custom template format that matches the log output style of confd and configure targets to use that format
cat > /etc/rsyslog.d/docker.conf << 'EOF'
template(
  name="rfc3339"
  string="%$year%-%$month%-%$day%T%timegenerated:12:19:date-rfc3339%Z %HOSTNAME% %syslogtag% %syslogpriority-text:::uppercase%%msg%\n"
  type="string"
)
*.info;authpriv.none;cron.none;kern.none;mail.none  -/dev/stdout;rfc3339
authpriv.*                      /dev/stdout;rfc3339
EOF

# Spawn rsyslog
/usr/sbin/rsyslogd -n &

# Set up log redirections:
# stdout goes to logger user.info
# stderr goes to logger user.err
# fd3 goes to standard out
process="${0##*/}"
process="${process%.*}[${BASHPID}]"
exec 3> >(exec cat >> /dev/stdout)
exec 1> >(exec logger -p user.info -t "${process}")
exec 2> >(exec logger -p user.err -t "${process}")

# Generate sshd keys
/usr/bin/ssh-keygen -A

# Set up authorized keys if AUTHORIZED_KEYS is set
if [ -n "$AUTHORIZED_KEYS" ]; then
  AK=/root/.ssh/authorized_keys
  echo "$AUTHORIZED_KEYS" | base64 -d > $AK
  chown 0:0 $AK
  chmod 600 $AK
fi

exec "$@"

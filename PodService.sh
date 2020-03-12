#!/usr/bin/env bash
function usage {
   echo "usage: $0 [--install / --uninstall / --dry-run] [--name servicename] [--cmd executable] [--user root] [--home home] [--options options] [--forking] [--needs-daemon]"
}

# daemon --name=zynghole --chdir=/root/work.git/work/poker/zynghole/Debugtmp ./zynghole
home=
install=0
uninstall=0
dryrun=0
needsdaemon=0
options=
command=
service=
forking=
user=root
remainder=""

if [ $# -eq 0 ]; then
   usage
   exit 1
fi

while test -n "$1"; do
   case $1 in

      --cmd )             		shift
                              command=$1
                              ;;
      --user )                shift
                              user=$1
                              ;;
      --forking )             # shift
                              forking=1
                              ;;
      --name )                shift
                              service=$1
                              ;;
      --options )             shift
                              options=$1
                              ;;
      --home )                shift
                              home=$1
                              ;;
      --dry-run )             # shift
                              dryrun=1
                              ;;
		--needs-daemon )        # shift
                              needsdaemon=1
                              ;;
      --install )             # shift
                              install=1
                              ;;
      --uninstall )             # shift
                              uninstall=1
                              ;;
      -h | --help )           usage
                              exit
                              ;;
      * )                     remainder="$remainder $1"
   esac
   shift
done

command=${command:-$service}
if test -z "$home"; then
	if [[ $command == */* ]]; then
		home=${command%/*}
		command=${command##*/}
	fi
fi

service=${service:-$command}


if test -z "$service" || test -z "$command" || test -n "$remainder"; then
   usage
   exit
fi

if (( dryrun + install + uninstall != 1 )); then
	echo "You can only pick one of --install, -uninstall, or --dry-run"
	usage
	exit
fi


SERVICE=$(echo "$service" | tr a-z A-Z)
###
# init.d template
###

function systemd_template {
	local _type
	(( ! needsdaemon )) && _type=simple || _type=forking
	(( forking )) && _type=forking
	# http://www.freedesktop.org/software/systemd/man/systemd.exec.html
cat <<EOTEMPLATE
[Unit]
Description=$service
After=network.target

[Service]
Type=$_type
User=$user
WorkingDirectory=$home
ExecStart=$home/$command $options

[Install]
WantedBy=multi-user.target
EOTEMPLATE
}

function template {
cat <<EOTEMPLATE
#!/bin/bash
#
### BEGIN INIT INFO
# Provides:          $service
# Required-Start:    \$syslog \$local_fs
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: $service
# Description:       Service Template for $SERVICE created by PodService
### END INIT INFO

# Locate $service heuristics
SERVICE_DIR='$home'
SERVICE='$service'
COMMAND='$command'
OPTIONS='$options'
USER='$user'
test -z "\$SERVICE_DIR" && SERVICE_DIR=\$(dirname \$(which $service 2>/dev/null) 2>/dev/null)
if test -z "\$SERVICE_DIR"; then
  if test -d /opt/$service; then
#    SERVICE_DIR=\$(dirname \$(dirname \$(find /opt/$service/ -name $service 2>/dev/null | tail -n 1) 2>/dev/null) 2>/dev/null)
#    SERVICE_DIR=\$(ls -t /opt/$service | head -n 1)
#    if test -n "\${SERVICE_DIR}"; then SERVICE_DIR="/opt/$service/\${SERVICE_DIR}";fi
     :
  fi
  if test -z "\$SERVICE_DIR"; then
    echo "Error, can't find $service, is it in the PATH?" 2>&1
    exit 1
  fi
fi

export LD_LIBRARY_PATH="\$SERVICE_DIR"
# Check for configuration
# This parsing is pretty lame
if test -f "/etc/$service.conf"; then
  OPTIONS="\$(cat "/etc/$service.conf" | sed -n /^options/p | cut -d '=' -f 2)"
# Build up $service command line options
  test -n "\${OPTIONS}" && OPTIONS="\${OPTIONS}" # do nothing kinda command?
fi

case \$1 in
        test)
            echo "Command line"
				echo "cd \"\$SERVICE_DIR\""
            echo "su \$USER -c \"'./\$COMMAND' \$OPTIONS\""
            ;;
        start)
            echo "Starting $service"
				if (( $needsdaemon )); then
					/usr/local/bin/daemon --name=\$SERVICE --chdir="\$SERVICE_DIR" "\$SERVICE_DIR/\$COMMAND" \$OPTIONS
				else
					cd "\$SERVICE_DIR"
					su \$USER -c "'./\$COMMAND' \$OPTIONS"
				fi
            ;;
        restart)
            \$0 stop
            sleep 3
            \$0 start
            ;;
        status)
			  Q=\$(pgrep $service)
            if test -z "\${Q}"; then 
              echo "$service process not found"; 
              exit 1; 
            fi
            echo "$service process \${Q}"; exit 0
            ;;
        stop)
            echo "Stopping $service"
            P=\$(cat /var/run/$service.pid 2>/dev/null)
            if test -z "\${P}"; then
              killall $service 2>/dev/null || echo >/dev/null
            else
              kill \$P 2>/dev/null || echo "Couldn't kill process \$P (privilege error?)"
            fi
            rm -f /var/run/$service.pid
            ;;
esac
EOTEMPLATE
}
###
# end init.d template
###

(( dryrun )) && {
	if test -n "$(which systemctl 2>/dev/null)"; then
		systemd_template
	else
		template 
	fi
}

(( install )) && {
   if test -n "$options"; then echo "options=$options" > /etc/${service}.conf; fi
	if test -n "$(which systemctl 2>/dev/null)"; then
		systemd_template > /etc/systemd/system/${service}.service
		systemctl daemon-reload
		systemctl enable ${service}.service
		systemctl start ${service}.service
	else
		template > /etc/init.d/${service}
		chmod 0755 /etc/init.d/${service}
		if test -n "$(which update-rc.d 2>/dev/null)"; then update-rc.d ${service} defaults;fi
		if test -n "$(which chkconfig 2>/dev/null)"; then chkconfig --add ${service} && chkconfig ${service} on;fi
		if test -f /bin/systemctl; then /bin/systemctl daemon-reload; fi
		/etc/init.d/${service} start
	fi
}

(( uninstall )) && {
	if test -n "$(which systemctl 2>/dev/null)"; then
		systemctl disable {$service}.service
	fi
	if test -f /etc/init.d/${service}; then /etc/init.d/${service} stop; fi
	if test -n "$(which update-rc.d 2>/dev/null)"; then sudo update-rc.d -f ${service} remove;fi
	if test -n "$(which chkconfig 2>/dev/null)"; then chkconfig --del ${service};fi
	rm -f /etc/init.d/${service}
}

# https://www.elastic.co/guide/en/elasticsearch/reference/1.6/setup-service.html

# Distributions like SUSE do not use the chkconfig tool to register services,
# but rather systemd and its command /bin/systemctl to start and stop services
# (at least in newer versions, otherwise use the chkconfig commands above). The
# configuration file is also placed at /etc/sysconfig/elasticsearch. After
# installing the RPM, you have to change the systemd configuration and then
# start up elasticsearch


(( 0 )) && {
	sudo /bin/systemctl daemon-reload
	sudo /bin/systemctl enable elasticsearch.service
	sudo /bin/systemctl start elasticsearch.service
}


# sed -e "s/%%SERVICE%%/$SERVICE/g" -e "s/%%service%%/$service/g" template.svc.sh
# $commands[] = 'grep "127.0.0.1" /etc/resolv.conf || sed -i -e "1inameserver 127.0.0.1" /etc/resolv.conf';
# $commands[] = 'sed -i "/domain/d" /etc/resolv.conf';
# service=pplnetmaster; SERVICE=$(echo "$service" | tr a-z A-Z); sed -e "s/%%SERVICE%%/$SERVICE/g" -e "s/%%service%%/$service/g" template.svc.sh

: <<EOSYSTEMD

					[Unit]
					Description=ZyngHole WebServer
					After=network.target apache2.service

					[Service]
					Type=forking
					ExecStart=/usr/local/bin/daemon --name=zynghole --chdir=/root/work.git/work/poker/zynghole/Debugtmp /root/work.git/work/poker/zynghole/Debugtmp/zynghole
					ExecReload=/usr/bin/killall zynghole

					[Install]
					WantedBy=multi-user.target
EOSYSTEMD

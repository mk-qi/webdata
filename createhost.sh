#!/usr/bin/env bash
# createhost.sh
# used to create container for docker
# 

# DEFAULT VALUE 
# --globle varibles explan
# name; container name
# img; docker images
# cmd;  contianer run command /bin/bash --login 
# ip/gw;   ipaddr for to conatainer 192.168.2.33/24 and gateway
# ifname   bridge interface name

# gen uuid for default hostname
uuid=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1)
# default container name
name="${name:=sh-${uuid}}"

# first we create an container without network
# and store pids to pid
# usage:  _c_fanli_conatainer $name "${options}" "${cmd}"  "${img}"
_c_fanli_conatainer(){
    host="$1";options="$2";
    cmd="$3";img="$4";volume=$6
    
    # DEFAULT VALUE
    cmd="${cmd:="/bin/bash --login"}"
    img="${img:="centos:6"}"
    volume="${volume:=""}"

    ifname="${ifname:="docker0"}"
    
    docker inspect --format="{{ .State.Running }}"\
        $host 2> /dev/null && {
        echo the name of ${host} is running, try a new one;
        exit 2;
    }
    # base dir of storage container's data
    base="/data/containers/"
    
    # container home 
    # /data/containers/web11/
    host_dir="${base}/${host}"
    # webdata source
    # create host directory
    # /data/containers/web11/weblogs,webdata
    mkdir -p ${hostdir}/{weblogs,webdata}
    
    # -v "souce:dest"
    # mount webdata volume from host
    if [ $webdata ];then
        webdata="/data/rodata/webdata/"
        samba="/opt/samba"
        volume="
          -v ${hostdir}/weblogs:/data/weblogs/ \
          -v ${hostdir}/webdata:/usr/local/webdata/ \
          -v ${samba}/fanliweb:/opt/fanliweb \
          -v ${samba}/tuangouweb:/opt/webdata \
        "
        img="centos:webdata"
    fi
  # start up container with options
  docker run  --name=${host} ${options} ${volume} ${img} ${cmd}
}

# inspired from pipework
# usage: _set_ip_forcontainer name ip/mask gw  bridge-interface
#    ex: _set_ip_forcontainer web1 192.168.2.22/24 192.168.2.1  docker0
_set_ip_forcontainer(){
    name=$1;ip=$2;gw=$3;
    ifname=$4;
    
    # get container pid
    pid=$(sudo docker inspect -f '{{.State.Pid}}' $name 2> /dev/null);
    [  $? != 0 ] && {
        echo "No such image or container: ${name}";
        exit 3;
    }
    # create a connecter between  host and container 
    # but first we should make sure bridge interface
    # exsit;
    if [ -d /sys/class/net/$ifname/bridge ];then
        if [ ! -d /var/run/netns ];then
            sudo mkdir -p /var/run/netns
        fi
        if [ ! -f /var/run/netns/$pid ];then
            sudo ln -s /proc/$pid/ns/net /var/run/netns/$pid
        fi
    fi

    # set an ip for container
    # we need to create a veth pair first
    # lveth=>localhost veth
    # gveth=>guesthost veth
    lveth="lveth${pid}"
    gveth="gveth${pid}"
  
    ip link add  $lveth type veth peer name $gveth
    # add veth to bridge
    ip link set $lveth master $ifname
    ip link set $lveth up
    # attache guestveth to container
    ip link set $gveth netns $pid
  
    #ip namespace set ip and gw to container interface
    ip netns exec $pid ip link set $gveth name eth0
    ip netns exec $pid ip addr add $ip dev eth0
    ip netns exec $pid ip link set eth0 up
    # cut ip/netmask to ip
    ipaddr=$(echo  $ip| cut -d/ -f1)
    # send arp broadcast in container interface
    ip netns exec $pid arping -c 1 -A -I eth0 $ipaddr
    # set default gateway  for container
    ip netns exec $pid ip route replace default via $gw
  
    # Clean up dangling symlinks in /var/run/netns
    find -L /var/run/netns -type l -delete
    #[ -f /var/run/netns/$pid ] && rm -f /var/run/netns/$pid
}

# http://stackoverflow.com/questions/402377/using-getopts-in-\
#    bash-shell-script-to-get-long-and-short-command-line-options
optspec=":h-:"
while getopts "$optspec" optchar; do
    case "${optchar}" in
        -)
            case "${OPTARG}" in
                name=*)
                    name=${OPTARG#*=}
                    ;;
                fanliweb=*)
                    webdata=${OPTARG#*=}
                   ;;
                dockeropt=*)
                    dockeropt=${OPTARG#*=}
                    ;;
                ip=*)
                    ip=${OPTARG#*=}
                    ;;
                gw=*)
                    gw=${OPTARG#*=}
                    ;;
                img=*)
                    img=${OPTARG#*=}
                    ;;
                cmd=*)
                    cmd=${OPTARG#*=}
                    ;;
                ifname=*)
                    ifname=${OPTARG#*=}
                    ;;
                *)
                    echo "Unknown option --${OPTARG}" >&2;;
            esac;;
        h)
            echo "usage: $0 --name=web1 --dockeropt=docker options --img=docker images --cmd=run cmd [-fanliweb] [-ip=ip/mask] [-gw=ip]"  >&2
            exit 2
            ;;
        *);;
    esac
done

# options parser
if [ $dockeropt ];then
    options=$dockeropt
elif [  $webdata ];then
    options=" --rm  -it"
elif [ $ip ];then
    options="--net=none -itd"
else
    options=" --rm --net=none -it"
fi
_c_fanli_conatainer $name "${options}" "${cmd}"  "${img}"

if [ $ip ];then
    _set_ip_forcontainer $name $ip $gw  $ifname
fi

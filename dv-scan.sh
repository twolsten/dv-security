#!/bin/bash

# Lets start with just the basic version of CentOS we are talking about
# Anything less than 6.7 needs a major update
cat /etc/centos-release |awk '{print $3}'

# Check to verify that /home /tmp /var /var/log /var/log/audit are separate partitions


echo "Checking partitions..."
for dir in \/home \/tmp \/var \/var\/log \/var\/log\/audit \/boot
  do
  egrep -q $dir /etc/mtab || printf "%s is not a separate partition\n" "$dir"
  du -sh $dir
  echo
  done

# Check SELinux level

Level=`getenforce`
printf "\n\nSELinux is set to %s\n" "$Level"

# Check for users without passwords

cat /etc/shadow | awk -F: '($2==""){print $1 "does not have a password"}'

# Check gpgcheck value
echo
gpgcheck=$(grep -i gpgcheck /etc/yum.conf |awk -F\= {'print $2'})

if [[ $gpgcheck == '1' ]]; then
   echo 'gpgcheck is set correctly'
else
   echo 'gpgcheck is NOT set correctly'
fi

# Check if AIDE is installed.  Is AIDE required?
echo
rpm -q aide

# Check if SELinux is set in grub.conf
echo
grub=$(grep -i selinux /etc/grub.conf)
if [[ $grub == '' ]]; then
   echo "SELinux is not set in grub.conf" 
else
   echo $grub
fi
echo

# Check SETroubleshoot
rpm -q setroubleshoot
echo

# Check mcstrans
rpm -q mcstrans
echo
# Check interactive boot

inter=$(grep -i prompt= /etc/sysconfig/init |awk -F\= {'print $2}')

if [[ $inter == "yes" ]]; then
   echo "Interactive boot is set"
else
   echo "Interactive boot is NOT set"
fi
echo

# Check core dumps

dumpable=$(sudo sysctl -a |grep dumpable |awk '{print $3}')

if [[ $dumpable == "1" ]]; then
   echo "Core dumps disabled in sysctl.conf"
else
   echo "Core dumps are enabled in sysctl.conf"
   echo "Set hard limit in limits.conf"
fi

# Check exec-shield
echo
printf "Kernel.exec-shield is set to %s" $(sysctl kernel.exec-shield |awk '{print $3}')
shield=$(grep exec /etc/sysctl.conf)
echo
if [[ $shield == "" ]]; then
   echo "kernel.exec-shield is NOT set in sysctl.conf"
else
   echo "kernel.exec-shield is set in sysctl.conf"
fi


# Check kernel space is randomized
echo
printf "kernel randomize  is set to %s" $(sysctl kernel.randomize_va_space |awk '{print $3}')
randomize=$(grep va_space /etc/sysctl.conf)
echo
if [[ $randomize == "" ]]; then
   echo "kernel.randomize_va_space is NOT set in sysctl.conf"
else
   echo "kernel.randomize_va_space is set in sysctl.conf"
fi


# Check installed apps that shouldn't be
echo
for apps in telnet telnet-server rsh rsh-server ypbind ypserv tftp tftp-server talk talk-server
do
rpm -q $apps
done

# Check umask in /etc/sysconfit/init
echo
if [[ $(grep -i umask /etc/sysconfig/init) == "umask 027" ]]; then
   echo "umask is set correctly in /etc/sysconfig/init"
else
  echo "umask needs to be set correctly in /etc/sysconfig/init"
fi

# Check net kernel parameters that should be set to 0
echo
for i in net.ipv4.ip_forward net.ipv4.conf.all.send_redirects net.ipv4.conf.default.send_redirects net.ipv4.conf.all.accept_source_route net.ipv4.conf.default.accept_source_route net.ipv4.conf.all.secure_redirects net.ipv4.conf.default.secure_redirects
do
   if [[ $(sysctl $i |awk '{print $3}') == "0" ]]; then
      printf "%s is set correctly\n" "$i"
   else
      printf "%s should be set to 0\n" "$i"
   fi
done

# Check net kernel parameters that should be set to 1
echo
for i in net.ipv4.icmp_echo_ignore_broadcasts net.ipv4.icmp_ignore_bogus_error_responses net.ipv4.tcp_syncookies 
do
   if [[ $(sysctl $i |awk '{print $3}') == "1" ]]; then
      printf "%s is set correctly\n" "$i"
   else
      printf "%s should be set to 1\n" "$i"
   fi
done

# Check if rsyslog is installed and enabled
echo
rpm -q rsyslog
chkconfig --list rsyslog

# CHeck if auditd is installed
echo
rpm -q audit
chkconfig --list auditd

# Check root login via ssh
echo
if [[ $(egrep -i "#permitrootlogin" /etc/ssh/sshd_config |awk '{print $2}') == "yes" ]]; then
   echo "Root is able to directly login"
else
   echo "Root is prevented from directly logging in"
fi

# Check sshd Protocol level
echo
if [[ $(grep -i protocol /etc/ssh/sshd_config |grep -v \# |awk '{print $2}') == "2" ]]; then
   echo "SSHD Protocol is correct"
else
   echo "SSHD Protocol is INCORRECT."
fi

# Check SSHD LogLevel
echo
if [[ $(grep -i loglevel /etc/ssh/sshd_config|awk '{print $2}') == "INFO" ]]; then
   echo "SSHD LogLevel is set correct"
else
   echo "SSHD LogLevel is INCORRECT"
fi

# Check for allowed empth passwords
echo
if [[ $(grep -i PermitEmptyPasswords /etc/ssh/sshd_config |awk '{print $2}') == "no" ]]; then
   echo "PermitEmptyPasswords is correct"
else
   echo "PermitEmptyPasswords is INCORRECT"
fi

# Check for user environments in sshd
echo
if [[ $(grep -i PermitUserEnvironment /etc/ssh/sshd_config|awk '{print $2}') == "no" ]]; then
   echo "PermitUserEnvironment is set correctly"
else
   echo "PermitUserEnvironment is set INCORRECTLY"
fi

# Check max password age
echo
if [[ $(grep -i pass_max_days /etc/login.defs |awk '{print $2}') == "90" ]]; then
   echo "PASS_MAX_DAYS is set correctly"
else
   echo "PASS_MAX_DAYS is set incorrectly"
fi

# Check logrotate....

echo
for i in /var/log/messages /var/log/secure /var/log/maillog /var/log/spooler /var/log/boot.log /var/log/cron
do
grep -i $i /etc/logrotate.d/syslog || printf "The %s logs are not in /etc/logrotate.d/syslog\n" "$i"
done


# Check cron service status
echo
for i in crond anacron
do
chkconfig --list |grep $i || printf "\n%s is not installed\n" "$i"
done

# check for duplicate IDs
# Cheating here and just using what is in the doc for a change
# but I did fix the indentation cause that would drive me nuts
/bin/cat /etc/passwd | /bin/cut -f3 -d":" | /bin/sort -n | /usr/bin/uniq -c |\
while read x ; do
[ -z "${x}" ] && break
set - $x
if [ $1 -gt 1 ]; then
   users=`/bin/gawk -F: '($3 == n) { print $1 }' n=$2 \ /etc/passwd | /usr/bin/xargs`
   echo "Duplicate UID ($2): ${users}"
fi
done



#

sudo yum install -y git mailx
cd /opt
git clone https://github.com/andreit2/linux-homework.git
cd linux-homework/hw09/
sudo chmod a+x script.sh
sudo echo "0 */1 * * * /opt/linux-homework/hw09/script.sh" > /var/spool/cron/root

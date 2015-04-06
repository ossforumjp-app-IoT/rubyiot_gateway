#
# daemon.rbを自動起動するスクリプト
#
# rc.localに以下を追加してください
#
# ifdown wlan0
# sleep 3
# ifup wlan0
# sleep 20
# export LANG=ja_JP.UTF-8
# su - pi -c "/home/pi/init.sh"
#

echo "unicorn start" >> daemon.log
#~/server/rubyiot_server/start.sh

cd ~/server/rubyiot_server
./start.sh

echo "unicorn start finish" >> daemon.log

cd ~/ossapp-src
ruby daemon.rb >> /home/pi/daemon.log &
#ruby daemon.rb 

#cd ossapp-src
#ruby daemon.rb



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

CURRENT_PATH=`pwd`
LOG_FILE="$CURRENT_PATH/log/daemon.log"

echo "unicorn start" >> $LOG_FILE
#~/server/rubyiot_server/start.sh

cd ~/server/rubyiot_server
./start.sh

echo "unicorn start finish" >> $LOG_FILE

cd $CURRENT_PATH
bundle exec ruby src/daemon.rb >> $LOG_FILE &
#ruby daemon.rb

#cd ossapp-src
#ruby daemon.rb

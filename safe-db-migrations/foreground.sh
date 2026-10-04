echo "Setting up PostgreSQL, the app and the tools. This takes about a minute..."
while [ ! -f /tmp/setup-done ]; do sleep 2; done
source /root/.bashrc
clear
echo "Ready. You are in /root/tutorial"
ls

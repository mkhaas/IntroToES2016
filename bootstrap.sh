#!/usr/bin/env bash

IP="127.0.0.1"
HOST=`es2`
sed -i "/$IP/ s/.*/$IP\tlocalhost\t$HOST/g" /etc/hosts

sudo apt-get update
sudo apt-get upgrade

# install curl
sudo apt-get -y install curl unzip

# install openjdk-7
sudo apt-get purge openjdk*
sudo apt-get -y install openjdk-8-jdk

# install ES
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list
sudo apt-get update && sudo apt-get install elasticsearch
sudo update-rc.d elasticsearch defaults 95 10

# either of the next two lines is needed to be able to access "localhost:9200" from the host os
sudo echo "network.bind_host: 0" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "network.host: 0.0.0.0" >> /etc/elasticsearch/elasticsearch.yml

# enable cors (to be able to use Sense)
sudo echo "http.cors.enabled: true" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "http.cors.allow-origin: /https?:\/\/localhost(:[0-9]+)?/" >> /etc/elasticsearch/elasticsearch.yml

# enable dynamic scripting
sudo echo "script.inline: on" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "script.indexed: on" >> /etc/elasticsearch/elasticsearch.yml

sudo /etc/init.d/elasticsearch start

sudo /usr/share/elasticsearch/bin/plugin install -b --verbose license
sudo /usr/share/elasticsearch/bin/plugin install -b --verbose marvel-agent

#Kibana setup
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb http://packages.elastic.co/kibana/4.5/debian stable main" | sudo tee -a /etc/apt/sources.list
sudo apt-get update && sudo apt-get install kibana
sudo echo "elasticsearch.url: "http://localhost:9200"" >> /opt/kibana/config/kibana.yml
sudo update-rc.d kibana defaults 95 10
sudo /bin/systemctl daemon-reload
sudo /bin/systemctl enable kibana.service
sudo /etc/init.d/kibana restart
#install and setup of sense and marvel
sudo /opt/kibana/bin/kibana plugin --install elastic/sense
sudo /opt/kibana/bin/kibana plugin --install elasticsearch/marvel/latest
#this was was an odd one.. fix permissions for various reasons.
sudo chown kibana:root /opt/kibana/optimize/.babelcache.json
# restart everything just to make sure
sudo /etc/init.d/elasticsearch restart
sudo /etc/init.d/kibana restart

sudo /etc/init.d/elasticsearch restart
sleep 30
#  Data Import for potential labs
curl -XPOST 'localhost:9200/books/es/1' -d '{"title":"Elasticsearch Server", "published": 2013}'
curl -XPOST 'localhost:9200/books/es/2' -d '{"title":"Elasticsearch Server Second Edition", "published": 2014}'
curl -XPOST 'localhost:9200/books/es/3' -d '{"title":"Mastering Elasticsearch", "published": 2013}'
curl -XPOST 'localhost:9200/books/es/4' -d '{"title":"Mastering Elasticsearch Second Edition", "published": 2015}'
curl -XPOST 'localhost:9200/books/solr/1' -d '{"title":"Apache Solr 4 Cookbook", "published": 2012}'
curl -XPOST 'localhost:9200/books/solr/2' -d '{"title":"Solr Cookbook Third Edition", "published": 2015}'
#import accounts data
Echo "downloading file"
curl -LOk -o accounts.zip 'https://github.com/bly2k/files/blob/master/accounts.zip?raw=true'
unzip 'accounts.zip_raw=true'
curl -XPOST 'localhost:9200/bank/account/_bulk?pretty' --data-binary "@accounts.json"



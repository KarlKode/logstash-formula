{%- from 'logstash/map.jinja' import logstash with context %}

{%- if grains['os_family'] == 'Debian' %}
logstash-repo:
  pkgrepo.managed:
    - humanname: Logstash Debian Repository for logstash version {{ logstash.version }}
    - name: deb http://packages.elastic.co/logstash/{{ logstash.version }}/debian stable main
    - file: /etc/apt/sources.list.d/logstash.list
    - key_url: https://packages.elastic.co/GPG-KEY-elasticsearch
{%- elif grains['os_family'] == 'RedHat' %}
logstash-repo:
  pkgrepo.managed:
    - humanname: logstash repository for {{ logstash.version }}.x packages
    - baseurl: http://packages.elasticsearch.org/logstash/{{ logstash.version }}/centos
    - gpgcheck: 1
    - gpgkey: http://packages.elasticsearch.org/GPG-KEY-elasticsearch
{%- endif %}

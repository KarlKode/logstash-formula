{%- from 'logstash/map.jinja' import logstash with context %}
{%- from 'logstash/map.jinja' import logstash_conf with context %}

include:
  - .repo
  - .plugin



logstash-pkg:
  pkg.{{ logstash.pkgstate }}:
    - name: {{logstash.pkg}}
#    - version: {{ logstash.version }}
    - require:
      - pkgrepo: logstash-repo

# This gets around a user permissions bug with the logstash user/group
# being able to read /var/log/syslog, even if the group is properly set for
# the account. The group needs to be defined as 'adm' in the init script,
# so we'll do a pattern replace.

{%- if salt['grains.get']('os', None) == "Ubuntu" %}
change service group in Ubuntu init script:
  file.replace:
    - name: /etc/init.d/logstash
    - pattern: "LS_GROUP=logstash"
    - repl: "LS_GROUP=adm"
    - watch_in:
      - service: logstash-svc

add adm group to logstash service account:
  user.present:
    - name: logstash
    - groups:
      - logstash
      - adm
    - require:
      - pkg: logstash-pkg
{%- endif %}

{%- for conf_name in logstash_conf.keys() %}
{{'/'.join([logstash.conf_dir, conf_name + '.conf'])}}:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - source: salt://logstash/files/conf
    - template: jinja
    - defaults:
        conf_name: {{conf_name}}
    - require:
      - pkg: logstash-pkg
    - require_in:
      - file: logstash-config
    - watch_in:
      - service: logstash-svc
{%- endfor %}

logstash-config:
  file.directory:
    - name: {{logstash.conf_dir}}
    - clean: True

{% if logstash.env is defined %}
logstash-env:
  file.managed:
    - name: /etc/default/logstash
    - mode: 664
    - user: root
    - group: root
    - source: salt://logstash/files/default
    - template: jinja
    - require:
      - pkg: logstash-pkg
    - defaults:
      config: {{ logstash.env | json }}
{% endif %}

logstash-svc:
  service.running:
    - name: {{logstash.svc}}
    - enable: true
    - watch:
      - file: logstash-config
{% if logstash.env is defined %}
      - file: logstash-env
{% endif %}


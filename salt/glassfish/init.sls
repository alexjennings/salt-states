#sls
include:
  - jdk
  - auth.service


{% if salt['pillar.get']('glassfish:version').startswith('2') %}
glassfishextract:
  file.managed:
    - name: /opt/glassfish-{{ salt['pillar.get']('glassfish:version') }}.jar
    - source: salt://glassfish/files/glassfish-{{ salt['pillar.get']('glassfish:version') }}.jar
  cmd.run:
    - name: echo a | /usr/bin/java -Xmx256m -jar /opt/glassfish-{{ salt['pillar.get']('glassfish:version') }}.jar
    - cwd: /opt/
    - unless: file /opt/glassfish
    - failhard: True
    - require:
      - alternatives: java
      - file: glassfishextract

setupglassfish:
  file.directory:
    - name: /opt/glassfish/lib/ant/bin
    - file_mode: 755
    - dir_mode: 755
    - recurse:
      - mode
    - require:
      - cmd: glassfishextract
      - file: glassfishpermissions
  cmd.run:
    - name: /opt/glassfish/lib/ant/bin/ant -f /opt/glassfish/setup.xml
    - unless: file /opt/glassfish/domains/domain1/config/domain.xml
    - user: {{ salt['pillar.get']('user:name') }}
    - require:
      - file: setupglassfish
      - file: glassfishextract

setimqjavaparams:
  file.sed:
    - name: /opt/glassfish/imq/bin/imqbrokerd
    - before: Xss128k
    - after: Xss160k
    - require:
      - cmd: setupglassfish

glassfishpermissions:
  file.directory:
    - name: /opt/glassfish
    - user: {{ salt['pillar.get']('user:name') }}
    - group: {{ salt['pillar.get']('group:name') }}
    - recurse:
      - user
      - group
    - require:
      - user: {{ salt['pillar.get']('user:name') }}
      - file: glassfishextract
    - require_in:
      - file: glassfishinitscript

{% endif %}

{% if salt['pillar.get']('glassfish:version').startswith('3') %}

glassfishanswers:
  file.managed:
    - name: {{ salt['pillar.get']('user:home') }}/.gfanswers
    - source: salt://glassfish/templates/minimal.txt
    - mode: 500
    - user: {{ salt['pillar.get']('user:name') }}
    - template: jinja
    - require:
      - user: {{ salt['pillar.get']('user:name') }}

glassfishroot:
  file.directory:
    - name: /opt/glassfish
    - user: {{ salt['pillar.get']('user:name') }}
    - group: {{ salt['pillar.get']('group:name') }}
    - require:
      - user: {{ salt['pillar.get']('user:name') }}
      
setupglassfish:
  file.managed:
    - name: /opt/glassfish-{{ salt['pillar.get']('glassfish:version') }}-unix.sh
    - source: salt://glassfish/files/glassfish-{{ salt['pillar.get']('glassfish:version') }}-unix.sh
    - mode: 750
    - user: {{ salt['pillar.get']('user:name') }}
  cmd.run:
    - name: /opt/glassfish-{{ salt['pillar.get']('glassfish:version') }}-unix.sh -s -a {{ salt['pillar.get']('user:home') }}/.gfanswers
    - user: {{ salt['pillar.get']('user:name') }}
    - cwd: /opt/
    - unless: file /opt/glassfish/bin/asadmin
    - failhard: True
    - require_in:
      - file: glassfishinitscript
    - require:
      - alternatives: java
      - file: glassfishanswers
      - file: setupglassfish
      - file: glassfishroot

{% if salt['pillar.get']('glassfish:webadmin') == 'True' %}
glassfishwebadmin:
  cmd.run:
    - names:
      - /opt/glassfish/bin/asadmin enable-secure-admin ; service glassfish restart
    - user: {{ salt['pillar.get']('user:name') }}
    - unless: grep "secure-admin enabled" /opt/glassfish/glassfish/domains/domain1/config/domain.xml
    - require:
      - service: glassfishservice

{% endif %}

{% endif %}


glassfishinitscript:
  file.managed:
    - name: /etc/init.d/glassfish
    - mode: 777
    - source: salt://glassfish/files/glassfish
    - require:
      - user: {{ salt['pillar.get']('user:name') }}


glassfishstartuplinks:
  file.symlink:
    - name: /etc/rc2.d/S99glassfish
    - target: /etc/init.d/glassfish
    - require:
      - file: glassfishinitscript

glassfishservice:
  service:
    - name: glassfish
    - running
    - require:
      - file: glassfishinitscript

include:
  - postgresql


listenoninterfaces:
  file.sed:
    - name: /etc/postgresql/9.1/main/postgresql.conf
    - before: "#listen_addresses = 'localhost'"
    - after: "listen_addresses = '*'"
    - require:
      - pkg: postgresql
    - watch_in:
      - service: postgresql


standbyon:
  file.sed:
    - name: /etc/postgresql/9.1/main/postgresql.conf
    - before: "#hot_standby = off"
    - after: "hot_standby = on"
    - require:
      - pkg: postgresql
    - watch_in:
      - service: postgresql



sshhome:
  file.directory:
    - name: /var/lib/postgresql/.ssh
    - user: postgres
    - group: postgres
    - mode: 700
    

sshprvkey:
  file.managed:
    - name: /var/lib/postgresql/.ssh/id_rsa
    - user: postgres
    - group: postgres
    - mode: 600
    - require:
      - file: sshhome


sshfingerprint:
  ssh_known_hosts.present:
    - name: {{ pillar['psqlmaster'] }}
    - user: postgres
    - fingerprint: {{ pillar['psqlmasterfinger'] }}
    - require:
      - file: sshhome

getbasefiles:
  cmd.run:
    - name: |
        echo "{{ pillar['ssh-prv-key']|indent(8) }}" > /var/lib/postgresql/.ssh/id_rsa;
        service postgresql stop;
        rm -rf /var/lib/postgresql/9.1-orig; mv /var/lib/postgresql/9.1 /var/lib/postgresql/9.1-orig;
        ssh {{ pillar['psqlmaster'] }} 'service postgresql restart; service postgresql stop';
        scp -r {{ pillar['psqlmaster'] }}:/var/lib/postgresql/9.1 /var/lib/postgresql;
        ssh {{ pillar['psqlmaster'] }} 'service postgresql start'
        echo "" > /var/lib/postgresql/.ssh/id_rsa
    - user: postgres
    - require:
      - file: listenoninterfaces
      - file: standbyon
      - file: sshprvkey
      - pkg: postgresql
      - ssh_known_hosts: sshfingerprint
    - unless: file /var/lib/postgresql/9.1/main/recovery.conf

recoveryconf:
  file.managed:
    - name: /var/lib/postgresql/9.1/main/recovery.conf
    - user: postgres
    - contents: |
        standby_mode = on
        primary_conninfo = 'host={{ pillar['psqlmaster'] }} port=5432'
    - require:
      - cmd: getbasefiles
    - watch_in:
      - service: postgresql

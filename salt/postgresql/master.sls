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

wallevel:
  file.sed:
    - name: /etc/postgresql/9.1/main/postgresql.conf
    - before: "#wal_level = minimal"
    - after: "wal_level = hot_standby"
    - require:
      - pkg: postgresql
    - watch_in:
      - service: postgresql

walsenders:
  file.sed:
    - name: /etc/postgresql/9.1/main/postgresql.conf
    - before: "#max_wal_senders = 0"
    - after: "max_wal_senders = 2"
    - require:
      - pkg: postgresql
    - watch_in:
      - service: postgresql



{% for server in salt['pillar.get']('psqlstandby') %}
{{ server }}authentication:
  file.append:
    - name: /etc/postgresql/9.1/main/pg_hba.conf
    - require:
      - pkg: postgresql
    - watch_in:
      - service: postgresql
    - text: |
        host  replication  postgres  {{ server }}/32  trust
{% endfor %}

sshpubkey:
  ssh_auth:
    - present
    - user: postgres
    - name: {{ pillar['ssh-pub-key']|indent(8) }}


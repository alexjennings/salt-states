#sls

{{ salt['pillar.get']('project:name') }}auth:
  group.present:
  - name: {{ salt['pillar.get']('group:name') }}
  - gid: {{ salt['pillar.get']('group:id') }}
  - system: True
  user.present:
  - name: {{ salt['pillar.get']('user:name') }}
  - shell: /bin/bash
  - home: {{ salt['pillar.get']('user:home') }}
  - uid: {{ salt['pillar.get']('user:id') }}
  - gid: {{ salt['pillar.get']('group:id') }}
  - system: True
  - require:
    - group: {{ salt['pillar.get']('group:name') }}
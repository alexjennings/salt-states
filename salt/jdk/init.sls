#sls

jdkbasedirectories:
  file.directory:
    - name: /usr/lib/jvm/releases/
    - makedirs: True


{% if salt['pillar.get']('jdk:version').startswith('1.6') %}
jdkextract:
  file.managed:
    - name: /usr/lib/jvm/releases/jdk{{ salt['pillar.get']('jdk:version') }}.bin
    - source: salt://jdk/files/jdk{{ salt['pillar.get']('jdk:version') }}.bin
    - mode: 777
    - require:
      - file: jdkbasedirectories
  cmd.run:
    - name: /usr/lib/jvm/releases/jdk{{ salt['pillar.get']('jdk:version') }}.bin -noregister
    - cwd: /usr/lib/jvm/releases/
    - unless: file /usr/lib/jvm/releases/jdk{{ salt['pillar.get']('jdk:version') }}/bin
    - require:
      - file: jdkextract
{% elif salt['pillar.get']('jdk:version').startswith('1.7') %}
jdkextract:
  file.managed:
    - name: /usr/lib/jvm/releases/jdk{{ salt['pillar.get']('jdk:version') }}.gz
    - source: salt://jdk/files/jdk{{ salt['pillar.get']('jdk:version') }}.gz
    - mode: 777
    - require:
      - file: jdkbasedirectories
  cmd.run:
    - name: tar xf jdk{{ salt['pillar.get']('jdk:version') }}.gz
    - cwd: /usr/lib/jvm/releases/
    - unless: file /usr/lib/jvm/releases/jdk{{ salt['pillar.get']('jdk:version') }}/bin
    - require:
      - file: jdkextract
{% endif %}


{% set alts = ['java', 'javac', 'javaws', 'jar'] -%}
{% for alt in alts %}
{{ alt }}:
  alternatives.install:
    - link: /usr/bin/{{ alt }}
    - path: /usr/lib/jvm/releases/jdk{{ salt['pillar.get']('jdk:version') }}/bin/{{ alt }}
    - priority: 1
    - require:
      - cmd: jdkextract
{% endfor %}
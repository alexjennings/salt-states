include:
  - postgresql

{% set sysctl = '/etc/sysctl.d/30-postgresql.conf' %}
{% set mem = (grains['mem_total'] / 2) %}
{% set shmmax = (1024**2 * mem * 1.1)|int %}
kernel.shmmax:
  sysctl.present:
    - config: {{ sysctl }}
    - value: {{ shmmax }}

{% set shmall =  (1 + (shmmax  / 4096))|int %}
kernel.shmall:
  sysctl.present:
    - config: {{ sysctl }}
    - value: {{ shmall }}

{% set shbuffers =  ((shmmax / 1073741824) - 1)|int %}
setsharedbuffers:
  file.sed:
    - name: /etc/postgresql/9.1/main/postgresql.conf
    - before: shared_buffers = 24MB
    - after: shared_buffers = {{ shbuffers }}GB
    - require:
      - sysctl: kernel.shmall
      - sysctl: kernel.shmmax

extend:
  postgresql:
    service:
      - watch:
        - file: setsharedbuffers

{% set devicepartition = ( pillar['device'] ~ pillar['partition'] ) %}
{% set lvpartition = ( pillar['vgname'] ~ '/' ~ pillar['lvname'] ) %}

scsiscan:
  pkg.installed:
    - name: scsitools
  cmd.run:
    - name: rescan-scsi-bus
    - require:
      - pkg: scsiscan
    - unless: file /dev/{{ devicepartition }}


partition:
  cmd.run:
    - name: echo "0,,8e" | sudo  sfdisk /dev/{{ salt['pillar.get']('device') }}
    - unless: file /dev/{{ devicepartition }}
    - require:
      - cmd: scsiscan

physicaldisk:
  lvm.pv_present:
    - name: /dev/{{ devicepartition }}
    - require:
      - cmd: partition

volumegroup:
  lvm.vg_present:
    - name: {{ salt['pillar.get']('vgname') }}
    - devices: /dev/{{ devicepartition }}
    - require:
      - lvm: physicaldisk

logicalvolume:
  lvm.lv_present:
    - name: {{ salt['pillar.get']('lvname') }}
    - vgname: {{ salt['pillar.get']('vgname') }}
    - size: {{ salt['pillar.get']('size') }}
    - require:
      - lvm: volumegroup

lvmkfs:
  cmd.run:
    - name: mkfs -T {{ salt['pillar.get']('fstype') }} /dev/{{ lvpartition }}
    - require:
      - lvm: logicalvolume
    - unless: file -sL /dev/{{ lvpartition }} | grep {{ salt['pillar.get']('fstype') }}

mount:
  mount.mounted:
    - name: {{ salt['pillar.get']('mountpoint') }}
    - device: /dev/{{ lvpartition }}
    - fstype: {{ salt['pillar.get']('fstype') }}
    - mkmnt: True
    - require:
      - cmd: lvmkfs


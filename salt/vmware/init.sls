#sls

vmwaredirectory:
  file.directory:
    - name: /opt/vmware
    - makedirs: True

vmwaretar:
  file.managed:
    - name: /opt/vmware/VMwareTools-{{ pillar['version'] }}.tar.gz
    - source: salt://vmware/VMwareTools-{{ pillar['version'] }}.tar.gz
    - require:
      - file.directory: /opt/vmware
  cmd.run:
    - name: tar -xf /opt/vmware/VMwareTools-{{ pillar['version'] }}.tar.gz 
    - cwd: /opt/vmware/
    - unless: file /opt/vmware/vmware-tools-distrib
    -  require:
       - file.managed: /opt/vmware/VMwareTools-{{ pillar['version'] }}.tar.gz


vmwareinstall:
  cmd.run:
    - name: /opt/vmware/vmware-tools-distrib/vmware-install.pl -d
    - unless: which vmtoolsd
    - require:
      - cmd.run: tar -xf /opt/vmware/VMwareTools-{{ pillar['version'] }}.tar.gz
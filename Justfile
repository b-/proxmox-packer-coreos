build:
    echo "burning installer.bu"
    just _butane config/installer.bu config/installer.ign
    echo "burning template.bu"
    just _butane config/template.bu config/template.ign

pack:
    packer build .

_butane bu ign:
    podman run --rm         \
     --security-opt label=disable          \
     --volume ".":/pwd --workdir /pwd \
     quay.io/coreos/butane:release         \
     "{{bu}}" > "{{ign}}"
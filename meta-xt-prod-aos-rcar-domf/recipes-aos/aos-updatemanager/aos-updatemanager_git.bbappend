FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = "\
    file://aos_updatemanager.cfg \
    file://aos-updatemanager.service \
    file://aos-reboot.service \
"

AOS_UM_UPDATE_MODULES ?= "\
    updatemodules/overlaysystemd \
"

inherit systemd

SYSTEMD_SERVICE_${PN} = "aos-updatemanager.service"

MIGRATION_SCRIPTS_PATH = "${base_prefix}/usr/share/aos/um/migration"

DEPENDS += " \
    pkgconfig-native \
    systemd \
    efivar \
"

RDEPENDS_${PN} += " \
    aos-rootca \
"

FILES_${PN} += " \
    ${sysconfdir} \
    ${systemd_system_unitdir} \
    ${MIGRATION_SCRIPTS_PATH} \
"

python do_update_componet_ids() {
    import json

    file_name = oe.path.join(d.getVar("D"), d.getVar("sysconfdir"), "aos", "aos_updatemanager.cfg")

    with open(file_name) as f:
        data = json.load(f)

    for update_module in data["UpdateModules"]:
        update_module["ID"] = d.getVar("BOARD_MODEL")+"-"+d.getVar("BOARD_VERSION")+"-"+update_module["ID"]

    with open(file_name, 'w') as f:
        json.dump(data, f, indent=4)
}

do_install_append() {
    install -d ${D}${sysconfdir}/aos
    install -m 0644 ${WORKDIR}/aos_updatemanager.cfg ${D}${sysconfdir}/aos

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/aos-updatemanager.service ${D}${systemd_system_unitdir}/aos-updatemanager.service
    install -m 0644 ${WORKDIR}/aos-reboot.service ${D}${systemd_system_unitdir}/aos-reboot.service

    install -d ${D}${MIGRATION_SCRIPTS_PATH}
    source_migration_path="src/${GO_IMPORT}/database/migration"
    if [ -d ${S}/${source_migration_path} ]; then
        install -m 0644 ${S}/${source_migration_path}/* ${D}${MIGRATION_SCRIPTS_PATH}
    fi
}

addtask update_componet_ids after do_install before do_package

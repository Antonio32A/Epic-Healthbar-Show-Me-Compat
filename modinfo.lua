name = "Epic Healthbar Show Me Compat"
author = "Antonio32A"
description = "Allows Epic Healthbar to work on servers with Show Me mod."
version = "1.2.0"
api_version = 10
priority = 2 ^ 1022 -- We want to load after Epic Healthbar if it's loaded on the server.

dont_starve_compatible = false
dst_compatible = true
reign_of_giants_compatible = false
shipwrecked_compatible = false

client_only_mod = true
all_clients_require_mod = false
server_only_mod = false

icon_atlas = "images/modicon.xml"
icon = "modicon.tex"

configuration_options = {}

mod_dependencies = {
    {
        workshop = "workshop-1185229307"
    }
}

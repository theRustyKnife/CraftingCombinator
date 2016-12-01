local migration = require "script.migration"


script.on_init(migration.init)
script.on_load(migration.load)
script.on_configuration_changed(migration.migrate)


require "script.events"

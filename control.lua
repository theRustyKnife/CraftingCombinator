local migration = require "script.migration"


script.on_init(migration.init)
script.on_configuration_changed(migration.migrate)


require "script.events"

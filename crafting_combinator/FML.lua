local config = {
	-- Settings that need to be configured to reflect the mod FML is installed in
	MOD = {
		NAME = "crafting_combinator",
	},
	
	
	LOG = {
		-- If true, log messages will be printed to the console as well
		IN_CONSOLE = true,
		
		-- If true, the respective level messsages will be logged. If false, the functions are replaced with empty ones,
		-- so it's safe to leave the calls in, without much performance loss.
		E = true,
		W = true,
		D = true,
	},
}


------- END OF CONFIG -------


local FML_import = next(remote.interfaces['therustyknife.FML.serialized']); FML_import = loadstring(FML_import)()
FML_import.module{}.init{module=FML_import.FML, stage='RUNTIME', args={local_config=config}}
return therustyknife.FML

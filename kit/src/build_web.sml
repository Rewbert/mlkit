
val _ = (SMLofNJ.Internals.GC.messages false;
	 print "\n ** Building the ML Kit compiler [SMLserver] **\n\n";
	 CM.make());

local
  structure K = KitKAM()
  fun enable s = K.Flags.turn_on s
  fun disable s =  K.Flags.turn_off s

in
  val _ = (disable "garbage_collection";
	   disable "cross_module_opt";   (* better module reuse *)
	   K.Flags.SMLserver := true;
           K.Flags.WEBserver := "AOLServer";
           (*K.Flags.WEBserver := "Apache";*)
	   enable "quotation";    (* support for quotation-antiquotation *)
(*	   enable "formtyping";  *) (* support for form typing *)
	   K.build_basislib() ;
	   K.install() 
	   )
end
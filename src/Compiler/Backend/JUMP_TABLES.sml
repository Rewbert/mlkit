signature JUMP_TABLES =
sig
(*
 val linear_search : (*sels*) ('sel * 'sinst) list *
		     (*default*) 'sinst *
                     (*comment*) (string * 'inst list -> 'inst list) *
		     (*new_label*) (string -> 'label) *
		     (*compile_sel*) ('sel * 'inst list -> 'inst list) *
		     (*if_no_match_go_lab*) ('label * 'inst list -> 'inst list) *
		     (*compile_insts*) ('sinst * 'inst list -> 'inst list) *
		     (*label*) ('label * 'inst list -> 'inst list) *
                     (*jmp*) ('label * 'inst list -> 'inst list) *
		     (*C*) 'inst list -> 'inst list

 val binary_search : (*sels *) (Int32.int*'sinst) list *
		     (*default*) 'sinst *
		     (*comment*) (string * 'inst list -> 'inst list) *
		     (*new_label*) (string -> 'label) *
		     (*compile_sel*) (Int32.int * 'inst list -> 'inst list) *
		     (*if_not_equal_go_lab*) ('label * 'inst list -> 'inst list) *
		     (*if_less_than_go_lab*) ('label * 'inst list -> 'inst list) *
		     (*if_greater_than_go_lab*) ('label * 'inst list -> 'inst list) *
		     (*compile_insts*) ('sinst * 'inst list -> 'inst list) *
		     (*label*) ('label * 'inst list -> 'inst list) *
		     (*jmp*) ('label * 'inst list -> 'inst list) *
		     (*sel_dist*) (Int32.int * Int32.int -> Int32.int) *
		     (*jump_table_header*) ('label * Int32.int * 'inst list -> 'inst list) *
		     (*add_label_to_jump_tab*) ('label * 'inst list -> 'inst list) *
		     (*eq_lab*) ('label * 'label -> bool) *
		     (*C*) 'inst list -> 'inst list
*)

 val linear_search_new : (*sels*) ('sel * 'sinst) list *
                         (*default*) 'sinst *
			 (*comment*) (string * 'inst list -> 'inst list) *
			 (*new_label*) (string -> 'label) *
			 (*if_no_match_go_lab_sel*) ('label * 'sel * 'inst list -> 'inst list) *
			 (*compile_insts*) ('sinst * 'inst list -> 'inst list) *
			 (*label*) ('label * 'inst list -> 'inst list) *
			 (*jmp*) ('label * 'inst list -> 'inst list) *
			 (*C*) 'inst list -> 'inst list

 val binary_search_new : (*sels *) (Int32.int*'sinst) list *
			 (*default*) 'sinst *
			 (*comment*) (string * 'inst list -> 'inst list) *
			 (*new_label*) (string -> 'label) *
			 (*if_not_equal_go_lab_sel*) ('label * Int32.int * 'inst list -> 'inst list) *
			 (*if_less_than_go_lab_sel*) ('label * Int32.int * 'inst list -> 'inst list) *
			 (*if_greater_than_go_lab_sel*) ('label * Int32.int * 'inst list -> 'inst list) *
			 (*compile_insts*) ('sinst * 'inst list -> 'inst list) *
			 (*label*) ('label * 'inst list -> 'inst list) *
			 (*jmp*) ('label * 'inst list -> 'inst list) *
			 (*sel_dist*) (Int32.int * Int32.int -> Int32.int) *
			 (*jump_table_header*) ('label * Int32.int * 'inst list -> 'inst list) *
			 (*add_label_to_jump_tab*) ('label * 'inst list -> 'inst list) *
			 (*eq_lab*) ('label * 'label -> bool) *
			 (*C*) 'inst list -> 'inst list

end
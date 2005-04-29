(* Path 6 -- new basis 1995-04-28, 1995-06-06, 1996-10-13 
   Code taken from MosML v 2.00 2003-09-05, nh *)

structure ScsPathMac : OS_PATH = 
  struct
    exception Path

    (* It would make sense to use substrings for internal versions of
     * fromString and toString, and to allocate new strings only when 
     * externalizing the strings.

     * Impossible cases: 
     UNIX: {isAbs = false, vol = _, arcs = "" :: _}
     Mac:  {isAbs = true,  vol = _, arcs = "" :: _}
     *)

    local 
      val op @ = List.@
      infix 9 sub
      val op sub = String.sub
      val substring = String.extract

      (* Modified extensively for Macintosh pathnames - 1995-09-17 e *)

      (* Mac pathnames differ from UNIX pathnames in many respects.
       It is generally impossible to tell from the Mac pathname itself
       - if the path is relative or absolute
       - if the path refers to a file or directory
       
       Slash is spelled ":"
       The root of the directory tree is referred to as "" and is an absolute
       path; otherwise, any name with no colons is considered a relative path.
       A name staring with a colon is always a relative path.
       A name ending in a colon is always a directory path.

       There are no special file names such as "." or ".."
       ":" is the current directory
       "::" is up one from the current directory
       ":::" is up two from the current directory, etc.
       ":a::b" = ":b", "a::b:" = "b:"

       It is safer to always include a colon in the pathname if you can.
       For example, instead of "foo" for a directory name
       use "foo:"  to refer to the absolute path
       use ":foo:" to refer to the relative path
       even though MacOS would allow all three names for the relative path.

       A pathname without colons is consider relative. This is what one usually
       wants (plain file names are looked for in the current directory first).
       This leads to odd behavior; e.g., (isCanonical "a") is false, and 
       (base "a.b") is ":a" -- oh well, it tends to work even if it looks weird.
       *)

      val slash = ":"
      val volslash = ""
      val relslash = ":"
      fun isslash c = c = #":"
      fun validVol s = s = ""

      (* empty name ""  => absolute
	first char ":" => relative
	other char ":" => absolute
        else, I picked => relative
      *)
      fun splitabsvolrest s =
	let val sz = size s
	in
	  if       sz = 0           then (true,  "", s)
	  else if isslash (s sub 0) then (false, "", substring(s, 1, NONE))
	       else let fun hasslash n =
		 if n <= 0 then (false, "", s)
		 else if isslash (s sub n)
			then (true, "", s)
		      else hasslash (n-1)
		    in hasslash (sz - 1) end
	end
    in
      val parentArc  = ""   (* not always! *)
      val currentArc = "."  (* not really! *)

      fun isAbsolute p = #1 (splitabsvolrest p)

      fun isRelative p = not (isAbsolute p);

      fun fromString p = 
	case splitabsvolrest p of
	  (true,  v,   "") => {isAbs=true,  vol = v, arcs = []}
	| (isAbs, v, rest) => {isAbs=isAbs, vol = v, 
			       arcs = String.fields isslash rest};
      fun isRoot p = 
	case splitabsvolrest p of
	  (true, _, "") => true
	| _             => false;

      fun getVolume p = #2 (splitabsvolrest p);
      fun validVolume{isAbs, vol} = validVol vol;

      fun toString (path as {isAbs, vol, arcs}) =
	let fun h []        res = res 
	      | h (a :: ar) res = h ar (a :: slash :: res)
	in  
	  if validVolume{isAbs=isAbs, vol=vol} then 
            case (isAbs, arcs) of
	      (false, []         ) => vol ^ relslash
	    | (false, [a]        ) => (* special case for simple filenames *)
		if a = "" then ":" else a
	    | (false, a1 :: arest) => 
		  String.concat (List.rev (h arest [a1, relslash, vol]))
	    | (true,  []         ) => vol ^ volslash
	    | (true, a1 :: arest ) => 
		  String.concat (List.rev (h arest [a1, volslash, vol])) 
	  else
            raise Path
	end;

      fun concat (p1, p2) =
	let fun stripslash path = 
	  let val sz = size path
	  in if sz > 0 andalso isslash (path sub (sz - 1)) then
	    substring(path, 0, SOME(sz - 1))
	     else path
	  end
	    val p2' = 
	      if size p2 > 0 andalso isslash (p2 sub 0)
		then substring(p2, 1, NONE)
	      else p2
	in
	  if p2 <> "" andalso isAbsolute p2 then raise Path
	  else
            case splitabsvolrest p1 of
	      (false, "",   "") =>     relslash ^ p2'
	    | (false, v,  path) => v ^ relslash ^ stripslash path ^ slash ^ p2'
	    | (true,  v,  ""  ) => v ^ volslash ^ p2'
	    | (true,  v,  path) => v ^ volslash ^ stripslash path ^ slash ^ p2'
	end;

      fun getParent p =
	let open List
	  fun getpar xs = 
            rev (case rev xs of
		   []                  => []         
		 | "" :: "" :: revrest => "" :: "" :: "" :: revrest
		 | "" ::  _ :: revrest => "" :: revrest
		 |       "" ::      [] => ["",""]
		 |        _ :: revrest => "" :: revrest)
	  val {isAbs, vol, arcs} = fromString p 
	in
	  case getpar arcs of 
            []   => 
	      if isAbs then toString {isAbs=true, vol=vol, arcs=[]}
	      else ":"
          | arcs => toString {isAbs=isAbs, vol=vol, arcs=arcs}
	end;

      fun canonize p =
	let val {isAbs, vol, arcs} = fromString p 
	  fun lastup []                 = if isAbs then [] else [""]
	    | lastup ( "" :: res) = "" :: "" :: res
	    | lastup (       res) = "" :: res
	  fun backup []                 = if isAbs then [] else [""]
	    | backup ( "" :: res) = "" :: "" :: res
	    | backup ( _  :: res) = res
	  fun reduce arcs = 
            let fun h []           []  = if isAbs then [] else [""]
                  | h []           res =             res
                  | h (""::[])     res =      (lastup res)
                  | h (""::ar)     res = h ar (backup res)
                  | h (a1::ar)     res = h ar (a1 :: res)
            in h arcs [] end
	in
	  {isAbs=isAbs, vol=vol, arcs=List.rev (reduce arcs)}
	end;

      fun mkCanonical p = toString (canonize p);

      fun parentize      []  = []
	| parentize (""::[]) = []
	| parentize (_ ::ar) = "" :: parentize ar;

      fun parentize' ar = "" :: parentize ar;

      fun mkRelative {path=p1, relativeTo=p2} =
	case (fromString p1, canonize p2) of
	  (_ ,                {isAbs=false,...}) => raise Path
	| ({isAbs=false,...}, _                ) => p1
	| ({vol=vol1, arcs=arcs1,...}, {vol=vol2, arcs=arcs2, ...}) =>
            let fun h []      []  = [""]
                  | h a1      []  = a1
                  | h a1 (""::[]) = a1
                  | h (""::[]) a2 = parentize' a2
                  | h      []  a2 = parentize' a2
                  | h (a1 as (a11::a1r)) (a2 as (a21::a2r)) =
                    if a11=a21 then h a1r a2r
                    else parentize a2 @ a1
            in
	      if vol1 <> vol2 then raise Path 
	      else toString {isAbs=false, vol="", arcs=h arcs1 arcs2}
            end;

(* 2005-04-27, knp: fun mkRelative (p1, p2) version is to be removed *)
      fun mkRelative (p1, p2) =
	case (fromString p1, canonize p2) of
	  (_ ,                {isAbs=false,...}) => raise Path
	| ({isAbs=false,...}, _                ) => p1
	| ({vol=vol1, arcs=arcs1,...}, {vol=vol2, arcs=arcs2, ...}) =>
            let fun h []      []  = [""]
                  | h a1      []  = a1
                  | h a1 (""::[]) = a1
                  | h (""::[]) a2 = parentize' a2
                  | h      []  a2 = parentize' a2
                  | h (a1 as (a11::a1r)) (a2 as (a21::a2r)) =
                    if a11=a21 then h a1r a2r
                    else parentize a2 @ a1
            in
	      if vol1 <> vol2 then raise Path 
	      else toString {isAbs=false, vol="", arcs=h arcs1 arcs2}
            end;


      fun mkAbsolute {path=p1, relativeTo=p2} =
	if isRelative p2 then raise Path
	else if isAbsolute p1 then p1
	     else mkCanonical(concat(p2, p1));

(* 2005-04-27, knp: fun mkAbsolute (p1, p2) version is to be removed *)
      fun mkAbsolute (p1, p2) =
	if isRelative p2 then raise Path
	else if isAbsolute p1 then p1
	     else mkCanonical(concat(p2, p1));

      fun isCanonical p = mkCanonical p = p;

      fun joinDirFile {dir, file} = concat(dir, file)

      fun splitDirFile p =
	let open List
	  val {isAbs, vol, arcs} = fromString p 
	in
	  case rev arcs of
            []            => 
	      {dir = toString {isAbs=isAbs, vol=vol, arcs=[]}, file = ""  }
          | "" :: _       => 
	      {dir = toString {isAbs=isAbs, vol=vol, arcs=arcs}, file = ""}
          | arcn :: [] => 
	      {dir = "", file = arcn}
          | arcn :: farcs => 
	      {dir = toString {isAbs=isAbs, vol=vol, arcs=rev ("" :: farcs)}, 
	       file = arcn}
	end

      fun dir s  = #dir (splitDirFile s);
      fun file s = #file(splitDirFile s);

      fun joinBaseExt {base, ext = NONE}    = base
	| joinBaseExt {base, ext = SOME ""} = base
	| joinBaseExt {base, ext = SOME ex} = base ^ "." ^ ex;

      fun splitBaseExt s =
	let val {dir, file} = splitDirFile s
	  open Substring 
	  val (fst, snd) = splitr (fn c => c <> #".") (all file)
	in 
	  if isEmpty snd         (* dot at right end     *) 
	    orelse isEmpty fst  (* no dot               *)
	    orelse size fst = 1 (* dot at left end only *) 
            then {base = s, ext = NONE}
	  else 
            {base = joinDirFile{dir = dir, 
                                file = string (trimr 1 fst)},
             ext = SOME (string snd)}
	end;
	
      fun ext s  = #ext  (splitBaseExt s);
      fun base s = #base (splitBaseExt s);
	
    end
  end (* Structure ScsPathMac *)
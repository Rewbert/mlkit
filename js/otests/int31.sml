(* File int31.sml: Testing Int31 operations.
 * Copyright (c) 1995-2014, Peter Sestoft, Martin Elsman.
 * MIT License.
 *)

open Utest
val _ = tstStart "structure Int31"

val range = fn p => fn f => range p (f o Int31.fromInt)
val tstrange = fn s => fn p => fn f => tstrange s p (f o Int31.fromInt)

local 
    open Int31
    infix 7 quot rem
    fun divmod s (i, d, q, r)  = tst s (i div d = q andalso i mod d = r)
    fun quotrem s (i, d, q, r) = tst s (i quot d = q andalso i rem d = r)
in      

val test1a = divmod "test1a" (10, 3, 3, 1)
val test1b = divmod "test1b" (~10, 3, ~4, 2)
val test1c = divmod "test1c" (~10, ~3, 3, ~1)
val test1d = divmod "test1d" (10, ~3, ~4, ~2)

val test2a = quotrem "test2a" (10, 3, 3, 1)
val test2b = quotrem "test2b" (~10, 3, ~3, ~1)
val test2c = quotrem "test2c" (~10, ~3, 3, ~1)
val test2d = quotrem "test2d" (10, ~3, ~3, 1)

val test3 = tst "test3" (max(~5, 2) =  2 andalso max(5, 2) = 5)
val test4 = tst "test4" (min(~5, 3) = ~5 andalso min(5, 2) = 2)

val test5 = tst "test5" (sign ~57 = ~1 andalso sign 99 = 1 andalso sign 0 = 0)
val test6 = tst "test6" (sameSign(~255, ~256) andalso sameSign(255, 256) 
                  andalso sameSign(0, 0))

val test12 = 
    tst "test12" (case (minInt, maxInt) of
                      (SOME mi, SOME ma) => (sign mi = ~1 andalso sign ma = 1 
                                             andalso sameSign(mi, ~1) andalso sameSign(ma, 1))
                    | (NONE, NONE)       => true
                    | _                  => false)

fun chk f (s, r) = 
    tst' "chk" (fn _ => 
           case f s of
               SOME res => res = r
             | NONE     => false)

fun chkScan fmt = chk (StringCvt.scanString (scan fmt))

val test13a = 
    List.map (chk fromString)
             [("10789", 10789),
              ("+10789", 10789),
              ("~10789", ~10789),
              ("-10789", ~10789),
              (" \n\t10789crap", 10789),
              (" \n\t+10789crap", 10789),
              (" \n\t~10789crap", ~10789),
              (" \n\t-10789crap", ~10789),
              ("0w123", 0),
              ("0W123", 0),
              ("0x123", 0),
              ("0X123", 0),
              ("0wx123", 0),
              ("0wX123", 0)]

val test13b = 
    List.map (fn s => tst "test13b" (case fromString s of NONE => true | _ => false))
           ["", "-", "~", "+", " \n\t", " \n\t-", " \n\t~", " \n\t+", 
            "+ 1", "~ 1", "- 1", "ff"]     

val test14a = 
    List.map (chkScan StringCvt.DEC)
             [("10789", 10789),
              ("+10789", 10789),
              ("~10789", ~10789),
              ("-10789", ~10789),
              (" \n\t10789crap", 10789),
              (" \n\t+10789crap", 10789),
              (" \n\t~10789crap", ~10789),
              (" \n\t-10789crap", ~10789),
              ("0w123", 0),
              ("0W123", 0),
              ("0x123", 0),
              ("0X123", 0),
              ("0wx123", 0),
              ("0wX123", 0)]

val test14b = 
    List.map (fn s => tst "test14b" (case StringCvt.scanString (scan StringCvt.DEC) s 
                                      of NONE => true | _ => false))
             ["", "-", "~", "+", " \n\t", " \n\t-", " \n\t~", " \n\t+", 
              "+ 1", "~ 1", "- 1", "ff"]     

val test15a = 
    List.map (chkScan StringCvt.BIN)
             [("10010", 18),
              ("+10010", 18),
              ("~10010", ~18),
              ("-10010", ~18),
              (" \n\t10010crap", 18),
              (" \n\t+10010crap", 18),
              (" \n\t~10010crap", ~18),
              (" \n\t-10010crap", ~18),
              ("0w101", 0),
              ("0W101", 0),
              ("0x101", 0),
              ("0X101", 0),
              ("0wx101", 0),
              ("0wX101", 0)]

val test15b = 
    List.map (fn s => tst "test15b" (case StringCvt.scanString (scan StringCvt.BIN) s 
                                      of NONE => true | _ => false))
             ["", "-", "~", "+", " \n\t", " \n\t-", " \n\t~", " \n\t+", 
              "+ 1", "~ 1", "- 1", "2", "8", "ff"]

val test16a = 
    List.map (chkScan StringCvt.OCT)
             [("2071", 1081),
              ("+2071", 1081),
              ("~2071", ~1081),
              ("-2071", ~1081),
              (" \n\t2071crap", 1081),
              (" \n\t+2071crap", 1081),
              (" \n\t~2071crap", ~1081),
              (" \n\t-2071crap", ~1081),
              ("0w123", 0),
              ("0W123", 0),
              ("0x123", 0),
              ("0X123", 0),
              ("0wx123", 0),
              ("0wX123", 0)]

val test16b = 
    List.map (fn s => tst "test16b" (case StringCvt.scanString (scan StringCvt.OCT) s 
                                      of NONE => true | _ => false))
             ["", "-", "~", "+", " \n\t", " \n\t-", " \n\t~", " \n\t+", 
              "+ 1", "~ 1", "- 1", "8", "ff"]

val test17a = 
    List.map (chkScan StringCvt.HEX)
             [("20Af", 8367),
              ("+20Af", 8367),
              ("~20Af", ~8367),
              ("-20Af", ~8367),
              (" \n\t20AfGrap", 8367),
              (" \n\t+20AfGrap", 8367),
              (" \n\t~20AfGrap", ~8367),
              (" \n\t-20AfGrap", ~8367),
              ("0w123", 0),
              ("0W123", 0),
              ("0x", 0),
              ("0x ", 0),
              ("0xG", 0),
              ("0X", 0),
              ("0XG", 0),
              ("0x123", 291),
              ("0X123", 291),
              ("-0x123", ~291),
              ("-0X123", ~291),
              ("~0x123", ~291),
              ("~0X123", ~291),
              ("+0x123", 291),
              ("+0X123", 291),
              ("0wx123", 0),
              ("0wX123", 0)]

val test17b = 
    List.map (fn s => tst "test17b" (case StringCvt.scanString (scan StringCvt.HEX) s 
                                      of NONE => true | _ => false))
             ["", "-", "~", "+", " \n\t", " \n\t-", " \n\t~", " \n\t+", 
              "+ 1", "~ 1", "- 1"]

local 
    fun fromToString i = 
        fromString (toString i) = SOME i

    fun scanFmt radix i = 
        StringCvt.scanString (scan radix) (fmt radix i) = SOME i

in
val test18 = 
    tst' "test18" (fn _ => range (~100, 100) fromToString)

val test19 = 
    tst' "test19" (fn _ => range (~100, 100) (scanFmt StringCvt.BIN))

val test20 = 
    tst' "test20" (fn _ => range (~100, 100) (scanFmt StringCvt.OCT))

val test21 = 
    tst' "test21" (fn _ => range (~100, 100) (scanFmt StringCvt.DEC))

val test22 = 
    tst' "test22" (fn _ => range (~100, 100) (scanFmt StringCvt.HEX))

val test23a = tst' "test23a" (fn _ => scanFmt StringCvt.HEX (valOf Int31.maxInt))
val test23b = tst' "test23b" (fn _ => scanFmt StringCvt.DEC (valOf Int31.maxInt))
val test23c = tst' "test23c" (fn _ => scanFmt StringCvt.OCT (valOf Int31.maxInt))
val test23d = tst' "test23d" (fn _ => scanFmt StringCvt.BIN (valOf Int31.maxInt))

val test24a = tst' "test24a" (fn _ => scanFmt StringCvt.HEX (valOf Int31.minInt))
val test24b = tst' "test24b" (fn _ => scanFmt StringCvt.DEC (valOf Int31.minInt))
val test24c = tst' "test24c" (fn _ => scanFmt StringCvt.OCT (valOf Int31.minInt))
val test24d = tst' "test24d" (fn _ => scanFmt StringCvt.BIN (valOf Int31.minInt))

val test25a = tst' "test25a" (fn _ => scanFmt StringCvt.HEX (valOf Int31.minInt + 10))
val test25b = tst' "test25b" (fn _ => scanFmt StringCvt.DEC (valOf Int31.minInt + 10))
val test25c = tst' "test25c" (fn _ => scanFmt StringCvt.OCT (valOf Int31.minInt + 10))
val test25d = tst' "test25d" (fn _ => scanFmt StringCvt.BIN (valOf Int31.minInt + 10))

fun chk' t f s = 
    tst' t (fn _ => ((f s; false) handle Overflow => true))
fun chkScanOvf t fmt = chk' t (StringCvt.scanString (scan fmt))

val test26a = chkScanOvf "test26a" StringCvt.HEX "~40000001"
val test26b = chkScanOvf "test26b" StringCvt.DEC "~1073741825"
val test26c = chkScanOvf "test26c" StringCvt.OCT "~10000000001"
val test26d = chkScanOvf "test26d" StringCvt.BIN "~1000000000000000000000000000001"

val test27a = chkScanOvf "test27a" StringCvt.HEX "40000000"
val test27b = chkScanOvf "test27b" StringCvt.DEC "1073741824"
val test27c = chkScanOvf "test27c" StringCvt.OCT "10000000000"
val test27d = chkScanOvf "test27d" StringCvt.BIN "1000000000000000000000000000000"

val test28a = tst' "test28a" (fn () => toString (valOf maxInt) = "1073741823")
val test28b = tst' "test28b" (fn () => toString (valOf minInt) = "~1073741824")

val test29a = tst' "test29a" (fn () => fromString "1073741823" = maxInt)
val test29b = tst' "test29b" (fn () => fromString "~1073741824" = minInt)

val test30a = tstrange "test30a" (~100,100) (fn k => k = fromLarge(toLarge k))
val test30b = tst' "test30b" (fn() => valOf maxInt = fromLarge(toLarge(valOf maxInt)))
val test30c = tst' "test30c" (fn() => valOf minInt = fromLarge(toLarge(valOf minInt)))
end
val _ = tstEnd()
end

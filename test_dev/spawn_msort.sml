signature THREAD = sig
  type 'a t
  val spawn : (unit->'a) -> ('a t->'b) -> 'b
  val get   : 'a t -> 'a
end

infix  7  * / div mod
infix  6  + - ^
infixr 5  :: @
infix  4  = <> > >= < <=
infix  3  := o
infix  0  before

local
fun exnName (e: exn) : string = prim("exnNameML", e)   (* exomorphic by copying *)

fun !(x: 'a ref): 'a = prim ("!", x)
fun (x: 'a ref) := (y: 'a): unit = prim (":=", (x, y))
fun op = (x: ''a, y: ''a): bool = prim ("=", (x, y))
fun not true = false | not false = true
fun a <> b = not (a = b)
fun print (s:string) : unit = prim("printStringML", s)
fun (s : string) ^ (s' : string) : string = prim ("concatStringML", (s, s'))
fun printNum (i:int) : unit = prim("printNum", i)

in
structure T :> THREAD = struct
  type thread = foreignptr
  type 'a t = (unit->'a) * thread
  fun get ((_,t0): 'a t) : 'a = prim("thread_get", t0)
  fun spawn (f: unit->'a) (k: 'a t -> 'b) : 'b =
      let val rf = ref f
          val fp_f : foreignptr = prim("pointer", !rf) (* very unsafe *)
          val () = if false then (f();()) else ()      (* mimic that spawn has the effect of calling f *)
          (*val () = prim("function_test", fp_f) *)
          val t0 : thread = prim("spawnone", fp_f)
          val t: 'a t = (f,t0)
          val res = k t
          val _ = get t                                (* make sure the thread has terminated before returning *)
          val () = prim("thread_free",t0)
      in res
      end
end
(*
structure T :> THREAD = struct
  type 'a t = 'a
  fun spawn f k = k(f())
  fun get x = x
end
*)
fun iota n =
    let fun loop (n,acc) =
            if n < 0 then acc
            else loop (n-1,n::acc)
    in loop (n-1,nil)
    end

fun repl n v =
    let fun loop (n,acc) =
            if n < 0 then acc
            else loop (n-1,v::acc)
    in loop (n-1,nil)
    end

fun rev xs =
    let fun loop (nil,acc) = acc
          | loop (x::xs,acc) = loop (xs,x::acc)
    in loop (xs,nil)
    end

fun map f xs =
    let fun loop (nil,acc) = rev acc
          | loop (x::xs,acc) = loop(xs,f x::acc)
    in loop (xs,nil)
    end

fun foldl f acc nil = acc
  | foldl f acc (x::xs) = foldl f (f(x,acc)) xs

fun fib x = if x < 2 then 1 else fib(x-1)+fib(x-2)

fun pair (f,g) (x,y) =
    T.spawn (fn () => f x)
            (fn t1 =>
                T.spawn (fn () => g y)
                        (fn t2 => (T.get t1,T.get t2)))

fun pmap f xs =
    let fun loop nil = nil
          | loop (x::xs) =
            T.spawn (fn () => f x)
                    (fn t =>
                        let val xs' = loop xs
                        in T.get t :: xs'
                        end)
    in loop xs
    end

fun calc n = foldl (op +) 0 (map fib (iota n))

fun myf n = map (fn x => x+1) (iota n)

fun cp nil = nil
  | cp (x::xs) = x :: cp xs

fun myfpmap nil = nil
  | myfpmap (x::xs) =
    T.spawn (fn () => myf x)
            (fn t =>
                let val xs' = myfpmap xs
                in cp(T.get t) :: xs'
                end)

fun length xs =
    let fun len (nil,n) = n
          | len (x::xs,n) = len(xs,n+1)
    in len(xs,0)
    end

fun split xs =
    let val h = length xs div 2
        fun tk (nil,n,acc) = (rev acc,nil)
          | tk (x::xs,n,acc) =
            if n < 1 then (rev acc,x::cp xs)
            else tk (xs,n-1,x::acc)
    in tk (xs,h,nil)
    end

fun merge (xs,ys) =
    case (xs,ys) of
        (nil,_) => cp ys
      | (_,nil) => cp xs
      | (x::xs',y::ys') =>
        if x < y then x :: merge (xs',ys)
        else y :: merge (xs,ys')

fun pmsort [] : int list = []
  | pmsort [x] = [x]
  | pmsort xs =
    let val (l,r) = split xs
    in T.spawn (fn() => pmsort l) (fn l =>
       T.spawn (fn() => pmsort r) (fn r =>
       merge (T.get l, T.get r)))
    end

val () = print "starting merge sort...\n"
val () =
    let val xs = [5,3,5,3,2,2,5,845,2,32,32,3,2,354,35,24,25,2,4,24,2,41,3,23,46,46,32,5,64,4,32,56,546,3]
        val res = pmsort xs
    in print "goodbye.\n"
    end
end

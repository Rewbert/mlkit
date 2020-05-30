signature THREAD = sig
  type 'a t
  val spawn : (unit->'a) -> ('a t->'b) -> 'b
  val get   : 'a t -> 'a
  val self  : unit -> 'a t
  val recv  : unit -> string
  val send  : (string * 'a t) -> unit
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
  type 'a t = thread
  fun get ((t0): 'a t) : 'a = prim("thread_get", t0)
  fun recv () : string        = prim("recv", ())
  fun send (msg,(t0))       = prim("send", (t0,msg))
  fun spawn (f: unit->'a) (k: 'a t -> 'b) : 'b =
      let val rf = ref f
          val fp_f : foreignptr = prim("pointer", !rf) (* very unsafe *)
          val t0 : thread = prim("spawnone", fp_f)
          val t: 'a t = (t0)
          val res = k t
          val _ = if true then get t else f()   (* make sure the thread has terminated before returning *)
                                                (* and mimic that, from a type perspective, spawn has *)
                                                (* the effect of calling f *)
          (* Notice that it is not safe to call `thread_free t0` here
           * as t0 may be live through later calls to `get t` *)

          (* What is needed is for the ThreadInfo structs to be region allocated and to
           * add finalisers (thread_free) to objects in these regions. *)
(*          val () = prim("thread_free", t0) *)
      in res
      end

  fun self () : 'a t = prim("self", ())
end

(*
structure T :> THREAD = struct
  type 'a t = 'a
  fun spawn f k = k(f())
  fun get x = x
end
*)

fun test () : int =
    let val f = T.spawn (fn () => 8 + 3) (fn t => fn () => T.get t)
    in f ()
    end

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

fun pmapMerge (f:'a->'c)
              (merge: 'c * 'b list->'b list)
              (xs:'a list) : 'b list =
  let fun g nil k = k()
        | g (x::xs) k =
          T.spawn (fn() => f x) (fn t =>
          g xs (fn() => merge(T.get t,k())))
  in  g xs (fn () => nil)
  end

fun sum xs = foldl (op +) 0 xs

fun f (a,b) =
    let val xs = map (fn x => (a+x) mod 10) (iota(b-a))
    in (sum xs, b-a)
    end

fun merge ((s,n),res) = (s,n)::res

fun myfun (xs:(int*int)list):(int*int)list =
    pmapMerge f merge xs

fun prList xs =
    (map (fn (x,_) => printNum x) xs
    ; ())

fun chk (x::(ys as y::xs)) =
    if x <= y then chk ys
    else "err\n"
  | chk _ = "ok\n"

exception Exception
fun deserialise str = case Int.fromString str of
                         SOME v => v
                       | _ => raise Exception

val _ = T.spawn (fn () => let val m1 = T.recv ()
                              val m2 = T.recv ()
                              val m3 = T.recv ()
                          in print (m1 ^ "\n" ^ m2 ^ "\n" ^ m3 ^ "\n") end)
                (fn t => (T.send ("First message",t); 
                          T.send ("Second message",t);
                          T.send ("Last message",t)))

(*
fun process t 0 = T.send (Int.toString 1, t)
  | process t n = let val self = T.self ()
                  in T.spawn (fn () => process self (n-1)) (fn _ => 
                     T.spawn (fn () => process self (n-1)) (fn _ => 
                     T.spawn (fn () => process self (n-1)) (fn _ =>
                     let
                       val m1 = deserialise (T.recv ())
                       val m2 = deserialise (T.recv ())
                       val m3 = deserialise (T.recv ())
                     in T.send (Int.toString (m1+m2+m3), t)
                     end))) end

val _ = T.spawn (fn () => print ((T.recv ()) ^ "\n")) (fn t => process t 3)*)
end

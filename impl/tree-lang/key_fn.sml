functor Key_Fn (
  val tag : string

) : sig
  type t 

  val inc : t -> t   
  
  val to_string : t -> string   

end = struct
  datatype t = Key of int

  fun inc (Key i) = Key (i + 1)

  fun to_string (Key i) = tag ^ "_" ^ (Int.toString i)

end
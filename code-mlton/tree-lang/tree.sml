structure Tree = struct

  datatype term = 
    Seq of (term * term * int) |
    Select of (term * string * int) |
    Pipe of (term * term * int) |
    Cns of (term * term * int) |
    Equiv of (term * term * int) |
    Implies of (term * term * int) |
    Or of (term * term * int) |
    And of (term * term * int) |
    Equal of (term * term * int) |

    Add of (term * term * int) |
    Sub of (term * term * int) |
    Mult of (term * term * int) |
    Div of (term * term * int) |
    Mod of (term * term * int) |
  
    AllocChan of int |
    Send of (term * int) |
    Recv of (term * int) |
    Wrap of (term * int) |
    Chse of (term * int) |
    Spawn of (term * int) |
    Sync of (term * int) |
    Solve of (term * int) |

    Not of (term * int) |
    Reduced of (term * int) |
    Blocked of (term * int) |
    Synced of (term * int) |
    Stuck of (term * int) |
    Done of (term * int) |
  
    AbsProp of ((string list) * term * int) |
    App of (term * term * int) |
    Fnc of (((term * term) list) * int) |
    Lst of ((term list) * int) |
    Rec of (((string * term) list) * int) |
  
    CatchAll of int |
    That of int |
    Bool of (bool * int) |
  
    Id of (string * int) |
    Num of (string * int) |
    Str of (string * int) |
    ChanId of int


  type contin = (
    string *
    term *
    (string -> (term option))
  )
  
  type contin_stack = (contin list)
  
  type chan_id = int

  datatype base_event =
    Base_Send of (chan_id * term * contin_stack) |
    Base_Recv of (chan_id * contin_stack)


  datatype transition_mode = 
    Mode_Alloc of int |
    Mode_Reduce of term |
    Mode_Spawn of term |
    Mode_Block of (base_event list) |
    Mode_Sync of (int * term) |
    Mode_Stuck of string |
    Mode_Done of term

  val empty_table = (fn key => NONE)

  fun insert (table, key, item) = (
    (fn key' => if key' = key then SOME item else (table key')) 
  )
  
  
  
  fun insert_table (val_store_base, val_store_top) = (
    (fn key => (case (val_store_top key) of
      SOME value => SOME value |
      NONE => (val_store_base key)
    ))
  )
  
  fun find (table, key) = (table key)
  
  fun remove (table, key) = (fn key' =>
    if key' = key then NONE else (table key')
  ) 



  fun to_string t = (case t of
    Seq (t1, t2, pos) => String.surround ("Seq@" ^ (Int.toString pos)) (
      (to_string t1) ^ ",\n" ^ (to_string t2)
    ) |

    Select (t1, name, pos) => String.surround ("Selec@" ^ (Int.toString pos)) (
      (to_string t1) ^ ", " ^ name
    ) |

    Pipe (t1, t2, pos) => String.surround ("Pipe@" ^ (Int.toString pos)) (
      (to_string t1) ^ ",\n" ^ (to_string t2)
    ) |

    Cns (t1, t2, pos) => String.surround ("Cns@" ^ (Int.toString pos)) (
      (to_string t1) ^ ",\n" ^ (to_string t2)) |

    Equiv (t1, t2, pos) => String.surround ("Equiv@_" ^ (Int.toString pos)) (
      (to_string t1) ^ ",\n" ^ (to_string t2)
    ) |

    Implies (t1, t2, pos) => String.surround ("Implies@" ^ (Int.toString pos)) (
      (to_string t1) ^ ",\n" ^ (to_string t2)
    ) |

    Or (t1, t2, pos) => String.surround ("Or@" ^ (Int.toString pos)) (
      (to_string t1) ^ ",\n" ^ (to_string t2)
    ) |

    And (t1, t2, pos) => String.surround ("And@" ^ (Int.toString pos)) (
      (to_string t1) ^ ",\n" ^ (to_string t2)
    ) |

    Equal (t1, t2, pos) => String.surround ("Equal@" ^ (Int.toString pos)) (
      (to_string t1) ^ ",\n" ^ (to_string t2)
    ) |

    Add (t1, t2, pos) => String.surround ("Add@" ^ (Int.toString pos)) (
      (to_string t1) ^ ",\n" ^ (to_string t2)
    ) |

    Sub (t1, t2, pos) => String.surround ("Sub@" ^ (Int.toString pos)) (
      (to_string t1) ^ ",\n" ^ (to_string t2)
    ) |

    Mult (t1, t2, pos) => String.surround ("Mult@" ^ (Int.toString pos)) (
      (to_string t1) ^ ",\n" ^ (to_string t2)
    ) |

    Div (t1, t2, pos) => String.surround ("Div@" ^ (Int.toString pos)) (
      (to_string t1) ^ ",\n" ^ (to_string t2)
    ) |

    Mod (t1, t2, pos) => String.surround ("Mod@" ^ (Int.toString pos)) (
      (to_string t1) ^ ",\n" ^ (to_string t2)
    ) |

    AllocChan pos =>
      "AllocChan@" ^ (Int.toString pos) |

    Send (t, pos) => String.surround ("Send@" ^ (Int.toString pos)) (
      (to_string t)
    ) |

    Recv (t, pos) => String.surround ("Recv@" ^ (Int.toString pos)) (
      (to_string t)
    ) |

    Wrap (t, pos) => String.surround ("Wrap@" ^ (Int.toString pos)) (
      (to_string t)
    ) |

    Chse (t, pos) => String.surround ("Chse@" ^ (Int.toString pos)) (
      (to_string t)
    ) |

    Spawn (t, pos) => String.surround ("Spawn@" ^ (Int.toString pos)) (
      (to_string t)
    ) |

    Sync (t, pos) => String.surround ("Sync@" ^ (Int.toString pos)) (
      (to_string t)
    ) |

    Solve (t, pos) => String.surround ("Solve@" ^ (Int.toString pos)) (
      (to_string t)
    ) |

    Not (t, pos) => String.surround ("Not@" ^ (Int.toString pos)) (
      (to_string t)
    ) |

    Reduced (t, pos) => String.surround ("Reduced@" ^ (Int.toString pos)) (
      (to_string t)
    ) |

    Blocked (t, pos) => String.surround ("Blocked@" ^ (Int.toString pos)) (
      (to_string t)
    ) |

    Synced (t, pos) => String.surround ("Synced@" ^ (Int.toString pos)) (
      (to_string t)
    ) |

    Stuck (t, pos) => String.surround ("Stuck@" ^ (Int.toString pos)) (
      (to_string t)
    ) |

    Done (t, pos) => String.surround ("Done@" ^ (Int.toString pos)) (
      (to_string t)
    ) |
  
    AbsProp (names, t, pos) => String.surround ("AbsProp@" ^ (Int.toString pos)) (
      "(" ^ (String.concatWith "," names) ^ "),\n" ^
      (to_string t)
    ) |

    App (t1, t2, pos) => String.surround ("App@" ^ (Int.toString pos)) (
      (to_string t1) ^ ",\n" ^
      (to_string t2)
    ) |

    Fnc (lams, pos) => String.surround ("Fnc@" ^ (Int.toString pos)) (
      String.concatWith ",\n" (List.map to_string_from_lam lams)) |

    Lst (ts, pos) => String.surround ("Lst@" ^ (Int.toString pos)) (
      String.concatWith ",\n" (List.map to_string ts)
    ) |

    Rec (fs, pos) => String.surround ("Rec@" ^ (Int.toString pos)) (
      String.concatWith ",\n" (List.map to_string_from_field fs)
    ) |
  
    CatchAll pos =>
      "CatchAll@" ^ (Int.toString pos) |

    That pos =>
      "That@" ^ (Int.toString pos) |

    Bool (true, pos) =>
      "True@" ^ (Int.toString pos) |

    Bool (false, pos) =>
      "False@" ^ (Int.toString pos) |
  
    Id (name, pos) =>
      "(Id@" ^ (Int.toString pos) ^ " " ^ name ^ ")" |

    Num (num, pos) =>
      "(Num@" ^ (Int.toString pos) ^ " " ^ num ^ ")" |

    Str (str, pos) =>
      "(Stringit@" ^ (Int.toString pos) ^ " " ^ str ^ ")" |

    ChanId i =>
      "(ChanId " ^ (Int.toString i) ^ ")"
  )

  and to_string_from_lam (t1, t2) = String.surround "Lam" (
    (to_string t1) ^ ",\n" ^
    (to_string t2)
  )

  and to_string_from_field (name, t) = String.surround name (
    (to_string t))


  fun store_insert (val_store, pat, value) = (case (pat, value) of
    (* **TODO** *)
    _ => NONE 
  )
  
  
  fun initial_thread t = (let
    val val_store = empty_table 
    val cont_stack = []
  in
    (t, val_store, [])
  end)

  fun sym i = "_g_" ^ (Int.toString i)

  fun normalize (
    t, term_fn, val_store, cont_stack,
    chan_store, block_store, cnt
  ) = (let
    val hole = sym cnt
    val cont = (hole, t, val_store)
    val cnt' = cnt + 1
    val cont_stack' = cont :: cont_stack
  in
    (
      Mode_Reduce t,
      [(term_fn (Id (hole, ~1)), val_store, cont_stack')],
      (chan_store, block_store, cnt')
    )
  end)

  fun return (
    result,
    val_store, cont_stack,
    chan_store, block_store, cnt
  ) = (let
    val (threads, md) = (case cont_stack of
      [] => ([], Mode_Done result) |
      (pat, t_body, val_store') :: cont_stack' => 
        (case store_insert (val_store', pat, result) of

          NONE => (
            [], Mode_Stuck "result does not match continuation hole pattern"
          ) |

          SOME val_store'' => (
            [(t_body, val_store'', cont_stack')],
            Mode_Reduce t_body  
          )

        )
    )
  in
    (
      md,
      threads,
      (chan_store, block_store, cnt)
    ) 
  end)


  fun resolve (val_store, t) = (case t of
    _ => NONE
    (* **TODO** *)
  )

  fun normalize_single_reduce (
    t, f,  
    val_store, cont_stack,
    chan_store, block_store, cnt,
    reduce_f
  ) = (case (resolve (val_store, t)) of
    NONE => normalize (
      t, fn v => (f v),
      val_store, cont_stack,
      chan_store, block_store, cnt
    ) |

    SOME v => (reduce_f v)
  )


  fun normalize_single_return (
    t, f, 
    val_store, cont_stack,
    chan_store, block_store, cnt
  ) = normalize_single_reduce (
    t, f, 
    val_store, cont_stack,
    chan_store, block_store, cnt,
    (fn v => return (
      (f v),
      val_store, cont_stack,
      chan_store, block_store, cnt
    ))
  )


  fun normalize_pair_reduce (
    (t1, t2), f,  
    val_store, cont_stack,
    chan_store, block_store, cnt,
    reduce_f
  ) = (case (
    resolve (val_store, t1),
    resolve (val_store, t2)
  ) of
    (NONE, _) => normalize (
      t1, fn v1 => f (v1, t2),
      val_store, cont_stack,
      chan_store, block_store, cnt
    ) |

    (_, NONE) => normalize (
      t2, fn v2 => f (t1, v2),
      val_store, cont_stack,
      chan_store, block_store, cnt
    ) |

    (SOME v1, SOME v2) => reduce_f (v1, v2)

  )


  fun normalize_pair_return (
    (t1, t2), f, 
    val_store, cont_stack,
    chan_store, block_store, cnt
  ) = normalize_pair_reduce (
    (t1, t2), f, 
    val_store, cont_stack,
    chan_store, block_store, cnt,
    (fn (v1, v2) => return (
      (f (v1, v2)),
      val_store, cont_stack,
      chan_store, block_store, cnt
    ))
  )

  fun fnc_equal (f1, f2) = (let
    (* **TODO** *)  
  in
    false
  end)

  fun num_add (n1, n2) = (let
    (* **TODO** *)  
  in
    n1 
  end)

  fun num_sub (n1, n2) = (let
    (* **TODO** *)  
  in
    n1 
  end)

  fun num_mult (n1, n2) = (let
    (* **TODO** *)  
  in
    n1 
  end)


  fun num_div (n1, n2) = (let
    (* **TODO** *)  
  in
    n1 
  end)

  fun num_mod (n1, n2) = (let
    (* **TODO** *)  
  in
    n1 
  end)

  fun seq_step (
    (t, val_store, cont_stack),
    (chan_store, block_store, cnt)
  ) = (case t of
    Seq (t1, t2, _) => normalize (
      t1, fn _ => t2,
      val_store, cont_stack,
      chan_store, block_store, cnt
    ) |

    Select (t, name, pos) => (case (resolve (val_store, t)) of

      NONE => normalize (
        t, fn v => Select (v, name, pos),
        val_store, cont_stack,
        chan_store, block_store, cnt
      ) |

      SOME (Rec (fields, _)) => (let
        val field_op = (List.find
          (fn (key, v) => key = name)
          fields
        )
      in
        (case field_op of
          SOME (_, v) => (
            Mode_Reduce v,
            [(v, val_store, cont_stack)],
            (chan_store, block_store, cnt)
          ) |

          NONE => (
            Mode_Stuck "selection from non-record",
            [], (chan_store, block_store, cnt)
          )
        )
      end) |

      _ => (
        Mode_Stuck "selection from non-record",
        [], (chan_store, block_store, cnt)
      )

    ) |

    Pipe (t_arg, t_fn, pos) => normalize_pair_reduce (
      (t_arg, t_fn), fn (t1, t2) => Pipe (t1, t2, pos),
      val_store, cont_stack,
      chan_store, block_store, cnt,
      (fn
        (v_arg, Fnc (lams, _)) => (let

          val hole = sym cnt
          val cont = (hole, t, val_store)
          val cnt' = cnt + 1
          val cont_stack' = cont :: cont_stack

          fun match_first lams = (case lams of
            [] => NONE |
            (p, t) :: lams' =>
              (case (store_insert (val_store, p, t_arg)) of
                NONE => match_first lams' |
                SOME val_store' => SOME (t, val_store')
              )
          )

          val (threads, md) = (case (match_first lams) of
            NONE => ([], Mode_Stuck "piped argument does not match pattern") |
            SOME (t_body, val_store') =>
              (
                [(t_body, val_store', cont_stack')],
                Mode_Reduce t_body 
              )
          )
        in
          (
            md,
            threads,
            (chan_store, block_store, cnt')
          )
        end) |

        _ => (
          Mode_Stuck "pipe into non-function",
          [], (chan_store, block_store, cnt)
        )
      )
    ) |

    Cns (t1, t2, pos) => normalize_pair_reduce (
      (t1, t2), fn (t1, t2) => Cns (t1, t2, pos),
      val_store, cont_stack,
      chan_store, block_store, cnt,
      (fn
        (v, Lst (ts, _)) => return (
          Lst (v :: ts, pos),
          val_store, cont_stack,
          chan_store, block_store, cnt
        ) |

        _ => (
          Mode_Stuck "cons with non-list",
          [], (chan_store, block_store, cnt)
        )
      )

    ) |

    Equiv (t1, t2, pos) => normalize_pair_reduce (
      (t1, t2), fn (t1, t2) => Equiv (t1, t2, pos),
      val_store, cont_stack,
      chan_store, block_store, cnt,
      (fn
        (Bool (b1, _), Bool (b2, _)) => return (
          Bool (b1 = b2, pos),
          val_store, cont_stack,
          chan_store, block_store, cnt
        ) |

        _ => (
          Mode_Stuck "<-> with non-boolean",
          [], (chan_store, block_store, cnt)
        )
      )

    ) |

    Implies (t1, t2, pos) => normalize_pair_reduce (
      (t1, t2), fn (t1, t2) => Implies (t1, t2, pos),
      val_store, cont_stack,
      chan_store, block_store, cnt,
      (fn
        (Bool (b1, _), Bool (b2, _)) => return (
          Bool (not b1 orelse b2, pos),
          val_store, cont_stack,
          chan_store, block_store, cnt
        ) |

        _ => (
          Mode_Stuck "--> with non-boolean",
          [], (chan_store, block_store, cnt)
        )
      )

    ) |

    Or (t1, t2, pos) => normalize_pair_reduce (
      (t1, t2), fn (t1, t2) => Or (t1, t2, pos),
      val_store, cont_stack,
      chan_store, block_store, cnt,
      (fn
        (Bool (b1, _), Bool (b2, _)) => return (
          Bool (b1 orelse b2, pos),
          val_store, cont_stack,
          chan_store, block_store, cnt
        ) |

        _ => (
          Mode_Stuck "\\/ with non-boolean",
          [], (chan_store, block_store, cnt)
        )
      )

    ) |

    And (t1, t2, pos) => normalize_pair_reduce (
      (t1, t2), fn (t1, t2) => And (t1, t2, pos),
      val_store, cont_stack,
      chan_store, block_store, cnt,
      (fn
        (Bool (b1, _), Bool (b2, _)) => return (
          Bool (b1 andalso b2, pos),
          val_store, cont_stack,
          chan_store, block_store, cnt
        ) |

        _ => (
          Mode_Stuck "/\\ with non-boolean",
          [], (chan_store, block_store, cnt)
        )
      )

    ) |

    Equal (t1, t2, pos) => normalize_pair_reduce (
      (t1, t2), fn (t1, t2) => Equal (t1, t2, pos),
      val_store, cont_stack,
      chan_store, block_store, cnt,
      (fn

        (Fnc f1, Fnc f2) => return (
          Bool (fnc_equal (f1, f2), pos),
          val_store, cont_stack,
          chan_store, block_store, cnt
        ) |

        (v1, v2) => return (
          Bool (v1 = v2, pos),
          val_store, cont_stack,
          chan_store, block_store, cnt
        )

      )

    ) |

    Add (t1, t2, pos) => normalize_pair_reduce (
      (t1, t2), fn (t1, t2) => Add (t1, t2, pos),
      val_store, cont_stack,
      chan_store, block_store, cnt,
      (fn
        (Num n1, Num n2) => return (
          Num (num_add (n1, n2)),
          val_store, cont_stack,
          chan_store, block_store, cnt
        ) |

        _ => (
          Mode_Stuck "+ with non-number",
          [], (chan_store, block_store, cnt)
        )
      )

    ) |

    Sub (t1, t2, pos) => normalize_pair_reduce (
      (t1, t2), fn (t1, t2) => Sub (t1, t2, pos),
      val_store, cont_stack,
      chan_store, block_store, cnt,
      (fn
        (Num n1, Num n2) => return (
          Num (num_sub (n1, n2)),
          val_store, cont_stack,
          chan_store, block_store, cnt
        ) |

        _ => (
          Mode_Stuck "- with non-number",
          [], (chan_store, block_store, cnt)
        )
      )

    ) |

    Mult (t1, t2, pos) => normalize_pair_reduce (
      (t1, t2), fn (t1, t2) => Mult (t1, t2, pos),
      val_store, cont_stack,
      chan_store, block_store, cnt,
      (fn
        (Num n1, Num n2) => return (
          Num (num_mult (n1, n2)),
          val_store, cont_stack,
          chan_store, block_store, cnt
        ) |

        _ => (
          Mode_Stuck "* with non-number",
          [], (chan_store, block_store, cnt)
        )
      )

    ) |


    Div (t1, t2, pos) => normalize_pair_reduce (
      (t1, t2), fn (t1, t2) => Div (t1, t2, pos),
      val_store, cont_stack,
      chan_store, block_store, cnt,
      (fn
        (Num n1, Num n2) => return (
          Num (num_div (n1, n2)),
          val_store, cont_stack,
          chan_store, block_store, cnt
        ) |

        _ => (
          Mode_Stuck "/ with non-number",
          [], (chan_store, block_store, cnt)
        )
      )

    ) |

    Mod (t1, t2, pos) => normalize_pair_reduce (
      (t1, t2), fn (t1, t2) => Mod (t1, t2, pos),
      val_store, cont_stack,
      chan_store, block_store, cnt,
      (fn
        (Num n1, Num n2) => return (
          Num (num_mod (n1, n2)),
          val_store, cont_stack,
          chan_store, block_store, cnt
        ) |

        _ => (
          Mode_Stuck "% with non-number",
          [], (chan_store, block_store, cnt)
        )
      )

    ) |

    AllocChan i => (let
      val chan_store' = insert (chan_store, cnt, ([], []))
      val cnt' = cnt + 1
    in
      return (
        ChanId cnt,
        val_store, cont_stack,
        chan_store', block_store, cnt'
      )
    end) |

    Send (t, pos) => normalize_single_return (
      t, fn v => Send (v, pos), 
      val_store, cont_stack,
      chan_store, block_store, cnt
    ) | 

    Recv (t, pos) => normalize_single_return (
      t, fn v => Recv (v, pos) ,
      val_store, cont_stack,
      chan_store, block_store, cnt
    ) | 

    Wrap (t, pos) => normalize_single_return (
      t, fn v => Wrap (v, pos),
      val_store, cont_stack,
      chan_store, block_store, cnt
    ) | 

    Chse (t, pos) => normalize_single_return (
      t, fn v => Chse (v, pos),
      val_store, cont_stack,
      chan_store, block_store, cnt
    ) | 


    _ => (
      Mode_Stuck "TODO",
      [], (chan_store, block_store, cnt)
    )


    (* **TODO** *)
    (*

  
    Spawn of (term * int) |
    Sync of (term * int) |
    Solve of (term * int) |

    Not of (term * int) |
    Reduced of (term * int) |
    Blocked of (term * int) |
    Synced of (term * int) |
    Stuck of (term * int) |
    Done of (term * int) |
  
    AbsProp of ((string list) * term * int) |
    App of (term * term * int) |
    Fnc of (((term * term) list) * int) |
    Lst of ((term list) * int) |
    Rec of (((string * term) list) * int) |
  
    CatchAll of int |
    That of int |
    Bool of (bool * int) |
  
    Id of (string * int) |
    Num of (string * int) |
    Str of (string * int)
    *)

  )

  fun string_from_mode md = (case md of
    (* **TODO **)
    _ => ""
    (*
    *)
  )


  fun concur_step (
    threads, env 
  
  ) = (case threads of
    [] => (print "all done!\n"; NONE) |
    thread :: threads' => (let
      val (md, seq_threads, env') = (seq_step (thread, env)) 
      val _ = print ((string_from_mode md) ^ "\n")
    in
      SOME (md, (threads' @ seq_threads, env'))
    end)
  )



  fun run t = (let

    val thread = initial_thread t

    val chan_store = empty_table
    val block_store = empty_table
    val cnt = 0

    fun loop cfg = (case (concur_step cfg) of
      NONE => () |
      SOME (md, cfg') =>
        loop cfg' 
    )
  
  in
    loop (
      [thread],
      (chan_store, block_store, cnt)
    )
  end)




end
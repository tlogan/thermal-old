structure Tree = struct

  type chan_id = int
  type thread_id = int

  type ('a, 'b) store = ('a * 'b) list

  datatype left_right = Left | Right

  type infix_option = (left_right * int) option

  datatype event = 
    Alloc_Chan |
    Send |
    Recv |
    Latch |
    Choose |
    Offer |
    Block

  datatype effect =
    Stage |
    Sync |
    Bind |
    Spawn |
    Par

  datatype contin_mode = Contin_With | Contin_Norm | Contin_App | Contin_Sync

  datatype term = 
    Blank of int |
    Sym of (term * int) |
    Id of (string * int) |
    Assoc of (term * int) |
    Log of (term * int) |

    List_Intro of (term * term * int) |

    (* TODO: factor out single Val constructor *)
    List_Val of ((term list) * int) |

    Func_Intro of (
      ((term * term) list) *
      int
    ) (* Func_Val (lams, pos) *) |

    Func_Val of (
      ((term * term) list) *
      ((string, infix_option * term) store) *
      ((string, infix_option * ((term * term) list)) store) *
      int
    ) (* Func_Val (lams, val_store, mutual_store, pos) *) |

    App of (term * term * int) |

    Compo of (term * term * int) |
    With of (term * term * int) |

    Rec_Intro of (
      ((string * (infix_option * term)) list) *
      int
    ) (* Rec_Intro (fields, pos) *) |

    Rec_Intro_Mutual of (
      ((string * (infix_option * term)) list) *
      int
    ) (* Rec_Intro (fields, pos) *) |

    Rec_Val of (
      ((string * (infix_option * term)) list) *
      int
    ) (* Rec_Intro (fields, pos) *) |

    Select of (term * int) |
  

    Event_Intro of (event * term * int) |
    Event_Val of transaction list |

    Effect_Intro of (effect * term * int) |
    Effect_Val of base_effect |
  
    String_Val of (string * int) |

    Num_Val of (string * int) |

    Num_Add of (term * int) |
    Num_Sub of (term * int) |
    Num_Mul of (term * int) |
    Num_Div of (term * int) |

    (* internal reps *)
    Chan_Loc of int |
    ThreadId of int |
    Error of string


  and base_event =
    Base_Alloc_Chan | 
    Base_Send of chan_id * term |
    Base_Recv of chan_id |
    Base_Offer of term |
    Base_Block

  and base_effect =
    Base_Stage of term |
    Base_Sync of transaction list |
    Base_Bind of base_effect * contin list |
    Base_Spawn of base_effect |
    Base_Par of base_effect

  and transaction = Tx of base_event * contin list 

  and contin = Contin of (
    contin_mode * 
    ((term * term) list) *
    ((string, infix_option * term) store) *
    ((string, infix_option * (term * term) list) store)
  )


  datatype transition_mode = 
    Mode_Start |
    Mode_Suspend |
    Mode_Reduce of term |
    Mode_Continue |
    Mode_Spawn of term |
    Mode_Block of (base_event list) |
    Mode_Sync of (int * term * int * int)
      (* Mode_Sync (thread_id, msg, send_id, recv_id) *) |
    Mode_Stick of string |
    Mode_Finish of term


  val surround_with = String.surround_with
  val surround = String.surround
(*
  fun surround tag body = (let
    val abc = "(" ^ tag
    val bodyLines = String.tokens (fn c => c = #"\n") body
    val indentedLines = map (fn l => "  " ^ l) bodyLines
    val indentedBody = String.concatWith "\n" indentedLines 
    val xyz = if body = "" then ")" else "\n" ^ indentedBody ^ ")"
  in
    abc ^ xyz 
  end)
*)

  fun from_infix_option_to_string fix_op = (case fix_op of
    SOME (Left, d) => " infixl d" ^ (Int.toString d) |
    SOME (Right, d) => " infixr d" ^ (Int.toString d) |
    NONE => ""
  )

  fun event_to_string evt = (case evt of
    Alloc_Chan => "alloc_chan" |
    Send => "send" |
    Recv => "recv" |
    Latch => "latch" |
    Choose => "choose" |
    Offer => "offer" | 
    Block => "block"
  )

  fun to_string t = (case t of

    Assoc (t, pos) => "(" ^ (to_string t) ^ ")" |

    Log (t, pos) => "log " ^  (to_string t) |
    Sym (t, pos) => "sym " ^ (to_string t) |

    List_Intro (t1, t2, pos) => (
      (to_string t1) ^ ", " ^ (to_string t2)
    ) |

    List_Val (ts, pos) => surround "" ( 
      String.concatWith "\n" (List.map (fn t => "# " ^ (to_string t)) ts)
    ) |

    Func_Intro (lams, pos) => String.surround "" (
      String.concatWith "\n" (List.map (fn t => (from_lam_to_string t)) lams)
    ) |

    Func_Val (lams, fnc_store, mutual_store, pos) => String.surround "val" (
      String.concatWith "\n" (List.map (fn t => (from_lam_to_string t)) lams)
    ) |

    Compo (t1, t2, pos) => "(compo " ^ (to_string t1) ^ " " ^ (to_string t2) ^")"|

    App (t1, t2, pos) => surround "apply" (
      (to_string t1) ^ " " ^ (to_string t2)
    ) |

    With (t1, t2, pos) => "with " ^ (to_string t1) ^ "\n" ^ (to_string t2) |

    Rec_Intro (fs, pos) => String.surround "" (
      String.concatWith ",\n" (List.map from_field_to_string fs)
    ) |

    Rec_Intro_Mutual (fs, pos) => String.surround "mutual" (
      String.concatWith ",\n" (List.map from_field_to_string fs)
    ) |

    Rec_Val (fs, pos) => String.surround "val" (
      String.concatWith ",\n" (List.map from_field_to_string fs)
    ) |

    Select (t, pos) => "select " ^ (to_string t) |

    Event_Intro (evt, t, pos) => "evt " ^ (event_to_string evt) ^ (to_string t) |

    Event_Val transactions => String.surround "evt_val" (
      String.concatWith "\n" (List.map transaction_to_string transactions)
    ) |

    _ => "(NOT YET IMPLEMENTED)"

    (*
    Sync (t, pos) => "sync " ^ (to_string t) |

    Spawn (t, pos) => "spawn " ^ (to_string t) |

    Par (t, pos) =>  surround_with "<|" "" (to_string t) "|>" |

    Blank pos => "()" |

    Id (name, pos) => name |

    String_Val (str, pos) => str |

    Chan_Loc i => "chan_loc_" ^ (Int.toString i) |

    ThreadId i => "thread_" ^ (Int.toString i) |


    Num_Val (num, pos) => num |

    Num_Add (t, pos) => "add " ^ (to_string t) |

    Num_Sub (t, pos) => "sub " ^ (to_string t) |

    Num_Mul (t, pos) => "mul " ^ (to_string t) |

    Num_Div (t, pos) => "div " ^ (to_string t) |

    Error msg => "(ERROR: " ^ msg ^ ")"
    *)

  )

  and from_lam_to_string (t1, t2) = String.surround "" (
    "case "  ^ (to_string t1) ^ " => " ^ (to_string t2)
  )

  and from_field_to_string (name, (fix_op, t)) = String.surround "" (
    "def "  ^ name ^ (from_infix_option_to_string fix_op) ^ " : " ^ (to_string t)
  )

  and transaction_to_string (Tx (bevt, wrap_stack)) =
    String.surround "transaction" (
      (base_event_to_string bevt) ^ "\n" ^ (stack_to_string wrap_stack)
    )

  and base_event_to_string bevt = (case bevt of  

    Base_Alloc_Chan => "alloc_chan" |

    Base_Send (i, msg) => String.surround "base_send " (
      (Int.toString i) ^ (to_string msg)
    ) |

    Base_Recv i => String.surround "base_recv " (
      (Int.toString i)
    ) |

    _ => "(NOT IMPLE: base_event_to_string)"

  )


  and stack_to_string stack = (String.surround "stack" (
    String.concatWith "\n" (map contin_to_string stack)
  ))

  and contin_to_string cont = "CONTIN TODO"


  val empty_table = [] 

  fun insert (table, key, item) = (
    (key, item) :: table
  )
  
  
  fun insert_table (val_store_base, val_store_top) = (
    val_store_top @ val_store_base
  )
  
  fun find (table, key) =
  (Option.map
    (fn (k, v) => v)
    (List.find (fn (k, v) => k = key) table)
  )
  
  fun remove (table, key) =
  (List.filter
    (fn k => k <> key)
    table
  ) 


(*

  fun num_add (n1, n2) = (let
    val i1 = (valOf o Int.fromString) n1
    val i2 = (valOf o Int.fromString) n2
    val i3 = i1 + i2
    val str = Int.toString i3
  in
    str
  end)

  fun num_sub (n1, n2) = (let
    val i1 = (valOf o Int.fromString) n1
    val i2 = (valOf o Int.fromString) n2
    val i3 = i1 - i2
  in
    Int.toString i3
  end)

  fun num_mul (n1, n2) = (let
    val i1 = (valOf o Int.fromString) n1
    val i2 = (valOf o Int.fromString) n2
    val i3 = i1 * i2
  in
    Int.toString i3
  end)


  fun num_div (n1, n2) = (let
    val i1 = (valOf o Int.fromString) n1
    val i2 = (valOf o Int.fromString) n2
    val i3 = i1 div i2
  in
    Int.toString i3
  end)

  fun num_rem (n1, n2) = (let
    val i1 = (valOf o Int.fromString) n1
    val i2 = (valOf o Int.fromString) n2
    val i3 = Int.rem (i1, i2)
  in
    Int.toString i3
  end)



  fun poll (base, chan_store, block_store) = (case base of
    Base_Send (i, msg, _) =>
      (let
        val chan_op = find (chan_store, i)
        fun poll_recv (send_q, recv_q) = (case recv_q of
          [] => (false, chan_store) |
          (block_id, cont_stack, _) :: recv_q' =>
            (case (find (block_store, block_id)) of
                SOME () => (true, chan_store) |
                NONE => poll (
                  base,
                  insert (chan_store, i, (send_q, recv_q')),
                  block_store
                )
            )
        )
      in
        (case chan_op of
          NONE =>
            (false, chan_store) |
          SOME chan =>
            (poll_recv chan)
        )
      end) |
  
     Base_Recv (i, _) =>
      (let
        val chan_op = find (chan_store, i)
        fun poll_send (send_q, recv_q) = (case send_q of
          [] => (false, chan_store) |
          (block_id, cont_stack, msg, _) :: send_q' =>
            (case (find (block_store, block_id)) of
              SOME () => (true, chan_store) |
              NONE => poll (
                base,
                insert (chan_store, i, (send_q', recv_q)),
                block_store
              )
            )
        )
      in
        (case chan_op of
          NONE =>
          (false, chan_store) |
          SOME chan =>
          (poll_send chan)
        )
      end)
  
  )


  fun find_active_transaction (
    transactions, chan_store, block_store
  ) = (case transactions of

    [] =>
      (NONE, chan_store) |

    transaction :: transactions' => (let
      val (is_active, chan_store') = poll (transaction, chan_store, block_store)
    in
      if is_active then
        (SOME transaction, chan_store')
      else 
        find_active_transaction (transactions', chan_store', block_store)
    end)
      
  )

  
  fun proceed (
    (bevt, wrap_stack), cont_stack, thread_id,
    (chan_store, block_store, sync_store, cnt)
  ) = (case bevt of

    Base_Send (i, msg) =>
    (let
      val chan_op = find (chan_store, i)
      val recv_op = (case chan_op of
        SOME (_, (block_id, recv_stack, recv_thread_id) :: recvs) =>
          SOME (recv_stack, recv_thread_id) | 
        SOME (_, []) => NONE |
        NONE => NONE
      )
      val (threads, md') = (case recv_op of
        NONE => ([], Mode_Stick "proceed Base_Send") |
        SOME (recv_stack, recv_thread_id) => (
          [
            (Blank 0, empty_table, wrap_stack @ cont_stack, thread_id),
            (msg, empty_table, recv_stack, recv_thread_id)
          ],
          Mode_Sync (i, msg, thread_id, recv_thread_id)
        )
      ) 

      val chan_store' = (case chan_op of
        SOME (sends, []) => insert (chan_store, i, (sends, [])) |
        SOME (sends, recv :: recvs) => insert (chan_store, i, (sends, recvs)) |
        NONE => chan_store 
      )

    in
      (
        md', 
        threads,
        (chan_store', block_store, sync_store, cnt)
      ) 
    end) |
  
    Base_Recv i =>
    (let
      val chan_op = find (chan_store, i)
      val send_op = (case chan_op of
        SOME ((block_id, send_stack, msg, send_thread_id) :: sends, _) =>
          SOME (send_stack, msg, send_thread_id) | 
        SOME ([], _) => NONE |
        NONE => NONE
      )
  
      val (threads, md') = (case send_op of
        NONE => ([], Mode_Stick "proceed Base_Recv") |
        SOME (send_stack, msg, send_thread_id) => (
          [
            (Blank 0, empty_table, send_stack, send_thread_id),
            (msg, empty_table, wrap_stack @ cont_stack, thread_id)
          ],
          Mode_Sync (i, msg, send_thread_id, thread_id)
        )
      )


      val chan_store' = (case chan_op of
        SOME ([], recvs) => insert (chan_store, i, ([], recvs)) |
        SOME (send :: sends, recvs) => insert (chan_store, i, (sends, recvs)) |
        NONE => chan_store 
      )
    in
      (
        md',
        threads,
        (chan_store', block_store, sync_store, cnt)
      )
    end)
  
  )
  
  fun block_one ((bevt, wrap_stack), cont_stack, chan_store, block_id, thread_id) = (case bevt of
    Base_Send (i, msg) =>
      (let
        val cont_stack' = wrap_stack @ cont_stack
        val chan_op = find (chan_store, i)
        val chan' = (case chan_op of
          NONE =>
            ([(block_id, cont_stack', msg, thread_id)], []) |
          SOME (send_q, recv_q) =>
            (send_q @ [(block_id, cont_stack', msg, thread_id)], recv_q)
        )
        val chan_store' = insert (chan_store, i, chan')
      in
        chan_store'
      end) |
  
    Base_Recv i =>
      (let
        val cont_stack' = wrap_stack @ cont_stack
        val chan_op = find (chan_store, i)
        val chan' = (case chan_op of
          NONE =>
            ([], [(block_id, cont_stack', thread_id)]) | 
          SOME (send_q, recv_q) =>
            (send_q, recv_q @ [(block_id, cont_stack', thread_id)])
        )
        val chan_store' = insert (chan_store, i, chan')
      in
        chan_store'
      end)
  
  )
  
  fun block (
    base_events, cont_stack, thread_id,
    (chan_store, block_store, sync_store, cnt)
  ) = (let
    val chan_store' = (List.foldl  
      (fn (bevt, chan_store) =>
        block_one (bevt, cont_stack, chan_store, cnt, thread_id)
      )
      chan_store
      base_events
    )
    val block_store' = insert (block_store, cnt, ())
    val cnt' = cnt + 1
  in
    (Mode_Block base_events, [], (chan_store', block_store', sync_store, cnt'))
  end)

  *)


  fun is_value t = (case t of
    Blank _ => true |
    List_Val _ => true |
    Func_Val _ => true | 
    Rec_Val _ => true |
    String_Val _ => true |
    Num_Val _ => true |
    Chan_Loc _ => true |
    Event_Val _ => true |
    Effect_Val _ => true |
    Error _ => true |
    _ => false 
  )

  fun match_symbolic_term_insert val_store (pattern, symbolic_term) = (case (pattern, symbolic_term) of
    (Blank _, _) => SOME val_store |

    (Sym (Id (id, _), _), _) => (let
      val thunk = Func_Val ([(Blank ~1, symbolic_term)], val_store, [], ~1)
    in
      SOME (insert (val_store, id, (NONE, thunk)))
    end) |

    (Id (p_id, _), Id (st_id, _)) =>
    (if p_id = st_id then
      SOME val_store
    else
      NONE
    ) |

    (Assoc (p, _), Assoc (st, _)) =>
      match_symbolic_term_insert val_store (p, st) |

    (Log (p, _), Log (st, _)) =>
      match_symbolic_term_insert val_store (p, st) |

    (List_Intro (p1, p2, _), List_Intro (st1, st2, _)) => (
      (Option.mapPartial
        (fn val_store' =>
          match_symbolic_term_insert val_store' (p2, st2)
        )
        (match_symbolic_term_insert val_store (p1, st1))
      )
    ) |

    (List_Val (ps, _), List_Val (sts, _)) =>
    (if (List.length ps = List.length sts) then
      (List.foldl
        (fn ((p, st), val_store_op) => 
          (Option.mapPartial
            (fn val_store' =>
              match_symbolic_term_insert val_store' (p, st)
            )
            val_store_op
          )
        )
        (SOME val_store)
        (ListPair.zip (ps, sts))
      )
    else
      NONE
    ) |

    (Func_Intro (p_lams, _), Func_Intro (st_lams, _)) =>
      from_lams_match_symbolic_term_insert val_store (p_lams, st_lams) |

    (Func_Val (p_lams, _, _, _), Func_Val (st_lams, _, _, _)) =>
      from_lams_match_symbolic_term_insert val_store (p_lams, st_lams) |

    
    (App (p1, p2, _), App (st1, st2, _)) =>
    (Option.mapPartial
      (fn val_store' =>
        match_symbolic_term_insert val_store' (p2, st2)
      )
      (match_symbolic_term_insert val_store (p1, st1))
    ) |

    (Compo (p1, p2, _), Compo (st1, st2, _)) => (
      (Option.mapPartial
        (fn val_store' =>
          match_symbolic_term_insert val_store' (p2, st2)
        )
        (match_symbolic_term_insert val_store (p1, st1))
      )
    ) |

    (With (p1, p2, _), With (st1, st2, _)) =>
    (Option.mapPartial
      (fn val_store' =>
        match_symbolic_term_insert val_store' (p2, st2)
      )
      (match_symbolic_term_insert val_store (p1, st1))
    ) |

    (Rec_Intro (p_fields, _), Rec_Intro (st_fields, _)) =>
      from_fields_match_symbolic_term_insert val_store (p_fields, st_fields) |

    (Rec_Intro_Mutual (p_fields, _), Rec_Intro_Mutual (st_fields, _)) =>
      from_fields_match_symbolic_term_insert val_store (p_fields, st_fields) |

    (Rec_Val (p_fields, _), Rec_Val (st_fields, _)) =>
      from_fields_match_symbolic_term_insert val_store (p_fields, st_fields) |

    (Select (p, _), Select (st, _)) =>
      match_symbolic_term_insert val_store (p, st) |

    (Event_Intro (p_evt, p, _), Event_Intro (st_evt, st, _)) =>
      if p_evt = st_evt then match_symbolic_term_insert val_store (p, st)
      else NONE |

(*
TODO:
    (Event_Val p_transactions, Event_Val st_transactions) =>
      match_symbolic_transactions_insert val_store (p_transactions, st_transactions) |
*)

    (Effect_Intro (p_effect, p, _), Effect_Intro (st_effect, st, _)) =>
      if p_effect = st_effect then match_symbolic_term_insert val_store (p, st)
      else NONE |

    (String_Val (p_str, _), String_Val (st_str, _)) =>
    (if p_str = st_str then
      SOME val_store
    else
      NONE
    ) |

    (Num_Val (p_str, _), Num_Val (st_str, _)) =>
    (if p_str = st_str then
      SOME val_store
    else
      NONE
    ) |

    (Num_Add (p, _), Num_Add (st, _)) =>
      match_symbolic_term_insert val_store (p, st) |

    (Num_Sub (p, _), Num_Sub (st, _)) =>
      match_symbolic_term_insert val_store (p, st) |

    (Num_Mul (p, _), Num_Mul (st, _)) =>
      match_symbolic_term_insert val_store (p, st) |

    (Num_Div (p, _), Num_Div (st, _)) =>
      match_symbolic_term_insert val_store (p, st) |

    (Chan_Loc (p_i), Chan_Loc (st_i)) =>
    (if p_i = st_i then
      SOME val_store
    else
      NONE
    ) |

    (ThreadId (p_i), ThreadId (st_i)) =>
    (if p_i = st_i then
      SOME val_store
    else
      NONE
    ) |

    (Error p_str, Error st_str) =>
    (if p_str = st_str then
      SOME val_store
    else
      NONE
    ) |

    _ => (
      NONE
    )


  )

  and from_lams_match_symbolic_term_insert val_store (p_lams, st_lams) = 
  (if (List.length p_lams = List.length st_lams) then
    (List.foldl
      (fn (((p1, p2), (st1, st2)), val_store_op) =>
        (Option.mapPartial
          (fn val_store' =>
            (Option.mapPartial
              (fn val_store' =>
                match_symbolic_term_insert val_store' (p2, st2)
              )
              (match_symbolic_term_insert val_store (p1, st1))
            )
          )
          val_store_op
        )
      )
      (SOME val_store)
      (ListPair.zip (p_lams, st_lams))
    )
  else
    NONE
  )

  and from_fields_match_symbolic_term_insert val_store (p_fields, st_fields) =
  (if (List.length p_fields = List.length st_fields) then
    (List.foldl
      (fn (((p_key, (p_fop, p)), (st_key, (st_fop, st))), val_store_op) =>
        (if p_key = st_key andalso p_fop = st_fop then
          (Option.mapPartial
            (fn val_store' =>
              match_symbolic_term_insert val_store (p, st)
            )
            val_store_op
          )
        else 
          NONE
        )
      )
      (SOME val_store)
      (ListPair.zip (p_fields, st_fields))
    )
  else
    NONE
  )




  fun match_value_insert (val_store, pat, value) = (case (pat, value) of

    (Assoc (pat', _), _) =>
      match_value_insert (val_store, pat', value) |

    (Blank _, _) =>
      SOME val_store |

    (Id (str, _), v) =>
      SOME (insert (val_store, str, (NONE, v))) |

    (List_Intro (t, t', _), List_Val (v :: vs, _)) =>
      (Option.mapPartial
        (fn val_store' =>
          match_value_insert (val_store', t, v)
        )
        (match_value_insert (val_store, t', List_Val (vs, ~1)))
      ) |

    (Rec_Intro (p_fields, _), Rec_Val (v_fields, _)) => (
      from_fields_match_value_insert val_store (p_fields, v_fields)
    ) |

    (Func_Intro ([(Blank _, p_body)], _), Func_Val ([(Blank _, st_body)], _, _, _)) => (
      (* function value's local stores are ignored; only syntax is matched; *)
      (* it's up to the user to determine if syntax can actually be evaluated in alternate context *)
      (* variables in pattern are specified by pattern_var syntax (sym f); *)
      (* it may then be used in new context and evaluated with f () *) 
      match_symbolic_term_insert val_store (p_body, st_body)
    ) |


    (Num_Val (n, _), Num_Val (nv, _)) => (
      if n = nv then
        SOME val_store
      else
        NONE
    ) |

    _ => NONE

    (* **TODO**

    (List_Val ([], _), List_Val ([], _)) => SOME val_store | 

    (List_Val (t :: ts, _), List_Val (v :: vs, _))  =>
      (Option.mapPartial
        (fn val_store' =>
          match_value_insert (val_store', t, v)
        )
        (match_value_insert (val_store, List_Val (ts, ~1), List_Val (vs, ~1)))
      ) |


    (Event_Send_Intro (t, _), Event_Send_Intro (v, _)) =>
      match_value_insert (val_store, t, v) |

    (Event_Recv_Intro (t, _), Event_Recv_Intro (v, _)) =>
      match_value_insert (val_store, t, v) |

    (Func_Val p_fnc, Func_Val v_fnc) => (
      if fnc_equal (p_fnc, v_fnc) then
        SOME val_store
      else
        NONE
    ) |

    (String_Val (str, _), String_Val (strv, _)) => (
      if str = strv then
        SOME val_store
      else
        NONE
    ) |

    (Rec_Intro (p_fields, _), Rec_Intro (v_fields, _)) => (case (p_fields, v_fields) of
      ([], []) =>
        SOME val_store |

      ((pk, t) :: ps, _ :: _) => (let
        val (match, remainder) = (List.partition  
          (fn (k, v) => k = pk)
          v_fields
        )
      in
        (case match of
          [(k, v)] => (Option.mapPartial
            (fn val_store' => match_value_insert (val_store', t, v))
            (match_value_insert (val_store, Rec_Intro (ps, ~1), Rec_Intro (remainder, ~1)))
          ) |

          _ => NONE
        )
      end) |

      _ =>
        NONE
      
    ) |

    *)
  )

  and from_fields_match_value_insert val_store (p_fields, v_fields) = (case p_fields of
    [] => SOME val_store |
    (pname, (pfix_op, p)) :: pfs => (let
      val (key_matches, vfs) = (List.partition
        (fn (vname, (vfix_op, _)) =>
          pname = vname andalso
          (pfix_op = vfix_op orelse pfix_op = NONE)
        )
        v_fields
      )
      fun match_term key_matches = (case key_matches of
        [] => NONE |
        [(vname,(vfix_op, v))] => (Option.mapPartial
          (fn val_store' =>
            SOME (insert (val_store', vname, (vfix_op, v)))
          )
          (match_value_insert (val_store, p, v))
        ) |
        _ :: key_matches' => match_term key_matches'
      )
      val val_store_op = match_term key_matches
    in
      (Option.mapPartial
        (fn val_store' =>
          from_fields_match_value_insert val_store' (pfs, vfs)
        )
        val_store_op
      )
    end)
  )








  fun sym i = "_g_" ^ (Int.toString i)

  fun hole i = Id (sym i, ~1)

  fun push (
    (t_arg, cont),
    val_store, cont_stack, thread_id,
    chan_store, block_store, sync_store, cnt
  ) = (let
    val cont_stack' = cont :: cont_stack

  in
    (
      Mode_Suspend,
      [(t_arg, val_store, cont_stack', thread_id)],
      (chan_store, block_store, sync_store, cnt)
    )
  end)

  fun pop (
    result,
    cont_stack, thread_id,
    chan_store, block_store, sync_store, cnt
  ) = (let
    val (threads, md) = (case cont_stack of
      [] => (case result of
        (* TODO *)
        (*
        Effect_Val base_effect => (run_effect base_effect) |
        *)
        _ => (
          [], Mode_Stick "top-level code with non-effect"
        )
      ) |
      (cmode, lams, val_store', mutual_store) :: cont_stack' => (let

        val val_store'' = (case result of
          Rec_Val (fields, _) => (if cmode = Contin_With then
            insert_table (val_store', fields)
          else
            val_store'
          ) |
          _ => val_store'
        )

        (* embed mutual_store within self's functions *)
        val fnc_store = (map 
          (fn (k, (fix_op, lams)) =>
            (k, (fix_op, Func_Val (lams, val_store'', mutual_store, ~1)))
          )
          mutual_store
        )

        val val_store''' = insert_table (val_store'', fnc_store)

        fun match_first lams = (case lams of
          [] => NONE |
          (p, t) :: lams' =>
            (case (match_value_insert (val_store''', p, result)) of
              NONE => match_first lams' |
              SOME val_store'''' => (
                SOME (t, val_store'''')
              )
            )
        )

      in
        (case (match_first lams) of

          NONE => (
            [], Mode_Stick ("result - " ^ (to_string result) ^ " - does not match continuation hole pattern")
          ) |

          SOME (t_body, val_store'''') => (
            [(t_body, val_store'''', cont_stack', thread_id)],
            Mode_Continue  
          )

        )
      end)
    )
  in
    (
      md,
      threads,
      (chan_store, block_store, sync_store, cnt)
    ) 
  end)




  fun apply (
    t_fn, t_arg, pos,
    val_store, cont_stack, thread_id,
    chan_store, block_store, sync_store, cnt
  ) = (case t_fn of
    (Id (id, _)) =>
      (case (find (val_store, id)) of
        SOME (_, v_fn) => (
          Mode_Suspend,
          [(App (v_fn, t_arg, pos), val_store, cont_stack, thread_id)],
          (chan_store, block_store, sync_store, cnt)
        ) |
        _  => (
          Mode_Stick ("apply arg variable " ^ id ^ " cannot be resolved"),
          [], (chan_store, block_store, sync_store, cnt)
        )
      ) |

    Func_Val (lams, fnc_store, mutual_store, _) =>
      push (
        (t_arg, (Contin_App, lams, fnc_store, mutual_store)),
        val_store, cont_stack, thread_id,
        chan_store, block_store, sync_store, cnt
      ) |

    v =>
      (if is_value t_fn then
        (
          Mode_Stick ("application of non-function: " ^ (to_string v)),
          [], (chan_store, block_store, sync_store, cnt)
        )
      else
        push (
          (t_fn, (Contin_Norm, [( hole cnt, App (hole cnt, t_arg, pos) )], val_store, [])),
          val_store, cont_stack, thread_id,
          chan_store, block_store, sync_store, cnt + 1
        )
      )
  )


  fun associate_infix val_store t = (case t of
    Compo (Compo (t1, Id (id, pos), p1), t2, p2) => (let
      val t1' = associate_infix val_store t1
    in
      (case (find (val_store, id)) of
        SOME (SOME (direc, prec), rator) => (case t1' of 
          Compo (Compo (t1a, Id (id1, pos1), p1a), t1b, p1b) =>
          (case (find (val_store, id1)) of
            SOME (SOME (direc', prec'), rator') =>
            (if (prec' = prec andalso direc = Right) orelse (prec > prec') then
              Compo (
                Compo (t1a, Id (id1, pos1), p1a),
                associate_infix val_store (Compo (Compo (t1b, Id (id, pos), p1b), t2, p2)),
                p1
              )
            else 
              Compo (Compo (t1', Id (id, pos), p1), t2, p2)
            ) |

            _ => (let
              val t1'' = Compo (App (t1a, Id (id1, pos1), p1a), t1b, p1b)
            in
              Compo (Compo (t1'', Id (id, pos), p1), t2, p2)
            end)
          ) |

          _ => Compo (Compo (t1', Id (id, pos), p1), t2, p2)
        ) |

        _ => (
          Compo (App (t1', Id (id, pos), p1), t2, p2)
        )
      )
    end) |

    _ => t
  )

  fun to_func_elim val_store t = (case t of
    Compo (Compo (t1, Id (id, pos), p1), t2, p2) => (
      (case (find (val_store, id)) of
        SOME (SOME (direc, prec), rator) => (
          App (
            Id (id, pos),
            List_Intro (
              to_func_elim val_store t1,
              List_Intro (to_func_elim val_store t2, Blank 0, pos),
              pos
            ),
            pos
          )
        ) |

        _ => (
          App (
            App (to_func_elim val_store t1, Id (id, pos), p1),
            to_func_elim val_store t2,
            p2
          )
        )
      )
    ) |
    _ => t
  )




  fun reduce_single (
    t, norm_f, reduce_f,
    val_store, cont_stack, thread_id,
    chan_store, block_store, sync_store, cnt
  ) = (case t of
    (Id (id, _)) =>
      (case (find (val_store, id)) of
        SOME (NONE, v) => (
          Mode_Suspend,
          [(reduce_f v, val_store, cont_stack, thread_id)],
          (chan_store, block_store, sync_store, cnt)
        ) |

        _  =>
          (
            Mode_Stick ("reduce single variable " ^ id ^ " cannot be resolved")
            ,
            [], (chan_store, block_store, sync_store, cnt)
          )

      ) |

    _ =>
      (if is_value t then
        (case (reduce_f t) of
          Error msg => (
            Mode_Stick msg,
            [], (chan_store, block_store, sync_store, cnt)
          ) |

          result => (
            Mode_Reduce result,
            [(result, val_store, cont_stack, thread_id)],
            (chan_store, block_store, sync_store, cnt)
          )
        )
      else
        push (
          (t, (Contin_Norm, [( hole cnt, norm_f (hole cnt) )], val_store, [])),
          val_store, cont_stack, thread_id,
          chan_store, block_store, sync_store, cnt + 1
        )
      )
  )


  fun reduce_list (
    ts, norm_f, reduce_f,
    val_store, cont_stack, thread_id,
    chan_store, block_store, sync_store, cnt
  ) = (let

    fun loop (prefix, postfix) = (case postfix of
      [] => (case (reduce_f prefix) of 
        Error msg => (
          Mode_Stick msg,
          [], (chan_store, block_store, sync_store, cnt)
        ) |

        result => (
          Mode_Reduce result,
          [(result, val_store, cont_stack, thread_id)],
          (chan_store, block_store, sync_store, cnt)
        )

      ) |

      x :: xs => (case x of
        (Id (id, _)) =>
          (case (find (val_store, id)) of
            SOME (NONE, v) => loop (prefix @ [v], xs) |
            _ => (
              Mode_Stick ("reduce list variable " ^ id ^ " cannot be resolved"),
              [], (chan_store, block_store, sync_store, cnt)
            )
          ) |

        _ =>
          (if is_value x then 
            loop (prefix @ [x], xs)
          else
            (push (
              (
                x,
                (
                  Contin_Norm,
                  [( hole cnt, norm_f (prefix @ (hole cnt :: xs)) )],
                  val_store,
                  []
                )
              ),
              val_store, cont_stack, thread_id,
              chan_store, block_store, sync_store, cnt + 1
            )
            )
          )

      )
    )

  in
    loop ([], ts)
  end)


  fun mk_transactions (evt, t) = (case (evt, t) of
  
    (Send, List_Val ([Chan_Loc i, msg], _)) =>
      [Tx (Base_Send (i, msg), [])] |
  
    (Recv, Chan_Loc i) =>
      [Tx (Base_Recv i, [])] |

    (Choose, List_Val (values, _)) =>
      mk_transactions_from_list values |

    _ => []

    (* TODO: modify to handle choose and other event results *)
    (*
    (Latch, List_Val ([Event_Val transactions, Func_Val (lams, fnc_store, mutual_store, _)], _)) =>
      (List.foldl
        (fn ((bevt, wrap_stack), transactions_acc) => let
          val cont = (Contin_Sync, lams, fnc_store, mutual_store)
        in
          transactions_acc @ [(bevt, cont :: wrap_stack)]
        end)
        []
        transactions 
      ) |
    *)

  
  )

  and mk_transactions_from_list (evts) = (case evts of
    [] => [] |
    (Event_Val base_events) :: evts' => 
      base_events @ (mk_transactions_from_list evts') |
    _ => raise (Fail "Internal: mk_transactions_from_list")
  )

  

  fun seq_step (
    md,
    (t, val_store, cont_stack, thread_id),
    (chan_store, block_store, sync_store, cnt)
  ) = (
    (* print ("stack size: " ^ (Int.toString (List.length cont_stack)) ^ "\n"); *)
    (*print ("\n(*** thread " ^ (Int.toString thread_id) ^ " ***)\n" ^ (to_string t) ^ "\n\n");*)
    case t of


    Assoc (term, pos) => (
      Mode_Reduce term,
      [(term, val_store, cont_stack, thread_id)],
      (chan_store, block_store, sync_store, cnt)
    ) |


    Log (t, pos) => reduce_single (
      t,
      fn t => Log (t, pos),
      fn v => (
        print ((to_string v) ^ "\n");
        v
      ),
      val_store, cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt
    ) | 



    Id (id, pos) => (case (find (val_store, id)) of
      SOME (NONE, v) => (
        Mode_Suspend,
        [(v, val_store, cont_stack, thread_id)],
        (chan_store, block_store, sync_store, cnt)
      ) |

      _ => (
        Mode_Stick ("variable " ^ id ^ " cannot be resolved"),
        [], (chan_store, block_store, sync_store, cnt)
      )
    ) |


    List_Intro (t, t', pos) => reduce_list (
      [t, t'],
      (fn
        [t, t'] => List_Intro (t, t', pos) |
        _ => raise (Fail "Internal: List_Intro")
      ),
      (fn
        [v, Blank _] => List_Val ([v], pos) |
        [v, List_Val (ts, _)] => List_Val (v :: ts, pos) |
        _ => Error "cons with non-list"
      ),
      val_store, cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt

    ) |

    List_Val (ts, pos) => pop (
      List_Val (ts, pos),
      cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt
    ) |


    Func_Intro (lams, pos) => pop (
      Func_Val (lams, val_store, [], pos),
      cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt
    ) |

    Func_Val (lams, [], mutual_store, pos) => pop (
      Func_Val (lams, val_store, mutual_store, pos),
      cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt
    ) |

    Func_Val (lams, fnc_store, mutual_store, pos) => pop (
      Func_Val (lams, fnc_store, mutual_store, pos),
      cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt
    ) |


    Compo (Compo (t1, Id (id, pos), p1), t2, p2) => (let
      val t_m = associate_infix val_store t
      val t' = to_func_elim val_store t_m 
    in
      (
        Mode_Reduce t',
        [(t', val_store, cont_stack, thread_id)],
        (chan_store, block_store, sync_store, cnt)
      )
    end) |

    Compo (t1, t2, pos) => (
      Mode_Reduce (App (t1, t2, pos)),
      [(App (t1, t2, pos), val_store, cont_stack, thread_id)],
      (chan_store, block_store, sync_store, cnt)
    ) |


    App (t_fn, t_arg, pos) => apply (
      t_fn, t_arg, pos,
      val_store, cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt
    ) |


    With (t1, t2, _) => push (
      (t1, (Contin_With, [(hole cnt, t2)], val_store, [])),
      val_store, cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt + 1
    ) |

    Rec_Intro (fields, pos) => (let
      val mutual_store = (List.mapPartial
        (fn
          (k, (fix_op,  Func_Intro (lams, _))) => 
            SOME (k, (fix_op, lams)) |
          _ => NONE
        )
        fields
      )
      
      (* embed mutual ids into ts' functions *)
      val fields' = (map
        (fn
          (k, (fix_op, Func_Intro (lams, pos))) =>
            (k, (fix_op, Func_Val (lams, val_store, mutual_store, pos))) |
          field => field 
        )
       fields 
      )
    in
      (
        Mode_Suspend,
        [(Rec_Intro_Mutual (fields', pos), val_store, cont_stack, thread_id)],
        (chan_store, block_store, sync_store, cnt)
      )
    end) |
    
    Rec_Intro_Mutual (fields, pos) => (let
      val ts = (map (fn (k, (fix_op, t)) => t) fields)

      fun f con ts = (let
        val fields' = (List.map
          (fn ((key, (fix_op, _)), t) => (key, (fix_op, t)))
          (ListPair.zip (fields, ts))
        )
      in
        con (fields',  pos)
      end)


    in
      reduce_list (
        ts, f Rec_Intro_Mutual, f Rec_Val, 
        val_store, cont_stack, thread_id,
        chan_store, block_store, sync_store, cnt
      )
    end) |

    Rec_Val (fields, pos) => pop (
      Rec_Val (fields, pos),
      cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt
    ) |

    Select (t, pos) => reduce_single (
      t,
      fn t => Select (t, pos),
      (fn
        List_Val ([Rec_Val (fields, _), Id (key, _)], _) =>
        (case find (fields, key) of
          SOME (_, v) => v |
          NONE => Error "selection not found"
        ) |

        _ => Error "selecting from non-record"
      ),
      val_store, cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt

    ) |


    (* internal rep *)
    Chan_Loc i => pop (
      Chan_Loc i,
      cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt
    ) |


    Event_Intro (evt, t, pos) => reduce_single (
      t, fn t => Event_Intro (evt, t, pos), fn v => Event_Val (mk_transactions (evt, t)),
      val_store, cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt
    ) | 

    _ => (
      Mode_Stick "TODO",
      [], (chan_store, block_store, sync_store, cnt)
    )
    (* **TODO**

    Event_Val transactions => pop (
      Event_Val transactions,
      cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt
    ) |

    Sync (t, pos) => (case t of

(*
** TODO: allocate chan during sync **
**    Alloc_Chan (_, i) => (let
**      val chan_store' = insert (chan_store, cnt, ([], []))
**      val cnt' = cnt + 1
**    in
**      pop (
**        Chan_Loc cnt,
**        cont_stack, thread_id,
**        chan_store', block_store, sync_store, cnt'
**      )
**    end) |
**
*)
      (Id (id, _)) => (case (find (val_store, id)) of
        SOME (NONE, v) => (
          Mode_Suspend,
          [(Sync (v, pos), val_store, cont_stack, thread_id)],
          (chan_store, block_store, sync_store, cnt)
        ) |

        _  => (
          Mode_Stick ("Sync argument variable " ^ id ^ " cannot be resolved"),
          [], (chan_store, block_store, sync_store, cnt)
        )

      ) |

      Event_Val v =>
        (let

          val transactions = mk_transactions (v, []) 
          
          val (active_transaction_op, chan_store') = (
            find_active_transaction (transactions, chan_store, block_store)
          )

        in
          (case active_transaction_op of
            SOME transaction =>
              proceed (
                transaction, cont_stack, thread_id,
                (chan_store', block_store, sync_store, cnt)
              ) |
            NONE =>
              block (
                transactions, cont_stack, thread_id,
                (chan_store', block_store, sync_store, cnt)
              )
          )
        end)
      v => if (is_value v) then
        (
          Mode_Stick "sync with non-event",
          [], (chan_store, block_store, sync_store, cnt)
        )
      else 
        push (
          (t, (Contin_Norm, [( hole cnt, Sync (hole cnt, pos) )], val_store, [])),
          val_store, cont_stack, thread_id,
          chan_store, block_store, sync_store, cnt + 1
        )
      )
    ) |

    (* internal rep *)
    ThreadId i => pop (
      ThreadId i,
      cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt
    ) |


    Spawn (t, pos) =>(case t of
      (Id (id, _)) => (case (find (val_store, id)) of
        SOME (_, v) => (
          Mode_Suspend,
          [(Spawn (v, pos), val_store, cont_stack, thread_id)],
          (chan_store, block_store, sync_store, cnt)
        ) |

        _  => (
          Mode_Stick ("Spawn argument variable " ^ id ^ " cannot be resolved"),
          [], (chan_store, block_store, sync_store, cnt)
        )


      ) |

      Func_Val ([(Blank _, t_body)], fnc_store, mutual_store, _) => (let
        val spawn_id = cnt
        val cnt' = cnt + 1
      in
        (
          Mode_Spawn t_body,
          [
            (List_Val ([], pos), val_store, cont_stack, thread_id),
            (t_body, val_store, [], spawn_id)
          ],
          (chan_store, block_store, sync_store, cnt')
        )
      end) |
      
      v => (if is_value v then
        (
          Mode_Stick "spawn with non-function",
          [], (chan_store, block_store, sync_store, cnt)
        )
      else
        push (
          (t, (Contin_Norm, [( hole cnt, Spawn (hole cnt, pos) )], val_store, [])),
          val_store, cont_stack, thread_id,
          chan_store, block_store, sync_store, cnt + 1
        )
      )
    ) |

    Blank pos => pop (
      Blank pos,
      cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt
    ) |

    String_Val (str, pos) => pop (
      String_Val (str, pos),
      cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt
    ) |

    Num_Val (str, pos) => pop (
      Num_Val (str, pos),
      cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt
    ) |

    Num_Add (t, pos) => reduce_single (
      t, fn t => Num_Add (t, pos),
      (fn
        List_Val ([Num_Val (n1, _), Num_Val (n2, _)], _) =>
          Num_Val (num_add (n1, n2), pos) |
        _ => Error "adding non-numbers"
      ),
      val_store, cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt

    ) |

    Num_Sub (t, pos) => reduce_single (
      t, fn t => Num_Sub (t, pos),
      (fn
        List_Val ([Num_Val (n1, _), Num_Val (n2, _)], _) => (
          Num_Val (num_sub (n1, n2), pos)
        ) |
        _ => Error "subtracting non-numbers"
      ),
      val_store, cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt

    ) |

    Num_Mul (t, pos) => reduce_single (
      t, fn t => Num_Mul (t, pos),
      (fn
        List_Val ([Num_Val (n1, _), Num_Val (n2, _)], _) => (
          Num_Val (num_mul (n1, n2), pos)
        ) |
        _ => Error "multplying non-numbers"
      ),
      val_store, cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt

    ) |

    Num_Div (t, pos) => reduce_single (
      t, fn t => Num_Div (t, pos),
      (fn
        List_Val ([Num_Val (n1, _), Num_Val (n2, _)], _) => (
          Num_Val (num_div (n1, n2), pos)
        ) |
        _ => Error "dividing non-numbers"
      ),
      val_store, cont_stack, thread_id,
      chan_store, block_store, sync_store, cnt

    ) |
  

    Par of (term * int) |
  
    *)

  )


  fun from_mode_to_string md = "----" ^ (case md of
    Mode_Start => "Start" |
    Mode_Suspend => "Push/Suspend" |
    Mode_Reduce t => "Reduce" |
    Mode_Continue => "Pop/Continue" |
    Mode_Spawn t => "Spawn" |
    Mode_Block transactions => "Block" |
    Mode_Sync (thread_id, msg, send_id, recv_id) => "Sync" |
    Mode_Stick msg => "Stick: " ^ msg  |
    Mode_Finish t => "Finish: " ^ (to_string t)
  ) ^ "----"



  fun concur_step (
    md, threads, env 
  
  ) = (case threads of
    [] => ( (*print "all done!\n";*) NONE) |
    thread :: threads' => (let
      val (md', seq_threads, env') = (seq_step (md, thread, env)) 

      (*
      val _ = print ((from_mode_to_string md') ^ "\n")
      *)
      (*
      val _ = print (
        "# seq_threads: " ^
        (Int.toString (length seq_threads)) ^
        "\n"
      )
      *)
    in
      SOME (md', threads' @ seq_threads, env')
    end)
  )


  fun eval t = (let

    val val_store = empty_table 
    val cont_stack = []
    val thread_id = 0
    val thread = (t, val_store, cont_stack, thread_id)

    val chan_store = empty_table
    val block_store = empty_table
    val sync_store = empty_table (* of ((thread_id, query_id) -> event_list) *)
    val cnt = 1


    fun loop cfg = (case (concur_step cfg) of
      NONE => () |
      SOME (cfg') =>
        loop cfg' 
    )
  
  in
    loop (
      Mode_Start,
      [thread],
      (chan_store, block_store, sync_store, cnt)
    )
  end)

end
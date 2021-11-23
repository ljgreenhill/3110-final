open Analyzer

type command =
  | Frequencies
  | Stemmer
  | Encoder
  | NA

let rec sub subreddit_name =
  try
    Yojson.Basic.from_file ("data/" ^ subreddit_name ^ ".json")
    |> Intake.from_json
  with
  | Sys_error _ ->
      print_endline "Invalid subreddit name. Try again.";
      print_string "> ";
      sub (read_line ())

let rec get_command () =
  print_endline "Enter one of the following commands:";
  print_endline "Frequencies";
  print_endline "Stemmer";
  print_endline "Encoder";
  print_string "> ";
  match read_line () with
  | exception End_of_file -> NA
  | command when command |> String.lowercase_ascii = "frequencies" ->
      Frequencies
  | command when command |> String.lowercase_ascii = "stemmer" ->
      Stemmer
  | command when command |> String.lowercase_ascii = "encoder" ->
      Encoder
  | _ ->
      print_endline "Did not recognize command. Please try again.\n";
      get_command ()

let big_string = "---"

let rec extract_top5 lst count =
  if count >= 5 then ()
  else
    match lst with
    | [] -> print_newline ()
    | (k, v) :: t ->
        print_string (k ^ ": ");
        for i = 1 to v do
          print_string big_string
        done;
        print_newline ();
        extract_top5 t (count + 1)

(* let rec string_of_array arr pos = if pos < Array.length arr then
   string_of_int arr.(pos) ^ " " ^ string_of_array arr (pos + 1) else ""

   let rec string_matrix (mat : int array array) : string = match mat
   with | [||] -> "" | [| one |] -> string_of_array one 0 | _ ->
   string_of_array mat.(0) 0 ^ "\n" ^ string_matrix (Array.sub mat 1
   (Array.length mat - 1)) *)
let print_frequencies subreddit_name =
  let json =
    Yojson.Basic.from_file
      ("data/subredditVocabJsons/" ^ subreddit_name ^ ".json")
  in
  let encoded_matrix =
    WordEncoding.encode_subreddit
      ("data/subredditVocabJsons/" ^ subreddit_name ^ ".json"
      |> Yojson.Basic.from_file)
      WordProcessor.stem_text
      (Yojson.Basic.from_file ("data/" ^ subreddit_name ^ ".json"))
  in
  let frequency_list =
    WordEncoding.find_frequencies json (Array.of_list encoded_matrix)
  in
  print_endline ("Finding the most frequent words r/" ^ subreddit_name);
  extract_top5 frequency_list 0

let print_stemmer post =
  let original_text = post |> Intake.selftext in
  let text_block = original_text |> WordProcessor.make_text_block in
  let stemmed_text = text_block |> WordProcessor.stemmed_text_block in
  print_endline
    ("Stemming the text of most recent post from r/"
    ^ (post |> Intake.subreddit_name)
    ^ "\n");
  print_endline ("Original text: " ^ original_text ^ "\n");
  print_endline ("Stemmed text: " ^ stemmed_text)

let print_encoder subreddit_name =
  let encoded_matrix =
    WordEncoding.encode_subreddit
      ("data/subredditVocabJsons/" ^ subreddit_name ^ ".json"
      |> Yojson.Basic.from_file)
      WordProcessor.stem_text
      ("data/" ^ subreddit_name ^ ".json" |> Yojson.Basic.from_file)
  in
  print_endline
    ("Encoding r/" ^ subreddit_name
   ^ " based on all seen vocabulary in the subreddit\n");
  encoded_matrix |> Array.of_list
  |> Array.iter (fun x ->
         Array.iter print_int x;
         print_newline ();
         print_newline ());
  print_newline ()

let run subreddit_name =
  let subreddit = sub subreddit_name in
  match get_command () with
  | Frequencies ->
      print_frequencies
        (subreddit |> Intake.recent_post |> Intake.subreddit_name
       |> String.lowercase_ascii)
  | Stemmer -> print_stemmer (subreddit |> Intake.recent_post)
  | Encoder ->
      print_encoder
        (subreddit |> Intake.recent_post |> Intake.subreddit_name
       |> String.lowercase_ascii)
  | NA -> exit 0

let terminal () =
  ANSITerminal.print_string [ ANSITerminal.green ]
    "\nWelcome to our NLP project.\n";
  print_endline "Enter the name of desired subreddit (excluding r/)";
  print_string "> ";
  match read_line () with
  | exception End_of_file -> ()
  | subreddit_name -> run (subreddit_name |> String.lowercase_ascii)

let () = terminal ()
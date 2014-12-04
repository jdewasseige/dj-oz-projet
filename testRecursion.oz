declare
fun {Test I}
   case I
   of 0 then nil
   else
      1|{Test I-1}
   end
end
{Browse {Test 5}}

fun {Test2 I Acc}
   case I of 0 then {Reverse Acc}
   else
      {Test2 I-1 1|Acc}
   end
end
{Browse {Test2 5 nil}}
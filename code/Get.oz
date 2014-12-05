% useless mais joli
fun {Get L I}
   case L
   of nil then none
   [] H|T then
      if I == 1 then
	 H
      else
	 {Get T I-1}
      end
   end
end
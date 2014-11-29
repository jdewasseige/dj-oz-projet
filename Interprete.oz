declare
fun {Interprete Partition}
   case Partition
      of nil then nil
      [] NestedPart|Rest then
	 {Interprete NestedPart}|{Interprete Rest}
      [] muet( Part ) then
	 {Muet {Interprete Part}}
      [] duree( secondes:N Part ) then
	 nil
      [] etirer( facteur:N Part ) then
	 {Etirer N {Interprete Part}}
      [] bourdon( note:Note Part ) then
      case Note
      of silence then
	 {Muet {Interprete Part}}
      else
	 {Bourdon {GivesH Note} {Interprete Part}}
      end
      [] transpose( demitons:N Part ) then
      nil
   else % Partition est une note
      {Flatten echantillon(hauteur:{GivesH Partition}
			   duree:1 instrument:none)}
   end 
end


fun {ToNote Note}
   case Note
   of Nom#Octave then note(nom:Nom octave:Octave alteration:'#')
   [] Atom then
      case {AtomToString Atom}
      of [N] then note(nom:Atom octave:4 alteration:none)
      [] [N O] then
	 note(nom:{StringToAtom [N]}
	      octave:{StringToInt [O]}
	      alteration:none)
      end
   end
end

fun {GivesH Note}
   local Noteext H1 H2 H3 in
      Noteext = {ToNote Partition}
      case Noteext.nom
	    of a then H1 = 0
	    [] b then H1 = 2
	    [] c then H1 = 3
	    [] d then H1 = 5
	    [] e then H1 = 7
	    [] f then H1 = 8
	    [] g then H1 = 10
	    end
	    H2 = (Noteext.octave - 4)*12
	    if Noteext.alteration == none then
	       H3 = 0
	    else
	       H3 = 1
	    end
	    H1+H2+H3
   end
end




fun {Muet Voix}
   case Voix
   of nil then nil
   [] Echantillon|Rest then
      silence(duree:Echantillon.duree)|{Muet Rest}
   end
end

fun {Etirer N Voix}
   case Voix
   of nil then nil
   [] Echantillon|Rest then
      case Echantillon
      of silence(duree:D) then
	 silence(duree:D*N)|{Etirer N Rest}
      [] echantillon(hauteur:H duree:D instrument:I) then
	 echantillon(hauteur:H duree:D*N instrument:I)|{Etirer N Rest}
      end
   end
end

fun {Bourdon Hb Voix}
   case Voix
   of nil then nil
   [] Echantillon|Rest then
      case Echantillon
      of silence(duree:D) then
	 echantillon(hauteur:Hb duree:D instrument:none)|{Bourdon Hb Rest}
      [] echantillon(hauteur:H duree:D instrument:I) then
	 echantillon(hauteur:Hb duree:D instrument:I)|{Bourdon Hb Rest}
      end
   end
end


declare
Partition = [a4 a6 a#4 b3]
{Browse {Interprete Partition}}
% TO DO : gerer float
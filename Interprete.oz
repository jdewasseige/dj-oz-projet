declare
fun {Interprete Partition}
   case Partition
   of nil then nil
   [] NestedPart|Rest then
      {Flatten {Interprete NestedPart}|{Interprete Rest}}
   [] muet( Part ) then
      {Muet {Interprete Part}}
   [] duree( secondes:N Part ) then
      % Le rapport de duree des echantillons entre eux est conserve
      local Nr DTot Voix in
	 if {IsInt N} then % Pour la robustesse
	    Nr = {IntToFloat N}
	 else
	    Nr = N
	 end
	 Voix =  {Interprete Part}
	 DTot = {GivesDureeTot Voix 0.0}
	 {Etirer Nr/DTot Voix}
      end
   [] etirer( facteur:N Part ) then
      if {IsInt N} then % Pour la robustesse
	 {Etirer {IntToFloat N} {Interprete Part}}
      else
	 {Etirer N {Interprete Part}}
      end
   [] bourdon( note:Note Part ) then
      case Note
      of silence then
	 {Muet {Interprete Part}}
      else
	 {Bourdon {GivesH Note} {Interprete Part}}
      end
   [] transpose( demitons:N Part ) then
      if {IsFloat N} then % Pour la robustesse
	 {Transpose {FloatToInt N} {Interprete Part}}
      else
	 {Transpose N {Interprete Part}}
      end
   else % Partition est une note
      if Partition == silence then
	 silence(duree:1.0)
      else
	 echantillon(hauteur:{GivesH Partition}
		     duree:1.0 instrument:none)
      end
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
      Noteext = {ToNote Note}
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


fun {Transpose N Voix}
   case Voix
   of nil then nil
   [] Echantillon|Rest then
      case Echantillon
      of silence(duree:D) then
	 silence(duree:D)|{Transpose N Rest}
      [] echantillon(hauteur:H duree:D instrument:I) then
	 echantillon(hauteur:H+N duree:D instrument:I)|{Transpose N Rest}
      end
   end
end


fun {GivesDureeTot Voix Acc}
   case Voix
   of nil then Acc
   [] Echantillon|Rest then
      {GivesDureeTot Rest Acc+Echantillon.duree}
   end
end



%%%%%%%%%% TESTS %%%%%%%%%%%%
declare
Partition = duree( secondes:5 [[a4 etirer(facteur:4 [a6])] a#4 [[[b3]]]] )
% etirer( facteur:5.1 muet( [[a4 [a6]] a#4 [[[b3]]]] ) )
{Browse {Interprete Partition}}
% duree doit d'office etre un float : OK
% muet : OK
% etirer : OK
% bourdon : OK
% transpose : OK
% duree : OK

% TO DO : batterie de tests
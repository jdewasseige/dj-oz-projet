% DJ'Oz - LFSAB1402 - Projet 2014
% Antoine LEGAT    4776-1300
% John DE WASSEIGE 5224-1300

declare % /!\ ne pas oublier d’enlever ‘declare’
proc {Assert Cond Exception}
   if {Not Cond} then raise Exception end end
end

fun {Interprete Partition}
   case Partition
   of nil then nil
   [] NestedPart|Rest then
      {Flatten {Interprete NestedPart}|{Interprete Rest}}
   [] muet( Part ) then
      {Interprete bourdon(note:silence Part)}
   [] duree( secondes:N Part ) then
      % Le rapport de duree des echantillons entre eux est conserve
      local Nr DTot Voix in
	 if {IsInt N} then % Pour la robustesse
	    Nr = {IntToFloat N}
	 else
	    Nr = N
	 end
	 Voix =  {Interprete Part}
	 DTot = {GivesDureeTot Voix}
	 {Etirer Nr/DTot Voix}
      end
   [] etirer( facteur:N Part ) then
      {Etirer N {Interprete Part}}
   [] bourdon( note:Note Part ) then
      {Bourdon {GetHauteur Note} {Interprete Part}}
   [] transpose( demitons:N Part ) then
      {Transpose N {Interprete Part}}
   [] instrument( nom:Instru Part ) then
      {Instrument Instru {Interprete Part}}
   else % Partition est une note
      if Partition == silence then
	 [silence(duree:1.0)]
      else
	 [echantillon(hauteur:{GetHauteur Partition}
		      duree:1.0 instrument:none)]
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


fun {GetHauteur Note}
   if Note == silence then silence
   else
      local Noteext H1 H2 H3 in
	 Noteext = {ToNote Note}
	 case Noteext.nom
	 of a then H1 = 0
	 [] b then H1 = 2
	 [] c then H1 = ~9
	 [] d then H1 = ~7
	 [] e then H1 = ~5
	 [] f then H1 = ~4
	 [] g then H1 = ~2
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
end


fun {Etirer Nr Voix}
   local N in
      if {IsInt Nr} then N = {IntToFloat {Abs Nr}}
      else N = {Abs Nr} end
      case Voix
      of nil then nil
      [] Ech|Rest then
	 case Ech
	 of silence(duree:D) then
	    silence(duree:D*N)|{Etirer N Rest}	    
	 [] echantillon(hauteur:H duree:D instrument:I) then
	    echantillon(hauteur:H duree:D*N instrument:I)|{Etirer N Rest}
	 end
      end
   end
end


fun {Bourdon Hb Voix}
   case Voix
   of nil then nil
   [] Echantillon|Rest then
      if Hb == silence then silence(duree:Echantillon.duree)|{Bourdon Hb Rest}
      else
	 case Echantillon
	 of silence(duree:D) then
	    echantillon(hauteur:Hb duree:D instrument:none)|{Bourdon Hb Rest}
	 [] echantillon(hauteur:H duree:D instrument:I) then
	    echantillon(hauteur:Hb duree:D instrument:I)|{Bourdon Hb Rest}
	 end
      end
   end
end


fun {Transpose Nr Voix}
   local N in 
      if {IsFloat Nr} then N = {FloatToInt Nr}
      else N = Nr
      end
      case Voix
      of nil then nil
      [] Ech|Rest then
	 case Ech
	 of silence(duree:D) then
	    silence(duree:D)|{Transpose N Rest}
	 [] echantillon(hauteur:H duree:D instrument:I) then
	    echantillon(hauteur:H+N duree:D instrument:I)|{Transpose N Rest}
	 end
      end
   end
end


fun {Instrument Instru Voix}
   fun {InstrumentAcc Voix Acc}
      case Voix
      of nil then {Reverse Acc}
      [] Ech|Rest then
	 case Ech
	 of silence(duree:D) then
	    {InstrumentAcc Rest Ech|Acc}
	 [] echantillon(hauteur:H duree:D instrument:none) then
	    {InstrumentAcc Rest echantillon(hauteur:H duree:D instrument:Instru)|Acc}
	 [] echantillon(hauteur:H duree:D instrument:I) then
	    {InstrumentAcc Rest Ech|Acc}
	 end
      end
   end
in
   {InstrumentAcc Voix nil}
end

fun {GivesDureeTot Voix}
   local 
      fun {GivesDureeTotAcc Voix Acc}
	 case Voix
	 of nil then Acc
	 [] Ech|Rest then
	    {GivesDureeTotAcc Rest Acc+Ech.duree}
	 end
      end
   in
      {GivesDureeTotAcc Voix 0.0}
   end
end


%%%%%%%%%% TESTS %%%%%%%%%%%%

declare
Partition2 = duree( secondes:24 b2)
%{Browse {Interprete Partition2}}
Partition1 = duree( secondes:42 [a2 etirer(facteur:5 [[b [c5] a4] d
						      transpose(demitons:20 [d])]) bourdon(note:a [b [[[b]] b]]) silence a#4 ])
%{Browse {Interprete [Partition1 muet(Partition1)]}}
%{Browse {Interprete duree(secondes:0.0001 [a2] )}}
%{Browse {Interprete [a4 b2]}}
% Test hard(hard)core passé avec mention :D

% Lancer une erreur si l'octave est différente de 0, 1, 2, 3, 4 ? Pq s'arrêter à 4 ?
% Idem pour le nom de la note, p.ex. erreur si c'est w ? Ou bien on se prend pas la tête
% TO DO : batterie de tests
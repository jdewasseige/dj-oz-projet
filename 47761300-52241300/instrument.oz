
%fun {UseWav Ech}
%   case Ech
%   of echantillon(hauteur:H duree:D instrument:I) then
%      local Nom Note  
%	 Nom = {VirtualString.toAtom I}
%	 Note = {GetNote H}
	 % nil % pour que ça compile
 %     in
%	 {RepeteD D {Couper 1.0 D {Project.readFile {VirtualString.toAtom 'wave/instruments/'#Nom#'_'#Note#'.wav'}}}}
 %     end
  % else nil end
%end

fun {GetNote H}
   local Octave Lettre ToNote 
      if H >= 0 then
	 Octave = 4 + ( (H+9) div 12 )
	 Lettre = H - (Octave-4)*12
      else
	 Octave = 4 + ( (H-2) div 12 )
	 Lettre = H - (Octave-4)*12
      end
      fun {ToNote Lettre Octave}
	 case Lettre
	 of 9 then "a"#Octave
	 [] 10 then "a"#Octave#"#"
	 [] 11 then "b"#Octave
	 [] 0 then "c"#Octave
	 [] 1 then "c"#Octave#"#"
	 [] 2 then "d"#Octave
	 [] 3 then "d"#Octave#"#"
	 [] 4 then "e"#Octave
	 [] 5 then "f"#Octave
	 [] 6 then "f"#Octave#"#"
	 [] 7 then "g"#Octave
	 [] 8 then "g"#Octave#"#"
	 end
      end
   in
      {VirtualString.toAtom {ToNote Lettre+9 Octave}}
   end
end
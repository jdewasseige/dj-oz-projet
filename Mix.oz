declare
fun {Mix Interprete Music}
   case Music
   of nil then nil
   [] Morceau|Rest then % Pas oublier Rest !!!
      case Morceau
      of voix( Voix ) then
	 {Flatten {MixVoix Voix}|{Mix Interprete Rest}}
      [] partition( Part ) then
	 {Flatten {Mix Interprete [voix({Interprete Part})]}|{Mix Interprete Rest}}
      [] wave( FileName ) then
	 nil
      [] merge( MusicInt ) then
	 % Fct récursive externe
	 nil
      else % Music est un filtre
	 nil
      end
   end
end


fun {MixVoix Voix}
   case Voix
   of nil then nil
   [] silence(duree:D)|Rest then
      {Silence {FloatToInt D*44100.0}}|{MixVoix Rest}
   [] echantillon( hauteur:H duree:D instrument:I )|Rest then
      local F K Pi in
	 Pi = 3.14159
	 F = {Pow 2.0 ({IntToFloat H}/12.0)} * 440.0
	 K = 2.0*Pi*F/44100.0
	 {MixEch K 1 {FloatToInt D*44100.0}}|{MixVoix Rest}
      end
   end
end


fun {Silence N}
   case N
   of 0 then nil
   else
      0|{Silence N-1}
   end
end


fun {MixEch K I Max}
   if I > Max then nil
   else
      0.5*{Sin K*{IntToFloat I}}|{MixEch K I+1 Max}
   end
end




% partition() : DONE
% voix() : DONE

%%%%%%%%% TESTS %%%%%%%%%%%%%%
\insert 'Interprete.oz'
declare
Music1 = [ voix( [ echantillon( hauteur:0 duree:0.0001 instrument:none) ] ) ]
Music2 = [ partition( duree(secondes:0.001 [silence b2] ) ) ]
Music3 = partition (Partition)
{Browse {Mix Interprete Music2}}
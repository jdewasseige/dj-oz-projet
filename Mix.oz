declare % /!\ ne pas oublier d’enlever ‘declare’
fun {Mix Interprete Music}
   case Music
   of nil then nil
   [] Morceau|Rest then % Pas oublier Rest !!!
      case Morceau
      of voix( Voix ) then
	 {Flatten {MixVoix Voix}|{Mix Interprete Rest}}
      [] partition( Part ) then
	 {Flatten {MixVoix {Interprete Part}}|{Mix Interprete Rest}}
      [] wave( FileName ) then
	 {Projet.readFile FileName}
      [] merge( MusicInt ) then
	 % Fct récursive externe
	 nil
      else % Music est un filtre
	 nil
      end
   end
end


fun {MixVoix Voix}
   local F K Pi N
      Pi = 3.14159
      case Voix
      of nil then nil
      [] silence(duree:D)|Rest then
	 N = {FloatToInt D*44100.0}
	 F = 0.0
      [] echantillon( hauteur:H duree:D instrument:I )|Rest then
	 N = {FloatToInt D*44100.0}
	 F = {Pow 2.0 {IntToFloat H}/12.0} * 440.0
      end % gerer le cas ou Voix ne contient ni un silence ni un echantillon ?
   in
      {Flatten {MixEch F 1 N}|{MixVoix Rest}}
   end
end


fun {MixEch F I Max}
   local K in
      K = 2.0*Pi*F/44100.0
      if I > Max then nil
      else
	 0.5*{Sin K*{IntToFloat I}}|{MixEch K I+1 Max}
      end
   end
end


% partition() : DONE
% voix() : DONE

%%%%%%%%% TESTS %%%%%%%%%%%%%%
\insert 'Interprete.oz'
declare
Music1 = [ voix( [ echantillon( hauteur:0 duree:0.0001 instrument:none) ] ) ]
Music2 = [ partition( duree(secondes:0.0001 [silence b2] ) ) ]
Music3 = partition (Partition)
{Browse {Mix Interprete Music2}}
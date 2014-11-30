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
	 %{Projet.readFile FileName}
      [] merge( MusicInt ) then
	 case {MergeHelper MusicInt nil 0.0}
	 of values(audiosMatrix:M sumF:S) then
	    {List.map {SumMatrix M nil} fun {$ N} N/S end}
	    % This line adds up the audios and divides them
	    % by S, the sum of the factors
	 end   
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
      0.0|{Silence N-1}
   end
end


fun {MixEch K I Max}
   if I > Max then nil
   else
      0.5*{Sin K*{IntToFloat I}}|{MixEch K I+1 Max}
   end
end


fun {MergeHelper MusicInt M S}
   % Petit mot d'explication sur M :
   % C'est un vecteur contenant les vecteurs audios calculés
   % jusqu'à présent. C'est un vecteur de vecteurs, on peut donc
   % le voir comme une matrice.
   case MusicInt
   of nil then values(audiosMatrix:M sumF:S)
   [] (F#Music)|Rest then % selon moi ça marche avec et sans les ()
                          % autour de F#Music, une préférence ?
      local Fr in
	 if {IsInt F} then % Pour la robustesse
	    Fr = {IntToFloat F}
	 else
	    Fr = F
	 end
	 { MergeHelper Rest
	   {Append M [{List.map {Mix Interprete Music} fun {$ N} Fr*N end}]}
	   S+Fr }
      % John si tu arrives à faire sans le Append c'est mieux mais
      % c'est un truc à se rendre fou
      %
      % cette ligne incompréhensible appelle MergeHelper avec Rest
      % comme MusicInt, en adjoignant à M le vecteur audio
      % correspondant à Music multiplié par F (c'est le rôle de
      % List.map) et en additionnant F à S.
      end
   end
end


fun {SumMatrix M Acc}
   % blabla description
   case M
   of nil then Acc
   [] Vec|Rest then
      {SumMatrix Rest {Sum Acc Vec}}
   end
end


fun {Sum L1 L2}
   % This function adds up the elements of the lists L1 and L2
   % one by one. If they don't have the same length, the one
   % with smaller length is extended with zeros.
   %
   % Moyen d'optimiser en plaçant judicieusement le vecteur le
   % + long en L1 ou L2 ?
   case L1
   of nil then
      case L2
      of nil then nil
      [] H2|T2 then
	 H2|{Sum nil T2}
      end
   [] H1|T1 then
      case L2
      of nil then
	 H1|{Sum T1 nil}
      [] H2|T2 then
	 H1+H2|{Sum T1 T2}
      end
   end
end

  





% partition() : DONE
% voix() : DONE
% merge() : DONE
%   Sum : DONE OK
%   SumMatrix : DONE OK
%   MergeHelper : DONE OK

%%%%%%%%% TESTS %%%%%%%%%%%%%%
\insert 'Interprete.oz'
declare
Music1 = [ voix( [ echantillon( hauteur:0 duree:0.0001 instrument:none) ] ) ]
Music2 = [ partition( duree(secondes:0.0002 [silence b2] ) ) ]
Music3 = partition (Partition1)
Music4 = partition (Partition2)
%{Browse {Mix Interprete Music1}}
MusicInt = [(2.0#Music1) (60.0#Music2)]
%{Browse {MergeHelper MusicInt nil 0.0}}
Music5 = [ merge( MusicInt ) ]
%{Browse {Mix Interprete Music5}}

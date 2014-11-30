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
	 nil
	 %{Projet.readFile FileName}
      [] merge( MusicInt ) then
	 case {MergeHelper MusicInt nil 0.0}
	 of values(audiosMatrix:M sumF:S) then
	    {List.map {SumMatrix M nil} fun {$ N} N/S end}
	    % This line adds up the audios and divides them
	    % by S, the sum of the factors
	 end  
      [] renverser( Music ) then
	 {Reverse {Interprete Music}} 
      [] repetition(nombre:N Music) then
	 {RepetitionN N {Mix Interprete Music}}
      [] repetition(duree:Secondes Music) then
	 {RepeteD Secondes {Mix Interprete Music}}
      [] clip(bas:Bas haut:Haut Music) then
	 {Clip Bas Haut {Mix Interprete Music}}
      else % Music est un filtre pas encore fait
	 nil
      end
   end
end

%%%%%%%%%%%%%%%
%%% FILTRES %%%
%%%%%%%%%%%%%%%
% reverse est deja implemente --'

fun {RepetitionN N Vec}
   local Nr in 
      if {IsFloat N} then Nr = {FloatToInt N}
      else Nr = N end
      local
	 fun {RepetitionNAcc N Vec Acc}
	    if N == 0 then Acc
	    else
	       {Repetiton N-1 Vec Vec|Acc}
	    end
	 end
      in
	 {Flatten {RepetitionNAcc N Vec Vec}} % on considere que si la musique est repetee 0 fois, alors on la joue une fois
      end
   end
end


fun {RepeteD Duree Vec}
   local DureeS L N R CompleteAcc in
      DureeS = {FloatToInt Duree*44100.0}
      L = {Length Vec}
      N = DureeS div L
      R = DureeS mod L
      fun {CompleteAcc Count Vec Acc}
	 if Count == 0 then {Reverse Acc}
	 else
	    case Vec
	    [] H|T then
	       {CompleteAcc Count-1 T H|Acc}
	    end
	 end
      end
      {Append {RepeteN N Vec} {CompleteAcc R Vec nil}}
   end
end


fun {Clip Bas Haut Vec} % erreur si H < B ??
   local
      fun {ClipAcc Bas Haut Vec Acc}
	 case Vec
	 of nil then {Reverse Acc}
	 [] H|T then
	    if H < Bas then {ClipAcc Bas Haut T Bas|Acc}
	    elseif H > Haut then {ClipAcc Bas Haut Haut|Acc}
	    else {ClipAcc Bas Haut H|Acc}
	    end
	 end
      end
   in
      {ClipAcc Bas Haut Vec nil}
   end
end



%%%%%%%%%%%
%%% MIX %%% 
%%%%%%%%%%%

fun {MixVoix Voix}
   local F N in
      case Voix
      of nil then nil
      [] silence(duree:D)|Rest then
	 N = {FloatToInt D*44100.0}
	 F = 0.0
	 {Flatten {MixEch F 1 N}|{MixVoix Rest}}
      [] echantillon( hauteur:H duree:D instrument:I )|Rest then
	 N = {FloatToInt D*44100.0}
	 F = {Pow 2.0 {IntToFloat H}/12.0} * 440.0
	 {Flatten {MixEch F 1 N}|{MixVoix Rest}}
      end
   end
end


fun {MixEch F I Max}
   local K Pi in
      Pi = 3.14159
      K = 2.0*Pi*F/44100.0
      if I > Max then nil
      else
	 0.5*{Sin K*{IntToFloat I}}|{MixEch F I+1 Max}
      end
   end
end

%%%%%%%%%%%%%
%%% MERGE %%%
%%%%%%%%%%%%%

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
   local Lbig Lshort SumAcc
      if {Length L1} > {Length L2} then
	 Lbig = L1
	 Lshort = L2
      else
	 Lbig = L2
	 Lshort = L1
      end
      fun {SumOpt Lshort Lbig}
	 case Lshort
	 of nil then
	    case Lbig
	    of nil then nil
	    [] Hb|Tb then
	       Hb|{SumOpt nil Tb}
	    end
	 [] Hs|Ts then
	    (Hs+Lbig.1)|{SumOpt Ts Lbig.2}
	 end
      end
   in
      {SumOpt Lshort Lbig}
   end
end

  





% partition() : DONE
% voix() : DONE
% merge() : DONE
%   Sum : DONE OK
%   SumMatrix : DONE OK
%   MergeHelper : DONE OK
% filtres
%   Reverse : DONE
%   RepeteN : DONE
%   RepeteD : DONE
%   Clip    : DONE

%%%%%%%%% TESTS %%%%%%%%%%%%%%
\insert 'Interprete.oz'
declare
Music1 = [ voix( [ echantillon( hauteur:0 duree:0.0001 instrument:none) ] ) ]
Music2 = [ partition( duree(secondes:0.0002 [silence b2] ) ) ]
Music3 = partition (Partition1)
Music4 = partition (Partition2)
{Browse {Mix Interprete Music2}}
MusicInt = [(2.0#Music1) (60.0#Music2)]
%{Browse {MergeHelper MusicInt nil 0.0}}
Music5 = [ merge( MusicInt ) ]
%{Browse {Mix Interprete Music5}}


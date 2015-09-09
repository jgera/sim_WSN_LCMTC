%% test LCMTC_node
startup
%% Si impostano alcuni parametri legati alla simulazione quali:
resolution=1;           % la risoluzione della simulazione, in secondi;
simulation_length=2;    % la lunghezza della simulazione, in giorni;
WSN_TXpower=10;         % la potenza del trasmettitore WSN (del concentratore LC-MTC)
                        % è impostata qui perchè quest'informazione è condivisa sia coi singoli nodi sia col
                        % concentratore

%% Si definisce una WSN costituita da un insieme di "numerodinodi" nodi

%Per l'utilizzo della classe WSN_node, si inizia definendo i parametri in
%ingresso che sono:

WSN_type='generic';     % il tipo di nodo che si vuole creare. Può essere un sensore
                        % di tipo generico, di gas, di elettricità o di acqua. A seconda 
                        % del tipo scelto varieranno i consumi ed i tempi delle misure/trasmissioni;

WSN_node_number=20;     % il numero di nodi che costituisce la WSN
WSN_node_distance=zeros(1,WSN_node_number)
for i=1:WSN_node_number % la distanza dell'i-esimo nodo della WSN dal concentratore LC-MTC
    WSN_node_distance(i)= 15*randn+16; %è un valore random estratto da una distribuzione normale con media 16 m e deviazione standard 15 m.
end

max_WSNnode_daily_tx=10;% il numero di trasmissioni massime che un nodo WSN può effettuare ogni giorno

WSNnode_daily_tx=zeros(1,WSN_node_number);
total_daily_WSN_tx=0;
G=0;

% la probabilità che vi siano delle collisioni è calcolata secondo quanto
% descritto in https://en.wikipedia.org/wiki/ALOHAnet#Pure_ALOHA
% Calcolo G, il numero medio di nodi che iniziano la trasmissione in un
% tempo di frame = numero medio di pacchetti che si vogliono trasmettere
% nel tempo di frame
for i=1:WSN_node_number;
    WSNnode_daily_tx(i)=randi(max_WSNnode_daily_tx);% assegna ai nodi un certo numero di trasmissioni random (numero compreso fra 0 e "max_WSN_daily_tx")
    G= G + ...                      % è la sommatoria del rapporto
        ( WSNnode_daily_tx(i)/...   % fra il numero di trasmissioni giornaliere
        (86400 / 0.110 ))           % ed il numero di slot utili per la trasmissione al giorno (0.110 è la durata della trasmissione per un nodo "generic", in s)
    % calcolo il numero di trasmissioni dei nodi WSN che avvengono durante
    % la singola giornata
    total_daily_WSN_tx=total_daily_WSN_tx+WSNnode_daily_tx(i);
end
% Calcolo S, il numero medio di pacchetti trasmessi con successo ogni tempo
% di frame. Ovviamente S <= G. Infatti S tiene conto dei pacchetti che 
% collidono mentre G no.
S=G*exp(-2*G);

% I pacchetti che si è tentato di TX sono stati, durante tutto il tempo di 
% simulazione:
PacchettiTX=(G*86400/0.110)*simulation_length;
% I pacchetti trasmessi con successo, saranno, durante tutto il tempo di 
% simulazione:
PacchettiSuccTX=(S*86400/0.110)*simulation_length;
% quindi i pacchetti non trasmessi correttamente nel tempo di simulazione 
% sono circa (multipli di due):
PacchettiNonTX=2*round((PacchettiTX-PacchettiSuccTX)/2);

% inoltre, dato che il canale ha le seguenti condizioni:

% allora la probabilità che un pacchetto non arrivi a destinazione è:

% CALCOLA!!! TROVA LA FORMULA SULLA RETE


profilodiPotenzaTotale=zeros(1,86400*simulation_length/resolution);
profilodiEnergiaTotale=profilodiPotenzaTotale;
sequenzadiTXTotale=profilodiPotenzaTotale;

% Imposto le condizioni del canale trasmissivo e, in base al numero di
% trasmissioni nella rete, stimo:
% - il numero di collisioni dei pacchetti;
% - il numero dei pacchetti che non raggiungolo il destinatario a causa
%   delle condizioni del canale trasmissivo (attenuazione, ecc).


% calcolo e visualizzo la potenza e l'energia assorbita da tutti i nodi
for i=1:WSN_node_number;
    nodo_WSN(i)=WSN_node(WSN_type,WSNnode_daily_tx(i),resolution,simulation_length,WSN_node_distance(i),WSN_TXpower);    % il numero di trasmissioni giornaliere del nodo è random, fra 1 e "max_WSN_daily_tx"
    nodo_WSN(i).computePowerSequence();
    nodo_WSN(i).computeEnergySequence();
    sequenzadiTXTotale=sequenzadiTXTotale + nodo_WSN(i).tx_sequence;
    profilodiPotenzaTotale=profilodiPotenzaTotale+nodo_WSN(i).power_sequence;
    profilodiEnergiaTotale=profilodiEnergiaTotale+nodo_WSN(i).energy_sequence;
    
end

%Plot the Tx sequence of the whole network
figure('Name',strcat('test WSN with ',num2str(WSN_node_number),' nodes'),'NumberTitle','off');
subplot(3,1,1);
stem(sequenzadiTXTotale);
ylabel('TX event');
xlabel(strcat('time [',num2str(resolution,'%d'),' s]'));
title('Total TX sequence');
%Plot the Power sequence
subplot(3,1,2);
stairs(profilodiPotenzaTotale*1e+3); %stairs it's a better representation than plot for "PowerSequence": the power consumption remains constant for a time-step!
xlabel(strcat('time [',num2str(resolution,'%d'),' s]'));
ylabel('power [mW]');
title({strcat('Power Sequence of a network composed by ',num2str(WSN_node_number),' WSN nodes');strcat(num2str(max_WSNnode_daily_tx),' max daily transmission each node, each day, ',num2str(simulation_length), ' day(s) simulated')});
%Plot Energy sequence
subplot(3,1,3);
plot(profilodiEnergiaTotale*1e+3);
xlabel(strcat('time [',num2str(resolution,'%d'),' s]'));
ylabel('energy [mJ]');
title({strcat('Energy drained by a network composed by ',num2str(WSN_node_number),' WSN nodes');strcat(num2str(max_WSNnode_daily_tx),' max daily transmission each node, each day, ',num2str(simulation_length), ' day(s) simulated')});

%% Si definisce un concentratore LC-MTC impostando inizialmente i parametri

LCMTC_type='concentrator';      % può contenere qualsiasi stringa, utile per sviluppi futuri
LCMTC_daily_tx=3;               % il numero di trasmissioni giornaliere verso la rete LTE. Da implementare i metodi annessi.
LTEIAT_mean=7200;               % Inter Arrival Time, è l'intervallo tipico fra due trasmissioni LTE 
LCMTC_BatteryLevel=0.5;         % il livello della batteria del concentratore (50% della capacità nominale)
LCMTC_WSN_TXpower=WSN_TXpower;  % [dBm] la potenza del trasmettitore WMBUS

%creo un oggetto "concentratore_LCMTC"
concentratore_LCMTC=LCMTC_node(LCMTC_type,LCMTC_daily_tx,resolution,simulation_length,sequenzadiTXTotale,LCMTC_BatteryLevel,LCMTC_WSN_TXpower,LTEIAT_mean);

% %Plot the WM-BUS transceiver power consumption sequence
figure('Name',strcat('test LCMTC with ',num2str(WSN_node_number),' nodes'),'NumberTitle','off');
% stairs(concentratore_LCMTC.computeWSNPowerSequence.*1e+3,'color','b');
% xlabel(strcat('time [',num2str(resolution,'%d'),' s]'));
% ylabel('power [mW]');
% title('Power drained during WM-BUS messages RX (data RX + TX of ACK + MCU-RUN surplus)');
% hold on;

%Plot the LCMTC power consumption sequence
concentratore_LCMTC.computePowerSequence();
stairs(concentratore_LCMTC.power_sequence.*1e+3,'color',[0 0.5 0]);
xlabel(strcat('time [',num2str(resolution,'%d'),' s]'));
ylabel('power [mW]');
title('Total power drained by LC-MTC concentrator');
% legend('WM-BUS power drained','Total power drained');
% hold off;

% costruisci il taskset, ossia i 3 vettori da dare in paso allo scheduler
[LTE_TX_phase, LTE_TX_deadline, LTE_TX_energy] = concentratore_LCMTC.computeSchedulableTaskset();

%Plot LTE TX phases and deadlines
figure('Name','Vectors of the schedulable taskset (LTE transmission)','NumberTitle','off');
subplot(2,1,1);
hold on
stem(LTE_TX_deadline,'-vb','MarkerEdgeColor','r','MarkerFaceColor','r');
stem(LTE_TX_phase,'-^g','MarkerFaceColor','g');
xlabel('optional LTE TX event number');
ylabel(strcat('timestep [',num2str(resolution,'%d'),' s]'));
legend('deadline','phase','Location','northwest');
title('LTE TX phases and deadlines');
hold off
%Plot LTE TX energies
subplot(2,1,2);
stem(LTE_TX_energy,'-pb','MarkerFaceColor','b');
xlabel('optional LTE TX event number');
ylabel('event energy [J]');
title('LTE TX energies');

%Plot PV incoming power
figure('Name','Energy Source profile','NumberTitle','off');
plot(concentratore_LCMTC.PV_incoming_power);
xlabel('timestep');
ylabel('harvested power [W]');

%Plot energy sequence
concentratore_LCMTC.computeEnergySequence();


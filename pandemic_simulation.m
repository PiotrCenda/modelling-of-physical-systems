clear;
clc;
clf;

%Model parameters
Npop = 500;      % Number of population
Xdim = 4;        % Area X dimension in km
Ydim = 2.5;        % Area Y dimension in km
dx   = 0.05;       % Mean person velocity
MR   = 0.2;       % Ratio of mobile persons
DR   = 0.03;      % Death ratio
dt   = 1;         % Timestep in hours
Tsim = 1500;      % Simulation time
Tinc = 120;       % Incubation mean time (5 days)
Trec = 336;       % Recovery time (2 weeks)
Tinf = 3;         % Contact time required for infection
Rinf = 0.05;     % Contact distance required for infection
TR = 0.95;        % Test success rate

%Variables concerning population
Px = rand(Npop,1)*Xdim-Xdim/2; % x coordinate of persons
Py = rand(Npop,1)*Ydim-Ydim/2; % y coordinate of persons
Ps = zeros(Npop,1);     % Status 0-healthy, 1-infected, 2-ill, 3-convalescent, 4-dead, 5-infected_tested
Pss = zeros(Npop,1);     % Temporary status table
Pa = zeros(Npop,1);     % Status age
Pm = zeros (Npop, Npop); % People conntacted in last 5 days
Pma = zeros (Npop, Npop); % People conntacted in last 5 days status age
Ps(1) = 1;
stat=[];

%Time loop
nt=0;

for t=0:dt:Tsim
    nt = nt+1;
    
    %calculation of statistics
    stat = [stat; t hist(Ps, [0:5])];
    
    %visualisation of results
    clf;
    subplot(2,1,1);
    hold on;
    
    for n=1:Npop
      switch Ps(n)
       case 0
        plot(Px(n),Py(n),'.g');      
       case 1
        plot(Px(n),Py(n),'.b');        
       case 2    
        plot(Px(n),Py(n),'.r');  
       case 3    
        plot(Px(n),Py(n),'.m');  
       case 5    
        plot(Px(n),Py(n),'.c');
      end  
    end
    
    axis([-Xdim/2 Xdim/2 -Ydim/2 Ydim/2]);
    title(['Simulation time ' int2str(t) ' (hours)']); 
    xlabel('x dimension (km)');
    ylabel('y dimension (km)');
    subplot(2,1,2);
    plot(stat(:,1),stat(:,2),'-g',...
         stat(:,1),stat(:,3),'-b',...
         stat(:,1),stat(:,4),'-r',...
         stat(:,1),stat(:,5),'-m',...
         stat(:,1),stat(:,6),'-k',...
         stat(:,1),stat(:,7),'-c');
     legend('healthy','infected','ill','recovered','death','infected tested', 'Location','northwest');
     title(['Healthly: ' int2str(stat(nt,2)) ' infected: ' int2str(stat(nt,3)) ' ill: ' int2str(stat(nt,4)) ' recoverd: ' int2str(stat(nt,5)) ' dead: ' int2str(stat(nt,6)) ' infected tested: ' int2str(stat(nt, 7))]);
     xlabel('time (hours)');
     ylabel('no of cases');
    pause(0.01);
    
    % moving people
    for n=1:Npop 
      if Ps(n) ~= 2 && Ps(n) ~= 4 && Ps(n) ~= 5 && rand(1) < MR  % condition states that person does not moves if he/she knows that is infected/ill (so ill cases and infected tested) and with MR probability
        pdx = randn(1);
        pdy = randn(1);
        Px_temp = Px(n)+pdx*dx;
        Py_temp = Py(n)+pdy*dx;
        safe_move = true;
        
        if Ps(n) == 0 || Ps(n) == 1 % this condition prevents healthy person from stepping in area where he/she can get infected
            for k=1:Npop
                if Ps(k) == 2 || Ps(k) == 5 % checks distance to ill/infected person
                    distance = sqrt((Px_temp-Px(k))^2+(Py_temp-Py(k))^2);
                    if distance <= Rinf  % if distance is to small then it is not safe to move
                        safe_move = false;
                        break;
                    end
                end
            end
        end
      
        % if move is, in respect to whole population, not dangerous then current person can move that way
        if safe_move == true
            Px(n) = Px_temp;
            Py(n) = Py_temp;
        end
      end
      
      Ix = fix(Px/(0.5*Xdim));
      Iy = fix(Py/(0.5*Ydim));
      Px = Px - Xdim*Ix;
      Py = Py - Ydim*Iy;
    end

%     for n=1:Npop
%       if rand(1)< MR && Ps(n) ~= 2  
%         Px(n) = Px(n)+randn(1)*dx;
%         Py(n) = Py(n)+randn(1)*dx;
%       end  
%       Ix = fix(Px/(0.5*Xdim));
%       Iy = fix(Py/(0.5*Ydim));
%       Px = Px - Xdim*Ix;
%       Py = Py - Ydim*Iy;
%     end
    
    %counting of infections
    % infection detection
    Pss = zeros(Npop,1);
    
    for n=1:Npop-1
        for m=n+1:Npop
          %calculation of distance
          distance = sqrt((Px(n)-Px(m))^2+(Py(n)-Py(m))^2);
          
          if distance < Rinf
            if ((Ps(m)>0 && Ps(m)<3) || Ps(m)==5) && Ps(n)==0  % added infections coming from tested people
              Pss(n)=1;
            end    
            if ((Ps(n)>0 && Ps(n)<3) || Ps(n)==5) && Ps(m)==0  % added infections coming from tested people
              Pss(m)=1;
            end
            
            Pm(n, m) = 1;
            Pm(m, n) = 1;
          end  
        end
    end
    
    % status modification
    for n=1:Npop
        if Pss(n) == 1                 % Increment age of contact with infected person
            Pa(n)=Pa(n)+dt;
        end 

        if Ps(n)>0                     % Increment age of status
            Pa(n)=Pa(n)+dt;
        end 

        if Ps(n)==0 && Pa(n)==Tinf     % If contact > inection time -> infected
            Ps(n)=1;
            Pa(n)=0;
        end   

        if Ps(n)==1 && Pa(n)==Tinc     % If infection > incubation -> ill
            Ps(n)=2;
            Pa(n)=0;

            for k=1:Npop
                if (Ps(k) == 1 || Ps(k) == 0) && Pm(n, k) == 1
                    if rand(1) < TR && Ps(k) == 1
                        Ps(k) = 5;
                    end
                    Pm(n, k) = 0;
                    Pma(n, k) = 0;
%                     for p=1:Npop
%                         Pm(k, p) = 0;
%                         Pma(k, p) = 0;
%                     end
                end
            end

            for p=1:Npop
                Pm(n, p) = 0;
                Pma(n, p) = 0;
            end
        end

        if Ps(n)==5 && Pa(n)==Tinc     % If infection tested > incubation -> ill
            Ps(n)=2;
            Pa(n)=0;
        end 

        if Ps(n)==2 && Pa(n)==Trec     % If illnes > recovery -> reconvalescent
            if rand(1)>DR
                Ps(n)=3;
            else
                Ps(n)=4;
            end    
            Pa(n)=0;
        end 
    end

    for n=1:Npop
        for m=1:Npop
          if Pm(n, m) == 1
            Pma(n, m) = Pma(n, m) + dt;
          end
          
          if Pm(m, n) == 1
            Pma(m, n) = Pma(m, n) + dt;
          end
          
          if Pma(n, m) > 120
            Pma(n, m) = 0;
            Pm(n, m) = 0;
          end

          if Pma(m, n) > 120
            Pma(m, n) = 0;
            Pm(m, n) = 0;
          end
        end
    end 

    if mod(t, 200) == 0
        name = sprintf('isolation3_%d.png', t);
        saveas(gcf, name);
    end
end
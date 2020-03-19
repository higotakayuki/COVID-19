function simulation
flag_gpu_on=true;
infection_days=10;
connection_type=2;

I=300;
J=300;
max_days=10000;

switch connection_type
    case 1
        infection_probability=1/13; %for 4 neighbours
    case 2
        infection_probability=1/30; % for 8 neighbours
end


state=int8(zeros(I,J));
rows=2:I-1;
cols=2:J-1;

if flag_gpu_on
    state=gpuArray(state);
    rows=gpuArray(rows);
    cols=gpuArray(cols);
end

[cols2d,rows2d]=meshgrid(cols,rows);

infected=state~=0 & state~=infection_days;

for t=1:max_days
    state(floor(I/2),floor(J/2))=1;
    tmp=arrayfun(@update,rows2d,cols2d);
    state(rows,cols)=tmp;
    state(infection_days<state)=infection_days;
    infected=state~=0 & state~=infection_days;
    total_num_carrier(t)=sum(infected,'all')-1;
    
    %%
    figure(1)
    subplot(1,3,1)
    imagesc(state)
    title(sprintf('%d days',t))
    subplot(1,3,2)
    imagesc(infected)
    title(sprintf('number of carrierF%d people',total_num_carrier(t)))
    subplot(1,3,3)
    plot(total_num_carrier)
    grid on
    drawnow
    
    %%
    F=getframe(1);
    [X,map]=rgb2ind(F.cdata,256);
    out_filename=sprintf('anim%d.gif',connection_type);
    if t==1
        imwrite(X,map,out_filename,'DelayTime',0.1)
    else
        imwrite(X,map,out_filename,'WriteMode','append','DelayTime',0.1)
    end
    if 100<t && total_num_carrier(t)==0,break;end
end

    function ret=update(i,j)
        if state(i,j)==0
            num_infected1=infected(i-1,j)+infected(i,j-1)+infected(i,j+1)+infected(i+1,j);
            num_infected2=infected(i-1,j-1)+infected(i-1,j+1)+infected(i+1,j-1)+infected(i+1,j+1);
%             num_infected=num_infected1;
            num_infected=num_infected1+num_infected2;
            flag_infected=(1-infection_probability).^num_infected<rand();
            ret=int8(flag_infected);
        else
            ret=state(i,j)+1;
        end
    end
end
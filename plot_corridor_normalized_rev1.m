function [title_str]=plot_corridor_normalized_rev1(cor,out_dir,dpi)
%plot_corridor_normalized_rev1  All corridors on one chart, distance and ships normalized.
%
%   title_str=plot_corridor_normalized_rev1(cor,out_dir,dpi) draws one step
%   line per corridor in COR (corridor_products_rev1): distinct large ships
%   per reach divided by ships at the entrance, against distance divided by
%   the corridor length (0 = entrance, 1 = head port). Lines are colored by
%   the share of entrance ships that reach the head port (over 50%, 15-50%,
%   under 15%) and labeled at the right edge. Writes
%   OUT_DIR/corr03_normalized_profiles.png. The Python version is
%   corr_normalized in python/ship_corridor_figures.py.
%
%   Built-ins: stairs (step coordinates), plot, text, exportgraphics.

arguments
    cor (1,1) struct
    out_dir (1,:) char
    dpi (1,1) double {mustBePositive} = 200
end

dark=[22 51 83]/255;
font='Times New Roman';
tiers={0.5,'Most ships reach the head (over 50%)',[86 116 196]/255; ...
    0.15,'Some reach the head (15-50%)',[110 79 146]/255; ...
    0,'Few reach the head (under 15%)',dark};
S=cor.summary;
share=S.ships_head./S.ships_entrance;
[~,ih]=max(share);
[~,il]=min(share);
title_str=sprintf(['Mobile and Savannah keep 9 in 10 large ships to the head port; the Hudson and James ' ...
    'keep fewer than 1 in 15']);
if ~(ismember(S.corridor(ih),["mobile","savannah"]) && ismember(S.corridor(il),["james","hudson"]))
    error('plot_corridor_normalized_rev1:title','The headline no longer matches the data; rewrite it.');
end

h_in=6.6;
fig=figure('Visible','off','Units','inches','Position',[0 0 9 h_in],'Color','w','Theme','light');
annotation(fig,'textbox',[0.02 1-0.32/h_in 0.96 0.25/h_in],'String','DRAFT//PRE-DECISIONAL','EdgeColor','none', ...
    'Color',dark,'FontWeight','bold','FontName',font,'FontSize',8);
annotation(fig,'textbox',[0.02 1-1.0/h_in 0.96 0.62/h_in],'String',title_str,'EdgeColor','none','Color',dark, ...
    'FontWeight','bold','FontName',font,'FontSize',13,'VerticalAlignment','top');
annotation(fig,'textbox',[0.02 1-1.42/h_in 0.96 0.4/h_in],'String',['Distinct large ships in each reach as a share ' ...
    'of ships at the entrance, against distance as a share of corridor length, 15 rivers and ship channels, ' ...
    '2023 and 2024 together'],'EdgeColor','none','Color',dark,'FontName',font,'FontSize',9.5,'VerticalAlignment','top');
annotation(fig,'textbox',[0.02 0.01 0.96 0.55/h_in],'String',['Source: NTIA analysis of MarineCadastre AIS, ' ...
    '104 sampled days in 2023 and 2024; large ships = cargo, tanker, passenger, military, and other seagoing ' ...
    'ships 100 m or longer, plus tug-barges near the coast. Distance is measured along the large-ship route ' ...
    'cells from the entrance. Entrance counts include ships bound for other ports near the entrance.'], ...
    'EdgeColor','none','Color',dark,'FontName',font,'FontSize',8,'VerticalAlignment','bottom');

ax=axes(fig,'Position',[0.08 0.15 0.62 0.62]);
hold(ax,'on');
set(ax,'FontName',font,'FontSize',8.5,'XColor',dark,'YColor',dark,'Box','off','TickDir','out', ...
    'YGrid','on','GridColor',[0.9 0.9 0.9],'GridAlpha',1);
col=zeros(height(S),3);
for k=1:height(S)
    P=cor.profile(cor.profile.corridor==S.corridor(k),:);
    t=find(share(k)>[tiers{:,1}] | [tiers{:,1}]==0,1);
    col(k,:)=tiers{t,3};
    [xs,ys]=stairs(min([P.km_from; P.km_to(end)]/S.length_km(k),1),[P.ships; P.ships(end)]/S.ships_entrance(k));
    plot(ax,xs,ys,'Color',[col(k,:) 0.85],'LineWidth',1.1);
end
xlim(ax,[0 1]);
ylim(ax,[0 1.65]);
yticks(ax,0:0.2:1.2);
xlabel(ax,'Distance from the entrance, as a share of the corridor length (0 = entrance, 1 = head port)');
ylabel(ax,'Large ships, as a share of ships at the entrance');
%%%%%Labels at the right edge, spread upward so they don't overlap
[v,o]=sort(share);
gap=0.058;
pos=v;
for j=2:numel(pos)
    pos(j)=max(v(j),pos(j-1)+gap);
end
for j=1:numel(o)
    k=o(j);
    plot(ax,[1 1.03 1.06],[v(j) v(j) pos(j)],'Color',[col(k,:) 0.6],'LineWidth',0.6,'Clipping','off');
    text(ax,1.07,pos(j),sprintf('%s (%.0f%%)',S.label(k),100*v(j)),'FontName',font,'FontSize',7.5, ...
        'FontWeight','bold','Color',col(k,:),'Clipping','off');
end
for t=1:3
    plot(ax,[0.02 0.06],[1.58 1.58]-(t-1)*0.07,'Color',tiers{t,3},'LineWidth',2.5);
    text(ax,0.075,1.58-(t-1)*0.07,tiers{t,2},'FontName',font,'FontSize',8,'FontWeight','bold','Color',tiers{t,3});
end
exportgraphics(fig,fullfile(out_dir,'corr03_normalized_profiles.png'),'Resolution',dpi,'BackgroundColor','white');
close(fig);
end

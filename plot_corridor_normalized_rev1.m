function [titles]=plot_corridor_normalized_rev1(cor,out_dir,dpi)
%plot_corridor_normalized_rev1  Continuation curves for all corridors on one chart.
%
%   titles=plot_corridor_normalized_rev1(cor,out_dir,dpi) uses
%   cor.continuation (corridor_products_rev1): distinct large ships seen at
%   or beyond each point, with distance scaled so 1 = the head port. Every
%   corridor is a thin gray step line; Savannah, Houston, the Mississippi, and
%   the Hudson are drawn in the accent and labeled at the right. Writes:
%
%     corr03_normalized_profiles   share of entering ships still on the corridor
%     corr04_continuation_counts   the same as ship counts (y not normalized)
%
%   The Python versions are corr_normalized and corr_counts in
%   python/ship_corridor_figures.py. Built-ins: stairs, plot, text,
%   exportgraphics.

arguments
    cor (1,1) struct
    out_dir (1,:) char
    dpi (1,1) double {mustBePositive} = 200
end

S=cor.summary;
K=cor.continuation;
M=cor.marks;
head_n=@(c) K.ships_beyond(K.corridor==c & K.frac_to_head==1);
titles=strings(2,1);
titles(1)=sprintf(['%.0f%% of the large ships that enter the Savannah River reach Garden City; on the Hudson ' ...
    'and the Mississippi, fewer than 1 in 10 reach the head port'],100*S.share_reaching_head(S.corridor=="savannah"));
if any(S.share_reaching_head(ismember(S.corridor,["hudson","mississippi"]))>=0.1)
    error('plot_corridor_normalized_rev1:title','The headline no longer matches the data; rewrite it.');
end
titles(2)=sprintf(['More large ships enter the Mississippi and the Houston Ship Channel than any other corridor, ' ...
    'but only about %d reach Baton Rouge and %d reach Houston'],round(head_n("mississippi"),-1),round(head_n("houston"),-1));
[~,o]=sort(K.ships_beyond(K.frac_to_head==0),'descend');
first=K(K.frac_to_head==0,:);
if ~isequal(sort(first.corridor(o(1:2))),sort(["houston";"mississippi"]))
    error('plot_corridor_normalized_rev1:title','The second headline no longer matches the data; rewrite it.');
end
src=['Source: NTIA analysis of MarineCadastre AIS, 104 sampled days in 2023 and 2024; large ships = cargo, ' ...
    'tanker, passenger, military, and other seagoing ships 100 m or longer, plus tug-barges near the coast. ' ...
    'Distance is measured along the large-ship route cells from the entrance. '];
draw(K,S,M,'share_beyond',titles(1),['Share of large ships entering each corridor that were seen at or beyond ' ...
    'each point, 15 rivers and ship channels, 2023 and 2024 together'],[src 'Ships entering = seen at least ' ...
    '3 km in from the entrance on any sampled day.'],'Share of entering large ships still on the corridor', ...
    @(v) sprintf('%.0f%%',100*v),1.05,fullfile(out_dir,'corr03_normalized_profiles.png'),dpi);
draw(K,S,M,'ships_beyond',titles(2),['Distinct large ships seen at or beyond each point of each corridor, ' ...
    '15 rivers and ship channels, 2023 and 2024 together'],[src 'Counts start 3 km in from the entrance.'], ...
    'Distinct large ships seen at or beyond this point',@(v) sprintf('%s ships',comma(v)), ...
    1.08*max(first.ships_beyond),fullfile(out_dir,'corr04_continuation_counts.png'),dpi);
end

function draw(K,S,M,var,title_str,subtitle,source,ylab,fmt,ytop,png,dpi)
dark=[22 51 83]/255;
blue=[86 116 196]/255;
font='Times New Roman';
hl=["savannah","houston","mississippi","hudson"];
h_in=6.4;
fig=figure('Visible','off','Units','inches','Position',[0 0 9 h_in],'Color','w','Theme','light');
annotation(fig,'textbox',[0.02 1-0.32/h_in 0.96 0.25/h_in],'String','DRAFT//PRE-DECISIONAL','EdgeColor','none', ...
    'Color',dark,'FontWeight','bold','FontName',font,'FontSize',8);
annotation(fig,'textbox',[0.02 1-1.0/h_in 0.96 0.62/h_in],'String',title_str,'EdgeColor','none','Color',dark, ...
    'FontWeight','bold','FontName',font,'FontSize',13,'VerticalAlignment','top');
annotation(fig,'textbox',[0.02 1-1.42/h_in 0.96 0.4/h_in],'String',subtitle,'EdgeColor','none','Color',dark, ...
    'FontName',font,'FontSize',9.5,'VerticalAlignment','top');
annotation(fig,'textbox',[0.02 0.01 0.96 0.55/h_in],'String',source,'EdgeColor','none','Color',dark, ...
    'FontName',font,'FontSize',8,'VerticalAlignment','bottom');
ax=axes(fig,'Position',[0.09 0.16 0.60 0.60]);
hold(ax,'on');
set(ax,'FontName',font,'FontSize',8.5,'XColor',dark,'YColor',dark,'Box','off','TickDir','out', ...
    'YGrid','on','GridColor',[0.9 0.9 0.9],'GridAlpha',1);
xlim(ax,[0 1]);
ylim(ax,[0 ytop]);
names=S.corridor';
ends=zeros(numel(hl),1);
for c=[names(~ismember(names,hl)) hl]
    T=K(K.corridor==c,:);
    [xs,ys]=stairs(T.frac_to_head,T.(var));
    if ismember(c,hl)
        plot(ax,xs,ys,'Color',blue,'LineWidth',2);
        ends(hl==c)=T.(var)(end);
    else
        plot(ax,xs,ys,'Color',[0.725 0.733 0.745],'LineWidth',0.8);
    end
end
%%%%%Labels for the highlighted corridors, spread so they don't overlap
[v,o]=sort(ends);
pos=v;
gap=0.06*ytop;
for j=2:numel(pos)
    pos(j)=max(v(j),pos(j-1)+gap);
end
for j=1:numel(o)
    c=hl(o(j));
    en=M.name(M.corridor==c & M.role=="end");
    plot(ax,[1 1.02 1.04],[v(j) v(j) pos(j)],'Color',blue,'LineWidth',0.6,'Clipping','off');
    text(ax,1.05,pos(j),sprintf('%s to %s: %s',S.label(S.corridor==c),en,fmt(v(j))),'FontName',font, ...
        'FontSize',8,'FontWeight','bold','Color',blue,'Clipping','off');
end
text(ax,0.99,0.985,'Gray: the other 11 rivers and ship channels (Table 7)','Units','normalized', ...
    'HorizontalAlignment','right','VerticalAlignment','top','FontName',font,'FontSize',8,'Color',dark);
xlabel(ax,'Distance from the entrance, as a share of the distance to the head port (1 = head port)');
ylabel(ax,ylab);
exportgraphics(fig,png,'Resolution',dpi,'BackgroundColor','white');
close(fig);
end

function s=comma(n)
s=char(string(round(n)));
s=fliplr(regexprep(fliplr(s),'(\d{3})(?=\d)','$1,'));
end

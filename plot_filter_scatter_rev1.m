function [info]=plot_filter_scatter_rev1(M,L_cut,png_path,dpi)
%plot_filter_scatter_rev1  Working-paper figure: what the 100 m length filter keeps and drops.
%
%   info=plot_filter_scatter_rev1(M,L_cut,png_path,dpi) plots registry
%   gross tonnage (log scale) against AIS length for the matched ships in
%   table M (check_gt_proxy_rev1 output .matched: length_m, gt). Ships the
%   length filter keeps (length >= L_CUT) are light blue; ships it drops
%   are gray. The kept side is shaded, the 3,000 GT line marks the SOLAS
%   Chapter V, Regulation 19 size for a 3 GHz radar, and each quadrant is
%   labeled with its ship count. Writes a PNG at DPI (default 200).
%
%   info returns the four counts, precision, recall, and the title.
%
%   Follows the NTIA figure rules: DRAFT//PRE-DECISIONAL at the top, a
%   takeaway title, direct labels instead of a legend, dark-blue source
%   line, Times New Roman, light blue as the one highlight.
%
%   Built-ins: scatter, patch, yline/xline, exportgraphics.

arguments
    M table
    L_cut (1,1) double {mustBePositive}
    png_path (1,:) char
    dpi (1,1) double {mustBePositive} = 200
end

dark_blue=[22 51 83]/255;
light_blue=[86 116 196]/255;
mid_gray=[138 141 145]/255;
font_name='Times New Roman';
gt_rule=3000;   %%%%%SOLAS Chapter V, Regulation 19.2.7

ok=M.length_m>0 & M.gt>0;
M=M(ok,:);
kept=M.length_m>=L_cut;
big=M.gt>=gt_rule;
info.kept_big=nnz(kept & big);
info.kept_small=nnz(kept & ~big);
info.dropped_big=nnz(~kept & big);
info.dropped_small=nnz(~kept & ~big);
info.precision=info.kept_big/(info.kept_big+info.kept_small);
info.recall=info.kept_big/(info.kept_big+info.dropped_big);

x_lim=[0 400];
y_lim=[1e2 4e5];
fig=figure('Visible','off','Units','inches','Position',[0 0 7.5 5.4],'Color','w','Theme','light');
ax=axes(fig,'Position',[0.10 0.17 0.86 0.64]);
hold(ax,'on');
set(ax,'YScale','log','FontName',font_name,'FontSize',10,'XColor',dark_blue,'YColor',dark_blue, ...
    'Box','off','TickDir','out','Layer','top');
%%%%%Kept side shaded
patch(ax,[L_cut x_lim(2) x_lim(2) L_cut],[y_lim(1) y_lim(1) y_lim(2) y_lim(2)],light_blue, ...
    'FaceAlpha',0.08,'EdgeColor','none');
scatter(ax,M.length_m(~kept),M.gt(~kept),7,mid_gray,'filled','MarkerFaceAlpha',0.5);
scatter(ax,M.length_m(kept),M.gt(kept),7,light_blue,'filled','MarkerFaceAlpha',0.5);
xline(ax,L_cut,'Color',dark_blue,'LineWidth',1.2);
yline(ax,gt_rule,'--','Color',dark_blue,'LineWidth',1);
xlim(ax,x_lim);
ylim(ax,y_lim);
yticks(ax,[1e2 1e3 1e4 1e5]);
yticklabels(ax,{'100','1,000','10,000','100,000'});
xlabel(ax,'Length reported in AIS (m)','Color',dark_blue);
ylabel(ax,'Wikidata gross tonnage (log scale)','Color',dark_blue);

%%%%%Line labels
text(ax,L_cut+4,1.4e2,sprintf('%g m length filter',L_cut),'Color',dark_blue,'FontName',font_name, ...
    'FontSize',9,'FontWeight','bold','VerticalAlignment','bottom');
text(ax,x_lim(2)-4,gt_rule*0.80,'3,000 GT: SOLAS 3 GHz radar size','Color',dark_blue,'FontName',font_name, ...
    'FontSize',9,'HorizontalAlignment','right','VerticalAlignment','top');

%%%%%Quadrant counts
label=@(x,y,s,c,ha) text(ax,x,y,s,'Color',c,'FontName',font_name,'FontSize',10,'FontWeight','bold', ...
    'HorizontalAlignment',ha,'BackgroundColor','w','Margin',1);
label(L_cut+10,2.0e5,sprintf('Kept, 3,000 GT or more: %s ships',comma(info.kept_big)),light_blue,'left');
label(L_cut+10,4.5e2,sprintf('Kept, under 3,000 GT: %s',comma(info.kept_small)),light_blue,'left');
label(L_cut-6,2.0e5,sprintf('Dropped, 3,000 GT or more: %s',comma(info.dropped_big)),mid_gray,'right');
label(L_cut-6,1.6e2,sprintf('Dropped, under 3,000 GT: %s',comma(info.dropped_small)),mid_gray,'right');

annotation(fig,'textbox',[0.02 0.94 0.96 0.05],'String','DRAFT//PRE-DECISIONAL','EdgeColor','none', ...
    'Color',dark_blue,'FontWeight','bold','FontName',font_name,'FontSize',8,'HorizontalAlignment','center');
info.title=sprintf('The %g m filter keeps %.0f%% of ships big enough to need an S-band radar, and few others', ...
    L_cut,100*info.recall);
annotation(fig,'textbox',[0.02 0.84 0.96 0.10],'String',info.title,'EdgeColor','none','Color',dark_blue, ...
    'FontWeight','bold','FontName',font_name,'FontSize',12,'HorizontalAlignment','left');
source_str=sprintf(['Source: NTIA analysis of MarineCadastre AIS (passenger, cargo, and tanker ships with an IMO number, ' ...
    'four days in 2024) matched by IMO number to Wikidata gross tonnage; %s ships. Light blue: kept by the filter; ' ...
    'gray: dropped.'],comma(height(M)));
annotation(fig,'textbox',[0.02 0.0 0.96 0.08],'String',source_str,'EdgeColor','none','Color',dark_blue, ...
    'FontName',font_name,'FontSize',8,'HorizontalAlignment','left');

exportgraphics(fig,png_path,'Resolution',dpi,'BackgroundColor','white');
close(fig);
end

function s=comma(n)
%%%%%Integer with thousands separators
s=char(string(n));
s=regexprep(fliplr(s),'(\d{3})(?=\d)','$1,');
s=fliplr(s);
end

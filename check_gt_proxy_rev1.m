function [chk]=check_gt_proxy_rev1(V,ref,filt,png_path)
%check_gt_proxy_rev1  Test the AIS length cutoff as a proxy for 3,000 gross tonnage.
%
%   chk=check_gt_proxy_rev1(V,ref,filt,png_path) joins the AIS ships in V
%   (ais_vessel_list_rev1) to registry gross tonnage in REF
%   (load_wikidata_gt_rev1) by IMO number, and measures how well
%   "length >= filt.min_length_m" picks out ships of 3,000 GT and up, the
%   SOLAS V/19 size for a 3 GHz radar. It writes a scatter plot to
%   PNG_PATH (skip with '').
%
%   chk fields
%     .num_ais        ships of the filtered types with an IMO number and a length
%     .num_matched    of those, ships found in REF
%     .coverage       match rate by 25 m length bin (table)
%     .at_cutoff      confusion counts and rates at filt.min_length_m
%     .sweep          precision and recall for cutoffs from 50 to 200 m (table)
%     .by_type        rates at the cutoff for passenger, cargo, and tanker
%     .length_check   AIS length vs registry length (median and 90th
%                     percentile absolute difference, m)
%     .no_imo_large   ships of the filtered types, 100 m and up, with no IMO
%                     number (the IMO rule drops these)
%     .matched        the joined table, for follow-up
%
%   Precision = share of ships the cutoff keeps that are >= 3,000 GT.
%   Recall    = share of >= 3,000 GT ships that the cutoff keeps.

arguments
    V table
    ref table
    filt (1,1) struct
    png_path (1,:) char = ''
end

gt_rule=3000;   %%%%%SOLAS Chapter V, Regulation 19.2.7: 3,000 GT and upward
L_cut=filt.min_length_m;

typed=ismember(V.vessel_type,filt.vessel_types) & V.length_m>0;
chk.no_imo_large=nnz(typed & isnan(V.imo) & V.length_m>=100);
A=V(typed & ~isnan(V.imo),:);
chk.num_ais=height(A);

[found,loc]=ismember(A.imo,ref.imo);
M=A(found,:);
M.gt=ref.gt(loc(found));
M.len_wd_m=ref.len_wd_m(loc(found));
chk.num_matched=height(M);
chk.matched=M;

%%%%%Coverage by length bin: is the reference sample biased toward big ships?
edges=[0 50 75 100 125 150 200 250 300 450];
bin_all=discretize(A.length_m,edges);
bin_hit=discretize(M.length_m,edges);
n_all=accumarray(bin_all(~isnan(bin_all)),1,[numel(edges)-1 1]);
n_hit=accumarray(bin_hit(~isnan(bin_hit)),1,[numel(edges)-1 1]);
chk.coverage=table(edges(1:end-1)',edges(2:end)',n_all,n_hit,n_hit./n_all, ...
    'VariableNames',{'len_from_m','len_to_m','ais_ships','matched','match_rate'});

%%%%%Confusion at the cutoff
is_big=M.gt>=gt_rule;
kept=M.length_m>=L_cut;
chk.at_cutoff=confusion(kept,is_big);
chk.at_cutoff.cutoff_m=L_cut;

%%%%%Sweep cutoffs
L_list=(50:5:200)';
P=NaN(size(L_list));
Rc=NaN(size(L_list));
for k=1:numel(L_list)
    c=confusion(M.length_m>=L_list(k),is_big);
    P(k)=c.precision;
    Rc(k)=c.recall;
end
chk.sweep=table(L_list,P,Rc,'VariableNames',{'cutoff_m','precision','recall'});

%%%%%By type group
groups={'passenger',60:69;'cargo',70:79;'tanker',80:89};
by=table('Size',[size(groups,1) 6],'VariableTypes',{'string','double','double','double','double','double'}, ...
    'VariableNames',{'group','matched','gt3000','kept','precision','recall'});
for k=1:size(groups,1)
    in=ismember(M.vessel_type,groups{k,2});
    c=confusion(kept(in),is_big(in));
    by(k,:)={groups{k,1},nnz(in),nnz(is_big(in)),nnz(kept(in)),c.precision,c.recall};
end
chk.by_type=by;

%%%%%AIS length vs registry length
has_len=M.len_wd_m>0;
d=abs(M.length_m(has_len)-M.len_wd_m(has_len));
chk.length_check=struct('num',nnz(has_len),'median_abs_m',median(d),'p90_abs_m',prctile(d,90));

if ~isempty(png_path)
    plot_check(M,is_big,kept,L_cut,gt_rule,chk,png_path);
end
end

function c=confusion(kept,is_big)
%%%%%Counts and rates for one cutoff
c.true_pos=nnz(kept & is_big);
c.false_pos=nnz(kept & ~is_big);
c.false_neg=nnz(~kept & is_big);
c.true_neg=nnz(~kept & ~is_big);
c.precision=c.true_pos/max(c.true_pos+c.false_pos,1);
c.recall=c.true_pos/max(c.true_pos+c.false_neg,1);
end

function plot_check(M,is_big,kept,L_cut,gt_rule,chk,png_path)
%%%%%Scatter: AIS length vs registry GT, log scale, with the two rules
dark_blue=[22 51 83]/255;
light_blue=[86 116 196]/255;
mid_gray=[138 141 145]/255;
purple=[112 48 160]/255;
font_name='Times New Roman';

fig=figure('Visible','off','Units','inches','Position',[0 0 7.5 5.2],'Color','w','Theme','light');
ax=axes(fig,'Position',[0.10 0.16 0.86 0.64]);
hold(ax,'on');
ok=kept==(is_big);
scatter(ax,M.length_m(ok),M.gt(ok),4,mid_gray,'filled','MarkerFaceAlpha',0.35);
scatter(ax,M.length_m(~ok),M.gt(~ok),6,purple,'filled','MarkerFaceAlpha',0.7);
set(ax,'YScale','log','FontName',font_name,'FontSize',9,'XColor',dark_blue,'YColor',dark_blue,'Box','off','TickDir','out');
xlim(ax,[0 400]);
ylim(ax,[100 3e5]);
xline(ax,L_cut,'Color',light_blue,'LineWidth',1.5);
yline(ax,gt_rule,'Color',light_blue,'LineWidth',1.5);
xlabel(ax,'Length reported in AIS (m)');
ylabel(ax,'Gross tonnage (log scale)');
c=chk.at_cutoff;
text(ax,L_cut+5,250,sprintf('%g m cutoff',L_cut),'Color',light_blue,'FontWeight','bold','FontName',font_name,'FontSize',9);
text(ax,395,gt_rule*0.72,'3,000 GT (SOLAS 3 GHz radar rule)','Color',light_blue,'FontWeight','bold','FontName',font_name,'FontSize',9,'HorizontalAlignment','right');
text(ax,385,150,sprintf('Purple: cutoff and tonnage disagree (%d of %d ships)',c.false_pos+c.false_neg,height(M)), ...
    'Color',purple,'FontName',font_name,'FontSize',9,'HorizontalAlignment','right');

annotation(fig,'textbox',[0.02 0.94 0.96 0.05],'String','DRAFT//PRE-DECISIONAL','EdgeColor','none', ...
    'Color',dark_blue,'FontWeight','bold','FontName',font_name,'FontSize',8,'HorizontalAlignment','center');
%%%%%One decimal: whole-percent rounding would show 99.55% as 100%
title_str=sprintf('%.1f%% of ships the %g m cutoff keeps are 3,000 GT or more; it keeps %.1f%% of those ships', ...
    100*c.precision,L_cut,100*c.recall);
annotation(fig,'textbox',[0.02 0.83 0.96 0.10],'String',title_str,'EdgeColor','none', ...
    'Color',dark_blue,'FontWeight','bold','FontName',font_name,'FontSize',12,'HorizontalAlignment','left');
annotation(fig,'textbox',[0.02 0.0 0.96 0.07],'String', ...
    ['Source: NTIA analysis of MarineCadastre AIS (passenger, cargo, and tanker ships with an IMO number) ' ...
    'matched by IMO number to gross tonnage on Wikidata.'],'EdgeColor','none', ...
    'Color',dark_blue,'FontName',font_name,'FontSize',8,'HorizontalAlignment','left');
exportgraphics(fig,png_path,'Resolution',200,'BackgroundColor','white');
close(fig);
end

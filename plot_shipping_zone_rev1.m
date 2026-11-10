function plot_shipping_zone_rev1(result,png_path)
%plot_shipping_zone_rev1  Map of the ship-source cells and each zone polygon.
%
%   plot_shipping_zone_rev1(result,png_path) draws the zones (largest
%   distance first) and the ship-source cells on a geographic axes and
%   saves the figure to PNG_PATH.
%
%   Built-ins: geopolyshape and geoplot draw the polygons; geoscatter
%   draws the source cells; exportgraphics writes the PNG.

arguments
    result (1,1) struct
    png_path (1,:) char
end

fig=figure('Visible','off','Position',[100 100 1400 850]);
gx=geoaxes(fig);
geobasemap(gx,'grayland');
hold(gx,'on');

[~,order]=sort([result.zone.distance_km],'descend');
face_colors=parula(max(numel(order),2));
legend_text=strings(0,1);
legend_handles=gobjects(0,1);
for k=1:numel(order)
    z=result.zone(order(k));
    if z.poly.NumRegions==0
        continue
    end
    [lon_b,lat_b]=boundary(z.poly);
    h=geoplot(gx,geopolyshape(lat_b,lon_b),'FaceColor',face_colors(k,:),'FaceAlpha',0.35,'EdgeColor','none');
    legend_handles(end+1,1)=h; %#ok<AGROW> at most a few distances
    legend_text(end+1,1)=sprintf('%g km zone',z.distance_km); %#ok<AGROW>
end

[lat_grid,lon_grid]=geographicGrid(result.R);
h_src=geoscatter(gx,lat_grid(result.source_mask),lon_grid(result.source_mask),1,'k','filled');
legend_handles(end+1,1)=h_src;
legend_text(end+1,1)="Large-ship cells (AIS + fairways)";

geolimits(gx,result.R.LatitudeLimits,result.R.LongitudeLimits);
legend(gx,legend_handles,legend_text,'Location','southwest');
title(gx,sprintf('Large-ship (S-band radar) zones, %s mode — DRAFT//PRE-DECISIONAL',result.params.zone_mode));
exportgraphics(fig,png_path,'Resolution',200);
close(fig);
end

function cells = guam_cnmi_links_rev1(out_csv)
%GUAM_CNMI_LINKS_REV1 Straight-line link cells Apra Harbor - Rota - Tinian - Saipan.
%   MATLAB twin of python/guam_cnmi_links.py. The sampled AIS days hold no Saipan or
%   Tinian lane, so these cells are a modeling assumption, not AIS. Grid matches
%   init_shipping_zone_guam_rev1: 12 to 21.5 N, 143.5 to 147 E, 0.01 deg; index is
%   column-major from the south-west cell, 1-based. Returns the sorted cell indices
%   and, if out_csv is given, writes one index per row.
%   Built-ins considered: interpm and track1 (great-circle or rhumb line) don't fit,
%   because the Python version uses straight lines in latitude and longitude.
arguments
    out_csv (1,1) string = ""
end
lat0=12.0; lon0=143.5; step=0.01; nr=950; nc=350;
ports=[13.4437 144.6667; 14.1400 145.1380; 14.9580 145.6200; 15.2258 145.7349];
idx=[];
for k=1:size(ports,1)-1
    a=ports(k,1); b=ports(k,2); c=ports(k+1,1); d=ports(k+1,2);
    n=floor(max(abs(c-a),abs(d-b))/step*2)+2;
    t=linspace(0,1,n);
    lat=a+t*(c-a); lon=b+t*(d-b);
    r=floor((lat-lat0)/step); col=floor((lon-lon0)/step);
    if any(r<0 | r>=nr | col<0 | col>=nc)
        error('guam_cnmi_links_rev1:outsideGrid','A link cell falls outside the grid.');
    end
    idx=[idx; col(:)*nr+r(:)+1]; %#ok<AGROW> 3 segments, so growth is small
end
cells=unique(idx);
if out_csv~=""
    writematrix(cells,out_csv);
end
end

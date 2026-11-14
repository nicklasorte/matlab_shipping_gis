function [rate_table,checks]=sband_carriage_rate_rev1(coder_a_csv,coder_b_csv,key_csv,kept_csv)
%sband_carriage_rate_rev1  Share of kept ships carrying an S-band radar, from the photo coding.
%
%   [T,C]=sband_carriage_rate_rev1(coder_a_csv,coder_b_csv,key_csv,kept_csv)
%   follows docs/protocols/photo_coding_protocol_rev1.md ("Estimate" 1-3):
%   rate = ships coded S over coded ships with a photo that are not unclear
%   or no_photo, by group (cargo, tanker, passenger, other), with a 95%
%   Wilson interval and the bounds if every unclear ship is S or none is.
%   The overall rate weights each group by its share of the kept ships; its
%   interval combines the group variances (normal approximation). Coder A's
%   codes are the estimate; coder B's give Cohen's kappa on the overlap.
%   Rows of key_csv with ship_group "planted" are the planted research ships.
%   MATLAB twin of python/sband_carriage_rate.py.
%
%   Built-ins: readtable, innerjoin, groupcounts-free counting with ismember,
%   norminv. Wilson and kappa are written out (no built-in in the installed
%   toolboxes gives a Wilson interval; binofit gives Clopper-Pearson).

arguments
    coder_a_csv (1,:) char
    coder_b_csv (1,:) char
    key_csv (1,:) char
    kept_csv (1,:) char
end

codes=["S","X_only","unclear","no_radar","no_photo"];
groups=["cargo";"tanker";"passenger";"other"];
z=norminv(0.975);

A=read_sheet(coder_a_csv,codes);
B=read_sheet(coder_b_csv,codes);
K=readtable(key_csv,'TextType','string','Delimiter',',');
K.imo=strtrim(string(K.imo));
kept=readtable(kept_csv,'TextType','string','Delimiter',',');
[in_key,loc]=ismember(A.imo,K.imo);
if ~all(in_key)
    error('shipgis:nokey','Coder A rows with no key entry: %s',strjoin(A.imo(~in_key),', '));
end
A.ship_group=K.ship_group(loc);

n_g=numel(groups);
weight=zeros(n_g,1); ships=zeros(n_g,1); coded=zeros(n_g,1); n_s=zeros(n_g,1); n_unclear=zeros(n_g,1); n_nophoto=zeros(n_g,1);
rate=NaN(n_g,1); wlo=NaN(n_g,1); whi=NaN(n_g,1); b_none=NaN(n_g,1); b_all=NaN(n_g,1); nophoto_share=NaN(n_g,1);
for g=1:n_g
    c=A.code(A.ship_group==groups(g));
    weight(g)=mean(kept.ship_group==groups(g));
    ships(g)=numel(c);
    n_s(g)=nnz(c=="S"); n_unclear(g)=nnz(c=="unclear"); n_nophoto(g)=nnz(c=="no_photo");
    n_photo=ships(g)-n_nophoto(g);
    coded(g)=n_photo-n_unclear(g);
    if coded(g)>0
        rate(g)=n_s(g)/coded(g);
        [wlo(g),whi(g)]=wilson(n_s(g),coded(g),z);
    end
    if n_photo>0
        b_none(g)=n_s(g)/n_photo; b_all(g)=(n_s(g)+n_unclear(g))/n_photo;
    end
    if ships(g)>0, nophoto_share(g)=n_nophoto(g)/ships(g); end
end
use=coded>0 & weight>0;
w=weight(use)/sum(weight(use));
est=sum(w.*rate(use));
sd=sqrt(sum(w.^2.*rate(use).*(1-rate(use))./coded(use)));
all_ships=sum(ships);
rate_table=table([groups;"overall"],[weight;sum(weight(use))],[ships;all_ships],[coded;sum(coded)],[n_s;sum(n_s)], ...
    [n_unclear;sum(n_unclear)],[n_nophoto;sum(n_nophoto)],[rate;est],[wlo;max(0,est-z*sd)],[whi;min(1,est+z*sd)], ...
    [b_none;sum(w.*b_none(use))],[b_all;sum(w.*b_all(use))],[nophoto_share;sum(n_nophoto)/max(1,all_ships)], ...
    'VariableNames',{'group','weight','ships','coded','s','unclear','no_photo','rate','wilson_lo','wilson_hi', ...
    'bound_none_unclear_s','bound_all_unclear_s','no_photo_share'});

[~,ia,ib]=intersect(A.imo,B.imo,'stable');
ca=A.code(ia); cb=B.code(ib);
checks=struct();
checks.overlap_ships=numel(ia);
checks.cohen_kappa=cohen_kappa(ca,cb,codes);
checks.kappa_meets_0_7=checks.cohen_kappa>=0.7;
checks.agreement=mean(ca==cb);
p=A.ship_group=="planted";
checks.planted_ships=nnz(p);
checks.planted_coded_s=nnz(p & A.code=="S");
checks.planted_not_s=A.imo(p & A.code~="S");
end

function S=read_sheet(path,codes)
S=readtable(path,'TextType','string','Delimiter',',');
S.imo=strtrim(string(S.imo));
c=string(S.code); c(ismissing(c))=""; S.code=strtrim(c);
bad=unique(S.code(~ismember(S.code,codes)));
if ~isempty(bad)
    error('shipgis:badcode','%s: unknown or blank codes %s',path,strjoin("'"+bad+"'",', '));
end
if numel(unique(S.imo))<height(S)
    error('shipgis:dupimo','%s: an IMO number appears twice',path);
end
end

function [lo,hi]=wilson(k,n,z)
%Wilson score interval (Wilson 1927).
p=k/n; den=1+z^2/n;
mid=(p+z^2/(2*n))/den;
half=z*sqrt(p*(1-p)/n+z^2/(4*n^2))/den;
lo=mid-half; hi=mid+half;
end

function kappa=cohen_kappa(a,b,labels)
n=numel(a);
if n==0, kappa=NaN; return, end
po=mean(a==b);
pe=0;
for c=labels
    pe=pe+mean(a==c)*mean(b==c);
end
kappa=(po-pe)/(1-pe);
end
